# Cane toad records in Australia (real data from GBIF)

Occurrence records of the cane toad (*Rhinella marina*) in Australia
from 1935, the year of its release at Gordonvale, Queensland (about
145.79 E, 17.10 S), to 2024. These are real records downloaded from the
GBIF occurrence API on 27 November 2026 with these filters: country
Australia, coordinates present, no geospatial issues, occurrence status
present, licence CC0 1.0 or CC BY 4.0. Records were then restricted to
coordinate uncertainty of 10 km or less (or not stated) and to specimen,
observation and occurrence records, and thinned to one record per 0.1
degree grid cell per year.

## Usage

``` r
cane_toad
```

## Format

A tibble with 6,680 rows and 11 columns:

- gbif_id:

  GBIF occurrence key. The record is at
  `https://www.gbif.org/occurrence/<gbif_id>`.

- species:

  Scientific name, `"Rhinella marina"`.

- year, month:

  Year and month of the record (month may be `NA`).

- lon, lat:

  Decimal longitude and latitude (WGS84).

- state:

  State or territory as given by the publisher.

- basis_of_record:

  GBIF basis of record.

- coordinate_uncertainty_m:

  Coordinate uncertainty in metres.

- dataset_key:

  GBIF key of the publishing dataset; see
  [cane_toad_sources](https://tidyinvasion.in4metrix.dev/reference/cane_toad_sources.md).

- licence:

  `"CC BY 4.0"` or `"CC0 1.0"`.

## Source

GBIF.org, GBIF Occurrence Search, <https://www.gbif.org>, accessed
through <https://api.gbif.org/v1/occurrence/search> on 27 November 2026.
Records are published by the 30 datasets listed in
[cane_toad_sources](https://tidyinvasion.in4metrix.dev/reference/cane_toad_sources.md)
under CC BY 4.0 or CC0 1.0. Credit those datasets when you use the data.
The download and cleaning code is in `data-raw/make_data.R` in the
package source.

## References

Phillips, B. L., Brown, G. P., Webb, J. K. and Shine, R. (2006).
Invasion and the evolution of speed in toads. *Nature*, 439, 803.
[doi:10.1038/439803a](https://doi.org/10.1038/439803a)

## Examples

``` r
cane_toad
#> # A tibble: 6,680 × 11
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
table(cane_toad$licence)
#> 
#> CC BY 4.0   CC0 1.0 
#>      6560       120 
```
