######################### Library Packages #########################
packages.used=c('shiny', 'leaflet', 'dplyr', 'reshape2', 'ggplot2', 'stringr',
                'geojson', 'geojsonio', 'ggthemes', 'plotly')

# check packages that need to be installed.
packages.needed=setdiff(packages.used, 
                        intersect(installed.packages()[,1], 
                                  packages.used))
# install additional packages
if(length(packages.needed)>0){
  install.packages(packages.needed, dependencies = TRUE)
}

library(shiny)
library(leaflet)
library(dplyr)
library(reshape2)
library(ggplot2)
library(stringr)
library(geojson)
library(geojsonio)
library(ggthemes)
library(plotly)

#########################  Load Dataset   #########################
party <- read.csv('../data/party.csv', stringsAsFactors = FALSE)
crime <- read.csv("../data/Crime.csv", stringsAsFactors = FALSE)

felony<- read.csv("../data/felonyint.csv")
nypd17<- read.csv("../data/nypd17.csv")
month <- substring(party$open.date,6,7)


######################### Process Dataset #########################

# Party Dataset
party <- party %>% 
           select("Location.Type", "Incident.Zip", "Borough", 
                  "Latitude", "Longitude", "open.date",
                  "open.time", "weekday", "work")
party <- party[!is.na(party$Latitude) & !is.na(party$Longitude), ]
party <- party[party$Borough != "Unspecified",]
party$Location.Type[party$Location.Type == "Residential Building/House"] <- 1
party$Location.Type[party$Location.Type == "Street/Sidewalk"] <- 2
party$Location.Type[party$Location.Type == "Club/Bar/Restaurant"] <- 3
party$Location.Type[party$Location.Type == "Store/Commercial"] <- 4
party$Location.Type[party$Location.Type == "Park/Playground"] <- 5
party$Location.Type[party$Location.Type == "House of Worship"] <- 6
party <- party[party$Location.Type == c(1, 2, 3, 4, 5, 6), ]

changetime = function(a){
  b = as.character(a[7])
  l = nchar(b)
  apm = substr(b, start = l-1, stop = l)
  if(apm=='AM'){
    return(as.numeric(substr(b, start = 1, stop = l-9)))
  }
  else{
    return(as.numeric(substr(b, start = 1, stop = l-9))+12)
  }
}

party[7] <- apply(party, MARGIN = 1, changetime)


# Crime Dataset

# crime.update <- read.csv("NYPDM.csv", stringsAsFactors = FALSE)
# crime.update <- crime.update %>%
#                   select("CMPLNT_TO_DT", "CMPLNT_TO_TM", "LAW_CAT_CD",
#                          "BORO_NM", "Latitude", "Longitude")
# colnames(crime.update) <- c("date", "time", "crime_type","BORO_NM", "Latitude", "Longitude")
# crime.update <- crime.update[!is.na(crime.update$Latitude) & !is.na(crime.update$Longitude), ]
# crime.update <- crime.update[!is.na(crime.update$time), ]
# crime.update <- crime.update[-which(crime.update$crime_type == "VIOLATION"), ]
# crime.update$date <- as.Date(crime.update$date, format = "%m/%d/%Y")
# crime.update<- crime.update[crime.update$date >= "2017-01-01",]
# crime.update<- crime.update[crime.update$date <= "2017-12-31",]
# 
# changetime = function(a){
#   b = as.character(a[2])
#   l = nchar(b)
#   return(as.numeric(substr(b, start = 1, stop = l-6)))
# }
# 
# crime.update[2] <- apply(crime.update, MARGIN = 1, changetime)
# 
# changecrime_type = function(a){
#   b = a[3]
#   if(b == "FELONY")
#     return(as.numeric(1))
#   else(b == "MISDEMEANOR")
#   return(as.numeric(2))
# }
# 
# crime.update[3] <- apply(crime.update, MARGIN = 1, changecrime_type)

nullcrime<- crime[0,]
nullparty<- party[0,]

######################### Call Function #########################
source("plotTheme.R")

#crime data set keran

nyc<- geojsonio::geojson_read("../data/Boundaries.geojson", what = "sp")
colnames(felony)<- c("Offense",2000:2016)
name<- felony[,1]
felony$base<-felony[,1]
felony<- felony[-8,]
felony1 <- melt(felony)
m <- leaflet() %>%
      addTiles() %>%
      setView(-73.935242, 	40.730610, zoom = 10)

nyc$num<- c(20856,111647,134715,89516,101306)
bins <- c(10000,50000,100000, 120000,Inf)
pal <- colorBin("YlOrRd", domain = nyc$num, bins = bins)
nyc$num2<- c("Violation: 4624
             Misdemeanor:11915
             Felony:4771",
             "Violation: 13271
             Misdemeanor:65814
             Felony:35391",
             "Violation: 19794
             Misdemeanor:73709
             Felony:44238",
             "Violation: 14274
             Misdemeanor:47994
             Felony:29468",
             "Violation: 15368
             Misdemeanor:59333
             Felony:28797")
labels <- sprintf("<strong>%s</strong><br/>%s", nyc$boro_name, nyc$num2) %>% 
            lapply(htmltools::HTML)


shinyServer(function(input, output, session){
  
  ######################### Interactive Map #########################
  # Interactive Map (Party Part): Xinlei Cao, Xinrou Li 
  # Interactive Map (Crime Part): Xiaochen Fan
  
  datafinal <- eventReactive(input$action1, {
    ######################### Party Dataset #########################
    party01 = party %>% 
      # filter date range
      filter(open.date >= as.Date(input$daterange1[1]) & open.date <= as.Date(input$daterange1[2])) %>%
      # filter time range
      filter(open.time >= input$time[1] & open.date <= input$time[2]) 
    
    # filter weekday or weekend
    if(input$weekday == 1 | input$weekday==0){
      party01 = party01 %>%
        filter(work == input$weekday)
    }
    
    # filter zipcode
    if(input$zipcode == 99999){
      party01
    } else {
      if(is.element(input$zipcode, unique(party$Incident.Zip))){
        party01 = party01 %>%
          filter(Incident.Zip == input$zipcode)
      } else {
        session$sendCustomMessage(type = 'testmessage',
                                  message = 'Please Input a Vaild Zipcode')
      }
    }
    
    # filter party type
    lt = input$locationtype
    l = length(lt)
    if(l==0){
      party01 = nullparty
    }else{
      a = 'party01 %>% filter('
      for (i in lt) {
        a = paste(a, 'Location.Type == lt[', i, '] | ', sep = '')
      }
      a = substr(a, start = 1, stop = nchar(a)-3)
      a = paste(a, ')', sep = '')
      party01 = eval(parse(text = a))
    }
    
    ######################### Crime Dataset #########################
    crime01 = crime %>% 
      # filter date range
      filter(date >= as.Date(input$daterange1[1]) & date <= as.Date(input$daterange1[2])) %>%
      # filter time range
      filter(time >= input$time[1] & time <= input$time[2])
    # filter crime type
    if (length(input$crimetype) == 0){
      crime01 <- nullcrime
      }
    else{
      if (length(input$crimetype) == 1){
        crime01 <- crime01 %>%
          filter(crime_type == input$crimetype)
      }
      else{
        crime01 <- crime01
        }
    }
    
    # Ouput two datasets as a list
    final<- list(party01, crime01)
    final
  })
  
  # 
  output$mapplot <- renderLeaflet({
    leaflet() %>%
      #addProviderTiles(providers$MtbMap)  %>%
      addTiles() %>%  # Add default OpenStreetMap map tiles
      #clearMarkers() %>%
      setView(lng = -74.0060, lat = 40.7128, zoom = 11) # set the NY Map
    
  })
  
  # Observe crime event
  
  observe({
    if(nrow(datafinal()[[2]]) == 0) {leafletProxy("mapplot") %>% clearShapes()} 
    else{
      leafletProxy("mapplot") %>% 
        clearShapes() %>% 
        addCircles(lng = datafinal()[[2]]$Longitude, lat = datafinal()[[2]]$Latitude, 
                   radius = 0.1, color = ifelse(datafinal()[[2]]$crime_type == 1, "blue", "red"))
    }
  })
  
  # Observe party event
  
  party_icon <- iconList(
    party = makeIcon("icon_beer.png", "icon_beer@2x.png", 36, 36)
  )

  observe({
    if(nrow(datafinal()[[1]]) == 0) {leafletProxy("mapplot") %>% clearMarkers()} 
    else{
      leafletProxy("mapplot") %>% 
      clearMarkerClusters() %>% 
      addMarkers(lng = datafinal()[[1]]$Longitude, lat = datafinal()[[1]]$Latitude,
                 clusterOptions = markerClusterOptions(),
                 icon = party_icon)
    }
  })
  
  
  ######################### Crime Analysis #########################
  # Crime Analysis: Keran Li
  output$selected_var <- renderPlot({
    
    if(input$var == "TOTAL")
      {
        data<- nypd17[which(nypd17$month >= input$range[1] & nypd17$month <= input$range[2]), ]
    }
    if(input$var != "TOTAL")
      {
      data<- nypd17[which(nypd17$month>=input$range[1]&nypd17$month<=input$range[2]&
                          nypd17$LAW_CAT_CD==input$var ), ]
    }
    
    ggplot(data, aes(BORO_NM))+ 
      geom_bar(aes(fill = clublocation), width = 0.5) + 
      theme(axis.text.x = element_text(angle = 65, vjust = 0.6)) +
      plotTheme() +
      labs(subtitle ="Boroughs across Party Location") 
  })
  
  output$yearplot<- renderPlotly({
    print(
      ggplotly(
    ggplot(felony1, aes(variable, value, group = factor(base)))+
      geom_line(aes(color = factor(base)))+
      plotTheme() +
      labs(x = "Year",y = "Number of Crimes",title = "Seven Type of Felony")+
       geom_point(color = "pink3") + theme_gdocs()))
  })
  
  output$mymap <- renderLeaflet({
    leaflet(data = nyc) %>%
      addTiles() %>%
      addPolygons(color = "#444444", weight = 1, fillColor = ~pal(num), smoothFactor = 0.5,
                  opacity = 0.7, fillOpacity = 0.5,
                  highlightOptions = highlightOptions(color = "white", weight = 2,
                                                      bringToFront = TRUE),
                  label = labels,
                  labelOptions = labelOptions(
                                   style = list("font-weight" = "normal", padding = "3px 8px"),
                                   textsize = "15px",
                                   direction = "auto")) %>%
      setView(-73.935242, 	40.730610, zoom = 10.5) %>%
      addLegend(pal = pal, values = ~num, opacity = 0.7, title = NULL,
                position = "topleft")
  })
  
  
  ######################### Party Analysis #########################
  # Party Analysis: Mengqi Chen
  selected <- reactive({
    # req(input$date)
    # validate(need(!is.na(input$date[1]) & !is.na(input$date[2]), "Error: Please provide both dates."))
    # validate(need(input$date[1] < input$date[2], "Error: Start date should be earlier than end date."))
    if(input$work==2){
      party %>% filter(
        open.date > as.Date(input$date[1]) & open.date < as.Date(input$date[2]))
    }else{
      party %>% 
        filter(open.date > as.Date(input$date[1]) & open.date < as.Date(input$date[2])) %>%
        filter(work == input$work)
      
    } 
  })
  

  output$histplot<- renderPlotly({
    print(
      ggplotly(
        ggplot(selected())+
          geom_histogram(aes(x = selected()$Borough,fill=Location.Type), stat="count",na.rm=T)+
          theme(axis.text.x =element_text(vjust=1)) + 
          plotTheme() +
          scale_fill_manual(values=c("steelblue2", "sienna2", "thistle2",
                                     "cyan3", "pink3", "lightseagreen"),
                            labels=c("Residential Building/House","Street/Sidewalk",
                                     "Club/Bar/Restaurant", "Store/Commercial",
                                     "Park/Playground", "House of Worship")
          )))
  })
  
  output$cmqplot<- renderPlotly({
    print(
      ggplotly(
        ggplot(data.frame(as.character(month)))+
          geom_bar(aes(x=month,fill=month), stat = "count")+
          labs(title="The number of parties in each month",caption="There are more parties in summer")+
          plotTheme()))
  })
  
})
