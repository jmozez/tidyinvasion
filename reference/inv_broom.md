# Tidy, glance and augment tidyinvasion models

broom-style summaries for the model objects returned by tidyinvasion:
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) gives one row
per parameter,
[`glance()`](https://generics.r-lib.org/reference/glance.html) one row
of model-level statistics and
[`augment()`](https://generics.r-lib.org/reference/augment.html) the
data with fitted values.

## Usage

``` r
# S3 method for class 'inv_establishment'
tidy(x, conf_int = TRUE, conf_level = NULL, ...)

# S3 method for class 'inv_establishment'
glance(x, ...)

# S3 method for class 'inv_establishment'
augment(x, new_data = NULL, ...)

# S3 method for class 'inv_kernel'
tidy(x, conf_int = FALSE, conf_level = 0.95, ...)

# S3 method for class 'inv_kernel'
glance(x, ...)

# S3 method for class 'inv_kernel'
augment(x, new_data = NULL, family = NULL, ...)

# S3 method for class 'inv_lag'
tidy(x, ...)

# S3 method for class 'inv_lag'
glance(x, ...)

# S3 method for class 'inv_lag'
augment(x, ...)

# S3 method for class 'inv_spread'
tidy(x, conf_int = TRUE, conf_level = NULL, ...)

# S3 method for class 'inv_spread'
glance(x, conf_level = NULL, ...)

# S3 method for class 'inv_spread'
augment(x, ...)

# S3 method for class 'inv_sdm_fit'
tidy(x, conf_int = FALSE, conf_level = 0.95, ...)

# S3 method for class 'inv_sdm_fit'
glance(x, ...)

# S3 method for class 'inv_rd_fit'
tidy(x, ...)

# S3 method for class 'inv_rd_fit'
glance(x, ...)
```

## Arguments

- x:

  An object returned by
  [`inv_establishment_prob()`](https://tidyinvasion.in4metrix.dev/reference/inv_establishment_prob.md),
  [`inv_dispersal_kernel()`](https://tidyinvasion.in4metrix.dev/reference/inv_dispersal_kernel.md),
  [`inv_lag_phase()`](https://tidyinvasion.in4metrix.dev/reference/inv_lag_phase.md),
  [`inv_spread_rate()`](https://tidyinvasion.in4metrix.dev/reference/inv_spread_rate.md),
  [`inv_sdm_fit()`](https://tidyinvasion.in4metrix.dev/reference/inv_sdm_fit.md)
  or
  [`inv_rd_fit()`](https://tidyinvasion.in4metrix.dev/reference/inv_rd_fit.md).

- conf_int:

  Include confidence intervals?

- conf_level:

  Confidence level. Defaults to the level used when fitting, or 0.95.

- ...:

  Not used.

- new_data:

  Optional new data for
  [`augment()`](https://generics.r-lib.org/reference/augment.html). For
  kernels, a numeric vector of distances.

- family:

  For kernels, which fitted family to use in
  [`augment()`](https://generics.r-lib.org/reference/augment.html).
  Defaults to the best by AIC.

## Value

A tibble.

## Examples

``` r
fit <- inv_establishment_prob(inv_introductions, established, propagule_size)
tidy(fit)
#> # A tibble: 1 × 5
#>   term  estimate std.error conf.low conf.high
#>   <chr>    <dbl>     <dbl>    <dbl>     <dbl>
#> 1 alpha   0.0397   0.00504   0.0310    0.0510
glance(fit)
#> # A tibble: 1 × 7
#>   model           n logLik   AIC   BIC   n50 converged
#>   <chr>       <int>  <dbl> <dbl> <dbl> <dbl> <lgl>    
#> 1 exponential   240  -84.9  172.  175.  17.4 TRUE     
head(augment(fit))
#> # A tibble: 6 × 4
#>   propagules established .fitted  .resid
#>        <dbl>       <dbl>   <dbl>   <dbl>
#> 1         16           0  0.470  -0.470 
#> 2          9           0  0.301  -0.301 
#> 3          1           0  0.0390 -0.0390
#> 4          3           0  0.112  -0.112 
#> 5          1           0  0.0390 -0.0390
#> 6          1           0  0.0390 -0.0390

occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
spread <- inv_spread_rate(occ, origin = c(145.79, -17.10), quantile = 0.95)
tidy(spread)
#> # A tibble: 2 × 7
#>   term       estimate std.error statistic  p.value  conf.low conf.high
#>   <chr>         <dbl>     <dbl>     <dbl>    <dbl>     <dbl>     <dbl>
#> 1 intercept -12511.    1324.        -9.45 4.92e-15 -15142.    -9879.  
#> 2 rate           7.01     0.669     10.5  3.64e-17      5.68      8.34
glance(spread)
#> # A tibble: 1 × 10
#>   method rate_km std.error conf.low conf.high r.squared  p.value     n origin_x
#>   <chr>    <dbl>     <dbl>    <dbl>     <dbl>     <dbl>    <dbl> <int>    <dbl>
#> 1 front     7.01     0.669     5.68      8.34     0.555 3.64e-17    90     146.
#> # ℹ 1 more variable: origin_y <dbl>
```
