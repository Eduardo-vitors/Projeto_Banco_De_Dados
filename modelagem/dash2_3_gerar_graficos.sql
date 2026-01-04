-- Atualizar dados do Dashboard Operacional
CALL sp_Atualizar_Dashboard_Operacional();

-- GRÁFICO 1
SELECT 
    eixo_x_data, 
    eixo_y_qtd_diaria, -- Linha 1 do gráfico (Valores Brutos)
    eixo_y_media_movel -- Linha 2 do gráfico (Tendência Suavizada)
FROM public.vm_dash2_grafico1_tendenciainscricoes
WHERE nome_evento = 'Congresso de Tecnologia (Edição Passada)'
ORDER BY _data_ordenacao;

-- GRÁFICO 2 
SELECT 
    Eixo_X_Etapa,
    Eixo_Y_Valor
FROM VM_Dash2_Grafico2_FunilConversao
WHERE Evento = 'Congresso de Tecnologia (Edição Passada)' -- nome do evento que quer agregar as informações
ORDER BY Eixo_Y_Valor DESC;

-- GRÁFICO 3
SELECT 
    Eixo_X_Modalidade, 
    Eixo_Y_Total 
FROM VM_Dash2_Grafico3_OcupacaoModalidade
WHERE Nome_Evento = 'Congresso de Tecnologia (Edição Passada)';

-- GRÁFICO 4
SELECT nome_evento, eixo_x_status, eixo_y_qtd
FROM public.vm_dash2_grafico4_statusfinanceiro;

-- GRÁFICO 5
SELECT * FROM vm_dash2_grafico5_topinstituicoes;

-- GRÁFICO 6
-- Exemplo 1: Atividades com mais demandas (Geral)
SELECT Eixo_X_Atividade, Eixo_Y_Inscritos 
FROM vm_dash2_grafico6_demandaatividades
LIMIT 10;

-- Exemplo 2: Atividades com mais demandas (por Evento)
SELECT Eixo_X_Atividade, Eixo_Y_Inscritos 
FROM vm_dash2_grafico6_demandaatividades
WHERE Nome_Evento_Pai = 'Semana Acadêmica de IA (Edição Passada)'
LIMIT 5;