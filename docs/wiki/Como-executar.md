# Como executar

## Requisitos

- R ≥ 4.4 (o RStudio é opcional).
- Pacotes: `readxl`, `dplyr`, `tidyr`, `stringr`, `lubridate`, `ggplot2` (≥ 3.5.2), `patchwork`, `scales`, `sandwich`, `lmtest`, `MASS`. O script instala os que faltarem e atualiza o `ggplot2` quando necessário.

## Passo a passo

```bash
git clone https://github.com/05071982/ITS-PEG-SDSS-Salvador.git
cd ITS-PEG-SDSS-Salvador
# copie os quatro arquivos de entrada para dados/ (ver Dicionário de dados)
Rscript R/its_peg_sdss.R
```

No RStudio: abra o projeto na raiz do repositório, reinicie a sessão (_Session → Restart R_) e use _Source_. Também é possível rodar por partes:

| Seções | O que fazem |
|---|---|
| 0 a 7 | pacotes, configuração, leitura dos dados e funções — **rodar sempre** |
| PARTE A | hanseníase |
| PARTE B | leptospirose |
| PARTE C | painel conjunto (requer A e B) |

## Saídas

Em `saida_its/hanseniase/` e `saida_its/leptospirose/`:

| Arquivo | Conteúdo |
|---|---|
| `tabela1_valores_absolutos.csv` | numerador, denominador, % e IC95% por ano e por período |
| `descritivo_semestral.csv` | indicador por semestre |
| `grafico1_descritivo.png` | barras anuais |
| `grafico2_its.png` | série interrompida com contrafactual |
| `its_grafico_sdss.png` | versão do gráfico para apresentação |
| `tabela2_modelo_its.csv` | OR, IC95%, p e efeito acumulado |
| `tabela3_sensibilidade.csv` e `sensibilidade/` | cenários alternativos de ponto de corte |
| `diag_*` | diagnósticos (ver [Diagnósticos](Diagnosticos)) |

Os CSV usam ponto e vírgula como separador e vírgula decimal (`write.csv2`), para abrir diretamente no Excel em português.

## Adaptar para outro indicador

1. Prepare dois arquivos (numerador e denominador mensais) e leia-os na seção 2, gerando um data frame com as colunas `data`, `num`, `den` e `valor`.
2. Crie uma lista de configuração como `cfg_hans`, informando nome, pasta de saída, rótulos, meta (ou `NA`), direção desejada (`"subir"` ou `"descer"`) e uso de sazonalidade.
3. Chame `analisar_indicador(seu_df, sua_cfg)`.

## Ajustes mais comuns

| Quero… | Altere |
|---|---|
| mudar a data da intervenção | `data_gt` |
| testar outros cortes ou transições | `cenarios` |
| considerar mais autocorrelação | `lag_nw` |
| incluir ou retirar a sazonalidade | `sazonal_hans`, `sazonal_lepto` |

> Dica: ao fechar o script no RStudio depois de atualizá-lo por fora (por exemplo, com `git pull`), escolha **não salvar** para não sobrescrever a versão nova.
