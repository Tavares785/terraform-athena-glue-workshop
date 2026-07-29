-- 03_top_vendedores.sql
-- Lista os 5 melhores vendedores por valor total de vendas.

SELECT
    vendedor,
    COUNT(*)                     AS qtd_vendas,
    ROUND(SUM(valor_total), 2)   AS valor_total_vendido
FROM workshop_db.vendas_processed
GROUP BY vendedor
ORDER BY valor_total_vendido DESC
LIMIT 5;
