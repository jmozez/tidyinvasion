# Fit engine for `inv_sdm()`

The fitting function called by parsnip for
[`inv_sdm()`](https://tidyinvasion.in4metrix.dev/reference/inv_sdm.md).
It is exported so that parsnip can call it; use
[`inv_sdm()`](https://tidyinvasion.in4metrix.dev/reference/inv_sdm.md)
instead.

## Usage

``` r
inv_sdm_fit(
  x,
  y,
  degree = 2,
  method = c("glm", "iwlr"),
  bg_weight = 100,
  threshold = "max_tss",
  weights = NULL
)
```

## Arguments

- x:

  A data frame or matrix of numeric predictors.

- y:

  A two-level factor; the first level is the presence.

- degree:

  Polynomial degree.

- method:

  `"glm"` or `"iwlr"`.

- bg_weight:

  Weight of background rows for `method = "iwlr"`.

- threshold:

  Suitability threshold for class predictions: `"max_tss"` (the default)
  chooses the threshold that maximises the True Skill Statistic on the
  training data; a number in (0, 1) is used as is.

- weights:

  Optional case weights.

## Value

An object of class `inv_sdm_fit`.

## Examples

``` r
fit <- inv_sdm_fit(inv_sdm_data[c("temp", "rain", "forest")], inv_sdm_data$presence)
fit
#> <inv_sdm_fit> glm species distribution model, degree 2
#> Predictors: temp, rain, and forest
#> Class threshold: 0.0914
tidy(fit)
#> # A tibble: 7 × 5
#>   term        estimate std.error statistic  p.value
#>   <chr>          <dbl>     <dbl>     <dbl>    <dbl>
#> 1 (Intercept) -3.28       0.265   -12.4    2.47e-35
#> 2 temp        -4.30       0.527    -8.16   3.42e-16
#> 3 rain         0.488      0.121     4.05   5.15e- 5
#> 4 forest       0.324      0.124     2.61   9.01e- 3
#> 5 temp_pow2   -2.06       0.301    -6.84   8.12e-12
#> 6 rain_pow2   -0.123      0.0965   -1.27   2.04e- 1
#> 7 forest_pow2 -0.00238    0.0981   -0.0243 9.81e- 1
```
