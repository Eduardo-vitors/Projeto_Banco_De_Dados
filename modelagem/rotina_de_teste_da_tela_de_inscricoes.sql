-- EXECUTE A QUERY PASSO A PASSO E SUBSTITUA OS VALORES CORRETAMENTE

-- 1. Verifica Evento que ainda não ocorreu e busca um usuário que está Inscrito
REFRESH MATERIALIZED VIEW VM_MinhasInscricoes;
SELECT 
    mi.ID_Inscricao,
    mi.ID_Usuario,
    mi.Nome_Evento,
    mi.Data_Inicio,
    mi.Status_Atual
FROM public.VM_MinhasInscricoes mi
WHERE 
    -- Filtra para pegar apenas inscrições do PRÓXIMO evento futuro
    mi.ID_Evento = (
        SELECT ID_Registro
        FROM TB_REGISTRO
        WHERE TP_Registro = 'Evento' 
          AND DH_Inicio > CURRENT_TIMESTAMP
        ORDER BY DH_Inicio ASC
        LIMIT 1
    )
    -- Garante que seja uma inscrição Paga (ideal para testar cancelamento/estorno)
    AND mi.Status_Atual = 'Pago'
LIMIT 1;

-- 2. Solicita cancelamento de um evento específico
CALL public.sp_realizarcancelamentoseguro(
	'21', -- id inscrição
	'9', -- id usuário
	''
);

-- 3. Consulta LOG
SELECT * FROM TB_AuditoriaCancelamento
WHERE ID_Inscricao = 21; -- id inscrição
