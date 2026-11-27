# S3 tibble subclasses built on vctrs ------------------------------------
#
# Every tidyinvasion class stores its metadata in a single "inv_meta"
# attribute. `required` lists the columns that must survive a dplyr verb for
# the class to be kept; if any is dropped the result falls back to a tibble.

new_inv_tbl <- function(x, meta, class) {
  if (!is.list(x)) {
    cli::cli_abort("{.arg x} must be a list or data frame.")
  }
  n <- if (is.data.frame(x)) nrow(x) else vctrs::vec_size_common(!!!x)
  x <- as.list(x)
  out <- tibble::new_tibble(x, nrow = n, class = c(class, "inv_tbl"))
  attr(out, "inv_meta") <- meta
  out
}

inv_meta <- function(x) {
  attr(x, "inv_meta", exact = TRUE) %||% list()
}

inv_class <- function(x) {
  cls <- class(x)
  cls[seq_len(match("inv_tbl", cls, nomatch = 1L) - 1L)][1]
}

inv_restore <- function(x, to) {
  meta <- inv_meta(to)
  cls <- inv_class(to)
  required <- meta$required %||% character()
  plain <- x
  attr(plain, "inv_meta") <- NULL
  if (is.na(cls) || !all(required %in% names(x))) {
    class(plain) <- c("tbl_df", "tbl", "data.frame")
    return(plain)
  }
  new_inv_tbl(plain, meta, cls)
}

same_meta <- function(x, y) {
  identical(inv_meta(x)[c("required", "geographic")], inv_meta(y)[c("required", "geographic")])
}

inv_ptype2 <- function(x, y, ...) {
  out <- vctrs::tib_ptype2(x, y, ...)
  if (same_meta(x, y)) inv_restore(out, x) else out
}

inv_cast <- function(x, to, ...) {
  out <- vctrs::tib_cast(x, to, ...)
  inv_restore(out, to)
}

#' @export
vec_restore.inv_tbl <- function(x, to, ...) {
  inv_restore(x, to)
}

#' @export
dplyr_reconstruct.inv_tbl <- function(data, template) {
  inv_restore(data, template)
}

#' @export
`[.inv_tbl` <- function(x, i, j, drop = FALSE, ...) {
  out <- NextMethod()
  if (!is.data.frame(out)) {
    return(out)
  }
  inv_restore(out, x)
}

#' @export
`names<-.inv_tbl` <- function(x, value) {
  old <- names(x)
  meta <- inv_meta(x)
  out <- NextMethod()
  if (length(old) == length(value)) {
    map <- stats::setNames(value, old)
    fields <- setdiff(names(meta), c("summary", "crs", "geographic", "scheme", "fit",
      "origin", "units", "method"))
    for (f in fields) {
      v <- meta[[f]]
      if (is.character(v) && length(v)) {
        hit <- v %in% old
        v[hit] <- unname(map[v[hit]])
        meta[[f]] <- v
      }
    }
    attr(out, "inv_meta") <- meta
  }
  out
}

#' @export
tbl_sum.inv_tbl <- function(x, ...) {
  meta <- inv_meta(x)
  out <- NextMethod()
  names(out)[1] <- paste0("A <", inv_class(x), ">")
  extra <- meta$summary %||% character()
  c(out, extra)
}

# Double dispatch methods. vctrs only dispatches on the first class, so each
# subclass gets its own set of methods.

#' @export
vec_ptype2.inv_occurrence.inv_occurrence <- function(x, y, ...) inv_ptype2(x, y, ...)
#' @export
vec_ptype2.inv_occurrence.tbl_df <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.tbl_df.inv_occurrence <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.inv_occurrence.data.frame <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.data.frame.inv_occurrence <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_cast.inv_occurrence.inv_occurrence <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.inv_occurrence.tbl_df <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.tbl_df.inv_occurrence <- function(x, to, ...) vctrs::tib_cast(x, to, ...)
#' @export
vec_cast.inv_occurrence.data.frame <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.data.frame.inv_occurrence <- function(x, to, ...) vctrs::df_cast(x, to, ...)

#' @export
vec_ptype2.inv_pathway.inv_pathway <- function(x, y, ...) inv_ptype2(x, y, ...)
#' @export
vec_ptype2.inv_pathway.tbl_df <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.tbl_df.inv_pathway <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.inv_pathway.data.frame <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.data.frame.inv_pathway <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_cast.inv_pathway.inv_pathway <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.inv_pathway.tbl_df <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.tbl_df.inv_pathway <- function(x, to, ...) vctrs::tib_cast(x, to, ...)
#' @export
vec_cast.inv_pathway.data.frame <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.data.frame.inv_pathway <- function(x, to, ...) vctrs::df_cast(x, to, ...)

#' @export
vec_ptype2.inv_spread.inv_spread <- function(x, y, ...) inv_ptype2(x, y, ...)
#' @export
vec_ptype2.inv_spread.tbl_df <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.tbl_df.inv_spread <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.inv_spread.data.frame <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_ptype2.data.frame.inv_spread <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @export
vec_cast.inv_spread.inv_spread <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.inv_spread.tbl_df <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.tbl_df.inv_spread <- function(x, to, ...) vctrs::tib_cast(x, to, ...)
#' @export
vec_cast.inv_spread.data.frame <- function(x, to, ...) inv_cast(x, to, ...)
#' @export
vec_cast.data.frame.inv_spread <- function(x, to, ...) vctrs::df_cast(x, to, ...)

# Occurrences -------------------------------------------------------------

#' Create an invasion occurrence table
#'
#' `inv_occurrence()` turns a data frame of species records into an
#' `<inv_occurrence>` tibble. The class remembers which columns hold the
#' coordinates, time and species, and whether coordinates are geographic.
#' Spread, distance, plotting and resampling functions read these columns
#' automatically. The class survives `dplyr` verbs such as `filter()`,
#' `mutate()` and `arrange()`; dropping a coordinate column returns a plain
#' tibble.
#'
#' @param .data A data frame, tibble or `sf` POINT layer. For `sf` input the
#'   coordinates are extracted (and transformed to WGS84 when the layer has a
#'   geographic or missing CRS) into `lon` and `lat` columns and the geometry
#'   is dropped.
#' @param lon,lat <[`tidy-select`][tidyselect::language]> Columns holding
#'   longitude and latitude in decimal degrees, or x and y for projected
#'   coordinates. Ignored for `sf` input.
#' @param time <[`tidy-select`][tidyselect::language]> Optional column with the
#'   record date or year (numeric, `Date` or `POSIXct`).
#' @param species <[`tidy-select`][tidyselect::language]> Optional column with
#'   taxon names.
#' @param crs Coordinate reference system of `lon` and `lat`, as an EPSG code
#'   or string. Geographic coordinates (`4326`, `"EPSG:4326"`, `"OGC:CRS84"`)
#'   use great-circle distances; anything else is treated as projected with
#'   coordinates in metres.
#' @param x An object to test.
#'
#' @return An `<inv_occurrence>` tibble with the same rows and columns as
#'   `.data`. `is_inv_occurrence()` returns a single logical.
#' @export
#' @examples
#' occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year,
#'   species = species)
#' occ
#'
#' # The class is kept through dplyr verbs
#' dplyr::filter(occ, year < 1960)
inv_occurrence <- function(.data, lon = NULL, lat = NULL, time = NULL,
                           species = NULL, crs = 4326) {
  check_data_frame(.data)
  geographic <- is_geographic_crs(crs)
  if (inherits(.data, "sf")) {
    xy <- sf_coords(.data)
    data <- as_plain_tibble(.data)
    data$lon <- xy$x
    data$lat <- xy$y
    lon <- "lon"
    lat <- "lat"
    geographic <- xy$geographic
    crs <- if (geographic) 4326 else crs
  } else {
    data <- as_plain_tibble(.data)
    lon <- select_one(rlang::enquo(lon), data, "lon")
    lat <- select_one(rlang::enquo(lat), data, "lat")
  }
  time <- select_one(rlang::enquo(time), data, "time", required = FALSE)
  species <- select_one(rlang::enquo(species), data, "species", required = FALSE)
  check_numeric_col(data, lon)
  check_numeric_col(data, lat)
  if (geographic && (any(abs(data[[lon]]) > 180, na.rm = TRUE) ||
    any(abs(data[[lat]]) > 90, na.rm = TRUE))) {
    cli::cli_abort(c(
      "Coordinates in {.field {lon}} and {.field {lat}} are not valid longitude and latitude.",
      "i" = "Set {.arg crs} to the projected coordinate system of the data."
    ))
  }
  if (!is.null(time)) {
    as_time_numeric(data[[time]], time)
  }
  new_inv_occurrence(data, lon = lon, lat = lat, time = time,
    species = species, crs = crs, geographic = geographic
  )
}

new_inv_occurrence <- function(x, lon, lat, time = NULL, species = NULL,
                               crs = 4326, geographic = TRUE) {
  summary <- c(
    Coordinates = paste0(lon, ", ", lat, " (", format_crs(crs), ")"),
    Time = time %||% "none",
    Species = if (is.null(species)) {
      "none"
    } else {
      paste(utils::head(unique(as.character(x[[species]])), 3), collapse = ", ")
    }
  )
  meta <- list(
    lon = lon, lat = lat, time = time, species = species, crs = crs,
    geographic = geographic, required = c(lon, lat, time, species),
    summary = summary
  )
  new_inv_tbl(x, meta, "inv_occurrence")
}

#' @rdname inv_occurrence
#' @export
is_inv_occurrence <- function(x) inherits(x, "inv_occurrence")

is_geographic_crs <- function(crs) {
  if (is.null(crs) || (length(crs) == 1 && is.na(crs))) {
    return(TRUE)
  }
  if (inherits(crs, "crs")) {
    rlang::check_installed("sf")
    return(isTRUE(sf::st_is_longlat(crs)))
  }
  as.character(crs) %in% c("4326", "EPSG:4326", "epsg:4326", "OGC:CRS84", "WGS84", "CRS84")
}

format_crs <- function(crs) {
  if (inherits(crs, "crs")) {
    return(crs$input %||% "custom CRS")
  }
  if (is.numeric(crs)) paste0("EPSG:", crs) else as.character(crs)
}

#' Convert an occurrence table to an sf layer
#'
#' @param x An `<inv_occurrence>` tibble.
#' @return An `sf` POINT layer with the occurrence attributes. Requires the
#'   sf package.
#' @export
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
#' inv_as_sf(occ[1:5, ])
inv_as_sf <- function(x) {
  if (!is_inv_occurrence(x)) {
    cli::cli_abort("{.arg x} must be an {.cls inv_occurrence} tibble.")
  }
  rlang::check_installed("sf", reason = "to convert occurrences to an sf layer.")
  meta <- inv_meta(x)
  sf::st_as_sf(as_plain_tibble(x), coords = c(meta$lon, meta$lat), crs = meta$crs,
    remove = FALSE
  )
}

# Pathways ----------------------------------------------------------------

#' CBD introduction pathway categories
#'
#' The six main pathway categories of the Convention on Biological Diversity
#' classification (CBD 2014; Hulme et al. 2008,
#' \doi{10.1111/j.1365-2664.2007.01442.x}).
#'
#' @return A character vector.
#' @export
#' @examples
#' cbd_pathways()
cbd_pathways <- function() {
  c("release", "escape", "contaminant", "stowaway", "corridor", "unaided")
}

#' Create an introduction pathway table
#'
#' `inv_pathway()` marks a table of introduction events with the column that
#' holds the pathway and, optionally, the propagule size of each event.
#' With `scheme = "CBD"` the pathway values are checked against
#' [cbd_pathways()].
#'
#' @param .data A data frame of introduction events, one row per event.
#' @param pathway <[`tidy-select`][tidyselect::language]> Column with the
#'   pathway of each event.
#' @param size <[`tidy-select`][tidyselect::language]> Optional column with
#'   the number of individuals (propagules) introduced in each event.
#' @param scheme Pathway classification. `"CBD"` validates the values against
#'   the six CBD categories; `"none"` skips validation.
#' @param x An object to test.
#' @return An `<inv_pathway>` tibble. `is_inv_pathway()` returns a logical.
#' @export
#' @examples
#' pw <- inv_pathway(inv_introductions, pathway = pathway, size = propagule_size)
#' pw
#' inv_propagule_pressure(pw, .by = pathway)
inv_pathway <- function(.data, pathway, size = NULL, scheme = c("CBD", "none")) {
  check_data_frame(.data)
  scheme <- rlang::arg_match(scheme)
  data <- as_plain_tibble(.data)
  pathway <- select_one(rlang::enquo(pathway), data, "pathway")
  size <- select_one(rlang::enquo(size), data, "size", required = FALSE)
  if (!is.null(size)) {
    check_numeric_col(data, size, non_negative = TRUE)
  }
  if (scheme == "CBD") {
    vals <- unique(tolower(as.character(data[[pathway]])))
    bad <- setdiff(vals[!is.na(vals)], cbd_pathways())
    if (length(bad)) {
      cli::cli_warn(c(
        "{length(bad)} pathway value{?s} not in the CBD classification: {.val {bad}}.",
        "i" = "Valid categories are {.val {cbd_pathways()}}."
      ))
    }
  }
  summary <- c(Pathway = pathway, Size = size %||% "none", Scheme = scheme)
  meta <- list(pathway = pathway, size = size, scheme = scheme,
    required = c(pathway, size), summary = summary
  )
  new_inv_tbl(data, meta, "inv_pathway")
}

#' @rdname inv_pathway
#' @export
is_inv_pathway <- function(x) inherits(x, "inv_pathway")

# Spread ------------------------------------------------------------------

new_inv_spread <- function(x, method, origin, units, fit, time_unit = "time") {
  summary <- c(
    Method = method,
    Origin = paste(signif(origin, 6), collapse = ", "),
    Rate = paste0(signif(stats::coef(fit)[[2]], 4), " km per ", time_unit)
  )
  meta <- list(method = method, origin = origin, units = units, fit = fit,
    required = c("time", "distance_km"), summary = summary
  )
  new_inv_tbl(x, meta, "inv_spread")
}

#' @rdname inv_spread_rate
#' @param x An object to test.
#' @export
is_inv_spread <- function(x) inherits(x, "inv_spread")
