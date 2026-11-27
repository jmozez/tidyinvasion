#' Distance from an origin
#'
#' Adds the distance in kilometres from each record to an origin point, using
#' the haversine formula for geographic coordinates and Euclidean distance
#' (assuming metres) for projected coordinates.
#'
#' @param .data A data frame, [inv_occurrence()] table or `sf` POINT layer.
#' @param origin Numeric vector of length two: the x (longitude) and y
#'   (latitude) of the origin.
#' @param lon,lat <[`tidy-select`][tidyselect::language]> Coordinate columns.
#'   Not needed for `<inv_occurrence>` or `sf` input.
#' @param name Name of the new column.
#' @return `.data` with an extra numeric column of distances in kilometres.
#' @export
#' @examples
#' # Distance of each cane toad record from the 1935 release at Gordonvale
#' inv_distance(cane_toad, origin = c(145.79, -17.10), lon = lon, lat = lat)
inv_distance <- function(.data, origin, lon = NULL, lat = NULL, name = "distance_km") {
  check_data_frame(.data)
  check_origin(origin)
  xy <- resolve_coords(.data, rlang::enquo(lon), rlang::enquo(lat))
  .data[[name]] <- inv_dist_km(origin[1], origin[2], xy$x, xy$y, geographic = xy$geographic)
  .data
}

check_origin <- function(origin, call = rlang::caller_env()) {
  if (!is.numeric(origin) || length(origin) != 2 || anyNA(origin)) {
    cli::cli_abort("{.arg origin} must be a numeric vector of length 2 (x, y).", call = call)
  }
  invisible(origin)
}

# Convex hull area (km^2) of projected points.
hull_area <- function(x, y) {
  if (length(x) < 3) {
    return(0)
  }
  h <- grDevices::chull(x, y)
  hx <- x[h]
  hy <- y[h]
  abs(sum(hx * c(hy[-1], hy[1]) - c(hx[-1], hx[1]) * hy)) / 2
}

#' Estimate the rate of spatial spread
#'
#' Estimates the radial rate of spread of an invasion from dated occurrence
#' records with three established methods:
#'
#' * `"front"`: for each time step, the range radius is the `quantile` of
#'   distances from the origin of all records up to that time (the maximum
#'   when `quantile = 1`). The rate is the slope of radius on time.
#' * `"first_record"`: records are gridded into cells of `cell_size`; each
#'   cell is dated by its first record and its distance is that of its
#'   nearest first-year record. The rate is the slope of distance on first
#'   record time, the distance regression method (Gilbert et al. 2004).
#' * `"area"`: the cumulative occupied area is the convex hull of all records
#'   up to each time, converted to an equivalent radius `sqrt(area / pi)`
#'   (Skellam 1951). The rate is the slope of radius on time.
#'
#' @param .data A data frame, [inv_occurrence()] table or `sf` POINT layer
#'   with dated records.
#' @param time <[`tidy-select`][tidyselect::language]> Column with the record
#'   time (numeric year, `Date` or `POSIXct`). Defaults to the time column of
#'   an `<inv_occurrence>`.
#' @param lon,lat <[`tidy-select`][tidyselect::language]> Coordinate columns.
#' @param origin Numeric vector of length two giving the introduction point.
#'   Defaults to the mean location of the earliest records.
#' @param method One of `"front"`, `"first_record"` or `"area"`.
#' @param quantile Quantile of distances used as the range front with
#'   `method = "front"`. Values below 1 reduce the effect of outlying records.
#' @param cell_size Grid cell size for `method = "first_record"`, in decimal
#'   degrees for geographic data or coordinate units for projected data.
#' @param min_records Minimum cumulative number of records for a time step to
#'   be used.
#' @param conf_level Confidence level for the rate interval in [glance()].
#'
#' @return An `<inv_spread>` tibble with columns `time`, `distance_km`
#'   (radius or cell distance) and `n` (records contributing). The fitted
#'   linear model is stored in the metadata; [tidy()] and [glance()] return
#'   the spread rate in km per time unit and [autoplot()] draws it.
#' @references Gilbert, M., Gregoire, J.-C., Freise, J. F. and Heitland, W.
#'   (2004). Long-distance dispersal and human population density allow the
#'   prediction of invasive patterns in the horse chestnut leafminer
#'   *Cameraria ohridella*. *Journal of Animal Ecology*, 73, 459-468.
#'   \doi{10.1111/j.0021-8790.2004.00820.x}
#'
#'   Skellam, J. G. (1951). Random dispersal in theoretical populations.
#'   *Biometrika*, 38, 196-218. \doi{10.1093/biomet/38.1-2.196}
#' @export
#' @examples
#' occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
#' spread <- inv_spread_rate(occ, origin = c(145.79, -17.10), quantile = 0.95)
#' spread
#' glance(spread)
#'
#' inv_spread_rate(occ, origin = c(145.79, -17.10), method = "first_record")
inv_spread_rate <- function(.data, time = NULL, lon = NULL, lat = NULL, origin = NULL,
                            method = c("front", "first_record", "area"),
                            quantile = 1, cell_size = 0.5, min_records = 1,
                            conf_level = 0.95) {
  check_data_frame(.data)
  method <- rlang::arg_match(method)
  check_probability(quantile, open = FALSE)
  check_number_positive(cell_size)
  check_integerish(min_records)
  check_probability(conf_level)
  meta <- inv_meta(.data)
  xy <- resolve_coords(.data, rlang::enquo(lon), rlang::enquo(lat))
  time_col <- select_one(rlang::enquo(time), xy$data, "time", required = is.null(meta$time)) %||%
    meta$time
  t <- as_time_numeric(xy$data[[time_col]], time_col)
  ok <- !is.na(t) & !is.na(xy$x) & !is.na(xy$y)
  t <- t[ok]
  x <- xy$x[ok]
  y <- xy$y[ok]
  if (is.null(origin)) {
    first <- t == min(t)
    origin <- c(mean(x[first]), mean(y[first]))
  }
  check_origin(origin)
  d <- inv_dist_km(origin[1], origin[2], x, y, geographic = xy$geographic)
  times <- sort(unique(t))

  out <- switch(method,
    front = {
      rows <- lapply(times, function(tt) {
        dd <- d[t <= tt]
        c(tt, stats::quantile(dd, quantile, names = FALSE, type = 7), length(dd))
      })
      m <- do.call(rbind, rows)
      tibble::tibble(time = m[, 1], distance_km = m[, 2], n = as.integer(m[, 3]))
    },
    area = {
      p <- project_km(x, y, origin[1], origin[2], geographic = xy$geographic)
      rows <- lapply(times, function(tt) {
        keep <- t <= tt
        c(tt, sqrt(hull_area(p$x[keep], p$y[keep]) / pi), sum(keep))
      })
      m <- do.call(rbind, rows)
      tibble::tibble(time = m[, 1], distance_km = m[, 2], n = as.integer(m[, 3]))
    },
    first_record = {
      cell <- paste(floor(x / cell_size), floor(y / cell_size), sep = "_")
      first_t <- tapply(t, cell, min)
      keep <- t == first_t[cell]
      cell_d <- tapply(d[keep], cell[keep], min)
      cell_n <- tapply(t, cell, length)
      tibble::tibble(
        cell = names(first_t),
        time = as.numeric(first_t),
        distance_km = as.numeric(cell_d[names(first_t)]),
        n = as.integer(cell_n[names(first_t)])
      )[order(as.numeric(first_t)), ]
    }
  )
  if (method != "first_record") {
    out <- out[out$n >= min_records, ]
  }
  if (nrow(out) < 3 || length(unique(out$time)) < 2) {
    cli::cli_abort("At least three time steps are needed to estimate a spread rate.")
  }
  fit <- stats::lm(distance_km ~ time, data = out)
  attr(fit, "conf_level") <- conf_level
  new_inv_spread(out, method = method, origin = origin, units = "km", fit = fit)
}

# Dispersal kernels -------------------------------------------------------

kernel_families <- function() {
  c("exponential", "halfnormal", "weibull", "lognormal", "gamma")
}

kernel_par_names <- function(family) {
  switch(family,
    exponential = "scale",
    halfnormal = "sigma",
    weibull = c("shape", "scale"),
    lognormal = c("meanlog", "sdlog"),
    gamma = c("shape", "rate")
  )
}

# Natural-scale parameters from the unconstrained vector.
kernel_natural <- function(theta, family) {
  if (family == "lognormal") c(theta[1], exp(theta[2])) else exp(theta)
}

kernel_density <- function(r, par, family, log = FALSE) {
  switch(family,
    exponential = stats::dexp(r, rate = 1 / par[1], log = log),
    halfnormal = {
      v <- log(2) + stats::dnorm(r, 0, par[1], log = TRUE)
      v[r < 0] <- -Inf
      if (log) v else exp(v)
    },
    weibull = stats::dweibull(r, shape = par[1], scale = par[2], log = log),
    lognormal = stats::dlnorm(r, par[1], par[2], log = log),
    gamma = stats::dgamma(r, shape = par[1], rate = par[2], log = log)
  )
}

kernel_cdf <- function(r, par, family) {
  switch(family,
    exponential = stats::pexp(r, rate = 1 / par[1]),
    halfnormal = pmax(0, 2 * stats::pnorm(r, 0, par[1]) - 1),
    weibull = stats::pweibull(r, shape = par[1], scale = par[2]),
    lognormal = stats::plnorm(r, par[1], par[2]),
    gamma = stats::pgamma(r, shape = par[1], rate = par[2])
  )
}

kernel_quantile <- function(p, par, family) {
  switch(family,
    exponential = stats::qexp(p, rate = 1 / par[1]),
    halfnormal = par[1] * stats::qnorm((1 + p) / 2),
    weibull = stats::qweibull(p, shape = par[1], scale = par[2]),
    lognormal = stats::qlnorm(p, par[1], par[2]),
    gamma = stats::qgamma(p, shape = par[1], rate = par[2])
  )
}

kernel_mean <- function(par, family) {
  switch(family,
    exponential = par[1],
    halfnormal = par[1] * sqrt(2 / pi),
    weibull = par[2] * gamma(1 + 1 / par[1]),
    lognormal = exp(par[1] + par[2]^2 / 2),
    gamma = par[1] / par[2]
  )
}

kernel_start <- function(r, family) {
  m <- mean(r)
  v <- stats::var(r)
  lr <- log(r)
  switch(family,
    exponential = log(m),
    halfnormal = log(sqrt(mean(r^2))),
    weibull = {
      k <- 1.2 / stats::sd(lr)
      c(log(k), log(m / gamma(1 + 1 / k)))
    },
    lognormal = c(mean(lr), log(stats::sd(lr))),
    gamma = c(log(m^2 / v), log(m / v))
  )
}

kernel_nll <- function(theta, r, w, family) {
  par <- kernel_natural(theta, family)
  ll <- kernel_density(r, par, family, log = TRUE)
  if (any(!is.finite(ll))) {
    return(1e100)
  }
  -sum(w * ll)
}

fit_kernel <- function(r, w, family) {
  start <- kernel_start(r, family)
  method <- if (length(start) == 1) "BFGS" else "Nelder-Mead"
  opt <- stats::optim(start, kernel_nll, r = r, w = w, family = family,
    method = method, control = list(maxit = 5000, reltol = 1e-12)
  )
  if (length(start) > 1) {
    opt <- stats::optim(opt$par, kernel_nll, r = r, w = w, family = family,
      method = "BFGS", control = list(maxit = 1000, reltol = 1e-12)
    )
  }
  vc <- safe_vcov(kernel_nll, opt$par, r = r, w = w, family = family)
  par <- kernel_natural(opt$par, family)
  # Delta method: d(natural)/d(theta) is exp(theta) for log-scale parameters.
  grad <- if (family == "lognormal") c(1, par[2]) else par
  se <- grad * safe_sqrt(diag(vc))
  names(par) <- names(se) <- kernel_par_names(family)
  k <- length(par)
  n <- sum(w)
  list(
    family = family, estimate = par, std_error = se, loglik = -opt$value, k = k,
    aic = 2 * opt$value + 2 * k, bic = 2 * opt$value + log(n) * k,
    mean_distance = kernel_mean(par, family),
    q99_distance = kernel_quantile(0.99, par, family),
    convergence = opt$convergence
  )
}

#' Fit dispersal kernels
#'
#' Fits one or more distance kernels to observed dispersal distances by
#' maximum likelihood and ranks them by AIC. The kernels describe the
#' probability density of dispersal distance and differ in the weight of
#' their tail: the half-normal is thin-tailed, the exponential has a standard
#' tail and the Weibull (shape below 1), lognormal and gamma can be
#' fat-tailed, which drives accelerating spread.
#'
#' @param .data A data frame with one row per dispersal event.
#' @param distance <[`tidy-select`][tidyselect::language]> Column with
#'   positive dispersal distances.
#' @param family Character vector of kernels to fit: any of
#'   `"exponential"`, `"halfnormal"`, `"weibull"`, `"lognormal"`, `"gamma"`.
#' @param weights <[`tidy-select`][tidyselect::language]> Optional column of
#'   frequency weights (for example, the number of seeds trapped at a
#'   distance).
#'
#' @return An object of class `inv_kernel` with one fit per family, ordered
#'   by AIC. Use [tidy()] for parameter estimates, [glance()] for model
#'   comparison (log-likelihood, AIC, Akaike weights, mean and 99th
#'   percentile dispersal distance), [augment()] for fitted densities and
#'   [autoplot()] for density and tail plots.
#' @references Nathan, R., Klein, E., Robledo-Arnuncio, J. J. and Revilla, E.
#'   (2012). Dispersal kernels: review. In *Dispersal Ecology and
#'   Evolution*, Oxford University Press, 187-210.
#' @export
#' @examples
#' k <- inv_dispersal_kernel(
#'   dplyr::filter(inv_dispersal, species == "sp_a"), distance = distance_m
#' )
#' glance(k)
#' tidy(k)
inv_dispersal_kernel <- function(.data, distance, family = kernel_families(),
                                 weights = NULL) {
  check_data_frame(.data)
  family <- rlang::arg_match(family, kernel_families(), multiple = TRUE)
  data <- as_plain_tibble(.data)
  col <- select_one(rlang::enquo(distance), data, "distance")
  w_col <- select_one(rlang::enquo(weights), data, "weights", required = FALSE)
  check_numeric_col(data, col)
  r <- data[[col]]
  w <- if (is.null(w_col)) rep(1, length(r)) else data[[w_col]]
  ok <- !is.na(r) & !is.na(w)
  r <- r[ok]
  w <- w[ok]
  if (any(r <= 0)) {
    cli::cli_abort(c(
      "Column {.field {col}} must contain strictly positive distances.",
      "i" = "Remove zero distances or add a small offset before fitting."
    ))
  }
  if (any(w < 0)) {
    cli::cli_abort("{.arg weights} must be non-negative.")
  }
  if (length(r) < 5) {
    cli::cli_abort("At least five dispersal distances are needed.")
  }
  fits <- lapply(family, function(f) fit_kernel(r, w, f))
  names(fits) <- family
  fits <- fits[order(vapply(fits, `[[`, numeric(1), "aic"))]
  structure(
    list(fits = fits, distance = r, weights = w, column = col),
    class = "inv_kernel"
  )
}

#' @export
print.inv_kernel <- function(x, ...) {
  cat_line(paste(
    "{.cls inv_kernel} {length(x$fits)} dispersal kernel{?s} fitted to",
    "{length(x$distance)} distances"
  ))
  best <- x$fits[[1]]
  cat("Best by AIC: ", best$family, " (",
    paste0(names(best$estimate), " = ", signif(best$estimate, 4), collapse = ", "),
    "); mean distance ", signif(best$mean_distance, 4), "\n",
    sep = ""
  )
  invisible(x)
}

# Lag phases --------------------------------------------------------------

#' Detect a lag phase in an invasion time series
#'
#' Many invasions grow slowly for years before expanding. `inv_lag_phase()`
#' builds the cumulative invasion curve (records, occupied cells or any
#' count over time), log-transforms it and compares a single exponential
#' growth model with a continuous two-phase (broken-stick) model whose
#' breakpoint is found by profile least squares. A lag phase is reported when
#' the two-phase model is better by more than `delta_aic` and growth after
#' the breakpoint is faster than before it (Aikio et al. 2010).
#'
#' @param .data A data frame, typically one row per record, or one row per
#'   time step when `count` is given.
#' @param time <[`tidy-select`][tidyselect::language]> Column with time.
#'   Defaults to the time column of an `<inv_occurrence>`.
#' @param count <[`tidy-select`][tidyselect::language]> Optional column with
#'   counts per row (for example, new occupied cells). Without it each row
#'   counts as one record.
#' @param min_points Minimum number of time steps on each side of the
#'   breakpoint.
#' @param delta_aic AIC improvement needed to declare a lag phase.
#'
#' @return An object of class `inv_lag`: a list with the series (`time`, `n`,
#'   `cumulative`, fitted values), breakpoint, growth rates and AIC values.
#'   Use [tidy()], [glance()], [augment()] and [autoplot()].
#' @references Aikio, S., Duncan, R. P. and Hulme, P. E. (2010). Lag-phases
#'   in alien plant invasions: separating the facts from the artefacts.
#'   *Oikos*, 119, 370-378. \doi{10.1111/j.1600-0706.2009.17963.x}
#' @export
#' @examples
#' lag <- inv_lag_phase(cane_toad, time = year)
#' glance(lag)
#' tidy(lag)
inv_lag_phase <- function(.data, time = NULL, count = NULL, min_points = 3,
                          delta_aic = 2) {
  check_data_frame(.data)
  check_integerish(min_points, min = 2)
  check_number_positive(delta_aic, allow_zero = TRUE)
  meta <- inv_meta(.data)
  data <- as_plain_tibble(.data)
  time_col <- select_one(rlang::enquo(time), data, "time", required = is.null(meta$time)) %||%
    meta$time
  count_col <- select_one(rlang::enquo(count), data, "count", required = FALSE)
  t <- as_time_numeric(data[[time_col]], time_col)
  cnt <- if (is.null(count_col)) rep(1, length(t)) else data[[count_col]]
  ok <- !is.na(t) & !is.na(cnt)
  per <- tapply(cnt[ok], t[ok], sum)
  series <- tibble::tibble(time = as.numeric(names(per)), n = as.numeric(per))
  series$cumulative <- cumsum(series$n)
  series <- series[series$cumulative > 0, ]
  m <- nrow(series)
  if (m < 2 * min_points + 1) {
    cli::cli_abort("At least {2 * min_points + 1} time steps with records are needed.")
  }
  tt <- series$time
  ly <- log(series$cumulative)

  fit1 <- stats::lm(ly ~ tt)
  rss_at <- function(b) sum(stats::lm.fit(cbind(1, tt, pmax(tt - b, 0)), ly)$residuals^2)
  candidates <- tt[(min_points):(m - min_points + 1)]
  rss <- vapply(candidates, rss_at, numeric(1))
  i <- which.min(rss)
  lo <- candidates[max(1, i - 1)]
  hi <- candidates[min(length(candidates), i + 1)]
  bp <- if (hi > lo) stats::optimize(rss_at, c(lo, hi))$minimum else candidates[i]
  if (rss_at(bp) > rss[i]) bp <- candidates[i]
  x2 <- cbind(1, tt, pmax(tt - bp, 0))
  fit2 <- stats::lm.fit(x2, ly)
  b <- fit2$coefficients
  aic_ls <- function(rss, k) m * log(rss / m) + 2 * (k + 1)
  aic1 <- aic_ls(sum(fit1$residuals^2), 2)
  aic2 <- aic_ls(sum(fit2$residuals^2), 4)
  rate_lag <- unname(b[2])
  rate_exp <- unname(b[2] + b[3])
  lag <- (aic1 - aic2) > delta_aic && rate_exp > rate_lag
  series$.fitted_single <- unname(exp(stats::fitted(fit1)))
  series$.fitted_two_phase <- unname(exp(drop(x2 %*% b)))
  structure(
    list(
      series = series, breakpoint = bp, rate_lag = rate_lag, rate_expansion = rate_exp,
      rate_single = unname(stats::coef(fit1)[2]), aic_single = aic1, aic_two_phase = aic2,
      lag_detected = lag, start = min(tt)
    ),
    class = "inv_lag"
  )
}

#' @export
print.inv_lag <- function(x, ...) {
  cat_line("{.cls inv_lag} invasion curve over {nrow(x$series)} time steps")
  if (x$lag_detected) {
    cat_line(paste(
      "Lag phase detected: ends at {signif(x$breakpoint, 6)} after",
      "{signif(x$breakpoint - x$start, 4)} time units"
    ))
  } else {
    cat_line("No lag phase detected")
  }
  cat_line("Growth rate before {signif(x$rate_lag, 3)}, after {signif(x$rate_expansion, 3)} (log scale per time unit)")
  invisible(x)
}
