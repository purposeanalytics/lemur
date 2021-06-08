
<!-- README.md is generated from README.Rmd. Please edit that file -->

# lemur

CMHC Housing Supply Challenge Proof of Concept

## Installation

You can install lemur from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("purposeanalytics/lemur")
```

## Usage

### App

The primary product of lemur is a Shiny app which will show low-end of
market rental housing in Toronto, along with other data sets. To load
the app, run:

``` r
lemur::run_app()
```

### Functions

lemur also contains a few utility functions.

For example, you can geocode addresses using the Bing geocoder:

``` r
library(lemur)
geocode_address("220 Yonge St Toronto ON")
#> ℹ Fetching 220 Yonge St Toronto ON - Status: 200
#> # A tibble: 1 x 8
#>   bing_status_code bing_address bing_municipality bing_postal_code bing_method
#>              <int> <chr>        <chr>             <chr>            <chr>      
#> 1              200 220 Yonge St Toronto           M5B 2H1          Rooftop    
#> # … with 3 more variables: bing_confidence <chr>, bing_latitude <dbl>,
#> #   bing_longitude <dbl>
```

This looks up any address in Canada, so it’s helpful to supply the city
or postal code for the most accurate results - for example, 220 Yonge St
without “Toronto ON” gives us somewhere on an island in Lake Huron:

``` r
geocode_address("220 Yonge St")
#> ℹ Fetching 220 Yonge St - Status: 200
#> # A tibble: 1 x 8
#>   bing_status_code bing_address bing_municipality bing_postal_code bing_method  
#>              <int> <chr>        <chr>             <chr>            <chr>        
#> 1              200 220 Yonge St Nipissing         P0H              Interpolatio…
#> # … with 3 more variables: bing_confidence <chr>, bing_latitude <dbl>,
#> #   bing_longitude <dbl>
```

An API token is required, and the function looks for it in the
`BING_TOKEN` environment variable, buit this can be changed or supplied
directly via the `token` argument.

### Data sets

lemur contains a number of spatial data sets (used in the app), which
can also be used in other code or packages.

#### toronto

toronto is a data set that includes the boundary of Toronto:

``` r
library(sf)
#> Linking to GEOS 3.8.1, GDAL 3.1.4, PROJ 6.3.1
library(ggplot2)
toronto
#> Simple feature collection with 1 feature and 3 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -79.63927 ymin: 43.581 xmax: -79.11525 ymax: 43.85547
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 x 4
#>   AREA_ID AREA_NAME OBJECTID                                            geometry
#>     <dbl> <chr>        <dbl>                                       <POLYGON [°]>
#> 1   49886 Toronto   13448849 ((-79.33131 43.6258, -79.33133 43.62571, -79.33153…

p <- ggplot() + 
  geom_sf(data = toronto)

p
```

<img src="man/figures/README-unnamed-chunk-4-1.png" width="80%" />

#### neighbourhoods

neighbourhoods contains the 140 social planning neighbourhoods in
Toronto and their boundaries. Once the [new 158
neighbourhoods](https://www.toronto.ca/city-government/data-research-maps/neighbourhoods-communities/neighbourhood-profiles/)
are released by the City of Toronto, this data set will be updated.

``` r
neighbourhoods
#> Simple feature collection with 140 features and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -79.63926 ymin: 43.581 xmax: -79.11527 ymax: 43.85546
#> Geodetic CRS:  WGS 84
#> # A tibble: 140 x 2
#>    neighbourhood                                                        geometry
#>    <chr>                                                           <POLYGON [°]>
#>  1 Casa Loma              ((-79.41469 43.67391, -79.41485 43.67434, -79.41553 4…
#>  2 Annex                  ((-79.39414 43.66872, -79.39588 43.66833, -79.39738 4…
#>  3 Caledonia-Fairbank     ((-79.46021 43.68156, -79.46044 43.6819, -79.46075 43…
#>  4 Woodbine Corridor      ((-79.31485 43.66674, -79.3166 43.66636, -79.31692 43…
#>  5 Lawrence Park South    ((-79.41096 43.70408, -79.41165 43.70394, -79.41208 4…
#>  6 Milliken               ((-79.24308 43.81297, -79.24433 43.81271, -79.24514 4…
#>  7 Henry Farm             ((-79.35966 43.76649, -79.35966 43.76655, -79.35967 4…
#>  8 Downsview-Roding-CFB   ((-79.50783 43.71776, -79.50854 43.71767, -79.51265 4…
#>  9 Kingsview Village-The… ((-79.55236 43.70947, -79.55229 43.7095, -79.55219 43…
#> 10 Kennedy Park           ((-79.24549 43.7306, -79.24555 43.73055, -79.24563 43…
#> # … with 130 more rows

p <- p +
  geom_sf(data = neighbourhoods)

p
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="80%" />

#### apartment\_building\_registry

apartment\_building\_registry is a geocoded version of the City of
Toronto’s [Apartment Building Registration
Dataset](https://open.toronto.ca/dataset/apartment-building-registration/),
with cleaned addresses and latitude and longitude:

``` r
apartment_building_registry
#> Simple feature collection with 3479 features and 74 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -79.61487 ymin: 43.58818 xmax: -79.14976 ymax: 43.81408
#> Geodetic CRS:  WGS 84
#> # A tibble: 3,479 x 75
#>       id bing_address           bing_municipality bing_postal_code bing_latitude
#>  * <dbl> <chr>                  <chr>             <chr>                    <dbl>
#>  1 62272 3725 Dundas St W       Toronto           M6S 2T5                   43.7
#>  2 65726 12 Thorncliffe Park Dr Toronto           M4H 1N8                   43.7
#>  3 62273 2743 Victoria Park Ave <NA>              M1T                       43.8
#>  4 62274 5 Stag Hill Dr         Toronto           M4B 1K7                   43.7
#>  5 62275 1085 Steeles Ave W     <NA>              M2R 2T1                   43.8
#>  6 62276 15 Forty Third St      <NA>              M8W 3P7                   43.6
#>  7 65727 595 Brookdale Ave      Toronto           M5M 1S5                   43.7
#>  8 65728 211 Wilson Ave         Toronto           M5M 3A9                   43.7
#>  9 65729 193 Wilson Ave         Toronto           M5M 4M8                   43.7
#> 10 62277 33 Rosehill Ave        Toronto           M4T 1G4                   43.7
#> # … with 3,469 more rows, and 70 more variables: bing_longitude <dbl>,
#> #   air_conditioning_type <chr>, amenities_available <chr>,
#> #   annual_fire_alarm_test_records <chr>,
#> #   annual_fire_pump_flow_test_records <chr>, approved_fire_safety_plan <chr>,
#> #   balconies <chr>, barrier_free_accessibilty_entr <chr>, bike_parking <chr>,
#> #   confirmed_storeys <dbl>, confirmed_units <dbl>,
#> #   date_of_last_inspection_by_tssa <chr>,
#> #   description_of_child_play_area <chr>,
#> #   description_of_indoor_exercise_room <chr>,
#> #   description_of_outdoor_rec_facilities <chr>, elevator_parts_replaced <chr>,
#> #   elevator_status <chr>, emerg_power_supply_test_records <chr>,
#> #   exterior_fire_escape <chr>, facilities_available <chr>, …

p + 
  geom_point(data = apartment_building_registry, aes(x = bing_longitude, y = bing_latitude))
```

<img src="man/figures/README-unnamed-chunk-6-1.png" width="80%" />
