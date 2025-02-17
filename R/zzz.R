main_colour <- "#0745a8"
default_line_colour <- "#FFFFFF"
accent_colour <- mid_colour <- "#F47A21"
low_colour <- "#3BA535"
high_colour <- "#9C62BE"
grey_colour <- "#B8B8B8"
base_size <- 14
bearing <- -17

layer_colours <- c(
  apartment_buildings_private = "#27a167",
  agi_apartment = "#FFC20A",
  agi_other = "#FFE69C",
  tdf = "#ffffbf"
)

rental_supply_colors <- function() {
  stats::setNames(
    c("#27a167", "#67BF95", main_colour, "#386aba", accent_colour, "#FF9E58"),
    c("Apartment", "Non-Apartment", "Condo", "Non-Condo", "Toronto Community Housing", "Other Non-Market")
  )
}

low_high_legend_colors <- function() {
  c("#ffffff", "#cedaee", "#9cb5dd", "#6a8fcb", "#386aba", main_colour)
}

amenity_density_colours <- function() {
  stats::setNames(c("#cedaee", "#6a8fcb", "#0745a8"), c("Low", "Medium", "High"))
}

rentsafe_colors <- function() {
  stats::setNames(
    c("#759406", "#95BD08", "#B4E012", "#D2FF2E"),
    c("Less than 50%", "51% to 65%", "66% to 80%", "81% to 100%")
  )
}

rooming_house_colors <- function() {
  stats::setNames(
    c("#A12F72", "#ED51AD", "#EDDC68"),
    c("Licensed prior to 2018", "Licensed 2018 onwards", "Lapsed")
  )
}
