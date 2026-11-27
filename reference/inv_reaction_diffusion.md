# Reaction-diffusion spread model specification

`inv_reaction_diffusion()` defines Skellam's (1951) model of an invasion
spreading from a point release by diffusion (coefficient `D`) and
exponential growth (rate `r`). Density at distance `x` and time `t` is
`N0 / (4 * pi * D * t) * exp(r * t - x^2 / (4 * D * t))`, so the radius
at which density falls to the detection threshold `c` is

## Usage

``` r
inv_reaction_diffusion(
  mode = "regression",
  engine = "skellam",
  growth_rate = NULL,
  diffusion = NULL
)
```

## Arguments

- mode:

  Must be `"regression"`.

- engine:

  Only `"skellam"`.

- growth_rate:

  Optional fixed intrinsic growth rate `r`. Estimated when `NULL`.

- diffusion:

  Optional fixed diffusion coefficient `D`. Estimated when `NULL`.

## Value

A model specification of class `inv_reaction_diffusion`.

## Details

`R(t) = sqrt(4 * D * t * (r * t + log(K) - log(4 * pi * D * t)))`,

where `K = N0 / c`. `D`, `r` and `K` are estimated by least squares from
observed range radii, and the radius tends to the Fisher-Skellam
asymptotic speed `2 * sqrt(r * D)`. The single predictor must be the
time since introduction (positive) and the outcome the range radius, for
example the output of
[`inv_spread_rate()`](https://tidyinvasion.in4metrix.dev/reference/inv_spread_rate.md).

## References

Skellam, J. G. (1951). Random dispersal in theoretical populations.
*Biometrika*, 38, 196-218.
[doi:10.1093/biomet/38.1-2.196](https://doi.org/10.1093/biomet/38.1-2.196)

## Examples

``` r
radius <- data.frame(years = 1:30)
radius$radius_km <- sqrt(4 * 50 * radius$years *
  (0.5 * radius$years + log(1e4) - log(4 * pi * 50 * radius$years)))
spec <- inv_reaction_diffusion() |> parsnip::set_engine("skellam")
fit <- parsnip::fit(spec, radius_km ~ years, data = radius)
fit
#> parsnip model object
#> 
#> <inv_rd_fit> Skellam reaction-diffusion model
#> Diffusion D = 50, growth rate r = 0.5, log K = 9.21
#> Asymptotic speed 2 * sqrt(r * D) = 10 distance units per time unit
predict(fit, data.frame(years = c(40, 50)))
#> # A tibble: 2 × 1
#>   .pred
#>   <dbl>
#> 1  391.
#> 2  488.
```
