# Custom recipes steps ----------------------------------------------------

#' Background (pseudo-absence) subsampling for presence-background data
#'
#' `step_inv_background()` creates a *specification* of a recipe step that
#' subsamples the background (or absence) rows of a presence-background data
#' set so that there are `ratio` background rows for every presence. With
#' `method = "stratified"` the background is first clustered by k-means on
#' the numeric predictors and sampled evenly across clusters, which spreads
#' the background across environmental space. Because it changes the number
#' of rows, the step is skipped when baking new data by default.
#'
#' @param recipe A recipe object.
#' @param ... One or more selector functions choosing the presence column:
#'   logical, 0/1 or a two-level factor.
#' @param role Not used by this step since no new variables are created.
#' @param trained A logical to indicate if the step has been trained.
#' @param ratio Number of background rows to keep per presence.
#' @param event Value of the presence column that marks presences. Defaults
#'   to `TRUE`, `1` or the first factor level.
#' @param method `"random"` or `"stratified"` (k-means on numeric
#'   predictors).
#' @param n_strata Number of k-means clusters for `method = "stratified"`.
#' @param column,predictors Set by [prep()]: the presence column and the
#'   numeric predictors used for stratification.
#' @param seed Integer seed for reproducible subsampling.
#' @param skip A logical. Should the step be skipped when the recipe is baked
#'   by [bake()]? Defaults to `TRUE` because the step removes rows.
#' @param id A character string that is unique to this step.
#' @param x A `step_inv_background` object.
#' @param training A data frame used to train the step.
#' @param info Variable information from the recipe.
#' @param object A trained step.
#' @param new_data A data frame to process.
#' @param width Print width.
#'
#' @return An updated recipe with the new step added. [tidy()] returns a
#'   tibble with columns `terms`, `ratio`, `method` and `id`.
#' @references Barbet-Massin, M., Jiguet, F., Albert, C. H. and Thuiller, W.
#'   (2012). Selecting pseudo-absences for species distribution models: how,
#'   where and how many? *Methods in Ecology and Evolution*, 3, 327-338.
#'   \doi{10.1111/j.2041-210X.2011.00172.x}
#' @export
#' @examples
#' library(recipes)
#' rec <- recipe(presence ~ temp + rain + forest, data = inv_sdm_data) |>
#'   step_inv_background(presence, ratio = 2, seed = 1)
#' prepped <- prep(rec)
#' table(bake(prepped, new_data = NULL)$presence)
#' tidy(prepped, number = 1)
step_inv_background <- function(recipe, ..., role = NA, trained = FALSE, ratio = 10,
                                event = NULL, method = c("random", "stratified"),
                                n_strata = 10, column = NULL, predictors = NULL,
                                seed = sample.int(10^5, 1), skip = TRUE,
                                id = recipes::rand_id("inv_background")) {
  method <- rlang::arg_match(method)
  check_number_positive(ratio)
  check_integerish(n_strata, min = 2)
  recipes::add_step(
    recipe,
    step_inv_background_new(
      terms = rlang::enquos(...), role = role, trained = trained, ratio = ratio,
      event = event, method = method, n_strata = n_strata, column = column,
      predictors = predictors, seed = seed, skip = skip, id = id
    )
  )
}

step_inv_background_new <- function(terms, role, trained, ratio, event, method, n_strata,
                                    column, predictors, seed, skip, id) {
  recipes::step(
    subclass = "inv_background", terms = terms, role = role, trained = trained,
    ratio = ratio, event = event, method = method, n_strata = n_strata,
    column = column, predictors = predictors, seed = seed, skip = skip, id = id
  )
}

#' @rdname step_inv_background
#' @export
prep.step_inv_background <- function(x, training, info = NULL, ...) {
  col <- recipes::recipes_eval_select(x$terms, training, info)
  if (length(col) != 1) {
    cli::cli_abort("{.fn step_inv_background} needs exactly one presence column, not {length(col)}.")
  }
  as_binary(training[[col]], col, event = x$event)
  preds <- info$variable[info$role %in% "predictor"]
  preds <- preds[vapply(training[preds], is.numeric, logical(1))]
  step_inv_background_new(
    terms = x$terms, role = x$role, trained = TRUE, ratio = x$ratio, event = x$event,
    method = x$method, n_strata = x$n_strata, column = unname(col),
    predictors = preds, seed = x$seed, skip = x$skip, id = x$id
  )
}

#' @rdname step_inv_background
#' @export
bake.step_inv_background <- function(object, new_data, ...) {
  col <- object$column
  if (!col %in% names(new_data)) {
    return(new_data)
  }
  pres <- as_binary(new_data[[col]], col, event = object$event)
  pres[is.na(pres)] <- FALSE
  bg <- which(!pres)
  n_keep <- min(length(bg), ceiling(object$ratio * sum(pres)))
  keep_bg <- withr::with_seed(object$seed, {
    if (object$method == "random" || length(object$predictors) == 0 ||
      length(bg) <= object$n_strata) {
      bg[sample.int(length(bg), n_keep)]
    } else {
      env <- scale(as.matrix(new_data[bg, object$predictors, drop = FALSE]))
      env[!is.finite(env)] <- 0
      cl <- stats::kmeans(env, centers = object$n_strata, nstart = 5)$cluster
      by_cl <- split(bg, cl)
      quota <- rep(floor(n_keep / length(by_cl)), length(by_cl))
      extra <- n_keep - sum(quota)
      if (extra > 0) quota[seq_len(extra)] <- quota[seq_len(extra)] + 1
      picked <- unlist(Map(function(ids, q) {
        if (length(ids) <= q) ids else ids[sample.int(length(ids), q)]
      }, by_cl, quota), use.names = FALSE)
      short <- n_keep - length(picked)
      if (short > 0) {
        rest <- setdiff(bg, picked)
        picked <- c(picked, rest[sample.int(length(rest), min(short, length(rest)))])
      }
      picked
    }
  })
  new_data[sort(c(which(pres), keep_bg)), , drop = FALSE]
}

#' @rdname step_inv_background
#' @export
print.step_inv_background <- function(x, width = max(20, options()$width - 30), ...) {
  title <- paste0("Background subsampling (", x$method, ", ratio ", x$ratio, ") on ")
  recipes::print_step(x$column, x$terms, x$trained, title, width)
  invisible(x)
}

#' @rdname step_inv_background
#' @export
tidy.step_inv_background <- function(x, ...) {
  terms <- if (recipes::is_trained(x)) x$column else recipes::sel2char(x$terms)
  tibble::tibble(terms = terms, ratio = x$ratio, method = x$method, id = x$id)
}

#' @rdname step_inv_background
#' @export
required_pkgs.step_inv_background <- function(x, ...) {
  c("tidyinvasion")
}

# Propagule pressure lags -------------------------------------------------

#' Lagged and cumulative propagule pressure features
#'
#' `step_inv_propagule_lags()` creates a *specification* of a recipe step
#' that adds, for each selected propagule pressure column, its values `lag`
#' time steps earlier within each group, the cumulative pressure before the
#' current time step and, optionally, an exponentially discounted cumulative
#' pressure `sum(x_s * exp(-decay * (t - s)))` over earlier times `s`. These
#' features capture the delayed effect of past introductions on
#' establishment and spread. Rows keep their original order.
#'
#' @inheritParams step_inv_background
#' @param ... One or more selector functions choosing numeric propagule
#'   pressure columns.
#' @param role Role of the new columns. Defaults to `"predictor"`.
#' @param time Name of the time column (bare or quoted).
#' @param group Optional name of a grouping column (for example region).
#' @param lag Positive whole numbers: lags (in rows within group, ordered by
#'   `time`) to create.
#' @param cumulative Add the cumulative pressure before each time step?
#' @param decay Optional non-negative decay rate per time unit.
#' @param prefix Prefix for lag column names.
#' @param columns Set by [prep()]: the selected column names.
#' @param x A `step_inv_propagule_lags` object.
#'
#' @return An updated recipe. New columns are named `{prefix}{lag}_{column}`,
#'   `cumpp_{column}` and `decaypp_{column}`; the first rows of each group
#'   have `NA` lags. [tidy()] returns `terms`, `lag` and `id`.
#' @export
#' @examples
#' library(recipes)
#' annual <- inv_introductions |>
#'   dplyr::count(region, year, wt = propagule_size, name = "propagules")
#' rec <- recipe(~., data = annual) |>
#'   step_inv_propagule_lags(propagules, time = year, group = region, lag = 1:2,
#'     decay = 0.2)
#' bake(prep(rec), new_data = NULL)
step_inv_propagule_lags <- function(recipe, ..., role = "predictor", trained = FALSE,
                                    time, group = NULL, lag = 1, cumulative = TRUE,
                                    decay = NULL, prefix = "lag", columns = NULL,
                                    skip = FALSE,
                                    id = recipes::rand_id("inv_propagule_lags")) {
  time <- as_col_name(rlang::enquo(time), "time")
  group <- as_col_name(rlang::enquo(group), "group")
  if (is.null(time)) {
    cli::cli_abort("{.arg time} must name the time column.")
  }
  if (!is.numeric(lag) || any(lag < 1) || any(lag != round(lag))) {
    cli::cli_abort("{.arg lag} must contain positive whole numbers.")
  }
  check_number_positive(decay, allow_zero = TRUE, allow_null = TRUE)
  recipes::add_step(
    recipe,
    step_inv_propagule_lags_new(
      terms = rlang::enquos(...), role = role, trained = trained, time = time,
      group = group, lag = sort(unique(as.integer(lag))), cumulative = cumulative,
      decay = decay, prefix = prefix, columns = columns, skip = skip, id = id
    )
  )
}

step_inv_propagule_lags_new <- function(terms, role, trained, time, group, lag, cumulative,
                                        decay, prefix, columns, skip, id) {
  recipes::step(
    subclass = "inv_propagule_lags", terms = terms, role = role, trained = trained,
    time = time, group = group, lag = lag, cumulative = cumulative, decay = decay,
    prefix = prefix, columns = columns, skip = skip, id = id
  )
}

#' @rdname step_inv_propagule_lags
#' @export
prep.step_inv_propagule_lags <- function(x, training, info = NULL, ...) {
  cols <- recipes::recipes_eval_select(x$terms, training, info)
  recipes::check_type(training[, cols], types = c("double", "integer"))
  missing_cols <- setdiff(c(x$time, x$group), names(training))
  if (length(missing_cols)) {
    cli::cli_abort("Column{?s} {.field {missing_cols}} not found in the training data.")
  }
  step_inv_propagule_lags_new(
    terms = x$terms, role = x$role, trained = TRUE, time = x$time, group = x$group,
    lag = x$lag, cumulative = x$cumulative, decay = x$decay, prefix = x$prefix,
    columns = unname(cols), skip = x$skip, id = x$id
  )
}

#' @rdname step_inv_propagule_lags
#' @export
bake.step_inv_propagule_lags <- function(object, new_data, ...) {
  recipes::check_new_data(c(object$columns, object$time, object$group), object, new_data)
  t <- as_time_numeric(new_data[[object$time]], object$time)
  g <- if (is.null(object$group)) rep("all", nrow(new_data)) else as.character(new_data[[object$group]])
  idx <- split(seq_len(nrow(new_data)), g)
  for (col in object$columns) {
    v <- new_data[[col]]
    lags <- matrix(NA_real_, nrow(new_data), length(object$lag))
    cum <- rep(NA_real_, nrow(new_data))
    dec <- rep(NA_real_, nrow(new_data))
    for (ids in idx) {
      ids <- ids[order(t[ids])]
      vv <- v[ids]
      tt <- t[ids]
      for (j in seq_along(object$lag)) {
        k <- object$lag[j]
        lags[ids, j] <- c(rep(NA_real_, min(k, length(vv))), utils::head(vv, -k))[seq_along(vv)]
      }
      vz <- ifelse(is.na(vv), 0, vv)
      cum[ids] <- cumsum(vz) - vz
      if (!is.null(object$decay)) {
        dec[ids] <- vapply(seq_along(vv), function(i) {
          prev <- tt < tt[i]
          sum(vz[prev] * exp(-object$decay * (tt[i] - tt[prev])))
        }, numeric(1))
      }
    }
    for (j in seq_along(object$lag)) {
      new_data[[paste0(object$prefix, object$lag[j], "_", col)]] <- lags[, j]
    }
    if (isTRUE(object$cumulative)) new_data[[paste0("cumpp_", col)]] <- cum
    if (!is.null(object$decay)) new_data[[paste0("decaypp_", col)]] <- dec
  }
  new_data
}

#' @rdname step_inv_propagule_lags
#' @export
print.step_inv_propagule_lags <- function(x, width = max(20, options()$width - 30), ...) {
  title <- paste0("Propagule pressure lags (", paste(x$lag, collapse = ", "), ") for ")
  recipes::print_step(x$columns, x$terms, x$trained, title, width)
  invisible(x)
}

#' @rdname step_inv_propagule_lags
#' @export
tidy.step_inv_propagule_lags <- function(x, ...) {
  terms <- if (recipes::is_trained(x)) x$columns else recipes::sel2char(x$terms)
  out <- tidyr_crossing(terms, x$lag)
  out$id <- rep(x$id, nrow(out))
  out
}

tidyr_crossing <- function(terms, lag) {
  g <- expand.grid(lag = lag, terms = terms, stringsAsFactors = FALSE)
  tibble::tibble(terms = g$terms, lag = g$lag)
}

#' @rdname step_inv_propagule_lags
#' @export
required_pkgs.step_inv_propagule_lags <- function(x, ...) {
  c("tidyinvasion")
}

# Environmental distance and novelty --------------------------------------

mess_score <- function(p, ref_sorted, mn, mx) {
  n <- length(ref_sorted)
  f <- 100 * findInterval(p, ref_sorted, left.open = TRUE) / n
  rng <- mx - mn
  rng <- if (rng > 0) rng else 1
  ifelse(f == 0, 100 * (p - mn) / rng,
    ifelse(f <= 50, 2 * f,
      ifelse(f < 100, 2 * (100 - f), 100 * (mx - p) / rng)
    )
  )
}

#' Environmental distance and novelty relative to reference conditions
#'
#' `step_inv_env_distance()` creates a *specification* of a recipe step that
#' measures how far each row lies from the reference environment learned
#' from the training data (all rows, or only presences when `presence` is
#' given). Two measures are available:
#'
#' * Mahalanobis distance from the centroid of the reference environment,
#'   using its covariance matrix (a pseudo-inverse is used when it is
#'   singular).
#' * The multivariate environmental similarity surface (MESS; Elith et al.
#'   2010). Negative values flag novel conditions outside the reference
#'   range, where predictions from transferred models are extrapolations. The
#'   most dissimilar variable (MoD) is also returned.
#'
#' @inheritParams step_inv_background
#' @param ... One or more selector functions choosing numeric environmental
#'   predictors.
#' @param role Role of the new columns. Defaults to `"predictor"`.
#' @param presence Optional name of the presence column. When given, only
#'   rows with `presence == event` form the reference.
#' @param event Value of `presence` that marks presences.
#' @param method `"both"`, `"mahalanobis"` or `"mess"`.
#' @param prefix Prefix for the new columns.
#' @param columns,reference Set by [prep()]: the selected columns and the
#'   reference statistics.
#' @param x A `step_inv_env_distance` object.
#'
#' @return An updated recipe. Baking adds `{prefix}mahalanobis` and/or
#'   `{prefix}mess` and `{prefix}mod`. [tidy()] returns `terms`, `mean` and
#'   `sd` of the reference for each variable, and `id`.
#' @references Elith, J., Kearney, M. and Phillips, S. (2010). The art of
#'   modelling range-shifting species. *Methods in Ecology and Evolution*, 1,
#'   330-342. \doi{10.1111/j.2041-210X.2010.00036.x}
#' @export
#' @examples
#' library(recipes)
#' rec <- recipe(presence ~ temp + rain + forest, data = inv_sdm_data) |>
#'   step_inv_env_distance(temp, rain, forest, presence = presence)
#' baked <- bake(prep(rec), new_data = NULL)
#' summary(baked$env_mess)
step_inv_env_distance <- function(recipe, ..., role = "predictor", trained = FALSE,
                                  presence = NULL, event = NULL,
                                  method = c("both", "mahalanobis", "mess"),
                                  prefix = "env_", columns = NULL, reference = NULL,
                                  skip = FALSE, id = recipes::rand_id("inv_env_distance")) {
  method <- rlang::arg_match(method)
  presence <- as_col_name(rlang::enquo(presence), "presence")
  recipes::add_step(
    recipe,
    step_inv_env_distance_new(
      terms = rlang::enquos(...), role = role, trained = trained, presence = presence,
      event = event, method = method, prefix = prefix, columns = columns,
      reference = reference, skip = skip, id = id
    )
  )
}

step_inv_env_distance_new <- function(terms, role, trained, presence, event, method, prefix,
                                      columns, reference, skip, id) {
  recipes::step(
    subclass = "inv_env_distance", terms = terms, role = role, trained = trained,
    presence = presence, event = event, method = method, prefix = prefix,
    columns = columns, reference = reference, skip = skip, id = id
  )
}

#' @rdname step_inv_env_distance
#' @export
prep.step_inv_env_distance <- function(x, training, info = NULL, ...) {
  cols <- recipes::recipes_eval_select(x$terms, training, info)
  recipes::check_type(training[, cols], types = c("double", "integer"))
  ref <- as.matrix(training[, cols, drop = FALSE])
  if (!is.null(x$presence)) {
    if (!x$presence %in% names(training)) {
      cli::cli_abort("Presence column {.field {x$presence}} not found in the training data.")
    }
    pres <- as_binary(training[[x$presence]], x$presence, event = x$event)
    ref <- ref[!is.na(pres) & pres, , drop = FALSE]
  }
  ref <- ref[stats::complete.cases(ref), , drop = FALSE]
  if (nrow(ref) < 2) {
    cli::cli_abort("At least two complete reference rows are needed.")
  }
  reference <- list(
    mean = colMeans(ref),
    sd = apply(ref, 2, stats::sd),
    inv_cov = pinv(stats::cov(ref)),
    min = apply(ref, 2, min),
    max = apply(ref, 2, max),
    sorted = lapply(seq_len(ncol(ref)), function(j) sort(ref[, j]))
  )
  step_inv_env_distance_new(
    terms = x$terms, role = x$role, trained = TRUE, presence = x$presence,
    event = x$event, method = x$method, prefix = x$prefix, columns = unname(cols),
    reference = reference, skip = x$skip, id = x$id
  )
}

#' @rdname step_inv_env_distance
#' @export
bake.step_inv_env_distance <- function(object, new_data, ...) {
  recipes::check_new_data(object$columns, object, new_data)
  m <- as.matrix(new_data[, object$columns, drop = FALSE])
  ref <- object$reference
  if (object$method %in% c("both", "mahalanobis")) {
    centred <- sweep(m, 2, ref$mean)
    d2 <- rowSums((centred %*% ref$inv_cov) * centred)
    new_data[[paste0(object$prefix, "mahalanobis")]] <- sqrt(pmax(d2, 0))
  }
  if (object$method %in% c("both", "mess")) {
    s <- vapply(seq_along(object$columns), function(j) {
      mess_score(m[, j], ref$sorted[[j]], ref$min[j], ref$max[j])
    }, numeric(nrow(m)))
    s <- matrix(s, nrow = nrow(m))
    mess <- apply(s, 1, function(r) if (anyNA(r)) NA_real_ else min(r))
    mod <- apply(s, 1, function(r) if (anyNA(r)) NA_character_ else object$columns[which.min(r)])
    new_data[[paste0(object$prefix, "mess")]] <- mess
    new_data[[paste0(object$prefix, "mod")]] <- factor(mod, levels = object$columns)
  }
  new_data
}

#' @rdname step_inv_env_distance
#' @export
print.step_inv_env_distance <- function(x, width = max(20, options()$width - 30), ...) {
  title <- paste0("Environmental distance (", x$method, ") from ")
  recipes::print_step(x$columns, x$terms, x$trained, title, width)
  invisible(x)
}

#' @rdname step_inv_env_distance
#' @export
tidy.step_inv_env_distance <- function(x, ...) {
  if (recipes::is_trained(x)) {
    tibble::tibble(
      terms = x$columns, mean = unname(x$reference$mean), sd = unname(x$reference$sd),
      id = x$id
    )
  } else {
    terms <- recipes::sel2char(x$terms)
    tibble::tibble(terms = terms, mean = NA_real_, sd = NA_real_, id = x$id)
  }
}

#' @rdname step_inv_env_distance
#' @export
required_pkgs.step_inv_env_distance <- function(x, ...) {
  c("tidyinvasion")
}
