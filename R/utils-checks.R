# Internal validation and helper functions --------------------------------

check_data_frame <- function(x, arg = rlang::caller_arg(x),
                             call = rlang::caller_env()) {
  if (!is.data.frame(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a data frame, tibble or {.cls sf} object, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
}

check_number_positive <- function(x, arg = rlang::caller_arg(x),
                                  call = rlang::caller_env(),
                                  allow_zero = FALSE, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(invisible(x))
  }
  ok <- is.numeric(x) && length(x) == 1 && !is.na(x) && is.finite(x) &&
    (if (allow_zero) x >= 0 else x > 0)
  if (!ok) {
    cli::cli_abort(
      paste0("{.arg {arg}} must be a single ", if (allow_zero) "non-negative" else "positive", " number."),
      call = call
    )
  }
  invisible(x)
}

check_probability <- function(x, arg = rlang::caller_arg(x),
                              call = rlang::caller_env(), open = TRUE) {
  ok <- is.numeric(x) && length(x) == 1 && !is.na(x) &&
    (if (open) x > 0 && x < 1 else x >= 0 && x <= 1)
  if (!ok) {
    cli::cli_abort("{.arg {arg}} must be a single number between 0 and 1.", call = call)
  }
  invisible(x)
}

check_integerish <- function(x, arg = rlang::caller_arg(x),
                             call = rlang::caller_env(), min = 1) {
  ok <- is.numeric(x) && length(x) == 1 && !is.na(x) && x == round(x) && x >= min
  if (!ok) {
    cli::cli_abort("{.arg {arg}} must be a single whole number of at least {min}.", call = call)
  }
  invisible(x)
}

# Resolve a single column from a tidyselect quosure. Returns the column name,
# or NULL when the quosure is NULL and the column is optional.
select_one <- function(quo, data, arg, required = TRUE,
                       call = rlang::caller_env()) {
  if (rlang::quo_is_null(quo) || rlang::quo_is_missing(quo)) {
    if (required) {
      cli::cli_abort("{.arg {arg}} is required and must name a column.", call = call)
    }
    return(NULL)
  }
  loc <- tidyselect::eval_select(quo, data, allow_rename = FALSE, error_call = call)
  if (length(loc) != 1) {
    cli::cli_abort(
      "{.arg {arg}} must select exactly one column, not {length(loc)}.",
      call = call
    )
  }
  names(loc)
}

# Resolve any number of columns from a tidyselect quosure.
select_many <- function(quo, data, arg, call = rlang::caller_env()) {
  if (rlang::quo_is_null(quo) || rlang::quo_is_missing(quo)) {
    return(character())
  }
  names(tidyselect::eval_select(quo, data, allow_rename = FALSE, error_call = call))
}

check_numeric_col <- function(data, col, call = rlang::caller_env(),
                              non_negative = FALSE) {
  x <- data[[col]]
  if (!is.numeric(x)) {
    cli::cli_abort("Column {.field {col}} must be numeric, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  if (non_negative && any(x < 0, na.rm = TRUE)) {
    cli::cli_abort("Column {.field {col}} must not contain negative values.", call = call)
  }
  invisible(x)
}

# Convert a 0/1, logical or two-level factor column into logical.
as_binary <- function(x, col, event = NULL, call = rlang::caller_env()) {
  if (is.logical(x)) {
    return(x)
  }
  if (is.numeric(x)) {
    if (!all(x[!is.na(x)] %in% c(0, 1))) {
      cli::cli_abort("Column {.field {col}} must only contain 0 and 1.", call = call)
    }
    return(x == 1)
  }
  if (is.factor(x) || is.character(x)) {
    lv <- if (is.factor(x)) levels(x) else sort(unique(x[!is.na(x)]))
    if (length(lv) != 2) {
      cli::cli_abort("Column {.field {col}} must have exactly two levels, not {length(lv)}.",
        call = call
      )
    }
    event <- event %||% lv[[1]]
    if (!event %in% lv) {
      cli::cli_abort("{.val {event}} is not a level of {.field {col}}.", call = call)
    }
    return(as.character(x) == event)
  }
  cli::cli_abort("Column {.field {col}} must be logical, 0/1 or a two-level factor.",
    call = call
  )
}

# Drop sf geometry (if any) and return a plain tibble.
as_plain_tibble <- function(x) {
  if (inherits(x, "sf")) {
    x <- sf_drop_geometry(x)
  }
  if (inherits(x, "inv_tbl")) {
    attr(x, "inv_meta") <- NULL
  }
  tibble::as_tibble(as.data.frame(x, stringsAsFactors = FALSE))
}

sf_drop_geometry <- function(x) {
  rlang::check_installed("sf", reason = "to read coordinates from an sf object.")
  sf::st_drop_geometry(x)
}

# Extract lon/lat (or x/y) coordinates from an sf POINT layer.
sf_coords <- function(x, call = rlang::caller_env()) {
  rlang::check_installed("sf", reason = "to read coordinates from an sf object.")
  geom_type <- unique(as.character(sf::st_geometry_type(x)))
  if (!all(geom_type %in% "POINT")) {
    cli::cli_abort("{.cls sf} input must contain POINT geometries only.", call = call)
  }
  crs <- sf::st_crs(x)
  geographic <- isTRUE(sf::st_is_longlat(x)) || is.na(crs)
  if (!is.na(crs) && !geographic) {
    coords <- sf::st_coordinates(x)
    return(list(x = coords[, 1], y = coords[, 2], geographic = FALSE))
  }
  if (!is.na(crs) && !isTRUE(crs == sf::st_crs(4326))) {
    x <- sf::st_transform(x, 4326)
  }
  coords <- sf::st_coordinates(x)
  list(x = coords[, 1], y = coords[, 2], geographic = TRUE)
}

# Resolve coordinates from a data frame, an inv_occurrence or an sf layer.
# Returns list(x, y, geographic, data) where data is a plain tibble.
resolve_coords <- function(.data, lon_quo, lat_quo, call = rlang::caller_env()) {
  if (inherits(.data, "sf")) {
    xy <- sf_coords(.data, call = call)
    xy$data <- as_plain_tibble(.data)
    return(xy)
  }
  meta <- inv_meta(.data)
  lon <- select_one(lon_quo, .data, "lon", required = is.null(meta$lon), call = call) %||%
    meta$lon
  lat <- select_one(lat_quo, .data, "lat", required = is.null(meta$lat), call = call) %||%
    meta$lat
  check_numeric_col(.data, lon, call = call)
  check_numeric_col(.data, lat, call = call)
  geographic <- meta$geographic %||% TRUE
  x <- .data[[lon]]
  y <- .data[[lat]]
  if (geographic && (any(abs(x) > 180, na.rm = TRUE) || any(abs(y) > 90, na.rm = TRUE))) {
    cli::cli_abort(
      c(
        "Coordinates are outside the range of longitude and latitude.",
        "i" = "Use {.fn inv_occurrence} with a projected {.arg crs} for projected coordinates."
      ),
      call = call
    )
  }
  list(x = x, y = y, geographic = geographic, data = as_plain_tibble(.data),
       lon = lon, lat = lat)
}

#' Great-circle and planar distances
#'
#' Vectorised haversine distance on a sphere of mean Earth radius
#' (6371.0088 km) or Euclidean distance for projected coordinates.
#'
#' @param x1,y1,x2,y2 Numeric coordinate vectors, recycled. For geographic
#'   coordinates these are longitude and latitude in decimal degrees.
#' @param geographic Logical. Use the haversine formula (`TRUE`) or Euclidean
#'   distance (`FALSE`).
#' @param unit_scale Divisor applied to Euclidean distances. The default of
#'   1000 converts metres to kilometres.
#' @return A numeric vector of distances in kilometres.
#' @keywords internal
#' @noRd
inv_dist_km <- function(x1, y1, x2, y2, geographic = TRUE, unit_scale = 1000) {
  if (!geographic) {
    return(sqrt((x2 - x1)^2 + (y2 - y1)^2) / unit_scale)
  }
  rad <- pi / 180
  dlat <- (y2 - y1) * rad
  dlon <- (x2 - x1) * rad
  a <- sin(dlat / 2)^2 + cos(y1 * rad) * cos(y2 * rad) * sin(dlon / 2)^2
  2 * 6371.0088 * asin(pmin(1, sqrt(a)))
}

# Local equirectangular projection to kilometres around a reference point.
project_km <- function(x, y, x0, y0, geographic = TRUE, unit_scale = 1000) {
  if (!geographic) {
    return(list(x = (x - x0) / unit_scale, y = (y - y0) / unit_scale))
  }
  rad <- pi / 180
  r <- 6371.0088
  list(x = (x - x0) * rad * r * cos(y0 * rad), y = (y - y0) * rad * r)
}

# Convert a time column (numeric, Date, POSIXct) into decimal numbers.
as_time_numeric <- function(x, col = "time", call = rlang::caller_env()) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    d <- as.Date(x)
    yr <- as.numeric(format(d, "%Y"))
    start <- as.Date(paste0(yr, "-01-01"))
    days <- as.numeric(as.Date(paste0(yr + 1, "-01-01")) - start)
    return(yr + as.numeric(d - start) / days)
  }
  if (!is.numeric(x)) {
    cli::cli_abort("Column {.field {col}} must be numeric, a {.cls Date} or a {.cls POSIXct}.",
      call = call
    )
  }
  as.numeric(x)
}

# Split-apply-combine over `.by` groups without data masking.
by_apply <- function(.data, by_quo, fn, call = rlang::caller_env()) {
  by_cols <- select_many(by_quo, .data, ".by", call = call)
  if (!length(by_cols) && inherits(.data, "grouped_df")) {
    by_cols <- dplyr::group_vars(.data)
  }
  data <- as_plain_tibble(dplyr::ungroup(.data))
  if (!length(by_cols)) {
    return(tibble::as_tibble(fn(data)))
  }
  pieces <- vctrs::vec_split(data, data[by_cols])
  res <- lapply(seq_along(pieces$val), function(i) {
    r <- tibble::as_tibble(fn(pieces$val[[i]]))
    key <- pieces$key[rep(i, nrow(r)), , drop = FALSE]
    dplyr::bind_cols(key, r[setdiff(names(r), by_cols)])
  })
  dplyr::bind_rows(res)
}

# Numerical Hessian based standard errors, guarded against singularity.
safe_vcov <- function(fn, par, ...) {
  h <- tryCatch(stats::optimHess(par, fn, ...), error = function(e) NULL)
  if (is.null(h) || any(!is.finite(h))) {
    return(matrix(NA_real_, length(par), length(par)))
  }
  v <- tryCatch(solve(h), error = function(e) NULL)
  if (is.null(v)) {
    return(matrix(NA_real_, length(par), length(par)))
  }
  v
}

safe_sqrt <- function(x) {
  out <- rep(NA_real_, length(x))
  ok <- is.finite(x) & x >= 0
  out[ok] <- sqrt(x[ok])
  out
}

# Moore-Penrose pseudo inverse via SVD.
pinv <- function(m, tol = sqrt(.Machine$double.eps)) {
  s <- svd(m)
  keep <- s$d > tol * max(s$d)
  if (!any(keep)) {
    return(matrix(0, ncol(m), nrow(m)))
  }
  s$v[, keep, drop = FALSE] %*% (t(s$u[, keep, drop = FALSE]) / s$d[keep])
}

as_col_name <- function(quo, arg, call = rlang::caller_env()) {
  if (rlang::quo_is_null(quo) || rlang::quo_is_missing(quo)) {
    return(NULL)
  }
  expr <- rlang::quo_get_expr(quo)
  if (is.character(expr) && length(expr) == 1) {
    return(expr)
  }
  if (rlang::is_symbol(expr)) {
    return(rlang::as_string(expr))
  }
  cli::cli_abort("{.arg {arg}} must be a single column name.", call = call)
}

# Print a line formatted with cli inline markup to standard output.
cat_line <- function(x, .envir = parent.frame()) {
  cat(cli::format_inline(x, .envir = .envir), "\n", sep = "")
}
