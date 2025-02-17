% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_blank_layers.R
\name{add_blank_aggregate_layers}
\alias{add_blank_aggregate_layers}
\title{Add a blank aggregate layers}
\usage{
add_blank_aggregate_layers(map)
}
\arguments{
\item{map}{Map created via \link{map_toronto}}
}
\description{
Add empty aggregate layers to a map (created via \link{map_toronto}). The purpose of this function is to allow for toggling the layers on and off, via \link{toggle_layer_visible} and \link{toggle_layer_invisible}. This function adds the following layers (accessed via IDs): estimated proportion low-end of market rentals (lem_percent), rental supply (primary - rental_supply_primary; condo - rental_supply_condo; non-condo secondary - rental_supply_non_condo; non-market - rental_supply_non_market), core housing need (core_housing_need), eviction filings rate (eviction_rate), and all neighbourhood outline / click / etc layers. Note that LEM is visible by default.
}
\examples{
library(sf)

map_toronto() \%>\%
  add_blank_aggregate_layers() \%>\%
  toggle_layer_visible("lem_percent")
}
