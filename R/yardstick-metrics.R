# yardstick metrics -------------------------------------------------------

#' True Skill Statistic
#'
#' The True Skill Statistic (TSS; Allouche et al. 2006) is sensitivity plus
#' specificity minus one. It ranges from -1 to 1, where 1 is perfect
#' agreement and 0 or less is no better than random, and unlike Cohen's
#' kappa it does not depend on prevalence. It is numerically the same as
#' Youden's J. For more than two classes the macro-averaged sensitivity and
#' specificity are used.
#'
#' @param data A data frame with the `truth` and `estimate` columns.
#' @param truth The column of true classes (a factor).
#' @param estimate The column of predicted classes (a factor with the same
#'   levels).
#' @param estimator One of `"binary"`, `"macro"`, `"macro_weighted"` or
#'   `"micro"`; `NULL` chooses `"binary"` for two classes.
#' @param na_rm Remove missing values?
#' @param case_weights Optional column of case weights.
#' @param event_level `"first"` or `"second"`: which level of `truth` is the
#'   presence (event).
#' @param ... Not used.
#'
#' @return For `tss()`, a tibble with columns `.metric`, `.estimator` and
#'   `.estimate`. For `tss_vec()`, a single number.
#' @references Allouche, O., Tsoar, A. and Kadmon, R. (2006). Assessing the
#'   accuracy of species distribution models: prevalence, kappa and the true
#'   skill statistic (TSS). *Journal of Applied Ecology*, 43, 1223-1232.
#'   \doi{10.1111/j.1365-2664.2006.01214.x}
#' @family invasion metrics
#' @export
#' @examples
#' df <- data.frame(
#'   truth = factor(c("presence", "presence", "background", "background", "presence"),
#'     levels = c("presence", "background")),
#'   pred = factor(c("presence", "background", "background", "background", "presence"),
#'     levels = c("presence", "background"))
#' )
#' tss(df, truth, pred)
#' tss_vec(df$truth, df$pred)
tss <- function(data, ...) {
  UseMethod("tss")
}
tss <- yardstick::new_class_metric(tss, direction = "maximize")

#' @rdname tss
#' @export
tss.data.frame <- function(data, truth, estimate, estimator = NULL, na_rm = TRUE,
                           case_weights = NULL, event_level = "first", ...) {
  yardstick::class_metric_summarizer(
    name = "tss", fn = tss_vec, data = data,
    truth = !!rlang::enquo(truth), estimate = !!rlang::enquo(estimate),
    estimator = estimator, na_rm = na_rm, case_weights = !!rlang::enquo(case_weights),
    event_level = event_level
  )
}

#' @rdname tss
#' @export
tss_vec <- function(truth, estimate, estimator = NULL, na_rm = TRUE, case_weights = NULL,
                    event_level = "first", ...) {
  estimator <- yardstick::finalize_estimator(truth, estimator, metric_class = "tss")
  yardstick::check_class_metric(truth, estimate, case_weights, estimator)
  if (na_rm) {
    res <- yardstick::yardstick_remove_missing(truth, estimate, case_weights)
    truth <- res$truth
    estimate <- res$estimate
    case_weights <- res$case_weights
  } else if (yardstick::yardstick_any_missing(truth, estimate, case_weights)) {
    return(NA_real_)
  }
  if (estimator == "binary") {
    lv <- levels(truth)
    event <- if (identical(event_level, "second")) lv[2] else lv[1]
    w <- if (is.null(case_weights)) rep(1, length(truth)) else as.numeric(case_weights)
    pos <- truth == event
    hit <- estimate == event
    sens <- sum(w[pos & hit]) / sum(w[pos])
    spec <- sum(w[!pos & !hit]) / sum(w[!pos])
    return(sens + spec - 1)
  }
  sens <- yardstick::sens_vec(truth, estimate, estimator = estimator,
    case_weights = case_weights, event_level = event_level
  )
  spec <- yardstick::spec_vec(truth, estimate, estimator = estimator,
    case_weights = case_weights, event_level = event_level
  )
  sens + spec - 1
}

#' Continuous Boyce Index
#'
#' The Continuous Boyce Index (CBI; Hirzel et al. 2006) evaluates
#' presence-background or presence-only predictions. Moving windows of width
#' `window_width` (as a fraction of the prediction range) are slid across
#' the predicted suitability. In each window the ratio of the proportion of
#' presences to the proportion of all evaluation points (presences and
#' background) is computed; the index is the Spearman correlation between
#' window centre and that ratio. Values near 1 mean presences become more
#' frequent than expected as suitability rises; values near 0 mean the model
#' is no better than random. Successive duplicate ratios are removed before
#' computing the correlation, as in the reference implementation.
#'
#' @inheritParams tss
#' @param truth The column of true classes: a two-level factor of presence
#'   and background.
#' @param ... The column of predicted suitability for the presence class
#'   (unquoted).
#' @param estimate A numeric vector of predicted suitability for the
#'   presence class.
#' @param estimator Only `"binary"` is supported.
#' @param window_width Width of each moving window as a fraction of the
#'   prediction range.
#' @param n_windows Number of window centres.
#'
#' @return For `boyce_index()`, a tibble with `.metric`, `.estimator` and
#'   `.estimate`. For `boyce_index_vec()`, a single number.
#' @references Hirzel, A. H., Le Lay, G., Helfer, V., Randin, C. and Guisan,
#'   A. (2006). Evaluating the ability of habitat suitability models to
#'   predict species presences. *Ecological Modelling*, 199, 142-152.
#'   \doi{10.1016/j.ecolmodel.2006.05.017}
#' @family invasion metrics
#' @export
#' @examples
#' set.seed(1)
#' suit <- runif(500)
#' truth <- factor(ifelse(runif(500) < suit^2, "presence", "background"),
#'   levels = c("presence", "background"))
#' boyce_index_vec(truth, suit)
#' boyce_index(data.frame(truth = truth, suit = suit), truth, suit)
boyce_index <- function(data, ...) {
  UseMethod("boyce_index")
}
boyce_index <- yardstick::new_prob_metric(boyce_index, direction = "maximize")

#' @rdname boyce_index
#' @export
boyce_index.data.frame <- function(data, truth, ..., estimator = NULL, na_rm = TRUE,
                                   case_weights = NULL, event_level = "first",
                                   window_width = 0.1, n_windows = 101) {
  yardstick::prob_metric_summarizer(
    name = "boyce_index", fn = boyce_index_vec, data = data,
    truth = !!rlang::enquo(truth), ..., estimator = estimator, na_rm = na_rm,
    case_weights = !!rlang::enquo(case_weights), event_level = event_level,
    fn_options = list(window_width = window_width, n_windows = n_windows)
  )
}

#' @rdname boyce_index
#' @export
boyce_index_vec <- function(truth, estimate, estimator = NULL, na_rm = TRUE,
                            case_weights = NULL, event_level = "first",
                            window_width = 0.1, n_windows = 101, ...) {
  estimator <- yardstick::finalize_estimator(truth, estimator, metric_class = "boyce_index")
  yardstick::check_prob_metric(truth, estimate, case_weights, estimator)
  if (estimator != "binary") {
    cli::cli_abort("{.fn boyce_index} only supports binary presence-background data.")
  }
  check_probability(window_width)
  check_integerish(n_windows, min = 3)
  if (na_rm) {
    res <- yardstick::yardstick_remove_missing(truth, estimate, case_weights)
    truth <- res$truth
    estimate <- res$estimate
    case_weights <- res$case_weights
  } else if (yardstick::yardstick_any_missing(truth, estimate, case_weights)) {
    return(NA_real_)
  }
  lv <- levels(truth)
  event <- if (identical(event_level, "second")) lv[2] else lv[1]
  w <- if (is.null(case_weights)) rep(1, length(truth)) else as.numeric(case_weights)
  boyce_core(as.numeric(estimate), truth == event, w, window_width, n_windows)
}

boyce_core <- function(pred, is_pres, w, window_width, n_windows) {
  if (!any(is_pres)) {
    return(NA_real_)
  }
  lo <- min(pred)
  hi <- max(pred)
  if (hi <= lo) {
    return(NA_real_)
  }
  width <- window_width * (hi - lo)
  starts <- seq(lo, hi - width, length.out = n_windows)
  w_pres <- w[is_pres]
  p_pres <- pred[is_pres]
  tot_pres <- sum(w_pres)
  tot_all <- sum(w)
  f <- vapply(starts, function(s) {
    in_all <- pred >= s & pred <= s + width
    in_pres <- p_pres >= s & p_pres <= s + width
    e <- sum(w[in_all]) / tot_all
    if (e == 0) NA_real_ else (sum(w_pres[in_pres]) / tot_pres) / e
  }, numeric(1))
  centres <- starts + width / 2
  keep <- !is.na(f)
  f <- f[keep]
  centres <- centres[keep]
  if (length(f) > 1) {
    dup <- c(FALSE, diff(f) == 0)
    f <- f[!dup]
    centres <- centres[!dup]
  }
  if (length(f) < 3 || stats::sd(f) == 0) {
    return(NA_real_)
  }
  stats::cor(centres, f, method = "spearman")
}
