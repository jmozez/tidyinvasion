# True Skill Statistic

The True Skill Statistic (TSS; Allouche et al. 2006) is sensitivity plus
specificity minus one. It ranges from -1 to 1, where 1 is perfect
agreement and 0 or less is no better than random, and unlike Cohen's
kappa it does not depend on prevalence. It is numerically the same as
Youden's J. For more than two classes the macro-averaged sensitivity and
specificity are used.

## Usage

``` r
tss(data, ...)

# S3 method for class 'data.frame'
tss(
  data,
  truth,
  estimate,
  estimator = NULL,
  na_rm = TRUE,
  case_weights = NULL,
  event_level = "first",
  ...
)

tss_vec(
  truth,
  estimate,
  estimator = NULL,
  na_rm = TRUE,
  case_weights = NULL,
  event_level = "first",
  ...
)
```

## Arguments

- data:

  A data frame with the `truth` and `estimate` columns.

- ...:

  Not used.

- truth:

  The column of true classes (a factor).

- estimate:

  The column of predicted classes (a factor with the same levels).

- estimator:

  One of `"binary"`, `"macro"`, `"macro_weighted"` or `"micro"`; `NULL`
  chooses `"binary"` for two classes.

- na_rm:

  Remove missing values?

- case_weights:

  Optional column of case weights.

- event_level:

  `"first"` or `"second"`: which level of `truth` is the presence
  (event).

## Value

For `tss()`, a tibble with columns `.metric`, `.estimator` and
`.estimate`. For `tss_vec()`, a single number.

## References

Allouche, O., Tsoar, A. and Kadmon, R. (2006). Assessing the accuracy of
species distribution models: prevalence, kappa and the true skill
statistic (TSS). *Journal of Applied Ecology*, 43, 1223-1232.
[doi:10.1111/j.1365-2664.2006.01214.x](https://doi.org/10.1111/j.1365-2664.2006.01214.x)

## See also

Other invasion metrics:
[`boyce_index()`](https://tidyinvasion.in4metrix.dev/reference/boyce_index.md)

## Examples

``` r
df <- data.frame(
  truth = factor(c("presence", "presence", "background", "background", "presence"),
    levels = c("presence", "background")),
  pred = factor(c("presence", "background", "background", "background", "presence"),
    levels = c("presence", "background"))
)
tss(df, truth, pred)
#> # A tibble: 1 × 3
#>   .metric .estimator .estimate
#>   <chr>   <chr>          <dbl>
#> 1 tss     binary         0.667
tss_vec(df$truth, df$pred)
#> [1] 0.6666667
```
