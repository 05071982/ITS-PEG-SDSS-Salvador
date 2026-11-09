# Dados de entrada

Esta pasta **não é versionada**: os arquivos contêm dados de vigilância (SINAN) extraídos do painel da Sala de Situação em Saúde de Salvador e não são publicados. Coloque aqui os quatro arquivos abaixo antes de executar `R/its_peg_sdss.R`.

| Arquivo | Conteúdo | Coluna 1 (rótulo do mês) | Coluna 2 |
|---|---|---|---|
| `Casos_Leptospirose.xlsx` | Casos confirmados de leptospirose por mês | `Março/2022` | número de casos (denominador) |
| `obitos_Leptospirose.xlsx` | Óbitos por leptospirose por mês | `Março/2022` | número de óbitos (numerador) |
| `Contatos_Hanseniase_Registrados.xlsx` | Contatos de casos de hanseníase registrados por mês | `Mar-22` | número de contatos registrados (denominador) |
| `Contatos_Hanseniase_Examinados.xlsx` | Contatos de casos de hanseníase examinados por mês | `Mar-22` | número de contatos examinados (numerador) |

Regras aplicadas pelo script:

- Apenas as duas primeiras colunas de cada planilha são lidas; os nomes das colunas são ignorados.
- Meses com casos e sem óbito (ausentes no arquivo de óbitos) recebem numerador 0.
- Meses com denominador igual a 0 são descartados.
- O mês corrente (incompleto) e meses futuros são removidos.
- Rótulos com ano truncado (ex.: `Fevereiro/202`) são descartados com aviso. Garanta que o rótulo seja exportado completo (ex.: `Fevereiro/2022`); alguns painéis cortam o texto em 13 caracteres e juntam todos os fevereiros em um único registro — ver a página **Dicionário de dados** da wiki.
