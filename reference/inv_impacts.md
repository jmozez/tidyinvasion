# EICAT impact records (simulated)

Simulated impact records for 25 placeholder taxa (`taxon_01` to
`taxon_25`), with one to six records each. Mechanisms are the 12 EICAT
impact mechanisms; magnitudes (MC, MN, MO, MR, MV, DD) and confidence
are random draws. They are not real assessments.

## Usage

``` r
inv_impacts
```

## Format

A tibble with columns `species`, `mechanism`, `magnitude`, `confidence`
and `record_id`.

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
inv_eicat_score(inv_impacts, species, magnitude, mechanism, confidence)
#> # A tibble: 25 × 9
#>    species  n_records eicat_category eicat_score harmful max_mechanisms         
#>    <chr>        <int> <ord>                <int> <lgl>   <chr>                  
#>  1 taxon_04         6 MV                       5 TRUE    hybridisation          
#>  2 taxon_22         6 MR                       4 TRUE    grazing/herbivory/brow…
#>  3 taxon_05         6 MR                       4 TRUE    chemical impact on eco…
#>  4 taxon_09         6 MR                       4 TRUE    bio-fouling            
#>  5 taxon_23         5 MR                       4 TRUE    grazing/herbivory/brow…
#>  6 taxon_25         5 MR                       4 TRUE    interaction with other…
#>  7 taxon_01         4 MR                       4 TRUE    structural impact on e…
#>  8 taxon_16         4 MR                       4 TRUE    competition            
#>  9 taxon_18         5 MR                       4 TRUE    parasitism             
#> 10 taxon_02         6 MO                       3 TRUE    competition; hybridisa…
#> # ℹ 15 more rows
#> # ℹ 3 more variables: confidence <chr>, n_mechanisms <int>,
#> #   cumulative_score <dbl>
```
