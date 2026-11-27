# Niche overlap and niche shift between native and invaded ranges

Compares the environmental niche of a species in its native and its
invaded range with the PCA-env framework of Broennimann et al. (2012)
and the COUE scheme of Guisan et al. (2014), as in the ecospat package:

1.  a principal component analysis of the environmental variables is
    calibrated on the background (available environment) of both ranges;

2.  occurrences and background are smoothed with a Gaussian kernel on a
    grid of the first two axes, and occupancy is the occurrence density
    divided by the density of available environment, so it does not
    depend on how common each environment is;

3.  overlap is measured with Schoener's D and Warren's I, and the niche
    dynamics in environments available in both ranges are split into
    stability (shared), expansion (occupied only in the invaded range)
    and unfilling (occupied only in the native range);

4.  a niche equivalency test reallocates the pooled occurrences at
    random between the ranges to ask whether the niches differ more than
    chance.

High expansion is evidence of a niche shift, which makes models
calibrated on the native range underpredict the invasion.

## Usage

``` r
inv_niche_overlap(
  .data,
  range,
  presence,
  env,
  native = NULL,
  grid = 100,
  nperm = 99,
  seed = NULL
)
```

## Arguments

- .data:

  A data frame with occurrences and background points of both ranges.

- range:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the range of each row, with two values; the first (factor
  level or sort order) is the native range, or set `native`.

- presence:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column marking occurrences (`TRUE` or 1) and background points
  (`FALSE` or 0).

- env:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Two or more numeric environmental columns.

- native:

  Value of `range` for the native range.

- grid:

  Number of grid cells along each axis.

- nperm:

  Number of permutations for the equivalency test; `0` skips it.

- seed:

  Optional random seed for the test.

## Value

A one-row tibble with `n_native`, `n_invaded` (occurrences),
`schoener_d`, `warren_i`, `stability`, `expansion`, `unfilling`,
`p_equivalency` (small values mean the niches are not equivalent) and
`pca_variance` (share of the environmental variance on the two axes).

## References

Broennimann, O., Fitzpatrick, M. C., Pearman, P. B., Petitpierre, B.,
Pellissier, L., Yoccoz, N. G., Thuiller, W., Fortin, M.-J., Randin, C.,
Zimmermann, N. E., Graham, C. H. and Guisan, A. (2012). Measuring
ecological niche overlap from occurrence and spatial environmental data.
Global Ecology and Biogeography, 21, 481-497.
[doi:10.1111/j.1466-8238.2011.00698.x](https://doi.org/10.1111/j.1466-8238.2011.00698.x)

Guisan, A., Petitpierre, B., Broennimann, O., Daehler, C. and Kueffer,
C. (2014). Unifying niche shift studies: insights from biological
invasions. Trends in Ecology and Evolution, 29, 260-269.
[doi:10.1016/j.tree.2014.02.009](https://doi.org/10.1016/j.tree.2014.02.009)

Warren, D. L., Glor, R. E. and Turelli, M. (2008). Environmental niche
equivalency versus conservatism: quantitative approaches to niche
evolution. Evolution, 62, 2868-2883.
[doi:10.1111/j.1558-5646.2008.00482.x](https://doi.org/10.1111/j.1558-5646.2008.00482.x)

## Examples

``` r
set.seed(1)
bg <- data.frame(
  range = rep(c("native", "invaded"), each = 400),
  temp = c(rnorm(400, 22, 3), rnorm(400, 24, 3)),
  rain = c(rnorm(400, 2000, 400), rnorm(400, 1800, 400))
)
bg$presence <- 0
# Invaded-range occurrences extend into warmer climates: a niche shift
occ <- data.frame(
  range = rep(c("native", "invaded"), each = 150),
  temp = c(rnorm(150, 21, 1.5), rnorm(150, 25, 1.5)),
  rain = c(rnorm(150, 2100, 200), rnorm(150, 1900, 200)),
  presence = 1
)
inv_niche_overlap(rbind(bg, occ), range, presence, c(temp, rain),
  native = "native", nperm = 19, seed = 1)
#> # A tibble: 1 × 11
#>   native invaded n_native n_invaded schoener_d warren_i stability expansion
#>   <chr>  <chr>      <int>     <int>      <dbl>    <dbl>     <dbl>     <dbl>
#> 1 native invaded      150       150      0.202    0.336     0.505     0.495
#> # ℹ 3 more variables: unfilling <dbl>, p_equivalency <dbl>, pca_variance <dbl>
```
