-- ============================================================
-- MARCO 2 — DASHBOARD ESTRATÉGICO
-- Views auxiliares para visualização dos gráficos analíticos
-- Fonte: mv_dashboard_estrategico_vetores (NOVO CONJUNTO)
-- ============================================================


-- ============================================================
-- VIEW S1
-- Novos usuários pagantes por mês
-- (crescimento real de usuários que pagaram pela primeira vez)
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s1_novos_usuarios_pagantes_mes AS
SELECT
    eixo_x        AS mes,
    eixo_y_valor  AS novos_usuarios
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S1_Novos_Usuarios_Pagantes_Por_Mes'
ORDER BY mes;


-- ============================================================
-- VIEW S2
-- Ticket médio mensal
-- (valor médio de pagamentos no mês)
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s2_ticket_medio_mensal AS
SELECT
    eixo_x            AS mes,
    eixo_y_valor      AS ticket_medio,
    valor_secundario  AS qtd_pagamentos
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S2_Ticket_Medio_Mensal'
ORDER BY mes;


-- ============================================================
-- VIEW S3
-- Distribuição % da receita por método de pagamento
-- (barras por método; tooltip com receita total do método)
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s3_receita_pct_por_metodo AS
SELECT
    eixo_x            AS metodo_pagamento,
    eixo_y_valor      AS receita_pct,
    valor_secundario  AS receita_total_metodo
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S3_Distribuicao_Receita_Por_Metodo'
ORDER BY receita_pct DESC, metodo_pagamento;


-- ============================================================
-- VIEW S4
-- Taxa de conversão do evento (pagantes / inscritos)
-- (qualidade do evento; tooltip com qtd pagantes)
-- ============================================================
CREATE OR REPLACE VIEW vw_grafico_s4_taxa_conversao_evento AS
SELECT
    eixo_x            AS evento,
    eixo_y_valor      AS taxa_conversao_pct,
    valor_secundario  AS qtd_pagantes
FROM mv_dashboard_estrategico_vetores
WHERE nome_grafico = 'S4_Taxa_Conversao_Evento'
ORDER BY taxa_conversao_pct DESC, evento;


-- ============================================================
-- TESTES (opcional)
-- ============================================================
SELECT * FROM vw_grafico_s1_novos_usuarios_pagantes_mes;
SELECT * FROM vw_grafico_s2_ticket_medio_mensal;
SELECT * FROM vw_grafico_s3_receita_pct_por_metodo;
SELECT * FROM vw_grafico_s4_taxa_conversao_evento;
