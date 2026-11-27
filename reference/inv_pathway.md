# Create an introduction pathway table

`inv_pathway()` marks a table of introduction events with the column
that holds the pathway and, optionally, the propagule size of each
event. With `scheme = "CBD"` the pathway values are checked against
[`cbd_pathways()`](https://tidyinvasion.in4metrix.dev/reference/cbd_pathways.md).

## Usage

``` r
inv_pathway(.data, pathway, size = NULL, scheme = c("CBD", "none"))

is_inv_pathway(x)
```

## Arguments

- .data:

  A data frame of introduction events, one row per event.

- pathway:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Column with the pathway of each event.

- size:

  \<[`tidy-select`](https://tidyselect.r-lib.org/reference/language.html)\>
  Optional column with the number of individuals (propagules) introduced
  in each event.

- scheme:

  Pathway classification. `"CBD"` validates the values against the six
  CBD categories; `"none"` skips validation.

- x:

  An object to test.

## Value

An `<inv_pathway>` tibble. `is_inv_pathway()` returns a logical.

## Examples

``` r
pw <- inv_pathway(inv_introductions, pathway = pathway, size = propagule_size)
pw
#> # A <inv_pathway>: 240 × 7
#> # Pathway:         pathway
#> # Size:            propagule_size
#> # Scheme:          CBD
#>    event_id species pathway  region  year propagule_size established
#>    <chr>    <chr>   <chr>    <chr>  <int>          <dbl> <lgl>      
#>  1 ev014    sp14    stowaway west    1990             16 FALSE      
#>  2 ev025    sp09    stowaway east    1990              9 FALSE      
#>  3 ev041    sp03    stowaway west    1990              1 FALSE      
#>  4 ev060    sp18    stowaway east    1990              3 FALSE      
#>  5 ev069    sp13    escape   east    1990              1 FALSE      
#>  6 ev072    sp12    corridor west    1990              1 FALSE      
#>  7 ev098    sp08    stowaway south   1990              5 FALSE      
#>  8 ev177    sp03    release  east    1990             38 TRUE       
#>  9 ev215    sp03    stowaway south   1990              6 FALSE      
#> 10 ev006    sp18    stowaway north   1991              4 FALSE      
#> # ℹ 230 more rows
inv_propagule_pressure(pw, .by = pathway)
#> # A tibble: 6 × 8
#>   pathway     n_events total_propagules mean_size median_size cv_size max_size
#>   <chr>          <int>            <dbl>     <dbl>       <dbl>   <dbl>    <dbl>
#> 1 stowaway          59              331      5.61         4     0.864       23
#> 2 escape            55              867     15.8         10     1.08        78
#> 3 corridor          23              269     11.7          9     0.861       35
#> 4 release           43             1774     41.3         35     0.771      123
#> 5 contaminant       36              244      6.78         4.5   0.907       25
#> 6 unaided           24              103      4.29         2.5   1.07        21
#> # ℹ 1 more variable: pp_index <dbl>
```
