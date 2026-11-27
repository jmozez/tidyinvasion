# Estimate detection probability and occupancy

Fits the constant single-season occupancy model of MacKenzie et al.
(2002) by maximum likelihood to repeated presence/absence surveys. It
separates the probability that a site is occupied (`psi`) from the
probability of detecting the species on one survey of an occupied site
(`p`), which is essential for surveillance of rare new incursions.

## Usage

``` r
inv_detection_prob(.data, surveys, .by = NULL, confidence = 0.95)
```

## Arguments

- .data:

  A data frame with one row per site and one column per survey.

- surveys:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Survey columns holding 1 (detected), 0 (not detected) or `NA` (not
  surveyed).

- .by:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional grouping columns, for example region or habitat.

- confidence:

  Target confidence used for `surveys_needed`.

## Value

A tibble with one row per group: `n_sites`, `n_surveys` (maximum per
site), `naive_occupancy`, `psi` and `psi_se`, `p` and `p_se`,
`cumulative_p` (probability of at least one detection across `n_surveys`
at an occupied site), `surveys_needed` (surveys required to be
`confidence` sure an undetected species is absent from an occupied site)
and `log_lik`.

## References

MacKenzie, D. I., Nichols, J. D., Lachman, G. B., Droege, S., Royle, J.
A. and Langtimm, C. A. (2002). Estimating site occupancy rates when
detection probabilities are less than one. *Ecology*, 83, 2248-2255.

## Examples

``` r
inv_detection_prob(inv_surveys, surveys = starts_with("visit"))
#> # A tibble: 1 × 10
#>   n_sites n_surveys naive_occupancy   psi psi_se     p   p_se cumulative_p
#>     <int>     <dbl>           <dbl> <dbl>  <dbl> <dbl>  <dbl>        <dbl>
#> 1     150         5           0.327 0.386 0.0483 0.344 0.0377        0.879
#> # ℹ 2 more variables: surveys_needed <dbl>, log_lik <dbl>
inv_detection_prob(inv_surveys, surveys = starts_with("visit"), .by = habitat)
#> # A tibble: 3 × 11
#>   habitat   n_sites n_surveys naive_occupancy   psi psi_se     p   p_se
#>   <chr>       <int>     <dbl>           <dbl> <dbl>  <dbl> <dbl>  <dbl>
#> 1 urban          48         5           0.312 0.349 0.0767 0.416 0.0671
#> 2 grassland      43         5           0.465 0.550 0.0980 0.339 0.0587
#> 3 forest         59         5           0.237 0.316 0.0863 0.263 0.0708
#> # ℹ 3 more variables: cumulative_p <dbl>, surveys_needed <dbl>, log_lik <dbl>
```
