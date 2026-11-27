# Dispersal distances (simulated)

Simulated dispersal distances in metres for two placeholder species:
`sp_a` (300 distances from a fat-tailed Weibull with shape 0.7 and scale
80) and `sp_b` (200 distances from a thin-tailed half-normal with sigma
40). Distances are rounded to 0.1 m with a minimum of 0.1 m.

## Usage

``` r
inv_dispersal
```

## Format

A tibble with 500 rows: `species` and `distance_m`.

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
inv_dispersal_kernel(dplyr::filter(inv_dispersal, species == "sp_b"), distance_m)
#> <inv_kernel> 5 dispersal kernels fitted to 200 distances
#> Best by AIC: halfnormal (sigma = 40.85); mean distance 32.6
```
