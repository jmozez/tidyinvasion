# Fit dispersal kernels

Fits one or more distance kernels to observed dispersal distances by
maximum likelihood and ranks them by AIC. The kernels describe the
probability density of dispersal distance and differ in the weight of
their tail: the half-normal is thin-tailed, the exponential has a
standard tail and the Weibull (shape below 1), lognormal and gamma can
be fat-tailed, which drives accelerating spread.

## Usage

``` r
inv_dispersal_kernel(
  .data,
  distance,
  family = kernel_families(),
  weights = NULL
)
```

## Arguments

- .data:

  A data frame with one row per dispersal event.

- distance:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with positive dispersal distances.

- family:

  Character vector of kernels to fit: any of `"exponential"`,
  `"halfnormal"`, `"weibull"`, `"lognormal"`, `"gamma"`.

- weights:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column of frequency weights (for example, the number of seeds
  trapped at a distance).

## Value

An object of class `inv_kernel` with one fit per family, ordered by AIC.
Use [`tidy()`](https://generics.r-lib.org/reference/tidy.html) for
parameter estimates,
[`glance()`](https://generics.r-lib.org/reference/glance.html) for model
comparison (log-likelihood, AIC, Akaike weights, mean and 99th
percentile dispersal distance),
[`augment()`](https://generics.r-lib.org/reference/augment.html) for
fitted densities and
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
for density and tail plots.

## References

Nathan, R., Klein, E., Robledo-Arnuncio, J. J. and Revilla, E. (2012).
Dispersal kernels: review. In *Dispersal Ecology and Evolution*, Oxford
University Press, 187-210.

## Examples

``` r
k <- inv_dispersal_kernel(
  dplyr::filter(inv_dispersal, species == "sp_a"), distance = distance_m
)
glance(k)
#> # A tibble: 5 × 11
#>   family          n n_par logLik   AIC   BIC delta_AIC   weight mean_distance
#>   <chr>       <int> <int>  <dbl> <dbl> <dbl>     <dbl>    <dbl>         <dbl>
#> 1 weibull       300     2 -1623. 3250. 3258.       0   9.97e- 1          93.6
#> 2 gamma         300     2 -1629. 3262. 3270.      12.0 2.50e- 3          95.0
#> 3 lognormal     300     2 -1631. 3266. 3274.      15.9 3.44e- 4         140. 
#> 4 exponential   300     1 -1666. 3335. 3338.      84.4 4.75e-19          95.0
#> 5 halfnormal    300     1 -1768. 3537. 3541.     287.  4.99e-63         140. 
#> # ℹ 2 more variables: q99_distance <dbl>, converged <lgl>
tidy(k)
#> # A tibble: 8 × 4
#>   family      term     estimate std.error
#>   <chr>       <chr>       <dbl>     <dbl>
#> 1 weibull     shape     0.690    0.0305  
#> 2 weibull     scale    72.9      6.44    
#> 3 gamma       shape     0.580    0.0396  
#> 4 gamma       rate      0.00610  0.000623
#> 5 lognormal   meanlog   3.48     0.0985  
#> 6 lognormal   sdlog     1.71     0.0697  
#> 7 exponential scale    95.0      5.49    
#> 8 halfnormal  sigma   175.       7.15    
```
