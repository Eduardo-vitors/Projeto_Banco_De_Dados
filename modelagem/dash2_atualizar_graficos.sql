CREATE OR REPLACE PROCEDURE sp_Atualizar_Dashboard_Analitico()
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Atualiza a Fonte de Verdade (Nível 1)
    REFRESH MATERIALIZED VIEW mv_Base_Analitica;
    
    -- 2. Atualiza as Visualizações (Nível 2)
    -- Feito de forma sequencial para garantir consistência
    REFRESH MATERIALIZED VIEW mv_Grafico1_Tendencia;
    REFRESH MATERIALIZED VIEW mv_Grafico2_Funil;
    REFRESH MATERIALIZED VIEW mv_Grafico3_Modalidade;
    REFRESH MATERIALIZED VIEW mv_Grafico4_Financeiro;
    REFRESH MATERIALIZED VIEW mv_Grafico5_Instituicoes;
    REFRESH MATERIALIZED VIEW mv_Grafico6_Atividades;
    
    RAISE NOTICE 'Dashboard atualizado com sucesso em: %', NOW();
END;
$$;