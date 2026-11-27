# Invaded and uninvaded plots (simulated)

Simulated plot data from six sites, each with eight invaded and eight
uninvaded plots. Native richness is Poisson with a site mean of 12 to 30
species, reduced in invaded plots by a site-specific log response ratio
drawn from Normal(-0.35, 0.15). Native cover (%) is reduced by 1.5 times
that log ratio.

## Usage

``` r
inv_plots
```

## Format

A tibble with 96 rows: `site`, `plot`, `status` (`"invaded"` or
`"uninvaded"`), `native_richness` and `native_cover`.

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
inv_impact_metrics(inv_plots, native_richness, status, .by = site)
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
