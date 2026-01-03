-- ============================================
-- TELA 1 - (LOGIN / RECUPERAR / ATUALIZAR)
-- ============================================

-- TABELA RECUPERACAO SENHA
CREATE TABLE IF NOT EXISTS TB_RecuperacaoSenha (
    ID_Recuperacao SERIAL PRIMARY KEY,
    ID_Usuario INTEGER REFERENCES TB_Usuario(ID_Usuario),
    CD_Token VARCHAR(32),
    DH_Solicitacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ST_Usado BOOLEAN DEFAULT FALSE
);

-- CRIAR MATERIALIZED VIEW
CREATE MATERIALIZED VIEW VM_LoginUsuarios AS
SELECT 
    ID_Usuario,
    CD_CPF,
    DS_Senha,
    DS_Email,
    DS_Nome
FROM TB_Usuario
WHERE CD_CPF IS NOT NULL 
  AND DS_Senha IS NOT NULL;

-- Índice único na MV
DROP INDEX IF EXISTS idx_vm_login_cpf;
CREATE UNIQUE INDEX idx_vm_login_cpf ON VM_LoginUsuarios (CD_CPF);


-- STORED PROCEDURE #1 - LOGIN
DROP PROCEDURE IF EXISTS SP_LoginUsuario_Login;

CREATE OR REPLACE PROCEDURE SP_LoginUsuario_Login(
    p_cpf         VARCHAR(20),
    p_senha_atual VARCHAR(120),
    INOUT p_resultado VARCHAR(200) DEFAULT ''
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario_id INTEGER;
    v_senha_db   VARCHAR(120);
    v_nome_db    VARCHAR(100);
BEGIN
    -- Normaliza CPF (somente dígitos)
    p_cpf := regexp_replace(COALESCE(p_cpf, ''), '[^0-9]', '', 'g');

    -- Validação de CPF
    IF p_cpf = '' THEN
        p_resultado := 'CPF inválido';
        RETURN;
    END IF;

    -- 1 SELECT (login)
    SELECT ID_Usuario, DS_Senha, DS_Nome
      INTO v_usuario_id, v_senha_db, v_nome_db
      FROM VM_LoginUsuarios
     WHERE CD_CPF = p_cpf;

    IF v_usuario_id IS NULL THEN
        p_resultado := 'CPF não encontrado';
    ELSIF p_senha_atual = v_senha_db THEN
        p_resultado := 'Login OK - Usuário: ' || v_nome_db;
    ELSE
        p_resultado := 'Senha incorreta';
    END IF;
END;
$$;

-- STORED PROCEDURE #2 - RECUPERAR SENHA (gera token)
DROP PROCEDURE IF EXISTS SP_LoginUsuario_Recuperar;

CREATE OR REPLACE PROCEDURE SP_LoginUsuario_Recuperar(
    p_cpf   VARCHAR(20),
    p_email VARCHAR(100),
    INOUT p_resultado VARCHAR(200) DEFAULT ''
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario_id INTEGER;
    v_token      VARCHAR(32);
BEGIN
    -- Normaliza CPF (somente dígitos)
    p_cpf := regexp_replace(COALESCE(p_cpf, ''), '[^0-9]', '', 'g');

    -- Validação de CPF
    IF p_cpf = '' THEN
        p_resultado := 'CPF inválido';
        RETURN;
    END IF;

    -- SELECT (confere CPF + email)
    SELECT ID_Usuario
      INTO v_usuario_id
      FROM VM_LoginUsuarios
     WHERE CD_CPF = p_cpf
       AND DS_Email = p_email;

    IF v_usuario_id IS NULL THEN
        p_resultado := 'CPF ou email incorretos';
        RETURN;
    END IF;

    -- Gera token
    v_token := md5(p_cpf || now()::text || random()::text);

    -- UPDATE (invalida tokens antigos não usados)
    UPDATE TB_RecuperacaoSenha
       SET ST_Usado = TRUE
     WHERE ID_Usuario = v_usuario_id
       AND ST_Usado = FALSE;

    -- INSERT (token novo)
    INSERT INTO TB_RecuperacaoSenha (ID_Usuario, CD_Token)
    VALUES (v_usuario_id, v_token);

    p_resultado := 'Token gerado: ' || v_token || ' (válido por 30 minutos)';
END;
$$;

-- STORED PROCEDURE #3 - ATUALIZAR SENHA (exige token válido)
DROP PROCEDURE IF EXISTS SP_LoginUsuario_Atualizar;

CREATE OR REPLACE PROCEDURE SP_LoginUsuario_Atualizar(
    p_cpf        VARCHAR(20),
    p_senha_nova VARCHAR(120),
    p_token      VARCHAR(32),
    INOUT p_resultado VARCHAR(200) DEFAULT ''
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario_id INTEGER;
BEGIN
    -- Normaliza CPF (somente dígitos)
    p_cpf := regexp_replace(COALESCE(p_cpf, ''), '[^0-9]', '', 'g');

    -- Validação de CPF
    IF p_cpf = '' THEN
        p_resultado := 'CPF inválido';
        RETURN;
    END IF;

    -- SELECT (confere se CPF existe)
    SELECT ID_Usuario
      INTO v_usuario_id
      FROM TB_Usuario
     WHERE CD_CPF = p_cpf;

    IF v_usuario_id IS NULL THEN
        p_resultado := 'CPF não encontrado';
        RETURN;
    END IF;

    IF p_senha_nova IS NULL OR p_senha_nova = '' THEN
        p_resultado := 'Senha nova inválida';
        RETURN;
    END IF;

    -- Token obrigatório
    IF p_token IS NULL OR p_token = '' THEN
        p_resultado := 'Token obrigatório para atualizar a senha';
        RETURN;
    END IF;

    -- Valida token: pertence ao usuário, não usado e recente (30 min)
    IF NOT EXISTS (
        SELECT 1
          FROM TB_RecuperacaoSenha r
         WHERE r.ID_Usuario = v_usuario_id
           AND r.CD_Token = p_token
           AND r.ST_Usado = FALSE
           AND r.DH_Solicitacao >= (NOW() - INTERVAL '30 minutes')
    ) THEN
        p_resultado := 'Token inválido, expirado ou já utilizado';
        RETURN;
    END IF;

    -- UPDATE senha
    UPDATE TB_Usuario
       SET DS_Senha = p_senha_nova
     WHERE ID_Usuario = v_usuario_id;

    -- Marca token como usado
    UPDATE TB_RecuperacaoSenha
       SET ST_Usado = TRUE
     WHERE ID_Usuario = v_usuario_id
       AND CD_Token = p_token;

    -- Atualiza MV para refletir a nova senha
    REFRESH MATERIALIZED VIEW VM_LoginUsuarios;

    p_resultado := 'Senha atualizada com sucesso (via token)';
END;
$$;