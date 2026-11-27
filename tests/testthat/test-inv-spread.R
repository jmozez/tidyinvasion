test_that("haversine distances are correct", {
  d <- inv_distance(data.frame(x = c(0, 0, 145.79), y = c(0, 1, -17.10)),
    origin = c(0, 0), lon = x, lat = y
  )
  expect_equal(d$distance_km[1], 0)
  expect_equal(d$distance_km[2], 6371.0088 * pi / 180, tolerance = 1e-8)
  # London to Paris, about 343.5 km
  lp <- inv_distance(data.frame(x = 2.3522, y = 48.8566), origin = c(-0.1276, 51.5072),
    lon = x, lat = y
  )
  expect_equal(lp$distance_km, 343.5, tolerance = 0.005)
  expect_error(inv_distance(data.frame(x = 1, y = 1), origin = 1, lon = x, lat = y), "length 2")
})

test_that("projected coordinates use Euclidean distance in km", {
  occ <- inv_occurrence(data.frame(x = c(0, 3000), y = c(0, 4000)), lon = x, lat = y, crs = 3577)
  d <- inv_distance(occ, origin = c(0, 0))
  expect_equal(d$distance_km, c(0, 5))
})

sim_spread <- function(rate = 20, years = 1:30, n = 40) {
  set.seed(1)
  do.call(rbind, lapply(years, function(t) {
    r <- rate * t * sqrt(stats::runif(n))
    a <- stats::runif(n, 0, 2 * pi)
    data.frame(year = t, x = r * cos(a) * 1000, y = r * sin(a) * 1000)
  }))
}

test_that("spread rate methods recover a known radial rate", {
  d <- sim_spread(rate = 20)
  occ <- inv_occurrence(d, lon = x, lat = y, time = year, crs = 3577)
  front <- inv_spread_rate(occ, origin = c(0, 0), method = "front")
  expect_s3_class(front, "inv_spread")
  expect_equal(glance(front)$rate_km, 20, tolerance = 0.05)
  area <- inv_spread_rate(occ, origin = c(0, 0), method = "area")
  expect_equal(glance(area)$rate_km, 20, tolerance = 0.15)
  first <- inv_spread_rate(occ, origin = c(0, 0), method = "first_record", cell_size = 20000)
  expect_true(glance(first)$rate_km > 10)
  expect_equal(tidy(front)$term, c("intercept", "rate"))
  expect_equal(nrow(augment(front)), nrow(front))
})

test_that("spread rate works on the cane toad data", {
  sp <- inv_spread_rate(cane_toad, time = year, lon = lon, lat = lat,
    origin = c(145.79, -17.10), quantile = 0.95
  )
  g <- glance(sp)
  expect_true(g$rate_km > 0)
  expect_true(g$conf.low < g$rate_km && g$rate_km < g$conf.high)
  expect_error(inv_spread_rate(cane_toad[1:2, ], time = year, lon = lon, lat = lat), "three")
  default_origin <- inv_spread_rate(cane_toad, time = year, lon = lon, lat = lat)
  expect_length(attr(default_origin, "inv_meta")$origin, 2)
})

test_that("dispersal kernels recover parameters and rank by AIC", {
  set.seed(3)
  r <- stats::rexp(2000, rate = 1 / 50)
  k <- inv_dispersal_kernel(data.frame(d = r), d, family = c("exponential", "halfnormal"))
  expect_s3_class(k, "inv_kernel")
  expect_equal(names(k$fits)[1], "exponential")
  expect_equal(unname(k$fits$exponential$estimate), mean(r), tolerance = 1e-4)
  expect_equal(unname(k$fits$halfnormal$estimate), sqrt(mean(r^2)), tolerance = 1e-4)

  w <- stats::rweibull(3000, shape = 0.7, scale = 80)
  kw <- inv_dispersal_kernel(data.frame(d = w), d)
  est <- kw$fits$weibull$estimate
  expect_equal(unname(est["shape"]), 0.7, tolerance = 0.05)
  expect_equal(unname(est["scale"]), 80, tolerance = 0.1)
  ln <- kw$fits$lognormal$estimate
  expect_equal(unname(ln["meanlog"]), mean(log(w)), tolerance = 1e-4)

  gl <- glance(kw)
  expect_equal(sum(gl$weight), 1)
  expect_equal(gl$delta_AIC[1], 0)
  td <- tidy(kw, conf_int = TRUE)
  expect_true(all(c("conf.low", "conf.high") %in% names(td)))
  aug <- augment(kw, new_data = c(1, 10, 100))
  expect_equal(nrow(aug), 3)
  expect_true(all(diff(aug$.cdf) > 0))
  expect_output(print(kw), "Best by AIC")
})

test_that("dispersal kernel validates input", {
  expect_error(inv_dispersal_kernel(data.frame(d = c(0, 1, 2, 3, 4)), d), "strictly positive")
  expect_error(inv_dispersal_kernel(data.frame(d = 1:3), d), "five")
  expect_error(inv_dispersal_kernel(data.frame(d = 1:10), d, family = "cauchy"))
})

test_that("weights act as frequencies in kernel fits", {
  d <- data.frame(dist = c(10, 20, 30, 40, 50), n = c(5, 4, 3, 2, 1))
  kw <- inv_dispersal_kernel(d, dist, family = "exponential", weights = n)
  expect_equal(unname(kw$fits$exponential$estimate), weighted.mean(d$dist, d$n), tolerance = 1e-4)
})

test_that("lag phase is detected in a curve with a lag", {
  t <- 1950:2020
  rate <- ifelse(t < 1985, 0.01, 0.01 + 0.15 * (t - 1985) / (t - 1985 + 1e-9))
  set.seed(2)
  cum <- round(10 * exp(cumsum(rate)) * exp(stats::rnorm(length(t), 0, 0.02)))
  d <- data.frame(year = t, new = c(cum[1], pmax(0, diff(cum))))
  lag <- inv_lag_phase(d, time = year, count = new)
  expect_s3_class(lag, "inv_lag")
  expect_true(lag$lag_detected)
  expect_equal(lag$breakpoint, 1985, tolerance = 3 / 1985)
  expect_true(lag$rate_expansion > lag$rate_lag)
  gl <- glance(lag)
  expect_true(gl$delta_aic > 2)
  expect_equal(nrow(augment(lag)), nrow(lag$series))
  expect_equal(tidy(lag)$term[1], "breakpoint")
  expect_output(print(lag), "Lag phase detected")
})

test_that("no lag is reported for pure exponential growth", {
  t <- 1:40
  set.seed(5)
  cum <- round(5 * exp(0.12 * t + stats::rnorm(40, 0, 0.01)))
  d <- data.frame(t = t, new = c(cum[1], pmax(0, diff(cum))))
  lag <- inv_lag_phase(d, time = t, count = new)
  expect_false(lag$lag_detected)
  expect_error(inv_lag_phase(data.frame(t = 1:4), time = t), "time steps")
})
