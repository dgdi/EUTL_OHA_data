#safe function to download xml
library(xml2)
library(purrr)
safe_download_xml <- safely(download_xml)

# logfilename <- logfilename_1
#function to download the page and log outcomes
download_page_and_log <- function(url_loop,
                                  pagefilename_loop,
                                  logfilename,
                                  country_loop,
                                  ma_loop,
                                  phase_loop,
                                  compliance_loop,
                                  wait_time) {
  #download the page (and compute the time needed to download)
  tik <- Sys.time()
  down_output <-
    safe_download_xml(url = url_loop, file = pagefilename_loop)
  tok <- Sys.time()
  
  #if the page download took more that 6 minutes
  if (as.period((tok - tik)) > (minutes(5) + seconds(59)) |
      (!file.exists(pagefilename_loop))) {
    #extract the error
    error_loop <- down_output$error
    #if the error is null, set it to "error not reported"
    if (is.null(down_output$error)) {
      down_output_error <- "error not reported"
    } else{
      down_output_error <- error_loop
    }
    #print error message
    print(
      paste0(
        "Country: ",
        country_loop,
        " - Activity: ",
        ma_loop,
        " - Phase: ",
        phase_loop,
        " - Compliance: ",
        compliance_loop,
        "   ---   ******ERROR******"
      )
    )
    #write error message
    write.table(
      x = data.frame(
        country_loop,
        ma_loop,
        phase_loop,
        compliance_loop,
        "error"
      ),
      sep = ",",
      file = logfilename,
      append = TRUE,
      row.names = FALSE,
      col.names = FALSE
    )
    #remove the downloaded page with error
    Sys.sleep(wait_time)
    if (file.exists(pagefilename_loop)) {
      file.remove(pagefilename_loop)
    }
    #if the page is empty
  } else if (readLines(pagefilename_loop, n = 1) == "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">") {
    #print empty message
    print(
      paste0(
        "Country: ",
        country_loop,
        " - Activity: ",
        ma_loop,
        " - Phase: ",
        phase_loop,
        " - Compliance: ",
        compliance_loop,
        "   ---   ______empty______"
      )
    )
    #write empty message
    write.table(
      x = data.frame(
        country_loop,
        ma_loop,
        phase_loop,
        compliance_loop,
        "empty"
      ),
      sep = ",",
      file = logfilename,
      append = TRUE,
      row.names = FALSE,
      col.names = FALSE
    )
    #remove the downloaded empty page
    Sys.sleep(wait_time)
    file.remove(pagefilename_loop)
    
    #if the download of the page was fine
  } else{
    #print loop progress
    print(
      paste0(
        "Country: ",
        country_loop,
        " - Activity: ",
        ma_loop,
        " - Phase: ",
        phase_loop,
        " - Compliance: ",
        compliance_loop,
        "   ---   ok"
      )
    )
    #write loop progress
    write.table(
      x = data.frame(country_loop, ma_loop, phase_loop, compliance_loop,  "ok"),
      sep = ",",
      file = logfilename,
      append = TRUE,
      row.names = FALSE,
      col.names = FALSE
    )
    Sys.sleep(wait_time)
    
  }
}

n_downpages_fun <- function(dfolder) {
  #identify the name of all the log files
  log_files <-
    list.files(
      dfolder,
      recursive = FALSE,
      include.dirs = FALSE,
      pattern = "^log_",
      full.names = TRUE
    )
  
  #create a dt with all the logfiles
  log_dt <- rbindlist(lapply(log_files, fread))
  
  #create a dt with all the downloaded pages (both empty and non-empty)
  pagedown_dt <- unique(log_dt[check != "error"])
  
  #compute the number of pages downloaded without error
  pagedown_dt[, .N]
}


##parse the xml EUTLOHApages information into data.table format (perform the computation of each country on a different core)
xml_to_table_fun <-
  function(dfolder,
           ETSinfo_varnames,
           ma99 = NULL,
           cluster = NULL) {
    if (is.null(ma99)) {
      print("The variable ma99 should be TRUE or FALSE")
    }
    
    #identify the EUTLOHApages filenames
    EUTLOHApageNames <-
      list.files(
        dfolder,
        recursive = FALSE,
        include.dirs = FALSE,
        pattern = "xml$"
      )
    
    #identify country of EUTLOHApages
    countries <- substr(EUTLOHApageNames, start = 1, stop = 2)
    
    #identify unique country of EUTLOHApages
    unique_countries <- unique(countries)
    
    if (is.null(cluster)) {
      loop_fun <- lapply
    } else{
      loop_fun <- pblapply
    }
    rbindlist(#loop through the National Administrators (country)
      loop_fun(unique_countries, cl = cl, function(countryLoop) {
        ##check single
        # countryLoop <- "BG"
        # EUTLOHApageNames_countryLoop_allma <- EUTLOHApageNames[which(countries == countryLoop)]
        # EUTLOHApageNames_countryOnepageLoop <- EUTLOHApageNames_countryLoop_allma[31]
        # instLoop <- 1
        
        ##check multiple
        # for(countryLoop in unique_countries#[25:length(countries)]){
        # countryLoop = unique_countries[1]
        
        #identify filenames of the EUTLOHApages matching the countryLoop
        EUTLOHApageNames_countryLoop_allma <-
          EUTLOHApageNames[which(countries == countryLoop)]
        
        #set the main activity type of pages to be processed
        if (ma99 == TRUE) {
          # processes only the EUTLOHApages with all the main activities "-1"
          EUTLOHApageNames_countryLoop <-
            EUTLOHApageNames_countryLoop_allma[grep("^[A-Z][A-Z]_-1", EUTLOHApageNames_countryLoop_allma)]
          
        } else if (ma99 == FALSE) {
          # exclude the EUTLOHApages of every country with main activity "-1" (all)
          EUTLOHApageNames_countryLoop <-
            EUTLOHApageNames_countryLoop_allma[-grep("^[A-Z][A-Z]_-1", EUTLOHApageNames_countryLoop_allma)]
        }
        #parse the xml EUTLOHApages of countryLoop information into data.table format
        country_data_loop <-
          rbindlist(lapply(EUTLOHApageNames_countryLoop, function(EUTLOHApageNames_countryOnepageLoop) {
            #read EUTLOHApage
            EUTLOHApage <-
              xmlToList(paste0(dfolder, "/", EUTLOHApageNames_countryOnepageLoop))
            
            #identify the country (long format e.g, "Austria") of EUTLOHApage
            country <-
              EUTLOHApage$OHADetailsCriteria$Account$NationalAdministrator
            
            #extract list of emissions by installation
            EUTLOHApage_instTot <-
              EUTLOHApage$OHADetails
            
            #create a data.table to store emissions data for the EUTLOHApage EUTLOHApageNames_countryOnepageLoop
            emissions_EUTLOHApageNames_countryOnepageLoop <-
              rbindlist(#loop through the EUTLOHApage data by installation
                lapply(seq_along(EUTLOHApage_instTot), function(instLoop) {
                  #select the installation in position instLoop
                  EUTLOHApage_instLoop <-
                    EUTLOHApage_instTot[[instLoop]]
                  
                  #identifying the emissions data
                  emissions_pos <-
                    which(names(EUTLOHApage_instLoop$Installation) == "Compliance")
                  
                  #selecting the emissions data
                  emissions_list <-
                    EUTLOHApage_instLoop$Installation[emissions_pos]
                  
                  #create a data.table to store emissions data by installation
                  emissions_inst_loop <-
                    data.table(
                      Year = as.integer(map_chr(
                        emissions_list, "Year", .default = NA
                      )),
                      NationalAdministratorCode = EUTLOHApage_instLoop[["NationalAdministratorCode"]],
                      MainActivityTypeCode = EUTLOHApage_instLoop$Installation[["MainActivityTypeCode"]],
                      AccountHolderName = EUTLOHApage_instLoop[["AccountHolderName"]],
                      InstallationNameOrAircraftOperatorCode = EUTLOHApage_instLoop$Installation[["InstallationNameOrAircraftOperatorCode"]],
                      InstallationOrAircraftOperatorID = EUTLOHApage_instLoop$Installation[["InstallationOrAircraftOperatorID"]],
                      AccountStatus = EUTLOHApage_instLoop[["AccountStatus"]],
                      PermitOrPlanID = EUTLOHApage_instLoop$Installation[["PermitOrPlanID"]],
                      #creating a data.frame from the list of emissions variables (missings are encoded as NA)
                      sapply(ETSinfo_varnames, function(dgdi) {
                        unlist(unname(map(
                          emissions_list, dgdi, .default = NA
                        )))
                      })
                    )
                  
                  #return the data.table with emissions data by installation
                  emissions_inst_loop
                }))
            
            #return the data.table with emissions data by EUTLOHApage
            emissions_EUTLOHApageNames_countryOnepageLoop
          }))
        
        #return the data.table with emissions data by country
        country_data_loop
      }))
    
  }
