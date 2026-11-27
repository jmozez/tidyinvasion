# SEICAT socio-economic impact classification

Assigns each alien taxon its Socio-Economic Impact Classification of
Alien Taxa (SEICAT) category from a table of impact records (Bacher et
al. 2018), the counterpart of
[`inv_eicat_score()`](https://tidyinvasion.in4metrix.dev/reference/inv_eicat_score.md)
for impacts on human well-being (safety, material and immaterial assets,
health, and social, spiritual and cultural relations). As in the IUCN
scheme, the category is the most severe magnitude recorded: Minimal
Concern (MC), Minor (MN), Moderate (MO), Major (MR) or Massive (MV); MO
and above are harmful.

## Usage

``` r
inv_seicat_score(
  .data,
  species,
  magnitude,
  mechanism = NULL,
  confidence = NULL
)
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
  Optional column with the constituent of well-being affected.

- confidence:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the confidence of each record (`"low"`,
  `"medium"`, `"high"`).

## Value

As
[`inv_eicat_score()`](https://tidyinvasion.in4metrix.dev/reference/inv_eicat_score.md),
with `seicat_category` and `seicat_score`.

## References

Bacher, S., Blackburn, T. M., Essl, F., Genovesi, P., Heikkila, J.,
Jeschke, J. M., Jones, G., Keller, R., Kenis, M., Kueffer, C., Martinou,
A. F., Nentwig, W., Pergl, J., Pysek, P., Rabitsch, W., Richardson, D.
M., Roy, H. E., Saul, W.-C., Scalera, R., Vila, M., Wilson, J. R. U. and
Kumschick, S. (2018). Socio-economic impact classification of alien taxa
(SEICAT). Methods in Ecology and Evolution, 9, 159-168.
[doi:10.1111/2041-210X.12844](https://doi.org/10.1111/2041-210X.12844)

## Examples

``` r
records <- data.frame(
  species = c("sp01", "sp01", "sp02", "sp03"),
  magnitude = c("MN", "MR", "MC", "DD"),
  mechanism = c("health", "material assets", "safety", "health")
)
inv_seicat_score(records, species, magnitude, mechanism)
#> # A tibble: 3 × 9
#>   species n_records seicat_category seicat_score harmful max_mechanisms 
#>   <chr>       <int> <ord>                  <int> <lgl>   <chr>          
#> 1 sp01            2 MR                         4 TRUE    material assets
#> 2 sp02            1 MC                         1 FALSE   safety         
#> 3 sp03            1 DD                        NA FALSE   NA             
#> # ℹ 3 more variables: confidence <chr>, n_mechanisms <int>,
#> #   cumulative_score <dbl>
```
