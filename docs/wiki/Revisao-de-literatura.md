# Revisão de literatura

Esta página resume a fundamentação teórica do estudo em cinco eixos. Os números entre parênteses remetem à página [Referências](Referencias).

## 1. Salas de situação e governo por metas

A **sala de situação em saúde** é um espaço técnico-político de análise contínua da situação de saúde, que integra dados de diferentes sistemas de informação para apoiar a decisão em tempo oportuno. No Brasil, a estratégia foi difundida pelo Ministério da Saúde e pela Organização Pan-Americana da Saúde como instrumento de gestão do SUS em todas as esferas de governo (31).

O **planejamento estratégico situacional** de Carlos Matus sustenta essa prática: os problemas são explicados a partir da situação concreta, os atores responsáveis são identificados e o cumprimento das ações é acompanhado por um sistema de prestação de contas e de monitoramento por indicadores (2). Os GTs do PEG funcionam como esse espaço de petição e prestação de contas, alimentado pelos painéis da Sala de Situação.

## 2. Monitoramento, retroalimentação e melhoria contínua

Os ciclos de melhoria contínua propostos por Deming — planejar, executar, verificar e agir — pressupõem que a medição sistemática do desempenho, discutida com quem executa o trabalho, gera aprendizagem e correção de rumo (3).

A estratégia de **auditoria e retroalimentação** (_audit and feedback_) é a forma mais estudada desse mecanismo em saúde. A revisão Cochrane de Ivers e colaboradores, com 140 ensaios, encontrou melhoria pequena, porém consistente, na adesão a práticas desejadas; os efeitos tendem a ser maiores quando o desempenho de partida é baixo, quando a devolutiva é feita por colegas ou supervisores, ocorre mais de uma vez, é apresentada de forma verbal e escrita e vem acompanhada de metas e de um plano de ação explícitos (4). Essas características estão presentes no desenho dos GTs, o que fundamenta a hipótese de efeito sobre **indicadores de processo** — como o exame de contatos — e, de forma mais indireta e defasada, sobre **indicadores de resultado** — como a letalidade.

## 3. Séries temporais interrompidas na avaliação de intervenções em saúde

### Por que STI

Quando uma intervenção é implantada em toda uma população em um momento conhecido, sem grupo de comparação, a STI é um dos desenhos quase-experimentais mais robustos disponíveis (5). A lógica é comparar a série observada após a intervenção com o cenário **contrafactual** obtido pela projeção da tendência anterior. O desenho controla, por construção, tendências seculares e diferenças estáveis entre períodos, desde que haja pontos suficientes antes da intervenção (6,7).

### Regressão segmentada

A forma mais usada é a **regressão segmentada**, que estima três parâmetros de interesse: a tendência anterior, a mudança imediata de nível e a mudança de tendência após a intervenção (6). Tutoriais metodológicos recomendam (7,11–13):

- definir **a priori** o ponto de corte e o formato esperado do efeito (imediato, gradual ou defasado);
- usar um modelo adequado ao tipo de desfecho (por exemplo, modelos binomiais ou de Poisson para proporções e contagens);
- considerar **sazonalidade** e **autocorrelação**;
- prever **períodos de transição** quando a implantação é gradual;
- ter número suficiente de pontos em cada segmento — referências clássicas sugerem ao menos 12 observações antes e 12 depois, com o poder dependendo também da variabilidade e do tamanho do efeito (6,16).

### Problemas frequentes na literatura

Revisões metodológicas mostram que muitos estudos publicados com STI não descrevem ou não tratam a autocorrelação, escolhem o ponto de corte depois de olhar os dados ou usam poucos pontos por segmento (14,16). A comparação empírica de Turner e colaboradores, com 190 séries publicadas, mostrou que diferentes métodos de estimação — mínimos quadrados com erros de Newey-West, Prais-Winsten, máxima verossimilhança restrita, ARIMA — podem levar a conclusões diferentes sobre a significância estatística, o que reforça a importância de análises de sensibilidade (15).

### Escolhas deste estudo à luz da literatura

| Recomendação | Como foi atendida |
|---|---|
| Ponto de corte a priori | Início dos GTs, definido antes da análise; demais datas apenas em sensibilidade |
| Modelo adequado ao desfecho | GLM quasibinomial com numerador e denominador mensais (17) |
| Autocorrelação | Erros-padrão de Newey-West (18,19) e teste de Ljung-Box nos resíduos (22) |
| Sazonalidade | Termos harmônicos anuais quando justificados; decomposição STL e periodograma (21,23) |
| Efeito defasado | Cenário com período de transição de seis meses |
| Robustez | Pontos de corte alternativos, incluindo a mudança de gestão anterior aos GTs |

## 4. Hanseníase e o exame de contatos

O Brasil concentra o segundo maior número de casos novos de hanseníase do mundo, e o diagnóstico tardio está associado a incapacidades físicas permanentes (24). A estratégia global da Organização Mundial da Saúde e a Estratégia Nacional para Enfrentamento à Hanseníase 2024–2030 colocam a **investigação de contatos** no centro da detecção precoce e da interrupção da transmissão (24,25).

Contatos de pessoas com hanseníase têm risco de adoecimento muito superior ao da população geral. A coorte de Teixeira e colaboradores, com contatos domiciliares de casos notificados no Brasil, confirmou essa elevada incidência e identificou fatores associados ao adoecimento entre os contatos (8). Por isso, a **proporção de contatos examinados** é um indicador operacional de qualidade dos serviços, com parâmetros definidos pelo Ministério da Saúde (9,26).

## 5. Leptospirose e letalidade

A leptospirose é uma zoonose de distribuição mundial, com cerca de um milhão de casos e quase 60 mil óbitos estimados por ano (27). Em Salvador, a doença é endêmica em comunidades com saneamento precário e apresenta surtos associados às chuvas; estudos na cidade descreveram uma epidemia urbana de formas graves e os determinantes espaciais e temporais da transmissão (28,29).

A letalidade depende do reconhecimento precoce, do início oportuno da antibioticoterapia e do manejo das formas graves em serviços preparados (10,30). Intervenções de gestão que melhorem a organização do cuidado podem, portanto, afetar a letalidade — mas com efeito esperado mais tardio e mais difícil de detectar, já que o número mensal de óbitos é pequeno.

## Lacuna

São frequentes as avaliações de STI para mudanças de políticas, programas e tecnologias, mas, até onde os autores puderam verificar, são escassas as avaliações publicadas de **instâncias municipais de governança e monitoramento de metas** — como os GTs — sobre indicadores epidemiológicos. Este estudo busca contribuir com essa evidência a partir de dados de rotina da vigilância.
