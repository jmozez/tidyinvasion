# ggplot2 autoplot methods ------------------------------------------------

#' Plot tidyinvasion objects
#'
#' `autoplot()` methods draw the standard figure for each kind of result:
#'
#' * `<inv_occurrence>`: a range map of records coloured by time.
#' * `<inv_spread>`: range radius (or cell distance) against time with the
#'   fitted spread rate.
#' * `inv_kernel`: dispersal distances with fitted kernels, either as
#'   densities or as a log-log survival plot that shows the tail.
#' * `inv_lag`: the cumulative invasion curve with the single and two-phase
#'   fits and the end of the lag phase.
#' * `inv_establishment`: the establishment dose-response curve.
#' * `inv_spatial_block_cv`: a map of records coloured by fold.
#'
#' Maps here are quick views in plain longitude and latitude. For
#' publication maps with basemaps and projections, pass results to the
#' companion package tidymapr.
#'
#' @param object An object to plot.
#' @param type For kernels: `"density"` or `"tail"`.
#' @param log_y For lag phases: use a log scale for the cumulative count?
#' @param ... Not used.
#' @return A `ggplot` object.
#' @name inv_autoplot
#' @examples
#' occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
#' autoplot(occ)
#'
#' spread <- inv_spread_rate(occ, origin = c(145.79, -17.10), quantile = 0.95)
#' autoplot(spread)
#'
#' k <- inv_dispersal_kernel(dplyr::filter(inv_dispersal, species == "sp_a"),
#'   distance_m)
#' autoplot(k, type = "tail")
#'
#' autoplot(inv_lag_phase(cane_toad, time = year))
NULL

#' @rdname inv_autoplot
#' @export
autoplot.inv_occurrence <- function(object, ...) {
  meta <- inv_meta(object)
  df <- as_plain_tibble(object)
  df$.x <- df[[meta$lon]]
  df$.y <- df[[meta$lat]]
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$.x, y = .data$.y))
  if (!is.null(meta$time)) {
    df$.time <- as_time_numeric(df[[meta$time]], meta$time)
    df <- df[order(df$.time), ]
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$.x, y = .data$.y, colour = .data$.time)) +
      ggplot2::geom_point(size = 1, alpha = 0.8) +
      ggplot2::scale_colour_viridis_c(name = meta$time)
  } else {
    p <- p + ggplot2::geom_point(size = 1, alpha = 0.8)
  }
  p <- p + ggplot2::labs(
    x = if (isTRUE(meta$geographic)) "Longitude" else meta$lon,
    y = if (isTRUE(meta$geographic)) "Latitude" else meta$lat
  ) + ggplot2::theme_minimal()
  if (isTRUE(meta$geographic)) p + ggplot2::coord_quickmap() else p + ggplot2::coord_equal()
}

#' @rdname inv_autoplot
#' @export
autoplot.inv_spread <- function(object, ...) {
  meta <- inv_meta(object)
  df <- augment(object)
  rate <- signif(stats::coef(meta$fit)[[2]], 3)
  ylab <- switch(meta$method,
    front = "Range radius (km)",
    area = "Equivalent radius sqrt(area / pi) (km)",
    first_record = "Distance of newly invaded cell (km)"
  )
  ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$distance_km)) +
    ggplot2::geom_point(alpha = 0.7) +
    ggplot2::geom_line(ggplot2::aes(y = .data$.fitted), colour = "#C0392B", linewidth = 1) +
    ggplot2::labs(x = "Time", y = ylab,
      subtitle = paste0("Spread rate ", rate, " km per time unit (", meta$method, ")")
    ) +
    ggplot2::theme_minimal()
}

#' @rdname inv_autoplot
#' @export
autoplot.inv_kernel <- function(object, type = c("density", "tail"), ...) {
  type <- rlang::arg_match(type)
  r <- object$distance
  grid <- if (type == "tail") {
    exp(seq(log(min(r)), log(max(r)), length.out = 200))
  } else {
    seq(min(r), max(r), length.out = 200)
  }
  curves <- dplyr::bind_rows(lapply(names(object$fits), function(f) augment(object, grid, family = f)))
  if (type == "density") {
    ggplot2::ggplot() +
      ggplot2::geom_histogram(
        data = tibble::tibble(distance = r),
        ggplot2::aes(x = .data$distance, y = ggplot2::after_stat(density)),
        bins = 30, fill = "grey80", colour = "white"
      ) +
      ggplot2::geom_line(data = curves,
        ggplot2::aes(x = .data$distance, y = .data$.density, colour = .data$family),
        linewidth = 0.9
      ) +
      ggplot2::labs(x = "Dispersal distance", y = "Density", colour = "Kernel") +
      ggplot2::theme_minimal()
  } else {
    emp <- tibble::tibble(distance = sort(r), survival = 1 - (seq_along(r) - 0.5) / length(r))
    ggplot2::ggplot() +
      ggplot2::geom_point(data = emp, ggplot2::aes(x = .data$distance, y = .data$survival),
        alpha = 0.5
      ) +
      ggplot2::geom_line(data = curves[curves$.survival > 0, ],
        ggplot2::aes(x = .data$distance, y = .data$.survival, colour = .data$family),
        linewidth = 0.9
      ) +
      ggplot2::scale_x_log10() +
      ggplot2::scale_y_log10() +
      ggplot2::labs(x = "Dispersal distance (log)", y = "P(distance > x) (log)",
        colour = "Kernel"
      ) +
      ggplot2::theme_minimal()
  }
}

#' @rdname inv_autoplot
#' @export
autoplot.inv_lag <- function(object, log_y = TRUE, ...) {
  df <- object$series
  long <- tibble::tibble(
    time = rep(df$time, 2),
    fitted = c(df$.fitted_single, df$.fitted_two_phase),
    model = rep(c("single exponential", "two-phase"), each = nrow(df))
  )
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$cumulative)) +
    ggplot2::geom_point(alpha = 0.7) +
    ggplot2::geom_line(data = long,
      ggplot2::aes(x = .data$time, y = .data$fitted, linetype = .data$model),
      colour = "#1F618D", linewidth = 0.8
    ) +
    ggplot2::labs(x = "Time", y = "Cumulative count", linetype = "Model") +
    ggplot2::theme_minimal()
  if (object$lag_detected) {
    p <- p + ggplot2::geom_vline(xintercept = object$breakpoint, colour = "#C0392B",
      linetype = "dashed"
    ) + ggplot2::labs(subtitle = paste0("Lag phase ends at ", signif(object$breakpoint, 5)))
  }
  if (log_y) p + ggplot2::scale_y_log10() else p
}

#' @rdname inv_autoplot
#' @export
autoplot.inv_establishment <- function(object, ...) {
  rng <- range(object$data$propagules)
  grid <- exp(seq(log(rng[1]), log(rng[2]), length.out = 200))
  curve <- stats::predict(object, grid)
  ggplot2::ggplot(object$data, ggplot2::aes(x = .data$propagules, y = .data$established)) +
    ggplot2::geom_jitter(height = 0.03, width = 0, alpha = 0.4) +
    ggplot2::geom_line(data = curve, ggplot2::aes(x = .data$propagules, y = .data$.pred),
      colour = "#C0392B", linewidth = 1
    ) +
    ggplot2::scale_x_log10() +
    ggplot2::labs(x = "Propagule size (log)", y = "Probability of establishment",
      subtitle = paste0(object$model, " model, N50 = ", signif(object$n50, 3))
    ) +
    ggplot2::theme_minimal()
}

#' @rdname inv_autoplot
#' @export
autoplot.inv_spatial_block_cv <- function(object, ...) {
  data <- object$splits[[1]]$data
  fold <- rep(NA_character_, nrow(data))
  for (i in seq_len(nrow(object))) {
    fold[object$splits[[i]]$out_id] <- object$id[[i]]
  }
  if (inherits(data, "sf")) {
    xy <- sf_coords(data)
    df <- tibble::tibble(.x = xy$x, .y = xy$y)
  } else {
    coords <- attr(object, "coords")
    df <- tibble::tibble(.x = data[[coords[1]]], .y = data[[coords[2]]])
  }
  df$fold <- fold
  ggplot2::ggplot(df, ggplot2::aes(x = .data$.x, y = .data$.y, colour = .data$fold)) +
    ggplot2::geom_point(size = 1) +
    ggplot2::labs(x = "x", y = "y", colour = "Assessment fold") +
    ggplot2::theme_minimal()
}
