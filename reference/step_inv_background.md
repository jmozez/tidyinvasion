# Background (pseudo-absence) subsampling for presence-background data

`step_inv_background()` creates a *specification* of a recipe step that
subsamples the background (or absence) rows of a presence-background
data set so that there are `ratio` background rows for every presence.
With `method = "stratified"` the background is first clustered by
k-means on the numeric predictors and sampled evenly across clusters,
which spreads the background across environmental space. Because it
changes the number of rows, the step is skipped when baking new data by
default.

## Usage

``` r
step_inv_background(
  recipe,
  ...,
  role = NA,
  trained = FALSE,
  ratio = 10,
  event = NULL,
  method = c("random", "stratified"),
  n_strata = 10,
  column = NULL,
  predictors = NULL,
  seed = sample.int(10^5, 1),
  skip = TRUE,
  id = recipes::rand_id("inv_background")
)

# S3 method for class 'step_inv_background'
prep(x, training, info = NULL, ...)

# S3 method for class 'step_inv_background'
bake(object, new_data, ...)

# S3 method for class 'step_inv_background'
print(x, width = max(20, options()$width - 30), ...)

# S3 method for class 'step_inv_background'
tidy(x, ...)

# S3 method for class 'step_inv_background'
required_pkgs(x, ...)
```

## Arguments

- recipe:

  A recipe object.

- ...:

  One or more selector functions choosing the presence column: logical,
  0/1 or a two-level factor.

- role:

  Not used by this step since no new variables are created.

- trained:

  A logical to indicate if the step has been trained.

- ratio:

  Number of background rows to keep per presence.

- event:

  Value of the presence column that marks presences. Defaults to `TRUE`,
  `1` or the first factor level.

- method:

  `"random"` or `"stratified"` (k-means on numeric predictors).

- n_strata:

  Number of k-means clusters for `method = "stratified"`.

- column, predictors:

  Set by [`prep()`](https://recipes.tidymodels.org/reference/prep.html):
  the presence column and the numeric predictors used for
  stratification.

- seed:

  Integer seed for reproducible subsampling.

- skip:

  A logical. Should the step be skipped when the recipe is baked by
  [`bake()`](https://recipes.tidymodels.org/reference/bake.html)?
  Defaults to `TRUE` because the step removes rows.

- id:

  A character string that is unique to this step.

- x:

  A `step_inv_background` object.

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

An updated recipe with the new step added.
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns a
tibble with columns `terms`, `ratio`, `method` and `id`.

## References

Barbet-Massin, M., Jiguet, F., Albert, C. H. and Thuiller, W. (2012).
Selecting pseudo-absences for species distribution models: how, where
and how many? *Methods in Ecology and Evolution*, 3, 327-338.
[doi:10.1111/j.2041-210X.2011.00172.x](https://doi.org/10.1111/j.2041-210X.2011.00172.x)

## Examples

``` r
library(recipes)
#> Loading required package: dplyr
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
#> 
#> Attaching package: ‘recipes’
#> The following object is masked from ‘package:stats’:
#> 
#>     step
rec <- recipe(presence ~ temp + rain + forest, data = inv_sdm_data) |>
  step_inv_background(presence, ratio = 2, seed = 1)
prepped <- prep(rec)
table(bake(prepped, new_data = NULL)$presence)
#> 
#>   presence background 
#>        271        542 
tidy(prepped, number = 1)
#> # A tibble: 1 × 4
#>   terms    ratio method id                  
#>   <chr>    <dbl> <chr>  <chr>               
#> 1 presence     2 random inv_background_Y0psJ
```
