# ITS-PEG-SDSS-Salvador

**Séries temporais interrompidas para avaliar o efeito dos Grupos de Trabalho em Saúde (GTs) do Planejamento Estratégico de Gestão (PEG) sobre indicadores epidemiológicos em Salvador, Bahia.**

Sala de Situação em Saúde de Salvador (SDSS) · Secretaria Municipal da Saúde de Salvador

---

## Sobre o estudo

O PEG 2025–2028 da Prefeitura de Salvador define metas para indicadores de saúde e institui Grupos de Trabalho em Saúde (GTs) que monitoram essas metas periodicamente, com a participação do secretário municipal de saúde, diretorias, áreas técnicas, representantes de todos os níveis de atenção e da Sala de Situação.

Este repositório reúne o **protocolo analítico e o código** usados para responder à pergunta:

> A implantação dos GTs modificou o nível ou a tendência dos indicadores monitorados?

Na primeira etapa são analisados dois indicadores ligados a metas do PEG:

| Indicador | Numerador | Denominador | Meta do PEG relacionada |
|---|---|---|---|
| Proporção de contatos de hanseníase examinados | contatos examinados | contatos registrados | aumentar a detecção precoce da hanseníase |
| Letalidade da leptospirose | óbitos | casos | reduzir a letalidade da leptospirose |

> ⚠️ Este repositório **não contém dados nem resultados**. Os dados são de vigilância (SINAN) e ficam fora do controle de versão. Os resultados são divulgados nos boletins epidemiológicos da SMS Salvador.

## Desenho em uma frase

Série temporal interrompida (STI) com dados mensais, regressão segmentada em GLM quasibinomial, erros-padrão de Newey-West, ponto de corte definido a priori (início dos GTs) e análise de sensibilidade com pontos de corte alternativos e período de transição.

A explicação completa está na **[wiki](../../wiki)**:

- [Motivação](../../wiki/Motivacao)
- [Revisão de literatura](../../wiki/Revisao-de-literatura)
- [Métodos](../../wiki/Metodos)
- [Diagnósticos do modelo](../../wiki/Diagnosticos)
- [Dicionário de dados](../../wiki/Dicionario-de-dados)
- [Como executar](../../wiki/Como-executar)
- [Limitações](../../wiki/Limitacoes)
- [Referências](../../wiki/Referencias)

Uma cópia das páginas da wiki está em [`docs/wiki/`](docs/wiki).

## Estrutura

```
ITS-PEG-SDSS-Salvador/
├── R/
│   └── its_peg_sdss.R     # análise completa (Parte A: hanseníase; Parte B: leptospirose)
├── dados/
│   └── README.md          # formato esperado dos arquivos (dados não versionados)
├── docs/wiki/             # cópia das páginas da wiki
├── LICENSE
└── README.md
```

## Como executar

1. Instale o R (≥ 4.4) e, opcionalmente, o RStudio.
2. Coloque os quatro arquivos de entrada em `dados/` (ver [`dados/README.md`](dados/README.md)).
3. A partir da raiz do repositório:

```bash
Rscript R/its_peg_sdss.R
```

O script instala os pacotes que faltarem (`readxl`, `dplyr`, `tidyr`, `stringr`, `lubridate`, `ggplot2`, `patchwork`, `scales`, `sandwich`, `lmtest`, `MASS`) e grava as saídas em `saida_its/hanseniase/` e `saida_its/leptospirose/`:

| Saída | Descrição |
|---|---|
| `tabela1_valores_absolutos.csv` | numerador, denominador, proporção e IC95% (Wilson) por ano e por período pré/pós GTs |
| `grafico1_descritivo.png` | barras anuais do indicador |
| `grafico2_its.png` | série interrompida com ajuste pré/pós e cenário contrafactual |
| `tabela2_modelo_its.csv` | razões de chances (OR), IC95%, p e efeito no último mês |
| `tabela3_sensibilidade.csv`, `sensibilidade/` | resultados com pontos de corte alternativos |
| `diag_*` | autocorrelação dos resíduos, decomposição STL, periodograma, sazonalidade |

## Parâmetros principais

Todos ficam na seção **1. CONFIGURAÇÃO** do script:

| Parâmetro | Função |
|---|---|
| `data_gt` | mês de início da intervenção (ponto de corte principal) |
| `cenarios` | pontos de corte e períodos de transição da análise de sensibilidade |
| `sazonal_lepto`, `sazonal_hans` | inclusão de termos harmônicos anuais |
| `lag_nw` | defasagem do estimador de Newey-West |
| `meta_lepto`, `base_lepto` | meta e linha de base públicas do PEG, usadas apenas como linhas de referência nos gráficos |

## Como citar

Sala de Situação em Saúde de Salvador (SDSS). ITS-PEG-SDSS-Salvador: séries temporais interrompidas para avaliação dos Grupos de Trabalho do PEG [código-fonte]. Salvador: Secretaria Municipal da Saúde; 2026. Disponível em: https://github.com/05071982/ITS-PEG-SDSS-Salvador

## Licença

Código sob licença [MIT](LICENSE).
