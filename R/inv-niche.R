#' Niche overlap and niche shift between native and invaded ranges
#'
#' @description
#' Compares the environmental niche of a species in its native and its
#' invaded range with the PCA-env framework of Broennimann et al. (2012) and
#' the COUE scheme of Guisan et al. (2014), as in the ecospat package:
#'
#' 1. a principal component analysis of the environmental variables is
#'    calibrated on the background (available environment) of both ranges;
#' 2. occurrences and background are smoothed with a Gaussian kernel on a
#'    grid of the first two axes, and occupancy is the occurrence density
#'    divided by the density of available environment, so it does not
#'    depend on how common each environment is;
#' 3. overlap is measured with Schoener's D and Warren's I, and the niche
#'    dynamics in environments available in both ranges are split into
#'    stability (shared), expansion (occupied only in the invaded range) and
#'    unfilling (occupied only in the native range);
#' 4. a niche equivalency test reallocates the pooled occurrences at random
#'    between the ranges to ask whether the niches differ more than chance.
#'
#' High expansion is evidence of a niche shift, which makes models
#' calibrated on the native range underpredict the invasion.
#'
#' @param .data A data frame with occurrences and background points of both
#'   ranges.
#' @param range <[`tidy-select`][tidyselect::language]> Column with the
#'   range of each row, with two values; the first (factor level or sort
#'   order) is the native range, or set `native`.
#' @param presence <[`tidy-select`][tidyselect::language]> Column marking
#'   occurrences (`TRUE` or 1) and background points (`FALSE` or 0).
#' @param env <[`tidy-select`][tidyselect::language]> Two or more numeric
#'   environmental columns.
#' @param native Value of `range` for the native range.
#' @param grid Number of grid cells along each axis.
#' @param nperm Number of permutations for the equivalency test; `0` skips
#'   it.
#' @param seed Optional random seed for the test.
#' @return A one-row tibble with `n_native`, `n_invaded` (occurrences),
#'   `schoener_d`, `warren_i`, `stability`, `expansion`, `unfilling`,
#'   `p_equivalency` (small values mean the niches are not equivalent) and
#'   `pca_variance` (share of the environmental variance on the two axes).
#' @references Broennimann, O., Fitzpatrick, M. C., Pearman, P. B.,
#'   Petitpierre, B., Pellissier, L., Yoccoz, N. G., Thuiller, W., Fortin,
#'   M.-J., Randin, C., Zimmermann, N. E., Graham, C. H. and Guisan, A.
#'   (2012). Measuring ecological niche overlap from occurrence and spatial
#'   environmental data. Global Ecology and Biogeography, 21, 481-497.
#'   \doi{10.1111/j.1466-8238.2011.00698.x}
#'
#'   Guisan, A., Petitpierre, B., Broennimann, O., Daehler, C. and Kueffer,
#'   C. (2014). Unifying niche shift studies: insights from biological
#'   invasions. Trends in Ecology and Evolution, 29, 260-269.
#'   \doi{10.1016/j.tree.2014.02.009}
#'
#'   Warren, D. L., Glor, R. E. and Turelli, M. (2008). Environmental niche
#'   equivalency versus conservatism: quantitative approaches to niche
#'   evolution. Evolution, 62, 2868-2883.
#'   \doi{10.1111/j.1558-5646.2008.00482.x}
#' @export
#' @examples
#' set.seed(1)
#' bg <- data.frame(
#'   range = rep(c("native", "invaded"), each = 400),
#'   temp = c(rnorm(400, 22, 3), rnorm(400, 24, 3)),
#'   rain = c(rnorm(400, 2000, 400), rnorm(400, 1800, 400))
#' )
#' bg$presence <- 0
#' # Invaded-range occurrences extend into warmer climates: a niche shift
#' occ <- data.frame(
#'   range = rep(c("native", "invaded"), each = 150),
#'   temp = c(rnorm(150, 21, 1.5), rnorm(150, 25, 1.5)),
#'   rain = c(rnorm(150, 2100, 200), rnorm(150, 1900, 200)),
#'   presence = 1
#' )
#' inv_niche_overlap(rbind(bg, occ), range, presence, c(temp, rain),
#'   native = "native", nperm = 19, seed = 1)
inv_niche_overlap <- function(.data, range, presence, env, native = NULL,
                              grid = 100, nperm = 99, seed = NULL) {
  check_data_frame(.data)
  data <- as_plain_tibble(.data)
  range_col <- select_one(rlang::enquo(range), data, "range")
  pres_col <- select_one(rlang::enquo(presence), data, "presence")
  env_cols <- select_many(rlang::enquo(env), data, "env")
  if (length(env_cols) < 2) cli::cli_abort("{.arg env} must select at least two numeric columns.")
  for (v in env_cols) check_numeric_col(data, v)
  check_integerish(grid)
  check_integerish(nperm, min = 0)
  if (grid < 10) cli::cli_abort("{.arg grid} must be at least 10.")
  rg <- as.character(data[[range_col]])
  lv <- if (is.factor(data[[range_col]])) levels(droplevels(data[[range_col]])) else sort(unique(rg))
  if (length(lv) != 2) cli::cli_abort("{.field {range_col}} must have exactly two values.")
  if (!is.null(native)) {
    if (!native %in% lv) cli::cli_abort("{.val {native}} is not a value of {.field {range_col}}.")
    lv <- c(native, setdiff(lv, native))
  }
  pres <- as_binary(data[[pres_col]], pres_col)
  x <- as.matrix(data[env_cols])
  ok <- stats::complete.cases(x) & !is.na(pres) & !is.na(rg)
  x <- x[ok, , drop = FALSE]
  pres <- pres[ok]
  rg <- rg[ok]
  is1 <- rg == lv[1]
  if (sum(pres & is1) < 5 || sum(pres & !is1) < 5) {
    cli::cli_abort("Each range needs at least five occurrences.")
  }
  if (sum(!pres & is1) < 5 || sum(!pres & !is1) < 5) {
    cli::cli_abort("Each range needs background points (rows with {.field {pres_col}} 0).")
  }
  pca <- stats::prcomp(x[!pres, , drop = FALSE], center = TRUE, scale. = TRUE)
  sc <- stats::predict(pca, x)[, 1:2, drop = FALSE]
  var2 <- sum(pca$sdev[1:2]^2) / sum(pca$sdev^2)
  lim <- apply(sc[!pres, , drop = FALSE], 2, range)
  pad <- 0.05 * (lim[2, ] - lim[1, ])
  gx <- seq(lim[1, 1] - pad[1], lim[2, 1] + pad[1], length.out = grid)
  gy <- seq(lim[1, 2] - pad[2], lim[2, 2] + pad[2], length.out = grid)
  bw <- apply(sc[!pres, , drop = FALSE], 2, niche_bandwidth)
  env1 <- niche_density(sc[!pres & is1, , drop = FALSE], gx, gy, bw)
  env2 <- niche_density(sc[!pres & !is1, , drop = FALSE], gx, gy, bw)
  z_of <- function(occ, envd) niche_occupancy(occ, envd, gx, gy, bw)
  z1 <- z_of(sc[pres & is1, , drop = FALSE], env1)
  z2 <- z_of(sc[pres & !is1, , drop = FALSE], env2)
  ov <- niche_overlap(z1$cor, z2$cor)
  dyn <- niche_dynamics(z1, z2, env1, env2)
  p_eq <- NA_real_
  if (nperm > 0) {
    if (!is.null(seed)) withr::local_seed(seed)
    occ <- sc[pres, , drop = FALSE]
    n1 <- sum(pres & is1)
    d_sim <- vapply(seq_len(nperm), function(k) {
      i <- sample.int(nrow(occ), n1)
      a <- z_of(occ[i, , drop = FALSE], env1)
      b <- z_of(occ[-i, , drop = FALSE], env2)
      niche_overlap(a$cor, b$cor)[["d"]]
    }, 1)
    p_eq <- (sum(d_sim <= ov[["d"]]) + 1) / (nperm + 1)
  }
  tibble::tibble(
    native = lv[1], invaded = lv[2],
    n_native = sum(pres & is1), n_invaded = sum(pres & !is1),
    schoener_d = ov[["d"]], warren_i = ov[["i"]],
    stability = dyn[["stability"]], expansion = dyn[["expansion"]],
    unfilling = dyn[["unfilling"]], p_equivalency = p_eq,
    pca_variance = var2
  )
}

niche_bandwidth <- function(v) {
  h <- 1.06 * min(stats::sd(v), stats::IQR(v) / 1.34) * length(v)^(-1 / 5)
  if (!is.finite(h) || h <= 0) h <- 1.06 * stats::sd(v) * length(v)^(-1 / 5)
  h
}

# Gaussian product kernel density of points `p` (two columns) on the grid.
niche_density <- function(p, gx, gy, bw) {
  kx <- stats::dnorm(outer(gx, p[, 1], "-") / bw[1]) / bw[1]
  ky <- stats::dnorm(outer(gy, p[, 2], "-") / bw[2]) / bw[2]
  d <- kx %*% t(ky) / nrow(p)
  # Threshold: below the lowest density at any input point counts as absent
  at <- niche_at(d, p, gx, gy)
  d[d < min(at)] <- 0
  d
}

niche_at <- function(d, p, gx, gy) {
  ix <- pmin(pmax(round((p[, 1] - gx[1]) / (gx[2] - gx[1])) + 1, 1), length(gx))
  iy <- pmin(pmax(round((p[, 2] - gy[1]) / (gy[2] - gy[1])) + 1, 1), length(gy))
  d[cbind(ix, iy)]
}

niche_occupancy <- function(occ, envd, gx, gy, bw) {
  uncor <- niche_density(occ, gx, gy, bw)
  uncor[envd == 0] <- 0
  cor <- ifelse(envd > 0, uncor / envd, 0)
  if (max(cor) > 0) cor <- cor / max(cor)
  if (max(uncor) > 0) uncor <- uncor / max(uncor)
  list(cor = cor, uncor = uncor)
}

niche_overlap <- function(a, b) {
  p1 <- a / sum(a)
  p2 <- b / sum(b)
  c(d = 1 - 0.5 * sum(abs(p1 - p2)), i = 1 - 0.5 * sum((sqrt(p1) - sqrt(p2))^2))
}

# COUE indices (Guisan et al. 2014) in environments available in both
# ranges, weighted by occurrence density as in ecospat.niche.dyn.index().
niche_dynamics <- function(z1, z2, env1, env2) {
  shared <- env1 > 0 & env2 > 0
  occ1 <- z1$uncor > 0 & shared
  occ2 <- z2$uncor > 0 & shared
  w2 <- z2$uncor * shared
  w1 <- z1$uncor * shared
  expansion <- sum(w2[occ2 & !occ1]) / sum(w2[occ2])
  stability <- 1 - expansion
  unfilling <- sum(w1[occ1 & !occ2]) / sum(w1[occ1])
  c(stability = stability, expansion = expansion, unfilling = unfilling)
}

#' Rate of introduction from first records, allowing for discovery effort
#'
#' @description
#' The number of alien species first recorded each year rises with both
#' the rate of introduction and the effort put into finding them. Solow
#' and Costello (2004) separate the two: species arrive at rate
#' \eqn{\mu_t = \exp(\beta_0 + \beta_1 t)}, and each undiscovered species
#' is found in year `t` with probability
#' \eqn{\pi_t = \mathrm{logit}^{-1}(\gamma_0 + \gamma_1 t)}, so the expected
#' first records in year `t` are
#' \eqn{\lambda_t = \sum_{s \le t} \mu_s \pi_t \prod_{r=s}^{t-1}(1 - \pi_r)}.
#' The four parameters are fitted by Poisson maximum likelihood. A
#' positive `beta_1` means introductions are accelerating even after
#' allowing for growing discovery effort; a positive `gamma_1` means
#' detection has improved.
#'
#' Time runs from the first year in the data, so years before the first
#' record are included only when given as rows with a count of zero. The
#' two rates are only weakly separable with short records; check the
#' widths of the intervals.
#'
#' @param .data A data frame with one row per species (with the year of its
#'   first record) or one row per year (with a count).
#' @param year <[`tidy-select`][tidyselect::language]> Column with the year.
#' @param count <[`tidy-select`][tidyselect::language]> Optional column with
#'   the number of first records in each year. Without it each row is one
#'   species.
#' @param conf_level Confidence level of the Wald intervals.
#' @return A tibble of class `inv_discovery` with one row per year: `year`,
#'   `observed`, `expected` (fitted first records), `introduced`
#'   (estimated introductions) and `detection` (discovery probability).
#'   The attribute `"coefficients"` holds a tibble of the four parameters
#'   with standard errors and intervals, and `"undiscovered"` the expected
#'   number of species introduced but not yet recorded by the last year.
#' @references Solow, A. R. and Costello, C. J. (2004). Estimating the rate
#'   of species introductions from the discovery record. Ecology, 85,
#'   1822-1825. \doi{10.1890/03-3102}
#' @export
#' @examples
#' set.seed(4)
#' yrs <- 1900:2000
#' mu <- exp(-1 + 0.025 * (yrs - 1900))
#' pi_t <- plogis(-3 + 0.03 * (yrs - 1900))
#' # Undiscovered species accumulate and are found with probability pi_t
#' pool <- 0
#' lam <- numeric(length(yrs))
#' for (t in seq_along(yrs)) {
#'   pool <- pool + mu[t]
#'   lam[t] <- pool * pi_t[t]
#'   pool <- pool * (1 - pi_t[t])
#' }
#' records <- data.frame(year = yrs, n = rpois(length(yrs), lam))
#' fit <- inv_discovery_rate(records, year, count = n)
#' attr(fit, "coefficients")
inv_discovery_rate <- function(.data, year, count = NULL, conf_level = 0.95) {
  check_data_frame(.data)
  data <- as_plain_tibble(.data)
  yr_col <- select_one(rlang::enquo(year), data, "year")
  n_col <- select_one(rlang::enquo(count), data, "count", required = FALSE)
  check_numeric_col(data, yr_col)
  yrs <- data[[yr_col]]
  if (anyNA(yrs) || any(abs(yrs - round(yrs)) > 1e-8)) {
    cli::cli_abort("{.field {yr_col}} must contain whole years without missing values.")
  }
  all_years <- seq(min(yrs), max(yrs))
  w <- if (is.null(n_col)) rep(1, length(yrs)) else check_numeric_col(data, n_col, non_negative = TRUE)
  y <- as.numeric(tapply(c(w, rep(0, length(all_years))), c(yrs, all_years), sum))
  if (length(all_years) < 8 || sum(y) < 10) {
    cli::cli_abort("Need at least 8 years and 10 first records.")
  }
  tt <- all_years - min(all_years)
  nll <- function(th) {
    lam <- discovery_lambda(th, tt)
    if (any(!is.finite(lam)) || any(lam <= 0)) return(1e100)
    -sum(stats::dpois(y, lam, log = TRUE))
  }
  starts <- list(
    c(log(mean(y) + 0.1), 0, 0, 0),
    c(log(mean(y) + 0.1) + 1, 0, -2, 0.02),
    c(log(mean(y) + 0.1) - 1, 0.02, -1, 0)
  )
  fits <- lapply(starts, function(s) {
    tryCatch(stats::optim(s, nll, method = "BFGS", control = list(maxit = 2000, reltol = 1e-12)),
      error = function(e) NULL
    )
  })
  fits <- Filter(Negate(is.null), fits)
  best <- fits[[which.min(vapply(fits, `[[`, 1, "value"))]]
  vc <- safe_vcov(nll, best$par)
  se <- safe_sqrt(diag(vc))
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  coefs <- tibble::tibble(
    term = c("beta_0", "beta_1", "gamma_0", "gamma_1"),
    estimate = best$par, std_error = se,
    conf_low = best$par - z * se, conf_high = best$par + z * se
  )
  lam <- discovery_lambda(best$par, tt)
  mu <- exp(best$par[1] + best$par[2] * tt)
  pi_t <- stats::plogis(best$par[3] + best$par[4] * tt)
  out <- tibble::tibble(
    year = all_years, observed = y, expected = lam, introduced = mu, detection = pi_t
  )
  attr(out, "coefficients") <- coefs
  attr(out, "undiscovered") <- sum(mu) - sum(lam)
  attr(out, "loglik") <- -best$value
  class(out) <- c("inv_discovery", class(out))
  out
}

discovery_lambda <- function(th, tt) {
  mu <- exp(th[1] + th[2] * tt)
  p <- stats::plogis(th[3] + th[4] * tt)
  n <- length(tt)
  # Undiscovered pool carried forward: U_t = (U_{t-1} + mu_t) * (1 - p_t)
  lam <- numeric(n)
  pool <- 0
  for (t in seq_len(n)) {
    pool <- pool + mu[t]
    lam[t] <- pool * p[t]
    pool <- pool * (1 - p[t])
  }
  lam
}

#' SEICAT socio-economic impact classification
#'
#' Assigns each alien taxon its Socio-Economic Impact Classification of
#' Alien Taxa (SEICAT) category from a table of impact records (Bacher et
#' al. 2018), the counterpart of [inv_eicat_score()] for impacts on human
#' well-being (safety, material and immaterial assets, health, and social,
#' spiritual and cultural relations). As in the IUCN scheme, the category is
#' the most severe magnitude recorded: Minimal Concern (MC), Minor (MN),
#' Moderate (MO), Major (MR) or Massive (MV); MO and above are harmful.
#'
#' @inheritParams inv_eicat_score
#' @param mechanism <[`tidy-select`][tidyselect::language]> Optional column
#'   with the constituent of well-being affected.
#' @return As [inv_eicat_score()], with `seicat_category` and
#'   `seicat_score`.
#' @references Bacher, S., Blackburn, T. M., Essl, F., Genovesi, P.,
#'   Heikkila, J., Jeschke, J. M., Jones, G., Keller, R., Kenis, M., Kueffer,
#'   C., Martinou, A. F., Nentwig, W., Pergl, J., Pysek, P., Rabitsch, W.,
#'   Richardson, D. M., Roy, H. E., Saul, W.-C., Scalera, R., Vila, M.,
#'   Wilson, J. R. U. and Kumschick, S. (2018). Socio-economic impact
#'   classification of alien taxa (SEICAT). Methods in Ecology and
#'   Evolution, 9, 159-168. \doi{10.1111/2041-210X.12844}
#' @export
#' @examples
#' records <- data.frame(
#'   species = c("sp01", "sp01", "sp02", "sp03"),
#'   magnitude = c("MN", "MR", "MC", "DD"),
#'   mechanism = c("health", "material assets", "safety", "health")
#' )
#' inv_seicat_score(records, species, magnitude, mechanism)
inv_seicat_score <- function(.data, species, magnitude, mechanism = NULL,
                             confidence = NULL) {
  out <- inv_eicat_score(.data, {{ species }}, {{ magnitude }},
    mechanism = {{ mechanism }}, confidence = {{ confidence }}
  )
  names(out)[names(out) == "eicat_category"] <- "seicat_category"
  names(out)[names(out) == "eicat_score"] <- "seicat_score"
  out
}
