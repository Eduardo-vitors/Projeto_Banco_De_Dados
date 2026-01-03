-- ====================================================
-- TESTES DO DASHBOARD 1 ESTRATÉGICO
-- ====================================================

-- 1) VISÃO GERAL DO DASHBOARD
SELECT '=== VISÃO GERAL DO DASHBOARD ===' AS info;
SELECT 
    tipo_grafico,
    COUNT(*) AS quantidade_registros,
    MIN(valor_principal) AS valor_minimo,
    MAX(valor_principal) AS valor_maximo,
    ROUND(AVG(valor_principal), 2) AS media_valores
FROM mv_dashboard_estrategico_completo
GROUP BY tipo_grafico
ORDER BY tipo_grafico;

-- 2) GRÁFICO 1: ENGAJAMENTO (Top 10 eventos com maior conversão)
SELECT '=== GRÁFICO 1: ENGAJAMENTO (Top 10) ===' AS info;
SELECT 
    dimensao_principal AS evento,
    valor_principal AS taxa_conversao_percentual,
    valor_absoluto AS usuarios_convertidos,
    valor_base AS total_inscritos,
    ranking
FROM mv_dashboard_estrategico_completo
WHERE tipo_grafico = 'Engajamento_Evento_Atividade'
ORDER BY ranking
LIMIT 10;

-- 3) GRÁFICO 2: FATURAMENTO (Top 5 por área)
SELECT '=== GRÁFICO 2: FATURAMENTO (Top 5 por área) ===' AS info;
SELECT 
    dimensao_principal AS area,
    dimensao_secundaria AS instituicao,
    valor_principal AS participacao_percentual,
    valor_absoluto AS receita_total,
    valor_base AS usuarios_pagantes,
    ranking
FROM mv_dashboard_estrategico_completo
WHERE tipo_grafico = 'Faturamento_Area_Instituicao'
ORDER BY dimensao_principal, ranking
LIMIT 5;

-- 4) GRÁFICO 3: QUALIDADE (Eventos com melhor taxa de certificação)
SELECT '=== GRÁFICO 3: QUALIDADE (Taxa de Certificação) ===' AS info;
SELECT 
    dimensao_principal AS evento,
    valor_principal AS taxa_certificacao_percentual,
    valor_absoluto AS certificados_emitidos,
    valor_base AS participantes_presentes,
    ranking
FROM mv_dashboard_estrategico_completo
WHERE tipo_grafico = 'Qualidade_Certificacao'
ORDER BY ranking
LIMIT 10;

-- 5) GRÁFICO 4: FIDELIZAÇÃO (Instituições com maior reincidência)
SELECT '=== GRÁFICO 4: FIDELIZAÇÃO (Top 10 instituições) ===' AS info;
SELECT 
    dimensao_principal AS instituicao,
    valor_principal AS taxa_reincidencia_percentual,
    valor_absoluto AS usuarios_reincidentes,
    valor_base AS total_usuarios,
    ranking
FROM mv_dashboard_estrategico_completo
WHERE tipo_grafico = 'Fidelizacao_Instituicao'
ORDER BY ranking
LIMIT 10;

-- 6) TESTE DE ATUALIZAÇÃO DA MATERIALIZED VIEW
SELECT '=== TESTE DE ATUALIZAÇÃO ===' AS info;

-- Contagem antes da atualização
SELECT 'Antes da atualização:' AS status, COUNT(*) AS registros
FROM mv_dashboard_estrategico_completo;

-- Executa a stored procedure de atualização
CALL sp_atualizar_dashboard_estrategico();

-- Contagem após a atualização
SELECT 'Após atualização:' AS status, COUNT(*) AS registros
FROM mv_dashboard_estrategico_completo;

-- 7) VISUALIZAÇÃO POR TIPO DE GRÁFICO (para relatório)
SELECT '=== RESUMO PARA RELATÓRIO ===' AS info;
SELECT 
    tipo_grafico AS "Tipo de Gráfico",
    titulo_grafico AS "Título",
    COUNT(*) AS "Qtd Itens",
    ROUND(AVG(valor_principal), 2) AS "Média %",
    ROUND(MIN(valor_principal), 2) AS "Mínimo %",
    ROUND(MAX(valor_principal), 2) AS "Máximo %"
FROM mv_dashboard_estrategico_completo
GROUP BY tipo_grafico, titulo_grafico
ORDER BY tipo_grafico;