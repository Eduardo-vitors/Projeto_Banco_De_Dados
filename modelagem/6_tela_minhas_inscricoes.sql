-- MATERIALIZED VIEW - MINHAS INSCRIÇÕES
CREATE MATERIALIZED VIEW VM_MinhasInscricoes AS
SELECT 
    i.ID_Usuario AS ID_Usuario,               
    i.ID_Inscricao AS ID_Inscricao,             
    r.ID_Registro AS ID_Evento,
    r.DS_Titulo AS Nome_Evento,
    r.DH_Inicio AS Data_Inicio,
    r.DS_Local AS Localizacao,
    i.TP_Inscricao AS Modalidade,
    i.ST_Pagamento AS Status_Atual,
    i.VL_CustoInscricao AS Valor_Pago,
    
    -- Verifica se o evento já iniciou
    CASE 
        WHEN r.DH_Inicio < NOW() THEN TRUE 
        ELSE FALSE 
    END AS Evento_Ja_Ocorreu,

    -- Verifica se o usuário pode cancelar inscrição no evento - 48h antecedência
    CASE 
        WHEN r.DH_Inicio > (NOW() + INTERVAL '2 days') AND i.ST_Pagamento != 'Cancelado' THEN TRUE
        ELSE FALSE
    END AS Pode_Cancelar
	
-- Lista apenas os Eventos
FROM TB_Inscricao i
JOIN TB_Registro r ON i.ID_Registro = r.ID_Registro
WHERE r.TP_Registro = 'Evento'
WITH DATA;

-- Índice para filtrar por usuário
CREATE INDEX idx_vm_minhas_inscricoes_user ON VM_MinhasInscricoes(ID_Usuario);

-- STORED PROCEDURE - CANCELAMENTO SEGURO + AUDITORIA
CREATE OR REPLACE PROCEDURE sp_RealizarCancelamentoSeguro(
    IN p_ID_Inscricao INT,
    IN p_ID_Usuario INT,
    IN p_Motivo VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ID_Usuario_Dono INT;
    v_Status_Pagamento VARCHAR(50);
    v_Data_Inicio_Evento TIMESTAMP;
	v_Tipo_Registro VARCHAR(50);
BEGIN
    -- BUSCA DE DADOS (Dono e Status)
    SELECT 
        i.ID_Usuario, 
        i.ST_Pagamento, 
        r.DH_Inicio,
		r.TP_Registro
    INTO 
        v_ID_Usuario_Dono, 
        v_Status_Pagamento, 
        v_Data_Inicio_Evento,
		v_Tipo_Registro
    FROM TB_Inscricao i
    JOIN TB_Registro r ON i.ID_Registro = r.ID_Registro
    WHERE i.ID_Inscricao = p_ID_Inscricao;

	-- VALIDAÇÕES
	-- Valida se a inscrição existe
    IF v_ID_Usuario_Dono IS NULL THEN
        RAISE EXCEPTION 'Inscrição não encontrada (ID: %).', p_ID_Inscricao;
    END IF;

	-- Valida se é um Evento
    IF v_Tipo_Registro <> 'Evento' THEN
        RAISE EXCEPTION 'Operação inválida: O cancelamento direto só é permitido para Eventos principais.';
    END IF;

	-- Valida Propriedade
    IF v_ID_Usuario_Dono <> p_ID_Usuario THEN
        RAISE EXCEPTION 'Acesso negado: Você não tem permissão para cancelar esta inscrição.';
    END IF;

	-- Valida Status Atual
    IF v_Status_Pagamento = 'Cancelado' THEN
        RAISE EXCEPTION 'Esta inscrição já encontra-se cancelada.';
    END IF;

	-- Valida Prazo
    IF v_Data_Inicio_Evento < (CURRENT_TIMESTAMP + INTERVAL '48' HOUR) THEN
        RAISE EXCEPTION 'Cancelamento não permitido: O prazo limite de 48h expirou.';
    END IF;

	-- EXECUÇÃO
	-- Soft Delete
    UPDATE TB_Inscricao 
    SET ST_Pagamento = 'Cancelado',
        ST_Presente = FALSE
    WHERE ID_Inscricao = p_ID_Inscricao;

    -- Log de Auditoria
    INSERT INTO TB_AuditoriaCancelamento (
        ID_Inscricao, 
        ID_Usuario,
        DS_Motivo
    ) VALUES (
        p_ID_Inscricao,
        p_ID_Usuario,
        p_Motivo
    );
	RAISE NOTICE 'Sucesso: Inscrição % cancelada.', p_ID_Inscricao;
END;
$$;