-- Gráfico 1 - Line
CREATE MATERIALIZED VIEW mv_Grafico1_Tendencia AS
SELECT 
    DS_Titulo AS Nome_Evento,
    TO_CHAR(DH_DataInscricao::DATE, 'YYYY-MM-DD') AS Eixo_X_Data,
    
    COUNT(ID_Inscricao) AS Eixo_Y_Qtd,
    
    ROUND(AVG(COUNT(ID_Inscricao)) OVER (
        PARTITION BY ID_Registro 
        ORDER BY DH_DataInscricao::DATE 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS Eixo_Y_MediaMovel
    
FROM mv_Base_Analitica
WHERE TP_Registro = 'Evento'
GROUP BY ID_Registro, DS_Titulo, DH_DataInscricao::DATE
ORDER BY DS_Titulo, Eixo_X_Data
WITH DATA;

-- Gráfico 2 - Bar Chart
CREATE MATERIALIZED VIEW mv_Grafico2_Funil AS
SELECT 
    b.DS_Titulo AS Nome_Evento,
    Etapa.Nome AS Eixo_X_Etapa,
    Etapa.Qtd AS Eixo_Y_Valor
FROM (
    SELECT DISTINCT ID_Registro, DS_Titulo FROM mv_Base_Analitica WHERE TP_Registro = 'Evento'
) b,
LATERAL (
    VALUES 
        ('1. Inscritos', (SELECT COUNT(*) FROM mv_Base_Analitica WHERE ID_Registro = b.ID_Registro)),
        ('2. Pagantes',  (SELECT COUNT(*) FROM mv_Base_Analitica WHERE ID_Registro = b.ID_Registro AND Status_Financeiro = 'Pago')),
        ('3. Presentes', (SELECT COUNT(*) FROM mv_Base_Analitica WHERE ID_Registro = b.ID_Registro AND ST_Presente = TRUE))
) AS Etapa(Nome, Qtd)
WITH DATA;

-- Gráfico 3
CREATE MATERIALIZED VIEW mv_Grafico3_Modalidade AS
SELECT 
    Modalidade AS Eixo_X_Label,
    COUNT(ID_Inscricao) AS Eixo_Y_Valor
FROM mv_Base_Analitica
WHERE TP_Registro = 'Evento'
GROUP BY Modalidade
WITH DATA;

-- Gráfico 4
CREATE MATERIALIZED VIEW mv_Grafico4_Financeiro AS
SELECT 
    DS_Titulo AS Eixo_X_Evento,
    COUNT(*) FILTER (WHERE Status_Financeiro = 'Pago') AS Eixo_Y_Pago,
    COUNT(*) FILTER (WHERE Status_Financeiro = 'Pendente') AS Eixo_Y_Pendente
FROM mv_Base_Analitica
WHERE TP_Registro = 'Evento'
GROUP BY DS_Titulo
WITH DATA;

-- Gráfico 5
CREATE MATERIALIZED VIEW mv_Grafico5_Instituicoes AS
SELECT 
    DS_Instituicao AS Eixo_X_Instituicao,
    COUNT(ID_Inscricao) AS Eixo_Y_Qtd
FROM mv_Base_Analitica
WHERE TP_Registro = 'Evento' AND DS_Instituicao IS NOT NULL
GROUP BY DS_Instituicao
ORDER BY Eixo_Y_Qtd DESC
LIMIT 5
WITH DATA;

-- Gráfico 6
CREATE MATERIALIZED VIEW mv_Grafico6_Atividades AS
SELECT 
    DS_Titulo AS Eixo_X_Atividade,
    COUNT(ID_Inscricao) AS Eixo_Y_Inscritos
FROM mv_Base_Analitica
WHERE TP_Registro = 'Atividade'
GROUP BY DS_Titulo
ORDER BY Eixo_Y_Inscritos DESC
LIMIT 10
WITH DATA;