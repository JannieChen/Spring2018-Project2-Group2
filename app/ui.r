library(leaflet)
library(plotly)
navbarPage(strong("Party & Crime in NYC"), id="nav",
           
           ######################### Interactive Map #########################
           
           tabPanel("Interactive map",
                    div(class="outer",
                        
                        tags$head(
                          # Include our custom CSS
                          includeCSS("styles.css"),
                          includeScript("gomap.js"),
                          includeScript("message-handler.js")
                        ),
                        
                        # If not using custom CSS, set height of leafletOutput to a number instead of percent
                        leafletOutput("mapplot", width="100%", height="100%"),
                        
                        # Shiny versions prior to 0.11 should use class = "modal" instead.
                        absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                      draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                                      width = 330, height = "auto",
                                      
                                      checkboxGroupInput('locationtype', 
                                                         label = h3('Party Type'), 
                                                         choiceNames = list('Residential Building/House', 'Street/Sidewalk', 
                                                                            'Club/Bar/Restaurant', 'Store/Commercial',
                                                                            'Park/Playground', 'House of Worship'),
                                                         choiceValues = list(1, 2, 3, 4, 5, 6)
                                      ),
                                      
                                      selectInput('weekday', label = h3('Weekdays or Weekends'), 
                                                  choices = list('the whole week' = 2, 'Weekdays' = 1, 
                                                                 'Weekends' =  0)),
                                      
                                      textInput('zipcode', label = h3('Zip Code'), value = '99999'),
                                      h5("('99999' means the NYC entire area)")
                                  
                        ),
                        
                        absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                      draggable = TRUE, top = 60, left = 20, right = "auto", bottom = "auto",
                                      width = 330, height = "auto",
                                      
                                      checkboxGroupInput('crimetype', label = h3('Crime Type'), 
                                                         choiceNames = list('felony', 'misdemeanor'), 
                                                         choiceValues = list(1, 2)),
                                      
                                      dateRangeInput('daterange1', label = h3('Date range:'), start = '2017-01-01', 
                                                     end = '2017-01-01', min = '2017-01-01', max = '2017-12-31',
                                                     format = 'mm/dd/yy', separator = ' - '),
                                      
                                      sliderInput('time', label = h3('Time:'), min = 0, max = 24, value = c(0, 24), 
                                                  step = 1, sep = ':'),
                                      
                                      actionButton("action1", label = "Search")
                                      
                        ),
                        
                        absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                      top = "auto", left = 20, right = "auto", bottom = 5,
                                      width = "auto", height = "auto",
                                      
                                      br(),
                                      
                                      strong("Crime Type Legend"),
                                      
                                      h5("FELONY", style = "color:blue"),
                                      h5("MISDEMEANOR", style = "color:red")
                                      
                        )
                        
                    )
           ),
           
           ######################### Crime Analysis #########################
           
           tabPanel("Crime Analysis",
                    
                    wellPanel(style = "overflow-y:scroll; height: 850px; max-height: 750px; background-color: #ffffff;",
                              br(),
                              tabsetPanel(type="tabs",
                                          tabPanel(title=strong("Seven Type of Felony"),
                                                   br(),
                                                   div(plotlyOutput("yearplot"), align="center")
                                          ),
                                          tabPanel(title=strong("2017 Number of Crimes"),
                                                   br(),
                                                   div(img(src="total.jpg", width=800), align="center",
                                                       height = 566, width = 843)
                                          ),
                                          tabPanel(title=strong("The Crime Number over 5 Boroughs"),
                                                   br(),
                                                   div(leafletOutput("mymap"), align="center")
                                          ),
                                          tabPanel(title=strong("Location Overlap for Party and Crime"),
                                                   br(),
                                                   div(sidebarLayout(
                                                     sidebarPanel(
                                                       helpText("Create demographic graph with information from the NYPD."),
                                                       
                                                       selectInput("var",
                                                                   label = "Choose a crime to display",
                                                                   choices = c("TOTAL","VIOLATION", "MISDEMEANOR","FELONY"),
                                                                   selected = "TOTAL"),
                                                       
                                                       sliderInput("range",
                                                                   label = "Range of Time (month):",
                                                                   min = 1, max = 12, value = c(1,12))
                                                     ),
                                                     
                                                     
                                                     mainPanel(
                                                       plotOutput("selected_var")
                                                     )
                                                   ))
                                          )
                              )
                    )
           ),
           
           ######################### Party Analysis #########################
           
           tabPanel("Party Analysis",
                    
                    fluidPage(
                      titlePanel("The number of parties"),
                      sidebarLayout(position = "left",
                                    # Select date range to plot
                                    dateRangeInput("date", strong("Date Range"), start="2017-01-01", end="2017-12-31", min="2017-01-01", max="2017-12-31"),
                                    # Select weekday or weekend
                                    radioButtons("work", strong("Weekday/weekend"), choices = list("All" = 2,  "Weekday" =1 , "Weekend" = 0),selected = 2)
                      ),
                      mainPanel(
                        plotlyOutput("histplot")
                      )
                      
                      
                    ),
                    tags$a(href="https://opendata.cityofnewyork.us", "Data Source:NYC Party 2017", target = "_blank"),
                    
                    p(),
                    
                    
                    
                    h3("...", style="text-align:center"),
                    mainPanel(
                      plotlyOutput("cmqplot")
                    )
                    
           )

)


