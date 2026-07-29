# Manual de Criação via Console AWS

Este manual descreve os passos para criar manualmente, pela interface web da AWS, um pipeline de dados parecido com o provisionado pelo Terraform neste workshop.

## 1. Preparação

1. Faça login no console AWS.
2. Selecione a região desejada (recomendado: `us-east-1`).
3. Verifique se você tem permissões para criar recursos em:
   - S3
   - IAM
   - Glue
   - Athena
   - CloudWatch Logs

## 2. Criar buckets S3

### 2.1 Bucket de dados raw

1. Acesse o serviço **S3**.
2. Clique em **Create bucket**.
3. Informe o nome do bucket, por exemplo: `gtavares-workshop-raw`.
4. Mantenha todas as opções de Bloqueio de Acesso Público habilitadas.
5. Crie o bucket.

### 2.2 Bucket de dados processados

1. Crie outro bucket, por exemplo: `gtavares-workshop-processed`.
2. Habilite Block Public Access em todas as opções.
3. Crie o bucket.

### 2.3 Bucket de resultados do Athena

1. Crie outro bucket, por exemplo: `gtavares-workshop-athena-results`.
2. Habilite Block Public Access.
3. Crie o bucket.

### 2.4 Bucket para script Glue

1. Crie outro bucket, por exemplo: `gtavares-workshop-glue-scripts`.
2. Habilite Block Public Access.
3. Crie o bucket.

## 3. Fazer upload dos artefatos

### 3.1 Upload do dataset CSV

1. Entre no bucket `gtavares-workshop-raw`.
2. Clique em **Upload**.
3. Arraste o arquivo `data/vendas_sample.csv` do repositório para a área de upload.
4. Defina a chave de objeto desejada, por exemplo: `vendas/ano=2024/vendas_sample.csv`.
5. Conclua o upload.

### 3.2 Upload do script Glue

1. Entre no bucket `gtavares-workshop-glue-scripts`.
2. Clique em **Upload**.
3. Arraste o arquivo `scripts/etl_job.py` do repositório.
4. Conclua o upload.

## 4. Criar database do Glue

1. Acesse o serviço **AWS Glue**.
2. No menu lateral, clique em **Databases**.
3. Clique em **Add database**.
4. Nomeie como `workshop_db`.
5. Salve o database.

## 5. Criar crawler Glue para catalogar o raw

1. No Glue, vá em **Crawlers**.
2. Clique em **Add crawler**.
3. Informe o nome, por exemplo: `workshop-raw-crawler`.
4. Em **Data sources**, escolha **S3**.
5. Selecione o bucket `gtavares-workshop-raw` e a pasta onde colocou o CSV.
6. Em **IAM role**, escolha ou crie uma role que permita ao Glue ler o bucket raw e escrever no Data Catalog.
7. Em **Database**, selecione `workshop_db`.
8. Defina o nome da tabela, por exemplo: `vendas_raw`.
9. Termine a criação do crawler.

### 5.1 Executar o crawler

1. Selecione o crawler `workshop-raw-crawler`.
2. Clique em **Run crawler**.
3. Aguarde o término.
4. Verifique no Glue Data Catalog se a tabela `vendas_raw` foi criada corretamente.

## 6. Criar job Glue (ETL)

1. No Glue, acesse **Jobs**.
2. Clique em **Add job**.
3. Informe o nome, por exemplo: `workshop-etl-job`.
4. Em **IAM role**, escolha ou crie uma role com permissão para:
   - ler o bucket `gtavares-workshop-raw`
   - gravar em `gtavares-workshop-processed`
   - atualizar o Glue Data Catalog
   - gravar logs no CloudWatch
5. Em **Type**, escolha **Spark**.
6. Em **Glue version**, selecione uma versão compatível com PySpark.
7. Em **This job runs**, escolha **A new script to be authored by you** ou **An existing script that you provide**, e aponte para o arquivo `scripts/etl_job.py` no bucket `gtavares-workshop-glue-scripts`.
8. Em **Script file name**, selecione o script `etl_job.py` que você fez upload.
9. Em **Job parameters**, se necessário, confirme os parâmetros de entrada / saída:
   - `--JOB_NAME` (automático)
   - `--raw_bucket` ou outra variável de caminho se o script usar
10. Salve o job.

### 6.1 Ajustar paths no script

1. Abra o script `etl_job.py` e verifique se ele lê o raw bucket e grava no processed bucket.
2. Confirme o caminho de saída Parquet particionado por `regiao`.

## 7. Criar workgroup Athena

1. Acesse o serviço **Athena**.
2. No painel lateral, clique em **Workgroups**.
3. Clique em **Create workgroup**.
4. Nomeie como `workshop-workgroup`.
5. Em **Settings**, configure a pasta de resultados no S3 como `s3://gtavares-workshop-athena-results/`.
6. Opcional: ative o limite de bytes escaneados por query em `1 GiB` para evitar custos altos.
7. Crie o workgroup.

## 8. Executar ETL e consultar os dados

### 8.1 Rodar o job Glue

1. No Glue, selecione `workshop-etl-job`.
2. Clique em **Run job**.
3. Aguarde a conclusão.
4. Verifique se os dados Parquet chegaram em `gtavares-workshop-processed`.

### 8.2 Verificar catálogo Glue atualizado

1. No Glue Data Catalog, observe a tabela criada ou atualizada para `processed`.
2. Se necessário, volte ao crawler e adicione o caminho do bucket processado para crawlar os dados Parquet.

### 8.3 Executar queries no Athena

1. Acesse o Athena e selecione o workgroup `workshop-workgroup`.
2. Abra a query editor.
3. Carregue ou cole as queries do diretório `queries/`:
   - `01_explorar_raw.sql`
   - `02_total_por_categoria.sql`
   - `03_top_vendedores.sql`
   - `04_vendas_por_regiao.sql`
   - `05_consultar_processed.sql`
4. Ajuste se necessário o nome do database `workshop_db` ou das tabelas.
5. Execute as queries para validar os dados.

## 9. Limpeza

1. Para destruir o ambiente, exclua os recursos criados manualmente:
   - Buckets S3 (esvazie e exclua)
   - Glue Crawler
   - Glue Job
   - Glue Database
   - Athena Workgroup
   - Roles IAM criadas
2. Se algum bucket estiver versionado, esvazie todas as versões antes de excluir.

## 10. Observações

- Use nomes únicos em todos os buckets para evitar conflitos de nome global do S3.
- Mantenha o bloqueio de acesso público habilitado nos buckets.
- Prefira usar uma política IAM de privilégio mínimo, permitindo apenas as ações necessárias.
- Se preferir, use o Terraform deste repositório para criar o ambiente automaticamente em vez de manualmente.
