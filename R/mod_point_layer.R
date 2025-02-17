#' Point Layer UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
mod_point_layer_ui <- function(id, layer) {
  ns <- shiny::NS(id)

  tooltip <- switch(layer,
    apartment_buildings = create_popover(title = "Apartment buildings (2021)", content = "This layer shows the location of all apartment buildings with at least three storeys and at least ten units in the City of Toronto. Each point contains information on the year built, number of units, landlord or property management, apartment building evaluation scores, and above guideline increase applications, as relevant."),
    rooming_houses = create_popover(title = "Rooming house licenses (2020)", content = "This layer shows the locations of rooming houses, including licensed (pre- and post-2018) and lapsed rooming houses."),
    apartment_evaluation = create_popover(title = "Apartment building evaluation scores (2021)", content = "This layer shows the latest evaluation scores for buildings registered with RentSafeTO. Buildings must undergo evaluation at least once every three years. Scores range from 0% to 100%. Apartments that fail the evaluation by scoring less than 50% must undergo an audit."),
    agi = create_popover(title = "Above Guideline Increase applications (2016 to 2020)", content = "This layer shows the locations of apartment buildings whose landlords applied for an Above Guideline Increase (AGI) in the rent from 2016 to 2020."),
    tdf = create_popover(title = "Tenant Defence Fund grants (2018 to 2020)", content = "This layer shows the locations of apartment buildings who received a Tenant Defence Fund grant (between 2018 and 2020) for the above guideline increases their landlords applied for.")
  )

  shiny::tagList(
    shiny::fluidRow(
      shiny::column(
        width = 12,
        shinyWidgets::prettyCheckbox(
          inputId = ns("layer"),
          label = shiny::HTML(point_layers_choices[[layer]]),
          value = FALSE,
          status = "default",
          inline = TRUE # Ensures tooltip appears beside, since elements are inline
        ),
        tooltip
      )
    ),
    shiny::fluidRow(
      shiny::column(
        width = 12,
        class = "summary-legend very-padded",
        shiny::uiOutput(ns("layer_summary"))
      )
    )
  )
}

#' Point Layer Server Functions
#'
#' @noRd
mod_point_layer_server <- function(id, address_and_neighbourhood, point_layers, layer) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Update reactive with value, mod_map handles what's shown
    shiny::observeEvent(input$layer, ignoreInit = TRUE, {
      if (!input$layer) {
        active_layers <- setdiff(point_layers(), layer)
      } else {
        active_layers <- c(point_layers(), layer)
      }

      # Update reactive with value from input - then mod_map handles what's shown
      point_layers(active_layers)
    })

    # Content ----

    neighbourhood <- shiny::reactive({
      address_and_neighbourhood$neighbourhood
    })

    level <- shiny::reactive({
      if (is.null(neighbourhood())) {
        "city"
      } else {
        "neighbourhood"
      }
    })

    dataset <- shiny::reactive({
      determine_dataset_from_level(level(), neighbourhood())
    })

    output$layer_summary <- shiny::renderUI({
      switch(layer,
        apartment_buildings = shiny::tagList(
          purrr::pmap(
            dplyr::tibble(
              color = c("Apartment", "Toronto Community Housing", "Other Non-Market"),
              wording = c("privately owned", "Toronto Community Housing", "other non-market"),
              data_suffix = c("private", "tch", "social_housing")
            ),
            function(color, wording, data_suffix) {
              create_circle_legend(rental_supply_colors()[[color]],
                glue::glue("{scales::comma(units)} units in {scales::comma(buildings)} <b>{wording}</b> apartment {buildings_word}",
                  units = dataset()[[glue::glue("number_of_units_{data_suffix}")]],
                  units = ifelse(is.null(units), 0, units),
                  buildings = dataset()[[glue::glue("number_of_buildings_{data_suffix}")]],
                  buildings = ifelse(is.null(buildings), 0, buildings),
                  buildings_word = ifelse(buildings == 1, "building", "buildings")
                ),
                alt_text = glue::glue("A legend showing the colour of the points of {wording} apartment buildings.")
              )
            }
          )
        ),
        rooming_houses =
          shiny::tagList(
            purrr::pmap(
              dplyr::tibble(
                filter = c("Licensed prior to 2018", "Licensed 2018 onwards", "Lapsed"),
                wording = c("licensed prior to 2018", "licensed 2018 onwards", "whose licenses have lapsed")
              ),
              function(filter, wording) {
                create_circle_legend(rooming_house_colors()[[filter]],
                  glue::glue("{value} {buildings_word}, {wording}",
                    value = dataset()[["rooming_houses"]] %>% dplyr::filter(.data$group == filter) %>% dplyr::pull(.data$value),
                    buildings_word = ifelse(value == 1, "rooming house", "rooming houses"),
                    wording = tolower(filter)
                  ),
                  alt_text = glue::glue("A legend showing the colour of the points of rooming houses {wording}.")
                )
              }
            )
          ),
        apartment_evaluation = shiny::div(
          generate_apartment_evaluation_legend(),
          shiny::uiOutput(ns("median_score"))
        ),
        agi = shiny::div(
          create_circle_legend(layer_colours[["agi_apartment"]], glue::glue("{scales::comma(buildings)} privately owned apartment {buildings_word} with above guideline increases", buildings = dataset()[["agi"]] %>% dplyr::filter(.data$group == "Apartment building") %>% dplyr::pull(value), buildings_word = ifelse(buildings == 1, "building", "buildings")), alt_text = "A legend showing the colour of the points of above guideline increase applications for apartment buildings."),
          shiny::uiOutput(ns("agi_prop")),
          shiny::div(
            style = "margin-top: 0.5em;",
            create_circle_legend(layer_colours[["agi_other"]], glue::glue("{scales::comma(buildings)} other {buildings_word} with above guideline increases", buildings = dataset()[["agi"]] %>% dplyr::filter(.data$group != "Apartment building") %>% dplyr::pull(value), buildings_word = ifelse(buildings == 1, "building", "buildings")), alt_text = "A legend showing the colour of the points of above guideline increase applications for other buildings.")
          )
        ),
        tdf = shiny::div(
          create_circle_legend(layer_colours[["tdf"]], glue::glue("{scales::comma(buildings)} apartment {buildings_word} received TDF grants", buildings = dataset()[["tdf"]][["n"]], buildings_word = ifelse(buildings == 1, "building", "buildings")), alt_text = "A legend showing the colour of the points of tenant defence fund grants."),
          shiny::uiOutput(ns("tdf_prop"))
        )
      )
    })

    output$median_score <- shiny::renderUI({
      score <- dataset()[["apartment_building_evaluation"]]

      score_text <- glue::glue("Median score: {score}%")

      if (!is.na(score)) {
        shiny::div(
          style = "margin-left: 0.33em; margin-top: 0.5em;",
          score_text
        )
      }
    })

    output$agi_prop <- shiny::renderUI({
      value <- dataset()[["agi"]] %>%
        dplyr::filter(.data$group == "Apartment building") %>%
        dplyr::pull(.data$prop)
      text <- glue::glue("AGI rate by building: {scales::percent(value, accuracy = 0.1)}")

      if (!is.na(value)) {
        shiny::div(
          style = "margin-left: 0.33em; margin-top: 0.5em;",
          text
        )
      }
    })

    output$tdf_prop <- shiny::renderUI({
      value <- dataset()[["tdf"]][["prop"]]
      text <- glue::glue("TDF rate by AGIs: {scales::percent(value, accuracy = 0.1)}")

      if (!is.na(value) & dataset()[["agi"]] %>%
        dplyr::filter(.data$group == "Apartment building") %>%
        dplyr::pull(.data$value) != 0) {
        shiny::div(
          style = "margin-left: 0.33em; margin-top: 0.5em;",
          text
        )
      }
    })
  })
}

point_layers_choices <- list(
  apartment_buildings = "Apartment buildings <span class = 'points-layer-year'>(2021)</span>", rooming_houses = "Rooming house licenses <span class = 'points-layer-year'>(2020)</span>", apartment_evaluation = "Apartment building evaluation scores <span class = 'points-layer-year'>(2021)</span>", agi = "Above Guideline Increase applications <span class = 'points-layer-year'>(2016 to 2020)</span>",
  tdf = "Tenant Defence Fund grants <span class = 'points-layer-year'>(2018 to 2020)</span>"
)

generate_apartment_evaluation_legend <- function() {
  create_circle_legend(colour = unname(rentsafe_colors()), text = names(rentsafe_colors()), alt_text = "A legend showing the colours of points for apartment building evaluation scores, broken into categories of less than 50%, 51% to 65%, 66% to 80%, and 81% to 100%.")
}

## To be copied in the UI
# mod_point_layer_ui("apartment_buildings")

## To be copied in the server
# mod_point_layer_server("apartment_buildings")
