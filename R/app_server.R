#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @noRd
app_server <- function(input, output, session) {
  requireNamespace("sf")
  options(knitr.kable.NA = "--")

  mod_home_server("home")

  # Check for link click on home page to change page
  shiny::observeEvent(
    input$page_link,
    {
      shiny::updateTabsetPanel(session, inputId = "page", selected = input$page_link)
    }
  )

  mod_page_map_server("map")

  mod_data_and_definitions_server("data_and_definitions")

  # Trigger tour when map is loaded
  shiny::observeEvent(input$mapLoaded, {
    if (input$mapLoaded) {
      Sys.sleep(1.5)

      # Get cookie
      visited <- glouton::fetch_cookies()

      # If cookie is null, set to "yes" then show the tour
      if (is.null(visited$visited_site)) {
        glouton::add_cookie("visited_site", "yes")
        map_guide()$init()$start()
      }
    }
  })

  # shiny::observeEvent(input$mapZoom, ignoreInit = TRUE, {
  #   if (input$mapZoom < 12.5 & input$mapZoom != 11) {
  #     search_method("back")
  #     address_and_neighbourhood$address <- NULL
  #     address_and_neighbourhood$neighbourhood <- NULL
  #   }
  # })
}

map_guide <- function() {
  cicerone::Cicerone$
    new()$
    step(
    "body",
    is_id = FALSE,
    position = "mid-center",
    class = "intro-tour-modal",
    "Welcome to the Low-end of Market Rental Monitor Map",
    shiny::HTML("LEMR is an interactive tool developed to understand changes in the stock of deeply affordable rental housing in the City of Toronto, visualized on a map. Click <b>next</b> for a tutorial."),
    # Set the background for this modal, since it's hacky and not done automatically
    on_highlighted = "function() {
      document.getElementById('driver-page-overlay').setAttribute('style', 'background-color: black !important');}",
    # Then turn it off, because the other ones already have it, so leaving it on would cause a double dark background
    on_next = "function() {
      document.getElementById('driver-page-overlay').setAttribute('style', 'background-color: transparent !important');}",
  )$
    step(
    "aggregate_layer_div",
    title = "See the big picture",
    description = "Choose a base layer to see aspects of Toronto's rentals."
  )$
    step(
    "points_layer_div",
    title = "Spot the details",
    description = "Enable point layers to identify and compare specific locations of interest. Click on each dot on the map for building details."
  )$
    step(
    "map-header-modal",
    position = "left",
    title = "Dive into the specifics",
    description = "Open the summary for a comprehensive view of available data, either city-wide or after selecting a specific neighbourhood."
  )$
    step(
    "[data-value='Data & Definitions']",
    is_id = FALSE,
    position = "left",
    title = "Learn more",
    description = "Find data sources and key terms in <b>Data & Definitions</b>."
  )
}
