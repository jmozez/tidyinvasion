# rsample resampling schemes ----------------------------------------------

# Minimum distance (km) from each point in `a` to the set `b`, in chunks.
min_dist_to_set <- function(ax, ay, bx, by, geographic, chunk = 500) {
  out <- rep(Inf, length(ax))
  if (!length(bx) || !length(ax)) {
    return(out)
  }
  starts <- seq(1, length(bx), by = chunk)
  for (s in starts) {
    j <- s:min(length(bx), s + chunk - 1)
    d <- vapply(j, function(k) inv_dist_km(bx[k], by[k], ax, ay, geographic), numeric(length(ax)))
    d <- matrix(d, nrow = length(ax))
    out <- pmin(out, apply(d, 1, min))
  }
  out
}

#' Spatial block cross-validation
#'
#' Splits records into `v` folds by spatial blocks, so that the assessment
#' set of each fold is spatially separated from its analysis set. This gives
#' honest estimates of how well a species distribution model transfers to
#' unsampled areas, which ordinary random folds overestimate because of
#' spatial autocorrelation (Roberts et al. 2017). Blocks are square grid
#' cells assigned to folds so that folds hold similar numbers of records. An
#' optional `buffer` also removes analysis records within that distance of
#' any assessment record.
#'
#' @param .data A data frame, [inv_occurrence()] table or `sf` POINT layer.
#' @param lon,lat <[`tidy-select`][tidyselect::language]> Coordinate columns.
#' @param v Number of folds.
#' @param block_size Block edge length, in decimal degrees for geographic
#'   coordinates or coordinate units (metres) for projected ones. Defaults to
#'   a size giving about `4 * v` blocks across the larger extent.
#' @param buffer Optional buffer distance in kilometres.
#'
#' @return An `rset` of class `inv_spatial_block_cv` with columns `splits`
#'   and `id`. Use [rsample::analysis()] and [rsample::assessment()] on the
#'   splits, or pass it to `tune::fit_resamples()`.
#' @references Roberts, D. R., Bahn, V., Ciuti, S. et al. (2017).
#'   Cross-validation strategies for data with temporal, spatial,
#'   hierarchical, or phylogenetic structure. *Ecography*, 40, 913-929.
#'   \doi{10.1111/ecog.02881}
#' @export
#' @examples
#' set.seed(1)
#' folds <- inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 5,
#'   block_size = 1)
#' folds
#' rsample::assessment(folds$splits[[1]])
inv_spatial_block_cv <- function(.data, lon = NULL, lat = NULL, v = 5, block_size = NULL,
                                 buffer = NULL) {
  check_data_frame(.data)
  check_integerish(v, min = 2)
  check_number_positive(block_size, allow_null = TRUE)
  check_number_positive(buffer, allow_null = TRUE)
  xy <- resolve_coords(.data, rlang::enquo(lon), rlang::enquo(lat))
  if (anyNA(xy$x) || anyNA(xy$y)) {
    cli::cli_abort("Coordinates must not contain missing values.")
  }
  if (is.null(block_size)) {
    ext <- max(diff(range(xy$x)), diff(range(xy$y)))
    block_size <- if (ext > 0) ext / ceiling(sqrt(4 * v)) else 1
  }
  block <- paste(floor((xy$x - min(xy$x)) / block_size),
    floor((xy$y - min(xy$y)) / block_size),
    sep = "_"
  )
  sizes <- table(block)
  if (length(sizes) < v) {
    cli::cli_abort(c(
      "Only {length(sizes)} block{?s} for {v} folds.",
      "i" = "Use a smaller {.arg block_size} or fewer folds."
    ))
  }
  # Shuffle, then greedily assign the largest blocks to the emptiest fold.
  ord <- names(sizes)[sample.int(length(sizes))]
  ord <- ord[order(-sizes[ord])]
  load <- rep(0, v)
  fold_of <- stats::setNames(integer(length(ord)), ord)
  for (b in ord) {
    f <- which(load == min(load))
    f <- if (length(f) > 1) sample(f, 1) else f
    fold_of[b] <- f
    load[f] <- load[f] + sizes[[b]]
  }
  fold <- unname(fold_of[block])
  data <- if (inherits(.data, "sf")) .data else xy$data
  splits <- lapply(seq_len(v), function(f) {
    out_id <- which(fold == f)
    in_id <- which(fold != f)
    if (!is.null(buffer) && length(in_id)) {
      dmin <- min_dist_to_set(xy$x[in_id], xy$y[in_id], xy$x[out_id], xy$y[out_id],
        geographic = xy$geographic
      )
      in_id <- in_id[dmin > buffer]
    }
    rsample::make_splits(list(analysis = in_id, assessment = out_id), data = data)
  })
  ids <- tibble::tibble(id = sprintf(paste0("Fold%0", nchar(v), "d"), seq_len(v)))
  rsample::new_rset(
    splits = splits, ids = ids,
    attrib = list(v = v, block_size = block_size, buffer = buffer,
      coords = if (inherits(.data, "sf")) NULL else c(xy$lon, xy$lat)),
    subclass = c("inv_spatial_block_cv", "rset")
  )
}

#' @export
print.inv_spatial_block_cv <- function(x, ...) {
  buffer <- attr(x, "buffer")
  cat("#  Spatial block cross-validation: ", attr(x, "v"), " folds, block size ",
    signif(attr(x, "block_size"), 4),
    if (!is.null(buffer)) paste0(", buffer ", buffer, " km"), "\n",
    sep = ""
  )
  class(x) <- c("tbl_df", "tbl", "data.frame")
  print(x, ...)
  invisible(x)
}

#' Temporal transfer cross-validation
#'
#' Forward-chaining resampling for invasion data: each resample trains on
#' records up to a time period and assesses on the following period(s), so
#' models are always evaluated on their ability to predict the future of an
#' invasion, never the past. With `cumulative = TRUE` the analysis window
#' grows; otherwise it slides with a fixed width of `initial` periods.
#'
#' @param .data A data frame or [inv_occurrence()] table.
#' @param time <[`tidy-select`][tidyselect::language]> Time column. Defaults
#'   to the time column of an `<inv_occurrence>`.
#' @param initial Number of distinct time periods in the first analysis set.
#' @param assess Number of time periods in each assessment set.
#' @param gap Number of time periods left out between analysis and
#'   assessment sets, to avoid leakage between adjacent periods.
#' @param cumulative Should the analysis set grow (`TRUE`) or slide
#'   (`FALSE`)?
#'
#' @return An `rset` of class `inv_temporal_transfer_cv` with columns
#'   `splits` and `id`.
#' @export
#' @examples
#' slices <- inv_temporal_transfer_cv(inv_sdm_data, time = year, initial = 10,
#'   assess = 3)
#' slices
inv_temporal_transfer_cv <- function(.data, time = NULL, initial = 5, assess = 1, gap = 0,
                                     cumulative = TRUE) {
  check_data_frame(.data)
  check_integerish(initial)
  check_integerish(assess)
  check_integerish(gap, min = 0)
  meta <- inv_meta(.data)
  time_col <- select_one(rlang::enquo(time), .data, "time", required = is.null(meta$time)) %||%
    meta$time
  t <- as_time_numeric(.data[[time_col]], time_col)
  u <- sort(unique(t[!is.na(t)]))
  last <- length(u) - gap - assess
  if (last < initial) {
    cli::cli_abort(c(
      "Not enough time periods: {length(u)} found.",
      "i" = "Need at least {initial + gap + assess} for these settings."
    ))
  }
  ends <- seq(initial, last, by = assess)
  data <- if (inherits(.data, "sf")) .data else as_plain_tibble(.data)
  splits <- lapply(ends, function(e) {
    first <- if (cumulative) 1 else e - initial + 1
    in_t <- u[first:e]
    out_t <- u[(e + gap + 1):(e + gap + assess)]
    rsample::make_splits(
      list(analysis = which(t %in% in_t), assessment = which(t %in% out_t)),
      data = data
    )
  })
  ids <- tibble::tibble(id = sprintf(paste0("Slice%0", nchar(length(ends)), "d"), seq_along(ends)))
  rsample::new_rset(
    splits = splits, ids = ids,
    attrib = list(initial = initial, assess = assess, gap = gap, cumulative = cumulative,
      time = time_col),
    subclass = c("inv_temporal_transfer_cv", "rset")
  )
}

#' @export
print.inv_temporal_transfer_cv <- function(x, ...) {
  cat("#  Temporal transfer cross-validation: ", nrow(x), " slices, ",
    if (isTRUE(attr(x, "cumulative"))) "growing" else "sliding", " window, assess ",
    attr(x, "assess"), ", gap ", attr(x, "gap"), "\n",
    sep = ""
  )
  class(x) <- c("tbl_df", "tbl", "data.frame")
  print(x, ...)
  invisible(x)
}
