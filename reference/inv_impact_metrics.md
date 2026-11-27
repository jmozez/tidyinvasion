# Effect sizes of invasion impact

Compares a response (native richness, cover, biomass, a soil property)
between invaded and reference (uninvaded) plots and returns the log
response ratio (Hedges et al. 1999), Hedges' bias-corrected standardised
mean difference *g*, and the percentage change, with confidence
intervals.

## Usage

``` r
inv_impact_metrics(
  .data,
  response,
  status,
  invaded = "invaded",
  .by = NULL,
  conf_level = 0.95
)
```

## Arguments

- .data:

  A data frame with one row per plot or sample.

- response:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Numeric response column.

- status:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the invasion status of each row. It must have exactly two
  values.

- invaded:

  Value of `status` that marks invaded rows. The other value is the
  reference.

- .by:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional grouping columns, for example site or response variable.

- conf_level:

  Confidence level.

## Value

A tibble with one row per group: sample sizes, means and standard
deviations of both groups, `lnrr` with `lnrr_var`, `lnrr_low` and
`lnrr_high`, `hedges_g` with `hedges_g_var`, `g_low` and `g_high`, and
`pct_change` (`100 * (exp(lnrr) - 1)`). The log response ratio is `NA`
when either mean is not positive.

## References

Hedges, L. V., Gurevitch, J. and Curtis, P. S. (1999). The meta-analysis
of response ratios in experimental ecology. *Ecology*, 80, 1150-1156.

## Examples

``` r
inv_impact_metrics(inv_plots, response = native_richness, status = status,
  .by = site)
#> # A tibble: 6 × 16
#>   site   n_invaded n_reference mean_invaded mean_reference sd_invaded
#>   <chr>      <int>       <int>        <dbl>          <dbl>      <dbl>
#> 1 site_1         8           8         13             19.8       4.07
#> 2 site_2         8           8         23.1           31.9       2.47
#> 3 site_3         8           8          9             17         2.39
#> 4 site_4         8           8         13.8           15.1       4.23
#> 5 site_5         8           8         16.6           17         4.14
#> 6 site_6         8           8         13.5           24.9       4.17
#> # ℹ 10 more variables: sd_reference <dbl>, lnrr <dbl>, lnrr_var <dbl>,
#> #   lnrr_low <dbl>, lnrr_high <dbl>, hedges_g <dbl>, hedges_g_var <dbl>,
#> #   g_low <dbl>, g_high <dbl>, pct_change <dbl>
```
