# Species distribution model specification

`inv_sdm()` defines a presence-background (or presence-absence) species
distribution model for use with the tidymodels framework. Predictors are
standardised and expanded into polynomial terms of degree `degree`
(degree 2 gives the classic quadratic response curves). Two engines are
available:

## Usage

``` r
inv_sdm(mode = "classification", engine = "glm", degree = NULL)
```

## Arguments

- mode:

  Must be `"classification"`.

- engine:

  `"glm"` or `"iwlr"`.

- degree:

  Polynomial degree of each predictor (1 or 2, or higher).

## Value

A model specification of class `inv_sdm`.

## Details

- `"glm"`: logistic regression (binomial GLM) of presence against
  background or absence. Probabilities are probabilities of presence
  under the sampling design.

- `"iwlr"`: infinitely weighted logistic regression (Fithian and Hastie
  2013). Background rows get a large weight (`bg_weight`, an engine
  argument, default 100), so slope estimates converge on those of an
  inhomogeneous Poisson process, the model underlying Maxent.
  Predictions are the relative intensity mapped to 0 to 1 with a
  complementary log-log link: a relative suitability index, not a
  probability of presence.

The outcome must be a two-level factor whose **first level** is the
presence, following the yardstick convention. Class predictions use the
threshold that maximises the True Skill Statistic on the training data
(Liu et al. 2005), which suits the low prevalence of presence-background
data far better than 0.5. Set the engine argument `threshold` to a
number to override it, for example `set_engine("glm", threshold = 0.3)`.

## References

Fithian, W. and Hastie, T. (2013). Finite-sample equivalence in
statistical models for presence-only data. *Annals of Applied
Statistics*, 7, 1917-1939.
[doi:10.1214/13-AOAS667](https://doi.org/10.1214/13-AOAS667)

Liu, C., Berry, P. M., Dawson, T. P. and Pearson, R. G. (2005).
Selecting thresholds of occurrence in the prediction of species
distributions. *Ecography*, 28, 385-393.
[doi:10.1111/j.0906-7590.2005.03957.x](https://doi.org/10.1111/j.0906-7590.2005.03957.x)

## Examples

``` r
spec <- inv_sdm(degree = 2) |> parsnip::set_engine("glm")
fit <- parsnip::fit(spec, presence ~ temp + rain + forest, data = inv_sdm_data)
predict(fit, inv_sdm_data[1:5, ], type = "prob")
#> # A tibble: 5 × 2
#>   .pred_presence .pred_background
#>            <dbl>            <dbl>
#> 1      0.0000644            1.000
#> 2      0.00121              0.999
#> 3      0.0421               0.958
#> 4      0.00241              0.998
#> 5      0.0219               0.978

iw <- inv_sdm() |> parsnip::set_engine("iwlr", bg_weight = 100)
parsnip::fit(iw, presence ~ temp + rain, data = inv_sdm_data)
#> parsnip model object
#> 
#> <inv_sdm_fit> iwlr species distribution model, degree 2
#> Predictors: temp and rain
#> Class threshold: 0.0897
```
