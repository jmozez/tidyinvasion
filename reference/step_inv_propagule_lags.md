# Lagged and cumulative propagule pressure features

`step_inv_propagule_lags()` creates a *specification* of a recipe step
that adds, for each selected propagule pressure column, its values `lag`
time steps earlier within each group, the cumulative pressure before the
current time step and, optionally, an exponentially discounted
cumulative pressure `sum(x_s * exp(-decay * (t - s)))` over earlier
times `s`. These features capture the delayed effect of past
introductions on establishment and spread. Rows keep their original
order.

## Usage

``` r
step_inv_propagule_lags(
  recipe,
  ...,
  role = "predictor",
  trained = FALSE,
  time,
  group = NULL,
  lag = 1,
  cumulative = TRUE,
  decay = NULL,
  prefix = "lag",
  columns = NULL,
  skip = FALSE,
  id = recipes::rand_id("inv_propagule_lags")
)

# S3 method for class 'step_inv_propagule_lags'
prep(x, training, info = NULL, ...)

# S3 method for class 'step_inv_propagule_lags'
bake(object, new_data, ...)

# S3 method for class 'step_inv_propagule_lags'
print(x, width = max(20, options()$width - 30), ...)

# S3 method for class 'step_inv_propagule_lags'
tidy(x, ...)

# S3 method for class 'step_inv_propagule_lags'
required_pkgs(x, ...)
```

## Arguments

- recipe:

  A recipe object.

- ...:

  One or more selector functions choosing numeric propagule pressure
  columns.

- role:

  Role of the new columns. Defaults to `"predictor"`.

- trained:

  A logical to indicate if the step has been trained.

- time:

  Name of the time column (bare or quoted).

- group:

  Optional name of a grouping column (for example region).

- lag:

  Positive whole numbers: lags (in rows within group, ordered by `time`)
  to create.

- cumulative:

  Add the cumulative pressure before each time step?

- decay:

  Optional non-negative decay rate per time unit.

- prefix:

  Prefix for lag column names.

- columns:

  Set by [`prep()`](https://recipes.tidymodels.org/reference/prep.html):
  the selected column names.

- skip:

  A logical. Should the step be skipped when the recipe is baked by
  [`bake()`](https://recipes.tidymodels.org/reference/bake.html)?
  Defaults to `TRUE` because the step removes rows.

- id:

  A character string that is unique to this step.

- x:

  A `step_inv_propagule_lags` object.

- training:

  A data frame used to train the step.

- info:

  Variable information from the recipe.

- object:

  A trained step.

- new_data:

  A data frame to process.

- width:

  Print width.

## Value

An updated recipe. New columns are named `{prefix}{lag}_{column}`,
`cumpp_{column}` and `decaypp_{column}`; the first rows of each group
have `NA` lags.
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns
`terms`, `lag` and `id`.

## Examples

``` r
library(recipes)
annual <- inv_introductions |>
  dplyr::count(region, year, wt = propagule_size, name = "propagules")
rec <- recipe(~., data = annual) |>
  step_inv_propagule_lags(propagules, time = year, group = region, lag = 1:2,
    decay = 0.2)
bake(prep(rec), new_data = NULL)
#> # A tibble: 102 × 7
#>    region  year propagules lag1_propagules lag2_propagules cumpp_propagules
#>    <fct>  <int>      <dbl>           <dbl>           <dbl>            <dbl>
#>  1 east    1990         51              NA              NA                0
#>  2 east    1991         78              51              NA               51
#>  3 east    1992          1              78              51              129
#>  4 east    1993         20               1              78              130
#>  5 east    1994         48              20               1              150
#>  6 east    1995         23              48              20              198
#>  7 east    1997         43              23              48              221
#>  8 east    1999          4              43              23              264
#>  9 east    2001        120               4              43              268
#> 10 east    2002         10             120               4              388
#> # ℹ 92 more rows
#> # ℹ 1 more variable: decaypp_propagules <dbl>
```
