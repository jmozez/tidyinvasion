# Summarise propagule pressure

Propagule pressure combines the number of introduction events (propagule
number) and the number of individuals released per event (propagule
size). `inv_propagule_pressure()` summarises both for each group,
optionally discounting older events with an exponential decay so that
recent introductions weigh more.

## Usage

``` r
inv_propagule_pressure(
  .data,
  size = NULL,
  time = NULL,
  decay = NULL,
  .by = NULL
)
```

## Arguments

- .data:

  A data frame (or
  [`inv_pathway()`](https://tidyinvasion.in4metrix.dev/reference/inv_pathway.md)
  table) with one row per introduction event.

- size:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the number of individuals introduced per event. Defaults
  to the size column of an `<inv_pathway>` table.

- time:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the event time, used with `decay`.

- decay:

  Optional non-negative decay rate per time unit. When given, the column
  `pp_discounted` holds `sum(size * exp(-decay * (t_max - t)))`.

- .by:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional grouping columns. Grouped data frames are also respected.

## Value

A tibble with one row per group and columns `n_events` (propagule
number), `total_propagules`, `mean_size`, `median_size`, `cv_size`
(coefficient of variation of size), `max_size`, `pp_index`
(`log10(1 + total_propagules)`) and, when `decay` is set,
`pp_discounted`.

## References

Lockwood, J. L., Cassey, P. and Blackburn, T. (2005). The role of
propagule pressure in explaining species invasions. *Trends in Ecology
and Evolution*, 20, 223-228.
[doi:10.1016/j.tree.2005.02.004](https://doi.org/10.1016/j.tree.2005.02.004)

## Examples

``` r
inv_propagule_pressure(inv_introductions, size = propagule_size, .by = pathway)
#> # A tibble: 6 × 8
#>   pathway     n_events total_propagules mean_size median_size cv_size max_size
#>   <chr>          <int>            <dbl>     <dbl>       <dbl>   <dbl>    <dbl>
#> 1 stowaway          59              331      5.61         4     0.864       23
#> 2 escape            55              867     15.8         10     1.08        78
#> 3 corridor          23              269     11.7          9     0.861       35
#> 4 release           43             1774     41.3         35     0.771      123
#> 5 contaminant       36              244      6.78         4.5   0.907       25
#> 6 unaided           24              103      4.29         2.5   1.07        21
#> # ℹ 1 more variable: pp_index <dbl>

# Discount older introductions by 10% per year
inv_propagule_pressure(inv_introductions, size = propagule_size,
  time = year, decay = 0.1, .by = species)
#> # A tibble: 20 × 9
#>    species n_events total_propagules mean_size median_size cv_size max_size
#>    <chr>      <int>            <dbl>     <dbl>       <dbl>   <dbl>    <dbl>
#>  1 sp14          11              129     11.7          3     1.60        63
#>  2 sp09          10              154     15.4          8     1.33        58
#>  3 sp03          14              195     13.9          7.5   1.31        67
#>  4 sp18          14              337     24.1          6     1.50       123
#>  5 sp13          10              149     14.9         14.5   0.754       33
#>  6 sp12          15              207     13.8          6     0.974       43
#>  7 sp08          16              186     11.6          5     1.91        91
#>  8 sp06          13              185     14.2         11     0.999       45
#>  9 sp07           9              113     12.6          6     1.48        61
#> 10 sp16           7               76     10.9         14     0.726       20
#> 11 sp02          14              187     13.4          3.5   1.58        78
#> 12 sp10          14              219     15.6          8     1.21        72
#> 13 sp11          12              167     13.9          9.5   1.08        57
#> 14 sp20           6               29      4.83         3     0.983       12
#> 15 sp05          15              195     13           10     0.881       47
#> 16 sp17          14              176     12.6          5.5   1.39        58
#> 17 sp04          11              254     23.1          9     1.47       113
#> 18 sp01          17              317     18.6         10     1.41        92
#> 19 sp19          12              262     21.8          4.5   1.55       105
#> 20 sp15           6               51      8.5          4     1.23        27
#> # ℹ 2 more variables: pp_index <dbl>, pp_discounted <dbl>
```
