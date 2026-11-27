# Repeated detection surveys (simulated)

Simulated detection histories from five survey visits to 150 sites. True
occupancy is 0.25 in forest, 0.50 in grassland and 0.40 in urban sites;
detection per visit is 0.25 in forest and 0.40 elsewhere. About 8% of
visits were not made and are `NA`.

## Usage

``` r
inv_surveys
```

## Format

A tibble with 150 rows: `site`, `habitat` and `visit_1` to `visit_5` (1
detected, 0 not detected, `NA` not surveyed).

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
inv_detection_prob(inv_surveys, surveys = starts_with("visit"), .by = habitat)
#> # A tibble: 3 × 11
#>   habitat   n_sites n_surveys naive_occupancy   psi psi_se     p   p_se
#>   <chr>       <int>     <dbl>           <dbl> <dbl>  <dbl> <dbl>  <dbl>
#> 1 urban          48         5           0.312 0.349 0.0767 0.416 0.0671
#> 2 grassland      43         5           0.465 0.550 0.0980 0.339 0.0587
#> 3 forest         59         5           0.237 0.316 0.0863 0.263 0.0708
#> # ℹ 3 more variables: cumulative_p <dbl>, surveys_needed <dbl>, log_lik <dbl>
```
