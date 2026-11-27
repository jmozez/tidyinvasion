test_that("eradication model matches closed-form results", {
  d <- data.frame(n0 = c(100, 100), r = c(0.5, 0.5))
  out <- inv_eradication_feasibility(d, population = n0, growth_rate = r,
    detect_prob = c(0.5, 0.2), efficacy = 1, rounds = 2, horizon = 10, target = 0.95
  )
  lambda <- exp(0.5) * (1 - c(0.5, 0.2))^2
  expect_equal(out$lambda, lambda)
  expect_equal(out$feasible, lambda < 1)
  expect_equal(out$p_eradicated, exp(-100 * lambda^10))
  t1 <- ceiling(log(-log(0.95) / 100) / log(lambda[1]))
  expect_equal(out$years_to_target[1], t1)
  expect_true(exp(-100 * lambda[1]^t1) >= 0.95)
  expect_true(exp(-100 * lambda[1]^(t1 - 1)) < 0.95)
  expect_equal(out$years_to_target[2], Inf)
  # Minimum rounds: smallest k with exp(r) * (1 - 0.2)^k < 1
  k <- out$min_rounds[2]
  expect_true(exp(0.5) * 0.8^k < 1)
  expect_true(exp(0.5) * 0.8^(k - 1) >= 1)
})

test_that("eradication accepts columns and constants and computes cost", {
  sc <- data.frame(n0 = c(10, 1000), ha = c(1, 100), p = c(0.7, 0.4))
  out <- inv_eradication_feasibility(sc, population = n0, growth_rate = 0.3,
    detect_prob = p, rounds = 3, area = ha, cost_per_unit = 50
  )
  expect_true("total_cost" %in% names(out))
  expect_equal(out$total_cost, ifelse(is.finite(out$years_to_target),
    sc$ha * 50 * 3 * out$years_to_target, Inf))
  expect_error(inv_eradication_feasibility(sc, population = n0, growth_rate = 0.3,
    detect_prob = 2), "detect_prob")
  expect_error(inv_eradication_feasibility(sc, population = n0, growth_rate = c(1, 2, 3),
    detect_prob = 0.5), "length")
  tiny <- inv_eradication_feasibility(data.frame(n = 0.01), population = n,
    growth_rate = 1, detect_prob = 0)
  expect_equal(tiny$years_to_target, 0)
})

test_that("horizon scan aggregates assessors and ranks taxa", {
  d <- data.frame(
    sp = rep(c("x", "y"), each = 3),
    who = rep(c("A", "B", "C"), 2),
    arrival = c(5, 4, 5, 1, 2, 1),
    impact = c(5, 5, 4, 2, 1, 1)
  )
  out <- inv_horizon_scan(d, arrival, impact, species = sp, assessor = who)
  expect_equal(out$sp, c("x", "y"))
  expect_equal(out$arrival, c(5, 1))
  expect_equal(out$score, c(25, 1))
  expect_equal(out$scaled_score, c(1, 0))
  expect_equal(as.character(out$priority), c("high", "low"))
  expect_equal(out$n_assessors, c(3L, 3L))
  expect_true(all(out$disagreement > 0))

  gm <- inv_horizon_scan(d, arrival, impact, species = sp, method = "geometric_mean")
  expect_equal(gm$score, c(5, 1))
  sm <- inv_horizon_scan(d, arrival, impact, species = sp, method = "sum")
  expect_equal(sm$scaled_score, c(1, 0))
  expect_error(inv_horizon_scan(d, species = sp), "at least one criterion")
  expect_error(inv_horizon_scan(d, arrival, species = sp, thresholds = c(0.9, 0.1)), "increasing")
})

test_that("horizon scan runs on the simulated scores", {
  out <- inv_horizon_scan(inv_horizon, arrival:impact, species = species, assessor = assessor)
  expect_equal(nrow(out), 30)
  expect_equal(out$rank[1], 1)
  expect_s3_class(out$priority, "ordered")
})
