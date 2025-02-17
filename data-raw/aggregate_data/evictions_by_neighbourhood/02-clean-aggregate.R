# Clean evictions data, just keep relevant column
# Add spatial elements in mapbox, otherwise it the data takes up too much room n the package!

library(dplyr)
library(sf)
library(purrr)
devtools::load_all()

# Read data
evictions_rate <- readRDS(here::here("data-raw", "aggregate_data", "evictions_by_neighbourhood", "extract", "evictions_rate.rds"))

# Clean up neighbourhood names
evictions_rate <- evictions_rate %>%
  mutate(neighbourhood = case_when(
    neighbourhood == "Mimico" ~ "Mimico (includes Humber Bay Shores)",
    neighbourhood == "Danforth-East York" ~ "Danforth East York",
    neighbourhood == "Dovercourt-Wallace Emerson-Juncti" ~ "Dovercourt-Wallace Emerson-Junction",
    TRUE ~ neighbourhood
  ))

# Keep relevant columns
evictions_by_neighbourhood <- evictions_rate %>%
  select(neighbourhood, evictions = l1or_l2_2016, eviction_rate = filing_rate2016, renter_households) %>%
  mutate(eviction_rate = round(eviction_rate, 3))

# Evictions for the whole city
evictions_city <- evictions_by_neighbourhood %>%
  summarise(
    value = sum(evictions),
    renter_households = sum(renter_households)
  ) %>%
  mutate(prop = value / renter_households) %>%
  pull(prop) %>%
  round(3)

evictions_by_neighbourhood <- evictions_by_neighbourhood %>%
  select(neighbourhood, prop = eviction_rate) %>%
  split(.$neighbourhood) %>%
  map(pull, prop) %>%
  map(round, 3)

# Save
saveRDS(evictions_city, here::here("data-raw", "aggregate_data", "evictions_by_neighbourhood", "aggregate", "evictions_city.rds"))
saveRDS(evictions_by_neighbourhood, here::here("data-raw", "aggregate_data", "evictions_by_neighbourhood", "aggregate", "evictions_by_neighbourhood.rds"))

# Version for mapping ----

# Add groups for colour, then make wide

evictions_by_neighbourhood <- evictions_by_neighbourhood %>%
  map(as_tibble) %>%
  bind_rows(.id = "neighbourhood") %>%
  select(neighbourhood, prop = value) %>%
  mutate(
    eviction_rate = cut(prop, seq(0, 0.15, length.out = length(low_high_legend_colors())), include.lowest = FALSE, labels = FALSE),
    eviction_rate = ifelse(prop == 0, 0, eviction_rate)
  ) %>%
  select(-prop)

saveRDS(evictions_by_neighbourhood, here::here("data-raw", "aggregate_data", "evictions_by_neighbourhood", "aggregate", "eviction_rate_by_neighbourhood_layer.rds"))
