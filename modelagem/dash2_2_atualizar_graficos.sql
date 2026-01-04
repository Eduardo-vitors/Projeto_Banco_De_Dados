CREATE OR REPLACE PROCEDURE SP_Atualizar_Dashboard_Operacional()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW vm_dash2_grafico1_tendenciainscricoes;
    REFRESH MATERIALIZED VIEW vm_dash2_grafico2_funilconversao;
    REFRESH MATERIALIZED VIEW vm_dash2_grafico3_ocupacaomodalidade;
    REFRESH MATERIALIZED VIEW vm_dash2_grafico4_statusfinanceiro;
    REFRESH MATERIALIZED VIEW vm_dash2_grafico5_topinstituicoes;
    REFRESH MATERIALIZED VIEW vm_dash2_grafico6_demandaatividades;
    
    RAISE NOTICE 'Dashboard 2 atualizado com sucesso em: %', NOW();
END;
$$;