#' tidyinvasion: tidy tools for invasion biology
#'
#' tidyinvasion covers the invasion process from introduction to impact.
#' Functions are grouped by stage:
#'
#' * **Classes**: [inv_occurrence()], [inv_pathway()] and the `inv_spread`
#'   tibble returned by [inv_spread_rate()].
#' * **Introduction**: [inv_propagule_pressure()], [inv_establishment_prob()],
#'   [inv_detection_prob()].
#' * **Spread**: [inv_distance()], [inv_spread_rate()],
#'   [inv_dispersal_kernel()], [inv_lag_phase()].
#' * **Impact**: [inv_impact_metrics()], [inv_parker_impact()],
#'   [inv_homogenization()], [inv_eicat_score()].
#' * **Biosecurity**: [inv_eradication_feasibility()], [inv_horizon_scan()].
#' * **tidymodels**: [step_inv_background()], [step_inv_propagule_lags()],
#'   [step_inv_env_distance()], [inv_spatial_block_cv()],
#'   [inv_temporal_transfer_cv()], [boyce_index()], [tss()], [inv_sdm()],
#'   [inv_reaction_diffusion()].
#'
#' Distances use the haversine formula for geographic coordinates and
#' Euclidean distance for projected coordinates, and all likelihoods are
#' maximised with [stats::optim()], so no compiled spatial libraries are
#' needed. `sf` point layers are accepted when the sf package is installed.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data := %||%
#' @importFrom generics tidy glance augment required_pkgs
#' @importFrom ggplot2 autoplot
#' @importFrom recipes prep bake
#' @importFrom pillar tbl_sum
#' @importFrom vctrs vec_restore vec_ptype2 vec_cast
#' @importFrom dplyr dplyr_reconstruct
#' @importFrom stats predict update
## usethis namespace: end
NULL

#' @export
generics::tidy

#' @export
generics::glance

#' @export
generics::augment

#' @export
ggplot2::autoplot

#' @export
recipes::prep

#' @export
recipes::bake

utils::globalVariables("density")

.onLoad <- function(libname, pkgname) {
  current <- parsnip::get_model_env()
  if (!"inv_sdm" %in% current$models) {
    make_inv_sdm()
  }
  if (!"inv_reaction_diffusion" %in% current$models) {
    make_inv_reaction_diffusion()
  }
  invisible()
}
