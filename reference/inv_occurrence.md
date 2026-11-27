# Create an invasion occurrence table

`inv_occurrence()` turns a data frame of species records into an
`<inv_occurrence>` tibble. The class remembers which columns hold the
coordinates, time and species, and whether coordinates are geographic.
Spread, distance, plotting and resampling functions read these columns
automatically. The class survives `dplyr` verbs such as
[`filter()`](https://dplyr.tidyverse.org/reference/filter.html),
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) and
[`arrange()`](https://dplyr.tidyverse.org/reference/arrange.html);
dropping a coordinate column returns a plain tibble.

## Usage

``` r
inv_occurrence(
  .data,
  lon = NULL,
  lat = NULL,
  time = NULL,
  species = NULL,
  crs = 4326
)

is_inv_occurrence(x)
```

## Arguments

- .data:

  A data frame, tibble or `sf` POINT layer. For `sf` input the
  coordinates are extracted (and transformed to WGS84 when the layer has
  a geographic or missing CRS) into `lon` and `lat` columns and the
  geometry is dropped.

- lon, lat:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Columns holding longitude and latitude in decimal degrees, or x and y
  for projected coordinates. Ignored for `sf` input.

- time:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the record date or year (numeric, `Date` or
  `POSIXct`).

- species:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with taxon names.

- crs:

  Coordinate reference system of `lon` and `lat`, as an EPSG code or
  string. Geographic coordinates (`4326`, `"EPSG:4326"`, `"OGC:CRS84"`)
  use great-circle distances; anything else is treated as projected with
  coordinates in metres.

- x:

  An object to test.

## Value

An `<inv_occurrence>` tibble with the same rows and columns as `.data`.
`is_inv_occurrence()` returns a single logical.

## Examples

``` r
occ <- inv_occurrence(cane_toad, lon = lon, lat = lat, time = year,
  species = species)
occ
#> # A <inv_occurrence>: 6,680 × 11
#> # Coordinates:        lon, lat (EPSG:4326)
#> # Time:               year
#> # Species:            Rhinella marina
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
#> # ℹ 3 more variables: coordinate_uncertainty_m <dbl>, dataset_key <chr>,
#> #   licence <chr>

# The class is kept through dplyr verbs
dplyr::filter(occ, year < 1960)
#> # A <inv_occurrence>: 266 × 11
#> # Coordinates:        lon, lat (EPSG:4326)
#> # Time:               year
#> # Species:            Rhinella marina
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
#> # ℹ 256 more rows
#> # ℹ 3 more variables: coordinate_uncertainty_m <dbl>, dataset_key <chr>,
#> #   licence <chr>
```
