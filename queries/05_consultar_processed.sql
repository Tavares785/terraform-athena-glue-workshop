-- 05_consultar_processed.sql
-- Consulta os dados processados em Parquet no S3_Processed_Bucket
-- via tabela catalogada (vendas_processed), demonstrando o ganho de
-- performance e organizacao apos o Glue_ETL_Job.

SELECT
    produto,
    categoria,
    regiao,
    data_venda,
    quantidade,
    preco_unitario,
    valor_total
FROM workshop_db.vendas_processed
WHERE regiao = 'Sudeste'
ORDER BY data_venda DESC
LIMIT 20;
