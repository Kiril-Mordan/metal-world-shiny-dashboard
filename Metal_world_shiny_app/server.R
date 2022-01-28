#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(data.table)
library(stringr)
library(ggplot2)
library(dplyr)
library(wordcloud)
library(wordcloud2)
library(viridis)
library(foreach)
library(doParallel)



DTT <- readRDS("../data/metal_bands_shiny")

world <- map_data("world")

n.cores <- parallel::detectCores()-1

if(Sys.info()['sysname'] == "Windows"){
  
  my.cluster <- parallel::makeCluster(
    n.cores, 
    type = "PSOCK"
  )
  
  doParallel::registerDoParallel(cl = my.cluster)
}


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  DTR <- reactive({

  if(input$status == "Active"){
      active = is.na(DTT$split)
      DTT <- DTT[active]
  }else if(input$status == "Split"){
      split = !is.na(DTT$split)
      DTT <- DTT[split]
  }
    
  
  if(input$countries == "ALL"){
    DTT <- DTT[year <= input$years]
  }else{
    DTT <- DTT[grepl(input$countries,DTT$origin),]
    DTT <- DTT[year <= input$years]
  }
  
  if(input$colab != "ALL"){
    DTT <- DTT[colab == input$colab]
  }
  
  
  DTT
  })
  
  output$worldMap <- renderPlot({
    
    # prepare data for the the map
    
    DT <- DTR()
    
    countries0 <- unique(trimws(unlist(str_split(unique(DT$origin),','))))
    countries <- countries0[countries0 != ""]
    
    lenC <- length(countries)
    
    dtClists <- list(rep(NA,lenC)) 
    
    if(Sys.info()['sysname'] == "Windows"){
    
    dtClists <- foreach(i = 1:lenC) %dopar% {
      countries_select <- grepl(countries[i],DT$origin)
      list(count = sum(countries_select),
           fans = sum(DT[countries_select,"fans"]))
      
      band_by_countries <- rbindlist(
        
        foreach(i = 1:lenC) %dopar% {data.frame(origin = countries[i],
                                             count=dtClists[[i]]$count,
                                             fans=dtClists[[i]]$fans)}
      )
      
    }
    }else{
      dtClists <- mclapply(1:lenC, function(i){
        countries_select <- grepl(countries[i],DT$origin)
        list(count = sum(countries_select),
             fans = sum(DT[countries_select,"fans"]))
      },mc.cores=n.cores)
      
      
      band_by_countries <- rbindlist(
        
        mclapply(1:lenC,function(i){data.frame(origin = countries[i],
                                             count=dtClists[[i]]$count,
                                             fans=dtClists[[i]]$fans)},mc.cores = n.cores)
      )
    }
    
    
    # draw the world map 
    
    world %>%
      merge(band_by_countries, by.x = "region", by.y = "origin", all.x = T) %>%
      arrange(group, order) %>%
      ggplot(aes(x = long, y = lat, group = group, fill = count)) +
      geom_polygon(color = "grey", size = 0.2) +
      scale_fill_gradientn(colours = viridis(10),name = "Number\nof bands\nin the country", trans = "log",
                           na.value = "grey90",labels = scales::number_format(accuracy = 1)) +
      
      theme_minimal() +
      theme(axis.text = element_blank(),
            axis.title = element_blank(),
            panel.grid = element_blank()) 
    
  })
  
  
    
    output$wordCloud <- renderWordcloud2({
      
      
      DT <- DTR()
      
      DT_band <- DT
      
      DT_band$fans <- DT_band$fans+1
    

      
      sum_fans <- sum(DT_band$fans)
      
      band_data1 <- data.frame(word = DT_band$band_name,freq = DT_band$fans)
      
      if(nrow(band_data1) == 1){
        band_data1 <- rbind(band_data1,band_data1)
      }
      
      wordcloud2(data=band_data1, color='random-dark',shape = 'pentagon')
      
    })
    
    output$freqpoly <- renderPlot({
      
      DT <- DTR()
      
      count_by_formed0 <- DT[,.N,by=formed]
      count_by_formed <- count_by_formed0[complete.cases(count_by_formed0),]
      
      years_by_count0 <- rep(count_by_formed$formed,count_by_formed$N)
      years_by_count <- data.frame(years = as.integer( years_by_count0[complete.cases(years_by_count0)]))
      
      # draw the freqpoly
      
      ggplot(years_by_count ,aes(x=years,colour=1)) + geom_freqpoly(bins = 30) +
        scale_colour_gradientn(colours = "#3F007D") +
        theme_minimal()+
        theme(legend.position = "none" ,panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
              panel.background = element_blank(), axis.line = element_line(colour = "black")) +
        xlab("Years of formation for the selected bands") +
        ylab("Number of bands formed in the year")
      
      
    })
    
    output$barplot <- renderPlot({
      # prepare data for barplot
      
      DT <- DTR()
      
      styles0 <- trimws(unique(unlist(str_split(unique(DT$style),','))))
      
      styles1 <- styles0[styles0!=""]
      styles <- styles1[!is.na(styles1)]
      
      lenS <- length(styles)
      
  
      if(Sys.info()['sysname'] == "Windows"){
      dtSlists <- foreach(i = 1:lenS) %dopar% {
        styles_select <- grepl(styles[i],DT$style)
        list(fans=sum(DT[styles_select,"fans"]))
      }
      
      fans_by_style <- NULL
      fans_by_style <- rbindlist(
        foreach(i = 1:lenS) %dopar% {data.frame(style = styles[i],fans=dtSlists[[i]]$fans)}
        )
      
      }else{
        dtSlists <- mclapply(1:lenS, function(i){
          styles_select <- grepl(styles[i],DT$style)
          list(fans=sum(DT[styles_select,"fans"]))
        },mc.cores = n.cores)
        
        fans_by_style <- NULL
        fans_by_style <- rbindlist(
          mclapply(1:lenS, function(i){data.frame(style = styles[i],fans=dtSlists[[i]]$fans)},mc.cores=n.cores)
        )
      }
      
      styles_fans <- arrange(fans_by_style,by=desc(fans))[1:min(5,nrow(fans_by_style)),]
      
      # draw the barplot
      
      ggplot(styles_fans,aes(y=reorder(style, fans),x=fans,fill=reorder(style, fans))) + geom_bar(stat="identity") +
        scale_fill_brewer(palette = "BuPu") +
        theme_minimal() +
        theme(legend.position = "none") + 
        ylab("Most common styles") +
        xlab("Fans on metalstorm.net")
      
      
      
    })

})