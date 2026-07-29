"""
Glue ETL Job - Workshop "Analise de Dados sem complicacao com AWS Athena e Glue"
Autor: Gustavo Tavares

Le os arquivos CSV brutos de vendas do S3_Raw_Bucket, aplica limpeza e
transformacoes, e grava o resultado em formato Parquet particionado por
`regiao` no S3_Processed_Bucket, atualizando o Glue Data Catalog.

Transformacoes aplicadas:
  - Remove registros com preco_unitario nulo ou negativo.
  - Converte `quantidade` para inteiro.
  - Converte `preco_unitario` para decimal(10,2).
  - Converte `data_venda` (string YYYY-MM-DD) para o tipo date.
  - Calcula a coluna derivada `valor_total = quantidade * preco_unitario`.
  - Particiona a saida por `regiao`.
"""

import sys

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as F
from pyspark.sql.types import IntegerType, DecimalType, DateType

# ---------------------------------------------------------------------------
# Parametros do Job (injetados pelo Terraform via default_arguments)
# ---------------------------------------------------------------------------
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "raw_s3_path",
        "processed_s3_path",
        "glue_database",
        "processed_table_name",
    ],
)

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

RAW_S3_PATH = args["raw_s3_path"]
PROCESSED_S3_PATH = args["processed_s3_path"]
GLUE_DATABASE = args["glue_database"]
PROCESSED_TABLE_NAME = args["processed_table_name"]

# ---------------------------------------------------------------------------
# 1. Leitura dos dados brutos (CSV) via DynamicFrame
# ---------------------------------------------------------------------------
raw_dynamic_frame = glueContext.create_dynamic_frame.from_options(
    format_options={"quoteChar": '"', "withHeader": True, "separator": ","},
    connection_type="s3",
    format="csv",
    connection_options={"paths": [RAW_S3_PATH], "recurse": True},
    transformation_ctx="raw_dynamic_frame",
)

if raw_dynamic_frame.count() == 0:
    raise RuntimeError(
        f"Nenhum dado de entrada encontrado em {RAW_S3_PATH}. "
        "Verifique se o Sample_Dataset foi carregado no S3_Raw_Bucket."
    )

df = raw_dynamic_frame.toDF()

# ---------------------------------------------------------------------------
# 2. Limpeza e tipagem
# ---------------------------------------------------------------------------
df = df.withColumn("quantidade", F.col("quantidade").cast(IntegerType()))
df = df.withColumn(
    "preco_unitario", F.col("preco_unitario").cast(DecimalType(10, 2))
)
df = df.withColumn("data_venda", F.to_date(F.col("data_venda"), "yyyy-MM-dd"))

# Remove registros com preco_unitario nulo ou negativo
df = df.filter(F.col("preco_unitario").isNotNull() & (F.col("preco_unitario") > 0))

# Coluna derivada valor_total = quantidade * preco_unitario
df = df.withColumn(
    "valor_total", (F.col("quantidade") * F.col("preco_unitario")).cast(DecimalType(12, 2))
)

# Remove duplicidades e linhas totalmente nulas
df = df.dropDuplicates(["id_venda"])
df = df.na.drop(how="all")

# ---------------------------------------------------------------------------
# 3. Escrita em Parquet particionado por regiao + catalogacao no Glue
# ---------------------------------------------------------------------------
processed_dynamic_frame = DynamicFrame.fromDF(df, glueContext, "processed_dynamic_frame")

sink = glueContext.getSink(
    connection_type="s3",
    path=PROCESSED_S3_PATH,
    enableUpdateCatalog=True,
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["regiao"],
    transformation_ctx="processed_sink",
)
sink.setFormat("glueparquet")
sink.setCatalogInfo(catalogDatabase=GLUE_DATABASE, catalogTableName=PROCESSED_TABLE_NAME)
sink.writeFrame(processed_dynamic_frame)

job.commit()
