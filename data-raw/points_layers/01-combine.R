# Once the apartment_building_registry, apartment_building_evaluation data sets have been created, combine them

library(dplyr)
library(purrr)
library(sf)
library(tidyr)
library(stringr)
devtools::load_all()

apartment_building_registry <- readRDS(here::here("data-raw", "points_layers", "apartment_building_registry", "clean", "apartment_building_registry.rds"))

apartment_building_evaluation <- readRDS(here::here("data-raw", "points_layers", "apartment_building_evaluation", "clean", "apartment_building_evaluation.rds"))

agi_applications_and_tdf <- readRDS(here::here("data-raw", "points_layers", "agi_and_tenant_defense_fund", "clean", "agi_applications_and_tdf.rds"))

rooming_houses <- readRDS(here::here("data-raw", "points_layers", "rooming_houses", "clean", "rooming_houses.rds"))

corporate_landlords <- readRDS(here::here("data-raw", "points_layers", "corporate_landlords", "clean", "corporate_landlords.rds"))

# Join registry and RentSafeTO -----

buildings <- apartment_building_registry %>%
  mutate(apartment = TRUE) %>%
  # Only joining by RSN, because the registry addresses have ranges but the evaluation addresses do not - use the addresses from registry
  inner_join(apartment_building_evaluation, by = "rsn", suffix = c("", "_evaluation")) %>%
  mutate(
    address = coalesce(address, address_evaluation),
    bing_address = coalesce(bing_address, bing_address_evaluation),
    year_built = coalesce(year_built, year_built_evaluation),
    neighbourhood = coalesce(neighbourhood, neighbourhood_evaluation)
  ) %>%
  select(rsn, address, bing_address, neighbourhood, apartment, property_type, year_built, year_registered, units, storeys, property_management, property_management, evaluation_completed_on, score, score_percent, score_bucket, geometry) %>%
  mutate(property_management = ifelse(property_management == "Unknown", NA_character_, property_management))

# Get coords instead of geometry column, so we can coalesce more easily
apartment_buildings_coords <- buildings %>%
  split(.$address) %>%
  map(slice, 1) %>%
  map(~ .x %>%
    st_coordinates() %>%
    as_tibble()) %>%
  bind_rows(.id = "address")

buildings <- buildings %>%
  st_set_geometry(NULL) %>%
  left_join(apartment_buildings_coords, by = "address")

# Add rooming houses ----

rooming_houses <- rooming_houses %>%
  mutate(rooming_house = TRUE)

rooming_houses_coords <- rooming_houses %>%
  split(.$address) %>%
  map(slice, 1) %>%
  map(~ .x %>%
    st_coordinates() %>%
    as_tibble()) %>%
  bind_rows(.id = "address")

rooming_houses <- rooming_houses %>%
  st_set_geometry(NULL) %>%
  left_join(rooming_houses_coords, by = "address")

buildings <- buildings %>%
  full_join(rooming_houses, by = "bing_address", suffix = c("_apt", "_rooming_houses"))

# Add AGI / TDF -----

# Combine multiple AGI dates, and take the latest non-NA landlord
latest_agi_landlord <- agi_applications_and_tdf %>%
  as_tibble() %>%
  filter(!is.na(landlord)) %>%
  group_by(bing_address) %>%
  filter(date_agi_initiated == max(date_agi_initiated, na.rm = TRUE)) %>%
  slice(1) %>%
  distinct(bing_address, landlord) %>%
  ungroup()

# Same with address! Just get the latest address, in case they're in different formats
latest_agi_address <- agi_applications_and_tdf %>%
  as_tibble() %>%
  group_by(bing_address) %>%
  arrange(date_agi_initiated, desc = TRUE) %>%
  slice(1) %>%
  distinct(bing_address, address) %>%
  ungroup()

agi_applications <- agi_applications_and_tdf %>%
  mutate(agi = TRUE) %>%
  as_tibble() %>%
  mutate(reduced_increase_by = case_when(
    is.na(reduced_increase_by) ~ NA_character_,
    TRUE ~ paste0(round(reduced_increase_by, 2), "%")
  )) %>%
  group_by(agi, bing_address, neighbourhood) %>%
  arrange(desc(date_agi_initiated)) %>%
  summarise(
    geometry = geometry,
    date_agi_initiated = paste(na.omit(unique(date_agi_initiated)), collapse = ", "),
    tdf_year = paste(na.omit(unique(tdf_year)), collapse = ", "),
    reduced_increase_by = paste(na.omit(unique(reduced_increase_by)), collapse = ", "),
    .groups = "drop"
  ) %>%
  distinct() %>%
  mutate(tdf = tdf_year != "") %>%
  st_as_sf(crs = 4326)

agi_applications <- agi_applications %>%
  left_join(latest_agi_landlord, by = "bing_address") %>%
  left_join(latest_agi_address, by = "bing_address")

agi_applications_coords <- agi_applications %>%
  split(.$address) %>%
  map(slice, 1) %>%
  map(~ .x %>%
    st_coordinates() %>%
    as_tibble()) %>%
  bind_rows(.id = "address")

agi_applications <- agi_applications %>%
  st_set_geometry(NULL) %>%
  distinct() %>%
  left_join(agi_applications_coords, by = "address") %>%
  rename(X_agi = X, Y_agi = Y, neighbourhood_agi = neighbourhood, address_agi = address)

buildings <- buildings %>%
  as_tibble() %>%
  full_join(agi_applications, by = "bing_address", suffix = c("_apt", "_agi"))

# Fill in columns, prioritizing apt -> agi -> rooming houses
# Except for address, since different addresses may be geocoded to the same place - prefer to keep them distinct
buildings <- buildings %>%
  mutate(
    address = case_when(
      apartment ~ coalesce(address_apt, address_agi, address_rooming_houses),
      TRUE ~ coalesce(address_rooming_houses, address_apt, address_agi)
    ),
    X = coalesce(X_apt, X_rooming_houses, X_agi),
    Y = coalesce(Y_apt, Y_rooming_houses, Y_agi),
    neighbourhood = coalesce(neighbourhood_apt, neighbourhood_rooming_houses, neighbourhood_agi),
    apartment = coalesce(apartment, FALSE),
    agi = coalesce(agi, FALSE),
    tdf = coalesce(tdf, FALSE),
    tdf_year = na_if(tdf_year, ""),
    reduced_increase_by = na_if(reduced_increase_by, ""),
    rooming_house = coalesce(rooming_house, FALSE)
  )

# Select columns -----

buildings <- buildings %>%
  select(rsn, address, bing_address, X, Y, neighbourhood, apartment, property_type, year_built, year_registered, units, storeys, evaluation_completed_on, score, score_percent, score_bucket, agi, date_agi_initiated, tdf, tdf_year, reduced_increase_by, rooming_house, rooming_house_status = status, property_management, landlord)

# Add in corporate landlords ----

# Clean address format for joining

prep_address_for_join <- function(address) {
  address <- address %>%
    str_to_upper() %>%
    str_replace("EAST", "E") %>%
    str_replace("NORTH", "N") %>%
    str_replace("WEST", "W") %>%
    str_replace("SOUTH", "S")

  street_code_conversion <- tribble(
    ~street_code_full, ~street_code_short,
    "AVENUE", "AVE",
    "BOULEVARD", "BLVD",
    "CIRCLE", "CRCL",
    "CIRCUIT", "CRCT",
    "COURT", "CRT",
    "CRESCENT", "CRES",
    "DRIVE", "DR",
    "GARDEN", "GDNS",
    "GATE", "GT",
    "GROVE", "GRV",
    "HEIGHTS", "HTS",
    "PARKWAY", "PKWY",
    "PLACE", "PL",
    "ROAD", "RD",
    "SQUARE", "SQ",
    "STREET", "ST",
    "TERRACE", "TER",
    "TRAIL", "TRL"
  )

  for (i in 1:nrow(street_code_conversion)) {
    address <- str_replace_all(
      address, street_code_conversion[i, ][["street_code_full"]],
      street_code_conversion[i, ][["street_code_short"]]
    )
  }

  address %>%
    str_remove_all("[^[:alnum:]]") %>%
    str_remove_all(" ")
}

buildings <- buildings %>%
  mutate(address_join = prep_address_for_join(address)) %>%
  left_join(corporate_landlords, by = "address_join") %>%
  select(-address_join)

# Take business owner > AGI, and property management separately

buildings <- buildings %>%
  mutate(landlord = coalesce(business_name, landlord)) %>%
  select(-business_name)

# Set NA landlord to Unknown so they always appear, and property_managament to unknown only for apartments

buildings <- buildings %>%
  mutate(
    landlord = coalesce(landlord, "Unknown"),
    property_management = case_when(
      apartment ~ coalesce(property_management, "Unknown"),
      TRUE ~ property_management
    )
  )

buildings <- buildings %>%
  relocate(landlord, .after = bing_address) %>%
  relocate(property_management, .after = property_type)

# Convert to spatial -----

buildings <- buildings %>%
  st_as_sf(coords = c("X", "Y"), crs = 4326)

# Recode property type
buildings <- buildings %>%
  mutate(property_type = recode(property_type, PRIVATE = "Privately owned", TCHC = "Toronto Community Housing", "SOCIAL HOUSING" = "Social housing"))

# Generate tooltip based on information available -----

generate_tooltip <- function(data) {
  variables <- tribble(
    ~title, ~variable,
    "Number of units", "units",
    "Year built", "year_built",
    "Ownership type", "property_type",
    "Property owner", "landlord",
    "Property manager", "property_management",
    "Apartment building evaluation score", "score_percent",
    "Above Guideline Increase applications", "date_agi_initiated",
    "Tenant Defence Fund grants", "tdf_year",
    "AGI reduction with TDF grant support", "reduced_increase_by",
    "Rooming house license status", "rooming_house_status"
  )

  variables_text <- purrr::map2_chr(
    variables[["title"]], variables[["variable"]],
    function(title, variable) {
      if (is.na(data[[variable]])) {
        ""
      } else {
        glue::glue("<b>{title}</b>: {data[[variable]]}<br>")
      }
    }
  ) %>%
    glue::glue_collapse()

  tooltip <- glue::glue("<b>{data$address}</b><br>{variables_text}")

  tooltip
}

tooltips <- buildings %>%
  as_tibble() %>%
  mutate(id = row_number()) %>%
  split(.$id) %>%
  map(generate_tooltip) %>%
  unlist()

tooltips <- tibble(tooltip = tooltips)

buildings <- buildings %>%
  bind_cols(tooltips)

usethis::use_data(buildings, overwrite = TRUE)
