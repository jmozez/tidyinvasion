# Horizon scanning scores (simulated)

Simulated scores from four assessors for 30 placeholder candidate taxa
(`cand_01` to `cand_30`). Each taxon has a latent score from 1 to 5 for
arrival, establishment, spread and impact; each assessor's score is the
latent score plus Normal(0, 0.7) noise, rounded and limited to 1 to 5.

## Usage

``` r
inv_horizon
```

## Format

A tibble with 120 rows: `species`, `assessor`, `arrival`,
`establishment`, `spread`, `impact` and `confidence`.

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
inv_horizon_scan(inv_horizon, arrival:impact, species = species,
  assessor = assessor)
#> # A tibble: 30 × 11
#>    species arrival establishment spread impact n_assessors disagreement score
#>    <chr>     <dbl>         <dbl>  <dbl>  <dbl>       <int>        <dbl> <dbl>
#>  1 cand_04     4             4.5    5      4.5           4        0.539  405 
#>  2 cand_22     4.5           4.5    4      5             4        0.634  405 
#>  3 cand_15     4             5      5      4             4        0.579  400 
#>  4 cand_17     4             5      5      3.5           4        0.614  350 
#>  5 cand_06     4.5           3      4.5    5             4        0.414  304.
#>  6 cand_23     4.5           5      4      3             4        0.614  270 
#>  7 cand_13     3             3      5      3.5           4        0.818  158.
#>  8 cand_09     5             1.5    4      5             4        0.558  150 
#>  9 cand_07     5             4      2      3.5           4        0.614  140 
#> 10 cand_20     1.5           5      5      3.5           4        0.509  131.
#> # ℹ 20 more rows
#> # ℹ 3 more variables: scaled_score <dbl>, rank <int>, priority <ord>
```
