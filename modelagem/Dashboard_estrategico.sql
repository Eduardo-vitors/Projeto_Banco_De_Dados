-- ====================================================
-- DASHBOARD 1: 4 GRÁFICOS ANALÍTICOS ESTRATÉGICOS
-- Materialized View com 4 KPIs estratégicos
-- ====================================================

DROP MATERIALIZED VIEW IF EXISTS mv_dashboard_estrategico_completo;
DROP PROCEDURE IF EXISTS sp_atualizar_dashboard_estrategico;

-- Materialized View que agrega os 4 gráficos estratégicos
CREATE MATERIALIZED VIEW mv_dashboard_estrategico_completo AS

-- 1) GRÁFICO: CONVERSÃO EVENTO → ATIVIDADES (Engajamento)
WITH 
inscritos_evento AS (
  SELECT
    e.id_registro AS id_evento,
    e.ds_titulo   AS evento,
    i.id_usuario
  FROM tb_registro e
  JOIN tb_inscricao i ON i.id_registro = e.id_registro
  WHERE e.tp_registro = 'Evento'
),
flag_atividade AS (
  SELECT
    ie.id_evento,
    ie.evento,
    ie.id_usuario,
    EXISTS (
      SELECT 1
      FROM tb_inscricao ia
      JOIN tb_registro a ON a.id_registro = ia.id_registro
      WHERE ia.id_usuario = ie.id_usuario
        AND a.tp_registro = 'Atividade'
        AND a.id_eventopai = ie.id_evento
    ) AS fez_atividade
  FROM inscritos_evento ie
),
conversao AS (
  SELECT
    evento,
    COUNT(*) AS inscritos_evento,
    COUNT(*) FILTER (WHERE fez_atividade) AS inscritos_com_atividade,
    ROUND(100.0 * COUNT(*) FILTER (WHERE fez_atividade) / NULLIF(COUNT(*),0), 2) AS conversao_pct,
    ROW_NUMBER() OVER () AS row_id  -- Adicionado para índice único
  FROM flag_atividade
  GROUP BY evento
)
SELECT
  'Engajamento_Evento_Atividade'::varchar AS tipo_grafico,
  'Taxa de Conversão'::varchar AS titulo_grafico,
  evento AS dimensao_principal,
  NULL::varchar AS dimensao_secundaria,
  conversao_pct::numeric AS valor_principal,
  inscritos_com_atividade::numeric AS valor_absoluto,
  inscritos_evento::numeric AS valor_base,
  RANK() OVER (ORDER BY conversao_pct DESC) AS ranking,
  row_id AS id_unico  -- Para índice único
FROM conversao

UNION ALL

-- 2) GRÁFICO: RECEITA POR ÁREA X INSTITUIÇÃO (Faturamento)
SELECT
  'Faturamento_Area_Instituicao'::varchar,
  'Distribuição de Receita',
  r.tp_area,
  u.ds_instituicao,
  ROUND(100.0 * SUM(p.vl_valorpago) / NULLIF(SUM(SUM(p.vl_valorpago)) OVER (PARTITION BY r.tp_area), 0), 2),
  SUM(p.vl_valorpago)::numeric,
  COUNT(DISTINCT u.id_usuario)::numeric,
  DENSE_RANK() OVER (PARTITION BY r.tp_area ORDER BY SUM(p.vl_valorpago) DESC),
  ROW_NUMBER() OVER () + 100000  -- IDs únicos
FROM tb_registro r
JOIN tb_inscricao i ON i.id_registro = r.id_registro
JOIN tb_usuario u   ON u.id_usuario = i.id_usuario
JOIN tb_pagamento p ON p.id_inscricao = i.id_inscricao
WHERE r.tp_registro = 'Evento'
GROUP BY r.tp_area, u.ds_instituicao

UNION ALL

-- 3) GRÁFICO: CERTIFICAÇÃO POR EVENTO (Qualidade)
SELECT
  'Qualidade_Certificacao'::varchar,
  'Taxa de Certificação',
  e.ds_titulo AS evento,
  NULL::varchar,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM tb_certificado c WHERE c.id_inscricao = i.id_inscricao))
    / NULLIF(COUNT(*) FILTER (WHERE i.st_presente), 0), 
  2) AS taxa_certificacao_pct,
  COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM tb_certificado c WHERE c.id_inscricao = i.id_inscricao))::numeric,
  COUNT(*) FILTER (WHERE i.st_presente)::numeric,
  RANK() OVER (
    ORDER BY (
      1.0 * COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM tb_certificado c WHERE c.id_inscricao = i.id_inscricao))
      / NULLIF(COUNT(*) FILTER (WHERE i.st_presente), 0)
    ) DESC
  ),
  ROW_NUMBER() OVER () + 200000  -- IDs únicos
FROM tb_registro e
JOIN tb_inscricao i ON i.id_registro = e.id_registro
WHERE e.tp_registro = 'Evento'
GROUP BY e.ds_titulo

UNION ALL

-- 4) GRÁFICO: REINCIDÊNCIA POR INSTITUIÇÃO (Fidelização)
SELECT
  'Fidelizacao_Instituicao'::varchar,
  'Taxa de Reincidência',
  u.ds_instituicao,
  NULL::varchar,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN eventos_usuario.qtd_eventos >= 2 THEN u.id_usuario END)
    / NULLIF(COUNT(DISTINCT u.id_usuario), 0), 
  2) AS reincidencia_pct,
  COUNT(DISTINCT CASE WHEN eventos_usuario.qtd_eventos >= 2 THEN u.id_usuario END)::numeric,
  COUNT(DISTINCT u.id_usuario)::numeric,
  DENSE_RANK() OVER (
    ORDER BY (
      1.0 * COUNT(DISTINCT CASE WHEN eventos_usuario.qtd_eventos >= 2 THEN u.id_usuario END)
      / NULLIF(COUNT(DISTINCT u.id_usuario), 0)
    ) DESC
  ),
  ROW_NUMBER() OVER () + 300000  -- IDs únicos
FROM tb_usuario u
JOIN tb_inscricao i ON i.id_usuario = u.id_usuario
JOIN tb_registro e ON e.id_registro = i.id_registro
JOIN (
  SELECT
    u2.id_usuario,
    COUNT(DISTINCT e2.id_registro) AS qtd_eventos
  FROM tb_usuario u2
  JOIN tb_inscricao i2 ON i2.id_usuario = u2.id_usuario
  JOIN tb_registro e2 ON e2.id_registro = i2.id_registro
  WHERE e2.tp_registro = 'Evento'
  GROUP BY u2.id_usuario
) eventos_usuario ON eventos_usuario.id_usuario = u.id_usuario
WHERE e.tp_registro = 'Evento'
GROUP BY u.ds_instituicao;

-- Índice ÚNICO obrigatório para REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_dashboard_id_unico ON mv_dashboard_estrategico_completo(id_unico);

-- Índices adicionais para otimização
CREATE INDEX idx_mv_dashboard_tipo ON mv_dashboard_estrategico_completo(tipo_grafico);
CREATE INDEX idx_mv_dashboard_kpi_dimensao ON mv_dashboard_estrategico_completo(tipo_grafico, dimensao_principal);

-- Stored Procedure para atualizar o dashboard (agora sem CONCURRENTLY)
CREATE OR REPLACE PROCEDURE sp_atualizar_dashboard_estrategico()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Atualização simples (bloqueante, mas mais segura)
    REFRESH MATERIALIZED VIEW mv_dashboard_estrategico_completo;
    RAISE NOTICE 'Dashboard estratégico atualizado em: %', CURRENT_TIMESTAMP;
END;
$$;