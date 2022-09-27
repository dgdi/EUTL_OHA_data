#set general options
options(scipen = 999)
options(stringsAsFactors = FALSE)

#load libraries for parallel computations
library(foreach)
library(parallel)
library(doParallel)
library(pbapply)

#stop the parallel cluster
stopImplicitCluster()
stopCluster(cl)
registerDoSEQ()

#clear the environment
rm(list = ls())

#set the number of cores based on the machine
sys_name <- Sys.info()["nodename"]
if (sys_name == "5CG7033WN9") {
  cores <- 3
} else if (sys_name == "DESKTOP-TE9IT0J") {
  cores <- 2
} else if (sys_name == "MCRUEBS02") {
  cores <- 30
} else if (sys_name == "DESKTOP-1V7JKB1") {
  cores <- 6
}

#load libraries
library(data.table)
library(here)
library(methods)
library(purrr)
library(utils)
library(XML)

# source general parameters
source(here("R/pars.R"))

# source functions
source(here("R/fun.R"))

#set download folder path
dfolder <- here(dfolder_name)

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

#define required libraries for the parallel cluster
required_libraries <-
  c("here", "data.table", "XML", "pbapply", "purrr")

#start the parallel cluster (if not yet started)
if (!exists("cl")) {
  cl <- parallel::makeCluster(cores)
  clusterExport(cl,
                c(
                  "required_libraries",
                  "dfolder",
                  "EUTLOHApageNames",
                  "countries"
                ))
  clusterEvalQ(cl,
               lapply(required_libraries, require, character.only = TRUE))
}
# #identify the unique fields in $Installation$Compliance across all EUTLOHApages (perform the computation of each country on a different core)
# fields_InstallationCompliance <- sort(unique(unlist(
#   #loop through the National Administrators (country)
#   pblapply(unique_countries, cl = cl, function(countryLoop) {
#     #check single
#     # countryLoop <- unique_countries[1]
#     #check multiple
#     # for(countryLoop in unique_countries#[25:length(countries)]){
#     
#     #identify filenames of the EUTLOHApages matching the countryLoop
#     EUTLOHApageNames_countryLoop <-
#       EUTLOHApageNames[which(countries == countryLoop)]
#     
#     #identify the unique fields in $Installation$Compliance on the EUTLOHApages of countryLoop
#     fields_countryLoop <-
#       #loop through the EUTLOHApages of the countryLoop
#       unique(unlist(lapply(EUTLOHApageNames_countryLoop, function(EUTLOHApageNames_countryOnepageLoop) {
#         ##check single
#         # EUTLOHApageNames_countryOnepageLoop <- EUTLOHApageNames_countryLoop[1]
#         #check multiple
#         # for(EUTLOHApageNames_countryOnepageLoop in EUTLOHApageNames_countryLoop){
#         
#         #read EUTLOHApage
#         EUTLOHApage <-
#           xmlToList(paste0(dfolder, "/", EUTLOHApageNames_countryOnepageLoop))
#         
#         #identify the country (long format e.g, "Austria") of EUTLOHApage
#         country <-
#           EUTLOHApage$OHADetailsCriteria$Account$NationalAdministrator
#         
#         #extract list of emissions by installation
#         EUTLOHApage_instTot <- EUTLOHApage$OHADetails
#         
#         #identify and return the unique fields in $Installation$Compliance
#         as.list(sort(unique(unlist(
#           #loop through the list of emissions by installation
#           lapply(seq_along(EUTLOHApage_instTot), function(instLoop) {
#             EUTLOHApage_instLoop <- EUTLOHApage_instTot[[instLoop]]
#             
#             #identify the data on emissions
#             compliance_pos <-
#               which(names(EUTLOHApage_instLoop$Installation) == "Compliance")
#             
#             #select the data on emissions
#             compliance_list <-
#               EUTLOHApage_instLoop$Installation[compliance_pos]
#             
#             #identify unique $Installation$Compliance entries
#             unique(unlist(sapply(compliance_list, names)))
#           })
#         ))))
#       })))
#     #return the unique $Installation$Compliance entries by country
#     fields_countryLoop
#   })
# )))
# #display compliance_list_names
# fields_InstallationCompliance
# # [1] "AllowanceInAllocation"       "ComplianceCode"              "CumulativeSurrenderedUnits"
# # [4] "CumulativeVerifiedEmissions" "ETSPhase"                    "FreeAllocations"
# # [7] "ReserveAllocations"          "SurrenderedAllowances"       "TrasitionalAllocations"
# # [10] "UnitsSurrendered"            "VerifiedEmissions"

#define the names of emissions variables of interest
ETSinfo_varnames <-
  c(
    "ComplianceCode",
    "AllowanceInAllocation",
    "TrasitionalAllocations",
    "ReserveAllocations",
    "VerifiedEmissions", 
    "UnitsSurrendered", 
    "SurrenderedAllowances",
    "FreeAllocations"
  )




#export to the cluster the names emissions variables of interest
if (exists("cl")) {
  clusterExport(cl, c("ETSinfo_varnames", "safe_download_xml"))
}

#create the EUTL OHA dataset in tabular form using the xml pages of "Main Activity Type" All -(1)
EUTLOHA_ma99 <- xml_to_table_fun(
  dfolder = dfolder,
  ETSinfo_varnames = ETSinfo_varnames,
  ma99 = TRUE,
  cluster = cl
)

#save the EUTLOHA_ma99 dataset in compressed (gzip) csv format
fwrite(EUTLOHA_ma99,
       here("data/EUTLOHA_ma99.csv.gz"))

#create the EUTL OHA dataset in tabular form using the xml pages NOT of "Main Activity Type" All -(1)
EUTLOHA_maNOT99 <- xml_to_table_fun(
  dfolder = dfolder,
  ETSinfo_varnames = ETSinfo_varnames,
  ma99 = FALSE,
  cluster = cl
)

#save the EUTLOHA_maNOT99 dataset in compressed (gzip) csv format
fwrite(EUTLOHA_maNOT99,
       here("data/EUTLOHA_maNOT99.csv.gz"))
