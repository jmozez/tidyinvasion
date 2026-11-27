test_that("propagule pressure summaries are correct", {
  d <- data.frame(g = c("a", "a", "b"), size = c(10, 30, 5), t = c(2000, 2002, 2001))
  out <- inv_propagule_pressure(d, size = size, .by = g)
  expect_equal(out$g, c("a", "b"))
  expect_equal(out$n_events, c(2L, 1L))
  expect_equal(out$total_propagules, c(40, 5))
  expect_equal(out$mean_size, c(20, 5))
  expect_equal(out$pp_index, log10(1 + c(40, 5)))
  expect_equal(out$cv_size[1], stats::sd(c(10, 30)) / 20)
  dec <- inv_propagule_pressure(d, size = size, time = t, decay = 0.5, .by = g)
  expect_equal(dec$pp_discounted[1], 10 * exp(-0.5 * 2) + 30)
  expect_error(inv_propagule_pressure(d, size = size, decay = 0.1), "time")
  expect_error(inv_propagule_pressure(d, size = g), "must be numeric")
})

test_that("propagule pressure reads the size column of an inv_pathway", {
  pw <- inv_pathway(inv_introductions, pathway = pathway, size = propagule_size)
  out <- inv_propagule_pressure(pw, .by = pathway)
  expect_equal(sum(out$total_propagules), sum(inv_introductions$propagule_size))
  grouped <- dplyr::group_by(inv_introductions, region)
  out2 <- inv_propagule_pressure(grouped, size = propagule_size)
  expect_equal(nrow(out2), 4)
})

test_that("establishment models recover known parameters", {
  set.seed(42)
  n <- round(exp(stats::runif(3000, 0, 5)))
  y <- stats::runif(3000) < 1 - exp(-0.05 * n)
  d <- data.frame(n = n, y = y)
  fit <- inv_establishment_prob(d, y, n, model = "exponential")
  expect_s3_class(fit, "inv_establishment")
  expect_equal(unname(fit$estimate["alpha"]), 0.05, tolerance = 0.1)
  expect_equal(fit$n50, log(2) / fit$estimate[["alpha"]])

  y2 <- stats::runif(3000) < 1 - exp(-0.01 * n^1.5)
  fit_w <- inv_establishment_prob(data.frame(n = n, y = y2), y, n, model = "weibull")
  expect_equal(unname(fit_w$estimate["c"]), 1.5, tolerance = 0.1)

  fit_l <- inv_establishment_prob(d, y, n, model = "logistic")
  ref <- stats::glm(y ~ log(n), family = stats::binomial())
  expect_equal(unname(fit_l$estimate), unname(stats::coef(ref)), tolerance = 1e-4)
  expect_equal(fit_l$loglik, as.numeric(stats::logLik(ref)), tolerance = 1e-6)
})

test_that("establishment fit has working methods", {
  fit <- inv_establishment_prob(inv_introductions, established, propagule_size,
    model = "weibull"
  )
  expect_output(print(fit), "dose-response")
  td <- tidy(fit)
  expect_equal(td$term, c("alpha", "c"))
  expect_true(all(td$conf.low < td$estimate & td$estimate < td$conf.high))
  gl <- glance(fit)
  expect_equal(gl$n, nrow(inv_introductions))
  aug <- augment(fit)
  expect_true(all(aug$.fitted >= 0 & aug$.fitted <= 1))
  pr <- predict(fit, data.frame(propagule_size = c(1, 1000)))
  expect_true(pr$.pred[2] > pr$.pred[1])
  expect_error(predict(fit, data.frame(x = 1)), "must contain")
  expect_error(
    inv_establishment_prob(data.frame(y = c(1, 1, 1), n = 1:3), y, n),
    "both successes and failures"
  )
  expect_error(
    inv_establishment_prob(data.frame(y = c(1, 0, 1), n = c(0, 1, 2)), y, n),
    "positive"
  )
})

test_that("occupancy model recovers psi and p", {
  set.seed(7)
  n <- 2000
  z <- stats::runif(n) < 0.4
  y <- sapply(1:4, function(j) as.integer(z & stats::runif(n) < 0.3))
  colnames(y) <- paste0("v", 1:4)
  d <- as.data.frame(y)
  out <- inv_detection_prob(d, surveys = dplyr::everything())
  expect_equal(out$psi, 0.4, tolerance = 0.1)
  expect_equal(out$p, 0.3, tolerance = 0.1)
  expect_equal(out$cumulative_p, 1 - (1 - out$p)^4)
  expect_equal(out$surveys_needed, ceiling(log(0.05) / log(1 - out$p)))
  expect_true(out$psi > out$naive_occupancy)
})

test_that("detection handles groups, missing visits and bad input", {
  out <- inv_detection_prob(inv_surveys, surveys = dplyr::starts_with("visit"), .by = habitat)
  expect_equal(sort(out$habitat), c("forest", "grassland", "urban"))
  expect_true(all(out$p > 0 & out$p < 1))
  bad <- data.frame(a = c(0, 2), b = c(1, 0))
  expect_error(inv_detection_prob(bad, surveys = c(a, b)), "only 0, 1 or NA")
  expect_error(inv_detection_prob(bad, surveys = a), "at least two")
})
