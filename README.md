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

## 💻 **Telas Implementadas**

### Autenticação e Gestão de Credenciais
- Funcionalidade de Login
- Solicitar alteração da senha
- Alterar a senha

### Gestão de Inscrições e Cancelamento Seguro
- Visualizar inscrições em eventos
- Solicitar o cancelamento de uma inscrição

## 📈 **Dashboards Implementados**

### Dashboard Estratégico (4 gráficos):
1. **Novos Usuários Pagantes** - Crescimento da base
2. **Ticket Médio Mensal** - Valor médio por pagamento
3. **Receita por Método** - Distribuição por forma de pagamento
4. **Taxa de Conversão** - Eficiência por evento

### Dashboard Operacional (6 gráficos):
1. **Tendência de Inscrições** - Evolução temporal com média móvel
2. **Funil de Conversão** - Inscritos → Pagantes → Certificados
3. **Ocupação por Modalidade** - Presencial vs Online
4. **Status Financeiro** - Pagos vs Pendentes
5. **Top Instituições** - Participação por instituição
6. **Demanda de Atividades** - Atividades mais populares

## 📋 Arquivos Necessários
Certifique-se de ter todos os arquivos abaixo salvos na mesma pasta:

### Infraestrutura Base:
- `1_criacao_tabelas.sql`
- `2_criacao_trigger.sql`
- `3_plano_indexacao_avançado.sql`
- `4_popular_tabelas.sql`

### Funcionalidades (Telas):
- `tela1_1_funcionalidades.sql` & `tela1_2_rotina_de_teste.sql`
- `tela2_1_funcionalidades.sql` & `tela2_2_rotina_de_teste.sql`

### Dashboards:
- `dash1_1_consultas_agrupadas.sql` (Núcleo do Dash Estratégico)
- `dash1_2_gerar_graficos.sql` (Visualização do Dash Estratégico)
- `dash2_1_consultas_graficos.sql` (Núcleo do Dash Operacional)
- `dash2_2_atualizar_graficos.sql` (Automação do Dash Operacional)
- `dash2_3_gerar_graficos.sql` (Rotina de Visualização)

## 🚀 Ordem de Execução (Passo a Passo)
### FASE 1: Infraestrutura Base
- Execute `1_criacao_tabelas.sql`.
- Execute `2_criacao_trigger.sql`.
- Execute `3_plano_indexacao_avançado.sql`.
- Execute `4_popular_tabelas.sql`.

### FASE 2: Funcionalidades das Telas
- Execute `tela1_1_funcionalidades.sql`.
- Execute `tela2_1_funcionalidades.sql`.

### FASE 3: Implementar Dashboards
1. Dashboard Estratégico:
   - Execute `dash1_1_consultas_agrupadas.sql`.
2. Dashboard Operacional:
   - Execute `dash2_1_consultas_graficos.sql`.
   - Execute `dash2_2_atualizar_graficos.sql`.

## 🔍 **Testes e Validações**

### Tela 1 - Autenticação e Gestão de Credenciais
- Execute passo a passo os comandos presentes no arquivo `tela1_2_rotina_de_teste.sql`

### Tela 2 - Gestão de Inscrições e Cancelamento Seguro
- Execute passo a passo os comandos presentes no arquivo `tela2_2_rotina_de_teste.sql`

### Dashboard 1 - Estratégico
- Abra o arquivo `dash1_2_gerar_graficos.sql`
- Gere as view para cada gráfico que compõe o dashboard
- Execute a consulta para o gráfico que deseja exibir
- Acesse o Graph Visualizer e carregue os dados retornados pela query

### Dashboard 2 - Operacional
- Abra o arquivo `dash2_3_gerar_graficos.sql`
- Atualize as views chamando a Stored Procedure
- Execute a consulta para o gráfico que deseja exibir
- Acesse o Graph Visualizer e carregue os dados retornados pela query

**Desenvolvido para disciplina de Banco de Dados**  
🎓 *Sistema completo de gestão acadêmica com foco em performance e usabilidade*
