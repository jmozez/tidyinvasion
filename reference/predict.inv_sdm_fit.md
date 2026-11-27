# Predict from a fitted species distribution model

Predict from a fitted species distribution model

## Usage

``` r
# S3 method for class 'inv_sdm_fit'
predict(
  object,
  new_data,
  type = c("prob", "class", "link"),
  threshold = NULL,
  ...
)
```

## Arguments

- object:

  An `inv_sdm_fit` object.

- new_data:

  A data frame with the predictor columns.

- type:

  `"prob"` (suitability of the presence class), `"class"` or `"link"`
  (linear predictor).

- threshold:

  Suitability threshold for `type = "class"`. Defaults to the threshold
  stored in the fit (see
  [`inv_sdm_fit()`](https://tidyinvasion.in4metrix.dev/reference/inv_sdm_fit.md)).

- ...:

  Not used.

## Value

A numeric vector, or a factor for `type = "class"`.

## Examples

``` r
fit <- inv_sdm_fit(inv_sdm_data[c("temp", "rain")], inv_sdm_data$presence)
head(predict(fit, inv_sdm_data, type = "prob"))
#> [1] 3.753576e-05 1.541151e-03 6.486713e-02 2.869793e-03 2.716271e-02
#> [6] 3.247475e-05
```
