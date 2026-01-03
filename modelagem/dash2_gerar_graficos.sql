CALL sp_Atualizar_Dashboard_Analitico();
SELECT * FROM mv_Grafico1_Tendencia; -- Line
SELECT * FROM mv_grafico2_funil; -- Bar Chart
SELECT * FROM mv_grafico3_modalidade; -- Pie chart
SELECT * FROM mv_grafico4_financeiro; -- stacked bar chart
SELECT * FROM mv_grafico5_instituicoes; -- bar chart
SELECT * FROM mv_grafico6_atividades; -- bar chart