# Native and alien community composition (simulated)

Simulated species lists for 12 sites in each of three regions. Each
region has its own pool of 40 native species (8 shared between all
regions), of which each site holds about 30%. Ten alien species come
from one shared pool and each occurs at about 60% of sites, so the
communities should show biotic homogenisation.

## Usage

``` r
inv_communities
```

## Format

A tibble with one row per species at a site: `region`, `site`, `species`
and `status` (`"native"` or `"alien"`).

## Source

Simulated in `data-raw/make_data.R`.

## Examples

``` r
inv_homogenization(inv_communities, site, species, status, .by = region)
#> # A tibble: 3 × 11
#>   region   n_sites n_native n_alien jaccard_native jaccard_current delta_jaccard
#>   <chr>      <int>    <int>   <int>          <dbl>           <dbl>         <dbl>
#> 1 region_1      12       40      10          0.189           0.261        0.0726
#> 2 region_2      12       39      10          0.190           0.256        0.0665
#> 3 region_3      12       40      10          0.175           0.253        0.0771
#> # ℹ 4 more variables: sorensen_native <dbl>, sorensen_current <dbl>,
#> #   delta_sorensen <dbl>, homogenised <lgl>
```
