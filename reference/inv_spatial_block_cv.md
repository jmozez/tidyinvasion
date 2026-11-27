# Spatial block cross-validation

Splits records into `v` folds by spatial blocks, so that the assessment
set of each fold is spatially separated from its analysis set. This
gives honest estimates of how well a species distribution model
transfers to unsampled areas, which ordinary random folds overestimate
because of spatial autocorrelation (Roberts et al. 2017). Blocks are
square grid cells assigned to folds so that folds hold similar numbers
of records. An optional `buffer` also removes analysis records within
that distance of any assessment record.

## Usage

``` r
inv_spatial_block_cv(
  .data,
  lon = NULL,
  lat = NULL,
  v = 5,
  block_size = NULL,
  buffer = NULL
)
```

## Arguments

- .data:

  A data frame,
  [`inv_occurrence()`](https://tidyinvasion.in4metrix.dev/reference/inv_occurrence.md)
  table or `sf` POINT layer.

- lon, lat:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Coordinate columns.

- v:

  Number of folds.

- block_size:

  Block edge length, in decimal degrees for geographic coordinates or
  coordinate units (metres) for projected ones. Defaults to a size
  giving about `4 * v` blocks across the larger extent.

- buffer:

  Optional buffer distance in kilometres.

## Value

An `rset` of class `inv_spatial_block_cv` with columns `splits` and
`id`. Use
[`rsample::analysis()`](https://rsample.tidymodels.org/reference/as.data.frame.rsplit.html)
and
[`rsample::assessment()`](https://rsample.tidymodels.org/reference/as.data.frame.rsplit.html)
on the splits, or pass it to `tune::fit_resamples()`.

## References

Roberts, D. R., Bahn, V., Ciuti, S. et al. (2017). Cross-validation
strategies for data with temporal, spatial, hierarchical, or
phylogenetic structure. *Ecography*, 40, 913-929.
[doi:10.1111/ecog.02881](https://doi.org/10.1111/ecog.02881)

## Examples

``` r
set.seed(1)
folds <- inv_spatial_block_cv(inv_sdm_data, lon = lon, lat = lat, v = 5,
  block_size = 1)
folds
#> #  Spatial block cross-validation: 5 folds, block size 1
#> # A tibble: 5 × 2
#>   splits             id   
#>   <list>             <chr>
#> 1 <split [2403/597]> Fold1
#> 2 <split [2403/597]> Fold2
#> 3 <split [2403/597]> Fold3
#> 4 <split [2388/612]> Fold4
#> 5 <split [2403/597]> Fold5
rsample::assessment(folds$splits[[1]])
#> # A tibble: 597 × 8
#>       id   lon    lat  year presence    temp  rain forest
#>    <int> <dbl>  <dbl> <int> <fct>      <dbl> <dbl>  <dbl>
#>  1     4  143.  -7.56  2001 background  27.1  2858  0.238
#>  2    13  142.  -7.38  2012 background  27.8  2848  0.726
#>  3    15  141. -10.6   2018 background  27.5  2626  0.477
#>  4    19  141.  -8.83  2007 background  28.1  2341  0.161
#>  5    42  148.  -6.88  2005 background  26.9  3428  0.377
#>  6    43  147.  -6.67  2001 background  27.2  3276  0.305
#>  7    45  142. -10.4   2013 background  28.0  2452  0.349
#>  8    50  142.  -7.67  2013 background  27.7  2771  0.425
#>  9    52  142.  -8.37  2011 background  27.9  2609  0.381
#> 10    74  143.  -8.35  2005 background  28.1  2905  0.368
#> # ℹ 587 more rows
```
