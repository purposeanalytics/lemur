# Extract and save above guideline increases (AGI) data

library(dplyr)
library(rvest)
library(janitor)

extract_data <- read_html(Sys.getenv("RENOVICTONS_TO_URL"))

all_evictions <- extract_data %>%
  html_element(".waffle") %>%
  html_table()

# Filter for AGI and basic cleaning
agi_applications <- all_evictions %>%
  row_to_names(1) %>%
  filter(type_agi_r == "agi") %>%
  mutate(
    date_initiated = as.Date(date_initiated, "%Y-%m-%d"),
    num_units = as.numeric(num_units),
    across(everything(), ~ na_if(.x, "")),
    # remove open text in case_number field
    case_number = if_else(nchar(case_number) < 12, NA_character_, case_number)
  ) %>%
  select(-`1`)

# Limit to the last 5 years - 2016 on

agi_applications <- agi_applications %>%
  filter(date_initiated >= "2016-01-01")

saveRDS(agi_applications, here::here("data-raw", "points_layers", "agi_and_tenant_defense_fund", "agi", "extract", "agi_applications.rds"))
