# Introduction events (simulated)

Simulated introduction events of 20 placeholder species (`sp01` to
`sp20`) in four regions, 1990 to 2020. Pathways follow the CBD
classification. Propagule sizes are one plus a negative binomial draw
(size 0.8) with a mean that depends on the pathway (release 40, escape
20, contaminant 6, stowaway 4, corridor 10, unaided 3). Establishment
was drawn from the Weibull dose-response
`P(N) = 1 - exp(-0.02 * N^1.3)`.
[`inv_establishment_prob()`](https://tidyinvasion.in4metrix.dev/reference/inv_establishment_prob.md)
estimates from these 240 events differ from the true values by sampling
error.

## Usage

``` r
inv_introductions
```

## Format

A tibble with 240 rows: `event_id`, `species`, `pathway`, `region`,
`year`, `propagule_size` and `established` (logical).

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
inv_introductions
#> # A tibble: 240 × 7
#>    event_id species pathway  region  year propagule_size established
#>    <chr>    <chr>   <chr>    <chr>  <int>          <dbl> <lgl>      
#>  1 ev014    sp14    stowaway west    1990             16 FALSE      
#>  2 ev025    sp09    stowaway east    1990              9 FALSE      
#>  3 ev041    sp03    stowaway west    1990              1 FALSE      
#>  4 ev060    sp18    stowaway east    1990              3 FALSE      
#>  5 ev069    sp13    escape   east    1990              1 FALSE      
#>  6 ev072    sp12    corridor west    1990              1 FALSE      
#>  7 ev098    sp08    stowaway south   1990              5 FALSE      
#>  8 ev177    sp03    release  east    1990             38 TRUE       
#>  9 ev215    sp03    stowaway south   1990              6 FALSE      
#> 10 ev006    sp18    stowaway north   1991              4 FALSE      
#> # ℹ 230 more rows
```
