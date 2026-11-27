# Horizon scanning for invasion risk

Combines expert scores for candidate species into an overall risk score
and rank, following the consensus approach of Roy et al. (2014). Scores
for criteria such as likelihood of arrival, establishment, spread and
impact are combined by product, geometric mean or sum. With several
assessors, scores are first aggregated by the median for each species
and criterion and their spread is reported as a measure of disagreement.

## Usage

``` r
inv_horizon_scan(
  .data,
  ...,
  species,
  assessor = NULL,
  method = c("product", "geometric_mean", "sum"),
  score_range = c(1, 5),
  thresholds = c(1/3, 2/3)
)
```

## Arguments

- .data:

  A data frame with one row per species (or per species and assessor).

- ...:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Criterion columns with numeric scores.

- species:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the species.

- assessor:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the assessor.

- method:

  How to combine criteria: `"product"`, `"geometric_mean"` or `"sum"`.

- score_range:

  Numeric vector of length two with the minimum and maximum possible
  score of each criterion. Used to scale the overall score to 0 to 1.

- thresholds:

  Two cut points on the scaled score separating `"low"`, `"medium"` and
  `"high"` priority.

## Value

A tibble with one row per species, sorted by rank: the median score for
each criterion, `n_assessors`, `disagreement` (mean across criteria of
the standard deviation among assessors; `NA` with one assessor),
`score`, `scaled_score`, `rank` and `priority`.

## References

Roy, H. E., Peyton, J., Aldridge, D. C. et al. (2014). Horizon scanning
for invasive alien species with the potential to threaten biodiversity
in Great Britain. *Global Change Biology*, 20, 3859-3871.
[doi:10.1111/gcb.12603](https://doi.org/10.1111/gcb.12603)

## Examples

``` r
inv_horizon_scan(inv_horizon, arrival, establishment, impact,
  species = species, assessor = assessor)
#> # A tibble: 30 × 10
#>    species arrival establishment impact n_assessors disagreement score
#>    <chr>     <dbl>         <dbl>  <dbl>       <int>        <dbl> <dbl>
#>  1 cand_22     4.5           4.5    5             4        0.678 101. 
#>  2 cand_04     4             4.5    4.5           4        0.552  81  
#>  3 cand_15     4             5      4             4        0.605  80  
#>  4 cand_07     5             4      3.5           4        0.652  70  
#>  5 cand_17     4             5      3.5           4        0.652  70  
#>  6 cand_06     4.5           3      5             4        0.359  67.5
#>  7 cand_23     4.5           5      3             4        0.652  67.5
#>  8 cand_24     5             4      3             4        0.605  60  
#>  9 cand_25     3             3      5             4        0.605  45  
#> 10 cand_12     3             3.5    4             4        0.863  42  
#> # ℹ 20 more rows
#> # ℹ 3 more variables: scaled_score <dbl>, rank <int>, priority <ord>
```
