#' Eradication feasibility
#'
#' Projects an incursion under repeated control with a simple stochastic
#' removal model. Each year the population grows by `exp(growth_rate)` and
#' is searched `rounds` times; each individual (or patch) is found with
#' probability `detect_prob` per round and removed with probability
#' `efficacy` once found. The annual multiplier is
#' `lambda = exp(growth_rate) * (1 - detect_prob * efficacy)^rounds`, the
#' expected population after `t` years is `population * lambda^t`, and the
#' probability that no individual remains is `exp(-population * lambda^t)`
#' (Poisson approximation). Eradication is feasible only when `lambda < 1`.
#'
#' Every argument after `.data` uses data masking, so each can be a column
#' of `.data` or a constant.
#'
#' @param .data A data frame with one row per incursion or scenario.
#' @param population Initial number of individuals or patches.
#' @param growth_rate Intrinsic annual growth rate `r` (log scale).
#' @param detect_prob Probability of detecting an individual per search
#'   round.
#' @param efficacy Probability that a detected individual is removed.
#' @param rounds Search rounds per year.
#' @param area Optional infested area (for example in hectares), used for
#'   cost.
#' @param cost_per_unit Optional cost of one search round per unit `area`.
#' @param horizon Planning horizon in years for `p_eradicated`.
#' @param target Probability of eradication that defines success.
#'
#' @return `.data` as a tibble with added columns `lambda`, `feasible`,
#'   `min_rounds` (fewest rounds per year giving `lambda < 1`),
#'   `years_to_target` (years until the eradication probability reaches
#'   `target`, `Inf` when not feasible), `p_eradicated` (probability of
#'   eradication within `horizon` years) and, when cost is given,
#'   `total_cost` (cost of all rounds up to `years_to_target`).
#' @references Regan, T. J., McCarthy, M. A., Baxter, P. W. J., Panetta,
#'   F. D. and Possingham, H. P. (2006). Optimal eradication: when to stop
#'   looking for an invasive plant. *Ecology Letters*, 9, 759-766.
#'   \doi{10.1111/j.1461-0248.2006.00920.x}
#' @export
#' @examples
#' scenarios <- data.frame(
#'   site = c("small", "medium", "large"),
#'   n0 = c(20, 400, 15000),
#'   ha = c(2, 50, 900)
#' )
#' inv_eradication_feasibility(scenarios, population = n0, growth_rate = 0.4,
#'   detect_prob = 0.6, efficacy = 0.95, rounds = 2, area = ha,
#'   cost_per_unit = 120)
inv_eradication_feasibility <- function(.data, population, growth_rate, detect_prob,
                                        efficacy = 1, rounds = 1, area = NULL,
                                        cost_per_unit = NULL, horizon = 10,
                                        target = 0.95) {
  check_data_frame(.data)
  check_number_positive(horizon)
  check_probability(target)
  data <- as_plain_tibble(.data)
  n <- nrow(data)
  ev <- function(quo, arg) {
    v <- rlang::eval_tidy(quo, data)
    if (is.null(v)) {
      return(NULL)
    }
    if (!is.numeric(v) || !(length(v) %in% c(1, n))) {
      cli::cli_abort("{.arg {arg}} must be numeric of length 1 or {n}.", call = rlang::caller_env(2))
    }
    rep_len(v, n)
  }
  n0 <- ev(rlang::enquo(population), "population")
  r <- ev(rlang::enquo(growth_rate), "growth_rate")
  p <- ev(rlang::enquo(detect_prob), "detect_prob")
  e <- ev(rlang::enquo(efficacy), "efficacy")
  k <- ev(rlang::enquo(rounds), "rounds")
  a <- ev(rlang::enquo(area), "area")
  cost <- ev(rlang::enquo(cost_per_unit), "cost_per_unit")
  if (any(n0 < 0, na.rm = TRUE)) cli::cli_abort("{.arg population} must be non-negative.")
  if (any(p < 0 | p > 1, na.rm = TRUE)) cli::cli_abort("{.arg detect_prob} must be in [0, 1].")
  if (any(e < 0 | e > 1, na.rm = TRUE)) cli::cli_abort("{.arg efficacy} must be in [0, 1].")
  if (any(k < 0, na.rm = TRUE)) cli::cli_abort("{.arg rounds} must be non-negative.")
  kill <- p * e
  lambda <- exp(r) * (1 - kill)^k
  feasible <- lambda < 1
  min_rounds <- ifelse(kill >= 1, 1,
    ifelse(kill <= 0, Inf, pmax(0, floor(r / -log1p(-kill)) + 1))
  )
  thresh <- -log(target)
  years <- ifelse(n0 <= thresh, 0,
    ifelse(feasible, ceiling(log(thresh / n0) / log(lambda)), Inf)
  )
  years[feasible & lambda == 0 & n0 > thresh] <- 1
  data$lambda <- lambda
  data$feasible <- feasible
  data$min_rounds <- min_rounds
  data$years_to_target <- years
  data$p_eradicated <- exp(-n0 * lambda^horizon)
  if (!is.null(a) && !is.null(cost)) {
    data$total_cost <- ifelse(is.finite(years), a * cost * k * years, Inf)
  }
  data
}

#' Horizon scanning for invasion risk
#'
#' Combines expert scores for candidate species into an overall risk score
#' and rank, following the consensus approach of Roy et al. (2014). Scores
#' for criteria such as likelihood of arrival, establishment, spread and
#' impact are combined by product, geometric mean or sum. With several
#' assessors, scores are first aggregated by the median for each species and
#' criterion and their spread is reported as a measure of disagreement.
#'
#' @param .data A data frame with one row per species (or per species and
#'   assessor).
#' @param ... <[`tidy-select`][tidyselect::language]> Criterion columns with
#'   numeric scores.
#' @param species <[`tidy-select`][tidyselect::language]> Column with the
#'   species.
#' @param assessor <[`tidy-select`][tidyselect::language]> Optional column
#'   with the assessor.
#' @param method How to combine criteria: `"product"`, `"geometric_mean"` or
#'   `"sum"`.
#' @param score_range Numeric vector of length two with the minimum and
#'   maximum possible score of each criterion. Used to scale the overall
#'   score to 0 to 1.
#' @param thresholds Two cut points on the scaled score separating `"low"`,
#'   `"medium"` and `"high"` priority.
#'
#' @return A tibble with one row per species, sorted by rank: the median
#'   score for each criterion, `n_assessors`, `disagreement` (mean across
#'   criteria of the standard deviation among assessors; `NA` with one
#'   assessor), `score`, `scaled_score`, `rank` and `priority`.
#' @references Roy, H. E., Peyton, J., Aldridge, D. C. et al. (2014). Horizon
#'   scanning for invasive alien species with the potential to threaten
#'   biodiversity in Great Britain. *Global Change Biology*, 20, 3859-3871.
#'   \doi{10.1111/gcb.12603}
#' @export
#' @examples
#' inv_horizon_scan(inv_horizon, arrival, establishment, impact,
#'   species = species, assessor = assessor)
inv_horizon_scan <- function(.data, ..., species, assessor = NULL,
                             method = c("product", "geometric_mean", "sum"),
                             score_range = c(1, 5), thresholds = c(1 / 3, 2 / 3)) {
  check_data_frame(.data)
  method <- rlang::arg_match(method)
  data <- as_plain_tibble(.data)
  crit_quos <- rlang::enquos(...)
  crit <- names(tidyselect::eval_select(rlang::expr(c(!!!crit_quos)), data, allow_rename = FALSE))
  sp_col <- select_one(rlang::enquo(species), data, "species")
  as_col <- select_one(rlang::enquo(assessor), data, "assessor", required = FALSE)
  crit <- setdiff(crit, c(sp_col, as_col))
  if (!length(crit)) {
    cli::cli_abort("Select at least one criterion column in {.arg ...}.")
  }
  for (col in crit) check_numeric_col(data, col)
  if (!is.numeric(score_range) || length(score_range) != 2 || diff(score_range) <= 0) {
    cli::cli_abort("{.arg score_range} must be two increasing numbers.")
  }
  if (!is.numeric(thresholds) || length(thresholds) != 2 || any(thresholds < 0 | thresholds > 1) ||
    diff(thresholds) <= 0) {
    cli::cli_abort("{.arg thresholds} must be two increasing numbers between 0 and 1.")
  }
  sp <- as.character(data[[sp_col]])
  groups <- split(seq_len(nrow(data)), factor(sp, levels = unique(sp)))
  combine <- function(v) {
    switch(method,
      product = prod(v),
      geometric_mean = exp(mean(log(v))),
      sum = sum(v)
    )
  }
  k <- length(crit)
  lims <- vapply(score_range, function(s) combine(rep(s, k)), numeric(1))
  rows <- lapply(names(groups), function(s) {
    i <- groups[[s]]
    med <- vapply(crit, function(cc) stats::median(data[[cc]][i], na.rm = TRUE), numeric(1))
    sds <- vapply(crit, function(cc) {
      if (length(i) > 1) stats::sd(data[[cc]][i], na.rm = TRUE) else NA_real_
    }, numeric(1))
    score <- combine(med)
    out <- tibble::as_tibble(as.list(med))
    out <- dplyr::bind_cols(tibble::tibble(species = s), out)
    out$n_assessors <- if (is.null(as_col)) length(i) else length(unique(data[[as_col]][i]))
    out$disagreement <- if (all(is.na(sds))) NA_real_ else mean(sds, na.rm = TRUE)
    out$score <- score
    out
  })
  out <- dplyr::bind_rows(rows)
  out$scaled_score <- (out$score - lims[1]) / (lims[2] - lims[1])
  out$rank <- rank(-out$score, ties.method = "min")
  out$priority <- factor(
    ifelse(out$scaled_score >= thresholds[2], "high",
      ifelse(out$scaled_score >= thresholds[1], "medium", "low")
    ),
    levels = c("low", "medium", "high"), ordered = TRUE
  )
  names(out)[1] <- sp_col
  out[order(out$rank), ]
}
