-- TESTE TELA 1

-- 1: Exibe login do usuário
SELECT * FROM public.vm_loginusuarios
WHERE CD_CPF = '00000000001'

-- 2: Realiza o login 
CALL public.sp_loginusuario_login(
	'00000000001',
	'Senha_00000000001'
)

-- 3: Solicita alteração de senha
CALL public.sp_loginusuario_recuperar(
	'00000000001',
	'usuario1@exemplo.com'
)

-- 4: Busca o Token Gerado
SELECT *
FROM TB_RecuperacaoSenha rs
JOIN TB_Usuario u ON rs.ID_Usuario = u.ID_Usuario
WHERE u.CD_CPF = '00000000001'
ORDER BY DH_Solicitacao DESC;

-- 5: Altera senha com token
CALL public.sp_loginusuario_atualizar(
	'00000000001',
	'novasenha123',
	'7c21faa50a579915e0c62b0829c81fdb'
)