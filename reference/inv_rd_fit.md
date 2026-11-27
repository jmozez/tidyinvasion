# Fit engine for `inv_reaction_diffusion()`

The fitting function called by parsnip for
[`inv_reaction_diffusion()`](https://tidyinvasion.in4metrix.dev/reference/inv_reaction_diffusion.md).
Use
[`inv_reaction_diffusion()`](https://tidyinvasion.in4metrix.dev/reference/inv_reaction_diffusion.md)
instead.

## Usage

``` r
inv_rd_fit(x, y, growth_rate = NULL, diffusion = NULL)
```

## Arguments

- x:

  A data frame or matrix with one numeric column: time since
  introduction (positive).

- y:

  Numeric vector of range radii.

- growth_rate, diffusion:

  Optional fixed values.

## Value

An object of class `inv_rd_fit`.

## Examples

``` r
t <- 1:25
radius <- sqrt(4 * 40 * t * (0.4 * t + log(5000) - log(4 * pi * 40 * t)))
fit <- inv_rd_fit(data.frame(t = t), radius)
fit
#> <inv_rd_fit> Skellam reaction-diffusion model
#> Diffusion D = 40, growth rate r = 0.4, log K = 8.517
#> Asymptotic speed 2 * sqrt(r * D) = 8 distance units per time unit
glance(fit)
#> # A tibble: 1 × 5
#>   speed      sigma      sse     n converged
#>   <dbl>      <dbl>    <dbl> <int> <lgl>    
#> 1  8.00 0.00000169 6.30e-11    25 TRUE     
```
