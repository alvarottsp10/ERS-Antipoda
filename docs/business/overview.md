# Visao Geral do Sistema

Este ERP foi desenvolvido para suportar o fluxo completo de um pedido comercial desde o primeiro contacto com o cliente ate a execucao do projeto, fabrico e analise de performance.

O sistema esta dividido em varios departamentos que representam as fases reais da operacao da empresa.

---

# Fluxo Geral

Cliente -> Pedido Comercial -> Orcamentacao -> Proposta -> Adjudicacao -> Projeto -> Fabrico -> Analise de Performance

---

# 1. Pedido Comercial

O processo inicia-se quando um comercial recebe um pedido de orcamento de um cliente.

Caso o cliente ainda nao exista no sistema, deve ser criado.

## Cliente

Campos principais:
- Nome
- Pais
- Locais (um cliente pode ter varios locais)
- NIF/VAT por local
- Email geral (opcional)
- Telefone geral (opcional)

Cada cliente pode ter varios contactos.

## Contactos

Campos principais:
- Nome
- Email
- Role
- Telemovel (opcional)

Um contacto pode ser definido como contacto primario.

---

# 2. Pedido

Apos o cliente existir, o comercial cria um pedido.

O pedido e registado na tabela `orders`.

Formato da referencia:

ANO + SIGLA_COMERCIAL + NUMERO_INCREMENTAL

Exemplo:

2026 AP 001

Cada pedido pode ter varias versoes.

A primeira versao nao tem letra.
As revisoes seguem o padrao:

v1 -> 2026 AP 001
v2 -> 2026 AP 001 A
v3 -> 2026 AP 001 B

---

# 3. Fases Comerciais

O pedido passa por varias fases dentro do departamento comercial.

Eventualmente o pedido entra na fase:

**Em Orcamentacao**

Nesse momento passa para o departamento de orcamentacao.

---

# 4. Departamento de Orcamentacao

O pedido chega ao chefe de departamento que atribui o pedido a um orcamentista.

Cada versao do pedido pode ter ate dois orcamentistas ativos:

- um responsavel principal (`lead`)
- um orcamentista de suporte (`support`)

O sistema deve guardar por versao:

- quem e o responsavel principal
- quem e o apoio, quando existir
- quantas horas cada um gastou nesse processo

Numa fase posterior o sistema devera permitir tambem um relogio/timer por processo para registo mais rigoroso de tempo, mas a base funcional deve desde ja prever horas por orcamentista e por versao.

O pedido passa entao a ter fases proprias de orcamentacao.

O orcamentista desenvolve o orcamento e cria uma proposta associada a versao do pedido.

Durante a orcamentacao, o orcamentista pode ter de pedir varios precos a diferentes fornecedores.

O sistema deve permitir guardar, por cada pedido de cotacao a fornecedor:

- a que fornecedor foi pedido
- quem fez o pedido
- quando foi pedido
- quando o fornecedor respondeu
- quanto tempo demorou a responder
- o que foi pedido / descricao do material, componente ou servico
- observacoes

Este historico deve permitir:

- acompanhar pedidos pendentes
- comparar respostas entre fornecedores
- analisar tempos medios de resposta
- no futuro prever tempos de resposta por fornecedor e por tipo de pedido

Cada pedido a fornecedor deve ficar associado a `order_version`, para que o tempo de resposta e o historico comercial/orcamental fiquem ligados a revisao certa do processo.

A proposta contem:

- custo estimado de mao-de-obra
- custo estimado de projeto
- custo estimado de material
- valor de venda
- margem de lucro
- tipologia do projeto
- tipo de produto
- indicacao se e standard ou nao

Quando o orcamento termina o estado pode ser:

- Concluido
- Em avaliacao

O comercial pode validar e aplicar ajustes de margem.

Alem disso, ao carregar o orcamento, o sistema deve permitir guardar um conjunto generico de dados extraidos automaticamente por macro.

Estes campos podem nao vir todos preenchidos em todos os orcamentos, mas a estrutura deve existir para permitir normalizacao futura e analise comparativa.

Campos genericos extraidos do orcamento:

- Obra
- Versao
- Equipamento
- Custo
- Venda
- Margem
- Especificacao
- Comprimento
- Largura
- Altura
- Passo
- Angulo
- Distancia entre Pista
- Curso
- Numero de Pistas
- Numero de Zonas
- Comprimento Zona
- Comprimento Total
- Tela
- Comprimento Cassur
- Motor
- Blindagem
- Rolo
- Curso RGV
- Comprimento Correntes
- Comprimento Transportador 24V
- Largura Transportador 24V
- Drive
- Carta
- Capacidade
- Acessorios
- Data

Esta informacao deve ficar associada a versao do pedido e ao respetivo orcamento/proposta, funcionando como tabela generica de apoio ao processo comercial e de orcamentacao.

---

# 5. Reviso es

Apos envio da proposta ao cliente pode existir pedido de revisao.

Nesse caso e criada uma nova versao do pedido mantendo a mesma referencia base.

Exemplo:

2026 AP 001 -> versao original
2026 AP 001 A -> revisao 1

A nova versao volta ao processo de orcamentacao.

Cada versao pode ter uma proposta diferente.

---

# 6. Adjudicacao

O cliente pode adjudicar qualquer versao do pedido.

O sistema deve permitir:

- visualizar todas as versoes
- comparar propostas
- escolher qual versao foi adjudicada

Apos adjudicacao o pedido passa para Projeto.

---

# 7. Projeto

Apos adjudicacao o pedido torna-se um projeto.

Nesta fase sao criadas tabelas adicionais para acompanhar:

- valores considerados no orcamento
- valores reais
- analise de performance

O projeto passa para o Departamento de Projeto.

---

# 8. Departamento de Projeto

O projeto e atribuido a um projetista pelo chefe de departamento.

O projeto passa por varias fases e pode incluir:

- desenvolvimento de projeto mecanico
- desenvolvimento de projeto eletrico

Devem existir timestamps importantes como:

- envio de desenhos para aprovacao
- aprovacao do cliente
- pedidos de alteracao

No final do projeto o projetista regista as horas gastas no sistema.

As horas sao divididas por categorias.

---

# 9. Departamento de Fabrico

Apos conclusao do projeto o trabalho passa para fabrico.

O chefe de departamento ativa o projeto para producao.

Os operadores registam:

- horas de trabalho
- categoria da operacao

As horas sao posteriormente validadas pelo chefe de departamento.

O fabrico tambem tem fases proprias e pode regressar temporariamente ao departamento de projeto se necessario.

---

# 10. Valores Reais e KPIs

Durante a execucao do projeto sao registados valores reais associados ao projeto, permitindo comparar o que foi considerado no orcamento com o desempenho real.

Estas tabelas devem suportar analise por categorias como:

- Fasten
- Laser
- Parafusaria
- Produtos Siderurgicos
- Standards
- Motorizacao
- Rolos Escravos
- Rolos Motorizados
- Cartas de Controlo
- Pneumatica
- Tela
- Corrente/Carretos
- Subcontratos - Soldadura
- Subcontratos - Maquinacao
- Pintura
- Zincagem
- Revestimento
- Material Eletrico
- Packing
- Transporte
- Projeto Mecanico
- Projeto Eletrico
- Mao-de-Obra - Montagem Mecanica
- Mao-de-Obra - FAT
- Mao-de-Obra - Packing
- Mao-de-Obra - Eletrificacao
- Instalacao Mecanica
- Instalacao Eletrica
- Despesas Instalacao
- SAT

Estas tabelas serao utilizadas para criar mapas de KPI e avaliar o desempenho da empresa, comparando custo orcamentado, custo real e desvios por categoria.

---

# 11. Compras e Faturacao

As areas de compras e faturacao sao geridas externamente no sistema PHC.

O ERP deve no entanto guardar:

- valores reais de compras associados ao projeto
- percentagem de faturacao do projeto

A percentagem de faturacao permite calcular automaticamente o valor a receber com base no valor de venda.

---

# Objetivo do Sistema

Centralizar a gestao operacional dos pedidos e projetos da empresa permitindo:

- controlo do pipeline comercial
- gestao de orcamentacao
- acompanhamento de projeto
- controlo de fabrico
- analise de performance
- criacao de mapas de KPI para avaliacao do desempenho da empresa
