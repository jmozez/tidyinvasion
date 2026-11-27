lv <- c("presence", "background")

test_that("TSS equals sensitivity plus specificity minus one", {
  truth <- factor(c(rep("presence", 10), rep("background", 10)), levels = lv)
  est <- factor(c(rep("presence", 8), rep("background", 2), rep("presence", 3),
    rep("background", 7)), levels = lv)
  expect_equal(tss_vec(truth, est), 0.8 + 0.7 - 1)
  df <- data.frame(truth = truth, est = est)
  res <- tss(df, truth, est)
  expect_equal(res$.metric, "tss")
  expect_equal(res$.estimator, "binary")
  expect_equal(res$.estimate, 0.5)
  expect_equal(res$.estimate, yardstick::j_index(df, truth, est)$.estimate)
  # Second level as the event
  expect_equal(tss_vec(truth, est, event_level = "second"), 0.7 + 0.8 - 1)
  # Missing values
  est_na <- est
  est_na[1] <- NA
  expect_true(is.na(tss_vec(truth, est_na, na_rm = FALSE)))
  expect_false(is.na(tss_vec(truth, est_na)))
  # Case weights
  w <- rep(1, 20)
  expect_equal(tss_vec(truth, est, case_weights = w), 0.5)
})

test_that("TSS works in metric sets and with multiclass data", {
  truth <- factor(c("a", "b", "c", "a", "b", "c"))
  est <- factor(c("a", "b", "c", "a", "c", "b"))
  macro <- tss_vec(truth, est)
  expect_equal(macro, yardstick::sens_vec(truth, est) + yardstick::spec_vec(truth, est) - 1)
  ms <- yardstick::metric_set(tss, yardstick::accuracy)
  out <- ms(data.frame(truth = truth, est = est), truth = truth, estimate = est)
  expect_equal(out$.metric, c("tss", "accuracy"))
  expect_s3_class(tss, "class_metric")
})

test_that("Boyce index is high for informative and low for random predictions", {
  set.seed(1)
  suit <- stats::runif(4000)
  truth <- factor(ifelse(stats::runif(4000) < suit^2, "presence", "background"), levels = lv)
  good <- boyce_index_vec(truth, suit)
  expect_true(good > 0.9)
  rand <- replicate(30, boyce_index_vec(truth, stats::runif(4000)))
  expect_true(abs(mean(rand)) < 0.25)
  bad <- boyce_index_vec(truth, 1 - suit)
  expect_true(bad < -0.9)
  df <- data.frame(truth = truth, suit = suit)
  res <- boyce_index(df, truth, suit)
  expect_equal(res$.metric, "boyce_index")
  expect_equal(res$.estimate, good)
  expect_s3_class(boyce_index, "prob_metric")
  wide <- boyce_index(df, truth, suit, window_width = 0.2, n_windows = 51)
  expect_true(wide$.estimate > 0.9)
})

test_that("Boyce index handles edge cases", {
  truth <- factor(c("presence", "background", "background"), levels = lv)
  expect_true(is.na(boyce_index_vec(truth, c(0.5, 0.5, 0.5))))
  expect_error(boyce_index_vec(truth, c(0.1, 0.2, 0.3), window_width = 2), "between 0 and 1")
  multi <- factor(c("a", "b", "c"))
  expect_error(boyce_index_vec(multi, matrix(stats::runif(9), 3)))
  ms <- yardstick::metric_set(boyce_index, yardstick::roc_auc)
  set.seed(2)
  suit <- stats::runif(500)
  tr <- factor(ifelse(stats::runif(500) < suit, "presence", "background"), levels = lv)
  out <- ms(data.frame(tr = tr, suit = suit), truth = tr, suit)
  expect_equal(out$.metric, c("boyce_index", "roc_auc"))
})
