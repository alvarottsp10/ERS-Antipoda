# Estado Atual do Projeto

## Base funcional

- A app Flutter ja esta ligada ao projeto Supabase novo.
- A base funcional continua centrada no fluxo:
  - `orders -> order_versions -> proposals -> adjudications`
- O foco real continua a ser fechar o ERP ate adjudicacao antes de abrir seriamente producao/projeto.

## Estrutura transversal da app

- A base estrutural moderna da app ja esta consolidada:
  - `ProviderScope`
  - `MaterialApp.router`
  - `go_router`
  - shell moderno
  - login moderno
  - `lib/core/routing/...`
  - `lib/core/theme/app_theme.dart`
- Existe agora uma camada global de acesso em Flutter:
  - `lib/features/app/application/app_access_models.dart`
  - `lib/features/app/application/app_access_providers.dart`
- Essa camada ja reage corretamente ao `onAuthStateChange`, evitando cache de nome/roles entre logout e novo login.
- Existe tambem uma camada simples de estado global para mock de cronometro:
  - `lib/features/app/application/app_timer_mock_provider.dart`

## Roles e acesso

### Roles reais na base

- `ADMIN`
- `COMERCIAL`
- `ORCAMENTISTA`
- `PROJETISTA`
- `PRODUCAO`
- `ORC_MANAGER`
- `PROJ_MANAGER`
- `PROD_MANAGER`
- `COM_MANAGER`

### Regras ja refletidas no Flutter

- `ADMIN` tem acesso transversal.
- `COM_MANAGER` e tratado como manager CRM.
- `COMERCIAL` e tratado como utilizador comercial.
- `ORC_MANAGER` e tratado como manager de orcamentacao.
- `ORCAMENTISTA` e tratado como utilizador de orcamentacao.

### Menu lateral

- `COMERCIAL` puro ve apenas:
  - `Dashboard`
  - `CRM`
  - `Relatorios`
- `ADMIN` e managers continuam a ver menu completo.
- O item CRM aparece como `CRM - Manager` para gestao/admin.
- O item Orcamentacao aparece como `Orcamentacao - Manager` para `ADMIN` e `ORC_MANAGER`.

## Dependencias de policies

Para a app refletir corretamente identidade e roles, a base precisa agora de permitir leitura autenticada em:

- `roles`
- `profile_roles`
- `profiles`

Sem isso, nome, iniciais e roles no shell ficam desalinhados.

## CRM

O CRM e a area mais madura do refactor.

### Estrutura

Ja segue de forma clara o padrao:

- `data`
- `domain`
- `application`
- `presentation`

### Backend alinhado

O CRM ja trabalha com:

- `customers`
- `contacts`
- `customer_sites`
- `orders`
- `order_versions`
- `workflow_phases`
- `proposals`
- `order_budget_assignments`

### Ownership de clientes

- `customers.commercial_user_id` ja existe.
- Cada cliente passa a ter comercial responsavel.
- A RPC `create_customer_with_contacts(...)` ja recebe `p_commercial_user_id`.
- Existe `reassign_customer_commercial(...)`.

### Datas de negocio ja modeladas

- `orders.requested_at`
- `order_versions.requested_at`
- `order_versions.sent_to_budgeting_at`
- `order_versions.expected_delivery_date`
- `order_versions.budget_delivered_at`
- `order_versions.actually_delivered_at`

### RPCs novas/alinhadas

- `create_order(...)` com `p_requested_at` e `p_expected_delivery_date`
- `create_order_revision(...)` com datas
- `create_order_revision_from_crm(...)` com datas
- `update_latest_order_version_expected_delivery(...)`
- `cancel_order_from_crm(...)`

### Dashboard CRM

- O dashboard atual passou a ser o frontend de `manager/admin`.
- Existe dashboard separado para comercial normal.
- O dashboard comercial esta restrito por contexto:
  - clientes do proprio comercial
  - pedidos do proprio comercial
  - revisoes sobre pedidos do proprio comercial
  - criacao de cliente com owner automatico no utilizador atual

### Fluxos CRM alinhados

- `SendProposal`
- `InsertOrder`
- `InsertRevision`
- `AddCustomer`
- `ViewCustomers`
- dashboard CRM partido em widgets

### Dialogos e shell visual

- Existe tema global de app para reduzir herdanca roxa/default.
- Os dialogs CRM ja estao mais coerentes entre si, embora ainda existam pequenos ajustes visuais a fechar.
- O shell ja identifica corretamente nome, iniciais e role ativa apos logout/login sem precisar de refresh manual.
- O shell ja consegue mostrar um cronometro ativo junto a campainha:
  - so aparece quando existe cronometro ativo
  - e iniciado a partir de `Os meus orcamentos`
  - ao mudar de pagina continua visivel por viver no shell
  - neste ponto continua a ser apenas mock de UX, sem persistencia backend

### Integracao local de pastas no CRM

- No `Editar Pedido` existe agora suporte local para Windows:
  - verificar se a pasta `info` do processo existe
  - abrir a pasta no Explorer
  - selecionar ficheiros por janela Windows e copiar para a pasta `info`
- O drag-and-drop no modal foi deixado apenas como placeholder de UX; no desktop, o fluxo fiavel neste ponto continua a ser:
  - `Abrir Pasta`
  - ou `Selecionar ficheiros`
- Para emails do Outlook, o fluxo atual recomendado continua a ser abrir a pasta e largar diretamente no Explorer.

### Pontos ainda em aberto no CRM

- O logo do topo ficou temporariamente em PNG por problemas de compatibilidade do SVG exportado com `flutter_svg`.
- O fluxo de notificacoes ainda nao arrancou.
- A edicao completa administrativa de pedido ainda nao existe:
  - mudar cliente
  - mudar comercial
  - corrigir dados estruturais do pedido

## Orcamentacao

### Estado anterior

A feature `budgeting` existia, mas estava muito pre-refactor:

- queries Supabase diretas na UI
- `initialBudgetingPhaseId` hardcoded
- dialogs com leitura/escrita direta
- referencias antigas a `order_revisions`

### Estado atual depois do passo 1 de refactor

Ja existe agora a mesma espinha dorsal do CRM:

- `lib/features/budgeting/data/budgeting_repository.dart`
- `lib/features/budgeting/domain/budgeting_models.dart`
- `lib/features/budgeting/application/budgeting_dashboard_view_models.dart`
- `lib/features/budgeting/application/budgeting_dashboard_mappers.dart`
- `lib/features/budgeting/application/budgeting_dashboard_providers.dart`
- `lib/features/budgeting/presentation/widgets/...`

### Separacao de dashboards

- `BudgetDashboardScreen` ja decide por role:
  - `ADMIN` / `ORC_MANAGER` -> dashboard de gestao
  - `ORCAMENTISTA` -> dashboard de utilizador

### Widgets criados

- `budgeting_dashboard_actions_bar.dart`
- `budgeting_panel.dart`
- `new_budget_orders_panel.dart`
- `my_budgets_panel.dart`
- `active_budgets_panel.dart`
- `budgeting_user_dashboard_screen.dart`
- `view_budgets_screen.dart`
- `widgets/order_detail_panel.dart`
- `widgets/version_card.dart`

### Ecr? `Ver orcamentos`

- Ja existe um ecr? dedicado de consulta global de orcamentos em:
  - `lib/features/budgeting/presentation/view_budgets_screen.dart`
- O ecr? foi partido sem mudar a UI final em:
  - lista de pedidos
  - detalhe do pedido
  - card de versao/proposta
- O detalhe vive agora em:
  - `lib/features/budgeting/presentation/widgets/order_detail_panel.dart`
- Cada versao/proposta do detalhe vive agora em:
  - `lib/features/budgeting/presentation/widgets/version_card.dart`

### Estado de presentation/application em `Ver orcamentos`

- A preparacao de dados de visualizacao das versoes foi extraida para:
  - `lib/features/budgeting/application/view_budgets_mapper.dart`
- Esse mapper ja concentra:
  - resolucao da proposta efetiva por versao
  - leitura de `proposal_items`
  - naming visual de proposta (`Original`, `A`, `B`, ...)
  - labels de datas
  - flags de estado usadas no card
  - mapping dos equipamentos para `view_proposal_dialog.dart`
- O estado e a logica do ecr? `Ver orcamentos` vivem agora em:
  - `lib/features/budgeting/presentation/application/view_budgets_screen_manager.dart`
- Esse manager ja e dono de:
  - filtros (`cliente`, `referencia`, `ano`)
  - lista carregada de pedidos
  - loading/erro da lista
  - pedido selecionado
  - versao expandida
  - future do detalhe
- O `ViewBudgetsScreen` ficou reduzido a composicao visual + bindings para o manager, sem manter a logica principal de estado no widget.

### Dashboard manager de Orcamentacao

O dashboard de `ADMIN` / `ORC_MANAGER` ficou agora organizado em 3 zonas:

- `Novos Pedidos`
- `Orcamentos`
- `Os meus orcamentos`

Nao existem metricas neste ecra por decisao funcional; essas devem viver mais tarde num espaco proprio.

### Acoes de topo em Orcamentacao

- A barra de acoes do dashboard manager ja suporta:
  - `Ver orcamentos` como placeholder visual
  - `Adicionar Fornecedor` como placeholder visual
- O dashboard de utilizador ORC tambem ja mostra os mesmos dois botoes no topo.
- Nesta fase ambos continuam placeholders de UX; ainda nao existe navegacao/CRUD final associado.

### Afinacao atual da UI de Orcamentacao

- Os quadros `Orcamentos` e `Os meus orcamentos` ja foram significativamente limpos.
- O quadro `Os meus orcamentos` usa agora cartoes colapsaveis mais compactos:
  - fechado mostram resumo operacional em linha unica
  - aberto mantem equipa e acoes de horas/cronometro no proprio header
- O quadro `Orcamentos` deixou de ser expansivel e ficou com header simples de resumo + acao de editar.
- Em ambos os quadros, o header ja mostra de forma consistente:
  - processo + cliente
  - `Lead`
  - `Support` por nome quando existe
  - `Fase`
  - `Horas Totais`
- As cards da equipa foram afinadas:
  - sem chip `Eu`
  - support com cor azul clara
  - conteudo verticalmente centrado
- No quadro `Orcamentos`, o cabecalho continua a mostrar contadores:
  - `Ativos`
  - `Em espera`
- O quadro `Os meus orcamentos` ja permite iniciar/parar o mock de cronometro por processo.
- O quadro `Orcamentos` ja permite abrir o mesmo `EditBudgetDialog` usado em `Os meus orcamentos`.

### Repository de Orcamentacao

Ja centraliza:

- leitura de orcamentistas elegiveis
- leitura de tipologias
- leitura de tipos de produto
- leitura de fases ORC
- leitura de novos pedidos a atribuir
- leitura dos meus orcamentos
- RPC `assign_budgeter(...)`
- RPC `update_order_budget_details(...)`

### Dialogos ja alinhados ao repository

- `assign_budgeter_dialog.dart`
- `edit_budget_dialog.dart`
- `upload_proposal_dialog.dart`
- `view_proposal_dialog.dart`

### Atribuicao de orcamentista

O dialogo de atribuicao ja suporta:

- `Lead`
- `Support` opcional
- `Data esperada de entrada`
- `Data prevista de entrega`
- `Tipologia` opcional
- `Produtos`
- botao para abrir pasta local de teste no Windows

O caminho de pasta usado neste ponto ainda e provisiorio/teste, mas ja provou que a app desktop consegue abrir uma pasta real na drive mapeada da empresa.

### Modelo de atribuicao ORC

- A base ja suporta ate 2 orcamentistas ativos por `order_version`.
- Existe no maximo 1 `lead` ativo por versao.
- O segundo assignment ativo pode funcionar como `support`.
- Cada assignment passa a ter:
  - `assignment_role`
  - `worked_hours`
- O backend ja tem:
  - `assign_budgeter(...)` com `p_assignment_role`
  - `update_budget_assignment_hours(...)`
  - `deactivate_budget_assignment(...)`
- O Flutter ja foi adaptado para ler varios assignments ativos por versao em vez de assumir apenas um.
- Os paineis ja refletem `lead/support`, embora a UI ainda esteja em afinacao.

### Realtime entre instancias

- Foi criada uma camada de realtime em:
  - `lib/features/app/application/app_realtime_service.dart`
- CRM e Orcamentacao passam agora a subscrever alteracoes em:
  - `orders`
  - `order_versions`
  - `order_budget_assignments`
  - `proposals`
- Quando ha alteracoes nessas tabelas, os dashboards invalidam os providers e recarregam sem exigir logout/login.
- Para isto funcionar, foi necessario colocar essas tabelas na publication `supabase_realtime` do projeto Supabase.

### O que ainda nao esta fechado em Orcamentacao

- o fluxo final de proposta continua parcial:
  - ja existe import real e visualizacao read-only
  - ainda nao existe edicao persistente de proposta/equipamentos
  - ainda nao existe eliminar/substituir proposta na UI
- ainda faltam filtros/acoes especificas para manager ORC
- ainda faltam testes manuais consistentes com contas `ORC_MANAGER` e `ORCAMENTISTA`
- a introducao/edicao de horas por orcamentista ainda nao tem UI final
- o cronometro no topo continua mockado:
  - ainda nao grava sessoes reais em backend por sessoes completas
  - ainda nao esta ligado a horas finais por assignment fora do fluxo local atual
  - ainda nao existe bloqueio funcional por permissao/processo alem do estado unico global de UI

### Importacao Excel de orcamentos

Ja existe progresso funcional relevante no parsing do Excel de orcamento e o fluxo ja consegue importar proposta real para backend a partir do dialog.

#### Estado atual do parser

- O upload do Excel ja funciona no dialog:
  - `lib/features/budgeting/presentation/dialog/upload_proposal_dialog.dart`
- Foi criado parser dedicado em:
  - `lib/features/budgeting/application/budgeting_excel_parser.dart`
- A package usada para leitura continua a ser:
  - `spreadsheet_decoder`
- O objetivo continua a ser replicar o comportamento do Excel/VBA o mais fielmente possivel, sem mudar de package nesta fase.
- O dialog ja mantem uma copia local editavel dos equipamentos detetados antes de submeter.
- A submissao ja usa a RPC `import_proposal_from_excel(...)` e persiste:
  - proposta
  - `proposal_items`
  - atributos dos equipamentos
  - `budget_import_data`

#### Leitura atual do ficheiro Excel

- O resumo ja e lido da folha `Resumo` por posicoes fixas:
  - `D9` total material
  - `D10` total M.O.
  - `D11` total projeto
  - `D22` total venda
- O parser ja resolve os limites da folha principal de orcamento atraves de `BudgetSheetBounds`:
  - `sheetName`
  - `startRow`
  - `endRow`
- A logica atual para descobrir a folha/range e:
  - tentar nome da folha igual ao processo sem versao
  - se nao existir, usar segunda folha
  - inicio fixo na linha 9 Excel
  - fim por `Total Equipamentos` na coluna `V`
  - fallback para ultimo `BREAK` na coluna `D`

#### Segmentacao por conjuntos

- O parser ja consegue partir o intervalo util em blocos/conjuntos usando `BREAK` na coluna `D`.
- Cada bloco representa um conjunto ou equipamento principal do orcamento.
- Ja existe uma estrutura de parser para cada bloco com dados base do conjunto principal, incluindo:
  - linha inicial
  - linha final
  - linha principal
  - classe principal
  - equipamento principal
  - descricao principal
  - quantidade
  - valor de venda unitario
  - valor de venda total
  - custo total do conjunto
  - margem calculada

#### Estado atual da extracao por conjunto

- Ja esta validado em testes reais que a separacao por blocos esta a funcionar corretamente.
- A identificacao do equipamento principal funciona bem para equipamentos standard.
- Quando o conjunto nao corresponde a equipamento standard da empresa, o parser continua a manter a descricao principal do bloco, deixando a classificacao final para decisao manual no ERP.
- Ja existe debug textual de apoio no dialog com formato aproximado da futura preview:
  - titulo do equipamento/conjunto
  - atributos extraidos da descricao principal
  - quantidade
  - venda unitária
  - venda total
  - custo total
  - margem

#### Atributos atualmente extraidos

- Nesta fase ja existe extracao inicial de atributos a partir da descricao principal, nomeadamente:
  - `L`
  - `W`
  - `H`
  - `BT`
- O parser ja consegue extrair pares `atributo: valor` e preserva-os no payload dos equipamentos importados.
- Estes atributos ja sao visiveis tanto na preview do upload como no dialog read-only de visualizacao da proposta.

#### Estado atual da visualizacao da proposta

- O `EditBudgetDialog` ja mostra uma entrada simples de `Proposta ativa`.
- Ao clicar, abre um dialog read-only (`view_proposal_dialog.dart`) com:
  - totais da proposta
  - margem
  - lista de equipamentos
  - caracteristicas detetadas por equipamento
- Quando a proposta vem de import recente, os equipamentos ja aparecem a partir do estado local.
- Quando a proposta ja existia anteriormente, os totais backend ja podem ser propagados pelos models; a leitura dos equipamentos continua dependente da relacao `proposal_items` via PostgREST.

#### Proximo passo desta linha de trabalho

- Continuar a aproximar a logica do parser ao comportamento do VBA original.
- Fechar a leitura robusta de `proposal_items` para propostas ja existentes usando a relacao correta no PostgREST.
- So depois abrir a fase seguinte de revisao/edicao persistente da proposta.

### Novo modelo backend para proposta, atributos e tempos

Foi fechado um novo modelo backend para suportar a estruturacao real dos equipamentos da proposta, os atributos dinamicos por equipamento e o registo detalhado de horas por categoria.

#### Estrutura de proposta por equipamento

Cada `BREAK` do Excel passa a corresponder a um equipamento/conjunto real da proposta.

Foram criadas tabelas novas para suportar isto:

- `proposal_items`
- `product_attribute_definitions`
- `proposal_item_attribute_values`

##### `proposal_items`

Guarda cada equipamento/conjunto da proposta, ligado a:

- `proposal_id`
- `order_version_id`

Nota operacional atual:

- `proposal_items` tem RLS ativo.
- Para o frontend autenticado conseguir ler os equipamentos de uma proposta existente, foi necessario abrir policy de `SELECT` para `authenticated`.
- Sem essa policy, os totais da proposta podiam aparecer mas a lista de equipamentos chegava vazia no Flutter.

Campos principais pensados para uso operacional e analitico:

- posicao no ficheiro
- nome do equipamento
- especificacao
- quantidade
- custo total
- venda unitaria
- venda total
- margem
- `is_special`
- `raw_payload`

Regras importantes:

- cada `proposal_item` pertence sempre a uma `proposal`
- `proposal_id` nao e opcional
- existe unicidade por:
  - `(proposal_id, position)`

##### `product_attribute_definitions`

Passa a existir um catalogo oficial de atributos tecnicos dos produtos/equipamentos.

Campos principais:

- `code`
- `label`
- `value_type`
- `source_type`
- `is_active`
- `sort_order`

Este catalogo serve para:

- dropdowns consistentes no Flutter
- validacao da importacao
- impedir caos de naming
- permitir criacao controlada de novos atributos

Tipos funcionais ja assumidos:

- `number`
- `text`
- `boolean`

Origens funcionais ja assumidas:

- `reference`
- `derived`
- `manual`

Ja ficou carregado um seed inicial com os atributos hoje extraidos da logica VBA / parser, incluindo por exemplo:

- `L`
- `W`
- `H`
- `P`
- `ANG`
- `BS`
- `ST`
- `NS`
- `NZ`
- `LZ`
- `LT`
- `BT`
- `LCASS`
- `M`
- `CV`
- `R`
- `LCURSO`
- `LCORRENTES`
- `L24V`
- `W24V`
- `D`
- `CD`
- `PC`
- `AlturaCorrentes`
- `Acessorios`
- `Especial`

##### `proposal_item_attribute_values`

Guarda o valor concreto de cada atributo num dado equipamento/conjunto.

Modelo funcional:

- 1 `proposal_item`
- 1 atributo do catalogo
- 1 valor concreto

Campos de valor:

- `value_text`
- `value_number`
- `value_boolean`

Regra importante:

- existe unicidade por:
  - `(proposal_item_id, attribute_definition_id)`

Isto impede duplicar o mesmo atributo no mesmo equipamento.

#### Novo papel da `budget_import_data`

A tabela `budget_import_data` deixou de ser tratada como estrutura principal dos atributos tecnicos do equipamento.

Passa a ficar com papel mais reduzido e coerente com o processo de orcamentacao:

- contexto do import
- ligacao a `order_version_id`
- ligacao a `proposal_id`
- `imported_by`
- `imported_at`
- `source_name`
- `raw_payload`

Os atributos tecnicos e os dados estruturados do equipamento passam a viver em:

- `proposal_items`
- `proposal_item_attribute_values`

#### Novo modelo para horas por categoria

Foi tambem fechado um modelo backend para registo detalhado de horas por categoria e por departamento.

Tabelas novas:

- `work_time_category_definitions`
- `work_time_entries`

##### `work_time_category_definitions`

Catalogo de categorias de tempo, reutilizavel entre departamentos.

Cada categoria pertence a um departamento e tem:

- `department_id`
- `code`
- `label`
- `is_active`
- `sort_order`

Isto permite usar a mesma estrutura em:

- Orcamentacao
- Projeto
- Producao

sem criar tabelas diferentes por area.

##### `work_time_entries`

Guarda registos reais de tempo por assignment.

Ligacao principal:

- `budget_assignment_id`
- `category_definition_id`

Campos principais:

- `hours`
- `note`
- `work_date`

A granularidade assumida e:

- varias entradas por assignment
- varias entradas por categoria
- total agregado por pessoa/processo

##### Relacao com `order_budget_assignments.worked_hours`

O campo `worked_hours` continua a existir em `order_budget_assignments`, mas o seu papel passa a ser o de total consolidado por assignment.

Ou seja:

- o detalhe vive em `work_time_entries`
- o total individual por orcamentista vive em `worked_hours`

O total global da versao deve ser obtido por soma dos assignments da respetiva `order_version`, e nao gravado numa coluna unica.

##### Categorias iniciais de ORC

Ja ficou definido o conjunto inicial de categorias do departamento `ORC`:

- `reuniao`
- `espera_orcamento`
- `desenvolvimento_orcamento`
- `desenvolvimento_proposta`
- `alteracoes_cliente`

Estas categorias devem suportar a primeira versao do registo de horas em Orcamentacao antes de expandir para Projeto e Producao.

## Fonte de verdade do backend

- O documento tecnico a usar como fonte de verdade do backend continua a ser:
  - `supabase_schema.sql`
- O repositorio ja inclui tambem:
  - `supabase/migrations/...`
- O ficheiro `docs/database/schema.md` nao deve ser tratado como fonte atual do schema real.

## Regra operacional atual

- Leitura pode ser por query.
- Escrita deve ser por stored procedures / RPC.

## Proximo passo recomendado

Depois deste ponto, o passo mais logico e continuar em Orcamentacao:

- validar o novo dashboard por role
- refatorar `upload_proposal_dialog.dart`
- fechar o primeiro fluxo real de proposta no lado ORC
- so depois voltar a estender o fluxo CRM -> ORC -> proposta -> adjudicacao
