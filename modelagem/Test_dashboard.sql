-- ============================================================
-- MARCO 2 — DASHBOARD ESTRATÉGICO
-- Views auxiliares para visualização dos gráficos analíticos
-- Fonte: mv_dashboard_estrategico_vetores
-- ============================================================


-- ============================================================
-- VIEW S1
-- Receita mensal por área (acumulada)
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s1_receita_mensal_area AS
SELECT
    eixo_x,
    eixo_y_valor     AS receita_acumulada,
    valor_secundario AS receita_no_mes
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S1_Receita_Mensal_Por_Area_Acumulada'
ORDER BY eixo_x;


-- ============================================================
-- VIEW S2
-- Percentual de usuários recorrentes por mês
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s2_usuarios_recorrentes AS
SELECT
    eixo_x           AS mes,
    eixo_y_valor     AS percentual_recorrentes,
    valor_secundario AS usuarios_unicos_no_mes
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S2_Usuarios_Recorrentes_Por_Mes'
ORDER BY mes;


-- ============================================================
-- VIEW S3
-- Concentração de arrecadação por instituição (HHI)
-- Indicador único
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s3_concentracao_hhi AS
SELECT
    eixo_y_valor     AS indice_hhi,
    valor_secundario AS qtd_instituicoes
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S3_Concentracao_Arrecadacao_Instituicao_HHI';


-- ============================================================
-- VIEW S4
-- Razão de inscrições em atividades por evento
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s4_razao_atividade_evento AS
SELECT
    eixo_x           AS evento,
    eixo_y_valor     AS razao_atividade_evento,
    valor_secundario AS inscritos_em_atividades
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S4_Razao_Atividade_por_Evento'
ORDER BY razao_atividade_evento DESC;

SELECT * FROM vw_grafico_s1_receita_mensal_area;
SELECT * FROM vw_grafico_s2_usuarios_recorrentes;
SELECT * FROM vw_grafico_s3_concentracao_hhi;
SELECT * FROM vw_grafico_s4_razao_atividade_evento;
