-- 04_vendas_por_regiao.sql
-- Analisa a distribuicao de vendas por regiao e retorna o percentual
-- de participacao de cada regiao no valor total vendido.

WITH totais_por_regiao AS (
    SELECT
        regiao,
        SUM(valor_total) AS valor_total_regiao
    FROM workshop_db.vendas_processed
    GROUP BY regiao
),
total_geral AS (
    SELECT SUM(valor_total_regiao) AS valor_total FROM totais_por_regiao
)
SELECT
    t.regiao,
    ROUND(t.valor_total_regiao, 2)                                   AS valor_total_regiao,
    ROUND(100.0 * t.valor_total_regiao / g.valor_total, 2)           AS percentual_participacao
FROM totais_por_regiao t
CROSS JOIN total_geral g
ORDER BY percentual_participacao DESC;
