CREATE FUNCTION FC_VerificarInscricaoAtividade()
RETURNS TRIGGER AS $$
DECLARE
    v_TipoRegistro VARCHAR;
    v_ID_Evento_Pai INT;
    v_InscricaoPaiCount INT;
BEGIN
    
    SELECT 
        TP_Registro,
        ID_EventoPai
    INTO 
        v_TipoRegistro,
        v_ID_Evento_Pai
    FROM 
        TB_Registro
    WHERE 
        ID_Registro = NEW.ID_Registro; -- 'NEW.ID_Registro' é o ID do registro da nova inscrição

    IF v_TipoRegistro = 'Atividade' THEN

        IF v_ID_Evento_Pai IS NULL THEN
            RAISE EXCEPTION 'Erro de integridade de dados: A Atividade (ID: %) não possui um Evento pai (ID_EventoPai) associado.', NEW.ID_Registro;
        END IF;

        SELECT 
            COUNT(*)
        INTO
            v_InscricaoPaiCount
        FROM 
            TB_Inscricao
        WHERE 
            ID_Usuario = NEW.ID_Usuario 
            AND ID_Registro = v_ID_Evento_Pai;

        IF v_InscricaoPaiCount = 0 THEN
            RAISE EXCEPTION 'Inscrição bloqueada: O usuário (ID: %) deve estar inscrito no Evento principal (ID: %) antes de se inscrever na Atividade (ID: %).',
            NEW.ID_Usuario, v_ID_Evento_Pai, NEW.ID_Registro;
        END IF;
        
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TG_AntesDeInserirInscricao
BEFORE INSERT ON TB_Inscricao
FOR EACH ROW
EXECUTE FUNCTION FC_VerificarInscricaoAtividade();