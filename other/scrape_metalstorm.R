scrape_metalstorm <- function(){
  
  msbands <- "https://metalstorm.net/bands/"
  
  pages <- read_html(msbands) %>% html_nodes("div.container") %>% html_nodes("div.pull-right") %>% html_nodes("ul.pagination") %>% html_nodes("li") %>% html_nodes("a") %>% html_text() %>% tail(.,1) %>% as.numeric(.)
  
  pages_href <- sapply(1:pages, function(i){
    paste0("https://metalstorm.net/bands/index.php?b_sortby=&b_where=&b_what=&page=",i)})
  
  scraped <- list(rep(NA,pages))
  
  t1 <- Sys.time()
  
  pg_read <- lapply(1:pages, function(page){
    pg_read <- read_html(pages_href[page])
  })
  
  Sys.time() - t1
  
  if(Sys.info()['sysname'] == "Windows"){
    
    n.cores <- parallel::detectCores()-1
    
    my.cluster <- parallel::makeCluster(
      n.cores, 
      type = "PSOCK"
    )
    
    doParallel::registerDoParallel(cl = my.cluster)
    
    scraped <- foreach(page = 1:pages) %dopar% {
      
      
      bands_and_styles0 <- pg_read[[page]]  %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td") %>% html_nodes("a") %>% html_text() %>% trimws(.)
      
      stops <- which(bands_and_styles0 == "")
      stops2 <- append(stops[2:length(stops)],length(bands_and_styles0)+1)
      
      bands <- bands_and_styles0[stops+1]
      
      styles <- sapply(1:length(stops), function(i){
        paste(bands_and_styles0[(stops[i]+2):(stops2[i]-1)],collapse = ",")
      })
      
      origins <- pg_read[[page]] %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(5)") %>% html_text() %>% gsub("\n","",.) %>% gsub("\t","",.)
      
      suppressWarnings({
        
        formed <- pg_read[[page]]  %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(6)") %>% html_text() %>% as.numeric(.)
        
        
        split <- pg_read[[page]]  %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(7)") %>% html_text() %>% as.numeric(.)
      })
      
      fans <- pg_read[[page]] %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(8)") %>% html_text() %>% as.numeric(.)
      
      data.frame(band_name= bands, style = styles,origin = origins,
                 formed = formed,split = split,fans = fans)
    }
    
    
    
    parallel::stopCluster(cl = my.cluster)
    
    
  }else{
    
    scraped <- mclapply(1:pages, function(page){
      
      
      bands_and_styles0 <- pg_read[[page]]  %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td") %>% html_nodes("a") %>% html_text() %>% trimws(.)
      
      stops <- which(bands_and_styles0 == "")
      stops2 <- append(stops[2:length(stops)],length(bands_and_styles0)+1)
      
      bands <- bands_and_styles0[stops+1]
      
      styles <- sapply(1:length(stops), function(i){
        paste(bands_and_styles0[(stops[i]+2):(stops2[i]-1)],collapse = ",")
      })
      
      origins <- pg_read[[page]] %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(5)") %>% html_text() %>% gsub("\n","",.) %>% gsub("\t","",.)
      
      suppressWarnings({
        
        formed <- pg_read[[page]]  %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(6)") %>% html_text() %>% as.numeric(.)
        
        
        split <- pg_read[[page]]  %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(7)") %>% html_text() %>% as.numeric(.)
      })
      
      fans <- pg_read[[page]] %>% html_nodes("div.container") %>% html_nodes("div.cbox") %>% html_nodes("table") %>% html_nodes("tr") %>% html_nodes("td:nth-child(8)") %>% html_text() %>% as.numeric(.)
      
      data.frame(band_name= bands, style = styles,origin = origins,
                 formed = formed,split = split,fans = fans)
    },mc.cores = detectCores()-2)
    
  }
  
  return(scraped)
}