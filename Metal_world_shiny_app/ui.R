#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(data.table)
library(stringr)
library(dplyr)
library(wordcloud)
library(wordcloud2)
library(viridis)
library(maps)

DTT <- readRDS("../data/metal_bands_shiny")

countries0 <- unique(trimws(unlist(str_split(unique(DTT$origin),','))))
countries <- countries0[countries0 != ""]

lenC <- length(countries)

dtClists <- lapply(1:lenC, function(i){
  countries_select <- grepl(countries[i],DTT$origin)
  list(data = DTT[countries_select,],count = sum(countries_select),
       fans = sum(DTT[countries_select,"fans"]))
})

band_by_countries <- rbindlist(lapply(1:lenC, function(i){data.frame(origin = countries[i],
                                                                     count=dtClists[[i]]$count,
                                                                     fans=dtClists[[i]]$fans)}))


# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Metal World Dashboard"),

    tags$style(HTML(".js-irs-0 .irs-single, .js-irs-0 .irs-bar-edge, .js-irs-0 .irs-bar {background: purple}")),
    
    
    # Row layaout
    fluidRow(
      column(9,    
             plotOutput("worldMap")),
      column(3,
             sliderInput("years",
                         "Bands that existed in the year:",
                         min = min(as.numeric(DTT$formed)+1,na.rm = T),
                         max = max(as.numeric(DTT$formed),na.rm = T),
                         value = max(as.numeric(DTT$formed),na.rm = T),
                         sep = ""),
             selectInput('countries', 'Countries', c("ALL",arrange(band_by_countries,by=desc(fans))$origin)),
             selectInput('status', 'Band status', c("ALL","Active","Split")),
             selectInput('colab', "Artist\'s origin", c("ALL","International","National"))
    ),
    fluidRow(
      column(4,
             plotOutput("barplot")
             ),
      column(4,
             plotOutput("freqpoly")
             ),
      column(4,
             wordcloud2Output("wordCloud"))
             )
      
    )
  
  
    
))
