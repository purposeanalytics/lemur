% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clean_neighbourhood_names.R
\name{clean_neighbourhood_names}
\alias{clean_neighbourhood_names}
\title{Clean neighbourhood names}
\usage{
clean_neighbourhood_names(neighbourhood)
}
\arguments{
\item{neighbourhood}{Name of neighbourhood column to be cleaned}
}
\description{
Clean up City of Toronto neighbourhood names to a standardized format and remove neighbourhood numbers, matching what's in the \link{neighbourhoods} data set.
}
\details{
If there are any cleaning errors and the names cannot all be matched to that format (meaning additional cleaning is required), the function produces a warning with the mismatched neighbourhood names, and returns the matching names cleaned, and the mismatching names in their original form.
}
\examples{
{
  library(dplyr)

  tibble(neighbourhood = c("Casa Loma (96)", "Milliken (130)")) \%>\%
    mutate(neighbourhood = clean_neighbourhood_names(neighbourhood))
}
}
