# Fit an establishment dose-response model

Estimates the probability that an introduction establishes as a function
of propagule size by maximum likelihood. Three models are available:

## Usage

``` r
inv_establishment_prob(
  .data,
  established,
  propagules,
  model = c("exponential", "weibull", "logistic"),
  conf_level = 0.95
)
```

## Arguments

- .data:

  A data frame with one row per introduction event.

- established:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the outcome: logical, 0/1 or a two-level factor (first
  level is success).

- propagules:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with propagule size (positive numbers).

- model:

  One of `"exponential"`, `"weibull"` or `"logistic"`.

- conf_level:

  Confidence level for intervals.

## Value

An object of class `inv_establishment`, a list with the fitted
parameters, their variance-covariance matrix, the log-likelihood, AIC,
`n50` (the propagule size giving 50% establishment) and the data used.
Use [`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html),
[`augment()`](https://generics.r-lib.org/reference/augment.html),
[`predict()`](https://rdrr.io/r/stats/predict.html) and
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) on
it.

## Details

- `"exponential"`: `P(N) = 1 - exp(-alpha * N)`, where each propagule
  establishes independently with probability `alpha` (no Allee effect).

- `"weibull"`: `P(N) = 1 - exp(-alpha * N^c)` (Leung et al. 2004).
  `c > 1` indicates an Allee effect, `c < 1` diminishing returns.

- `"logistic"`: `logit P(N) = b0 + b1 * log(N)`.

The binomial likelihood is maximised with
[`stats::optim()`](https://rdrr.io/r/stats/optim.html) on an
unconstrained scale; standard errors come from the numerical Hessian.

## References

Leung, B., Drake, J. M. and Lodge, D. M. (2004). Predicting invasions:
propagule pressure and the gravity of Allee effects. *Ecology*, 85,
1651-1660. [doi:10.1890/02-0571](https://doi.org/10.1890/02-0571)

## Examples

``` r
fit <- inv_establishment_prob(inv_introductions, established, propagule_size,
  model = "weibull")
fit
#> <inv_establishment> weibull dose-response model
#> 240 introduction events, log-likelihood -79.706
#> Estimates: alpha = 0.009128, c = 1.538
#> Propagules for 50% establishment: 16.71
tidy(fit)
#> # A tibble: 2 × 5
#>   term  estimate std.error conf.low conf.high
#>   <chr>    <dbl>     <dbl>    <dbl>     <dbl>
#> 1 alpha  0.00913   0.00504  0.00310    0.0269
#> 2 c      1.54      0.191    1.21       1.96  
glance(fit)
#> # A tibble: 1 × 7
#>   model       n logLik   AIC   BIC   n50 converged
#>   <chr>   <int>  <dbl> <dbl> <dbl> <dbl> <lgl>    
#> 1 weibull   240  -79.7  163.  170.  16.7 TRUE     
predict(fit, data.frame(propagule_size = c(1, 10, 100)))
#> # A tibble: 3 × 2
#>   propagules   .pred
#>        <dbl>   <dbl>
#> 1          1 0.00909
#> 2         10 0.270  
#> 3        100 1.000  
```
