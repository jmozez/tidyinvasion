# Virtual species presence-background data (simulated)

A virtual species for species distribution modelling. 3,000 random
points in a box from 141 to 150 E and 11 to 2 S carry smooth synthetic
covariates (they are not real climate or land-cover data). True
suitability is
`plogis(-2 - 0.5 * (temp - 24)^2 + 0.0015 * (rain - 2500) + 2 * forest)`
and each point is a presence with probability 0.6 times its suitability.
All other points are background. Years from 2000 to 2020 were assigned
at random, for temporal resampling examples.

## Usage

``` r
inv_sdm_data
```

## Format

A tibble with 3,000 rows: `id`, `lon`, `lat`, `year`, `presence` (factor
with levels `"presence"` and `"background"`), `temp` (degrees C), `rain`
(mm per year) and `forest` (proportion).

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
table(inv_sdm_data$presence)
#> 
#>   presence background 
#>        271       2729 
```
