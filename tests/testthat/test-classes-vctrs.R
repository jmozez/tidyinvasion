occ_df <- data.frame(
  id = 1:6,
  x = c(145, 146, 147, 148, 149, 150),
  y = c(-17, -18, -19, -20, -21, -22),
  yr = c(1935, 1940, 1950, 1960, 1970, 1980),
  sp = "Rhinella marina"
)

test_that("inv_occurrence builds a tibble subclass with metadata", {
  occ <- inv_occurrence(occ_df, lon = x, lat = y, time = yr, species = sp)
  expect_s3_class(occ, c("inv_occurrence", "inv_tbl", "tbl_df", "tbl", "data.frame"))
  expect_true(is_inv_occurrence(occ))
  meta <- attr(occ, "inv_meta")
  expect_equal(meta$lon, "x")
  expect_equal(meta$lat, "y")
  expect_equal(meta$time, "yr")
  expect_true(meta$geographic)
  expect_equal(nrow(occ), 6)
})

test_that("class survives dplyr verbs and drops when coordinates go", {
  occ <- inv_occurrence(occ_df, lon = x, lat = y, time = yr)
  expect_s3_class(dplyr::filter(occ, yr > 1940), "inv_occurrence")
  expect_s3_class(dplyr::mutate(occ, z = id * 2), "inv_occurrence")
  expect_s3_class(dplyr::arrange(occ, dplyr::desc(yr)), "inv_occurrence")
  expect_s3_class(occ[1:2, ], "inv_occurrence")
  dropped <- dplyr::select(occ, id, yr)
  expect_false(inherits(dropped, "inv_occurrence"))
  expect_s3_class(dropped, "tbl_df")
  renamed <- dplyr::rename(occ, longitude = x)
  expect_s3_class(renamed, "inv_occurrence")
  expect_equal(attr(renamed, "inv_meta")$lon, "longitude")
  expect_equal(inv_distance(renamed, origin = c(145, -17))$distance_km[1], 0)
  expect_s3_class(occ[, c("x", "y", "yr")], "inv_occurrence")
  expect_false(inherits(occ[, "id"], "inv_occurrence"))
})

test_that("vctrs ptype2 and cast methods combine occurrence tables", {
  occ <- inv_occurrence(occ_df, lon = x, lat = y, time = yr)
  both <- vctrs::vec_rbind(occ[1:2, ], occ[3:4, ])
  expect_s3_class(both, "inv_occurrence")
  expect_equal(nrow(both), 4)
  mixed <- vctrs::vec_rbind(occ[1:2, ], tibble::as_tibble(occ_df[3:4, ]))
  expect_s3_class(mixed, "tbl_df")
  expect_false(inherits(mixed, "inv_occurrence"))
  casted <- vctrs::vec_cast(tibble::as_tibble(occ_df), occ)
  expect_s3_class(casted, "inv_occurrence")
  to_tbl <- vctrs::vec_cast(occ, tibble::as_tibble(occ_df))
  expect_s3_class(to_tbl, "tbl_df")
  expect_false(inherits(to_tbl, "inv_occurrence"))
  expect_s3_class(vctrs::vec_ptype2(occ, occ), "inv_occurrence")
})

test_that("inv_occurrence validates input", {
  expect_error(inv_occurrence(1:3, lon = x, lat = y), "must be a data frame")
  bad <- occ_df
  bad$x <- bad$x + 200
  expect_error(inv_occurrence(bad, lon = x, lat = y), "not valid longitude")
  expect_silent(inv_occurrence(bad, lon = x, lat = y, crs = 3857))
  expect_error(inv_occurrence(occ_df, lon = c(x, y), lat = y), "exactly one column")
  chr <- occ_df
  chr$x <- as.character(chr$x)
  expect_error(inv_occurrence(chr, lon = x, lat = y), "must be numeric")
})

test_that("printing shows the class header", {
  occ <- inv_occurrence(occ_df, lon = x, lat = y, time = yr)
  out <- format(occ)
  expect_true(any(grepl("inv_occurrence", out)))
  expect_true(any(grepl("Coordinates", out)))
})

test_that("sf points are accepted when sf is installed", {
  skip_if_not_installed("sf")
  pts <- sf::st_as_sf(occ_df, coords = c("x", "y"), crs = 4326)
  occ <- inv_occurrence(pts, time = yr)
  expect_equal(occ$lon, occ_df$x)
  expect_equal(occ$lat, occ_df$y)
  back <- inv_as_sf(occ)
  expect_s3_class(back, "sf")
  projected <- sf::st_transform(pts, 3577)
  occ_p <- inv_occurrence(projected, time = yr, crs = 3577)
  expect_false(attr(occ_p, "inv_meta")$geographic)
})

test_that("inv_pathway checks CBD categories", {
  pw <- inv_pathway(inv_introductions, pathway = pathway, size = propagule_size)
  expect_s3_class(pw, "inv_pathway")
  expect_true(is_inv_pathway(pw))
  expect_s3_class(dplyr::filter(pw, pathway == "escape"), "inv_pathway")
  bad <- data.frame(route = c("escape", "ballast"), n = 1:2)
  expect_warning(inv_pathway(bad, pathway = route), "not in the CBD")
  expect_silent(inv_pathway(bad, pathway = route, scheme = "none"))
  expect_equal(cbd_pathways()[1], "release")
  combined <- vctrs::vec_rbind(pw[1:3, ], pw[4:5, ])
  expect_s3_class(combined, "inv_pathway")
})

test_that("inv_spread keeps its class through filtering", {
  occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
  sp <- inv_spread_rate(occ, origin = c(145.79, -17.10))
  expect_true(is_inv_spread(sp))
  expect_s3_class(dplyr::filter(sp, time > 1950), "inv_spread")
  expect_s3_class(vctrs::vec_rbind(sp[1:2, ], sp[3:4, ]), "inv_spread")
  expect_false(inherits(dplyr::select(sp, n), "inv_spread"))
})
