% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/zoom_map_to_neighbourhood.R
\name{zoom_map_to_neighbourhood}
\alias{zoom_map_to_neighbourhood}
\title{Zoom map of Toronto to neighbourhood}
\usage{
zoom_map_to_neighbourhood(map, neighbourhood)
}
\arguments{
\item{map}{Map created by \link{map_toronto}}

\item{neighbourhood}{Neighbourhood from \link{neighbourhoods}}
}
\description{
Zoom map of Toronto to neighbourhood
}
\examples{
library(sf)
map_toronto() \%>\%
  add_blank_aggregate_layers() \%>\%
  zoom_map_to_neighbourhood("Casa Loma")
}
