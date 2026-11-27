test_that("inv_sdm specification prints and updates", {
  spec <- inv_sdm(degree = 2)
  expect_s3_class(spec, c("inv_sdm", "model_spec"))
  expect_equal(spec$mode, "classification")
  expect_output(print(spec), "Species distribution model")
  upd <- update(spec, degree = 1)
  expect_equal(rlang::eval_tidy(upd$args$degree), 1)
  expect_error(inv_sdm(mode = "regression"), "classification")
})

test_that("inv_sdm glm engine matches a hand-built quadratic GLM", {
  fit <- inv_sdm(degree = 2) |>
    parsnip::set_engine("glm") |>
    parsnip::fit(presence ~ temp + rain, data = inv_sdm_data)
  expect_s3_class(fit$fit, "inv_sdm_fit")
  d <- inv_sdm_data
  zt <- (d$temp - mean(d$temp)) / stats::sd(d$temp)
  zr <- (d$rain - mean(d$rain)) / stats::sd(d$rain)
  ref <- stats::glm(I(presence == "presence") ~ zt + zr + I(zt^2) + I(zr^2),
    family = stats::binomial(), data = d
  )
  prob <- predict(fit, d, type = "prob")
  expect_named(prob, c(".pred_presence", ".pred_background"))
  expect_equal(prob$.pred_presence, unname(stats::fitted(ref)), tolerance = 1e-6)
  expect_equal(prob$.pred_presence + prob$.pred_background, rep(1, nrow(d)))
  cls <- predict(fit, d)
  expect_equal(levels(cls$.pred_class), c("presence", "background"))
  # The default class threshold maximises TSS on the training data
  th <- fit$fit$threshold
  expect_equal(as.character(cls$.pred_class),
    ifelse(prob$.pred_presence >= th, "presence", "background"))
  tss_at <- function(t) {
    tss_vec(d$presence, factor(ifelse(prob$.pred_presence >= t, "presence", "background"),
      levels = c("presence", "background")))
  }
  expect_true(tss_at(th) >= tss_at(0.5))
  expect_true(tss_at(th) >= tss_at(th * 1.5) && tss_at(th) >= tss_at(th / 1.5))
  fixed <- inv_sdm(degree = 2) |>
    parsnip::set_engine("glm", threshold = 0.3) |>
    parsnip::fit(presence ~ temp + rain, data = inv_sdm_data)
  expect_equal(fixed$fit$threshold, 0.3)
  expect_output(print(fixed$fit), "Class threshold")
  td <- tidy(fit$fit)
  expect_equal(nrow(td), 5)
  gl <- glance(fit$fit)
  expect_true(gl$deviance_explained > 0)
})

test_that("inv_sdm recovers the virtual species optimum and is evaluable", {
  fit <- inv_sdm(degree = 2) |>
    parsnip::set_engine("glm") |>
    parsnip::fit(presence ~ temp + rain + forest, data = inv_sdm_data)
  grid <- data.frame(temp = seq(20, 28, by = 0.1), rain = 2500, forest = 0.5)
  p <- predict(fit, grid, type = "prob")$.pred_presence
  expect_equal(grid$temp[which.max(p)], 24, tolerance = 0.05)
  scored <- dplyr::bind_cols(inv_sdm_data, predict(fit, inv_sdm_data, type = "prob"))
  expect_true(boyce_index(scored, presence, .pred_presence)$.estimate > 0.8)
})

test_that("iwlr engine gives a relative suitability index", {
  fit <- inv_sdm(degree = 1) |>
    parsnip::set_engine("iwlr", bg_weight = 1000) |>
    parsnip::fit(presence ~ temp + forest, data = inv_sdm_data)
  expect_equal(fit$fit$method, "iwlr")
  p <- predict(fit, inv_sdm_data, type = "prob")$.pred_presence
  expect_true(all(p >= 0 & p <= 1))
  glm_fit <- inv_sdm_fit(inv_sdm_data[c("temp", "forest")], inv_sdm_data$presence, degree = 1)
  # Slopes are close to the unweighted logistic slopes when presences are rare
  expect_equal(unname(stats::coef(fit$fit$fit))[-1], unname(stats::coef(glm_fit$fit))[-1],
    tolerance = 0.3
  )
  expect_error(inv_sdm_fit(data.frame(a = "x"), factor(c("p"))), "numeric")
})

test_that("inv_sdm works inside a workflow with resampling", {
  skip_if_not_installed("workflows")
  wf <- workflows::workflow() |>
    workflows::add_formula(presence ~ temp + rain + forest) |>
    workflows::add_model(inv_sdm(degree = 2) |> parsnip::set_engine("glm"))
  set.seed(3)
  folds <- inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 3, block_size = 2)
  aucs <- vapply(folds$splits, function(s) {
    f <- parsnip::fit(wf, rsample::analysis(s))
    a <- rsample::assessment(s)
    p <- predict(f, a, type = "prob")
    yardstick::roc_auc_vec(a$presence, p$.pred_presence)
  }, numeric(1))
  expect_true(all(aucs > 0.7))
})

skellam_data <- function(D = 50, r = 0.5, log_k = log(1e4), noise = 0) {
  t <- 1:30
  set.seed(9)
  rad <- sqrt(4 * D * t * (r * t + log_k - log(4 * pi * D * t)))
  data.frame(years = t, radius = rad + stats::rnorm(30, 0, noise))
}

test_that("reaction-diffusion model recovers Skellam parameters", {
  d <- skellam_data()
  spec <- inv_reaction_diffusion() |> parsnip::set_engine("skellam")
  expect_output(print(spec), "Reaction-diffusion")
  fit <- parsnip::fit(spec, radius ~ years, data = d)
  rd <- fit$fit
  expect_s3_class(rd, "inv_rd_fit")
  expect_equal(rd$speed, 2 * sqrt(50 * 0.5), tolerance = 0.02)
  pr <- predict(fit, data.frame(years = c(10, 40)))
  expect_equal(pr$.pred[1], d$radius[10], tolerance = 0.01)
  td <- tidy(rd)
  expect_equal(td$term, c("diffusion", "growth_rate", "log_k", "speed"))
  expect_true(glance(rd)$sigma < 1)
  expect_output(print(rd), "Asymptotic speed")
})

test_that("reaction-diffusion parameters can be fixed and updated", {
  d <- skellam_data(noise = 2)
  spec <- inv_reaction_diffusion(growth_rate = 0.5) |> parsnip::set_engine("skellam")
  fit <- parsnip::fit(spec, radius ~ years, data = d)
  expect_equal(fit$fit$growth_rate, 0.5)
  expect_equal(fit$fit$diffusion, 50, tolerance = 0.1)
  expect_true(tidy(fit$fit)$fixed[2])
  upd <- update(spec, diffusion = 10)
  expect_equal(rlang::eval_tidy(upd$args$diffusion), 10)
  expect_error(inv_rd_fit(data.frame(t = c(0, 1, 2, 3)), 1:4), "positive")
  expect_error(inv_rd_fit(data.frame(t = 1:5, u = 1:5), 1:5), "exactly one")
  expect_error(inv_reaction_diffusion(mode = "classification"), "regression")
})

test_that("dials parameters are available for tuning", {
  skip_if_not_installed("dials")
  expect_s3_class(spread_growth_rate(), "quant_param")
  expect_s3_class(spread_diffusion(), "quant_param")
})
