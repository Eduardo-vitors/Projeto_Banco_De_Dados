TRUNCATE TABLE TB_Pagamento, TB_Certificado, TB_Inscricao, TB_Registro, TB_Usuario 
RESTART IDENTITY CASCADE;

DO $$
DECLARE
    v_user_record RECORD;
    v_activity_record RECORD;
    
    v_event_id INT;
    v_event_start TIMESTAMP; -- Nova variável para validar data do evento
    v_num_events_user INT;
    v_num_activities_user INT;
    
    v_all_event_ids INT[];
    v_valor_evento DECIMAL;
BEGIN

    -- 1) TB_Usuario (5.000) COM SENHA
    RAISE NOTICE 'Gerando Usuários...';
    INSERT INTO TB_Usuario (
        CD_CPF, DS_Email, DS_Nome, DS_Instituicao, DS_Escolaridade, DS_Senha
    )
    SELECT
        LPAD(s::text, 11, '0'),
        'usuario' || s || '@exemplo.com',
        'Nome ' || (ARRAY['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fábio', 'Gabriela'])[1 + floor(random() * 7)] || ' ' || 
        (ARRAY['Silva', 'Souza', 'Pereira', 'Costa', 'Alves', 'Lima', 'Santos'])[1 + floor(random() * 7)] || ' ' || s,
        CASE 
            WHEN random() < 0.45 THEN 'Universidade Federal da Bahia'
            WHEN random() < 0.75 THEN 'Instituto Federal da Bahia'
            WHEN random() < 0.90 THEN 'Universidade Católica'
            ELSE 'Universidade Estadual da Bahia'
        END,
        CASE 
            WHEN random() < 0.40 THEN 'Superior Incompleto'
            WHEN random() < 0.75 THEN 'Superior Completo'
            WHEN random() < 0.95 THEN 'Mestrado'
            ELSE 'Doutorado'
        END,
        'Senha_' || LPAD(s::text, 11, '0')
    FROM generate_series(1, 5000) s;


    -- 2) TB_Registro (EVENTOS) - MIX DE PASSADO E FUTURO
    -- Usamos CURRENT_TIMESTAMP +/- INTERVAL para garantir dinamismo sempre que rodar o script
    RAISE NOTICE 'Gerando Eventos (Passados e Futuros)...';
    INSERT INTO TB_Registro (
        ID_EventoPai, TP_Registro, DS_Titulo, VL_ValorEvento, DS_Descricao, DS_Local, DH_Inicio, DH_Fim, TP_Area
    )
    VALUES
        -- Eventos PASSADOS (Para gerar histórico, presença e certificados)
        (NULL, 'Evento', 'Congresso de Tecnologia (Edição Passada)', 200.00, '...', 'Centro de Convenções A', 
         CURRENT_TIMESTAMP - INTERVAL '2 months', 
         CURRENT_TIMESTAMP - INTERVAL '2 months' + INTERVAL '3 days', 'TI'),
         
        (NULL, 'Evento', 'Semana Acadêmica de IA (Edição Passada)', 150.00, '...', 'Auditório Reitoria', 
         CURRENT_TIMESTAMP - INTERVAL '1 month', 
         CURRENT_TIMESTAMP - INTERVAL '1 month' + INTERVAL '2 days', 'IA'),

        -- Eventos FUTUROS (Para planejamento e testes de datas futuras)
        (NULL, 'Evento', 'Simpósio de Redes e Segurança 2026', 180.00, '...', 'Prédio de Engenharia', 
         CURRENT_TIMESTAMP + INTERVAL '15 days', 
         CURRENT_TIMESTAMP + INTERVAL '16 days', 'Redes'),
         
        (NULL, 'Evento', 'Feira de Hardware e Robótica 2026', 120.00, '...', 'Ginásio de Esportes', 
         CURRENT_TIMESTAMP + INTERVAL '2 months', 
         CURRENT_TIMESTAMP + INTERVAL '2 months' + INTERVAL '2 days', 'Hardware'),
         
        (NULL, 'Evento', 'Workshop Avançado de Programação', 100.00, '...', 'Laboratório 301', 
         CURRENT_TIMESTAMP + INTERVAL '3 months', 
         CURRENT_TIMESTAMP + INTERVAL '3 months' + INTERVAL '1 day', 'TI');

    v_all_event_ids := ARRAY(SELECT ID_Registro FROM TB_Registro WHERE TP_Registro = 'Evento');

    -- 2.1) TB_Registro (ATIVIDADES)
    -- As datas das atividades são calculadas baseadas na data do pai, então elas acompanharão automaticamente o futuro/passado
    FOR v_event_id IN SELECT * FROM unnest(v_all_event_ids) LOOP
        v_num_activities_user := floor(random() * 11)::INT; -- 0..10
        IF v_num_activities_user > 0 THEN
            INSERT INTO TB_Registro (
                ID_EventoPai, TP_Registro, DS_Titulo, VL_ValorEvento, DS_Descricao, DS_Local, DH_Inicio, DH_Fim, TP_Area
            )
            SELECT 
                v_event_id,
                'Atividade',
                'Atividade Tópico ' || s,
                0.00,
                '...',
                'Sala ' || (100 + s),
                (SELECT DH_Inicio FROM TB_Registro WHERE ID_Registro = v_event_id) + (s * '1 hour'::interval),
                (SELECT DH_Inicio FROM TB_Registro WHERE ID_Registro = v_event_id) + ((s + 1) * '1 hour'::interval),
                (SELECT TP_Area FROM TB_Registro WHERE ID_Registro = v_event_id)
            FROM generate_series(1, v_num_activities_user) s;
        END IF;
    END LOOP;


    -- 3) TB_Inscricao
    RAISE NOTICE 'Gerando Inscrições...';
    FOR v_user_record IN SELECT ID_Usuario FROM TB_Usuario LOOP

        v_num_events_user := floor(random() * 4)::INT; -- 0..3
        IF v_num_events_user > 0 THEN

            FOR i IN 1..v_num_events_user LOOP
                
                v_event_id := v_all_event_ids[1 + floor(random() * array_length(v_all_event_ids, 1))];
                
                -- Captura Valor E DATA DE INICIO do evento para validação lógica
                SELECT VL_ValorEvento, DH_Inicio 
                  INTO v_valor_evento, v_event_start
                  FROM TB_Registro 
                 WHERE ID_Registro = v_event_id;

                -- Inscrição no EVENTO
                INSERT INTO TB_Inscricao (
                    ID_Registro, ID_Usuario, DH_DataInscricao, TP_Inscricao, 
                    ST_Pagamento, VL_CustoInscricao, ST_Presente
                )
                VALUES (
                    v_event_id, 
                    v_user_record.ID_Usuario, 
                    NOW() - (random()*30 + 1) * '1 day'::interval, 
                    (ARRAY['Online', 'Presencial'])[1 + floor(random()*2)],
                    CASE WHEN random() < 0.6 THEN 'Pago' WHEN random() < 0.85 THEN 'Pendente' ELSE 'Isento' END,
                    COALESCE(v_valor_evento, 0),
                    -- REGRA DE NEGÓCIO: Só pode estar PRESENTE se o evento já aconteceu (Data < NOW)
                    CASE 
                        WHEN v_event_start < NOW() THEN (random() < 0.65) -- Sorteio normal para eventos passados
                        ELSE FALSE -- Impossível estar presente no futuro
                    END
                )
                ON CONFLICT (id_registro, id_usuario) DO NOTHING;

                -- Inscrições em ATIVIDADES
                v_num_activities_user := floor(random() * 3)::INT;
                IF v_num_activities_user > 0 THEN
                    FOR v_activity_record IN 
                        SELECT ID_Registro FROM TB_Registro 
                        WHERE ID_EventoPai = v_event_id 
                        ORDER BY random() 
                        LIMIT v_num_activities_user 
                    LOOP
                        INSERT INTO TB_Inscricao (
                            ID_Registro, ID_Usuario, DH_DataInscricao, TP_Inscricao, 
                            ST_Pagamento, VL_CustoInscricao, ST_Presente
                        )
                        VALUES (
                            v_activity_record.ID_Registro, v_user_record.ID_Usuario, NOW() - (random()*30 + 1) * '1 day'::interval,
                            (ARRAY['Online', 'Presencial'])[1 + floor(random()*2)],
                            'Isento', 0.00,
                            -- Mesma Regra: Presença apenas se o evento pai já começou
                            CASE 
                                WHEN v_event_start < NOW() THEN (random() < 0.8) 
                                ELSE FALSE 
                            END
                        )
                        ON CONFLICT (id_registro, id_usuario) DO NOTHING;
                    END LOOP;
                END IF;

            END LOOP;
        END IF;
    END LOOP;


    -- 4) TB_Pagamento
    RAISE NOTICE 'Gerando Pagamentos...';
    INSERT INTO TB_Pagamento (
        ID_Inscricao, DH_DataPagamento, VL_ValorPago, TP_MetodoPagamento, CD_Transacao
    )
    SELECT 
        I.ID_Inscricao, 
        I.DH_DataInscricao + (random() * 3 + 1) * '1 hour'::interval, 
        (CASE 
            WHEN random() < 0.7 THEN I.VL_CustoInscricao
            WHEN random() < 0.9 THEN I.VL_CustoInscricao * 0.5
            ELSE I.VL_CustoInscricao * 0.75
        END)::DECIMAL(10,2),
        CASE         
            WHEN random() < 0.5 THEN 'PIX' 
            WHEN random() < 0.85 THEN 'Cartão de Crédito' 
            ELSE 'Boleto' 
        END,
        'TRX_' || MD5(I.ID_Inscricao::text || NOW()::text)
    FROM TB_Inscricao I
    WHERE I.ST_Pagamento = 'Pago';


    -- 5) TB_Certificado
    -- Nota: A cláusula 'WHERE I.ST_Presente = true' garante automaticamente que
    -- certificados só serão gerados para os eventos PASSADOS configurados acima.
    RAISE NOTICE 'Gerando Certificados...';
    INSERT INTO TB_Certificado (
        ID_Inscricao, CD_Validacao, DH_Emissao
    )
    SELECT
        I.ID_Inscricao,
        MD5(I.ID_Usuario::text || I.ID_Registro::text || R.DH_Fim::text),
        R.DH_Fim + '1 day'::interval
    FROM TB_Inscricao I
    JOIN TB_Registro R ON I.ID_Registro = R.ID_Registro
    WHERE I.ST_Presente = true;

END $$;

-- Conferência Final
SELECT 'TB_Usuario' AS tabela, COUNT(*) FROM TB_Usuario
UNION ALL
SELECT 'TB_Registro', COUNT(*) FROM TB_Registro
UNION ALL
SELECT 'TB_Inscricao', COUNT(*) FROM TB_Inscricao
UNION ALL
SELECT 'TB_Pagamento', COUNT(*) FROM TB_Pagamento
UNION ALL
SELECT 'TB_Certificado', COUNT(*) FROM TB_Certificado;