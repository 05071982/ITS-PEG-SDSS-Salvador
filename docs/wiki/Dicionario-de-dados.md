# Dicionário de dados

Os dados **não são publicados** neste repositório. Esta página descreve o formato esperado para que o código possa ser reproduzido com dados próprios ou atualizados.

## Arquivos de entrada (pasta `dados/`)

| Arquivo | Variável | Papel no modelo | Rótulo do mês |
|---|---|---|---|
| `Casos_Leptospirose.xlsx` | casos confirmados de leptospirose | denominador (_n<sub>t</sub>_) | `Março/2022` |
| `obitos_Leptospirose.xlsx` | óbitos por leptospirose | numerador (_y<sub>t</sub>_) | `Março/2022` |
| `Contatos_Hanseniase_Registrados.xlsx` | contatos registrados de casos de hanseníase | denominador (_n<sub>t</sub>_) | `Mar-22` |
| `Contatos_Hanseniase_Examinados.xlsx` | contatos examinados | numerador (_y<sub>t</sub>_) | `Mar-22` |

Cada planilha deve ter **duas colunas**: o rótulo do mês e o valor. Os nomes das colunas são ignorados.

## Regras de limpeza aplicadas pelo script

1. Numerador e denominador são unidos pelo rótulo do mês.
2. Mês presente no denominador e ausente no numerador recebe numerador **0** (ex.: mês com casos e sem óbito).
3. Meses com denominador 0 são descartados (não há como calcular a proporção).
4. O mês corrente, ainda incompleto, e meses futuros são removidos.
5. O script avisa quais meses estão ausentes na série.

## Cuidados na extração

- **Rótulos truncados.** Alguns painéis limitam o texto do rótulo a 13 caracteres. Como `Fevereiro/2026` tem 14, todos os fevereiros podem ser agregados em um único registro `Fevereiro/202`. O script descarta esse registro e emite um aviso. Para evitar a perda, exporte o rótulo completo.
- **Data de referência.** Use sempre a mesma data de referência (notificação, diagnóstico, avaliação do contato) em todos os meses e documente a escolha.
- **Atraso de encerramento.** Óbitos e exames de contatos dos meses mais recentes podem ainda estar em investigação ou sem registro. Registre a **data de extração** e considere reanalisar após o encerramento oportuno.
- **Mesma definição ao longo do tempo.** Mudanças de critério, de sistema ou de abrangência territorial durante a série podem produzir quebras artificiais, confundíveis com efeito da intervenção.

## Definições operacionais

| Indicador | Cálculo |
|---|---|
| Proporção de contatos examinados | contatos examinados ÷ contatos registrados × 100 |
| Letalidade da leptospirose | óbitos por leptospirose ÷ casos confirmados × 100 |

As definições seguem as orientações do Ministério da Saúde para a vigilância da hanseníase e da leptospirose (9,26,30).
