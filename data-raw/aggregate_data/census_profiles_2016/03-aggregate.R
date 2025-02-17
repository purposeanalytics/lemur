# Aggregate census tracts to neighbourhoods, for variables of interest
# Some of the dimensions we will be showing need comparisons to the city
# Either a city average / # or a distribution of all of the neighbourhoods

# # People
#
# Population
# Number of households
# Population change
# Population density
# Household size
# One person and 2+ people incomes
# Unaffordable housing %
# Total people under poverty measure
# Visible minority population

# # Places
#
# Private dwellings by structure
# Number of bedrooms
# Renter versus Owner
# Shelter Cost

library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)
library(forcats)

#### Read data ----
census_profiles_toronto_cts <- readRDS(here::here("data-raw", "aggregate_data", "census_profiles_2016", "clean", "census_profiles_toronto_cts.rds"))
census_profiles_toronto <- readRDS(here::here("data-raw", "aggregate_data", "census_profiles_2016", "clean", "census_profiles_toronto.rds"))

neighbourhood <- list()
city <- list()

#### Function for keeping more detailed dimension dimensions -----

# There is so much hierarchy in some of these, so for each dimension, check if it's a parent - if so, don't keep it. If not, then it's the most detailed, and we want to keep it.

keep_most_detailed_dimension <- function(df, dimension_full_start) {
  df_dimension <- df %>%
    distinct(parent_id, dimension_full, dimension, dimension_id) %>%
    filter(str_starts(dimension_full, dimension_full_start))

  dimension_id <- df_dimension %>%
    pull(dimension_id)

  dimension_flag_parent <- map_lgl(dimension_id, ~ .x %in% df_dimension[["parent_id"]])
  names(dimension_flag_parent) <- dimension_id

  dimension_not_parent <- dimension_flag_parent[!dimension_flag_parent]
  dimension_not_parent <- names(dimension_not_parent)

  df_dimension %>%
    filter(dimension_id %in% dimension_not_parent) %>%
    select(dimension_id) %>%
    inner_join(df, by = "dimension_id")
}

## Functions for getting total and prop -----

aggregate_total_city <- function(df) {
  df %>%
    summarise(value = sum(total, na.rm = TRUE))
}

aggregate_total_by_neighbourhood <- function(df) {
  df %>%
    group_by(neighbourhood) %>%
    summarise(value = sum(total, na.rm = TRUE))
}

# When we calculate proportion we can't just sum the totals - we need to use the parent dimension because of rounding / non-response
aggregate_prop_by_neighbourhood <- function(df, dimension_full_start) {
  df_children <- df %>%
    keep_most_detailed_dimension(dimension_full_start)

  df_children_summary <- df_children %>%
    group_by(neighbourhood, group = dimension) %>%
    summarise(value = sum(total, na.rm = TRUE), .groups = "drop")

  df_parent <- df %>%
    filter(dimension == dimension_full_start)

  df_parent_summary <- df_parent %>%
    aggregate_total_by_neighbourhood() %>%
    rename(total = value)

  df_children_summary %>%
    left_join(df_parent_summary, by = "neighbourhood") %>%
    mutate(prop = round(value / total, 3)) %>%
    select(neighbourhood, group, prop) %>%
    complete(neighbourhood, group, fill = list(prop = 0))
}

aggregate_prop_city <- function(df, dimension_full_start) {
  df_children <- df %>%
    keep_most_detailed_dimension(dimension_full_start) %>%
    select(group = dimension, value = total) %>%
    # Aggregate in cases where there was combination of some dimensions
    group_by(group) %>%
    summarise(value = sum(value, na.rm = TRUE))

  df_parent <- df %>%
    filter(dimension == dimension_full_start) %>%
    select(total)

  df_children %>%
    bind_cols(df_parent) %>%
    mutate(prop = round(value / total, 3)) %>%
    select(group, prop)
}

## People ---------------------------------------------------------------- -----

### Population -----
# Dimension: "Population, 2016"

population_by_neighbourhood <- census_profiles_toronto_cts %>%
  filter(dimension == "Population, 2016") %>%
  aggregate_total_by_neighbourhood()

neighbourhood <- append(neighbourhood, list(population = population_by_neighbourhood))

# City
population_city <- census_profiles_toronto %>%
  filter(dimension == "Population, 2016") %>%
  pull(total)

city <- append(city, list(population = population_city))

### Households -----

households_by_neighbourhood <- census_profiles_toronto_cts %>%
  filter(dimension == "Total - Private households by household size - 100% data") %>%
  aggregate_total_by_neighbourhood()

neighbourhood <- append(neighbourhood, list(households = households_by_neighbourhood))

# City
households_city <- census_profiles_toronto %>%
  filter(dimension == "Total - Private households by household size - 100% data") %>%
  pull(total)

city <- append(city, list(households = households_city))

### Population change ----
# Use "Population, 2011" and compare to 2016

population_2011 <- census_profiles_toronto_cts %>%
  filter(dimension == "Population, 2011") %>%
  aggregate_total_by_neighbourhood()

population_change_by_neighbourhood <- population_by_neighbourhood %>%
  left_join(population_2011, by = "neighbourhood", suffix = c("_2016", "_2011")) %>%
  mutate(
    population_change = (value_2016 - value_2011) / value_2011,
    population_change = round(population_change, 3)
  ) %>%
  select(neighbourhood, value = population_change)

rm(population_2011)

neighbourhood <- append(neighbourhood, list(population_change = population_change_by_neighbourhood))

# Compare to city with value and distribution

population_change_city <- census_profiles_toronto %>%
  filter(dimension == "Population percentage change, 2011 to 2016") %>%
  pull(total)
population_change_city <- population_change_city / 100

population_change_city_distribution <- population_change_by_neighbourhood["value"]

city <- append(city, list(population_change = population_change_city, population_change_distribution = population_change_city_distribution))

### Population density -----

population_density_by_neighbourhood <- census_profiles_toronto_cts %>%
  filter(dimension %in% c("Population, 2016", "Land area in square kilometres")) %>%
  select(geo_code, neighbourhood, dimension, total) %>%
  mutate(dimension = case_when(
    dimension == "Population, 2016" ~ "population",
    dimension == "Land area in square kilometres" ~ "area"
  )) %>%
  pivot_wider(names_from = dimension, values_from = total) %>%
  group_by(neighbourhood) %>%
  summarize(across(c(population, area), sum, na.rm = TRUE)) %>%
  mutate(population_density = round(population / area)) %>%
  select(neighbourhood, value = population_density)

neighbourhood <- append(neighbourhood, list(population_density = population_density_by_neighbourhood))

# Compare to city with value and distribution
population_density_city <- census_profiles_toronto %>%
  filter(dimension == "Population density per square kilometre") %>%
  pull(total) %>%
  round()

population_density_city_distribution <- population_density_by_neighbourhood["value"]

city <- append(city, list(population_density = population_density_city, population_density_distribution = population_density_city_distribution))

### Household size ----
# Variable: "Total - Private households by household size - 100% data"

# Retrieved from rental_supply > census_custom_tab_2016_table2

### Average total income ----

# Retrieved from census_custom_tab_2016_table1_income/

### Unaffordable housing ----
# Variable: "Total - Tenant households in non-farm, non-reserve private dwellings - 25% sample data"
# "% of tenant households spending 30% or more of its income on shelter costs"

household_tenure_by_ct <- census_profiles_toronto_cts %>%
  keep_most_detailed_dimension("Total - Private households by tenure - 25% sample data") %>%
  filter(dimension %in% c("Owner", "Renter")) %>%
  select(neighbourhood, geo_code, dimension, total)

renter_by_ct <- household_tenure_by_ct %>%
  filter(dimension == "Renter") %>%
  select(-dimension, -neighbourhood) %>%
  rename(renter = total)

unaffordable_housing_by_neighbourhood <- census_profiles_toronto_cts %>%
  keep_most_detailed_dimension("Total - Tenant households in non-farm, non-reserve private dwellings - 25% sample data") %>%
  filter(dimension == "% of tenant households spending 30% or more of its income on shelter costs") %>%
  select(neighbourhood, geo_code, percent_unaffordable = total) %>%
  left_join(renter_by_ct, by = "geo_code") %>%
  mutate(number_unaffordable = round(renter * percent_unaffordable / 100)) %>%
  group_by(neighbourhood) %>%
  summarise(
    value = sum(number_unaffordable, na.rm = TRUE) / sum(renter, na.rm = TRUE),
    value = round(value, 3)
  )

# TODO not quite right
# Danforth shows 49.6
unaffordable_housing_by_neighbourhood %>%
  filter(neighbourhood == "Danforth")
# This gives 49.9

neighbourhood <- append(neighbourhood, list(unaffordable_housing = unaffordable_housing_by_neighbourhood))

# Compare to city with value and distribution
unaffordable_housing_city <- census_profiles_toronto %>%
  filter(dimension == "% of tenant households spending 30% or more of its income on shelter costs") %>%
  pull(total)
unaffordable_housing_city <- round(unaffordable_housing_city / 100, 3)

unaffordable_housing_city_distribution <- unaffordable_housing_by_neighbourhood["value"]

city <- append(city, list(unaffordable_housing = unaffordable_housing_city, unaffordable_housing_distribution = unaffordable_housing_city_distribution))

### Total people under poverty measure ----
# Low-income measure after tax (LIM-AT)
private_households_by_neighbourhood <- census_profiles_toronto_cts %>%
  filter(dimension == "Number of persons in private households") %>%
  aggregate_total_by_neighbourhood()

lim_at_by_neighbourhood <- census_profiles_toronto_cts %>%
  filter(dimension == "In low income based on the Low-income measure, after tax (LIM-AT)") %>%
  aggregate_total_by_neighbourhood() %>%
  left_join(private_households_by_neighbourhood, by = "neighbourhood", suffix = c("_poverty", "_population")) %>%
  mutate(
    value = value_poverty / value_population,
    value = round(value, 3)
  ) %>%
  select(neighbourhood, value)

neighbourhood <- append(neighbourhood, list(lim_at = lim_at_by_neighbourhood))

# Compare to city with value and distribution
lim_at_city <- census_profiles_toronto %>%
  filter(dimension == "In low income based on the Low-income measure, after tax (LIM-AT)") %>%
  pull(total)

persons_city <- census_profiles_toronto %>%
  filter(dimension == "Number of persons in private households") %>%
  pull(total)

lim_at_city <- round(lim_at_city / persons_city, 3)

city <- append(city, list(lim_at = lim_at_city, lim_at_distribution = lim_at_by_neighbourhood["value"]))

### Visible minority -----
# Variable: "Total - Visible minority for the population in private households - 25% sample"

# Combine Chinese, Japanese, Korean into "East Asian"
# Combine "Filipino" with "Southeast Asian"

# These numbers seem a tiny bit off compared to the City's, even before collapsing - e.g. they have 60 for Korean vs 65 here
visible_minority_by_neighbourhood <- census_profiles_toronto_cts %>%
  mutate(dimension = case_when(
    dimension %in% c("Chinese", "Japanese", "Korean") ~ "East Asian",
    dimension == "Filipino" ~ "Southeast Asian",
    TRUE ~ dimension
  )) %>%
  aggregate_prop_by_neighbourhood("Total - Visible minority for the population in private households - 25% sample data")

neighbourhood <- append(neighbourhood, list(visible_minority = visible_minority_by_neighbourhood))

# Compare to city with breakdown

visible_minority_city <- census_profiles_toronto %>%
  mutate(dimension = case_when(
    dimension %in% c("Chinese", "Japanese", "Korean") ~ "East Asian",
    dimension == "Filipino" ~ "Southeast Asian",
    TRUE ~ dimension
  )) %>%
  aggregate_prop_city("Total - Visible minority for the population in private households - 25% sample data") %>%
  mutate(
    group = fct_reorder(group, prop, .desc = TRUE),
    group = fct_relevel(group, "Visible minority, n.i.e.", "Multiple visible minorities", "Not a visible minority", after = Inf)
  )

city <- append(city, list(visible_minority = visible_minority_city))

### Places ------- ----

### Private dwellings by structure -----

# Retrieved from rental_supply > census_custom_tab_2016_table1

### Number of bedrooms ----

# Retrieved from rental_supply > census_custom_tab_2016_table2

### Household tenure -----
# Variable: "Total - Private households by tenure - 25% sample data"
# "Band housing" (relevant when the housing is on a First Nations reserve or settlement) is not present in Toronto.
# So limit to Owner and Renter.

household_tenure_by_neighbourhood <- census_profiles_toronto_cts %>%
  aggregate_prop_by_neighbourhood("Total - Private households by tenure - 25% sample data") %>%
  filter(group %in% c("Owner", "Renter"))

neighbourhood <- append(neighbourhood, list(household_tenure = household_tenure_by_neighbourhood))

# Compare to city by breakdown

household_tenure_city <- census_profiles_toronto %>%
  aggregate_prop_city("Total - Private households by tenure - 25% sample data") %>%
  filter(group %in% c("Owner", "Renter"))

city <- append(city, list(household_tenure = household_tenure_city))

### Shelter cost -----

average_renter_shelter_cost_by_ct <- census_profiles_toronto_cts %>%
  filter(dimension == "Average monthly shelter costs for rented dwellings ($)") %>%
  select(neighbourhood, geo_code, avg_shelter_cost = total)

renter_shelter_cost_by_neighbourhood <- average_renter_shelter_cost_by_ct %>%
  left_join(renter_by_ct, by = "geo_code") %>%
  mutate(total_shelter_cost = avg_shelter_cost * renter) %>%
  group_by(neighbourhood) %>%
  summarise(
    value = sum(total_shelter_cost, na.rm = TRUE) / sum(renter, na.rm = TRUE),
    value = round(value)
  )

neighbourhood <- append(neighbourhood, list(average_renter_shelter_cost = renter_shelter_cost_by_neighbourhood))

# Compare to city by value and distribution

average_renter_shelter_cost_city <- census_profiles_toronto %>%
  filter(dimension == "Average monthly shelter costs for rented dwellings ($)") %>%
  pull(total) %>%
  round()

average_renter_shelter_cost_distribution <- renter_shelter_cost_by_neighbourhood["value"]

city <- append(city, list(average_renter_shelter_cost = average_renter_shelter_cost_city, average_renter_shelter_cost_distribution = average_renter_shelter_cost_distribution))

### Restructure data sets ----
# I want to make a list, one element for each neighbourhood, then within that have one element for each variable / dimension

neighbourhood_profiles <- neighbourhood %>%
  map(~ split(.x, .x$neighbourhood))

# Some of these are just a single value, so they don't need to be in a data frame
neighbourhood_profiles[["population"]] <- neighbourhood_profiles[["population"]] %>%
  map("value")
neighbourhood_profiles[["households"]] <- neighbourhood_profiles[["households"]] %>%
  map("value")
neighbourhood_profiles[["population_change"]] <- neighbourhood_profiles[["population_change"]] %>%
  map("value")
neighbourhood_profiles[["population_density"]] <- neighbourhood_profiles[["population_density"]] %>%
  map("value")
neighbourhood_profiles[["lim_at"]] <- neighbourhood_profiles[["lim_at"]] %>%
  map("value")
neighbourhood_profiles[["unaffordable_housing"]] <- neighbourhood_profiles[["unaffordable_housing"]] %>%
  map("value")
neighbourhood_profiles[["average_renter_shelter_cost"]] <- neighbourhood_profiles[["average_renter_shelter_cost"]] %>%
  map("value")

# Set factor levels separately for visible minority for *each* neighbourhood, so that it goes in descending order, with visible minority n.i.e., multiple visible minorities, and not a visible minority at the end

neighbourhood_profiles[["visible_minority"]] <- neighbourhood_profiles[["visible_minority"]] %>%
  map(function(x) {
    x %>%
      mutate(
        group = fct_reorder(group, prop, .desc = TRUE),
        group = fct_relevel(group, "Visible minority, n.i.e.", "Multiple visible minorities", "Not a visible minority", after = Inf)
      )
  })

# Now there's one element per variable, and within one per neighbourhood - transpose so it's inside out!
neighbourhood_profiles <- neighbourhood_profiles %>%
  transpose()

# Save as RDS, aggregate into package dataset at top level of aggregate_data folder
saveRDS(neighbourhood_profiles, here::here("data-raw", "aggregate_data", "census_profiles_2016", "aggregate", "neighbourhood_profiles.rds"))

saveRDS(city, here::here("data-raw", "aggregate_data", "census_profiles_2016", "aggregate", "city_profile.rds"))
