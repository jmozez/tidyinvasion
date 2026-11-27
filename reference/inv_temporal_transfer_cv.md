# Temporal transfer cross-validation

Forward-chaining resampling for invasion data: each resample trains on
records up to a time period and assesses on the following period(s), so
models are always evaluated on their ability to predict the future of an
invasion, never the past. With `cumulative = TRUE` the analysis window
grows; otherwise it slides with a fixed width of `initial` periods.

## Usage

``` r
inv_temporal_transfer_cv(
  .data,
  time = NULL,
  initial = 5,
  assess = 1,
  gap = 0,
  cumulative = TRUE
)
```

## Arguments

- .data:

  A data frame or
  [`inv_occurrence()`](https://tidyinvasion.in4metrix.dev/reference/inv_occurrence.md)
  table.

- time:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Time column. Defaults to the time column of an `<inv_occurrence>`.

- initial:

  Number of distinct time periods in the first analysis set.

- assess:

  Number of time periods in each assessment set.

- gap:

  Number of time periods left out between analysis and assessment sets,
  to avoid leakage between adjacent periods.

- cumulative:

  Should the analysis set grow (`TRUE`) or slide (`FALSE`)?

## Value

An `rset` of class `inv_temporal_transfer_cv` with columns `splits` and
`id`.

## Examples

``` r
slices <- inv_temporal_transfer_cv(inv_sdm_data, time = year, initial = 10,
  assess = 3)
slices
#> #  Temporal transfer cross-validation: 3 slices, growing window, assess 3, gap 0
#> # A tibble: 3 × 2
#>   splits             id    
#>   <list>             <chr> 
#> 1 <split [1407/416]> Slice1
#> 2 <split [1823/467]> Slice2
#> 3 <split [2290/409]> Slice3
```
