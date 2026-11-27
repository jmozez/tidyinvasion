# Tuning parameters for reaction-diffusion spread

dials parameter objects for the `growth_rate` and `diffusion` arguments
of
[`inv_reaction_diffusion()`](https://tidyinvasion.in4metrix.dev/reference/inv_reaction_diffusion.md).
They need the dials package.

## Usage

``` r
spread_growth_rate(range = c(-3, 1), trans = NULL)

spread_diffusion(range = c(-2, 4), trans = NULL)
```

## Arguments

- range:

  Two numbers: the parameter range on the log10 scale.

- trans:

  A transformation object from the scales package. The default is log10.

## Value

A dials `quant_param` object.

## Examples

``` r
spread_growth_rate()
#> Intrinsic growth rate (quantitative)
#> Transformer: log-10 [1e-100, Inf]
#> Range (transformed scale): [-3, 1]
spread_diffusion()
#> Diffusion coefficient (quantitative)
#> Transformer: log-10 [1e-100, Inf]
#> Range (transformed scale): [-2, 4]
```
