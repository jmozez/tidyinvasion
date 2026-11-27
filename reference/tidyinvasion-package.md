# tidyinvasion: tidy tools for invasion biology

tidyinvasion covers the invasion process from introduction to impact.
Functions are grouped by stage:

## Details

- **Classes**:
  [`inv_occurrence()`](https://tidyinvasion.in4metrix.dev/reference/inv_occurrence.md),
  [`inv_pathway()`](https://tidyinvasion.in4metrix.dev/reference/inv_pathway.md)
  and the `inv_spread` tibble returned by
  [`inv_spread_rate()`](https://tidyinvasion.in4metrix.dev/reference/inv_spread_rate.md).

- **Introduction**:
  [`inv_propagule_pressure()`](https://tidyinvasion.in4metrix.dev/reference/inv_propagule_pressure.md),
  [`inv_establishment_prob()`](https://tidyinvasion.in4metrix.dev/reference/inv_establishment_prob.md),
  [`inv_detection_prob()`](https://tidyinvasion.in4metrix.dev/reference/inv_detection_prob.md).

- **Spread**:
  [`inv_distance()`](https://tidyinvasion.in4metrix.dev/reference/inv_distance.md),
  [`inv_spread_rate()`](https://tidyinvasion.in4metrix.dev/reference/inv_spread_rate.md),
  [`inv_dispersal_kernel()`](https://tidyinvasion.in4metrix.dev/reference/inv_dispersal_kernel.md),
  [`inv_lag_phase()`](https://tidyinvasion.in4metrix.dev/reference/inv_lag_phase.md).

- **Impact**:
  [`inv_impact_metrics()`](https://tidyinvasion.in4metrix.dev/reference/inv_impact_metrics.md),
  [`inv_parker_impact()`](https://tidyinvasion.in4metrix.dev/reference/inv_parker_impact.md),
  [`inv_homogenization()`](https://tidyinvasion.in4metrix.dev/reference/inv_homogenization.md),
  [`inv_eicat_score()`](https://tidyinvasion.in4metrix.dev/reference/inv_eicat_score.md).

- **Biosecurity**:
  [`inv_eradication_feasibility()`](https://tidyinvasion.in4metrix.dev/reference/inv_eradication_feasibility.md),
  [`inv_horizon_scan()`](https://tidyinvasion.in4metrix.dev/reference/inv_horizon_scan.md).

- **tidymodels**:
  [`step_inv_background()`](https://tidyinvasion.in4metrix.dev/reference/step_inv_background.md),
  [`step_inv_propagule_lags()`](https://tidyinvasion.in4metrix.dev/reference/step_inv_propagule_lags.md),
  [`step_inv_env_distance()`](https://tidyinvasion.in4metrix.dev/reference/step_inv_env_distance.md),
  [`inv_spatial_block_cv()`](https://tidyinvasion.in4metrix.dev/reference/inv_spatial_block_cv.md),
  [`inv_temporal_transfer_cv()`](https://tidyinvasion.in4metrix.dev/reference/inv_temporal_transfer_cv.md),
  [`boyce_index()`](https://tidyinvasion.in4metrix.dev/reference/boyce_index.md),
  [`tss()`](https://tidyinvasion.in4metrix.dev/reference/tss.md),
  [`inv_sdm()`](https://tidyinvasion.in4metrix.dev/reference/inv_sdm.md),
  [`inv_reaction_diffusion()`](https://tidyinvasion.in4metrix.dev/reference/inv_reaction_diffusion.md).

Distances use the haversine formula for geographic coordinates and
Euclidean distance for projected coordinates, and all likelihoods are
maximised with [`stats::optim()`](https://rdrr.io/r/stats/optim.html),
so no compiled spatial libraries are needed. `sf` point layers are
accepted when the sf package is installed.

## See also

Useful links:

- <https://github.com/jmozez/tidyinvasion>

- Report bugs at <https://github.com/jmozez/tidyinvasion/issues>

## Author

**Maintainer**: Jimmy Moses <jimmy.moses@pnguot.ac.pg>
([ORCID](https://orcid.org/0000-0003-3342-2384)) \[copyright holder\]

Authors:

- Jimmy Moses <jimmy.moses@pnguot.ac.pg>
  ([ORCID](https://orcid.org/0000-0003-3342-2384)) \[copyright holder\]
