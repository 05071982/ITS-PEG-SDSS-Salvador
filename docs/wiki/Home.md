# ITS-PEG-SDSS-Salvador — Wiki

Bem-vindo(a) à documentação do estudo de **séries temporais interrompidas (STI)** que avalia se a implantação dos **Grupos de Trabalho em Saúde (GTs)** do **Planejamento Estratégico de Gestão (PEG) 2025–2028** modificou o comportamento de indicadores epidemiológicos em Salvador, Bahia.

O estudo é conduzido pela **Sala de Situação em Saúde de Salvador (SDSS)**, da Secretaria Municipal da Saúde (SMS).

> Esta wiki descreve **motivação, fundamentação teórica e métodos**. Ela não apresenta dados nem resultados, que são divulgados nos boletins epidemiológicos da SMS Salvador.

## Páginas

| Página | Conteúdo |
|---|---|
| [Motivação](Motivacao) | Contexto do PEG, papel dos GTs e pergunta do estudo |
| [Revisão de literatura](Revisao-de-literatura) | Monitoramento de metas e governança em saúde; STI na avaliação de intervenções; os dois agravos |
| [Métodos](Metodos) | Desenho, indicadores, modelo, ponto de corte, sensibilidade |
| [Diagnósticos](Diagnosticos) | Autocorrelação, sobredispersão, sazonalidade, decomposição e análise espectral |
| [Dicionário de dados](Dicionario-de-dados) | Arquivos de entrada, regras de limpeza e cuidados na extração |
| [Como executar](Como-executar) | Passo a passo para rodar o código e onde ficam as saídas |
| [Limitações](Limitacoes) | Ameaças à validade e como foram tratadas |
| [Referências](Referencias) | Referências citadas (Vancouver) |

## Resumo do desenho

```
 Dados mensais (SINAN)  ──►  Indicador = numerador / denominador
            │
            ▼
 Regressão segmentada (GLM quasibinomial)
   tendência pré  +  mudança de nível  +  mudança de tendência  [+ sazonalidade]
            │
            ▼
 Erros-padrão de Newey-West  ──►  OR, IC95%, efeito vs. contrafactual
            │
            ▼
 Sensibilidade ao ponto de corte  +  diagnósticos dos resíduos
```
