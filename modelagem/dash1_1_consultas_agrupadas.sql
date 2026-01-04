-- ============================================================
-- DASHBOARD ESTRATÉGICO (4 gráficos) - CONSULTAS REFORMULADAS
-- ============================================================

DROP MATERIALIZED VIEW IF EXISTS mv_dashboard_estrategico_vetores;

CREATE MATERIALIZED VIEW mv_dashboard_estrategico_vetores AS

/* ------------------------------------------------------------
 S1 (AVANÇADA): Novos usuários pagantes por mês
 - Mede crescimento real da base
------------------------------------------------------------ */
SELECT *
FROM (
  WITH primeiro_pagamento AS (
    SELECT
      u.id_usuario,
      MIN(p.dh_datapagamento) AS primeiro_pag
    FROM tb_usuario u
    JOIN tb_inscricao i ON i.id_usuario = u.id_usuario
    JOIN tb_pagamento p ON p.id_inscricao = i.id_inscricao
    GROUP BY u.id_usuario
  )
  SELECT
    'S1_Novos_Usuarios_Pagantes_Por_Mes'::text AS nome_grafico,
    'bar'::text AS tipo_grafico_sugerido,
    TO_CHAR(primeiro_pag, 'YYYY-MM') AS eixo_x,
    COUNT(*)::numeric AS eixo_y_valor,
    COUNT(*)::numeric AS valor_secundario,
    'novos_usuarios'::text AS rotulo_secundario
  FROM primeiro_pagamento
  GROUP BY TO_CHAR(primeiro_pag, 'YYYY-MM')
) s1

UNION ALL

/* ------------------------------------------------------------
 S2 (AVANÇADA): Ticket médio mensal
 - Receita / pagamentos
------------------------------------------------------------ */
SELECT *
FROM (
  SELECT
    'S2_Ticket_Medio_Mensal'::text AS nome_grafico,
    'line'::text AS tipo_grafico_sugerido,
    TO_CHAR(p.dh_datapagamento, 'YYYY-MM') AS eixo_x,
    ROUND(AVG(p.vl_valorpago), 2)::numeric AS eixo_y_valor,
    COUNT(*)::numeric AS valor_secundario,
    'qtd_pagamentos'::text AS rotulo_secundario
  FROM tb_pagamento p
  JOIN tb_inscricao i ON i.id_inscricao = p.id_inscricao
  JOIN tb_registro r ON r.id_registro = i.id_registro
  WHERE r.tp_registro = 'Evento'
  GROUP BY TO_CHAR(p.dh_datapagamento, 'YYYY-MM')
) s2

UNION ALL

/* ------------------------------------------------------------
 S3 (AVANÇADA): Receita percentual por método de pagamento
 - Distribuição estratégica de meios de pagamento
------------------------------------------------------------ */
SELECT *
FROM (
  WITH base AS (
    SELECT
      p.tp_metodopagamento AS metodo,
      SUM(p.vl_valorpago) AS receita_metodo
    FROM tb_pagamento p
    JOIN tb_inscricao i ON i.id_inscricao = p.id_inscricao
    JOIN tb_registro r ON r.id_registro = i.id_registro
    WHERE r.tp_registro = 'Evento'
    GROUP BY p.tp_metodopagamento
  )
  SELECT
    'S3_Distribuicao_Receita_Por_Metodo'::text AS nome_grafico,
    'bar'::text AS tipo_grafico_sugerido,
    metodo AS eixo_x,
    ROUND(
      100.0 * receita_metodo / NULLIF(SUM(receita_metodo) OVER (),0),
      2
    )::numeric AS eixo_y_valor,
    receita_metodo::numeric AS valor_secundario,
    'receita_total_metodo'::text AS rotulo_secundario
  FROM base
) s3

UNION ALL

/* ------------------------------------------------------------
 S4 (AVANÇADA): Taxa de conversão do evento (pagantes / inscritos)
 - Qualidade do evento
------------------------------------------------------------ */
SELECT *
FROM (
  WITH base AS (
    SELECT
      r.ds_titulo AS evento,
      COUNT(i.id_inscricao) AS inscritos,
      COUNT(p.id_pagamento) AS pagamentos
    FROM tb_registro r
    JOIN tb_inscricao i ON i.id_registro = r.id_registro
    LEFT JOIN tb_pagamento p ON p.id_inscricao = i.id_inscricao
    WHERE r.tp_registro = 'Evento'
    GROUP BY r.ds_titulo
  )
  SELECT
    'S4_Taxa_Conversao_Evento'::text AS nome_grafico,
    'bar'::text AS tipo_grafico_sugerido,
    evento AS eixo_x,
    ROUND(
      100.0 * pagamentos / NULLIF(inscritos,0),
      2
    )::numeric AS eixo_y_valor,
    pagamentos::numeric AS valor_secundario,
    'qtd_pagantes'::text AS rotulo_secundario
  FROM base
) s4
;

-- ============================================================
-- Stored Procedure
-- ============================================================

DROP PROCEDURE IF EXISTS sp_refresh_dashboard_estrategico;

CREATE PROCEDURE sp_refresh_dashboard_estrategico()
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_dashboard_estrategico_vetores;
END;
$$;

-- ============================================================
-- Teste
-- ============================================================

CALL sp_refresh_dashboard_estrategico();

SELECT *
FROM mv_dashboard_estrategico_vetores
ORDER BY nome_grafico, eixo_x;
