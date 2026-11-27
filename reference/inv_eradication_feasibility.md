# Eradication feasibility

Projects an incursion under repeated control with a simple stochastic
removal model. Each year the population grows by `exp(growth_rate)` and
is searched `rounds` times; each individual (or patch) is found with
probability `detect_prob` per round and removed with probability
`efficacy` once found. The annual multiplier is
`lambda = exp(growth_rate) * (1 - detect_prob * efficacy)^rounds`, the
expected population after `t` years is `population * lambda^t`, and the
probability that no individual remains is `exp(-population * lambda^t)`
(Poisson approximation). Eradication is feasible only when `lambda < 1`.

## Usage

``` r
inv_eradication_feasibility(
  .data,
  population,
  growth_rate,
  detect_prob,
  efficacy = 1,
  rounds = 1,
  area = NULL,
  cost_per_unit = NULL,
  horizon = 10,
  target = 0.95
)
```

## Arguments

- .data:

  A data frame with one row per incursion or scenario.

- population:

  Initial number of individuals or patches.

- growth_rate:

  Intrinsic annual growth rate `r` (log scale).

- detect_prob:

  Probability of detecting an individual per search round.

- efficacy:

  Probability that a detected individual is removed.

- rounds:

  Search rounds per year.

- area:

  Optional infested area (for example in hectares), used for cost.

- cost_per_unit:

  Optional cost of one search round per unit `area`.

- horizon:

  Planning horizon in years for `p_eradicated`.

- target:

  Probability of eradication that defines success.

## Value

`.data` as a tibble with added columns `lambda`, `feasible`,
`min_rounds` (fewest rounds per year giving `lambda < 1`),
`years_to_target` (years until the eradication probability reaches
`target`, `Inf` when not feasible), `p_eradicated` (probability of
eradication within `horizon` years) and, when cost is given,
`total_cost` (cost of all rounds up to `years_to_target`).

## Details

Every argument after `.data` uses data masking, so each can be a column
of `.data` or a constant.

## References

Regan, T. J., McCarthy, M. A., Baxter, P. W. J., Panetta, F. D. and
Possingham, H. P. (2006). Optimal eradication: when to stop looking for
an invasive plant. *Ecology Letters*, 9, 759-766.
[doi:10.1111/j.1461-0248.2006.00920.x](https://doi.org/10.1111/j.1461-0248.2006.00920.x)

## Examples

``` r
scenarios <- data.frame(
  site = c("small", "medium", "large"),
  n0 = c(20, 400, 15000),
  ha = c(2, 50, 900)
)
inv_eradication_feasibility(scenarios, population = n0, growth_rate = 0.4,
  detect_prob = 0.6, efficacy = 0.95, rounds = 2, area = ha,
  cost_per_unit = 120)
#> # A tibble: 3 × 9
#>   site      n0    ha lambda feasible min_rounds years_to_target p_eradicated
#>   <chr>  <dbl> <dbl>  <dbl> <lgl>         <dbl>           <dbl>        <dbl>
#> 1 small     20     2  0.276 TRUE              1               5        1.000
#> 2 medium   400    50  0.276 TRUE              1               7        0.999
#> 3 large  15000   900  0.276 TRUE              1              10        0.962
#> # ℹ 1 more variable: total_cost <dbl>
```
