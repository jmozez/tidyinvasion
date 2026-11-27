# Predict range radius from a reaction-diffusion fit

Predict range radius from a reaction-diffusion fit

## Usage

``` r
# S3 method for class 'inv_rd_fit'
predict(object, new_data, ...)
```

## Arguments

- object:

  An `inv_rd_fit` object.

- new_data:

  A data frame whose time column has the same name as in the fit (or a
  single numeric column).

- ...:

  Not used.

## Value

A numeric vector of predicted radii.

## Examples

``` r
fit <- inv_rd_fit(data.frame(t = 1:20), 30 * (1:20) + 5)
predict(fit, data.frame(t = 25))
#> [1] 755.0536
```
