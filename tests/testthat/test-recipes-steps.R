library(recipes)

test_that("step_inv_background subsamples background to the ratio", {
  n_pres <- sum(inv_sdm_data$presence == "presence")
  rec <- recipe(presence ~ temp + rain + forest, data = inv_sdm_data) |>
    step_inv_background(presence, ratio = 2, seed = 11)
  prepped <- prep(rec)
  out <- bake(prepped, new_data = NULL)
  expect_equal(sum(out$presence == "presence"), n_pres)
  expect_equal(sum(out$presence == "background"), 2 * n_pres)
  # Skipped on new data
  expect_equal(nrow(bake(prepped, new_data = inv_sdm_data)), nrow(inv_sdm_data))
  # Reproducible with the same seed
  again <- bake(prep(rec), new_data = NULL)
  expect_identical(out, again)
  td <- tidy(prepped, number = 1)
  expect_equal(td$terms, "presence")
  expect_equal(td$ratio, 2)
  expect_equal(tidy(rec, number = 1)$terms, "presence")
  expect_true(any(grepl("Background subsampling", cli::cli_fmt(print(prepped)))))
  expect_equal(required_pkgs(rec$steps[[1]]), "tidyinvasion")
})

test_that("stratified background spreads across environmental clusters", {
  rec <- recipe(presence ~ temp + rain + forest, data = inv_sdm_data) |>
    step_inv_background(presence, ratio = 1, method = "stratified", n_strata = 5, seed = 3)
  out <- bake(prep(rec), new_data = NULL)
  n_pres <- sum(inv_sdm_data$presence == "presence")
  expect_equal(sum(out$presence == "background"), n_pres)
  expect_error(
    recipe(presence ~ temp + rain, data = inv_sdm_data) |>
      step_inv_background(temp, rain) |>
      prep(),
    "exactly one presence column"
  )
})

test_that("step_inv_propagule_lags computes lags and cumulative pressure", {
  d <- data.frame(
    region = rep(c("a", "b"), each = 4),
    year = c(2003, 2001, 2002, 2004, 2001, 2002, 2003, 2004),
    pp = c(30, 10, 20, 40, 1, 2, 3, 4)
  )
  rec <- recipe(~., data = d) |>
    step_inv_propagule_lags(pp, time = year, group = region, lag = 1:2, decay = 0.5)
  out <- bake(prep(rec), new_data = NULL)
  # Row order is preserved
  expect_equal(out$year, d$year)
  a <- out[out$region == "a", ]
  a <- a[order(a$year), ]
  expect_equal(a$lag1_pp, c(NA, 10, 20, 30))
  expect_equal(a$lag2_pp, c(NA, NA, 10, 20))
  expect_equal(a$cumpp_pp, c(0, 10, 30, 60))
  expect_equal(a$decaypp_pp[3], 10 * exp(-0.5 * 2) + 20 * exp(-0.5))
  td <- tidy(prep(rec), number = 1)
  expect_equal(nrow(td), 2)
  expect_true(any(grepl("Propagule pressure lags", cli::cli_fmt(print(prep(rec))))))
  expect_equal(required_pkgs(rec$steps[[1]]), "tidyinvasion")
  expect_error(step_inv_propagule_lags(recipe(~., data = d), pp, time = year, lag = 0), "positive")
  expect_error(prep(recipe(~., data = d) |> step_inv_propagule_lags(region, time = year)))
})

test_that("step_inv_propagule_lags works on the introductions data", {
  annual <- inv_introductions |>
    dplyr::count(region, year, wt = propagule_size, name = "propagules")
  rec <- recipe(~., data = annual) |>
    step_inv_propagule_lags(propagules, time = year, group = region)
  out <- bake(prep(rec), new_data = NULL)
  expect_true(all(c("lag1_propagules", "cumpp_propagules") %in% names(out)))
})

test_that("step_inv_env_distance computes Mahalanobis distance and MESS", {
  set.seed(1)
  train <- data.frame(a = stats::rnorm(200), b = stats::rnorm(200, 10, 2))
  rec <- recipe(~ a + b, data = train) |> step_inv_env_distance(a, b)
  prepped <- prep(rec)
  new <- data.frame(a = c(0, 100), b = c(10, 10))
  out <- bake(prepped, new_data = new)
  expected <- sqrt(stats::mahalanobis(as.matrix(new), colMeans(train), stats::cov(train)))
  expect_equal(out$env_mahalanobis, expected, tolerance = 1e-6)
  expect_true(out$env_mess[1] > 0)
  expect_true(out$env_mess[2] < 0)
  expect_equal(as.character(out$env_mod[2]), "a")
  # MESS hand check for a value beyond the reference maximum
  mx <- max(train$a)
  mn <- min(train$a)
  expect_equal(out$env_mess[2], min(100 * (mx - 100) / (mx - mn),
    tidyinvasion:::mess_score(10, sort(train$b), min(train$b), max(train$b))))
  td <- tidy(prepped, number = 1)
  expect_equal(td$terms, c("a", "b"))
  expect_equal(td$mean, unname(colMeans(train)))
  expect_true(any(grepl("Environmental distance", cli::cli_fmt(print(prepped)))))
  expect_equal(required_pkgs(rec$steps[[1]]), "tidyinvasion")
})

test_that("step_inv_env_distance can use presences as the reference", {
  rec <- recipe(presence ~ temp + rain + forest, data = inv_sdm_data) |>
    step_inv_env_distance(temp, rain, forest, presence = presence, method = "mess")
  out <- bake(prep(rec), new_data = NULL)
  expect_true("env_mess" %in% names(out))
  expect_false("env_mahalanobis" %in% names(out))
  pres <- out$presence == "presence"
  expect_true(mean(out$env_mess[pres]) > mean(out$env_mess[!pres]))
  baked_new <- bake(prep(rec), new_data = inv_sdm_data[1:10, c("temp", "rain", "forest")])
  expect_equal(nrow(baked_new), 10)
})
