#clear the environment
rm(list = ls())

#load libraries
library(data.table)
library(here)
library(methods)
library(utils)
library(XML)

#set timeout (for connections) to 6 minutes
options(timeout = 3600)

# source general parameters
source(here("R/pars.R"))

# source functions
source(here("R/fun.R"))

#set download folder path
dfolder <- here(dfolder_name)

#set the scraper report filename
scraperreportfilename <- "EUTLOHA_scraper_report"

#create download folder if it does not exists
if (!dir.exists(dfolder)) {
  dir.create(dfolder)
}

# set wait_time to slow down the scraping (and avoid being blocklisted)
wait_time <- 1

# set max percentage errors - if the number of errors is above this threshold there are major issues (website down, change in the website structure, etc)
#in this case we do not try to re-download the error-pages, the scraper is halted and the error is logged
max_rel_errors <- 10

# save start time
start_time <- Sys.time()
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#### Retrieval of codes for url building  ####
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

#I retrieve the list of "National Administrators", "Main Activity Type" and "Compliance Status" from
# "https://ec.europa.eu/clima/ets/oha.do""https://ec.europa.eu/clima/ets/oha.do"
page_manycodes <-
  htmlParse(readLines(url(
    "https://ec.europa.eu/clima/ets/oha.do"
  )), encoding = "UTF-8")

#disply National Administrator - (country)
unlist(
  xpathApply(
    page_manycodes,
    '//select[@name="account.registryCodes"]/option',
    xmlValue
  )
)

#retrieve country codes
country_codes_raw <-
  unlist(
    xpathApply(
      page_manycodes,
      '//select[@name="account.registryCodes"]/option',
      xmlGetAttr,
      name = "value"
    )
  )

#removing the empty entry from country_codes
country_codes <- country_codes_raw[country_codes_raw != ""]
country_codes

#display Main Activity Type - (ma)
unlist(
  xpathApply(
    page_manycodes,
    '//select[@name="mainActivityType"]/option',
    xmlValue
  )
)
# c("All", "Combustion of fuels", "Refining of mineral oil", "Production of coke",
#   "Metal ore roasting or sintering", "Production of pig iron or steel",
#   "Production or processing of ferrous metals", "Production of primary aluminium",
#   "Production of secondary aluminium", "Production or processing of non-ferrous metals",
#   "Production of cement clinker", "Production of lime, or calcination of dolomite/magnesite",
#   "Manufacture of glass", "Manufacture of ceramics", "Manufacture of mineral wool",
#   "Production or processing of gypsum or plasterboard", "Production of pulp",
#   "Production of paper or cardboard", "Production of carbon black",
#   "Production of nitric acid", "Production of adipic acid", "Production of glyoxal and glyoxylic acid",
#   "Production of ammonia", "Production of bulk chemicals", "Production of hydrogen and synthesis gas",
#   "Production of soda ash and sodium bicarbonate", "Capture of greenhouse gases under Directive 2009/31/EC",
#   "Transport of greenhouse gases under Directive 2009/31/EC", "Storage of greenhouse gases under Directive 2009/31/EC",
#   "Combustion installations with a rated thermal input exceeding 20 MW",
#   "Mineral oil refineries", "Coke ovens", "Metal ore (including sulphide ore) roasting or sintering installations",
#   "Installations for the production o...ion) including continuous casting",
#   "Installations for the production o...rotary kilns or in other furnaces",
#   "Installations for the manufacture of glass including glass fibre",
#   "Installations for the manufacture ...ks, tiles, stoneware or porcelain",
#   "Industrial plants for the producti...ous materials (b) paper and board",
#   "Aircraft operator activities", "Other activity opted-in pursuant to Article 24 of Directive 2003/87/EC"
# )

#retrieve ma codes
ma_codes <-
  unlist(
    xpathApply(
      page_manycodes,
      '//select[@name="mainActivityType"]/option',
      xmlGetAttr,
      name = "value"
    )
  )
ma_codes
# ma_codes <- c("-1", "20", "21", "22", "23", "24", "25",
#               "26", "27", "28",
#   "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
#   "40", "41", "42", "43", "44", "45", "46", "47", "1", "2", "3",
#   "4", "5", "6", "7", "8", "9", "10", "99")
# display Compliance Status - (compliance_codes)
unlist(
  xpathApply(
    page_manycodes,
    '//select[@name="account.complianceStatusArray"]/option',
    xmlValue
  )
)
#c("None", "-", "A", "B", "C", "D", "E", "X")

#retrieve compliance_codes
compliance_codes <-
  unlist(
    xpathApply(
      page_manycodes,
      '//select[@name="account.complianceStatusArray"]/option',
      xmlGetAttr,
      name = "value"
    )
  )
compliance_codes

#the values to select the ETS phase can be retrieved once the other variables are selected. Without loss of generality I use:
#https://ec.europa.eu/clima/ets/choosePeriodsEntry.do?accountID=93707&action=select&languageCode=en&returnURL=installationName%3D%26accountHolder%3D%26search%3DSearch%26permitIdentifier%3D%26form%3Doha%26searchType%3Doha%26mainActivityType%3D20%26currentSortSettings%3D%26account.complianceStatusArray%3DA%26installationIdentifier%3D%26account.registryCodes%3DAT%26languageCode%3Den&registryCode=IT
page_phase_codes <-
  htmlParse(readLines(
    url(
      "https://ec.europa.eu/clima/ets/choosePeriodsEntry.do?accountID=93707&action=select&languageCode=en&returnURL=installationName%3D%26accountHolder%3D%26search%3DSearch%26permitIdentifier%3D%26form%3Doha%26searchType%3Doha%26mainActivityType%3D20%26currentSortSettings%3D%26account.complianceStatusArray%3DA%26installationIdentifier%3D%26account.registryCodes%3DAT%26languageCode%3Den&registryCode=IT"
    )
  ), encoding = "UTF-8")

#EU ETS Phase(s) - (phase_codes)
phase_codes <-
  as.integer(unlist(
    xpathApply(
      page_phase_codes,
      '//input[@type="checkbox"]',
      xmlGetAttr,
      name = "value"
    )
  ))

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#### Download of all the pages  ####
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# set log filename
logfilename_1 <- paste0(dfolder, "/", "log_", 1, ".txt")

#create log with named columns
if (!file.exists(logfilename_1)) {
  write.table(
    x = t(c(
      "country", "activity", "phase", "compliance", "check"
    )),
    sep = ",",
    file = logfilename_1,
    append = FALSE,
    row.names = FALSE,
    col.names = FALSE
  )
}
# download all the EUTL OHA pages by looping through activity, country, phase and compliance
for (ma_Mloop in ma_codes) {
  for (country_Mloop in country_codes) {
    for (phase_Mloop in phase_codes) {
      for (compliance_Mloop in compliance_codes) {
        ## single test
        # country_Mloop <- "BU"
        # ma_Mloop <- 20
        # phase_Mloop <- 2
        # compliance_Mloop <- "A"
        
        # ## multiple test
        # for (ma_Mloop in ma_codes[10:11]) {
        #   for (country_Mloop in country_codes[1:2]) {
        #     for (phase_Mloop in phase_codes[1:2]) {
        #       for (compliance_Mloop in compliance_codes[1:3]) {
        
        #create the url of the page to download
        url_Mloop <-
          paste0(
            "https://ec.europa.eu/clima/ets/exportEntry.do?installationName=&permitIdentifier=&searchType=oha&mainActivityType=",
            ma_Mloop,
            "&accountType=&selectedPeriods=",
            phase_Mloop,
            "&complianceStatus=&account.registryCodes=",
            country_Mloop,
            "&languageCode=en&account.registryCode=&accountStatus=&accountID=&accountHolder=&form=ohaDetails&registryCode=&account.complianceStatusArray=",
            compliance_Mloop,
            "&installationIdentifier=&action=&primaryAuthRep=&identifierInReg=&returnURL=&buttonAction=select&exportType=1&exportAction=ohaDetails&exportOK=exportOK"
          )
        
        #create the file_path of the page to download
        pagefilename_Mloop <- paste0(
          dfolder,
          "/",
          country_Mloop,
          "_",
          ma_Mloop,
          "_",
          phase_Mloop,
          "_",
          compliance_Mloop,
          ".xml"
        )
        
        #download the page and log the outcome
        download_page_and_log(
          url_loop = url_Mloop,
          pagefilename_loop = pagefilename_Mloop,
          logfilename = logfilename_1,
          country_loop = country_Mloop,
          ma_loop = ma_Mloop,
          phase_loop = phase_Mloop,
          compliance_loop = compliance_Mloop,
          wait_time = wait_time
        )
        
      }
    }
  }
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#### Additional tries to download pages that raised an error ####
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# set max additional attempts to re-download pages where an error has occurred
max_additional_tries <- 9

#compute the number of pages to query (to evaluate the share of missing ones)
n_pagesTOT <- length(ma_codes) * length(country_codes) *
  length(phase_codes) * length(compliance_codes)

#external loop to retry the download of pages that raised an error
for (n_addtry in 1:(max_additional_tries + 1)) {
  #single test
  # n_addtry = 2
  
  # set log filename
  logfilename_Sloop_toread <-
    paste0(dfolder, "/", "log_", n_addtry, ".txt")
  #read the log
  log_read_Sloop <- fread(file = logfilename_Sloop_toread)
  
  #check if there have been errors during download
  errors_dt_Sloop <- log_read_Sloop[check == "error"]
  
  #computing number of errors
  n_errors_Sloop <- errors_dt_Sloop[, .N]
  
  #computing the pct of errors relative to the total pages scraped
  rel_errors_Sloop <-
    100 * n_errors_Sloop / (n_pagesTOT)
  
  #if there are no errors
  if (rel_errors_Sloop == 0) {
    #save the end time
    end_time <- Sys.time()
    
    #identifies all the pages that have been correctly queried
    n_pages <- n_downpages_fun(dfolder)
    
    #check that the code has queried without error all the pages
    if (n_pages == n_pagesTOT) {
      #create success message
      message <-
        paste0(
          "The scraping is completed without errors --- ",
          "all the pages have been successfully queried in the timspan (",
          start_time,
          " - ",
          end_time,
          ")"
        )
    } else{
      message <- paste0(
        "The scraping is completed without errors --- ",
        round(100 * n_pages / n_pagesTOT, 3),
        "% of the pages ",
        "(",
        n_pages,
        "/",
        n_pagesTOT,
        ") have been queried in the timspan (",
        start_time,
        " - ",
        end_time,
        ")"
      )
    }
    #print success message
    print(message)
    
    #write success message
    write.table(
      x = message,
      sep = ",",
      file = paste0("data/", scraperreportfilename, ".txt"),
      append = TRUE,
      row.names = FALSE,
      col.names = FALSE
    )
    
    break
    
    #if the number of errors is above the threshold max_rel_errors (only really useful at the first iteration)
  } else if (rel_errors_Sloop > max_rel_errors) {
    #save the end time
    end_time <- Sys.time()
    
    #create failure  message
    message <-
      paste0(
        "The scraping has NOT been completed ---- too many errors. Queries performed in the timspan (",
        start_time,
        " - ",
        end_time,
        ")"
      )
    
    #print failure message - too many errors
    print(message)
    
    #write failure message - too many errors
    write.table(
      x = message,
      sep = ",",
      file = paste0("data/", scraperreportfilename, ".txt"),
      append = TRUE,
      row.names = FALSE,
      col.names = FALSE
    )
    
    break
    
    #if the number of errors is positive but below the threshold but we have performed already the maximum number of tries
  } else if (n_addtry > max_additional_tries) {
    #save the end time
    end_time <- Sys.time()
    
    #identifies all the pages that have been correctly queried
    n_pages <- n_downpages_fun(dfolder)
    
    #create failure message
    message <-
      paste0(
        "The scraping has been completed with errors --- ",
        round(rel_errors_Sloop, 3),
        "% of the pages still produce an error +++ ",
        round(100 * n_pages / n_pagesTOT, 3),
        "% of the pages ",
        "(",
        n_pages,
        "/",
        n_pagesTOT,
        ") have been in the timspan (",
        start_time,
        " - ",
        end_time,
        ")"
      )
    
    #print message - errors are still present after max_additional_tries
    print(message)
    
    #write  message - errors are still present after max_additional_tries
    write.table(
      x = message,
      sep = ",",
      file = paste0("data/", scraperreportfilename, ".txt"),
      append = TRUE,
      row.names = FALSE,
      col.names = FALSE
    )
    
    break
    
    #if the number of errors is positive but below the threshold and we have not performed already the maximum number of tries
  } else{
    # wait 6 hours
    #(we skip it on the first additional try as the main loop takes a long time)
    if (n_addtry > 1) {
      Sys.sleep(60 * 60 * 6)
    }
    
    #set log filename
    logfilename_Sloop_towrite <-
      paste0(dfolder, "/", "log", "_", n_addtry + 1, ".txt")
    
    #create log with named columns
    write.table(
      x = t(c(
        "country", "activity", "phase", "compliance", "check"
      )),
      sep = ",",
      file = logfilename_Sloop_towrite,
      append = FALSE,
      row.names = FALSE,
      col.names = FALSE
    )
    
    #loop through the pages reported an error
    for (errorid_Sloop in 1:(errors_dt_Sloop[, .N])) {
      ma_Sloop <- errors_dt_Sloop[errorid_Sloop]$activity
      phase_Sloop <- errors_dt_Sloop[errorid_Sloop]$phase
      country_Sloop <- errors_dt_Sloop[errorid_Sloop]$country
      compliance_Sloop <- errors_dt_Sloop[errorid_Sloop]$compliance
      
      #create the url of the page to download
      url_Sloop <-
        paste0(
          "https://ec.europa.eu/clima/ets/exportEntry.do?installationName=&permitIdentifier=&searchType=oha&mainActivityType=",
          ma_Sloop,
          "&accountType=&selectedPeriods=",
          phase_Sloop,
          "&complianceStatus=&account.registryCodes=",
          country_Sloop,
          "&languageCode=en&account.registryCode=&accountStatus=&accountID=&accountHolder=&form=ohaDetails&registryCode=&account.complianceStatusArray=",
          compliance_Sloop,
          "&installationIdentifier=&action=&primaryAuthRep=&identifierInReg=&returnURL=&buttonAction=select&exportType=1&exportAction=ohaDetails&exportOK=exportOK"
        )
      
      #create the file_path of the page to download
      pagefilename_Sloop <- paste0(
        dfolder,
        country_Sloop,
        "_",
        ma_Sloop,
        "_",
        phase_Sloop,
        "_",
        compliance_Sloop,
        ".xml"
      )
      
      #download the page and log the outcome
      download_page_and_log(
        url_loop = url_Sloop,
        pagefilename_loop = pagefilename_Sloop,
        logfilename = logfilename_Sloop_towrite,
        country_loop = country_Sloop,
        ma_loop = ma_Sloop,
        phase_loop = phase_Sloop,
        compliance_loop = compliance_Sloop,
        wait_time = wait_time
      )
    }
  }
}
