# Biotic homogenisation

Measures whether alien species make communities more similar to each
other. Mean pairwise Jaccard and Sorensen similarity among sites is
computed for the native assemblage alone and for the current assemblage
(native plus alien species). A positive change means homogenisation and
a negative change differentiation (Olden and Rooney 2006).

## Usage

``` r
inv_homogenization(.data, site, species, status, native = "native", .by = NULL)
```

## Arguments

- .data:

  A long data frame with one row per species occurrence at a site.

- site, species, status:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Columns identifying the site, the species and its status.

- native:

  Value of `status` marking native species. Any other value is treated
  as alien.

- .by:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional grouping columns, for example region.

## Value

A tibble with one row per group: `n_sites`, `n_native`, `n_alien`,
`jaccard_native`, `jaccard_current`, `delta_jaccard`, `sorensen_native`,
`sorensen_current`, `delta_sorensen` and `homogenised`
(`delta_jaccard > 0`). Sites without native species are kept with an
empty native assemblage; pairs of empty assemblages are ignored.

## References

Olden, J. D. and Rooney, T. P. (2006). On defining and quantifying
biotic homogenization. *Global Ecology and Biogeography*, 15, 113-120.
[doi:10.1111/j.1466-822x.2006.00214.x](https://doi.org/10.1111/j.1466-822x.2006.00214.x)

## Examples

``` r
inv_homogenization(inv_communities, site = site, species = species,
  status = status, .by = region)
#> # A tibble: 3 × 11
#>   region   n_sites n_native n_alien jaccard_native jaccard_current delta_jaccard
#>   <chr>      <int>    <int>   <int>          <dbl>           <dbl>         <dbl>
#> 1 region_1      12       40      10          0.189           0.261        0.0726
#> 2 region_2      12       39      10          0.190           0.256        0.0665
#> 3 region_3      12       40      10          0.175           0.253        0.0771
#> # ℹ 4 more variables: sorensen_native <dbl>, sorensen_current <dbl>,
#> #   delta_sorensen <dbl>, homogenised <lgl>
```
