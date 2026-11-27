#' Cane toad records in Australia (real data from GBIF)
#'
#' Occurrence records of the cane toad (*Rhinella marina*) in Australia
#' from 1935, the year of its release at Gordonvale, Queensland (about
#' 145.79 E, 17.10 S), to 2024. These are real records downloaded from the
#' GBIF occurrence API on 27 November 2026 with these filters: country
#' Australia, coordinates present, no geospatial issues, occurrence status
#' present, licence CC0 1.0 or CC BY 4.0. Records were then restricted to
#' coordinate uncertainty of 10 km or less (or not stated) and to specimen,
#' observation and occurrence records, and thinned to one record per 0.1
#' degree grid cell per year.
#'
#' @format A tibble with 6,680 rows and 11 columns:
#' \describe{
#'   \item{gbif_id}{GBIF occurrence key. The record is at
#'     `https://www.gbif.org/occurrence/<gbif_id>`.}
#'   \item{species}{Scientific name, `"Rhinella marina"`.}
#'   \item{year, month}{Year and month of the record (month may be `NA`).}
#'   \item{lon, lat}{Decimal longitude and latitude (WGS84).}
#'   \item{state}{State or territory as given by the publisher.}
#'   \item{basis_of_record}{GBIF basis of record.}
#'   \item{coordinate_uncertainty_m}{Coordinate uncertainty in metres.}
#'   \item{dataset_key}{GBIF key of the publishing dataset; see
#'     [cane_toad_sources].}
#'   \item{licence}{`"CC BY 4.0"` or `"CC0 1.0"`.}
#' }
#' @source GBIF.org, GBIF Occurrence Search, <https://www.gbif.org>,
#'   accessed through <https://api.gbif.org/v1/occurrence/search> on 27
#'   November 2026. Records are published by the 30 datasets listed in
#'   [cane_toad_sources] under CC BY 4.0 or CC0 1.0. Credit those datasets
#'   when you use the data. The download and cleaning code is in
#'   `data-raw/make_data.R` in the package source.
#' @references Phillips, B. L., Brown, G. P., Webb, J. K. and Shine, R.
#'   (2006). Invasion and the evolution of speed in toads. *Nature*, 439,
#'   803. \doi{10.1038/439803a}
#' @examples
#' cane_toad
#' table(cane_toad$licence)
"cane_toad"

#' Datasets behind the cane toad records
#'
#' The GBIF datasets that published the records in [cane_toad], with their
#' title, publisher, licence, DOI and the number of records each
#' contributed. Real metadata from the GBIF dataset and organisation APIs.
#'
#' @format A tibble with 30 rows and 6 columns: `dataset_key`, `title`,
#'   `publisher`, `licence`, `doi` and `n_records`.
#' @source GBIF registry API, <https://api.gbif.org/v1/dataset/>, accessed
#'   27 November 2026.
#' @examples
#' cane_toad_sources
"cane_toad_sources"

#' Introduction events (simulated)
#'
#' Simulated introduction events of 20 placeholder species (`sp01` to
#' `sp20`) in four regions, 1990 to 2020. Pathways follow the CBD
#' classification. Propagule sizes are one plus a negative binomial draw
#' (size 0.8) with a mean that depends on the pathway (release 40, escape
#' 20, contaminant 6, stowaway 4, corridor 10, unaided 3). Establishment was
#' drawn from the Weibull dose-response `P(N) = 1 - exp(-0.02 * N^1.3)`.
#' [inv_establishment_prob()] estimates from these 240 events differ from
#' the true values by sampling error.
#'
#' @format A tibble with 240 rows: `event_id`, `species`, `pathway`,
#'   `region`, `year`, `propagule_size` and `established` (logical).
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' inv_introductions
"inv_introductions"

#' Repeated detection surveys (simulated)
#'
#' Simulated detection histories from five survey visits to 150 sites.
#' True occupancy is 0.25 in forest, 0.50 in grassland and 0.40 in urban
#' sites; detection per visit is 0.25 in forest and 0.40 elsewhere. About 8%
#' of visits were not made and are `NA`.
#'
#' @format A tibble with 150 rows: `site`, `habitat` and `visit_1` to
#'   `visit_5` (1 detected, 0 not detected, `NA` not surveyed).
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' inv_detection_prob(inv_surveys, surveys = starts_with("visit"), .by = habitat)
"inv_surveys"

#' Dispersal distances (simulated)
#'
#' Simulated dispersal distances in metres for two placeholder species:
#' `sp_a` (300 distances from a fat-tailed Weibull with shape 0.7 and scale
#' 80) and `sp_b` (200 distances from a thin-tailed half-normal with sigma
#' 40). Distances are rounded to 0.1 m with a minimum of 0.1 m.
#'
#' @format A tibble with 500 rows: `species` and `distance_m`.
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' inv_dispersal_kernel(dplyr::filter(inv_dispersal, species == "sp_b"), distance_m)
"inv_dispersal"

#' Invaded and uninvaded plots (simulated)
#'
#' Simulated plot data from six sites, each with eight invaded and eight
#' uninvaded plots. Native richness is Poisson with a site mean of 12 to 30
#' species, reduced in invaded plots by a site-specific log response ratio
#' drawn from Normal(-0.35, 0.15). Native cover (%) is reduced by 1.5 times
#' that log ratio.
#'
#' @format A tibble with 96 rows: `site`, `plot`, `status` (`"invaded"` or
#'   `"uninvaded"`), `native_richness` and `native_cover`.
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' inv_impact_metrics(inv_plots, native_richness, status, .by = site)
"inv_plots"

#' Native and alien community composition (simulated)
#'
#' Simulated species lists for 12 sites in each of three regions. Each
#' region has its own pool of 40 native species (8 shared between all
#' regions), of which each site holds about 30%. Ten alien species come
#' from one shared pool and each occurs at about 60% of sites, so the
#' communities should show biotic homogenisation.
#'
#' @format A tibble with one row per species at a site: `region`, `site`,
#'   `species` and `status` (`"native"` or `"alien"`).
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' inv_homogenization(inv_communities, site, species, status, .by = region)
"inv_communities"

#' EICAT impact records (simulated)
#'
#' Simulated impact records for 25 placeholder taxa (`taxon_01` to
#' `taxon_25`), with one to six records each. Mechanisms are the 12 EICAT
#' impact mechanisms; magnitudes (MC, MN, MO, MR, MV, DD) and confidence
#' are random draws. They are not real assessments.
#'
#' @format A tibble with columns `species`, `mechanism`, `magnitude`,
#'   `confidence` and `record_id`.
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' inv_eicat_score(inv_impacts, species, magnitude, mechanism, confidence)
"inv_impacts"

#' Horizon scanning scores (simulated)
#'
#' Simulated scores from four assessors for 30 placeholder candidate taxa
#' (`cand_01` to `cand_30`). Each taxon has a latent score from 1 to 5 for
#' arrival, establishment, spread and impact; each assessor's score is the
#' latent score plus Normal(0, 0.7) noise, rounded and limited to 1 to 5.
#'
#' @format A tibble with 120 rows: `species`, `assessor`, `arrival`,
#'   `establishment`, `spread`, `impact` and `confidence`.
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' inv_horizon_scan(inv_horizon, arrival:impact, species = species,
#'   assessor = assessor)
"inv_horizon"

#' Virtual species presence-background data (simulated)
#'
#' A virtual species for species distribution modelling. 3,000 random
#' points in a box from 141 to 150 E and 11 to 2 S carry smooth synthetic
#' covariates (they are not real climate or land-cover data). True
#' suitability is
#' `plogis(-2 - 0.5 * (temp - 24)^2 + 0.0015 * (rain - 2500) + 2 * forest)`
#' and each point is a presence with probability 0.6 times its suitability.
#' All other points are background. Years from 2000 to 2020 were assigned at
#' random, for temporal resampling examples.
#'
#' @format A tibble with 3,000 rows: `id`, `lon`, `lat`, `year`, `presence`
#'   (factor with levels `"presence"` and `"background"`), `temp` (degrees
#'   C), `rain` (mm per year) and `forest` (proportion).
#' @source Simulated in `data-raw/make_data.R`.
#' @examples
#' table(inv_sdm_data$presence)
"inv_sdm_data"
