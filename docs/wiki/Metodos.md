# Métodos

## 1. Desenho

Estudo quase-experimental do tipo **série temporal interrompida (STI)**, com unidade de análise mensal, no município de Salvador, Bahia (5–7).

| Elemento | Definição |
|---|---|
| Intervenção | Implantação dos Grupos de Trabalho em Saúde (GTs) do PEG 2025–2028 |
| Ponto de corte principal | **Julho de 2025** (início dos GTs), definido antes da análise dos resultados |
| Período de estudo | Janeiro de 2022 até o último mês completo disponível |
| Unidade de análise | Mês |
| Fonte | SINAN, via painéis da Sala de Situação em Saúde de Salvador |

## 2. Indicadores

| Indicador | Numerador (_y<sub>t</sub>_) | Denominador (_n<sub>t</sub>_) | Direção desejada |
|---|---|---|---|
| Proporção de contatos de hanseníase examinados | contatos examinados no mês | contatos registrados no mês | aumentar |
| Letalidade da leptospirose | óbitos por leptospirose no mês | casos confirmados no mês | reduzir |

Os dois indicadores são proporções. Por isso o modelo usa **numerador e denominador** e não apenas a taxa mensal: meses com poucos casos recebem menos peso, o que evita que valores extremos de meses pequenos (por exemplo, 1 óbito em 1 caso = 100%) dominem a estimativa.

## 3. Análise descritiva

Para cada ano e para os períodos antes e depois dos GTs são apresentados o numerador, o denominador e a proporção com **intervalo de confiança de 95% pelo método de Wilson**, adequado para proporções com denominadores pequenos ou valores próximos de 0% e 100% (20). A distribuição semestral e a média por mês do calendário também são calculadas.

## 4. Modelo de regressão segmentada

Para cada indicador ajusta-se um modelo linear generalizado com função de ligação logit e família **quasibinomial** (17):

$$
\operatorname{logit}(\pi_t) = \beta_0 + \beta_1\,t + \beta_2\,D_t + \beta_3\,(t - t_0)\,D_t \;[+\; \gamma_1 \sin(2\pi m_t/12) + \gamma_2 \cos(2\pi m_t/12)]
$$

com $y_t \sim$ quasibinomial$(n_t, \pi_t)$ e $\operatorname{Var}(y_t) = \phi\, n_t\, \pi_t (1-\pi_t)$, em que:

| Termo | Significado |
|---|---|
| $t$ | meses desde o início da série |
| $D_t$ | 0 antes e 1 a partir do ponto de corte $t_0$ |
| $(t - t_0)D_t$ | meses desde o ponto de corte (0 antes dele) |
| $m_t$ | mês do calendário (1 a 12) |
| $\beta_1$ | tendência antes dos GTs |
| $\beta_2$ | mudança imediata de **nível** no ponto de corte |
| $\beta_3$ | mudança de **tendência** após os GTs |
| $\gamma_1, \gamma_2$ | sazonalidade anual (termos harmônicos), incluídos quando justificados pelo agravo |
| $\phi$ | parâmetro de dispersão, que acomoda variabilidade maior que a binomial (sobredispersão) |

Os coeficientes são apresentados como **razões de chances (OR = e<sup>β</sup>)**. Assim, por exemplo, um OR de mudança de tendência maior que 1 indica que a chance do desfecho passou a crescer mais rápido, a cada mês, do que vinha crescendo antes da intervenção.

**Sazonalidade.** Para a leptospirose, cuja ocorrência depende do período chuvoso, os termos harmônicos são incluídos no modelo principal. Para a hanseníase, a necessidade é verificada nos diagnósticos (ver [Diagnósticos](Diagnosticos)).

## 5. Erros-padrão e inferência

A dependência entre meses consecutivos (autocorrelação) e a heterocedasticidade são tratadas com o estimador **HAC de Newey-West**, com núcleo de Bartlett, defasagem de 3 meses e correção para amostras pequenas $n/(n-k)$ (18,19). Os testes dos coeficientes usam a estatística z e o nível de significância de 5%.

## 6. Cenário contrafactual e efeito acumulado

O **contrafactual** é obtido zerando os termos da intervenção ($\beta_2 = \beta_3 = 0$), ou seja, projetando a tendência anterior para o período pós-intervenção.

O **efeito acumulado** é a diferença, em pontos percentuais, entre a proporção ajustada pelo modelo e a proporção contrafactual no último mês da série:

$$
\Delta_T = \operatorname{logit}^{-1}(\mathbf{x}_T\hat{\boldsymbol\beta}) - \operatorname{logit}^{-1}(\mathbf{x}^{cf}_T\hat{\boldsymbol\beta})
$$

O IC95% de $\Delta_T$ é obtido por **simulação paramétrica**: 5.000 vetores de coeficientes são sorteados de uma normal multivariada com média $\hat{\boldsymbol\beta}$ e covariância de Newey-West, e calculam-se os percentis 2,5 e 97,5 das diferenças.

## 7. Ponto de corte, transição e análise de sensibilidade

O ponto de corte foi definido pela data de início da intervenção, e **não** pelo momento em que a série parece mudar. Escolher o corte a partir dos dados tende a produzir resultados artificialmente significativos (7,14).

Como intervenções de gestão costumam ter efeito gradual ou defasado, a robustez é avaliada em quatro cenários:

| Cenário | Corte | Período de transição | Racional |
|---|---|---|---|
| Nova gestão da SMS | fevereiro de 2025 | — | mudança de gestão anterior aos GTs (cointervenção) |
| **Principal** | **julho de 2025** | — | início dos GTs |
| Efeito defasado | julho de 2025 | julho a dezembro de 2025 excluídos do ajuste | tempo de implantação e de resposta dos serviços |
| Efeito pleno | janeiro de 2026 | — | alternativa ao período de transição |

Não são testados cortes muito próximos do fim da série, porque deixariam poucos meses no período pós-intervenção (6,16).

## 8. Software

R 4.4 (32), com os pacotes `readxl`, `dplyr`, `tidyr`, `stringr`, `lubridate`, `ggplot2`, `patchwork`, `scales`, `sandwich` (19), `lmtest` e `MASS`. Código em [`R/its_peg_sdss.R`](https://github.com/05071982/ITS-PEG-SDSS-Salvador/blob/main/R/its_peg_sdss.R).
