# Detect a lag phase in an invasion time series

Many invasions grow slowly for years before expanding. `inv_lag_phase()`
builds the cumulative invasion curve (records, occupied cells or any
count over time), log-transforms it and compares a single exponential
growth model with a continuous two-phase (broken-stick) model whose
breakpoint is found by profile least squares. A lag phase is reported
when the two-phase model is better by more than `delta_aic` and growth
after the breakpoint is faster than before it (Aikio et al. 2010).

## Usage

``` r
inv_lag_phase(.data, time = NULL, count = NULL, min_points = 3, delta_aic = 2)
```

## Arguments

- .data:

  A data frame, typically one row per record, or one row per time step
  when `count` is given.

- time:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with time. Defaults to the time column of an
  `<inv_occurrence>`.

- count:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with counts per row (for example, new occupied cells).
  Without it each row counts as one record.

- min_points:

  Minimum number of time steps on each side of the breakpoint.

- delta_aic:

  AIC improvement needed to declare a lag phase.

## Value

An object of class `inv_lag`: a list with the series (`time`, `n`,
`cumulative`, fitted values), breakpoint, growth rates and AIC values.
Use [`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html),
[`augment()`](https://generics.r-lib.org/reference/augment.html) and
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).

## References

Aikio, S., Duncan, R. P. and Hulme, P. E. (2010). Lag-phases in alien
plant invasions: separating the facts from the artefacts. *Oikos*, 119,
370-378.
[doi:10.1111/j.1600-0706.2009.17963.x](https://doi.org/10.1111/j.1600-0706.2009.17963.x)

## Examples

``` r
lag <- inv_lag_phase(cane_toad, time = year)
glance(lag)
#> # A tibble: 1 × 8
#>   lag_detected lag_end lag_duration doubling_time aic_single aic_two_phase
#>   <lgl>          <dbl>        <dbl>         <dbl>      <dbl>         <dbl>
#> 1 FALSE             NA           NA          12.1      -107.         -231.
#> # ℹ 2 more variables: delta_aic <dbl>, n_times <int>
tidy(lag)
#> # A tibble: 4 × 2
#>   term            estimate
#>   <chr>              <dbl>
#> 1 breakpoint     1937.    
#> 2 rate_lag          1.73  
#> 3 rate_expansion    0.0573
#> 4 rate_single       0.0623
```
