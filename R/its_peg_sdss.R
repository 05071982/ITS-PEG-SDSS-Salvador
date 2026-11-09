# =====================================================================
#  Séries Temporais Interrompidas (ITS) — PEG 2025-2028 · SDSS Salvador
#  Efeito da implantação dos GTs (jul/2025) sobre:
#    PARTE A — Proporção de contatos de hanseníase examinados
#    PARTE B — Letalidade da leptospirose
#  Gera tabelas, gráficos descritivos e de STI, análise de sensibilidade
#  e diagnósticos (resíduos, sazonalidade, espectro).
#  Repositório: https://github.com/05071982/ITS-PEG-SDSS-Salvador
#  Execute a partir da raiz do repositório; os dados ficam em dados/ (não versionados).
#  Rode as seções 0 a 7 e depois a PARTE A e/ou a PARTE B.
# =====================================================================
# Remover todos os objetos do ambiente
rm(list = ls())

## 0. Pacotes ----------------------------------------------------------
pkgs <- c("readxl", "dplyr", "tidyr", "stringr", "lubridate", "ggplot2",
          "patchwork", "scales", "sandwich", "lmtest", "MASS")
novos <- pkgs[!pkgs %in% rownames(installed.packages())]
# patchwork recente exige ggplot2 >= 3.5.2 (função is_ggplot).
# Se o ggplot2 instalado for mais antigo, atualiza os dois.
if ("ggplot2" %in% rownames(installed.packages()) &&
    packageVersion("ggplot2") < "3.5.2") {
  if ("ggplot2" %in% loadedNamespaces())
    stop("ggplot2 desatualizado e já carregado. Reinicie o R (Ctrl+Shift+F10 no RStudio) e rode de novo.")
  novos <- union(novos, c("ggplot2", "patchwork"))
}
if (length(novos)) install.packages(novos)
suppressPackageStartupMessages(invisible(lapply(pkgs, library, character.only = TRUE)))
select <- dplyr::select   # evita conflito com MASS::select

## 1. CONFIGURAÇÃO — edite aqui ----------------------------------------
# Numerador e denominador mensais (exportados do painel da Sala de Situação)
# Formato esperado: ver dados/README.md
pasta_dados   <- "dados"
arq_lepto_den <- file.path(pasta_dados, "Casos_Leptospirose.xlsx")            # casos
arq_lepto_num <- file.path(pasta_dados, "obitos_Leptospirose.xlsx")           # óbitos
arq_hans_num  <- file.path(pasta_dados, "Contatos_Hanseniase_Examinados.xlsx")
arq_hans_den  <- file.path(pasta_dados, "Contatos_Hanseniase_Registrados.xlsx")

# Ponto de corte principal: início dos GTs (2º semestre de 2025)
data_gt <- as.Date("2025-07-01")

# Cenários de sensibilidade: c(início, fim da transição)
# fim da transição = NA -> sem período de transição.
# Com transição, os meses entre início e fim ficam fora do ajuste (efeito defasado).
cenarios <- list(
  "Fev/25 · nova gestão SMS"      = c("2025-02-01", NA),
  "Jul/25 · início dos GTs"       = c("2025-07-01", NA),
  "Jul/25 + transição jul–dez/25" = c("2025-07-01", "2025-12-01"),
  "Jan/26"                        = c("2026-01-01", NA))

# Metas do PEG (NA = não desenhar a linha de meta)
meta_lepto <- 0.111                   # meta pública do PEG 2025-2028 (linha de base 2024: 13,6%)
base_lepto <- 0.136                   # linha de base pública do PEG (2024)
meta_hans  <- NA                      # a meta de 53% é de DETECÇÃO PRECOCE,
                                      # não de contatos examinados.

sazonal_lepto <- TRUE                 # leptospirose tem sazonalidade (chuvas)
sazonal_hans  <- FALSE
lag_nw        <- 3                    # defasagem para erros de Newey-West
pasta_saida   <- "saida_its"
dir.create(pasta_saida, showWarnings = FALSE)

## 2. Leitura e limpeza ------------------------------------------------
mes_num <- c(jan = 1, fev = 2, mar = 3, abr = 4, mai = 5, jun = 6,
             jul = 7, ago = 8, set = 9, out = 10, nov = 11, dez = 12)
mes_atual <- floor_date(Sys.Date(), "month")

ler_contagem <- function(arq, nome_col) {
  d <- read_excel(arq, col_types = "text")[, 1:2]
  names(d) <- c("rotulo", nome_col)
  d[[nome_col]] <- suppressWarnings(as.numeric(str_replace(d[[nome_col]], ",", ".")))
  d
}

# Leptospirose: rótulos "Março/2022". ATENÇÃO: o Qlik corta o rótulo em 13
# caracteres, então TODOS os fevereiros viram "Fevereiro/202" (soma 2022-2026).
# Essa linha é descartada até os fevereiros serem exportados separadamente.
lepto <- ler_contagem(arq_lepto_den, "den") |>
  left_join(ler_contagem(arq_lepto_num, "num"), by = "rotulo") |>
  mutate(num     = coalesce(num, 0),                 # mês com casos e sem óbito = 0
         rotulo  = str_trim(rotulo),
         mes     = unname(mes_num[str_to_lower(str_sub(rotulo, 1, 3))]),
         ano_txt = str_extract(rotulo, "(?<=/)\\d+"))
trunc <- lepto |> filter(nchar(ano_txt) != 4)
if (nrow(trunc)) message("[Leptospirose] descartado rótulo truncado: ",
                         paste(trunc$rotulo, collapse = ", "), " (", sum(trunc$den),
                         " casos / ", sum(trunc$num), " óbitos somando todos os fevereiros)")
lepto <- lepto |>
  filter(nchar(ano_txt) == 4, den > 0) |>
  mutate(data = make_date(as.integer(ano_txt), mes, 1), valor = num / den) |>
  arrange(data)

# Hanseníase: rótulos "Jan-24"
hans <- ler_contagem(arq_hans_num, "num") |>
  left_join(ler_contagem(arq_hans_den, "den"), by = "rotulo") |>
  filter(den > 0) |>                                  # descarta meses sem registro
  mutate(mes  = unname(mes_num[str_to_lower(str_sub(rotulo, 1, 3))]),
         ano  = 2000L + as.integer(str_sub(rotulo, -2)),
         data = make_date(ano, mes, 1), valor = num / den) |>
  arrange(data)

# Remove mês corrente (incompleto) e meses futuros
checar_futuro <- function(df, nome) {
  fora <- df |> filter(data >= mes_atual)
  if (nrow(fora)) message("[", nome, "] removidos (mês corrente/futuro): ",
                          paste(format(fora$data, "%m/%Y"), collapse = ", "))
  df |> filter(data < mes_atual)
}
hans  <- checar_futuro(hans,  "Hanseníase")
lepto <- checar_futuro(lepto, "Leptospirose")

faltantes <- function(df, nome) {
  todos <- seq(min(df$data), max(df$data), by = "month")
  aus <- todos[!todos %in% df$data]
  if (length(aus)) message("[", nome, "] meses ausentes: ",
                           paste(format(aus, "%m/%Y"), collapse = ", "))
}
faltantes(lepto, "Leptospirose")
faltantes(hans,  "Hanseníase")

## 3. Funções do modelo ITS --------------------------------------------
meses_entre <- function(de, ate) (year(ate) - year(de)) * 12 + (month(ate) - month(de))

prep_its <- function(df, origem, data_int) {
  df |> mutate(
    tempo = meses_entre(origem, data),                 # tendência pré
    pos   = as.integer(data >= data_int),              # mudança de nível
    t_pos = pos * meses_entre(data_int, data),         # mudança de tendência
    sen   = sin(2 * pi * month(data) / 12),            # sazonalidade
    cosn  = cos(2 * pi * month(data) / 12))
}

ajustar_its <- function(df, sazonal = FALSE) {
  rhs <- "tempo + pos + t_pos"
  if (sazonal) rhs <- paste(rhs, "+ sen + cosn")
  tem_den <- all(c("num", "den") %in% names(df)) && any(!is.na(df$den))
  if (tem_den) {
    mod <- glm(as.formula(paste("cbind(num, den - num) ~", rhs)),
               family = quasibinomial(), data = df)
    inv <- plogis
  } else {
    mod <- lm(as.formula(paste("valor ~", rhs)), data = df)
    inv <- identity
  }
  V <- NeweyWest(mod, lag = lag_nw, prewhite = FALSE, adjust = TRUE)
  list(mod = mod, V = V, inv = inv, tem_den = tem_den,
       teste = coeftest(mod, vcov. = V))
}

matriz_X <- function(fit, novo) model.matrix(delete.response(terms(fit$mod)), data = novo)

prever <- function(fit, novo, contrafactual = FALSE) {
  periodo <- novo$pos
  if (contrafactual) novo <- mutate(novo, pos = 0L, t_pos = 0)
  X   <- matriz_X(fit, novo)
  eta <- drop(X %*% coef(fit$mod))
  se  <- sqrt(rowSums((X %*% fit$V) * X))
  tibble(data = novo$data, periodo = periodo,
         ajuste = fit$inv(eta),
         li = pmax(fit$inv(eta - 1.96 * se), 0),
         ls = pmin(fit$inv(eta + 1.96 * se), 1))
}

# Efeito no último mês: observado-ajustado menos contrafactual (p.p.)
efeito_final <- function(fit, grade, nsim = 5000) {
  set.seed(2026)
  ult <- tail(grade, 1)
  Xr  <- matriz_X(fit, ult)
  Xc  <- matriz_X(fit, mutate(ult, pos = 0L, t_pos = 0))
  B   <- MASS::mvrnorm(nsim, coef(fit$mod), fit$V)
  d   <- drop(fit$inv(B %*% t(Xr)) - fit$inv(B %*% t(Xc)))
  c(dif = unname(fit$inv(sum(Xr * coef(fit$mod))) - fit$inv(sum(Xc * coef(fit$mod)))),
    li  = unname(quantile(d, .025)),
    ls  = unname(quantile(d, .975)))
}

## 4. Visual -----------------------------------------------------------
cores <- c(pre = "#8C97A4", pos = "#0E7C7B", cf = "#D1495B", tinta = "#1F2A37")

virgula <- function(x, d = 1) formatC(x, format = "f", digits = d, decimal.mark = ",")
rotulo_mes <- function(x) ifelse(is.na(x), "", paste0(names(mes_num)[month(x)], "/", format(x, "%y")))

tema_sdss <- function() {
  theme_minimal(base_size = 13) +
    theme(plot.title          = element_text(face = "bold", size = 16, colour = cores[["tinta"]]),
          plot.subtitle       = element_text(colour = "#4B5563", size = 11, lineheight = 1.15, margin = margin(t = 4, b = 14)),
          plot.caption        = element_text(colour = "#6B7280", size = 9, hjust = 0, margin = margin(t = 12)),
          plot.title.position = "plot", plot.caption.position = "plot",
          panel.grid.minor    = element_blank(),
          panel.grid.major.x  = element_blank(),
          panel.grid.major.y  = element_line(colour = "#E5E7EB", linewidth = .4),
          axis.text           = element_text(colour = "#4B5563"),
          plot.background     = element_rect(fill = "white", colour = NA),
          plot.margin         = margin(18, 26, 12, 18))
}

linha_coef <- function(fit, termo, rotulo, unid) {
  b <- fit$teste[termo, 1]; p <- fit$teste[termo, 4]
  ptxt <- ifelse(p < .001, "p < 0,001", paste0("p = ", virgula(p, 3)))
  if (fit$tem_den) paste0(rotulo, ": OR ", virgula(exp(b), 3), " (", ptxt, ")")
  else paste0(rotulo, ": ", ifelse(b >= 0, "+", "−"), virgula(abs(b) * 100, 2), " ", unid, " (", ptxt, ")")
}

manchete <- function(nome, fit, melhor) {
  b <- fit$teste["t_pos", 1]; p <- fit$teste["t_pos", 4]
  favor <- if (melhor == "subir") b > 0 else b < 0
  if (favor && p < .05) paste0(nome, ": melhora significativa da tendência após os GTs")
  else if (favor)       paste0(nome, ": tendência favorável após os GTs, ainda sem significância")
  else                  paste0(nome, ": sem sinal de melhora após os GTs")
}

grafico_its <- function(df, fit, grade, data_int, nome, meta, melhor, inicio = data_int, excl = NULL) {
  real <- prever(fit, grade)
  cf   <- prever(fit, filter(grade, data >= data_int), contrafactual = TRUE)
  ef   <- efeito_final(fit, grade)
  x_min <- min(grade$data); x_max <- max(grade$data)
  y_top <- max(c(df$valor, meta), na.rm = TRUE)
  favor_ef <- if (melhor == "subir") ef[["dif"]] > 0 else ef[["dif"]] < 0
  cor_ef <- if (favor_ef) cores[["pos"]] else cores[["cf"]]

  g <- ggplot() +
    annotate("rect", xmin = data_int, xmax = x_max + 20, ymin = -Inf, ymax = Inf,
             fill = cores[["pos"]], alpha = .06)
  if (inicio < data_int) {
    g <- g +
      annotate("rect", xmin = inicio, xmax = data_int, ymin = -Inf, ymax = Inf,
               fill = "#F2C14E", alpha = .15) +
      annotate("text", x = inicio + (data_int - inicio) / 2, y = 0, vjust = -.5, size = 3.2,
               colour = "#8A6D1F", label = "transição\n(fora do ajuste)")
  }
  if (!is.null(excl) && nrow(excl))
    g <- g + geom_point(data = excl, aes(data, valor), shape = 21, size = 2.4,
                        colour = "#8A6D1F", fill = "white", stroke = .8)

  if (!is.na(meta)) {
    g <- g +
      geom_hline(yintercept = meta, colour = cores[["tinta"]], linetype = "22", linewidth = .5) +
      annotate("label", x = x_min, y = meta, vjust = -.35, hjust = 0, size = 3.6,
               fontface = "bold", colour = cores[["tinta"]], fill = "white",
               linewidth = 0, label.padding = unit(.15, "lines"),
               label = paste0("Meta PEG: ", virgula(meta * 100), "%"))
  }

  g +
    geom_ribbon(data = cf, aes(data, ymin = li, ymax = ls), fill = cores[["cf"]], alpha = .12) +
    geom_line(data = cf, aes(data, ajuste), colour = cores[["cf"]], linetype = "42", linewidth = 1) +
    geom_ribbon(data = real, aes(data, ymin = li, ymax = ls, group = periodo,
                                 fill = factor(periodo)), alpha = .14) +
    geom_point(data = df, aes(data, valor, colour = factor(pos)), size = 2.4, alpha = .8) +
    geom_line(data = real, aes(data, ajuste, group = periodo, colour = factor(periodo)),
              linewidth = 1.5, lineend = "round") +
    geom_vline(xintercept = inicio, colour = cores[["tinta"]], linewidth = .4) +
    annotate("label", x = inicio, y = y_top * 1.08, hjust = 0, vjust = 1, size = 3.3,
             fontface = "bold", colour = cores[["tinta"]], fill = "white", linewidth = 0,
             label = paste0(" GTs (", rotulo_mes(inicio), ")")) +
    scale_colour_manual(values = c(`0` = cores[["pre"]], `1` = cores[["pos"]]), guide = "none") +
    scale_fill_manual(values = c(`0` = cores[["pre"]], `1` = cores[["pos"]]), guide = "none") +
    scale_y_continuous(labels = label_percent(accuracy = 1, decimal.mark = ","),
                       breaks = function(l) { b <- breaks_pretty(6)(l); b[b <= 1] }) +
    scale_x_date(labels = rotulo_mes, expand = expansion(mult = .01),
                 breaks = seq(floor_date(x_min, "year"), x_max, by = "6 months")) +
    coord_cartesian(ylim = c(0, y_top * 1.08)) +
    labs(title = manchete(nome, fit, melhor),
         subtitle = paste0(linha_coef(fit, "t_pos", "Mudança de tendência", "p.p./mês"), "   ·   ",
                          linha_coef(fit, "pos", "Mudança de nível", "p.p."), "\n",
                          "Efeito no último mês vs. cenário sem GTs: ",
                          ifelse(ef[["dif"]] >= 0, "+", "−"), virgula(abs(ef[["dif"]]) * 100), " p.p. (IC95% ",
                          virgula(ef[["li"]] * 100), " a ", virgula(ef[["ls"]] * 100), ")"),
         x = NULL, y = NULL,
         caption = paste0(
           "Pontos: valores mensais · Linha cinza: tendência antes dos GTs · Linha verde: após os GTs · ",
           "Tracejado vermelho: cenário contrafactual (tendência pré projetada) com IC95%.\n",
           "Regressão segmentada com erros-padrão de Newey-West (lag ", lag_nw, ")",
           if (fit$tem_den) ", GLM quasibinomial" else "",
           ". Fonte: Sala de Situação em Saúde de Salvador (SDSS/SMS).")) +
    tema_sdss()
}

## 5. Funções dos boletins: tabelas, gráficos e diagnósticos ---------
BOL <- list(navy = "#063D71", blue = "#006CB5", gray = "#8C97A4", red = "#C0392B", light = "#E1EBF4")

fmt_n  <- function(x) formatC(x, format = "d", big.mark = ".")
fmt_p  <- function(x, d = 1) formatC(x, format = "f", digits = d, decimal.mark = ",")
fmt_pv <- function(p) ifelse(p < .001, "<0,001", formatC(p, format = "f", digits = 3, decimal.mark = ","))
fmt_ic <- function(a, b, d = 1) paste0(fmt_p(a, d), "–", fmt_p(b, d))

# IC95% de Wilson para proporções
wilson <- function(x, n, z = 1.96) {
  p <- x / n; d <- 1 + z^2 / n
  centro <- (p + z^2 / (2 * n)) / d
  h <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / d
  cbind(centro - h, centro + h)
}

tema_bol <- function() {
  theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour = "#E5E7EB", linewidth = .4),
          axis.line.x = element_line(colour = "#8C97A4", linewidth = .4),
          axis.text = element_text(colour = "#333333"),
          plot.caption = element_text(colour = "#6B7280", size = 8, hjust = 0),
          plot.background = element_rect(fill = "white", colour = NA))
}

# Tabela 1: valores absolutos por ano e por período (pré/pós GTs)
tabela1 <- function(df) {
  ult <- max(df$data)
  anual <- df |>
    group_by(grupo = as.character(year(data))) |>
    summarise(num = sum(num), den = sum(den), .groups = "drop")
  if (month(ult) < 12)
    anual$grupo[anual$grupo == as.character(year(ult))] <- paste0(year(ult), "*")
  pre <- df |> filter(data < data_gt); pos <- df |> filter(data >= data_gt)
  per <- tibble(
    grupo = c(paste0("Pré-GTs (", rotulo_mes(min(pre$data)), "–", rotulo_mes(max(pre$data)), ")"),
              paste0("Pós-GTs (", rotulo_mes(min(pos$data)), "–", rotulo_mes(max(pos$data)), ")"),
              "Total"),
    num = c(sum(pre$num), sum(pos$num), sum(df$num)),
    den = c(sum(pre$den), sum(pos$den), sum(df$den)))
  t <- bind_rows(anual, per)
  ic <- wilson(t$num, t$den)
  t |> mutate(pct = 100 * num / den, ic_inf = 100 * ic[, 1], ic_sup = 100 * ic[, 2])
}

formatar_t1 <- function(t1, rot_den, rot_num, rot_pct) {
  out <- tibble(a = t1$grupo, b = fmt_n(t1$den), c = fmt_n(t1$num),
                d = fmt_p(t1$pct), e = fmt_ic(t1$ic_inf, t1$ic_sup))
  names(out) <- c("Ano/período", rot_den, rot_num, rot_pct, "IC95%")
  out
}

# Gráfico 1: barras anuais do indicador (rótulo interno = numerador/denominador)
grafico_desc <- function(t1, titulo_y, meta = NA, base = NA) {
  d <- t1 |> filter(!str_detect(grupo, "GTs|Total")) |>
    mutate(p = num / den, grupo = factor(grupo, levels = grupo))
  top <- max(c(d$p, meta, base), na.rm = TRUE) * 1.22
  g <- ggplot(d, aes(grupo, p)) +
    geom_col(fill = BOL$blue, width = .62) +
    geom_label(aes(label = paste0(fmt_p(100 * p), "%")), vjust = -.25, fontface = "bold",
               size = 3.6, fill = "white", linewidth = 0, label.padding = unit(.12, "lines")) +
    geom_text(aes(y = top * .015, label = paste0(num, "/", den)), vjust = 0,
              colour = "white", size = 3)
  ref <- tibble(y = c(base, meta),
                lab = c(paste0("Linha de base PEG (2024): ", fmt_p(100 * base), "%"),
                        paste0("Meta PEG 2028: ", fmt_p(100 * meta), "%"))) |>
    filter(!is.na(y))
  if (nrow(ref)) {
    lt <- setNames(ifelse(str_detect(ref$lab, "Meta"), "dashed", "dotted"), ref$lab)
    cl <- setNames(ifelse(str_detect(ref$lab, "Meta"), BOL$red, "#555555"), ref$lab)
    g <- g + geom_hline(data = ref, aes(yintercept = y, linetype = lab, colour = lab), linewidth = .6) +
      scale_linetype_manual(NULL, values = lt) + scale_colour_manual(NULL, values = cl)
  }
  g + scale_y_continuous(labels = label_percent(accuracy = 1, decimal.mark = ","),
                         limits = c(0, top), expand = expansion(mult = c(0, .02))) +
    labs(x = "Ano", y = titulo_y,
         caption = "Rótulos internos: numerador/denominador. *Ano incompleto.") +
    tema_bol() +
    theme(legend.position = "inside", legend.position.inside = c(.99, .99),
          legend.justification = c(1, 1), legend.text = element_text(size = 8))
}

# Gráfico 2: série interrompida no padrão do boletim
grafico_boletim <- function(res, ylab, meta = NA) {
  df <- res$df_aj
  linhas <- bind_rows(
    res$real |> filter(periodo == 0) |> mutate(serie = "Ajuste antes dos GTs"),
    res$real |> filter(periodo == 1) |> mutate(serie = "Ajuste após os GTs"),
    res$cf |> mutate(serie = "Cenário sem GTs (contrafactual)"))
  cores_l <- c("Ajuste antes dos GTs" = BOL$gray, "Ajuste após os GTs" = BOL$navy,
               "Cenário sem GTs (contrafactual)" = BOL$red)
  tipos_l <- c("Ajuste antes dos GTs" = "solid", "Ajuste após os GTs" = "solid",
               "Cenário sem GTs (contrafactual)" = "dashed")
  y_top <- min(1.04, max(df$valor) * 1.1)
  g <- ggplot() +
    annotate("rect", xmin = res$data_int, xmax = max(df$data) + 20, ymin = -Inf, ymax = Inf,
             fill = BOL$light, alpha = .7) +
    geom_ribbon(data = linhas, aes(data, ymin = li, ymax = ls, fill = serie),
                alpha = .15, show.legend = FALSE) +
    geom_point(data = df, aes(data, valor, size = den),
               colour = ifelse(df$pos == 1, BOL$blue, BOL$gray), alpha = .65) +
    geom_line(data = linhas, aes(data, ajuste, colour = serie, linetype = serie), linewidth = 1.1) +
    geom_vline(xintercept = res$inicio, linewidth = .4) +
    annotate("text", x = res$data_int, y = y_top, hjust = 0, vjust = 1, fontface = "bold", size = 3.3,
             label = paste0("  Implantação dos GTs (", rotulo_mes(res$inicio), ")"))
  if (res$inicio < res$data_int)
    g <- g + annotate("rect", xmin = res$inicio, xmax = res$data_int, ymin = -Inf, ymax = Inf,
                      fill = "#F2C14E", alpha = .15)
  if (!is.na(meta))
    g <- g + geom_hline(yintercept = meta, linetype = "dotted", linewidth = .5) +
      annotate("text", x = min(df$data), y = meta, hjust = 0, vjust = -.4, size = 3,
               label = paste0("Meta PEG ", fmt_p(100 * meta), "%"))
  g + scale_colour_manual(NULL, values = cores_l) +
    scale_linetype_manual(NULL, values = tipos_l) +
    scale_fill_manual(values = cores_l, guide = "none") +
    scale_size_area(max_size = 6, guide = "none") +
    scale_y_continuous(labels = label_percent(accuracy = 1, decimal.mark = ",")) +
    scale_x_date(labels = rotulo_mes, expand = expansion(mult = .01),
                 breaks = seq(floor_date(min(df$data), "year"), max(df$data), by = "6 months")) +
    coord_cartesian(ylim = c(0, y_top)) +
    labs(x = NULL, y = ylab,
         caption = "Pontos: valores mensais (tamanho proporcional ao denominador). Faixas: IC95% dos valores ajustados.") +
    tema_bol() + theme(legend.position = "bottom", legend.text = element_text(size = 9))
}

# Tabela 2: coeficientes do modelo principal (OR, IC95%, p) + efeito no último mês
tabela2 <- function(res, sazonal) {
  t <- res$fit$teste
  termos <- c(tempo = "Tendência antes dos GTs (por mês)",
              pos   = paste0("Mudança de nível em ", rotulo_mes(res$data_int)),
              t_pos = "Mudança de tendência após os GTs (por mês)")
  if (sazonal) termos <- c(termos, sen = "Sazonalidade — seno", cosn = "Sazonalidade — cosseno")
  k <- names(termos); b <- t[k, 1]; se <- t[k, 2]
  dig <- ifelse(k %in% c("tempo", "t_pos"), 3, 2)
  tab <- tibble(`Parâmetro do modelo` = unname(termos),
                OR      = mapply(fmt_p, exp(b), dig),
                `IC95%` = mapply(function(a, z, d) fmt_ic(a, z, d), exp(b - 1.96 * se), exp(b + 1.96 * se), dig),
                p       = fmt_pv(t[k, 4]))
  ult <- rotulo_mes(max(res$real$data))
  aj <- tail(res$real$ajuste, 1); cf <- tail(res$cf$ajuste, 1); ef <- res$ef
  bind_rows(tab, tibble(
    `Parâmetro do modelo` = c(paste0("Valor ajustado em ", ult, " (%)"),
                              paste0("Cenário sem GTs em ", ult, " (%)"),
                              paste0("Efeito acumulado em ", ult, " (p.p.)")),
    OR = c(fmt_p(100 * aj), fmt_p(100 * cf), fmt_p(100 * ef[["dif"]])),
    `IC95%` = c("—", "—", paste0(fmt_p(100 * ef[["li"]]), " a ", fmt_p(100 * ef[["ls"]]))),
    p = "—"))
}

# Diagnósticos: resíduos, sobredispersão, sazonalidade, decomposição e espectro
diagnosticos <- function(res, df, cfg, pasta) {
  r    <- residuals(res$fit$mod, type = "pearson")
  lb   <- Box.test(r, lag = 12, type = "Ljung-Box")
  disp <- sum(r^2) / res$fit$mod$df.residual
  p_saz <- if (cfg$sazonal) res$fit$teste[c("sen", "cosn"), 4] else
    ajustar_its(res$df_aj, TRUE)$teste[c("sen", "cosn"), 4]

  # ACF dos resíduos
  ac <- acf(r, lag.max = 12, plot = FALSE)
  d_acf <- tibble(lag = ac$lag[-1], acf = ac$acf[-1])
  g_acf <- ggplot(d_acf, aes(lag, acf)) + geom_col(fill = BOL$blue, width = .5) +
    geom_hline(yintercept = c(-1, 1) * 1.96 / sqrt(length(r)), linetype = "dashed", colour = BOL$red) +
    geom_hline(yintercept = 0) + scale_x_continuous(breaks = 1:12) +
    labs(x = "Defasagem (meses)", y = "Autocorrelação",
         title = paste("ACF dos resíduos de Pearson —", cfg$nome),
         subtitle = paste0("Ljung-Box (12 defasagens): Q = ", fmt_p(lb$statistic, 1), "; p = ", fmt_pv(lb$p.value))) +
    tema_bol()
  ggsave(file.path(pasta, "diag_acf_residuos.png"), g_acf, width = 7, height = 3.5, dpi = 200, bg = "white")

  # Série mensal completa (meses ausentes interpolados — uso exploratório)
  grade <- tibble(data = seq(min(df$data), max(df$data), by = "month")) |>
    left_join(df |> select(data, valor), by = "data")
  n_int <- sum(is.na(grade$valor))
  idx <- seq_len(nrow(grade)); ok <- !is.na(grade$valor)
  grade$valor_i <- approx(idx[ok], grade$valor[ok], xout = idx, rule = 2)$y
  y <- ts(grade$valor_i, start = c(year(min(grade$data)), month(min(grade$data))), frequency = 12)

  # Decomposição STL
  dec <- stl(y, s.window = "periodic")
  comp <- as.data.frame(dec$time.series) |>
    mutate(data = grade$data, observado = as.numeric(y)) |>
    pivot_longer(c(observado, trend, seasonal, remainder), names_to = "componente") |>
    mutate(componente = factor(componente, levels = c("observado", "trend", "seasonal", "remainder"),
                               labels = c("Observado", "Tendência", "Sazonalidade", "Ruído (resto)")))
  g_stl <- ggplot(comp, aes(data, value)) + geom_line(colour = BOL$navy) +
    geom_vline(xintercept = data_gt, linetype = "dashed", colour = BOL$red) +
    facet_wrap(~componente, ncol = 1, scales = "free_y") +
    scale_x_date(labels = rotulo_mes, date_breaks = "6 months") +
    labs(x = NULL, y = NULL, title = paste("Decomposição STL —", cfg$nome),
         subtitle = if (n_int) paste(n_int, "meses ausentes interpolados (uso exploratório)") else NULL) +
    tema_bol()
  ggsave(file.path(pasta, "diag_decomposicao_stl.png"), g_stl, width = 7, height = 7, dpi = 200, bg = "white")

  # Periodograma da série sem tendência linear + teste g de Fisher (ruído branco)
  tt <- seq_along(y); yd <- residuals(lm(as.numeric(y) ~ tt))
  sp <- spec.pgram(yd, taper = 0, detrend = FALSE, plot = FALSE)
  I <- sp$spec; m <- length(I); g <- max(I) / sum(I)
  p_fisher <- min(1, m * (1 - g)^(m - 1))
  pico <- 1 / sp$freq[which.max(I)]
  g_sp <- ggplot(tibble(periodo = 1 / sp$freq, I = I), aes(periodo, I)) +
    geom_segment(aes(xend = periodo, yend = 0), colour = BOL$blue) + geom_point(colour = BOL$navy) +
    geom_vline(xintercept = 12, linetype = "dashed", colour = BOL$red) +
    scale_x_log10(breaks = c(2, 3, 4, 6, 12, 24, 48)) +
    labs(x = "Período (meses, escala log)", y = "Intensidade",
         title = paste("Periodograma —", cfg$nome),
         subtitle = paste0("Pico em ", fmt_p(pico, 1), " meses · teste g de Fisher: p = ", fmt_pv(p_fisher),
                           " (p > 0,05 = compatível com ruído branco)")) +
    tema_bol()
  ggsave(file.path(pasta, "diag_periodograma.png"), g_sp, width = 7, height = 3.5, dpi = 200, bg = "white")

  # Média do denominador por mês do calendário (sazonalidade dos casos/registros)
  saz_den <- df |> group_by(mes = month(data)) |>
    summarise(media_denominador = round(mean(den), 1), indicador_pct = round(100 * sum(num) / sum(den), 1), .groups = "drop")
  write.csv2(saz_den, file.path(pasta, "diag_media_por_mes_do_ano.csv"), row.names = FALSE)

  resumo <- tibble(
    teste = c("Ljung-Box (12 defasagens) — resíduos de Pearson", "Sobredispersão (qui-quadrado/gl)",
              "Termo sazonal seno (p)", "Termo sazonal cosseno (p)", "Teste g de Fisher — periodograma (p)",
              "Período do pico espectral (meses)", "Meses interpolados na decomposição"),
    valor = c(paste0("Q = ", fmt_p(lb$statistic, 1), "; p = ", fmt_pv(lb$p.value)), fmt_p(disp, 2),
              fmt_pv(p_saz[1]), fmt_pv(p_saz[2]), fmt_pv(p_fisher), fmt_p(pico, 1), as.character(n_int)))
  write.csv2(resumo, file.path(pasta, "diag_resumo.csv"), row.names = FALSE)
  cat("\n---------------- Diagnósticos ----------------\n"); print(as.data.frame(resumo))
  resumo
}

## 6. Modelo ITS para um ponto de corte --------------------------------
# inicio = mês de início da intervenção; fim_trans = último mês de transição (ou NA)
rodar <- function(df, nome, meta, melhor, sazonal, arquivo, inicio = data_gt,
                  fim_trans = NA, pasta = pasta_saida) {
  inicio   <- as.Date(inicio)
  data_int <- if (is.na(fim_trans)) inicio else as.Date(fim_trans) %m+% months(1)
  origem   <- min(df$data)
  df    <- prep_its(df, origem, data_int)
  excl  <- df |> filter(data >= inicio, data < data_int)          # transição
  df_aj <- df |> filter(!(data >= inicio & data < data_int))
  grade <- tibble(data = seq(origem, max(df$data), by = "month")) |>
    prep_its(origem, data_int) |> filter(!(data >= inicio & data < data_int))
  fit  <- ajustar_its(df_aj, sazonal)
  g    <- grafico_its(df_aj, fit, grade, data_int, nome, meta, melhor, inicio, excl)
  ggsave(file.path(pasta, arquivo), g, width = 13.33, height = 7.5, dpi = 300, bg = "white")
  ef <- efeito_final(fit, grade)
  cat("\n================", nome, "· corte", format(inicio, "%m/%Y"),
      if (!is.na(fim_trans)) paste("· transição até", format(as.Date(fim_trans), "%m/%Y")) else "",
      "================\n")
  cat("Pré:", sum(df_aj$pos == 0), "meses | Pós:", sum(df_aj$pos == 1), "meses",
      if (nrow(excl)) paste("| Transição (excluídos):", nrow(excl)) else "", "\n")
  print(fit$teste)
  t <- fit$teste
  resumo <- tibble(
    `Ponto de corte` = paste0(format(inicio, "%m/%Y"),
                              if (!is.na(fim_trans)) paste0(" + transição até ", format(as.Date(fim_trans), "%m/%Y")) else ""),
    `Meses pré/pós` = paste0(sum(df_aj$pos == 0), "/", sum(df_aj$pos == 1)),
    `OR tendência (IC95%)` = paste0(fmt_p(exp(t["t_pos", 1]), 3), " (",
                                    fmt_ic(exp(t["t_pos", 1] - 1.96 * t["t_pos", 2]),
                                           exp(t["t_pos", 1] + 1.96 * t["t_pos", 2]), 3), ")"),
    `p tendência` = fmt_pv(t["t_pos", 4]),
    `OR nível` = fmt_p(exp(t["pos", 1]), 2),
    `p nível` = fmt_pv(t["pos", 4]),
    `Efeito último mês, p.p. (IC95%)` = paste0(fmt_p(100 * ef[["dif"]]), " (", fmt_p(100 * ef[["li"]]),
                                               " a ", fmt_p(100 * ef[["ls"]]), ")"))
  list(grafico = g, fit = fit, ef = ef, resumo = resumo, df_aj = df_aj, inicio = inicio,
       data_int = data_int, real = prever(fit, grade),
       cf = prever(fit, filter(grade, data >= data_int), contrafactual = TRUE))
}

## 7. Análise completa de um indicador ---------------------------------
analisar_indicador <- function(df, cfg) {
  pasta <- file.path(pasta_saida, cfg$pasta)
  dir.create(file.path(pasta, "sensibilidade"), recursive = TRUE, showWarnings = FALSE)
  cat("\n\n####################", toupper(cfg$nome), "####################\n")

  # Tabela 1 e Gráfico 1 (descritivo)
  t1 <- tabela1(df)
  t1_fmt <- formatar_t1(t1, cfg$rot_den, cfg$rot_num, cfg$rot_pct)
  write.csv2(t1_fmt, file.path(pasta, "tabela1_valores_absolutos.csv"), row.names = FALSE)
  cat("\n---------------- Tabela 1 ----------------\n"); print(as.data.frame(t1_fmt))
  g1 <- grafico_desc(t1, cfg$rot_pct, cfg$meta, cfg$base)
  ggsave(file.path(pasta, "grafico1_descritivo.png"), g1, width = 7, height = 3.2, dpi = 300, bg = "white")

  sem <- df |> mutate(semestre = paste0(year(data), "/", ifelse(month(data) <= 6, 1, 2))) |>
    group_by(semestre) |>
    summarise(num = sum(num), den = sum(den), pct = round(100 * num / den, 1), .groups = "drop")
  write.csv2(sem, file.path(pasta, "descritivo_semestral.csv"), row.names = FALSE)

  # Modelo principal: Gráfico 2 e Tabela 2
  res <- rodar(df, cfg$nome, cfg$meta, cfg$melhor, cfg$sazonal, "its_grafico_sdss.png",
               data_gt, NA, pasta)
  g2 <- grafico_boletim(res, cfg$rot_pct, cfg$meta)
  ggsave(file.path(pasta, "grafico2_its.png"), g2, width = 7.2, height = 3.6, dpi = 300, bg = "white")
  t2 <- tabela2(res, cfg$sazonal)
  write.csv2(t2, file.path(pasta, "tabela2_modelo_its.csv"), row.names = FALSE)
  cat("\n---------------- Tabela 2 ----------------\n"); print(as.data.frame(t2))

  # Tabela 3: sensibilidade ao ponto de corte
  t3 <- bind_rows(lapply(names(cenarios), function(nm) {
    ini <- cenarios[[nm]][1]; fim <- cenarios[[nm]][2]
    tag <- paste0(str_remove_all(ini, "-"), if (!is.na(fim)) "_trans" else "")
    rodar(df, cfg$nome, cfg$meta, cfg$melhor, cfg$sazonal, paste0("sens_", tag, ".png"),
          ini, fim, file.path(pasta, "sensibilidade"))$resumo |> mutate(Cenário = nm, .before = 1)
  }))
  write.csv2(t3, file.path(pasta, "tabela3_sensibilidade.csv"), row.names = FALSE)
  cat("\n---------------- Tabela 3 ----------------\n"); print(as.data.frame(t3))

  # Diagnósticos
  dg <- diagnosticos(res, df, cfg, pasta)
  message("\n[", cfg$nome, "] saídas em: ", normalizePath(pasta))
  invisible(list(res = res, t1 = t1_fmt, t2 = t2, t3 = t3, diag = dg, g1 = g1, g2 = g2))
}

# =====================================================================
#  PARTE A — HANSENÍASE: proporção de contatos examinados
# =====================================================================
cfg_hans <- list(nome = "Contatos de hanseníase examinados", pasta = "hanseniase",
                 rot_den = "Contatos registrados (n)", rot_num = "Contatos examinados (n)",
                 rot_pct = "Contatos examinados (%)", meta = NA, base = NA,
                 melhor = "subir", sazonal = sazonal_hans)
out_hans <- analisar_indicador(hans, cfg_hans)
print(out_hans$g2)          # Gráfico 2 do boletim (ver também saida_its/hanseniase/)

# =====================================================================
#  PARTE B — LEPTOSPIROSE: letalidade
# =====================================================================
cfg_lepto <- list(nome = "Letalidade da leptospirose", pasta = "leptospirose",
                  rot_den = "Casos (n)", rot_num = "Óbitos (n)",
                  rot_pct = "Letalidade (%)", meta = meta_lepto, base = base_lepto,
                  melhor = "descer", sazonal = sazonal_lepto)
out_lepto <- analisar_indicador(lepto, cfg_lepto)
print(out_lepto$g2)         # Gráfico 2 do boletim (ver também saida_its/leptospirose/)

# =====================================================================
#  PARTE C — Painel conjunto (opcional; requer as Partes A e B)
# =====================================================================
if (exists("out_hans") && exists("out_lepto")) {
  painel <- (out_hans$res$grafico / out_lepto$res$grafico) +
    plot_annotation(
      title = "GTs do PEG e indicadores epidemiológicos — Salvador",
      subtitle = paste0("Séries temporais interrompidas · GLM quasibinomial · intervenção em ",
                        rotulo_mes(data_gt)),
      theme = theme(plot.title = element_text(face = "bold", size = 22),
                    plot.subtitle = element_text(size = 13, colour = "#4B5563")))
  ggsave(file.path(pasta_saida, "its_painel.png"), painel, width = 13.33, height = 16,
         dpi = 300, bg = "white")
}
message("\nPronto! Abra a pasta: ", normalizePath(pasta_saida))
if (interactive()) browseURL(normalizePath(pasta_saida))
