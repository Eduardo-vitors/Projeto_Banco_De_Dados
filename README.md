# 📊 Sistema de Gestão de Eventos Acadêmicos

**Autores:** Eduardo Vitor dos Santos Silva e Silva, Elis Marcela de Souza Alcantara, Otávio Novais de Oliveira, Saulo Matos Pereira Gomes

## 🗂️ Estrutura do Sistema

### 👤 **Usuário (`TB_Usuario`)**
Cada usuário é identificado por um ID único e possui:
- CPF (único)
- E-mail (único)
- Nome completo
- Instituição de ensino
- Nível de escolaridade
- Senha (criptografada)

**Relacionamentos:**
- Pode se inscrever em múltiplos Eventos e Atividades
- Pode solicitar recuperação de senha
- Recebe certificados de participação

### 📅 **Registro (`TB_Registro`)**
Representa um evento acadêmico ou atividade associada.

**Atributos:**
- Título
- Tipo (`Evento` ou `Atividade`)
- Descrição
- Área de conhecimento
- Local
- Data de início e fim
- Valor (para eventos)
- Evento pai (para hierarquia)

**Relacionamentos:**
- Pode ter subeventos/atividades (`ID_EventoPai`)
- Recebe múltiplas inscrições
- Atividades exigem inscrição prévia no evento pai

### 📝 **Inscrição (`TB_Inscricao`)**
Registra a participação de um usuário em um evento/atividade.

**Atributos:**
- Data da inscrição
- Tipo (`Online` ou `Presencial`)
- Custo da inscrição
- Status de pagamento (`Pago`, `Pendente`, `Isento`, `Cancelado`)
- Status de presença

**Relacionamentos:**
- Vincula um usuário a um registro
- Pode gerar pagamento
- Pode gerar certificado

### 💳 **Pagamento (`TB_Pagamento`)**
Registro financeiro das inscrições.

**Atributos:**
- Data do pagamento
- Valor pago
- Método de pagamento (`PIX`, `Cartão de Crédito`, `Boleto`)
- Código da transação

### 🎓 **Certificado (`TB_Certificado`)**
Comprovação oficial de participação.

**Atributos:**
- Código de validação (hash único)
- Data de emissão

### 🔐 **Recuperação de Senha (`TB_RecuperacaoSenha`)**
Sistema seguro para redefinição de senha.

**Atributos:**
- Token único (32 caracteres)
- Data de solicitação
- Status de uso

### 📋 **Auditoria (`TB_AuditoriaCancelamento`)**
Registro de todas as operações de cancelamento.

**Atributos:**
- Timestamp da ação
- Motivo do cancelamento

## 🚀 **Requisitos Técnicos**

- **PostgreSQL** (versão 12 ou superior recomendada)
- **pgAdmin 4** ou cliente psql
- Usuário do banco com privilégios de criação (`CREATE`, `INSERT`, `REFERENCES`, etc.)

## 📁 **Sequência de Execução**

### Via pgAdmin (GUI)

1. **Conecte-se** ao servidor PostgreSQL
2. **(Opcional) Crie um novo banco de dados:**
   - Clique direito em "Databases" → "Create" → "Database..."
   - Nome sugerido: `gestao_eventos`

3. **Execute os scripts na ordem:**

| Ordem | Arquivo | Descrição |
|-------|---------|-----------|
| 1 | `1_criacao_tabelas.sql` | Cria todas as tabelas e constraints |
| 2 | `2_criacao_trigger.sql` | Cria triggers de validação |
| 3 | `3_plano_indexacao_avançado.sql` | Cria índices para performance |
| 4 | `4_popular_tabelas.sql` | Popula com dados de teste |

4. **Para funcionalidades específicas:**

| Módulo | Arquivos | Descrição |
|--------|----------|-----------|
| Autenticação | `tela1_1_funcionalidades.sql` | Login e recuperação de senha |
| Inscrições | `tela2_1_funcionalidades.sql` | Gerenciamento de inscrições |
| Dashboard Operacional | `dash2_1_consultas_graficos.sql`<br>`dash2_2_atualizar_graficos.sql` | Views para dashboards |
| Dashboard Estratégico | `dash1_1_consultas_agrupadas` | Métricas estratégicas |

### Como executar cada arquivo:

1. Selecione o banco de dados no painel esquerdo
2. Clique com o botão direito → "Query Tool"
3. Vá em **File → Open** e selecione o arquivo SQL
4. Execute com **F5** ou clique no botão ▶
5. Verifique mensagens na aba "Messages"

## 🔍 **Testes e Validações**

Cada módulo possui scripts de teste:

| Teste | Arquivo | Comando |
|-------|---------|---------|
| Autenticação | `tela1_2_rotina_de_teste.sql` | `CALL sp_loginusuario_login('00000000001', 'senha')` |
| Cancelamento | `tela2_2_rotina_de_teste.sql` | `CALL sp_realizarcancelamentoseguro(21, 9, 'motivo')` |
| Dashboards | `dash2_3_gerar_graficos.sql` | `CALL sp_atualizar_dashboard_operacional()` |
| Dashboard Estratégico | `dash1_2_gerar_graficos` | `SELECT * FROM vw_grafico_s1_novos_usuarios_pagantes_mes` |

## 📊 **Análise de Performance**

### Planos de Indexação Disponíveis:
- **Índices Compostos**: Otimizam consultas com múltiplas condições
- **Índices Parciais**: Indexam apenas subconjuntos relevantes
- **Índices para Dashboards**: Aceleram consultas analíticas

### Para analisar planos de execução no pgAdmin:
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM vm_dash2_grafico1_tendenciainscricoes;
```

## 🗑️ **Como Limpar o Banco (Estado Inicial)**

### Remover TODOS os objetos:
```sql
-- Remove todas as tabelas e objetos dependentes
DROP TABLE IF EXISTS 
    TB_Pagamento, 
    TB_Certificado, 
    TB_Inscricao, 
    TB_Registro, 
    TB_Usuario,
    TB_RecuperacaoSenha,
    TB_AuditoriaCancelamento 
CASCADE;
```

### Remover índices específicos:
```sql
-- Índices avançados
DROP INDEX IF EXISTS 
    idx_avanc_inscricao_funil,
    idx_avanc_inscricao_usuario,
    idx_avanc_registro_pai_tipo,
    idx_avanc_registro_APENAS_EVENTOS,
    idx_avanc_inscricao_APENAS_PRESENTES;

-- Views Materializadas
DROP MATERIALIZED VIEW IF EXISTS 
    vm_dash2_grafico1_tendenciainscricoes,
    vm_dash2_grafico2_funilconversao,
    vm_dash2_grafico3_ocupacaomodalidade,
    vm_dash2_grafico4_statusfinanceiro,
    vm_dash2_grafico5_topinstituicoes,
    vm_dash2_grafico6_demandaatividades,
    vm_loginusuarios,
    vm_minhasinscricoes,
    mv_dashboard_estrategico_vetores;

-- Procedures e Functions
DROP PROCEDURE IF EXISTS 
    sp_loginusuario_login,
    sp_loginusuario_recuperar,
    sp_loginusuario_atualizar,
    sp_realizarcancelamentoseguro,
    sp_atualizar_dashboard_operacional,
    sp_refresh_dashboard_estrategico;

DROP FUNCTION IF EXISTS fc_verificarinscricaoatividade;
```

## 📈 **Dashboards Implementados**

### Dashboard Operacional (6 gráficos):
1. **Tendência de Inscrições** - Evolução temporal com média móvel
2. **Funil de Conversão** - Inscritos → Pagantes → Certificados
3. **Ocupação por Modalidade** - Presencial vs Online
4. **Status Financeiro** - Pagos vs Pendentes
5. **Top Instituições** - Participação por instituição
6. **Demanda de Atividades** - Atividades mais populares

### Dashboard Estratégico (4 gráficos):
1. **Novos Usuários Pagantes** - Crescimento da base
2. **Ticket Médio Mensal** - Valor médio por pagamento
3. **Receita por Método** - Distribuição por forma de pagamento
4. **Taxa de Conversão** - Eficiência por evento


**Desenvolvido para disciplina de Banco de Dados**  
🎓 *Sistema completo de gestão acadêmica com foco em performance e usabilidade*
