# Predict establishment probability

Predict establishment probability

## Usage

``` r
# S3 method for class 'inv_establishment'
predict(object, new_data, ...)
```

## Arguments

- object:

  An `inv_establishment` fit.

- new_data:

  A data frame with the propagule column used in the fit, or a numeric
  vector of propagule sizes.

- ...:

  Not used.

## Value

A tibble with the propagule size and `.pred` (probability).

## Examples

``` r
fit <- inv_establishment_prob(inv_introductions, established, propagule_size)
predict(fit, c(1, 5, 50))
#> # A tibble: 3 × 2
#>   propagules  .pred
#>        <dbl>  <dbl>
#> 1          1 0.0390
#> 2          5 0.180 
#> 3         50 0.863 
```
