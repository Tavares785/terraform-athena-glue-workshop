-- 02_total_por_categoria.sql
-- Agrupa as vendas por categoria e calcula o valor_total somado,
-- ordenado de forma decrescente.
-- Requer a tabela processada (vendas_processed) gerada pelo Glue_ETL_Job.

SELECT
    categoria,
    COUNT(*)                         AS qtd_vendas,
    SUM(quantidade)                  AS qtd_itens_vendidos,
    ROUND(SUM(valor_total), 2)       AS valor_total_categoria
FROM workshop_db.vendas_processed
GROUP BY categoria
ORDER BY valor_total_categoria DESC;
