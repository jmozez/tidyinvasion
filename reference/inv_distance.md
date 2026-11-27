# Distance from an origin

Adds the distance in kilometres from each record to an origin point,
using the haversine formula for geographic coordinates and Euclidean
distance (assuming metres) for projected coordinates.

## Usage

``` r
inv_distance(.data, origin, lon = NULL, lat = NULL, name = "distance_km")
```

## Arguments

- .data:

  A data frame,
  [`inv_occurrence()`](https://tidyinvasion.in4metrix.dev/reference/inv_occurrence.md)
  table or `sf` POINT layer.

- origin:

  Numeric vector of length two: the x (longitude) and y (latitude) of
  the origin.

- lon, lat:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Coordinate columns. Not needed for `<inv_occurrence>` or `sf` input.

- name:

  Name of the new column.

## Value

`.data` with an extra numeric column of distances in kilometres.

## Examples

``` r
# Distance of each cane toad record from the 1935 release at Gordonvale
inv_distance(cane_toad, origin = c(145.79, -17.10), lon = lon, lat = lat)
#> # A tibble: 6,680 × 12
#>    gbif_id    species          year month   lon   lat state      basis_of_record
#>    <chr>      <chr>           <int> <int> <dbl> <dbl> <chr>      <chr>          
#>  1 3779737797 Rhinella marina  1935     6  146. -17.1 Queensland OCCURRENCE     
#>  2 3778768717 Rhinella marina  1936    NA  146. -17.9 Queensland OCCURRENCE     
#>  3 3778772911 Rhinella marina  1936    NA  146. -17.1 Queensland OCCURRENCE     
#>  4 3779026696 Rhinella marina  1936    NA  146. -18.6 Queensland OCCURRENCE     
#>  5 3779308017 Rhinella marina  1936    NA  146. -16.9 Queensland OCCURRENCE     
#>  6 3779431297 Rhinella marina  1936    NA  146. -18.6 Queensland OCCURRENCE     
#>  7 3779762508 Rhinella marina  1936    NA  146. -17.2 Queensland OCCURRENCE     
#>  8 3779791887 Rhinella marina  1936    NA  146. -17.5 Queensland OCCURRENCE     
#>  9 3780084613 Rhinella marina  1936    NA  146. -18.2 Queensland OCCURRENCE     
#> 10 3780306368 Rhinella marina  1936    NA  146. -16.9 Queensland OCCURRENCE     
#> # ℹ 6,670 more rows
#> # ℹ 4 more variables: coordinate_uncertainty_m <dbl>, dataset_key <chr>,
#> #   licence <chr>, distance_km <dbl>
```
