SELECT ID_Usuario FROM TB_Inscricao
WHERE ID_Registro = (
	SELECT ID_Registro
	FROM TB_REGISTRO
	WHERE
		TP_Registro = 'Evento'
		AND DH_Inicio > CURRENT_TIMESTAMP
	ORDER BY DH_Inicio ASC
	LIMIT 1
);

-- 1. Verifica Eventos que o usuário está Inscrito
SELECT mi.* FROM public.vm_minhasinscricoes mi
JOIN TB_USUARIO u ON mi.ID_Usuario = u.ID_Usuario
WHERE u.CD_CPF = '000000000008'

-- 2. Solicita cancelamento de um evento específico
CALL public.sp_realizarcancelamentoseguro(
	'1', -- id inscrição
	'1', -- id usuário
	''
)

