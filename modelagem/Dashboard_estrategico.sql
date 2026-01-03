-- ============================================================
-- DASHBOARD ESTRATÉGICO (4 gráficos analíticos) - MARCO 2
-- Materialized View (vetorial) + Stored Procedure (refresh)
-- Saída: nome_grafico, tipo_grafico_sugerido, eixo_x, eixo_y_valor, valor_secundario, rotulo_secundario
-- ============================================================

DROP MATERIALIZED VIEW IF EXISTS mv_dashboard_estrategico_vetores;

CREATE MATERIALIZED VIEW mv_dashboard_estrategico_vetores AS

/* ------------------------------------------------------------
 S1 (AVANÇADA): Receita mensal por ÁREA (tp_area) + acumulado por área
 - 3 tabelas: tb_registro, tb_inscricao, tb_pagamento
 - JOIN + GROUP BY + WINDOW
------------------------------------------------------------ */
SELECT
  'S1_Receita_Mensal_Por_Area_Acumulada'::text AS nome_grafico,
  'line'::text AS tipo_grafico_sugerido,
  (r.tp_area || ' | ' || TO_CHAR(p.dh_datapagamento, 'YYYY-MM')) AS eixo_x,
  SUM(SUM(p.vl_valorpago)) OVER (
    PARTITION BY r.tp_area
    ORDER BY TO_CHAR(p.dh_datapagamento, 'YYYY-MM')
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )::numeric AS eixo_y_valor,
  SUM(p.vl_valorpago)::numeric AS valor_secundario,
  'receita_no_mes'::text AS rotulo_secundario
FROM tb_registro r
JOIN tb_inscricao i ON i.id_registro = r.id_registro
JOIN tb_pagamento p ON p.id_inscricao = i.id_inscricao
WHERE r.tp_registro = 'Evento'
GROUP BY r.tp_area, TO_CHAR(p.dh_datapagamento, 'YYYY-MM')

UNION ALL

/* ------------------------------------------------------------
 S2 (AVANÇADA): % de usuários recorrentes por mês (já tinham pago antes)
 - 3 tabelas: tb_usuario, tb_inscricao, tb_pagamento
 - SUBCONSULTA (EXISTS) + JOIN + GROUP BY + COUNT
------------------------------------------------------------ */
SELECT
  'S2_Usuarios_Recorrentes_Por_Mes'::text,
  'bar'::text,
  TO_CHAR(p.dh_datapagamento, 'YYYY-MM') AS eixo_x,
  ROUND(
    100.0 * COUNT(DISTINCT u.id_usuario) FILTER (
      WHERE EXISTS (
        SELECT 1
        FROM tb_inscricao i2
        JOIN tb_pagamento p2 ON p2.id_inscricao = i2.id_inscricao
        WHERE i2.id_usuario = u.id_usuario
          AND p2.dh_datapagamento < DATE_TRUNC('month', p.dh_datapagamento)
      )
    )
    / NULLIF(COUNT(DISTINCT u.id_usuario), 0)
  , 2)::numeric AS eixo_y_valor,
  COUNT(DISTINCT u.id_usuario)::numeric AS valor_secundario,
  'usuarios_unicos_no_mes'::text
FROM tb_usuario u
JOIN tb_inscricao i ON i.id_usuario = u.id_usuario
JOIN tb_pagamento p ON p.id_inscricao = i.id_inscricao
GROUP BY TO_CHAR(p.dh_datapagamento, 'YYYY-MM')

UNION ALL

/* ------------------------------------------------------------
 S3 (AVANÇADA): Concentração de arrecadação por instituição (HHI)
 - HHI alto = poucas instituições dominam a receita
 - 3 tabelas: tb_usuario, tb_inscricao, tb_pagamento
 - CTE + JOIN + GROUP BY + WINDOW
------------------------------------------------------------ */
SELECT *
FROM (
  WITH inst AS (
    SELECT
      u.ds_instituicao,
      SUM(p.vl_valorpago) AS receita_inst
    FROM tb_usuario u
    JOIN tb_inscricao i ON i.id_usuario = u.id_usuario
    JOIN tb_pagamento p ON p.id_inscricao = i.id_inscricao
    GROUP BY u.ds_instituicao
  ),
  base AS (
    SELECT
      ds_instituicao,
      receita_inst,
      (receita_inst / NULLIF(SUM(receita_inst) OVER (), 0)) AS share
    FROM inst
  )
  SELECT
    'S3_Concentracao_Arrecadacao_Instituicao_HHI'::text AS nome_grafico,
    'single'::text AS tipo_grafico_sugerido,
    'HHI_Geral'::text AS eixo_x,
    ROUND(SUM(share * share), 4)::numeric AS eixo_y_valor,
    COUNT(*)::numeric AS valor_secundario,
    'qtd_instituicoes'::text AS rotulo_secundario
  FROM base
) s3

UNION ALL

/* ------------------------------------------------------------
 S4 (AVANÇADA): Razão inscrições em ATIVIDADES / inscrições em EVENTOS (por evento pai)
 - 3+ tabelas: tb_registro (evento), tb_registro (atividade), tb_inscricao
 - CTEs + JOIN + GROUP BY + COUNT
------------------------------------------------------------ */
SELECT *
FROM (
  WITH eventos AS (
    SELECT id_registro, ds_titulo
    FROM tb_registro
    WHERE tp_registro = 'Evento'
  ),
  ins_evento AS (
    SELECT
      e.id_registro AS id_evento,
      COUNT(i.id_inscricao) AS inscritos_evento
    FROM eventos e
    LEFT JOIN tb_inscricao i ON i.id_registro = e.id_registro
    GROUP BY e.id_registro
  ),
  ins_ativ AS (
    SELECT
      e.id_registro AS id_evento,
      COUNT(i.id_inscricao) AS inscritos_atividades
    FROM eventos e
    JOIN tb_registro a
      ON a.id_eventopai = e.id_registro
     AND a.tp_registro = 'Atividade'
    LEFT JOIN tb_inscricao i ON i.id_registro = a.id_registro
    GROUP BY e.id_registro
  )
  SELECT
    'S4_Razao_Atividade_por_Evento'::text AS nome_grafico,
    'bar'::text AS tipo_grafico_sugerido,
    e.ds_titulo AS eixo_x,
    ROUND(
      1.0 * COALESCE(ia.inscritos_atividades, 0)
      / NULLIF(ie.inscritos_evento, 0),
      4
    )::numeric AS eixo_y_valor,
    COALESCE(ia.inscritos_atividades, 0)::numeric AS valor_secundario,
    'inscritos_atividades'::text AS rotulo_secundario
  FROM eventos e
  JOIN ins_evento ie ON ie.id_evento = e.id_registro
  LEFT JOIN ins_ativ ia ON ia.id_evento = e.id_registro
) s4
;

DROP PROCEDURE IF EXISTS sp_refresh_dashboard_estrategico;

CREATE PROCEDURE sp_refresh_dashboard_estrategico()
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_dashboard_estrategico_vetores;
END;
$$;

CALL sp_refresh_dashboard_estrategico();

SELECT *
FROM mv_dashboard_estrategico_vetores
ORDER BY nome_grafico, eixo_x;

