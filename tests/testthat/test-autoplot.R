test_that("autoplot draws occurrences, spread, kernels and lag phases", {
  occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
  p1 <- autoplot(occ)
  expect_s3_class(p1, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p1))
  occ_nt <- inv_occurrence(cane_toad, lon = lon, lat = lat)
  expect_s3_class(autoplot(occ_nt), "ggplot")

  for (m in c("front", "area", "first_record")) {
    sp <- inv_spread_rate(occ, origin = c(145.79, -17.10), method = m)
    p <- autoplot(sp)
    expect_s3_class(p, "ggplot")
    expect_no_error(ggplot2::ggplot_build(p))
  }

  k <- inv_dispersal_kernel(dplyr::filter(inv_dispersal, species == "sp_a"), distance_m)
  expect_no_error(ggplot2::ggplot_build(autoplot(k)))
  expect_no_error(ggplot2::ggplot_build(autoplot(k, type = "tail")))
  expect_error(autoplot(k, type = "map"))

  lag <- inv_lag_phase(occ)
  expect_no_error(ggplot2::ggplot_build(autoplot(lag)))
  expect_no_error(ggplot2::ggplot_build(autoplot(lag, log_y = FALSE)))
})

test_that("autoplot draws establishment curves and block folds", {
  fit <- inv_establishment_prob(inv_introductions, established, propagule_size)
  p <- autoplot(fit)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
  set.seed(1)
  folds <- inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 4, block_size = 1.5)
  pf <- autoplot(folds)
  expect_no_error(ggplot2::ggplot_build(pf))
  expect_equal(length(unique(pf$data$fold)), 4)
})
