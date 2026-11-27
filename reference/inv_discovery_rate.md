# Rate of introduction from first records, allowing for discovery effort

The number of alien species first recorded each year rises with both the
rate of introduction and the effort put into finding them. Solow and
Costello (2004) separate the two: species arrive at rate \\\mu_t =
\exp(\beta_0 + \beta_1 t)\\, and each undiscovered species is found in
year `t` with probability \\\pi_t = \mathrm{logit}^{-1}(\gamma_0 +
\gamma_1 t)\\, so the expected first records in year `t` are \\\lambda_t
= \sum\_{s \le t} \mu_s \pi_t \prod\_{r=s}^{t-1}(1 - \pi_r)\\. The four
parameters are fitted by Poisson maximum likelihood. A positive `beta_1`
means introductions are accelerating even after allowing for growing
discovery effort; a positive `gamma_1` means detection has improved.

Time runs from the first year in the data, so years before the first
record are included only when given as rows with a count of zero. The
two rates are only weakly separable with short records; check the widths
of the intervals.

## Usage

``` r
inv_discovery_rate(.data, year, count = NULL, conf_level = 0.95)
```

## Arguments

- .data:

  A data frame with one row per species (with the year of its first
  record) or one row per year (with a count).

- year:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the year.

- count:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the number of first records in each year. Without
  it each row is one species.

- conf_level:

  Confidence level of the Wald intervals.

## Value

A tibble of class `inv_discovery` with one row per year: `year`,
`observed`, `expected` (fitted first records), `introduced` (estimated
introductions) and `detection` (discovery probability). The attribute
`"coefficients"` holds a tibble of the four parameters with standard
errors and intervals, and `"undiscovered"` the expected number of
species introduced but not yet recorded by the last year.

## References

Solow, A. R. and Costello, C. J. (2004). Estimating the rate of species
introductions from the discovery record. Ecology, 85, 1822-1825.
[doi:10.1890/03-3102](https://doi.org/10.1890/03-3102)

## Examples

``` r
set.seed(4)
yrs <- 1900:2000
mu <- exp(-1 + 0.025 * (yrs - 1900))
pi_t <- plogis(-3 + 0.03 * (yrs - 1900))
# Undiscovered species accumulate and are found with probability pi_t
pool <- 0
lam <- numeric(length(yrs))
for (t in seq_along(yrs)) {
  pool <- pool + mu[t]
  lam[t] <- pool * pi_t[t]
  pool <- pool * (1 - pi_t[t])
}
records <- data.frame(year = yrs, n = rpois(length(yrs), lam))
fit <- inv_discovery_rate(records, year, count = n)
attr(fit, "coefficients")
#> # A tibble: 4 × 5
#>   term    estimate std_error conf_low conf_high
#>   <chr>      <dbl>     <dbl>    <dbl>     <dbl>
#> 1 beta_0   -0.245     2.30    -4.75      4.26  
#> 2 beta_1    0.0158    0.0206  -0.0246    0.0562
#> 3 gamma_0  -2.98      2.12    -7.13      1.16  
#> 4 gamma_1   0.0147    0.0953  -0.172     0.201 
```
