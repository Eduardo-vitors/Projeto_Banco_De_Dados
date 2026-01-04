-- GRÁFICO 1 - Evolução Temporal com Média Móvel (Line)
CREATE MATERIALIZED VIEW VM_Dash2_Grafico1_TendenciaInscricoes AS
SELECT 
    r.DS_Titulo AS Nome_Evento,
    -- Eixo X: Data formatada para exibição (String)
    TO_CHAR(i.DH_DataInscricao::DATE, 'DD/MM/YYYY') AS Eixo_X_Data,
    
    -- Dica: Mantivemos a data original (sem formatação) oculta caso precise ordenar no front
    i.DH_DataInscricao::DATE AS _Data_Ordenacao,
    
    -- Eixo Y (Série 1): Total bruto do dia
    COUNT(i.ID_Inscricao) AS Eixo_Y_Qtd_Diaria,
    
    -- Eixo Y (Série 2): Cálculo Avançado (Média Móvel 7 dias)
    ROUND(AVG(COUNT(i.ID_Inscricao)) OVER (
        PARTITION BY r.ID_Registro 
        ORDER BY i.DH_DataInscricao::DATE 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS Eixo_Y_Media_Movel

FROM TB_Registro r
JOIN TB_Inscricao i ON r.ID_Registro = i.ID_Registro
JOIN TB_Usuario u ON i.ID_Usuario = u.ID_Usuario -- 3ª Tabela
WHERE r.TP_Registro = 'Evento'
GROUP BY r.ID_Registro, r.DS_Titulo, i.DH_DataInscricao::DATE
ORDER BY r.DS_Titulo, i.DH_DataInscricao::DATE
WITH DATA;
-- Cria índice para acelerar o filtro por Nome do Evento
CREATE INDEX idx_vm_tendencia_nome ON VM_Dash2_Grafico1_TendenciaInscricoes(Nome_Evento);
-- Cria índice para ordenação temporal
CREATE INDEX idx_vm_tendencia_data ON VM_Dash2_Grafico1_TendenciaInscricoes(_Data_Ordenacao);

-- GRÁFICO 2 - Conversão Operacional
CREATE MATERIALIZED VIEW VM_Dash2_Grafico2_FunilConversao AS
WITH Resumo_Funil AS (
    SELECT 
        r.DS_Titulo AS Evento,
        -- Contagens (Count) + Joins para obter os números absolutos de cada etapa
        COUNT(i.ID_Inscricao) AS Qtd_Inscritos,
        COUNT(p.ID_Pagamento) AS Qtd_Pagantes,
        COUNT(c.ID_Certificado) AS Qtd_Certificados
    FROM TB_Registro r
    JOIN TB_Inscricao i ON r.ID_Registro = i.ID_Registro
    LEFT JOIN TB_Pagamento p ON i.ID_Inscricao = p.ID_Inscricao -- 3ª Tabela
    LEFT JOIN TB_Certificado c ON i.ID_Inscricao = c.ID_Inscricao -- 4ª Tabela
    WHERE r.TP_Registro = 'Evento'
    GROUP BY r.DS_Titulo
)
-- Transforma colunas em linhas (Unpivot manual) para facilitar o eixo X do gráfico
SELECT 
    Evento, 
    '1. Inscritos' AS Eixo_X_Etapa, 
    Qtd_Inscritos AS Eixo_Y_Valor 
FROM Resumo_Funil

UNION ALL

SELECT 
    Evento, 
    '2. Pagantes', 
    Qtd_Pagantes 
FROM Resumo_Funil

UNION ALL

SELECT 
    Evento, 
    '3. Certificados', 
    Qtd_Certificados 
FROM Resumo_Funil

ORDER BY Evento, Eixo_Y_Valor DESC
WITH DATA;
-- Cria índice para acelerar o filtro por Nome do Evento
CREATE INDEX idx_vm_funil_evento ON VM_Dash2_Grafico2_FunilConversao(Evento);


-- GRÁFICO 3 - 	Analisa a proporção da modalidade do evento
CREATE MATERIALIZED VIEW VM_Dash2_Grafico3_OcupacaoModalidade AS
SELECT 
    r.DS_Titulo AS Nome_Evento,
    i.TP_Inscricao AS Eixo_X_Modalidade,
    COUNT(i.ID_Inscricao) AS Eixo_Y_Total
FROM TB_Registro r
JOIN TB_Inscricao i ON r.ID_Registro = i.ID_Registro
JOIN TB_Usuario u ON i.ID_Usuario = u.ID_Usuario
WHERE r.TP_Registro = 'Evento'
GROUP BY r.DS_Titulo, i.TP_Inscricao
ORDER BY r.DS_Titulo, Eixo_Y_Total DESC
WITH DATA;
-- Índice para filtrar rapidamente por evento
CREATE INDEX idx_vm_ocupacao_evento ON VM_Dash2_Grafico3_OcupacaoModalidade(Nome_Evento);


-- GRÁFICO 4 - Status Financeiro
CREATE MATERIALIZED VIEW VM_Dash2_Grafico4_StatusFinanceiro AS
SELECT 
    r.DS_Titulo AS Nome_Evento, -- Coluna pivô para agrupar as barras no gráfico
    
    -- Define a categoria da pilha (Stack)
    CASE 
        WHEN p.ID_Pagamento IS NOT NULL THEN 'Pago' 
        ELSE 'Pendente' 
    END AS Eixo_X_Status,
    
    -- Define a altura da barra
    COUNT(i.ID_Inscricao) AS Eixo_Y_Qtd
    
FROM TB_Registro r
JOIN TB_Inscricao i ON r.ID_Registro = i.ID_Registro
LEFT JOIN TB_Pagamento p ON i.ID_Inscricao = p.ID_Inscricao
WHERE r.TP_Registro = 'Evento'
GROUP BY r.DS_Titulo, 
    CASE WHEN p.ID_Pagamento IS NOT NULL THEN 'Pago' ELSE 'Pendente' END
ORDER BY r.DS_Titulo, Eixo_X_Status
WITH DATA;

CREATE INDEX idx_vm_financeiro_evento ON VM_Dash2_Grafico4_StatusFinanceiro(Nome_Evento);

-- GRÁFICO 5 - Top Instituições
CREATE MATERIALIZED VIEW VM_Dash2_Grafico5_TopInstituicoes AS
SELECT 
    u.DS_Instituicao AS Eixo_X_Instituicao,
    COUNT(i.ID_Inscricao) AS Eixo_Y_Participantes
FROM TB_Usuario u
JOIN TB_Inscricao i ON u.ID_Usuario = i.ID_Usuario
JOIN TB_Registro r ON i.ID_Registro = r.ID_Registro -- 3ª Tabela
WHERE r.TP_Registro = 'Evento' 
  AND u.DS_Instituicao IS NOT NULL
GROUP BY u.DS_Instituicao
ORDER BY Eixo_Y_Participantes DESC
WITH DATA;
CREATE INDEX idx_vm_top_instituicoes_qtd ON VM_Dash2_Grafico5_TopInstituicoes(Eixo_Y_Participantes DESC);

-- GRÁFICO 6 - Demanda Atividades
CREATE MATERIALIZED VIEW VM_Dash2_Grafico6_DemandaAtividades AS
SELECT 
    evento.DS_Titulo AS Nome_Evento_Pai,
    atividade.DS_Titulo AS Eixo_X_Atividade,
    COUNT(i.ID_Inscricao) AS Eixo_Y_Inscritos
FROM TB_Registro evento
JOIN TB_Registro atividade ON atividade.ID_EventoPai = evento.ID_Registro
JOIN TB_Inscricao i ON i.ID_Registro = atividade.ID_Registro
WHERE evento.TP_Registro = 'Evento' 
  AND atividade.TP_Registro = 'Atividade'
GROUP BY evento.DS_Titulo, atividade.DS_Titulo
ORDER BY Eixo_Y_Inscritos DESC
WITH DATA;

CREATE INDEX idx_vm_demanda_qtd ON VM_Dash2_Grafico6_DemandaAtividades(Eixo_Y_Inscritos DESC);