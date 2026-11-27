#' Effect sizes of invasion impact
#'
#' Compares a response (native richness, cover, biomass, a soil property)
#' between invaded and reference (uninvaded) plots and returns the log
#' response ratio (Hedges et al. 1999), Hedges' bias-corrected standardised
#' mean difference *g*, and the percentage change, with confidence intervals.
#'
#' @param .data A data frame with one row per plot or sample.
#' @param response <[`tidy-select`][tidyselect::language]> Numeric response
#'   column.
#' @param status <[`tidy-select`][tidyselect::language]> Column with the
#'   invasion status of each row. It must have exactly two values.
#' @param invaded Value of `status` that marks invaded rows. The other value
#'   is the reference.
#' @param .by <[`tidy-select`][tidyselect::language]> Optional grouping
#'   columns, for example site or response variable.
#' @param conf_level Confidence level.
#'
#' @return A tibble with one row per group: sample sizes, means and standard
#'   deviations of both groups, `lnrr` with `lnrr_var`, `lnrr_low` and
#'   `lnrr_high`, `hedges_g` with `hedges_g_var`, `g_low` and `g_high`, and
#'   `pct_change` (`100 * (exp(lnrr) - 1)`). The log response ratio is `NA`
#'   when either mean is not positive.
#' @references Hedges, L. V., Gurevitch, J. and Curtis, P. S. (1999). The
#'   meta-analysis of response ratios in experimental ecology. *Ecology*, 80,
#'   1150-1156.
#' @export
#' @examples
#' inv_impact_metrics(inv_plots, response = native_richness, status = status,
#'   .by = site)
inv_impact_metrics <- function(.data, response, status, invaded = "invaded",
                               .by = NULL, conf_level = 0.95) {
  check_data_frame(.data)
  check_probability(conf_level)
  y_col <- select_one(rlang::enquo(response), .data, "response")
  s_col <- select_one(rlang::enquo(status), .data, "status")
  check_numeric_col(.data, y_col)
  vals <- unique(as.character(.data[[s_col]]))
  vals <- vals[!is.na(vals)]
  if (length(vals) != 2 || !invaded %in% vals) {
    cli::cli_abort(c(
      "Column {.field {s_col}} must have exactly two values, one of them {.val {invaded}}.",
      "x" = "Found {.val {vals}}."
    ))
  }
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  by_apply(.data, rlang::enquo(.by), function(d) {
    inv <- d[[y_col]][as.character(d[[s_col]]) == invaded]
    ref <- d[[y_col]][as.character(d[[s_col]]) != invaded]
    inv <- inv[!is.na(inv)]
    ref <- ref[!is.na(ref)]
    n1 <- length(inv)
    n2 <- length(ref)
    m1 <- if (n1) mean(inv) else NA_real_
    m2 <- if (n2) mean(ref) else NA_real_
    s1 <- if (n1 > 1) stats::sd(inv) else NA_real_
    s2 <- if (n2 > 1) stats::sd(ref) else NA_real_
    lnrr <- if (isTRUE(m1 > 0 && m2 > 0)) log(m1 / m2) else NA_real_
    lnrr_var <- s1^2 / (n1 * m1^2) + s2^2 / (n2 * m2^2)
    sp <- sqrt(((n1 - 1) * s1^2 + (n2 - 1) * s2^2) / (n1 + n2 - 2))
    j <- 1 - 3 / (4 * (n1 + n2 - 2) - 1)
    g <- j * (m1 - m2) / sp
    g_var <- (n1 + n2) / (n1 * n2) + g^2 / (2 * (n1 + n2))
    tibble::tibble(
      n_invaded = n1, n_reference = n2,
      mean_invaded = m1, mean_reference = m2,
      sd_invaded = s1, sd_reference = s2,
      lnrr = lnrr, lnrr_var = lnrr_var,
      lnrr_low = lnrr - z * sqrt(lnrr_var), lnrr_high = lnrr + z * sqrt(lnrr_var),
      hedges_g = g, hedges_g_var = g_var,
      g_low = g - z * sqrt(g_var), g_high = g + z * sqrt(g_var),
      pct_change = 100 * (exp(lnrr) - 1)
    )
  })
}

#' Parker impact score
#'
#' Computes the overall impact of an invader as the product of its range,
#' its abundance (density or cover per unit area) and its per-capita or
#' per-unit-biomass effect, `I = R * A * E` (Parker et al. 1999).
#'
#' @param .data A data frame with one row per invader (or invader by
#'   region).
#' @param range,abundance,effect <[`tidy-select`][tidyselect::language]>
#'   Numeric columns with range size, abundance and per-capita effect.
#' @param .by <[`tidy-select`][tidyselect::language]> Optional grouping
#'   columns within which `relative_impact` and `rank` are computed.
#'
#' @return `.data` as a tibble with added columns `impact`, `log10_impact`,
#'   `relative_impact` (impact divided by the largest absolute impact within
#'   the group) and `rank` (1 is the largest absolute impact).
#' @references Parker, I. M., Simberloff, D., Lonsdale, W. M. et al. (1999).
#'   Impact: toward a framework for understanding the ecological effects of
#'   invaders. *Biological Invasions*, 1, 3-19.
#'   \doi{10.1023/A:1010034312781}
#' @export
#' @examples
#' invaders <- data.frame(
#'   species = c("a", "b", "c"),
#'   range_km2 = c(1200, 300, 5000),
#'   density = c(4, 25, 0.5),
#'   effect = c(-0.02, -0.01, -0.3)
#' )
#' inv_parker_impact(invaders, range_km2, density, effect)
inv_parker_impact <- function(.data, range, abundance, effect, .by = NULL) {
  check_data_frame(.data)
  r_col <- select_one(rlang::enquo(range), .data, "range")
  a_col <- select_one(rlang::enquo(abundance), .data, "abundance")
  e_col <- select_one(rlang::enquo(effect), .data, "effect")
  for (col in c(r_col, a_col, e_col)) check_numeric_col(.data, col)
  check_numeric_col(.data, r_col, non_negative = TRUE)
  check_numeric_col(.data, a_col, non_negative = TRUE)
  by_apply(.data, rlang::enquo(.by), function(d) {
    impact <- d[[r_col]] * d[[a_col]] * d[[e_col]]
    mx <- suppressWarnings(max(abs(impact), na.rm = TRUE))
    d$impact <- impact
    d$log10_impact <- log10(abs(impact))
    d$relative_impact <- if (is.finite(mx) && mx > 0) impact / mx else NA_real_
    d$rank <- rank(-abs(impact), na.last = "keep", ties.method = "min")
    d
  })
}

pairwise_similarity <- function(m) {
  # m: logical site x species matrix
  m <- m * 1
  a <- tcrossprod(m)
  s <- diag(a)
  b <- outer(s, s, "+") - 2 * a
  jac <- a / (a + b)
  sor <- 2 * a / (2 * a + b)
  lt <- lower.tri(a)
  list(jaccard = jac[lt], sorensen = sor[lt])
}

#' Biotic homogenisation
#'
#' Measures whether alien species make communities more similar to each
#' other. Mean pairwise Jaccard and Sorensen similarity among sites is
#' computed for the native assemblage alone and for the current assemblage
#' (native plus alien species). A positive change means homogenisation and a
#' negative change differentiation (Olden and Rooney 2006).
#'
#' @param .data A long data frame with one row per species occurrence at a
#'   site.
#' @param site,species,status <[`tidy-select`][tidyselect::language]>
#'   Columns identifying the site, the species and its status.
#' @param native Value of `status` marking native species. Any other value
#'   is treated as alien.
#' @param .by <[`tidy-select`][tidyselect::language]> Optional grouping
#'   columns, for example region.
#'
#' @return A tibble with one row per group: `n_sites`, `n_native`, `n_alien`,
#'   `jaccard_native`, `jaccard_current`, `delta_jaccard`,
#'   `sorensen_native`, `sorensen_current`, `delta_sorensen` and
#'   `homogenised` (`delta_jaccard > 0`). Sites without native species are
#'   kept with an empty native assemblage; pairs of empty assemblages are
#'   ignored.
#' @references Olden, J. D. and Rooney, T. P. (2006). On defining and
#'   quantifying biotic homogenization. *Global Ecology and Biogeography*,
#'   15, 113-120. \doi{10.1111/j.1466-822x.2006.00214.x}
#' @export
#' @examples
#' inv_homogenization(inv_communities, site = site, species = species,
#'   status = status, .by = region)
inv_homogenization <- function(.data, site, species, status, native = "native",
                               .by = NULL) {
  check_data_frame(.data)
  site_col <- select_one(rlang::enquo(site), .data, "site")
  sp_col <- select_one(rlang::enquo(species), .data, "species")
  st_col <- select_one(rlang::enquo(status), .data, "status")
  by_apply(.data, rlang::enquo(.by), function(d) {
    d <- d[!is.na(d[[site_col]]) & !is.na(d[[sp_col]]), ]
    sites <- sort(unique(as.character(d[[site_col]])))
    spp <- sort(unique(as.character(d[[sp_col]])))
    if (length(sites) < 2) {
      cli::cli_abort("At least two sites are needed to measure homogenisation.", call = NULL)
    }
    m <- matrix(FALSE, length(sites), length(spp), dimnames = list(sites, spp))
    m[cbind(as.character(d[[site_col]]), as.character(d[[sp_col]]))] <- TRUE
    is_native <- tapply(as.character(d[[st_col]]) == native, as.character(d[[sp_col]]), all)
    is_native <- is_native[spp]
    cur <- pairwise_similarity(m)
    nat <- pairwise_similarity(m[, is_native, drop = FALSE])
    mean_ok <- function(x) mean(x[is.finite(x)])
    tibble::tibble(
      n_sites = length(sites),
      n_native = sum(is_native),
      n_alien = sum(!is_native),
      jaccard_native = mean_ok(nat$jaccard),
      jaccard_current = mean_ok(cur$jaccard),
      delta_jaccard = mean_ok(cur$jaccard) - mean_ok(nat$jaccard),
      sorensen_native = mean_ok(nat$sorensen),
      sorensen_current = mean_ok(cur$sorensen),
      delta_sorensen = mean_ok(cur$sorensen) - mean_ok(nat$sorensen),
      homogenised = (mean_ok(cur$jaccard) - mean_ok(nat$jaccard)) > 0
    )
  })
}

eicat_levels <- function() c("MC", "MN", "MO", "MR", "MV")

eicat_codes <- function(x) {
  key <- c(
    "mc" = "MC", "minimal concern" = "MC", "minimal" = "MC",
    "mn" = "MN", "minor" = "MN",
    "mo" = "MO", "moderate" = "MO",
    "mr" = "MR", "major" = "MR",
    "mv" = "MV", "massive" = "MV",
    "dd" = "DD", "data deficient" = "DD"
  )
  unname(key[tolower(trimws(as.character(x)))])
}

#' EICAT impact classification
#'
#' Assigns each alien taxon its Environmental Impact Classification for Alien
#' Taxa (EICAT) category from a table of impact records. Following the IUCN
#' standard, a taxon's category is the most severe impact magnitude recorded
#' for it across all mechanisms: Minimal Concern (MC), Minor (MN), Moderate
#' (MO), Major (MR) or Massive (MV). Taxa with only Data Deficient (DD)
#' records are DD. MO, MR and MV are harmful. A cumulative score (sum over
#' mechanisms of the highest score for each mechanism, with MC = 1 to
#' MV = 5) is also returned to rank taxa within a category.
#'
#' @param .data A data frame with one row per impact record.
#' @param species <[`tidy-select`][tidyselect::language]> Column with the
#'   taxon.
#' @param magnitude <[`tidy-select`][tidyselect::language]> Column with the
#'   impact magnitude, as codes (`"MC"`, `"MN"`, `"MO"`, `"MR"`, `"MV"`,
#'   `"DD"`) or names (`"Minimal Concern"`, `"Minor"`, `"Moderate"`,
#'   `"Major"`, `"Massive"`, `"Data Deficient"`), in any case.
#' @param mechanism <[`tidy-select`][tidyselect::language]> Optional column
#'   with the impact mechanism (for example competition, predation,
#'   hybridisation).
#' @param confidence <[`tidy-select`][tidyselect::language]> Optional column
#'   with the confidence of each record (`"low"`, `"medium"`, `"high"`).
#'
#' @return A tibble with one row per taxon, sorted from most to least
#'   severe: `n_records`, `eicat_category` (an ordered factor with `DD` as
#'   the lowest level), `eicat_score` (1 to 5, `NA` for DD), `harmful`,
#'   `max_mechanisms` (mechanisms with the highest magnitude),
#'   `confidence` (highest confidence among records of the highest
#'   magnitude), `n_mechanisms` and `cumulative_score`.
#' @references Blackburn, T. M., Essl, F., Evans, T. et al. (2014). A unified
#'   classification of alien species based on the magnitude of their
#'   environmental impacts. *PLoS Biology*, 12, e1001850.
#'   \doi{10.1371/journal.pbio.1001850}
#'
#'   IUCN (2020). *IUCN EICAT Categories and Criteria*. First edition. IUCN,
#'   Gland. \doi{10.2305/iucn.ch.2020.05.en}
#' @export
#' @examples
#' inv_eicat_score(inv_impacts, species = species, magnitude = magnitude,
#'   mechanism = mechanism, confidence = confidence)
inv_eicat_score <- function(.data, species, magnitude, mechanism = NULL,
                            confidence = NULL) {
  check_data_frame(.data)
  data <- as_plain_tibble(.data)
  sp_col <- select_one(rlang::enquo(species), data, "species")
  mag_col <- select_one(rlang::enquo(magnitude), data, "magnitude")
  mech_col <- select_one(rlang::enquo(mechanism), data, "mechanism", required = FALSE)
  conf_col <- select_one(rlang::enquo(confidence), data, "confidence", required = FALSE)
  codes <- eicat_codes(data[[mag_col]])
  bad <- unique(data[[mag_col]][is.na(codes) & !is.na(data[[mag_col]])])
  if (length(bad)) {
    cli::cli_abort(c(
      "Unknown EICAT magnitude values in {.field {mag_col}}: {.val {bad}}.",
      "i" = "Use MC, MN, MO, MR, MV or DD, or their full names."
    ))
  }
  score <- match(codes, eicat_levels())
  conf_rank <- if (is.null(conf_col)) {
    rep(NA_integer_, nrow(data))
  } else {
    match(tolower(as.character(data[[conf_col]])), c("low", "medium", "high"))
  }
  groups <- split(seq_len(nrow(data)), as.character(data[[sp_col]]))
  rows <- lapply(names(groups), function(sp) {
    i <- groups[[sp]]
    s <- score[i]
    if (all(is.na(s))) {
      cat_code <- "DD"
      best <- NA_integer_
      top <- integer()
    } else {
      best <- max(s, na.rm = TRUE)
      cat_code <- eicat_levels()[best]
      top <- i[!is.na(s) & s == best]
    }
    mechs <- if (is.null(mech_col)) {
      NA_character_
    } else {
      paste(sort(unique(as.character(data[[mech_col]][top]))), collapse = "; ")
    }
    conf <- if (is.null(conf_col) || !length(top) || all(is.na(conf_rank[top]))) {
      NA_character_
    } else {
      c("low", "medium", "high")[max(conf_rank[top], na.rm = TRUE)]
    }
    cum <- if (is.null(mech_col) || all(is.na(s))) {
      if (all(is.na(s))) NA_real_ else max(s, na.rm = TRUE)
    } else {
      sum(tapply(s, as.character(data[[mech_col]][i]), function(v) {
        if (all(is.na(v))) 0 else max(v, na.rm = TRUE)
      }))
    }
    tibble::tibble(
      species = sp,
      n_records = length(i),
      eicat_category = cat_code,
      eicat_score = best,
      harmful = !is.na(best) & best >= 3,
      max_mechanisms = if (length(top)) mechs else NA_character_,
      confidence = conf,
      n_mechanisms = if (is.null(mech_col)) {
        NA_integer_
      } else {
        length(unique(stats::na.omit(as.character(data[[mech_col]][i][!is.na(s)]))))
      },
      cumulative_score = as.numeric(cum)
    )
  })
  out <- dplyr::bind_rows(rows)
  names(out)[1] <- sp_col
  out$eicat_category <- factor(out$eicat_category, levels = c("DD", eicat_levels()),
    ordered = TRUE
  )
  out[order(-xtfrm(out$eicat_category), -out$cumulative_score, out[[sp_col]]), ]
}
