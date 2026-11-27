# Build the datasets shipped with tidyinvasion.
#
# Run from the package root with:  source("data-raw/make_data.R")
#
# * cane_toad and cane_toad_sources are real occurrence records downloaded
#   from the GBIF occurrence API (https://api.gbif.org/v1/). Only records
#   published under CC0 1.0 or CC BY 4.0 are used, and every record keeps
#   its dataset key and licence so that the publishing datasets can be
#   credited (see cane_toad_sources).
# * All other datasets are simulated from stated models with fixed seeds.
#   They are clearly labelled as simulated in their documentation and use
#   placeholder taxon codes rather than real species names, so that no
#   simulated impact or risk score can be mistaken for a real assessment.
#
# Requires: jsonlite (download step only), and an internet connection for
# the GBIF step. Raw API pages are cached in data-raw/cache/ (not committed).

`%||%` <- function(x, y) if (is.null(x)) y else x

# ---------------------------------------------------------------------------
# 1. Cane toad (Rhinella marina) records in Australia from GBIF
# ---------------------------------------------------------------------------

gbif_base <- "https://api.gbif.org/v1"
cache_dir <- file.path("data-raw", "cache")
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

gbif_get <- function(url) {
  for (attempt in 1:5) {
    res <- tryCatch(jsonlite::fromJSON(url, simplifyVector = FALSE), error = function(e) NULL)
    if (!is.null(res)) {
      return(res)
    }
    Sys.sleep(2 * attempt)
  }
  stop("GBIF request failed: ", url)
}

taxon_key <- gbif_get(paste0(gbif_base, "/species/match?name=Rhinella%20marina"))$usageKey

get_year_block <- function(years) {
  cache_file <- file.path(cache_dir, paste0("cane_toad_", years[1], "_", years[2], ".rds"))
  if (file.exists(cache_file)) {
    return(readRDS(cache_file))
  }
  out <- list()
  offset <- 0
  repeat {
    url <- paste0(
      gbif_base, "/occurrence/search?taxonKey=", taxon_key,
      "&country=AU&hasCoordinate=true&hasGeospatialIssue=false",
      "&occurrenceStatus=PRESENT",
      "&license=CC0_1_0&license=CC_BY_4_0",
      "&year=", years[1], ",", years[2],
      "&limit=300&offset=", offset
    )
    page <- gbif_get(url)
    recs <- lapply(page$results, function(r) {
      data.frame(
        gbif_id = as.character(r$key),
        year = as.integer(r$year %||% NA),
        month = as.integer(r$month %||% NA),
        lon = as.numeric(r$decimalLongitude),
        lat = as.numeric(r$decimalLatitude),
        state = as.character(r$stateProvince %||% NA),
        basis_of_record = as.character(r$basisOfRecord %||% NA),
        coordinate_uncertainty_m = as.numeric(r$coordinateUncertaintyInMeters %||% NA),
        dataset_key = as.character(r$datasetKey),
        licence = as.character(r$license %||% NA),
        stringsAsFactors = FALSE
      )
    })
    out <- c(out, recs)
    offset <- offset + 300
    if (isTRUE(page$endOfRecords) || offset >= 99900) break
  }
  res <- do.call(rbind, out)
  saveRDS(res, cache_file)
  res
}

blocks <- list(
  c(1935, 1979), c(1980, 1999), c(2000, 2009), c(2010, 2014),
  c(2015, 2017), c(2018, 2020), c(2021, 2022), c(2023, 2024)
)
raw <- do.call(rbind, lapply(blocks, get_year_block))
raw <- raw[!duplicated(raw$gbif_id), ]

keep_basis <- c(
  "PRESERVED_SPECIMEN", "HUMAN_OBSERVATION", "OBSERVATION",
  "MACHINE_OBSERVATION", "MATERIAL_SAMPLE", "OCCURRENCE"
)
toad <- raw[
  !is.na(raw$year) & raw$year >= 1935 & raw$year <= 2024 &
    raw$basis_of_record %in% keep_basis &
    (is.na(raw$coordinate_uncertainty_m) | raw$coordinate_uncertainty_m <= 10000) &
    raw$lon >= 112 & raw$lon <= 154 & raw$lat >= -44 & raw$lat <= -9,
]

# Thin to one record per 0.1 degree cell per year (the earliest month, then
# the lowest GBIF id) to remove repeated records of the same population.
toad$cell <- paste(floor(toad$lon / 0.1), floor(toad$lat / 0.1), toad$year)
toad <- toad[order(toad$year, toad$month, toad$gbif_id, na.last = TRUE), ]
toad <- toad[!duplicated(toad$cell), ]
toad$cell <- NULL

licence_map <- c(
  "http://creativecommons.org/publicdomain/zero/1.0/legalcode" = "CC0 1.0",
  "http://creativecommons.org/licenses/by/4.0/legalcode" = "CC BY 4.0",
  "CC0_1_0" = "CC0 1.0", "CC_BY_4_0" = "CC BY 4.0"
)
toad$licence <- unname(ifelse(toad$licence %in% names(licence_map),
  licence_map[toad$licence], toad$licence
))
stopifnot(all(toad$licence %in% c("CC0 1.0", "CC BY 4.0")))

toad$species <- "Rhinella marina"
cane_toad <- tibble::as_tibble(toad[, c(
  "gbif_id", "species", "year", "month", "lon", "lat", "state",
  "basis_of_record", "coordinate_uncertainty_m", "dataset_key", "licence"
)])
cane_toad <- cane_toad[order(cane_toad$year, cane_toad$gbif_id), ]
cane_toad$lon <- round(cane_toad$lon, 5)
cane_toad$lat <- round(cane_toad$lat, 5)

ds_keys <- sort(unique(cane_toad$dataset_key))
cane_toad_sources <- do.call(rbind, lapply(ds_keys, function(k) {
  d <- gbif_get(paste0(gbif_base, "/dataset/", k))
  org <- tryCatch(
    gbif_get(paste0(gbif_base, "/organization/", d$publishingOrganizationKey))$title,
    error = function(e) NA_character_
  )
  data.frame(
    dataset_key = k,
    title = d$title %||% NA_character_,
    publisher = org %||% NA_character_,
    licence = paste(sort(unique(cane_toad$licence[cane_toad$dataset_key == k])), collapse = "; "),
    doi = d$doi %||% NA_character_,
    n_records = sum(cane_toad$dataset_key == k),
    stringsAsFactors = FALSE
  )
}))
cane_toad_sources <- tibble::as_tibble(cane_toad_sources[order(-cane_toad_sources$n_records), ])

# ---------------------------------------------------------------------------
# 2. Simulated datasets
# ---------------------------------------------------------------------------

set.seed(20261127)

# Introduction events. Propagule sizes are negative binomial with a mean
# that depends on the CBD pathway; establishment follows the Weibull
# dose-response P(N) = 1 - exp(-alpha * N^c) with alpha = 0.02, c = 1.3.
pathways <- c("release", "escape", "contaminant", "stowaway", "corridor", "unaided")
pathway_mean <- c(release = 40, escape = 20, contaminant = 6, stowaway = 4,
  corridor = 10, unaided = 3)
n_events <- 240
inv_introductions <- tibble::tibble(
  event_id = sprintf("ev%03d", seq_len(n_events)),
  species = sprintf("sp%02d", sample.int(20, n_events, replace = TRUE)),
  pathway = sample(pathways, n_events, replace = TRUE,
    prob = c(0.15, 0.25, 0.2, 0.2, 0.1, 0.1)),
  region = sample(c("north", "south", "east", "west"), n_events, replace = TRUE),
  year = sample(1990:2020, n_events, replace = TRUE)
)
inv_introductions$propagule_size <- 1 + stats::rnbinom(n_events, size = 0.8,
  mu = pathway_mean[inv_introductions$pathway])
p_est <- 1 - exp(-0.02 * inv_introductions$propagule_size^1.3)
inv_introductions$established <- stats::runif(n_events) < p_est
inv_introductions <- inv_introductions[order(inv_introductions$year, inv_introductions$event_id), ]

# Repeated surveys for occupancy and detection. Occupancy differs by habitat
# (forest 0.25, grassland 0.50, urban 0.40), detection per visit is 0.25 in
# forest and 0.40 elsewhere, and about 8% of visits were not made (NA).
n_sites <- 150
habitat <- sample(c("forest", "grassland", "urban"), n_sites, replace = TRUE)
psi <- c(forest = 0.25, grassland = 0.5, urban = 0.4)[habitat]
p_det <- c(forest = 0.25, grassland = 0.4, urban = 0.4)[habitat]
z <- stats::runif(n_sites) < psi
visits <- sapply(1:5, function(j) as.integer(z & stats::runif(n_sites) < p_det))
visits[stats::runif(length(visits)) < 0.08] <- NA
colnames(visits) <- paste0("visit_", 1:5)
inv_surveys <- tibble::as_tibble(data.frame(
  site = sprintf("site%03d", seq_len(n_sites)), habitat = habitat, visits,
  stringsAsFactors = FALSE
))

# Dispersal distances (m). sp_a: Weibull(shape 0.7, scale 80), a fat tail;
# sp_b: half-normal with sigma 40, a thin tail.
inv_dispersal <- tibble::tibble(
  species = c(rep("sp_a", 300), rep("sp_b", 200)),
  distance_m = round(pmax(0.1, c(
    stats::rweibull(300, shape = 0.7, scale = 80),
    abs(stats::rnorm(200, 0, 40))
  )), 1)
)

# Paired invaded and uninvaded plots at six sites. Native richness is
# Poisson with a site mean of 12 to 30 species, reduced in invaded plots by
# a site-specific log ratio drawn from Normal(-0.35, 0.15). Native cover (%)
# is reduced in the same way.
sites <- sprintf("site_%d", 1:6)
base_rich <- stats::runif(6, 12, 30)
eff <- stats::rnorm(6, -0.35, 0.15)
inv_plots <- do.call(rbind, lapply(seq_along(sites), function(i) {
  status <- rep(c("invaded", "uninvaded"), each = 8)
  mu <- base_rich[i] * exp(ifelse(status == "invaded", eff[i], 0))
  cover_mu <- 70 * exp(ifelse(status == "invaded", eff[i] * 1.5, 0))
  data.frame(
    site = sites[i], plot = sprintf("%s_p%02d", sites[i], 1:16), status = status,
    native_richness = stats::rpois(16, mu),
    native_cover = round(pmin(100, pmax(1, stats::rnorm(16, cover_mu, 8))), 1),
    stringsAsFactors = FALSE
  )
}))
inv_plots <- tibble::as_tibble(inv_plots)

# Communities in three regions. Each region has its own pool of 40 native
# species (with 8 shared between regions); 10 alien species are drawn from
# one cosmopolitan pool and are frequent everywhere, which should make the
# regions' communities more similar (homogenisation).
native_pool <- lapply(1:3, function(r) c(sprintf("nat_shared_%02d", 1:8), sprintf("nat_r%d_%02d", r, 1:32)))
alien_pool <- sprintf("alien_%02d", 1:10)
inv_communities <- do.call(rbind, lapply(1:3, function(r) {
  do.call(rbind, lapply(1:12, function(s) {
    nat <- native_pool[[r]][stats::runif(40) < 0.3]
    ali <- alien_pool[stats::runif(10) < 0.6]
    data.frame(
      region = paste0("region_", r), site = sprintf("r%d_s%02d", r, s),
      species = c(nat, ali), status = c(rep("native", length(nat)), rep("alien", length(ali))),
      stringsAsFactors = FALSE
    )
  }))
}))
inv_communities <- tibble::as_tibble(inv_communities)

# EICAT impact records for 25 placeholder taxa. Magnitudes, mechanisms and
# confidence are random draws; they are not real assessments.
mechanisms <- c(
  "competition", "predation", "hybridisation", "transmission of disease",
  "parasitism", "poisoning/toxicity", "bio-fouling", "grazing/herbivory/browsing",
  "chemical impact on ecosystem", "physical impact on ecosystem",
  "structural impact on ecosystem", "interaction with other alien species"
)
inv_impacts <- do.call(rbind, lapply(sprintf("taxon_%02d", 1:25), function(sp) {
  n <- sample(1:6, 1)
  data.frame(
    species = sp,
    mechanism = sample(mechanisms, n, replace = TRUE),
    magnitude = sample(c("MC", "MN", "MO", "MR", "MV", "DD"), n, replace = TRUE,
      prob = c(0.25, 0.3, 0.22, 0.12, 0.04, 0.07)),
    confidence = sample(c("low", "medium", "high"), n, replace = TRUE, prob = c(0.3, 0.45, 0.25)),
    record_id = NA_character_,
    stringsAsFactors = FALSE
  )
}))
inv_impacts$record_id <- sprintf("rec%03d", seq_len(nrow(inv_impacts)))
inv_impacts <- tibble::as_tibble(inv_impacts)

# Horizon scanning scores: 30 placeholder candidate taxa scored 1 to 5 by
# four assessors for arrival, establishment, spread and impact. Each taxon
# has a latent score per criterion; assessors add Normal(0, 0.7) noise.
cands <- sprintf("cand_%02d", 1:30)
latent <- matrix(stats::runif(30 * 4, 1, 5), 30, 4,
  dimnames = list(cands, c("arrival", "establishment", "spread", "impact")))
inv_horizon <- do.call(rbind, lapply(paste0("assessor_", LETTERS[1:4]), function(a) {
  sc <- round(latent + matrix(stats::rnorm(120, 0, 0.7), 30, 4))
  sc[] <- pmin(5, pmax(1, sc))
  data.frame(species = cands, assessor = a, sc, stringsAsFactors = FALSE, row.names = NULL)
}))
inv_horizon$confidence <- sample(c("low", "medium", "high"), nrow(inv_horizon), replace = TRUE)
inv_horizon <- tibble::as_tibble(inv_horizon)

# Virtual species for species distribution modelling. 3000 random points in
# a longitude/latitude box (141 to 150 E, 11 to 2 S) carry smooth synthetic
# covariates; they are not real climate or land-cover data. True suitability
# is logit(s) = -2 - 0.5 * (temp - 24)^2 + 0.0015 * (rain - 2500) + 2 * forest,
# and presences are Bernoulli draws of 0.6 * s. All other points are
# background. Years 2000 to 2020 are assigned at random.
n_pts <- 3000
lon <- stats::runif(n_pts, 141, 150)
lat <- stats::runif(n_pts, -11, -2)
temp <- 26 - 2.5 * sin((lat + 6) / 2) + 0.5 * cos((lon - 145) / 1.5) + stats::rnorm(n_pts, 0, 0.4)
rain <- 2600 + 700 * cos((lon - 145.5) / 2) - 300 * sin((lat + 4) / 3) + stats::rnorm(n_pts, 0, 120)
forest <- stats::plogis(1.2 * sin((lon - 141) / 2) + 0.8 * cos((lat + 2) / 2) + stats::rnorm(n_pts, 0, 0.5))
suit <- stats::plogis(-2 - 0.5 * (temp - 24)^2 + 0.0015 * (rain - 2500) + 2 * forest)
pres <- stats::runif(n_pts) < 0.6 * suit
inv_sdm_data <- tibble::tibble(
  id = seq_len(n_pts),
  lon = round(lon, 4), lat = round(lat, 4),
  year = sample(2000:2020, n_pts, replace = TRUE),
  presence = factor(ifelse(pres, "presence", "background"), levels = c("presence", "background")),
  temp = round(temp, 2), rain = round(rain), forest = round(forest, 3)
)

# ---------------------------------------------------------------------------
# 3. Save
# ---------------------------------------------------------------------------

dir.create("data", showWarnings = FALSE)
for (nm in c("cane_toad", "cane_toad_sources", "inv_introductions", "inv_surveys",
  "inv_dispersal", "inv_plots", "inv_communities", "inv_impacts", "inv_horizon",
  "inv_sdm_data")) {
  obj <- get(nm)
  assign(nm, obj)
  save(list = nm, file = file.path("data", paste0(nm, ".rda")), compress = "xz",
    version = 2)
}
