#' page_map UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
mod_page_map_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(
      class = "map-col",
      mod_map_ui(ns("map"))
    ),
    shiny::div(
      class = "sidebar-col",
      shiny::wellPanel(
        class = "map-sidebar",
        style = "margin-left: 15px; padding-right: 30px;",
        mod_search_ui(ns("search")),
        shiny::hr(),
        shiny::h1(style = "padding-top: 0;", shiny::textOutput(ns("header"))),
        mod_aggregate_layer_ui(ns("aggregate")),
        shiny::h2("Select point layer(s)", id = "points_layer_div"),
        mod_point_layer_ui(ns("apartment_buildings"), "apartment_buildings"),
        mod_point_layer_ui(ns("rooming_houses"), "rooming_houses"),
        mod_point_layer_ui(ns("apartment_evaluation"), "apartment_evaluation"),
        mod_point_layer_ui(ns("agi"), "agi"),
        mod_point_layer_ui(ns("tdf"), "tdf"),
        shiny::hr(),
        mod_sidebar_header_ui(ns("header"))
      )
    )
  )
}

#' page_map Server Functions
#'
#' @noRd
mod_page_map_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    address_and_neighbourhood <- shiny::reactiveValues()
    search_method <- shiny::reactiveVal()

    mod_search_server("search", address_and_neighbourhood, search_method)

    mod_map_server("map", address_and_neighbourhood, search_method, point_layers, aggregate_layers)

    # Just text header!

    output$header <- shiny::renderText({
      if (is.null(
        address_and_neighbourhood$neighbourhood
      )) {
        "Toronto"
      } else {
        address_and_neighbourhood$neighbourhood
      }
    })

    # Header

    mod_sidebar_header_server("header", address_and_neighbourhood, search_method)

    # Layers

    ## Aggregate layers

    aggregate_layers <- shiny::reactiveVal()

    mod_aggregate_layer_server("aggregate", address_and_neighbourhood, aggregate_layers)

    ## Points layers

    point_layers <- shiny::reactiveVal()

    mod_point_layer_server("apartment_buildings", address_and_neighbourhood, point_layers, "apartment_buildings")
    mod_point_layer_server("rooming_houses", address_and_neighbourhood, point_layers, "rooming_houses")
    mod_point_layer_server("apartment_evaluation", address_and_neighbourhood, point_layers, "apartment_evaluation")
    mod_point_layer_server("agi", address_and_neighbourhood, point_layers, "agi")
    mod_point_layer_server("tdf", address_and_neighbourhood, point_layers, "tdf")
  })
}

## To be copied in the UI
# mod_page_map_ui("map")

## To be copied in the server
# mod_page_map_server("map")
