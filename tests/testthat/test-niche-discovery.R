niche_data <- function(shift, seed = 1) {
  set.seed(seed)
  bg <- data.frame(
    range = rep(c("native", "invaded"), each = 400),
    temp = c(stats::rnorm(400, 22, 3), stats::rnorm(400, 23, 3)),
    rain = c(stats::rnorm(400, 2000, 400), stats::rnorm(400, 1900, 400)),
    presence = 0
  )
  occ <- data.frame(
    range = rep(c("native", "invaded"), each = 150),
    temp = c(stats::rnorm(150, 21.5, 1.5), stats::rnorm(150, 21.5 + shift, 1.5)),
    rain = c(stats::rnorm(150, 2000, 200), stats::rnorm(150, 2000, 200)),
    presence = 1
  )
  rbind(bg, occ)
}

test_that("inv_niche_overlap() separates conserved and shifted niches", {
  same <- inv_niche_overlap(niche_data(0), range, presence, c(temp, rain),
    native = "native", nperm = 19, seed = 1
  )
  moved <- inv_niche_overlap(niche_data(4), range, presence, c(temp, rain),
    native = "native", nperm = 19, seed = 1
  )
  expect_gt(same$schoener_d, 0.6)
  expect_lt(moved$schoener_d, same$schoener_d - 0.3)
  expect_gt(moved$expansion, same$expansion)
  expect_gt(same$p_equivalency, 0.05)
  expect_lte(moved$p_equivalency, 0.05)
  expect_equal(same$stability + same$expansion, 1)
  expect_true(all(c(same$warren_i, moved$warren_i) <= 1))
  expect_equal(same$native, "native")
  quick <- inv_niche_overlap(niche_data(0), range, presence, c(temp, rain),
    native = "native", nperm = 0
  )
  expect_true(is.na(quick$p_equivalency))
  expect_equal(quick$schoener_d, same$schoener_d)
})

test_that("niche overlap indices behave as defined", {
  a <- matrix(c(1, 0, 0, 0), 2)
  expect_equal(unname(niche_overlap(a, a)), c(1, 1))
  b <- matrix(c(0, 0, 0, 1), 2)
  expect_equal(unname(niche_overlap(a, b)), c(0, 0))
  expect_error(
    inv_niche_overlap(niche_data(0), range, presence, temp),
    "at least two"
  )
})

test_that("the Solow-Costello expectation matches its sum form", {
  th <- c(0.5, 0.02, -3, 0.03)
  tt <- 0:30
  mu <- exp(th[1] + th[2] * tt)
  p <- stats::plogis(th[3] + th[4] * tt)
  direct <- vapply(seq_along(tt), function(t) {
    sum(vapply(seq_len(t), function(s) {
      surv <- if (s < t) prod(1 - p[s:(t - 1)]) else 1
      mu[s] * p[t] * surv
    }, 1))
  }, 1)
  expect_equal(discovery_lambda(th, tt), direct)
})

test_that("inv_discovery_rate() reaches the maximum likelihood", {
  set.seed(1)
  tt <- 0:100
  truth <- c(0.5, 0.02, -3, 0.03)
  y <- stats::rpois(length(tt), discovery_lambda(truth, tt))
  rec <- data.frame(year = 1900 + tt, n = y)
  fit <- inv_discovery_rate(rec, year, count = n)
  expect_s3_class(fit, "inv_discovery")
  ll_true <- sum(stats::dpois(y, discovery_lambda(truth, tt), log = TRUE))
  expect_gte(attr(fit, "loglik"), ll_true)
  cf <- attr(fit, "coefficients")
  expect_equal(cf$term, c("beta_0", "beta_1", "gamma_0", "gamma_1"))
  expect_true(cf$conf_low[2] < 0.02 && cf$conf_high[2] > 0.02)
  expect_gt(attr(fit, "undiscovered"), 0)
  expect_equal(sum(fit$observed), sum(y))
  # One row per species gives the same fit (time starts at the first record)
  rec <- rec[seq(which(rec$n > 0)[1], nrow(rec)), ]
  sp <- data.frame(year = rep(rec$year, rec$n))
  expect_equal(
    attr(inv_discovery_rate(sp, year), "loglik"),
    attr(inv_discovery_rate(rec, year, count = n), "loglik"),
    tolerance = 1e-6
  )
  expect_error(inv_discovery_rate(data.frame(year = 1:3), year), "at least")
})

test_that("inv_seicat_score() mirrors EICAT with SEICAT names", {
  rec <- data.frame(
    species = c("sp01", "sp01", "sp02", "sp03"),
    magnitude = c("MN", "MR", "MC", "DD"),
    mechanism = c("health", "material assets", "safety", "health")
  )
  s <- inv_seicat_score(rec, species, magnitude, mechanism)
  expect_true(all(c("seicat_category", "seicat_score") %in% names(s)))
  expect_equal(as.character(s$seicat_category), c("MR", "MC", "DD"))
  expect_equal(s$harmful, c(TRUE, FALSE, FALSE))
})
