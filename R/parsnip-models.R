# parsnip model specifications --------------------------------------------

#' Species distribution model specification
#'
#' `inv_sdm()` defines a presence-background (or presence-absence) species
#' distribution model for use with the tidymodels framework. Predictors are
#' standardised and expanded into polynomial terms of degree `degree`
#' (degree 2 gives the classic quadratic response curves). Two engines are
#' available:
#'
#' * `"glm"`: logistic regression (binomial GLM) of presence against
#'   background or absence. Probabilities are probabilities of presence
#'   under the sampling design.
#' * `"iwlr"`: infinitely weighted logistic regression (Fithian and Hastie
#'   2013). Background rows get a large weight (`bg_weight`, an engine
#'   argument, default 100), so slope estimates converge on those of an
#'   inhomogeneous Poisson process, the model underlying Maxent. Predictions
#'   are the relative intensity mapped to 0 to 1 with a complementary
#'   log-log link: a relative suitability index, not a probability of
#'   presence.
#'
#' The outcome must be a two-level factor whose **first level** is the
#' presence, following the yardstick convention. Class predictions use the
#' threshold that maximises the True Skill Statistic on the training data
#' (Liu et al. 2005), which suits the low prevalence of presence-background
#' data far better than 0.5. Set the engine argument `threshold` to a number
#' to override it, for example `set_engine("glm", threshold = 0.3)`.
#'
#' @param mode Must be `"classification"`.
#' @param engine `"glm"` or `"iwlr"`.
#' @param degree Polynomial degree of each predictor (1 or 2, or higher).
#'
#' @return A model specification of class `inv_sdm`.
#' @references Fithian, W. and Hastie, T. (2013). Finite-sample equivalence
#'   in statistical models for presence-only data. *Annals of Applied
#'   Statistics*, 7, 1917-1939. \doi{10.1214/13-AOAS667}
#'
#'   Liu, C., Berry, P. M., Dawson, T. P. and Pearson, R. G. (2005).
#'   Selecting thresholds of occurrence in the prediction of species
#'   distributions. *Ecography*, 28, 385-393.
#'   \doi{10.1111/j.0906-7590.2005.03957.x}
#' @export
#' @examples
#' spec <- inv_sdm(degree = 2) |> parsnip::set_engine("glm")
#' fit <- parsnip::fit(spec, presence ~ temp + rain + forest, data = inv_sdm_data)
#' predict(fit, inv_sdm_data[1:5, ], type = "prob")
#'
#' iw <- inv_sdm() |> parsnip::set_engine("iwlr", bg_weight = 100)
#' parsnip::fit(iw, presence ~ temp + rain, data = inv_sdm_data)
inv_sdm <- function(mode = "classification", engine = "glm", degree = NULL) {
  if (mode != "classification") {
    cli::cli_abort("{.fn inv_sdm} only supports {.val classification} mode.")
  }
  args <- list(degree = rlang::enquo(degree))
  parsnip::new_model_spec(
    "inv_sdm", args = args, eng_args = NULL, mode = mode, user_specified_mode = !missing(mode),
    method = NULL, engine = engine, user_specified_engine = !missing(engine)
  )
}

#' @export
print.inv_sdm <- function(x, ...) {
  cat("Species distribution model specification (", x$mode, ")\n\n", sep = "")
  parsnip::model_printer(x, ...)
  if (!is.null(x$method$fit$args)) {
    cat("Model fit template:\n")
    print(parsnip::show_call(x))
  }
  invisible(x)
}

#' @export
update.inv_sdm <- function(object, parameters = NULL, degree = NULL, fresh = FALSE, ...) {
  args <- list(degree = rlang::enquo(degree))
  parsnip::update_spec(
    object = object, parameters = parameters, args_enquo_list = args, fresh = fresh,
    cls = "inv_sdm", ...
  )
}

sdm_features <- function(x, center, scale, degree) {
  z <- sweep(sweep(x, 2, center), 2, scale, "/")
  feats <- lapply(seq_len(degree), function(d) {
    m <- z^d
    colnames(m) <- if (d == 1) colnames(z) else paste0(colnames(z), "_pow", d)
    m
  })
  do.call(cbind, feats)
}

#' Fit engine for `inv_sdm()`
#'
#' The fitting function called by parsnip for [inv_sdm()]. It is exported
#' so that parsnip can call it; use [inv_sdm()] instead.
#'
#' @param x A data frame or matrix of numeric predictors.
#' @param y A two-level factor; the first level is the presence.
#' @param degree Polynomial degree.
#' @param method `"glm"` or `"iwlr"`.
#' @param bg_weight Weight of background rows for `method = "iwlr"`.
#' @param threshold Suitability threshold for class predictions:
#'   `"max_tss"` (the default) chooses the threshold that maximises the True
#'   Skill Statistic on the training data; a number in (0, 1) is used as is.
#' @param weights Optional case weights.
#' @return An object of class `inv_sdm_fit`.
#' @keywords internal
#' @export
#' @examples
#' fit <- inv_sdm_fit(inv_sdm_data[c("temp", "rain", "forest")], inv_sdm_data$presence)
#' fit
#' tidy(fit)
inv_sdm_fit <- function(x, y, degree = 2, method = c("glm", "iwlr"), bg_weight = 100,
                        threshold = "max_tss", weights = NULL) {
  method <- rlang::arg_match(method)
  x <- as.data.frame(x)
  num <- vapply(x, is.numeric, logical(1))
  if (!all(num)) {
    cli::cli_abort("All predictors must be numeric; {.field {names(x)[!num]}} {?is/are} not.")
  }
  if (!is.factor(y) || nlevels(y) != 2) {
    cli::cli_abort("The outcome must be a two-level factor with the presence level first.")
  }
  degree <- as.integer(degree %||% 2)
  check_integerish(degree)
  x <- as.matrix(x)
  center <- colMeans(x, na.rm = TRUE)
  scl <- apply(x, 2, stats::sd, na.rm = TRUE)
  scl[!is.finite(scl) | scl == 0] <- 1
  feats <- sdm_features(x, center, scl, degree)
  pres <- as.numeric(y == levels(y)[1])
  w <- if (is.null(weights)) rep(1, length(pres)) else as.numeric(weights)
  if (method == "iwlr") {
    check_number_positive(bg_weight)
    w <- w * ifelse(pres == 1, 1, bg_weight)
  }
  df <- data.frame(.pres = pres, feats, check.names = FALSE)
  fit <- suppressWarnings(stats::glm(.pres ~ ., data = df, family = stats::binomial(),
    weights = w
  ))
  out <- structure(
    list(
      fit = fit, levels = levels(y), center = center, scale = scl, degree = degree,
      method = method, bg_weight = if (method == "iwlr") bg_weight else NULL,
      predictors = colnames(x), threshold = 0.5
    ),
    class = "inv_sdm_fit"
  )
  if (identical(threshold, "max_tss")) {
    p <- stats::predict(out, as.data.frame(x), type = "prob")
    out$threshold <- max_tss_threshold(p, pres == 1)
  } else {
    check_probability(threshold)
    out$threshold <- threshold
  }
  out
}

# Threshold maximising sensitivity + specificity - 1 (Liu et al. 2005).
max_tss_threshold <- function(p, is_pres) {
  ok <- !is.na(p) & !is.na(is_pres)
  p <- p[ok]
  is_pres <- is_pres[ok]
  if (!any(is_pres) || all(is_pres)) {
    return(0.5)
  }
  cand <- unique(stats::quantile(p, probs = seq(0, 1, length.out = 201), names = FALSE))
  tss <- vapply(cand, function(th) {
    hit <- p >= th
    mean(hit[is_pres]) + mean(!hit[!is_pres]) - 1
  }, numeric(1))
  cand[which.max(tss)]
}

#' @export
print.inv_sdm_fit <- function(x, ...) {
  cat_line("{.cls inv_sdm_fit} {x$method} species distribution model, degree {x$degree}")
  cat_line("Predictors: {.field {x$predictors}}")
  cat_line("Class threshold: {signif(x$threshold, 3)}")
  invisible(x)
}

#' Predict from a fitted species distribution model
#'
#' @param object An `inv_sdm_fit` object.
#' @param new_data A data frame with the predictor columns.
#' @param type `"prob"` (suitability of the presence class), `"class"` or
#'   `"link"` (linear predictor).
#' @param threshold Suitability threshold for `type = "class"`. Defaults to
#'   the threshold stored in the fit (see [inv_sdm_fit()]).
#' @param ... Not used.
#' @return A numeric vector, or a factor for `type = "class"`.
#' @export
#' @examples
#' fit <- inv_sdm_fit(inv_sdm_data[c("temp", "rain")], inv_sdm_data$presence)
#' head(predict(fit, inv_sdm_data, type = "prob"))
predict.inv_sdm_fit <- function(object, new_data, type = c("prob", "class", "link"),
                                threshold = NULL, ...) {
  type <- rlang::arg_match(type)
  missing_cols <- setdiff(object$predictors, names(new_data))
  if (length(missing_cols)) {
    cli::cli_abort("{.arg new_data} is missing predictor{?s} {.field {missing_cols}}.")
  }
  x <- as.matrix(as.data.frame(new_data)[object$predictors])
  feats <- as.data.frame(sdm_features(x, object$center, object$scale, object$degree),
    check.names = FALSE
  )
  eta <- stats::predict(object$fit, newdata = feats, type = "link")
  eta <- unname(eta)
  if (type == "link") {
    return(eta)
  }
  p <- if (object$method == "iwlr") {
    1 - exp(-exp(eta + log(object$bg_weight)))
  } else {
    stats::plogis(eta)
  }
  if (type == "prob") {
    return(p)
  }
  threshold <- threshold %||% object$threshold %||% 0.5
  factor(ifelse(p >= threshold, object$levels[1], object$levels[2]), levels = object$levels)
}

# Reaction-diffusion spread -------------------------------------------------

#' Reaction-diffusion spread model specification
#'
#' `inv_reaction_diffusion()` defines Skellam's (1951) model of an invasion
#' spreading from a point release by diffusion (coefficient `D`) and
#' exponential growth (rate `r`). Density at distance `x` and time `t` is
#' `N0 / (4 * pi * D * t) * exp(r * t - x^2 / (4 * D * t))`, so the radius at
#' which density falls to the detection threshold `c` is
#'
#' `R(t) = sqrt(4 * D * t * (r * t + log(K) - log(4 * pi * D * t)))`,
#'
#' where `K = N0 / c`. `D`, `r` and `K` are estimated by least squares from
#' observed range radii, and the radius tends to the Fisher-Skellam
#' asymptotic speed `2 * sqrt(r * D)`. The single predictor must be the time
#' since introduction (positive) and the outcome the range radius, for
#' example the output of [inv_spread_rate()].
#'
#' @param mode Must be `"regression"`.
#' @param engine Only `"skellam"`.
#' @param growth_rate Optional fixed intrinsic growth rate `r`. Estimated
#'   when `NULL`.
#' @param diffusion Optional fixed diffusion coefficient `D`. Estimated when
#'   `NULL`.
#'
#' @return A model specification of class `inv_reaction_diffusion`.
#' @references Skellam, J. G. (1951). Random dispersal in theoretical
#'   populations. *Biometrika*, 38, 196-218. \doi{10.1093/biomet/38.1-2.196}
#' @export
#' @examples
#' radius <- data.frame(years = 1:30)
#' radius$radius_km <- sqrt(4 * 50 * radius$years *
#'   (0.5 * radius$years + log(1e4) - log(4 * pi * 50 * radius$years)))
#' spec <- inv_reaction_diffusion() |> parsnip::set_engine("skellam")
#' fit <- parsnip::fit(spec, radius_km ~ years, data = radius)
#' fit
#' predict(fit, data.frame(years = c(40, 50)))
inv_reaction_diffusion <- function(mode = "regression", engine = "skellam",
                                   growth_rate = NULL, diffusion = NULL) {
  if (mode != "regression") {
    cli::cli_abort("{.fn inv_reaction_diffusion} only supports {.val regression} mode.")
  }
  args <- list(growth_rate = rlang::enquo(growth_rate), diffusion = rlang::enquo(diffusion))
  parsnip::new_model_spec(
    "inv_reaction_diffusion", args = args, eng_args = NULL, mode = mode,
    user_specified_mode = !missing(mode), method = NULL, engine = engine,
    user_specified_engine = !missing(engine)
  )
}

#' @export
print.inv_reaction_diffusion <- function(x, ...) {
  cat("Reaction-diffusion spread model specification (", x$mode, ")\n\n", sep = "")
  parsnip::model_printer(x, ...)
  invisible(x)
}

#' @export
update.inv_reaction_diffusion <- function(object, parameters = NULL, growth_rate = NULL,
                                          diffusion = NULL, fresh = FALSE, ...) {
  args <- list(growth_rate = rlang::enquo(growth_rate), diffusion = rlang::enquo(diffusion))
  parsnip::update_spec(
    object = object, parameters = parameters, args_enquo_list = args, fresh = fresh,
    cls = "inv_reaction_diffusion", ...
  )
}

skellam_radius <- function(t, D, r, log_k) {
  inner <- r * t + log_k - log(4 * pi * D * t)
  sqrt(pmax(0, 4 * D * t * inner))
}

#' Fit engine for `inv_reaction_diffusion()`
#'
#' The fitting function called by parsnip for [inv_reaction_diffusion()].
#' Use [inv_reaction_diffusion()] instead.
#'
#' @param x A data frame or matrix with one numeric column: time since
#'   introduction (positive).
#' @param y Numeric vector of range radii.
#' @param growth_rate,diffusion Optional fixed values.
#' @return An object of class `inv_rd_fit`.
#' @keywords internal
#' @export
#' @examples
#' t <- 1:25
#' radius <- sqrt(4 * 40 * t * (0.4 * t + log(5000) - log(4 * pi * 40 * t)))
#' fit <- inv_rd_fit(data.frame(t = t), radius)
#' fit
#' glance(fit)
inv_rd_fit <- function(x, y, growth_rate = NULL, diffusion = NULL) {
  x <- as.data.frame(x)
  if (ncol(x) != 1 || !is.numeric(x[[1]])) {
    cli::cli_abort("The reaction-diffusion model needs exactly one numeric predictor (time).")
  }
  t <- x[[1]]
  ok <- !is.na(t) & !is.na(y)
  t <- t[ok]
  y <- y[ok]
  if (any(t <= 0)) {
    cli::cli_abort("Time since introduction must be positive.")
  }
  if (length(t) < 4) {
    cli::cli_abort("At least four time points are needed.")
  }
  check_number_positive(growth_rate, allow_null = TRUE)
  check_number_positive(diffusion, allow_null = TRUE)
  slope <- max(stats::coef(stats::lm(y ~ t))[2], 1e-6)
  unpack <- function(theta) {
    i <- 1
    D <- diffusion %||% exp(theta[i])
    if (is.null(diffusion)) i <- i + 1
    r <- growth_rate %||% exp(theta[i])
    if (is.null(growth_rate)) i <- i + 1
    c(D = D, r = r, log_k = theta[i])
  }
  sse <- function(theta) {
    p <- unpack(theta)
    sum((y - skellam_radius(t, p[["D"]], p[["r"]], p[["log_k"]]))^2)
  }
  best <- NULL
  for (r0 in c(0.1, 0.5, 2)) {
    D0 <- diffusion %||% (slope^2 / (4 * (growth_rate %||% r0)))
    start <- c(
      if (is.null(diffusion)) log(D0),
      if (is.null(growth_rate)) log(r0),
      log(4 * pi * D0 * stats::median(t)) + 1
    )
    opt <- tryCatch(
      stats::optim(start, sse, method = if (length(start) > 1) "Nelder-Mead" else "BFGS",
        control = list(maxit = 10000, reltol = 1e-12)
      ),
      error = function(e) NULL
    )
    if (!is.null(opt) && length(start) > 1) {
      opt <- tryCatch(stats::optim(opt$par, sse, method = "BFGS",
        control = list(maxit = 2000, reltol = 1e-14)), error = function(e) opt)
    }
    if (!is.null(opt) && (is.null(best) || opt$value < best$value)) best <- opt
  }
  if (is.null(best)) {
    cli::cli_abort("The reaction-diffusion model could not be fitted.")
  }
  p <- unpack(best$par)
  structure(
    list(
      diffusion = p[["D"]], growth_rate = p[["r"]], log_k = p[["log_k"]],
      speed = 2 * sqrt(p[["D"]] * p[["r"]]),
      sigma = sqrt(best$value / max(1, length(y) - length(best$par))),
      sse = best$value, n = length(y), time = names(x)[1],
      fixed = c(growth_rate = !is.null(growth_rate), diffusion = !is.null(diffusion)),
      convergence = best$convergence
    ),
    class = "inv_rd_fit"
  )
}

#' @export
print.inv_rd_fit <- function(x, ...) {
  cat_line("{.cls inv_rd_fit} Skellam reaction-diffusion model")
  cat_line(paste(
    "Diffusion D = {signif(x$diffusion, 4)}, growth rate r = {signif(x$growth_rate, 4)},",
    "log K = {signif(x$log_k, 4)}"
  ))
  cat_line("Asymptotic speed 2 * sqrt(r * D) = {signif(x$speed, 4)} distance units per time unit")
  invisible(x)
}

#' Predict range radius from a reaction-diffusion fit
#'
#' @param object An `inv_rd_fit` object.
#' @param new_data A data frame whose time column has the same name as in
#'   the fit (or a single numeric column).
#' @param ... Not used.
#' @return A numeric vector of predicted radii.
#' @export
#' @examples
#' fit <- inv_rd_fit(data.frame(t = 1:20), 30 * (1:20) + 5)
#' predict(fit, data.frame(t = 25))
predict.inv_rd_fit <- function(object, new_data, ...) {
  new_data <- as.data.frame(new_data)
  t <- if (object$time %in% names(new_data)) new_data[[object$time]] else new_data[[1]]
  skellam_radius(t, object$diffusion, object$growth_rate, object$log_k)
}

# Registration with parsnip -------------------------------------------------

make_inv_sdm <- function() {
  parsnip::set_new_model("inv_sdm")
  parsnip::set_model_mode("inv_sdm", "classification")
  for (eng in c("glm", "iwlr")) {
    parsnip::set_model_engine("inv_sdm", "classification", eng)
    parsnip::set_dependency("inv_sdm", eng, "tidyinvasion", mode = "classification")
    parsnip::set_model_arg(
      model = "inv_sdm", eng = eng, parsnip = "degree", original = "degree",
      func = list(pkg = "dials", fun = "degree_int"), has_submodel = FALSE
    )
    parsnip::set_fit(
      model = "inv_sdm", eng = eng, mode = "classification",
      value = list(
        interface = "data.frame", protect = c("x", "y", "weights"),
        func = c(pkg = "tidyinvasion", fun = "inv_sdm_fit"),
        defaults = list(method = eng)
      )
    )
    parsnip::set_encoding(
      model = "inv_sdm", eng = eng, mode = "classification",
      options = list(
        predictor_indicators = "traditional", compute_intercept = FALSE,
        remove_intercept = TRUE, allow_sparse_x = FALSE
      )
    )
    parsnip::set_pred(
      model = "inv_sdm", eng = eng, mode = "classification", type = "class",
      value = list(
        pre = NULL, post = NULL, func = c(fun = "predict"),
        args = list(object = quote(object$fit), new_data = quote(new_data),
          type = "class")
      )
    )
    parsnip::set_pred(
      model = "inv_sdm", eng = eng, mode = "classification", type = "prob",
      value = list(
        pre = NULL,
        post = function(result, object) {
          out <- tibble::tibble(result, 1 - result)
          names(out) <- object$lvl
          out
        },
        func = c(fun = "predict"),
        args = list(object = quote(object$fit), new_data = quote(new_data),
          type = "prob")
      )
    )
  }
}

make_inv_reaction_diffusion <- function() {
  parsnip::set_new_model("inv_reaction_diffusion")
  parsnip::set_model_mode("inv_reaction_diffusion", "regression")
  parsnip::set_model_engine("inv_reaction_diffusion", "regression", "skellam")
  parsnip::set_dependency("inv_reaction_diffusion", "skellam", "tidyinvasion",
    mode = "regression"
  )
  parsnip::set_model_arg(
    model = "inv_reaction_diffusion", eng = "skellam", parsnip = "growth_rate",
    original = "growth_rate", func = list(pkg = "tidyinvasion", fun = "spread_growth_rate"),
    has_submodel = FALSE
  )
  parsnip::set_model_arg(
    model = "inv_reaction_diffusion", eng = "skellam", parsnip = "diffusion",
    original = "diffusion", func = list(pkg = "tidyinvasion", fun = "spread_diffusion"),
    has_submodel = FALSE
  )
  parsnip::set_fit(
    model = "inv_reaction_diffusion", eng = "skellam", mode = "regression",
    value = list(
      interface = "data.frame", protect = c("x", "y"),
      func = c(pkg = "tidyinvasion", fun = "inv_rd_fit"), defaults = list()
    )
  )
  parsnip::set_encoding(
    model = "inv_reaction_diffusion", eng = "skellam", mode = "regression",
    options = list(
      predictor_indicators = "none", compute_intercept = FALSE,
      remove_intercept = FALSE, allow_sparse_x = FALSE
    )
  )
  parsnip::set_pred(
    model = "inv_reaction_diffusion", eng = "skellam", mode = "regression", type = "numeric",
    value = list(
      pre = NULL, post = NULL, func = c(fun = "predict"),
      args = list(object = quote(object$fit), new_data = quote(new_data))
    )
  )
}

#' Tuning parameters for reaction-diffusion spread
#'
#' dials parameter objects for the `growth_rate` and `diffusion` arguments
#' of [inv_reaction_diffusion()]. They need the dials package.
#'
#' @param range Two numbers: the parameter range on the log10 scale.
#' @param trans A transformation object from the scales package. The default
#'   is log10.
#' @return A dials `quant_param` object.
#' @export
#' @examplesIf requireNamespace("dials", quietly = TRUE)
#' spread_growth_rate()
#' spread_diffusion()
spread_growth_rate <- function(range = c(-3, 1), trans = NULL) {
  rlang::check_installed("dials")
  dials::new_quant_param(
    type = "double", range = range, inclusive = c(TRUE, TRUE),
    trans = trans %||% scales_log10(), label = c(growth_rate = "Intrinsic growth rate")
  )
}

#' @rdname spread_growth_rate
#' @export
spread_diffusion <- function(range = c(-2, 4), trans = NULL) {
  rlang::check_installed("dials")
  dials::new_quant_param(
    type = "double", range = range, inclusive = c(TRUE, TRUE),
    trans = trans %||% scales_log10(), label = c(diffusion = "Diffusion coefficient")
  )
}

scales_log10 <- function() {
  ns <- asNamespace("scales")
  if (exists("transform_log10", ns)) ns$transform_log10() else ns$log10_trans()
}
