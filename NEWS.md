# tidyinvasion (development version)

* `inv_niche_overlap()` compares the niche of a species in its native and
  invaded ranges with the PCA-env framework (Broennimann et al. 2012):
  Schoener's D and Warren's I, the COUE niche dynamics (stability,
  expansion and unfilling; Guisan et al. 2014) in environments available in
  both ranges, and a niche equivalency test.
* `inv_discovery_rate()` estimates the trend in the rate of introductions
  from first records while allowing for changing discovery effort (Solow
  and Costello 2004), with the expected number of species introduced but
  not yet recorded.
* `inv_seicat_score()` classifies socio-economic impacts with the SEICAT
  scheme (Bacher et al. 2018), alongside the existing EICAT scoring.

# tidyinvasion 0.1.0

* First version. Covers introduction (propagule pressure, establishment
  dose-response, detection and occupancy), spread (distances, spread rates,
  dispersal kernels, lag phases), impact (effect sizes, Parker impact,
  biotic homogenisation, EICAT), biosecurity (eradication feasibility,
  horizon scanning) and tidymodels extensions (recipes steps, rsample
  resampling, yardstick metrics and parsnip models).
* Ships real cane toad records from GBIF (`cane_toad`, `cane_toad_sources`)
  and simulated teaching datasets.
