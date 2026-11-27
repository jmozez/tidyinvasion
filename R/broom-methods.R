# broom-style methods -----------------------------------------------------

wald_ci <- function(est, se, conf_level, log_scale = FALSE) {
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  if (log_scale) {
    list(low = est * exp(-z * se / est), high = est * exp(z * se / est))
  } else {
    list(low = est - z * se, high = est + z * se)
  }
}

#' Tidy, glance and augment tidyinvasion models
#'
#' broom-style summaries for the model objects returned by tidyinvasion:
#' `tidy()` gives one row per parameter, `glance()` one row of model-level
#' statistics and `augment()` the data with fitted values.
#'
#' @param x An object returned by [inv_establishment_prob()],
#'   [inv_dispersal_kernel()], [inv_lag_phase()], [inv_spread_rate()],
#'   [inv_sdm_fit()] or [inv_rd_fit()].
#' @param conf_int Include confidence intervals?
#' @param conf_level Confidence level. Defaults to the level used when
#'   fitting, or 0.95.
#' @param new_data Optional new data for `augment()`. For kernels, a numeric
#'   vector of distances.
#' @param family For kernels, which fitted family to use in `augment()`.
#'   Defaults to the best by AIC.
#' @param ... Not used.
#'
#' @return A tibble.
#' @name inv_broom
#' @examples
#' fit <- inv_establishment_prob(inv_introductions, established, propagule_size)
#' tidy(fit)
#' glance(fit)
#' head(augment(fit))
#'
#' occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
#' spread <- inv_spread_rate(occ, origin = c(145.79, -17.10), quantile = 0.95)
#' tidy(spread)
#' glance(spread)
NULL

#' @rdname inv_broom
#' @export
tidy.inv_establishment <- function(x, conf_int = TRUE, conf_level = NULL, ...) {
  conf_level <- conf_level %||% x$conf_level
  se_link <- safe_sqrt(diag(x$vcov))
  log_scale <- x$link == "log"
  se <- if (log_scale) x$estimate * se_link else se_link
  out <- tibble::tibble(term = names(x$estimate), estimate = unname(x$estimate),
    std.error = unname(se)
  )
  if (conf_int) {
    z <- stats::qnorm(1 - (1 - conf_level) / 2)
    out$conf.low <- if (log_scale) exp(x$theta - z * se_link) else x$theta - z * se_link
    out$conf.high <- if (log_scale) exp(x$theta + z * se_link) else x$theta + z * se_link
  }
  out
}

#' @rdname inv_broom
#' @export
glance.inv_establishment <- function(x, ...) {
  k <- length(x$estimate)
  tibble::tibble(
    model = x$model, n = x$n, logLik = x$loglik, AIC = -2 * x$loglik + 2 * k,
    BIC = -2 * x$loglik + log(x$n) * k, n50 = x$n50, converged = x$convergence == 0
  )
}

#' @rdname inv_broom
#' @export
augment.inv_establishment <- function(x, new_data = NULL, ...) {
  if (is.null(new_data)) {
    out <- x$data
    out$.fitted <- estab_prob(x$theta, out$propagules, x$model)
    out$.resid <- out$established - out$.fitted
    return(out)
  }
  pred <- stats::predict(x, new_data)
  out <- tibble::as_tibble(new_data)
  out$.fitted <- pred$.pred
  out
}

#' @rdname inv_broom
#' @export
tidy.inv_kernel <- function(x, conf_int = FALSE, conf_level = 0.95, ...) {
  rows <- lapply(x$fits, function(f) {
    out <- tibble::tibble(family = f$family, term = names(f$estimate),
      estimate = unname(f$estimate), std.error = unname(f$std_error)
    )
    if (conf_int) {
      ci <- wald_ci(out$estimate, out$std.error, conf_level)
      out$conf.low <- ci$low
      out$conf.high <- ci$high
    }
    out
  })
  dplyr::bind_rows(rows)
}

#' @rdname inv_broom
#' @export
glance.inv_kernel <- function(x, ...) {
  out <- dplyr::bind_rows(lapply(x$fits, function(f) {
    tibble::tibble(family = f$family, n_par = f$k, logLik = f$loglik, AIC = f$aic, BIC = f$bic,
      mean_distance = f$mean_distance, q99_distance = f$q99_distance,
      converged = f$convergence == 0
    )
  }))
  out$delta_AIC <- out$AIC - min(out$AIC)
  w <- exp(-out$delta_AIC / 2)
  out$weight <- w / sum(w)
  out$n <- length(x$distance)
  out[c("family", "n", "n_par", "logLik", "AIC", "BIC", "delta_AIC", "weight",
    "mean_distance", "q99_distance", "converged")]
}

#' @rdname inv_broom
#' @export
augment.inv_kernel <- function(x, new_data = NULL, family = NULL, ...) {
  family <- family %||% names(x$fits)[1]
  if (!family %in% names(x$fits)) {
    cli::cli_abort("{.val {family}} was not fitted. Fitted: {.val {names(x$fits)}}.")
  }
  f <- x$fits[[family]]
  r <- if (is.null(new_data)) x$distance else if (is.data.frame(new_data)) new_data[[1]] else new_data
  dens <- kernel_density(r, f$estimate, family)
  cdf <- kernel_cdf(r, f$estimate, family)
  tibble::tibble(
    distance = r, family = family, .density = dens, .cdf = cdf, .survival = 1 - cdf
  )
}

#' @rdname inv_broom
#' @export
tidy.inv_lag <- function(x, ...) {
  tibble::tibble(
    term = c("breakpoint", "rate_lag", "rate_expansion", "rate_single"),
    estimate = c(x$breakpoint, x$rate_lag, x$rate_expansion, x$rate_single)
  )
}

#' @rdname inv_broom
#' @export
glance.inv_lag <- function(x, ...) {
  tibble::tibble(
    lag_detected = x$lag_detected,
    lag_end = if (x$lag_detected) x$breakpoint else NA_real_,
    lag_duration = if (x$lag_detected) x$breakpoint - x$start else NA_real_,
    doubling_time = if (x$rate_expansion > 0) log(2) / x$rate_expansion else NA_real_,
    aic_single = x$aic_single, aic_two_phase = x$aic_two_phase,
    delta_aic = x$aic_single - x$aic_two_phase, n_times = nrow(x$series)
  )
}

#' @rdname inv_broom
#' @export
augment.inv_lag <- function(x, ...) {
  x$series
}

#' @rdname inv_broom
#' @export
tidy.inv_spread <- function(x, conf_int = TRUE, conf_level = NULL, ...) {
  fit <- inv_meta(x)$fit
  conf_level <- conf_level %||% attr(fit, "conf_level") %||% 0.95
  s <- summary(fit)$coefficients
  out <- tibble::tibble(
    term = c("intercept", "rate"), estimate = unname(s[, 1]), std.error = unname(s[, 2]),
    statistic = unname(s[, 3]), p.value = unname(s[, 4])
  )
  if (conf_int) {
    ci <- stats::confint(fit, level = conf_level)
    out$conf.low <- unname(ci[, 1])
    out$conf.high <- unname(ci[, 2])
  }
  out
}

#' @rdname inv_broom
#' @export
glance.inv_spread <- function(x, conf_level = NULL, ...) {
  meta <- inv_meta(x)
  fit <- meta$fit
  conf_level <- conf_level %||% attr(fit, "conf_level") %||% 0.95
  s <- summary(fit)
  ci <- stats::confint(fit, level = conf_level)
  tibble::tibble(
    method = meta$method, rate_km = unname(stats::coef(fit)[2]),
    std.error = unname(s$coefficients[2, 2]), conf.low = unname(ci[2, 1]),
    conf.high = unname(ci[2, 2]), r.squared = s$r.squared,
    p.value = unname(s$coefficients[2, 4]), n = nrow(x),
    origin_x = meta$origin[1], origin_y = meta$origin[2]
  )
}

#' @rdname inv_broom
#' @export
augment.inv_spread <- function(x, ...) {
  fit <- inv_meta(x)$fit
  out <- as_plain_tibble(x)
  out$.fitted <- unname(stats::fitted(fit))
  out$.resid <- unname(stats::residuals(fit))
  out
}

#' @rdname inv_broom
#' @export
tidy.inv_sdm_fit <- function(x, conf_int = FALSE, conf_level = 0.95, ...) {
  s <- summary(x$fit)$coefficients
  out <- tibble::tibble(term = rownames(s), estimate = unname(s[, 1]),
    std.error = unname(s[, 2]), statistic = unname(s[, 3]), p.value = unname(s[, 4])
  )
  if (conf_int) {
    ci <- wald_ci(out$estimate, out$std.error, conf_level)
    out$conf.low <- ci$low
    out$conf.high <- ci$high
  }
  out
}

#' @rdname inv_broom
#' @export
glance.inv_sdm_fit <- function(x, ...) {
  tibble::tibble(
    method = x$method, degree = x$degree, n = stats::nobs(x$fit),
    logLik = as.numeric(stats::logLik(x$fit)), AIC = stats::AIC(x$fit),
    deviance = stats::deviance(x$fit), null.deviance = x$fit$null.deviance,
    deviance_explained = 1 - stats::deviance(x$fit) / x$fit$null.deviance
  )
}

#' @rdname inv_broom
#' @export
tidy.inv_rd_fit <- function(x, ...) {
  tibble::tibble(
    term = c("diffusion", "growth_rate", "log_k", "speed"),
    estimate = c(x$diffusion, x$growth_rate, x$log_k, x$speed),
    fixed = c(x$fixed[["diffusion"]], x$fixed[["growth_rate"]], FALSE, FALSE)
  )
}

#' @rdname inv_broom
#' @export
glance.inv_rd_fit <- function(x, ...) {
  tibble::tibble(speed = x$speed, sigma = x$sigma, sse = x$sse, n = x$n,
    converged = x$convergence == 0
  )
}
