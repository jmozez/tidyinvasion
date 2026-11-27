# Environmental distance and novelty relative to reference conditions

`step_inv_env_distance()` creates a *specification* of a recipe step
that measures how far each row lies from the reference environment
learned from the training data (all rows, or only presences when
`presence` is given). Two measures are available:

## Usage

``` r
step_inv_env_distance(
  recipe,
  ...,
  role = "predictor",
  trained = FALSE,
  presence = NULL,
  event = NULL,
  method = c("both", "mahalanobis", "mess"),
  prefix = "env_",
  columns = NULL,
  reference = NULL,
  skip = FALSE,
  id = recipes::rand_id("inv_env_distance")
)

# S3 method for class 'step_inv_env_distance'
prep(x, training, info = NULL, ...)

# S3 method for class 'step_inv_env_distance'
bake(object, new_data, ...)

# S3 method for class 'step_inv_env_distance'
print(x, width = max(20, options()$width - 30), ...)

# S3 method for class 'step_inv_env_distance'
tidy(x, ...)

# S3 method for class 'step_inv_env_distance'
required_pkgs(x, ...)
```

## Arguments

- recipe:

  A recipe object.

- ...:

  One or more selector functions choosing numeric environmental
  predictors.

- role:

  Role of the new columns. Defaults to `"predictor"`.

- trained:

  A logical to indicate if the step has been trained.

- presence:

  Optional name of the presence column. When given, only rows with
  `presence == event` form the reference.

- event:

  Value of `presence` that marks presences.

- method:

  `"both"`, `"mahalanobis"` or `"mess"`.

- prefix:

  Prefix for the new columns.

- columns, reference:

  Set by [`prep()`](https://recipes.tidymodels.org/reference/prep.html):
  the selected columns and the reference statistics.

- skip:

  A logical. Should the step be skipped when the recipe is baked by
  [`bake()`](https://recipes.tidymodels.org/reference/bake.html)?
  Defaults to `TRUE` because the step removes rows.

- id:

  A character string that is unique to this step.

- x:

  A `step_inv_env_distance` object.

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

An updated recipe. Baking adds `{prefix}mahalanobis` and/or
`{prefix}mess` and `{prefix}mod`.
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns
`terms`, `mean` and `sd` of the reference for each variable, and `id`.

## Details

- Mahalanobis distance from the centroid of the reference environment,
  using its covariance matrix (a pseudo-inverse is used when it is
  singular).

- The multivariate environmental similarity surface (MESS; Elith et al.
  2010). Negative values flag novel conditions outside the reference
  range, where predictions from transferred models are extrapolations.
  The most dissimilar variable (MoD) is also returned.

## References

Elith, J., Kearney, M. and Phillips, S. (2010). The art of modelling
range-shifting species. *Methods in Ecology and Evolution*, 1, 330-342.
[doi:10.1111/j.2041-210X.2010.00036.x](https://doi.org/10.1111/j.2041-210X.2010.00036.x)

## Examples

``` r
library(recipes)
rec <- recipe(presence ~ temp + rain + forest, data = inv_sdm_data) |>
  step_inv_env_distance(temp, rain, forest, presence = presence)
baked <- bake(prep(rec), new_data = NULL)
summary(baked$env_mess)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#> -72.009 -27.088  -2.658  -4.979  10.332  96.679 
```
