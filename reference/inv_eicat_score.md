# EICAT impact classification

Assigns each alien taxon its Environmental Impact Classification for
Alien Taxa (EICAT) category from a table of impact records. Following
the IUCN standard, a taxon's category is the most severe impact
magnitude recorded for it across all mechanisms: Minimal Concern (MC),
Minor (MN), Moderate (MO), Major (MR) or Massive (MV). Taxa with only
Data Deficient (DD) records are DD. MO, MR and MV are harmful. A
cumulative score (sum over mechanisms of the highest score for each
mechanism, with MC = 1 to MV = 5) is also returned to rank taxa within a
category.

## Usage

``` r
inv_eicat_score(.data, species, magnitude, mechanism = NULL, confidence = NULL)
```

## Arguments

- .data:

  A data frame with one row per impact record.

- species:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the taxon.

- magnitude:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the impact magnitude, as codes (`"MC"`, `"MN"`, `"MO"`,
  `"MR"`, `"MV"`, `"DD"`) or names (`"Minimal Concern"`, `"Minor"`,
  `"Moderate"`, `"Major"`, `"Massive"`, `"Data Deficient"`), in any
  case.

- mechanism:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the impact mechanism (for example competition,
  predation, hybridisation).

- confidence:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the confidence of each record (`"low"`,
  `"medium"`, `"high"`).

## Value

A tibble with one row per taxon, sorted from most to least severe:
`n_records`, `eicat_category` (an ordered factor with `DD` as the lowest
level), `eicat_score` (1 to 5, `NA` for DD), `harmful`, `max_mechanisms`
(mechanisms with the highest magnitude), `confidence` (highest
confidence among records of the highest magnitude), `n_mechanisms` and
`cumulative_score`.

## References

Blackburn, T. M., Essl, F., Evans, T. et al. (2014). A unified
classification of alien species based on the magnitude of their
environmental impacts. *PLoS Biology*, 12, e1001850.
[doi:10.1371/journal.pbio.1001850](https://doi.org/10.1371/journal.pbio.1001850)

IUCN (2020). *IUCN EICAT Categories and Criteria*. First edition. IUCN,
Gland.
[doi:10.2305/iucn.ch.2020.05.en](https://doi.org/10.2305/iucn.ch.2020.05.en)

## Examples

``` r
inv_eicat_score(inv_impacts, species = species, magnitude = magnitude,
  mechanism = mechanism, confidence = confidence)
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
