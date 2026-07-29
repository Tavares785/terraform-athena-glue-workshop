-- 01_explorar_raw.sql
-- Explora a tabela raw catalogada automaticamente pelo Glue_Crawler
-- a partir dos arquivos CSV em s3://{S3_Raw_Bucket}/vendas/

SELECT
    id_venda,
    data_venda,
    produto,
    categoria,
    quantidade,
    preco_unitario,
    vendedor,
    regiao
FROM workshop_db.vendas
LIMIT 20;
