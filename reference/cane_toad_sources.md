# Datasets behind the cane toad records

The GBIF datasets that published the records in
[cane_toad](https://tidyinvasion.in4metrix.dev/reference/cane_toad.md),
with their title, publisher, licence, DOI and the number of records each
contributed. Real metadata from the GBIF dataset and organisation APIs.

## Usage

``` r
cane_toad_sources
```

## Format

A tibble with 30 rows and 6 columns: `dataset_key`, `title`,
`publisher`, `licence`, `doi` and `n_records`.

## Source

GBIF registry API, <https://api.gbif.org/v1/dataset/>, accessed 27
November 2026.

## Examples

``` r
cane_toad_sources
#> # A tibble: 30 × 6
#>    dataset_key                          title  publisher licence doi   n_records
#>    <chr>                                <chr>  <chr>     <chr>   <chr>     <int>
#>  1 e4473544-f4cd-4429-b791-39d6e1fdb0a4 WildN… Queensla… CC BY … 10.1…      3953
#>  2 358fbd61-739f-4102-afc9-9d468f571e4d Fauna… Northern… CC BY … 10.1…       892
#>  3 0645ccdb-e001-4ab0-9729-51f1755e007e NSW B… NSW Depa… CC BY … 10.1…       508
#>  4 50c9509d-22c7-4a22-a47d-8c48425ef4a7 iNatu… iNatural… CC BY … 10.1…       432
#>  5 19729f12-88c3-4e56-a84f-b42a5cf052ad AWC E… Australi… CC BY … 10.1…       388
#>  6 a79c2b50-6c8a-11de-8226-b8a03c50a862 Queen… Queensla… CC BY … 10.1…       220
#>  7 dce8feb0-6c89-11de-8225-b8a03c50a862 Austr… Australi… CC BY … 10.1…        65
#>  8 84a649ce-ff81-420d-9c41-aa1de59e3766 ALA s… Atlas of… CC BY … 10.1…        54
#>  9 4c313e80-c48b-4fc8-bd19-d8226b0a6921 Dandj… Atlas of… CC BY … 10.1…        34
#> 10 0debafd0-6c8a-11de-8225-b8a03c50a862 Austr… Commonwe… CC BY … 10.1…        24
#> # ℹ 20 more rows
```
