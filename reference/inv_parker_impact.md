# Parker impact score

Computes the overall impact of an invader as the product of its range,
its abundance (density or cover per unit area) and its per-capita or
per-unit-biomass effect, `I = R * A * E` (Parker et al. 1999).

## Usage

``` r
inv_parker_impact(.data, range, abundance, effect, .by = NULL)
```

## Arguments

- .data:

  A data frame with one row per invader (or invader by region).

- range, abundance, effect:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Numeric columns with range size, abundance and per-capita effect.

- .by:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional grouping columns within which `relative_impact` and `rank`
  are computed.

## Value

`.data` as a tibble with added columns `impact`, `log10_impact`,
`relative_impact` (impact divided by the largest absolute impact within
the group) and `rank` (1 is the largest absolute impact).

## References

Parker, I. M., Simberloff, D., Lonsdale, W. M. et al. (1999). Impact:
toward a framework for understanding the ecological effects of invaders.
*Biological Invasions*, 1, 3-19.
[doi:10.1023/A:1010034312781](https://doi.org/10.1023/A%3A1010034312781)

## Examples

``` r
invaders <- data.frame(
  species = c("a", "b", "c"),
  range_km2 = c(1200, 300, 5000),
  density = c(4, 25, 0.5),
  effect = c(-0.02, -0.01, -0.3)
)
inv_parker_impact(invaders, range_km2, density, effect)
#> # A tibble: 3 × 8
#>   species range_km2 density effect impact log10_impact relative_impact  rank
#>   <chr>       <dbl>   <dbl>  <dbl>  <dbl>        <dbl>           <dbl> <int>
#> 1 a            1200     4    -0.02    -96         1.98          -0.128     2
#> 2 b             300    25    -0.01    -75         1.88          -0.1       3
#> 3 c            5000     0.5  -0.3    -750         2.88          -1         1
```
