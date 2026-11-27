test_that("spatial block folds are disjoint and cover all rows", {
  set.seed(10)
  folds <- inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 5, block_size = 1)
  expect_s3_class(folds, c("inv_spatial_block_cv", "rset"))
  expect_equal(nrow(folds), 5)
  all_out <- unlist(lapply(folds$splits, function(s) s$out_id))
  expect_equal(sort(all_out), seq_len(nrow(inv_sdm_data)))
  for (s in folds$splits) {
    expect_length(intersect(s$in_id, s$out_id), 0)
  }
  sizes <- vapply(folds$splits, function(s) length(s$out_id), integer(1))
  expect_true(max(sizes) / min(sizes) < 1.5)
  expect_output(print(folds), "Spatial block cross-validation")
  expect_s3_class(rsample::analysis(folds$splits[[1]]), "tbl_df")
})

test_that("blocks never straddle folds and buffers remove nearby training rows", {
  set.seed(2)
  folds <- inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 4, block_size = 1.5,
    buffer = 50
  )
  s <- folds$splits[[1]]
  test <- inv_sdm_data[s$out_id, ]
  train <- inv_sdm_data[s$in_id, ]
  dmin <- vapply(seq_len(nrow(train)), function(i) {
    min(tidyinvasion:::inv_dist_km(train$lon[i], train$lat[i], test$lon, test$lat))
  }, numeric(1))
  expect_true(all(dmin > 50))
  no_buf <- length(setdiff(seq_len(nrow(inv_sdm_data)), s$out_id))
  expect_true(length(s$in_id) < no_buf)
})

test_that("spatial block CV accepts occurrences and validates input", {
  occ <- inv_occurrence(inv_sdm_data, lon = lon, lat = lat, time = year)
  set.seed(1)
  folds <- inv_spatial_block_cv(occ, v = 3)
  expect_equal(nrow(folds), 3)
  expect_error(inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 5, block_size = 100),
    "block")
  expect_error(inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 1), "at least 2")
})

test_that("spatial block CV works with sf input", {
  skip_if_not_installed("sf")
  pts <- sf::st_as_sf(inv_sdm_data[1:300, ], coords = c("lon", "lat"), crs = 4326)
  set.seed(4)
  folds <- inv_spatial_block_cv(pts, v = 3, block_size = 2)
  expect_equal(nrow(folds), 3)
  expect_s3_class(rsample::assessment(folds$splits[[1]]), "sf")
})

test_that("temporal transfer folds always assess later periods", {
  slices <- inv_temporal_transfer_cv(inv_sdm_data, time = year, initial = 10, assess = 2, gap = 1)
  expect_s3_class(slices, c("inv_temporal_transfer_cv", "rset"))
  for (s in slices$splits) {
    tr <- inv_sdm_data$year[s$in_id]
    te <- inv_sdm_data$year[s$out_id]
    expect_true(max(tr) + 1 < min(te))
    expect_equal(length(unique(te)), 2)
  }
  first <- slices$splits[[1]]
  expect_equal(sort(unique(inv_sdm_data$year[first$in_id])), 2000:2009)
  expect_output(print(slices), "Temporal transfer")

  sliding <- inv_temporal_transfer_cv(inv_sdm_data, time = year, initial = 5, cumulative = FALSE)
  widths <- vapply(sliding$splits, function(s) length(unique(inv_sdm_data$year[s$in_id])), integer(1))
  expect_true(all(widths == 5))
  expect_error(inv_temporal_transfer_cv(inv_sdm_data, time = year, initial = 30), "Not enough")
})
