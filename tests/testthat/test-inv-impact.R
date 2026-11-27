test_that("impact effect sizes match hand calculations", {
  d <- data.frame(
    status = rep(c("invaded", "uninvaded"), each = 4),
    y = c(8, 10, 12, 10, 18, 20, 22, 20)
  )
  out <- inv_impact_metrics(d, response = y, status = status)
  m1 <- 10
  m2 <- 20
  s1 <- stats::sd(c(8, 10, 12, 10))
  s2 <- stats::sd(c(18, 20, 22, 20))
  expect_equal(out$lnrr, log(m1 / m2))
  expect_equal(out$lnrr_var, s1^2 / (4 * m1^2) + s2^2 / (4 * m2^2))
  sp <- sqrt((3 * s1^2 + 3 * s2^2) / 6)
  j <- 1 - 3 / (4 * 6 - 1)
  expect_equal(out$hedges_g, j * (m1 - m2) / sp)
  expect_equal(out$pct_change, -50)
  expect_true(out$lnrr_low < out$lnrr && out$lnrr < out$lnrr_high)
})

test_that("impact metrics work by group and validate status", {
  out <- inv_impact_metrics(inv_plots, response = native_richness, status = status, .by = site)
  expect_equal(nrow(out), 6)
  expect_true(mean(out$lnrr) < 0)
  bad <- data.frame(status = c("a", "b", "c"), y = 1:3)
  expect_error(inv_impact_metrics(bad, y, status), "exactly two values")
  zero <- data.frame(status = rep(c("invaded", "uninvaded"), each = 2), y = c(0, 0, 1, 2))
  expect_true(is.na(inv_impact_metrics(zero, y, status)$lnrr))
})

test_that("Parker impact multiplies range, abundance and effect", {
  d <- data.frame(sp = c("a", "b"), r = c(10, 2), a = c(2, 5), e = c(-1, -4))
  out <- inv_parker_impact(d, r, a, e)
  expect_equal(out$impact, c(-20, -40))
  expect_equal(out$rank, c(2, 1))
  expect_equal(out$relative_impact, c(-0.5, -1))
  expect_error(inv_parker_impact(data.frame(r = -1, a = 1, e = 1), r, a, e), "negative")
})

test_that("homogenisation index matches hand-computed Jaccard values", {
  d <- data.frame(
    site = c("s1", "s1", "s1", "s2", "s2", "s2"),
    species = c("n1", "n2", "a1", "n3", "n4", "a1"),
    status = c("native", "native", "alien", "native", "native", "alien")
  )
  out <- inv_homogenization(d, site, species, status)
  expect_equal(out$jaccard_native, 0)
  expect_equal(out$jaccard_current, 1 / 5)
  expect_equal(out$sorensen_current, 2 / 6)
  expect_true(out$homogenised)
  expect_equal(out$n_alien, 1)
})

test_that("the simulated communities are homogenised in every region", {
  out <- inv_homogenization(inv_communities, site, species, status, .by = region)
  expect_equal(nrow(out), 3)
  expect_true(all(out$delta_jaccard > 0))
  expect_error(
    inv_homogenization(data.frame(site = "a", species = "x", status = "native"), site, species, status),
    "two sites"
  )
})

test_that("EICAT category is the maximum magnitude per taxon", {
  d <- data.frame(
    sp = c("a", "a", "a", "b", "b", "c"),
    mag = c("MN", "Major", "mo", "MC", "DD", "dd"),
    mech = c("competition", "predation", "competition", "grazing", "grazing", "predation"),
    conf = c("high", "low", "medium", "medium", "low", "low")
  )
  out <- inv_eicat_score(d, sp, mag, mechanism = mech, confidence = conf)
  expect_equal(out$sp, c("a", "b", "c"))
  expect_equal(as.character(out$eicat_category), c("MR", "MC", "DD"))
  expect_s3_class(out$eicat_category, "ordered")
  expect_equal(out$eicat_score, c(4L, 1L, NA))
  expect_equal(out$harmful, c(TRUE, FALSE, FALSE))
  expect_equal(out$max_mechanisms[1], "predation")
  expect_equal(out$confidence[1], "low")
  # competition max is MO (3), predation MR (4)
  expect_equal(out$cumulative_score[1], 7)
  expect_error(inv_eicat_score(data.frame(s = "a", m = "huge"), s, m), "Unknown EICAT")
})

test_that("EICAT works on the simulated impact records", {
  out <- inv_eicat_score(inv_impacts, species, magnitude, mechanism, confidence)
  expect_equal(nrow(out), length(unique(inv_impacts$species)))
  expect_false(is.unsorted(rev(as.integer(out$eicat_category))))
})
