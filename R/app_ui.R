#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @noRd
app_ui <- function(request) {
  shiny::tagList(
    golem_add_external_resources(),
    shiny::tags$script(shiny::HTML(
      'function link(page) {
      Shiny.onInputChange("page_link", page)
      }'
    )),
    shiny::navbarPage(
      shiny::tags$a(href="/", onclick = "link('Home')", shiny::img(class = "navbar-img", src = fs::path("www", "lemr-logo", ext = "png"), title = "Low-end of market rental monitor")),
      collapsible = TRUE,
      id = "page",
      selected = "Home",
      shiny::tabPanel(
        "Home",
        mod_home_ui("home")
      ),
      shiny::tabPanel(
        "Map",
        mod_page_map_ui("map")
      ),
      shiny::tabPanel(
        "Data & Definitions",
        mod_data_and_definitions_ui("data_and_definitions")
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#' @noRd
golem_add_external_resources <- function() {
  golem::add_resource_path(
    "www", app_sys("app/www")
  )

  shiny::tags$head(
    golem::bundle_resources(
      path = app_sys("app/www"),
      app_title = "Low-end of Market Rental Monitor"
    ),
    golem::favicon(),
    cicerone::use_cicerone(),
    glouton::use_glouton(),
    bsplus::use_bs_popover(),
    shiny::tags$head(HTML("
      <!-- Engagebay code -->
  		<script type='text/javascript' >
  		var EhAPI = EhAPI || {}; EhAPI.after_load = function(){
  		EhAPI.set_account('k0ka9ikceq0dbvm3ekmbg59lnq', 'purposeanalytics');
  		EhAPI.execute('rules');};(function(d,s,f) {
  		var sc=document.createElement(s);sc.type='text/javascript';
  		sc.async=true;sc.src=f;var m=document.getElementsByTagName(s)[0];
  		m.parentNode.insertBefore(sc,m);
  		})(document, 'script', '//d2p078bqz5urf7.cloudfront.net/jsapi/ehform.js');
  		</script>
  		")),
    shiny::tags$head(HTML("
    		<!-- Global site tag (gtag.js) - Google Analytics -->
    		<script async src='https://www.googletagmanager.com/gtag/js?id=G-Q8KYE4S9DG'></script>
    		<script>
    			window.dataLayer = window.dataLayer || [];
    			function gtag(){dataLayer.push(arguments);}
    			gtag('js', new Date());

    			gtag('config', 'G-Q8KYE4S9DG');
    		</script>
    "))
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
