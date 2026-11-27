#' Summarise propagule pressure
#'
#' Propagule pressure combines the number of introduction events
#' (propagule number) and the number of individuals released per event
#' (propagule size). `inv_propagule_pressure()` summarises both for each
#' group, optionally discounting older events with an exponential decay so
#' that recent introductions weigh more.
#'
#' @param .data A data frame (or [inv_pathway()] table) with one row per
#'   introduction event.
#' @param size <[`tidy-select`][tidyselect::language]> Column with the number
#'   of individuals introduced per event. Defaults to the size column of an
#'   `<inv_pathway>` table.
#' @param time <[`tidy-select`][tidyselect::language]> Optional column with
#'   the event time, used with `decay`.
#' @param decay Optional non-negative decay rate per time unit. When given,
#'   the column `pp_discounted` holds `sum(size * exp(-decay * (t_max - t)))`.
#' @param .by <[`tidy-select`][tidyselect::language]> Optional grouping
#'   columns. Grouped data frames are also respected.
#'
#' @return A tibble with one row per group and columns `n_events`
#'   (propagule number), `total_propagules`, `mean_size`, `median_size`,
#'   `cv_size` (coefficient of variation of size), `max_size`, `pp_index`
#'   (`log10(1 + total_propagules)`) and, when `decay` is set,
#'   `pp_discounted`.
#' @references Lockwood, J. L., Cassey, P. and Blackburn, T. (2005). The role
#'   of propagule pressure in explaining species invasions. *Trends in Ecology
#'   and Evolution*, 20, 223-228. \doi{10.1016/j.tree.2005.02.004}
#' @export
#' @examples
#' inv_propagule_pressure(inv_introductions, size = propagule_size, .by = pathway)
#'
#' # Discount older introductions by 10% per year
#' inv_propagule_pressure(inv_introductions, size = propagule_size,
#'   time = year, decay = 0.1, .by = species)
inv_propagule_pressure <- function(.data, size = NULL, time = NULL, decay = NULL,
                                   .by = NULL) {
  check_data_frame(.data)
  meta <- inv_meta(.data)
  size_col <- select_one(rlang::enquo(size), .data, "size", required = is.null(meta$size)) %||%
    meta$size
  time_col <- select_one(rlang::enquo(time), .data, "time", required = FALSE)
  check_numeric_col(.data, size_col, non_negative = TRUE)
  check_number_positive(decay, allow_zero = TRUE, allow_null = TRUE)
  if (!is.null(decay) && is.null(time_col)) {
    cli::cli_abort("{.arg time} is required when {.arg decay} is set.")
  }
  by_apply(.data, rlang::enquo(.by), function(d) {
    s <- d[[size_col]]
    s <- s[!is.na(s)]
    total <- sum(s)
    m <- if (length(s)) mean(s) else NA_real_
    out <- tibble::tibble(
      n_events = length(s),
      total_propagules = total,
      mean_size = m,
      median_size = if (length(s)) stats::median(s) else NA_real_,
      cv_size = if (length(s) > 1 && m > 0) stats::sd(s) / m else NA_real_,
      max_size = if (length(s)) max(s) else NA_real_,
      pp_index = log10(1 + total)
    )
    if (!is.null(decay)) {
      t <- as_time_numeric(d[[time_col]], time_col)
      ok <- !is.na(t) & !is.na(d[[size_col]])
      out$pp_discounted <- sum(d[[size_col]][ok] * exp(-decay * (max(t[ok]) - t[ok])))
    }
    out
  })
}

# Establishment dose-response --------------------------------------------

estab_prob <- function(theta, n, model) {
  switch(model,
    exponential = 1 - exp(-exp(theta[1]) * n),
    weibull = 1 - exp(-exp(theta[1]) * n^exp(theta[2])),
    logistic = stats::plogis(theta[1] + theta[2] * log(n))
  )
}

estab_nll <- function(theta, n, y, model) {
  p <- estab_prob(theta, n, model)
  p <- pmin(pmax(p, 1e-12), 1 - 1e-12)
  -sum(stats::dbinom(y, 1, p, log = TRUE))
}

#' Fit an establishment dose-response model
#'
#' Estimates the probability that an introduction establishes as a function
#' of propagule size by maximum likelihood. Three models are available:
#'
#' * `"exponential"`: `P(N) = 1 - exp(-alpha * N)`, where each propagule
#'   establishes independently with probability `alpha` (no Allee effect).
#' * `"weibull"`: `P(N) = 1 - exp(-alpha * N^c)` (Leung et al. 2004). `c > 1`
#'   indicates an Allee effect, `c < 1` diminishing returns.
#' * `"logistic"`: `logit P(N) = b0 + b1 * log(N)`.
#'
#' The binomial likelihood is maximised with [stats::optim()] on an
#' unconstrained scale; standard errors come from the numerical Hessian.
#'
#' @param .data A data frame with one row per introduction event.
#' @param established <[`tidy-select`][tidyselect::language]> Column with the
#'   outcome: logical, 0/1 or a two-level factor (first level is success).
#' @param propagules <[`tidy-select`][tidyselect::language]> Column with
#'   propagule size (positive numbers).
#' @param model One of `"exponential"`, `"weibull"` or `"logistic"`.
#' @param conf_level Confidence level for intervals.
#'
#' @return An object of class `inv_establishment`, a list with the fitted
#'   parameters, their variance-covariance matrix, the log-likelihood, AIC,
#'   `n50` (the propagule size giving 50% establishment) and the data used.
#'   Use [tidy()], [glance()], [augment()], [predict()] and [autoplot()] on it.
#' @references Leung, B., Drake, J. M. and Lodge, D. M. (2004). Predicting
#'   invasions: propagule pressure and the gravity of Allee effects.
#'   *Ecology*, 85, 1651-1660. \doi{10.1890/02-0571}
#' @export
#' @examples
#' fit <- inv_establishment_prob(inv_introductions, established, propagule_size,
#'   model = "weibull")
#' fit
#' tidy(fit)
#' glance(fit)
#' predict(fit, data.frame(propagule_size = c(1, 10, 100)))
inv_establishment_prob <- function(.data, established, propagules,
                                   model = c("exponential", "weibull", "logistic"),
                                   conf_level = 0.95) {
  check_data_frame(.data)
  model <- rlang::arg_match(model)
  check_probability(conf_level)
  data <- as_plain_tibble(.data)
  y_col <- select_one(rlang::enquo(established), data, "established")
  n_col <- select_one(rlang::enquo(propagules), data, "propagules")
  check_numeric_col(data, n_col)
  y <- as_binary(data[[y_col]], y_col)
  n <- data[[n_col]]
  ok <- !is.na(y) & !is.na(n)
  if (any(n[ok] <= 0)) {
    cli::cli_abort("Column {.field {n_col}} must contain positive propagule sizes.")
  }
  y <- as.numeric(y[ok])
  n <- n[ok]
  if (length(y) < 3 || length(unique(y)) < 2) {
    cli::cli_abort("At least three events with both successes and failures are needed.")
  }
  start <- switch(model,
    exponential = log(-log(1 - min(max(mean(y), 0.01), 0.99)) / stats::median(n)),
    weibull = c(log(-log(1 - min(max(mean(y), 0.01), 0.99)) / stats::median(n)), 0),
    logistic = unname(stats::coef(stats::glm(y ~ log(n), family = stats::binomial())))
  )
  opt <- stats::optim(start, estab_nll, n = n, y = y, model = model,
    method = if (length(start) == 1) "BFGS" else "Nelder-Mead",
    control = list(maxit = 5000, reltol = 1e-12)
  )
  if (length(start) > 1) {
    opt <- stats::optim(opt$par, estab_nll, n = n, y = y, model = model, method = "BFGS",
      control = list(maxit = 1000, reltol = 1e-12)
    )
  }
  if (opt$convergence != 0) {
    cli::cli_warn("The optimiser did not converge (code {opt$convergence}).")
  }
  vc <- safe_vcov(estab_nll, opt$par, n = n, y = y, model = model)
  par_names <- switch(model,
    exponential = "alpha",
    weibull = c("alpha", "c"),
    logistic = c("b0", "b1")
  )
  link <- switch(model, logistic = "identity", "log")
  est <- if (link == "log") exp(opt$par) else opt$par
  names(est) <- par_names
  dimnames(vc) <- list(par_names, par_names)
  n50 <- switch(model,
    exponential = log(2) / est[["alpha"]],
    weibull = (log(2) / est[["alpha"]])^(1 / est[["c"]]),
    logistic = exp(-est[["b0"]] / est[["b1"]])
  )
  structure(
    list(
      model = model, estimate = est, theta = opt$par, vcov = vc, link = link,
      loglik = -opt$value, n = length(y), n50 = n50, conf_level = conf_level,
      data = tibble::tibble(propagules = n, established = y),
      columns = c(established = y_col, propagules = n_col),
      convergence = opt$convergence
    ),
    class = "inv_establishment"
  )
}

#' @export
print.inv_establishment <- function(x, ...) {
  cat_line("{.cls inv_establishment} {x$model} dose-response model")
  cat_line("{x$n} introduction events, log-likelihood {signif(x$loglik, 5)}")
  cat("Estimates: ", paste0(names(x$estimate), " = ", signif(x$estimate, 4), collapse = ", "),
    "\n", sep = "")
  cat_line("Propagules for 50% establishment: {signif(x$n50, 4)}")
  invisible(x)
}

#' Predict establishment probability
#'
#' @param object An `inv_establishment` fit.
#' @param new_data A data frame with the propagule column used in the fit, or
#'   a numeric vector of propagule sizes.
#' @param ... Not used.
#' @return A tibble with the propagule size and `.pred` (probability).
#' @export
#' @examples
#' fit <- inv_establishment_prob(inv_introductions, established, propagule_size)
#' predict(fit, c(1, 5, 50))
predict.inv_establishment <- function(object, new_data, ...) {
  n <- if (is.data.frame(new_data)) {
    col <- object$columns[["propagules"]]
    if (!col %in% names(new_data)) {
      cli::cli_abort("{.arg new_data} must contain the column {.field {col}}.")
    }
    new_data[[col]]
  } else {
    new_data
  }
  if (!is.numeric(n)) {
    cli::cli_abort("Propagule sizes must be numeric.")
  }
  tibble::tibble(propagules = n, .pred = estab_prob(object$theta, n, object$model))
}

# Detection and occupancy -------------------------------------------------

occu_nll <- function(theta, y) {
  psi <- stats::plogis(theta[1])
  p <- stats::plogis(theta[2])
  det <- rowSums(y == 1, na.rm = TRUE)
  surv <- rowSums(!is.na(y))
  lik_occ <- psi * p^det * (1 - p)^(surv - det)
  lik <- ifelse(det > 0, lik_occ, lik_occ + (1 - psi))
  -sum(log(pmax(lik, 1e-300)))
}

#' Estimate detection probability and occupancy
#'
#' Fits the constant single-season occupancy model of MacKenzie et al.
#' (2002) by maximum likelihood to repeated presence/absence surveys. It
#' separates the probability that a site is occupied (`psi`) from the
#' probability of detecting the species on one survey of an occupied site
#' (`p`), which is essential for surveillance of rare new incursions.
#'
#' @param .data A data frame with one row per site and one column per survey.
#' @param surveys <[`tidy-select`][tidyselect::language]> Survey columns
#'   holding 1 (detected), 0 (not detected) or `NA` (not surveyed).
#' @param .by <[`tidy-select`][tidyselect::language]> Optional grouping
#'   columns, for example region or habitat.
#' @param confidence Target confidence used for `surveys_needed`.
#'
#' @return A tibble with one row per group: `n_sites`, `n_surveys` (maximum
#'   per site), `naive_occupancy`, `psi` and `psi_se`, `p` and `p_se`,
#'   `cumulative_p` (probability of at least one detection across
#'   `n_surveys` at an occupied site), `surveys_needed` (surveys required to
#'   be `confidence` sure an undetected species is absent from an occupied
#'   site) and `log_lik`.
#' @references MacKenzie, D. I., Nichols, J. D., Lachman, G. B., Droege, S.,
#'   Royle, J. A. and Langtimm, C. A. (2002). Estimating site occupancy rates
#'   when detection probabilities are less than one. *Ecology*, 83,
#'   2248-2255.
#' @export
#' @examples
#' inv_detection_prob(inv_surveys, surveys = starts_with("visit"))
#' inv_detection_prob(inv_surveys, surveys = starts_with("visit"), .by = habitat)
inv_detection_prob <- function(.data, surveys, .by = NULL, confidence = 0.95) {
  check_data_frame(.data)
  check_probability(confidence)
  cols <- select_many(rlang::enquo(surveys), .data, "surveys")
  by_cols <- select_many(rlang::enquo(.by), .data, ".by")
  cols <- setdiff(cols, by_cols)
  if (length(cols) < 2) {
    cli::cli_abort("{.arg surveys} must select at least two survey columns.")
  }
  for (col in cols) {
    v <- .data[[col]]
    v <- if (is.logical(v)) as.numeric(v) else v
    if (!is.numeric(v) || !all(v[!is.na(v)] %in% c(0, 1))) {
      cli::cli_abort("Survey column {.field {col}} must contain only 0, 1 or NA.")
    }
  }
  by_apply(.data, rlang::enquo(.by), function(d) {
    y <- as.matrix(as.data.frame(lapply(d[cols], as.numeric)))
    y <- y[rowSums(!is.na(y)) > 0, , drop = FALSE]
    det <- rowSums(y == 1, na.rm = TRUE)
    naive <- mean(det > 0)
    start <- c(stats::qlogis(min(max(naive, 0.05), 0.95)), 0)
    opt <- stats::optim(start, occu_nll, y = y, method = "BFGS",
      control = list(maxit = 1000, reltol = 1e-12)
    )
    vc <- safe_vcov(occu_nll, opt$par, y = y)
    psi <- stats::plogis(opt$par[1])
    p <- stats::plogis(opt$par[2])
    k <- max(rowSums(!is.na(y)))
    tibble::tibble(
      n_sites = nrow(y),
      n_surveys = k,
      naive_occupancy = naive,
      psi = psi,
      psi_se = psi * (1 - psi) * safe_sqrt(vc[1, 1]),
      p = p,
      p_se = p * (1 - p) * safe_sqrt(vc[2, 2]),
      cumulative_p = 1 - (1 - p)^k,
      surveys_needed = if (p > 0 && p < 1) ceiling(log(1 - confidence) / log(1 - p)) else NA_real_,
      log_lik = -opt$value
    )
  })
}
