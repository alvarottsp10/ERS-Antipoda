# Database Schema Summary

Fonte: resultados SQL colados da base de dados Supabase em 2026-03-10.

## Âmbito desta síntese

Este resumo cobre:
- tabelas em `public`
- colunas principais identificadas nos resultados SQL
- foreign keys
- views
- funções RPC

Nota: a listagem de colunas recebida está parcial para algumas tabelas, em especial `proposal_feedback_history`, `proposal_phase_history`, `proposal_phases`, `proposals`, `roles` e `workflow_phases`. Nessas situações o documento assinala explicitamente a limitação.

## Tabelas

### `budget_typologies`
- Finalidade: catálogo de tipologias de orçamento/projeto.
- Colunas principais:
  - `id` `bigint` not null
  - `name` `text` not null
  - `sort_order` `integer`
  - `is_active` `boolean`
- Foreign keys: sem FKs próprias; é referenciada por `order_budget_assignments.budget_typology_id`.

### `contacts`
- Finalidade: contactos associados a clientes.
- Colunas principais:
  - `id` `uuid` not null
  - `customer_id` `uuid` not null
  - `name` `text` not null
  - `email` `text`
  - `phone` `text`
  - `role` `text`
  - `is_primary` `boolean`
  - `created_at` `timestamptz`
- Foreign keys:
  - `customer_id -> customers.id`

### `countries`
- Finalidade: catálogo de países.
- Colunas principais:
  - `id` `smallint` not null
  - `name` `text` not null
  - `iso2` `character` not null
  - `iso3` `character`
  - `phone_prefix` `text`
  - `vat_prefix` `text` not null
- Foreign keys: nenhuma.

### `customers`
- Finalidade: clientes comerciais.
- Colunas principais:
  - `id` `uuid` not null
  - `name` `text` not null
  - `vat_number` `text`
  - `email` `text`
  - `phone` `text`
  - `created_at` `timestamptz`
  - `country_id` `smallint`
  - `vat_country_prefix` `character`
  - `vat_number_digits` `text`
- Foreign keys:
  - `country_id -> countries.id`

### `departments`
- Finalidade: departamentos funcionais do ERP.
- Colunas principais:
  - `id` `smallint` not null
  - `code` `text` not null
  - `name` `text` not null
- Foreign keys: nenhuma; é referenciada por outras tabelas via `id` e `code`.

### `order_budget_assignments`
- Finalidade: atribuição de pedidos/versões a orçamentistas.
- Colunas principais identificadas:
  - `id` `bigint` not null
  - `assignee_user_id` `uuid` not null
  - `assigned_by` `uuid`
  - `assigned_at` `timestamptz` not null
  - `is_active` `boolean` not null
  - `note` `text`
  - `is_special` `boolean`
  - `budget_typology_id` `bigint`
  - `product_type_id` `bigint`
  - `order_version_id` `uuid` not null
- Foreign keys:
  - `assignee_user_id -> profiles.user_id`
  - `assigned_by -> profiles.user_id`
  - `budget_typology_id -> budget_typologies.id`
  - `product_type_id -> product_types.id`
  - `order_version_id -> order_versions.id`
- Observação: a coluna na posição ordinal `2` não foi incluída na listagem recebida.

### `order_counters`
- Finalidade: controlo do sequencial por ano e sigla comercial.
- Colunas principais:
  - `order_year` `integer` not null
  - `commercial_sigla` `text` not null
  - `last_seq` `integer` not null
- Foreign keys: nenhuma.

### `order_phase_history`
- Finalidade: histórico de transições de fase por departamento.
- Colunas principais:
  - `id` `bigint` not null
  - `order_id` `uuid` not null
  - `department_code` `text` not null
  - `old_phase_id` `bigint`
  - `new_phase_id` `bigint` not null
  - `changed_by` `uuid`
  - `changed_at` `timestamptz` not null
  - `note` `text`
- Foreign keys:
  - `order_id -> orders.id`
  - `department_code -> departments.code`
  - `old_phase_id -> workflow_phases.id`
  - `new_phase_id -> workflow_phases.id`

### `order_versions`
- Finalidade: versões/revisões de cada pedido.
- Colunas principais:
  - `id` `uuid` not null
  - `order_id` `uuid` not null
  - `revision_code` `text`
  - `revision_ref` `text` not null
  - `created_at` `timestamptz`
- Foreign keys:
  - `order_id -> orders.id`

### `orders`
- Finalidade: entidade central do pedido comercial.
- Colunas principais identificadas:
  - `id` `uuid` not null
  - `order_year` `integer` not null
  - `commercial_sigla` `text` not null
  - `order_seq` `integer` not null
  - `order_ref` `text` not null
  - `customer_id` `uuid`
  - `created_at` `timestamptz`
  - `commercial_user_id` `uuid`
  - `current_department` `text`
  - `outcome` `text`
  - `commercial_phase_id` `bigint`
  - `budgeting_phase_id` `bigint`
  - `project_phase_id` `bigint`
  - `production_phase_id` `bigint`
  - `awarded_order_version_id` `uuid`
  - `contact_id` `uuid`
- Foreign keys:
  - `customer_id -> customers.id`
  - `commercial_user_id -> profiles.user_id`
  - `commercial_phase_id -> workflow_phases.id`
  - `budgeting_phase_id -> workflow_phases.id`
  - `project_phase_id -> workflow_phases.id`
  - `production_phase_id -> workflow_phases.id`
  - `awarded_order_version_id -> order_versions.id`
  - `contact_id -> contacts.id`
- Observação: a listagem recebida omite várias posições ordinais intermédias, pelo que a estrutura acima é parcial.

### `product_types`
- Finalidade: catálogo de tipos de produto.
- Colunas principais:
  - `id` `bigint` not null
  - `name` `text` not null
  - `sort_order` `integer`
  - `is_active` `boolean`
- Foreign keys: nenhuma; é referenciada por `order_budget_assignments.product_type_id`.

### `profile_roles`
- Finalidade: associação N:N entre utilizadores e papéis.
- Colunas principais:
  - `user_id` `uuid` not null
  - `role_id` `smallint` not null
- Foreign keys:
  - `user_id -> profiles.user_id`
  - `role_id -> roles.id`

### `profiles`
- Finalidade: perfis de utilizador internos.
- Colunas principais:
  - `user_id` `uuid` not null
  - `full_name` `text` not null
  - `initials` `text`
  - `department_id` `smallint`
  - `is_active` `boolean`
  - `created_at` `timestamptz`
  - `pin` `text`
- Foreign keys:
  - `department_id -> departments.id`

### `proposal_feedback_history`
- Finalidade: histórico de feedback sobre propostas.
- Colunas principais identificadas:
  - `id` `bigint` not null
  - `proposal_id` `uuid` not null
  - `created_at` `timestamptz` not null
- Foreign keys:
  - `proposal_id -> proposals.id`
  - `created_by -> profiles.user_id`
- Observação: a FK indica a existência de `created_by`, mas essa coluna não apareceu na listagem parcial recebida.

### `proposal_phase_history`
- Finalidade: histórico de fases de proposta.
- Colunas principais: não vieram na listagem de colunas.
- Foreign keys:
  - `proposal_id -> proposals.id`
  - `old_phase_id -> proposal_phases.id`
  - `new_phase_id -> proposal_phases.id`

### `proposal_phases`
- Finalidade: catálogo de fases de proposta.
- Colunas principais: não vieram na listagem de colunas.
- Foreign keys: nenhuma recebida.

### `proposals`
- Finalidade: proposta comercial/orçamental por versão de pedido.
- Colunas principais: não vieram na listagem de colunas.
- Foreign keys:
  - `order_version_id -> order_versions.id`
  - `phase_id -> proposal_phases.id`

### `roles`
- Finalidade: catálogo de perfis/papéis de acesso.
- Colunas principais: não vieram na listagem de colunas.
- Foreign keys: nenhuma recebida.

### `workflow_phases`
- Finalidade: catálogo de fases por departamento para o fluxo do pedido.
- Colunas principais: não vieram na listagem de colunas.
- Foreign keys:
  - `department_code -> departments.code`

## Views

### `commercials_list_view`
- Finalidade: listagem de comerciais utilizável em UI/dropdowns.
- Colunas:
  - `user_id`
  - `full_name`
  - `initials`
  - `is_active`
  - `department_name`

### `customer_list_view`
- Finalidade: listagem agregada de clientes.
- Colunas:
  - `id`
  - `name`
  - `vat_number`
  - `email`
  - `phone`
  - `country_name`
  - `contact_count`

## Funções RPC

### Clientes e contactos
- `add_customer_contact(p_customer_id uuid, p_name text, p_email text, p_phone text, p_role text, p_is_primary boolean)`
- `create_customer_with_contacts(p_name text, p_country_id integer, p_vat_number text, p_email text, p_phone text, p_contacts jsonb)`
- `remove_customer_contact(p_contact_id uuid)`

### Pedidos e revisões
- `create_order(p_customer_id uuid, p_commercial_user_id uuid, p_commercial_sigla text, p_commercial_phase_id bigint)`
- `create_order_revision(p_order_id uuid)`
- `create_order_revision_from_crm(p_order_id uuid, p_contact_id uuid)`
- `get_next_order_seq(p_year integer, p_sigla text)`
- `orders_set_ref()`
- `validate_awarded_order_version()`

### Orçamentação e workflow
- `assign_budgeter(p_order_id uuid, p_assignee_user_id uuid, p_budget_typology_id bigint, p_product_type_id bigint, p_is_special boolean)`
- `set_order_commercial_phase(p_order_id uuid, p_commercial_phase_id bigint)`
- `update_order_budget_details(p_order_id uuid, p_budgeting_phase_id bigint, p_budget_typology_id bigint, p_product_type_id bigint, p_is_special boolean)`
- `log_order_status_change()`
- `update_order_status(p_order_id uuid, p_new_status order_status)`

## Relações principais

### Núcleo comercial
- `customers -> contacts`
- `customers -> orders`
- `contacts -> orders`
- `profiles -> orders` via comercial responsável

### Versionamento e proposta
- `orders -> order_versions`
- `order_versions -> proposals`
- `orders -> awarded_order_version_id`
- `proposals -> proposal_phases`
- `proposal_feedback_history -> proposals`
- `proposal_phase_history -> proposals`

### Workflow por departamento
- `departments -> workflow_phases`
- `orders -> workflow_phases` para comercial, orçamentação, projeto e produção
- `order_phase_history -> workflow_phases`

### Gestão interna
- `profiles -> profile_roles -> roles`
- `profiles -> departments`
- `order_budget_assignments -> profiles`

## Comparação com `docs/business/overview.md`

### O que está alinhado
- Existe base de clientes e contactos: `customers`, `contacts`, `countries`.
- Existe conceito de pedido comercial com referência sequencial: `orders`, `order_counters`, RPC `get_next_order_seq`, `create_order` e `orders_set_ref`.
- Existe versionamento/revisões: `order_versions`, `create_order_revision`, `create_order_revision_from_crm`.
- Existe workflow por departamentos e histórico de fases: `workflow_phases`, `order_phase_history`, campos de fase em `orders`.
- Existe atribuição para orçamentação: `order_budget_assignments`, `assign_budgeter`.
- Existe tipologia e tipo de produto para a proposta/orçamento: `budget_typologies`, `product_types`.
- Existe proposta ligada à versão do pedido: `proposals`, `proposal_phases`, histórico de feedback e fases.
- Existe adjudicação ao nível da versão: `orders.awarded_order_version_id`, `validate_awarded_order_version`.
- Existe modelo de utilizadores internos e departamentos: `profiles`, `roles`, `profile_roles`, `departments`.

### O que falta no schema face ao negócio
- `customers` não mostra suporte explícito a "locais" do cliente. No overview, um cliente pode ter vários locais com NIF/VAT por local; hoje o schema mostra o VAT no cliente, não numa entidade própria.
- Não aparecem entidades para Projeto após adjudicação. O overview pede uma fase em que o pedido "torna-se projeto" com dados próprios.
- Não aparecem entidades para atribuição de projetista e workflow detalhado de projeto.
- Não aparecem entidades para timestamps de projeto: envio de desenhos, aprovação do cliente, pedidos de alteração.
- Não aparecem entidades para registo de horas de projeto por categoria.
- Não aparecem entidades para fabrico/produção com operadores, registo de horas, categorias operacionais e validação do chefe.
- Não aparecem entidades para retorno de fabrico para projeto, além dos campos genéricos de fase em `orders`.
- Não aparecem entidades de custos reais por categoria/KPI.
- Não aparecem entidades para categorias de custo/KPI listadas no overview.
- Não aparecem entidades para compras reais integradas a projeto.
- Não aparecem entidades para faturação/progresso de faturação por projeto.
- Não aparece, pelos dados recebidos, o detalhe financeiro da proposta referido no overview: custo de mão-de-obra, projeto, material, valor de venda e margem. Isto pode existir em `proposals`, mas não foi possível confirmar com a listagem parcial.
- O RPC `update_order_status(... order_status)` sugere um tipo/estado adicional, mas não foi fornecida a definição do enum nem colunas de estado confirmadas nas tabelas.

### Entidades recomendadas a criar a seguir

Prioridade 1:
- `customer_sites`
  - Para suportar vários locais por cliente.
  - Deve guardar nome/local, morada, país e VAT/NIF por local.
- `projects`
  - Para separar claramente pedido adjudicado de execução.
  - Deve referenciar `orders` e a `order_version` adjudicada.
- `project_assignments`
  - Para atribuição de projetista e eventualmente chefe de projeto.
- `project_phase_history`
  - Para histórico próprio do departamento de projeto.

Prioridade 2:
- `project_milestones`
  - Para timestamps como envio de desenhos, aprovação do cliente, pedidos de alteração.
- `project_time_entries`
  - Horas de projeto por utilizador, categoria e data.
- `production_time_entries`
  - Horas de fabrico por operador, categoria e validação.
- `production_assignments`
  - Ativação do projeto para produção e responsáveis.

Prioridade 3:
- `cost_categories`
  - Catálogo normalizado das categorias KPI/custo do overview.
- `project_budget_lines`
  - Valores orçamentados por categoria, derivados da proposta adjudicada.
- `project_actual_cost_lines`
  - Valores reais por categoria.
- `project_billing_progress`
  - Percentagem e marcos de faturação.
- `project_purchase_costs`
  - Custos reais de compras importados/manualizados.

### Observações de modelação
- Vale a pena decidir se `proposals` será a fonte única dos valores orçamentados detalhados ou se esses valores devem ser materializados em linhas (`proposal_lines` / `proposal_cost_lines`).
- `workflow_phases` já suporta múltiplos departamentos; a mesma abordagem pode ser reutilizada para projeto e fabrico, evitando catálogos duplicados.
- Para KPIs, o mínimo sustentável é ter uma dimensão `cost_categories` e duas fact tables: orçamento vs real.
