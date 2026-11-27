# Continuous Boyce Index

The Continuous Boyce Index (CBI; Hirzel et al. 2006) evaluates
presence-background or presence-only predictions. Moving windows of
width `window_width` (as a fraction of the prediction range) are slid
across the predicted suitability. In each window the ratio of the
proportion of presences to the proportion of all evaluation points
(presences and background) is computed; the index is the Spearman
correlation between window centre and that ratio. Values near 1 mean
presences become more frequent than expected as suitability rises;
values near 0 mean the model is no better than random. Successive
duplicate ratios are removed before computing the correlation, as in the
reference implementation.

## Usage

``` r
boyce_index(data, ...)

# S3 method for class 'data.frame'
boyce_index(
  data,
  truth,
  ...,
  estimator = NULL,
  na_rm = TRUE,
  case_weights = NULL,
  event_level = "first",
  window_width = 0.1,
  n_windows = 101
)

boyce_index_vec(
  truth,
  estimate,
  estimator = NULL,
  na_rm = TRUE,
  case_weights = NULL,
  event_level = "first",
  window_width = 0.1,
  n_windows = 101,
  ...
)
```

## Arguments

- data:

  A data frame with the `truth` and `estimate` columns.

- ...:

  The column of predicted suitability for the presence class (unquoted).

- truth:

  The column of true classes: a two-level factor of presence and
  background.

- estimator:

  Only `"binary"` is supported.

- na_rm:

  Remove missing values?

- case_weights:

  Optional column of case weights.

- event_level:

  `"first"` or `"second"`: which level of `truth` is the presence
  (event).

- window_width:

  Width of each moving window as a fraction of the prediction range.

- n_windows:

  Number of window centres.

- estimate:

  A numeric vector of predicted suitability for the presence class.

## Value

For `boyce_index()`, a tibble with `.metric`, `.estimator` and
`.estimate`. For `boyce_index_vec()`, a single number.

## References

Hirzel, A. H., Le Lay, G., Helfer, V., Randin, C. and Guisan, A. (2006).
Evaluating the ability of habitat suitability models to predict species
presences. *Ecological Modelling*, 199, 142-152.
[doi:10.1016/j.ecolmodel.2006.05.017](https://doi.org/10.1016/j.ecolmodel.2006.05.017)

## See also

Other invasion metrics:
[`tss()`](https://tidyinvasion.in4metrix.dev/reference/tss.md)

## Examples

``` r
set.seed(1)
suit <- runif(500)
truth <- factor(ifelse(runif(500) < suit^2, "presence", "background"),
  levels = c("presence", "background"))
boyce_index_vec(truth, suit)
#> [1] 0.9881306
boyce_index(data.frame(truth = truth, suit = suit), truth, suit)
#> # A tibble: 1 × 3
#>   .metric     .estimator .estimate
#>   <chr>       <chr>          <dbl>
#> 1 boyce_index binary         0.988
```
