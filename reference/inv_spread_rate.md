# Estimate the rate of spatial spread

Estimates the radial rate of spread of an invasion from dated occurrence
records with three established methods:

## Usage

``` r
is_inv_spread(x)

inv_spread_rate(
  .data,
  time = NULL,
  lon = NULL,
  lat = NULL,
  origin = NULL,
  method = c("front", "first_record", "area"),
  quantile = 1,
  cell_size = 0.5,
  min_records = 1,
  conf_level = 0.95
)
```

## Arguments

- x:

  An object to test.

- .data:

  A data frame,
  [`inv_occurrence()`](https://tidyinvasion.in4metrix.dev/reference/inv_occurrence.md)
  table or `sf` POINT layer with dated records.

- time:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the record time (numeric year, `Date` or `POSIXct`).
  Defaults to the time column of an `<inv_occurrence>`.

- lon, lat:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Coordinate columns.

- origin:

  Numeric vector of length two giving the introduction point. Defaults
  to the mean location of the earliest records.

- method:

  One of `"front"`, `"first_record"` or `"area"`.

- quantile:

  Quantile of distances used as the range front with `method = "front"`.
  Values below 1 reduce the effect of outlying records.

- cell_size:

  Grid cell size for `method = "first_record"`, in decimal degrees for
  geographic data or coordinate units for projected data.

- min_records:

  Minimum cumulative number of records for a time step to be used.

- conf_level:

  Confidence level for the rate interval in
  [`glance()`](https://generics.r-lib.org/reference/glance.html).

## Value

An `<inv_spread>` tibble with columns `time`, `distance_km` (radius or
cell distance) and `n` (records contributing). The fitted linear model
is stored in the metadata;
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
[`glance()`](https://generics.r-lib.org/reference/glance.html) return
the spread rate in km per time unit and
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws it.

## Details

- `"front"`: for each time step, the range radius is the `quantile` of
  distances from the origin of all records up to that time (the maximum
  when `quantile = 1`). The rate is the slope of radius on time.

- `"first_record"`: records are gridded into cells of `cell_size`; each
  cell is dated by its first record and its distance is that of its
  nearest first-year record. The rate is the slope of distance on first
  record time, the distance regression method (Gilbert et al. 2004).

- `"area"`: the cumulative occupied area is the convex hull of all
  records up to each time, converted to an equivalent radius
  `sqrt(area / pi)` (Skellam 1951). The rate is the slope of radius on
  time.

## References

Gilbert, M., Gregoire, J.-C., Freise, J. F. and Heitland, W. (2004).
Long-distance dispersal and human population density allow the
prediction of invasive patterns in the horse chestnut leafminer
*Cameraria ohridella*. *Journal of Animal Ecology*, 73, 459-468.
[doi:10.1111/j.0021-8790.2004.00820.x](https://doi.org/10.1111/j.0021-8790.2004.00820.x)

Skellam, J. G. (1951). Random dispersal in theoretical populations.
*Biometrika*, 38, 196-218.
[doi:10.1093/biomet/38.1-2.196](https://doi.org/10.1093/biomet/38.1-2.196)

## Examples

``` r
occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
spread <- inv_spread_rate(occ, origin = c(145.79, -17.10), quantile = 0.95)
spread
#> # A <inv_spread>: 90 × 3
#> # Method:         front
#> # Origin:         145.79, -17.1
#> # Rate:           7.014 km per time
#>     time distance_km     n
#>    <dbl>       <dbl> <int>
#>  1  1935       0.616     1
#>  2  1936     172.       10
#>  3  1937    1113.       32
#>  4  1938    1125.       37
#>  5  1939    1122.       42
#>  6  1940    1124.       60
#>  7  1941    1124.       63
#>  8  1942    1124.       65
#>  9  1943    1130.       67
#> 10  1944    1140.       78
#> # ℹ 80 more rows
glance(spread)
#> # A tibble: 1 × 10
#>   method rate_km std.error conf.low conf.high r.squared  p.value     n origin_x
#>   <chr>    <dbl>     <dbl>    <dbl>     <dbl>     <dbl>    <dbl> <int>    <dbl>
#> 1 front     7.01     0.669     5.68      8.34     0.555 3.64e-17    90     146.
#> # ℹ 1 more variable: origin_y <dbl>

inv_spread_rate(occ, origin = c(145.79, -17.10), method = "first_record")
#> # A <inv_spread>: 544 × 4
#> # Method:         first_record
#> # Origin:         145.79, -17.1
#> # Rate:           13.83 km per time
#>    cell     time distance_km     n
#>    <chr>   <dbl>       <dbl> <int>
#>  1 291_-35  1935       0.616    97
#>  2 291_-34  1936      21.0      70
#>  3 291_-36  1936      93.7      63
#>  4 291_-37  1936     125.       17
#>  5 292_-36  1936      54.6      28
#>  6 292_-38  1936     171.       34
#>  7 290_-33  1937      83.7      39
#>  8 290_-34  1937      44.6      70
#>  9 292_-35  1937      53.6       9
#> 10 294_-40  1937     302.       14
#> # ℹ 534 more rows
```
