library(rvest)
library(stringr)
library(parallel)
library(splitstackshape)
library(dplyr)
library(tidyr)
library(xml2)
library(parallel)
library(data.table)
source("src/func/scrape_metalstorm.R")

# Data was scraped from metalstorm.net
scraped <- scrape_metalstorm()

scraped_data <- rbindlist(scraped)

saveRDS(scraped_data,"data/metal_bands_scraped")

imported <- readRDS("data/metal_bands_scraped")
dt <- as.data.table(imported)


dt$style <- gsub("E,B,M","EBM",dt$style)
dt$style <- gsub("A,Cappella","A_Cappella",dt$style)
dt$style <- gsub("-,","-",dt$style)
dt$style <- gsub("'n,","'n ",dt$style)
dt$style <- gsub(",N',"," N' ",dt$style)

# cleaning origins column
dt$origin <- gsub("United Kingdom","UK",dt$origin)
dt$origin <- gsub("UAE","United Arab Emirates",dt$origin)
dt$origin <- gsub("Gibraltar","UK",dt$origin) # no Gibraltar in ggplot2 map_data("world")
dt$origin <- gsub("Hong Kong","China",dt$origin)
dt$origin <- gsub("Slovak Republic","Slovakia",dt$origin)
dt$origin <- gsub("The Netherlands","Netherlands",dt$origin)
dt$origin <- gsub("Korea","South Korea",dt$origin) # Korea assumed to be South Korea
dt$origin <- gsub(", South","",dt$origin)

# managing data types
dt$formed <- as.numeric(dt$formed)
dt$split <- as.numeric(dt$split)

# creating new columns

origins <- str_split((dt$origin),',')

n_origins <- sapply(1:nrow(dt),function(i){length(origins[[i]])})

dt$colab <- ifelse(n_origins>1,"International","National")

# if band doesn't have a year then the most resent from the data is assumed

dt$year <- ifelse(is.na(dt$formed),max(dt$formed,na.rm = T),dt$formed)


clean <- dt

saveRDS(clean,"data/metal_bands_shiny")
