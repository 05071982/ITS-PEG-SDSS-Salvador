# Diagnósticos do modelo

O script gera, para cada indicador, um conjunto de verificações gravadas em `saida_its/<indicador>/diag_*`. Elas servem para checar se os pressupostos do modelo são razoáveis — **não** fazem parte da inferência principal.

## 1. Autocorrelação dos resíduos

- **O que é:** meses vizinhos tendem a se parecer. Se isso não for considerado, os erros-padrão ficam pequenos demais e os valores de p, otimistas.
- **Como é verificada:** função de autocorrelação (ACF) dos resíduos de Pearson até 12 defasagens e **teste de Ljung-Box** com 12 defasagens (22).
- **Leitura:** p > 0,05 no Ljung-Box e barras da ACF dentro das faixas de ±1,96/√n indicam ausência de autocorrelação relevante. Se houver autocorrelação, aumentar `lag_nw` ou testar modelos com estrutura autorregressiva.
- **Arquivo:** `diag_acf_residuos.png`.

## 2. Sobredispersão

- **O que é:** variabilidade maior que a esperada pelo modelo binomial, comum em dados de serviços.
- **Como é verificada:** razão entre a soma dos quadrados dos resíduos de Pearson e os graus de liberdade residuais ($\hat\phi$).
- **Leitura:** $\hat\phi$ > 1 justifica o uso da família quasibinomial (17), que amplia os erros-padrão na proporção adequada.

## 3. Sazonalidade

São usadas três abordagens complementares:

| Abordagem | O que mostra | Arquivo |
|---|---|---|
| Teste dos termos harmônicos (seno e cosseno) no modelo | se há ciclo anual estatisticamente detectável no indicador | `diag_resumo.csv` |
| Decomposição **STL** (_Seasonal-Trend decomposition using Loess_) | separa a série em tendência, componente sazonal e resto (21) | `diag_decomposicao_stl.png` |
| Média do denominador e do indicador por mês do ano | se a sazonalidade está nos casos/registros, no indicador ou em ambos | `diag_media_por_mes_do_ano.csv` |

A decomposição STL exige série mensal completa. Quando faltam meses, eles são **interpolados linearmente apenas para essa visualização exploratória**, e o gráfico informa quantos meses foram interpolados. O modelo de STI usa somente os meses observados.

## 4. Análise espectral e ruído branco

- **Periodograma** da série sem a tendência linear: mostra a intensidade de ciclos de diferentes períodos (2, 3, 6, 12 meses…). Um pico em 12 meses sugere sazonalidade anual.
- **Teste g de Fisher**: verifica se o maior pico do periodograma é maior do que o esperado para **ruído branco** (23). p > 0,05 indica que a série, sem tendência, é compatível com ruído branco, ou seja, sem ciclos dominantes.
- **Arquivo:** `diag_periodograma.png`.

## 5. Resumo

O arquivo `diag_resumo.csv` reúne: estatística e p do Ljung-Box, dispersão, p dos termos sazonais, p do teste de Fisher, período do pico espectral e número de meses interpolados.
