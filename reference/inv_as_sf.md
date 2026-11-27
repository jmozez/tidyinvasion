# Convert an occurrence table to an sf layer

Convert an occurrence table to an sf layer

## Usage

``` r
inv_as_sf(x)
```

## Arguments

- x:

  An `<inv_occurrence>` tibble.

## Value

An `sf` POINT layer with the occurrence attributes. Requires the sf
package.

## Examples

``` r
occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year)
inv_as_sf(occ[1:5, ])
#> Simple feature collection with 5 features and 11 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 145.6678 ymin: -18.58165 xmax: 146.2511 ymax: -16.89845
#> Geodetic CRS:  WGS 84
#> # A tibble: 5 × 12
#>   gbif_id    species          year month   lon   lat state      basis_of_record
#> * <chr>      <chr>           <int> <int> <dbl> <dbl> <chr>      <chr>          
#> 1 3779737797 Rhinella marina  1935     6  146. -17.1 Queensland OCCURRENCE     
#> 2 3778768717 Rhinella marina  1936    NA  146. -17.9 Queensland OCCURRENCE     
#> 3 3778772911 Rhinella marina  1936    NA  146. -17.1 Queensland OCCURRENCE     
#> 4 3779026696 Rhinella marina  1936    NA  146. -18.6 Queensland OCCURRENCE     
#> 5 3779308017 Rhinella marina  1936    NA  146. -16.9 Queensland OCCURRENCE     
#> # ℹ 4 more variables: coordinate_uncertainty_m <dbl>, dataset_key <chr>,
#> #   licence <chr>, geometry <POINT [°]>
```
