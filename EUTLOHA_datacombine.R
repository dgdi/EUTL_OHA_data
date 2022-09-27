#clear the environment
rm(list = ls())

#load libraries
library(data.table)
library(here)
library(methods)
library(stringr)
library(utils)

#set timeout (for connections) to 6 minutes
options(timeout = 3600)

# source general parameters
source(here("R/pars.R"))

# source functions
source(here("R/fun.R"))

#set download folder path
dfolder <- here(dfolder_name)

EUTLOHA_ma99 <- fread(here("data/EUTLOHA_ma99.csv.gz"))
EUTLOHA_maNOT99 <- fread(here("data/EUTLOHA_maNOT99.csv.gz"))

#creating unique id
EUTLOHA_ma99[, id := paste(Year, NationalAdministratorCode, MainActivityTypeCode, InstallationOrAircraftOperatorID, sep = "_")]
EUTLOHA_maNOT99[, id := paste(Year, NationalAdministratorCode, MainActivityTypeCode, InstallationOrAircraftOperatorID,  sep = "_")]

#check that id uniquely identifies observations
EUTLOHA_ma99[, .N, by = id][, unique(N)]
EUTLOHA_maNOT99[, .N, by = id][, unique(N)]

#set key and order 
setkey(EUTLOHA_ma99, id)
setkey(EUTLOHA_maNOT99, id)
setorder(EUTLOHA_ma99, id)
setorder(EUTLOHA_maNOT99, id)

#check if there are some id in one but not the other dataset
setdiff(EUTLOHA_ma99$id, EUTLOHA_maNOT99$id)
setdiff(EUTLOHA_maNOT99$id, EUTLOHA_ma99$id)

#define variables to check
tocheck_varnames <-  c(
  "SurrenderedAllowances",
  "FreeAllocations", 
  "VerifiedEmissions", 
  "UnitsSurrendered", 
  "AllowanceInAllocation",
  "TrasitionalAllocations",
  "ReserveAllocations")

#merge the ma99 and maNOT99  data
EUTLOHA_merge <- merge(
  x = EUTLOHA_ma99,
  y = EUTLOHA_maNOT99[, c("id", tocheck_varnames), with = FALSE],
  by = "id",
  suffixes = c("_ma99", "_maNOT99")
)


#define names of columns to store "difference" check
checknames_D <- paste0(tocheck_varnames, "_D")

#identify the cases where both dt have are non-NA but are different
for(tocheck_varnames_loop in seq_along(tocheck_varnames)){
  
  EUTLOHA_merge[, (checknames_D[tocheck_varnames_loop]) := 
                       (get(paste0(tocheck_varnames[tocheck_varnames_loop], "_ma99")
                       ) != 
                         get(paste0(tocheck_varnames[tocheck_varnames_loop], "_maNOT99")
                         )
                       )
                     
  ]
  
}

#among the non-NA values there are no differences
EUTLOHA_merge[, colSums(.SD, na.rm = TRUE), .SDcols = checknames_D]

#define names of columns to identify observations where one of the two dataset have information not present in the other one ("M"ore information)
checknames_M <- sapply(c("_Mma99", "_MmaNOT99"), function(colname_temp){
  paste0(tocheck_varnames, colname_temp)
})

#identify the cases where ma99 or maNOT99 have more non-NA obs
for(tocheck_varnames_loop in seq_along(tocheck_varnames)){
  
  EUTLOHA_merge[, checknames_M[tocheck_varnames_loop, ] := .(FALSE, FALSE)]
  
  EUTLOHA_merge[!is.na(get(paste0(tocheck_varnames[tocheck_varnames_loop], "_ma99"))) & 
                     is.na(get(paste0(tocheck_varnames[tocheck_varnames_loop], "_maNOT99"))), 
                   checknames_M[tocheck_varnames_loop, 1] := TRUE
  ]
  
  EUTLOHA_merge[is.na(get(paste0(tocheck_varnames[tocheck_varnames_loop], "_ma99"))) & 
                     !is.na(get(paste0(tocheck_varnames[tocheck_varnames_loop], "_maNOT99"))), 
                   checknames_M[tocheck_varnames_loop, 2] := TRUE
  ]
}


#compute the number of cases where one of the two dataset have information not present in the other one
EUTLOHA_merge[, colSums(.SD, na.rm = TRUE), .SDcols = unlist(checknames_M)]
# SurrenderedAllowances_Mma99  2164 
# UnitsSurrendered_Mma99       2164
# SurrenderedAllowances_MmaNOT99    3462
# UnitsSurrendered_MmaNOT99         3525 

#define names of columns to store info from both ma99 and maNOT99 data
checknames_T <- paste0(tocheck_varnames, "_comb")

#create columns where the information from both datasets is combined
for(tocheck_varnames_loop in seq_along(tocheck_varnames)){
  
  EUTLOHA_merge[,  checknames_T[tocheck_varnames_loop] := get(paste0(tocheck_varnames[tocheck_varnames_loop], "_ma99"))]
  
  EUTLOHA_merge[is.na(get(paste0(tocheck_varnames[tocheck_varnames_loop], "_ma99"))) &
                       !is.na(get(paste0(tocheck_varnames[tocheck_varnames_loop], "_maNOT99"))),
                     
                     checknames_T[tocheck_varnames_loop] := get(paste0(tocheck_varnames[tocheck_varnames_loop], "_maNOT99"))]
  
}

#checks @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# #identify rows where Mma99 has less noNA
# rowid_check_Mma99 <- EUTLOHA_merge[, which(SurrenderedAllowances_Mma99 > 0)][1]
# 
# #check that the additional noNA obs in Mma99 are imputed
# EUTLOHA_merge[rowid_check_Mma99, .SD, .SDcols = paste0(tocheck_varnames, "_ma99")]
# EUTLOHA_merge[rowid_check_Mma99, .SD, .SDcols = paste0(tocheck_varnames, "_maNOT99")]
# EUTLOHA_merge[rowid_check_Mma99, .SD, .SDcols = paste0(tocheck_varnames, "_T")]
# 
# #identify rows where MmaNOT99 has less noNA
# rowid_check_MmaNOT99 <- EUTLOHA_merge[, which(SurrenderedAllowances_MmaNOT99 > 0)][1]
# 
# #check that the additional noNA obs in MmaNOT99 are imputed
# EUTLOHA_merge[rowid_check_MmaNOT99, .SD, .SDcols = paste0(tocheck_varnames, "_ma99")]
# EUTLOHA_merge[rowid_check_MmaNOT99, .SD, .SDcols = paste0(tocheck_varnames, "_maNOT99")]
# EUTLOHA_merge[rowid_check_MmaNOT99, .SD, .SDcols = paste0(tocheck_varnames, "_T")]

#define the column names of the combined dataset
toextract_varnames <- c("Year", "NationalAdministratorCode", "MainActivityTypeCode", 
  "AccountHolderName", "InstallationNameOrAircraftOperatorCode", 
  "InstallationOrAircraftOperatorID", "AccountStatus", "PermitOrPlanID", "ComplianceCode",
  "AllowanceInAllocation_comb", "TrasitionalAllocations_comb", "ReserveAllocations_comb",
  "VerifiedEmissions_comb", "UnitsSurrendered_comb", 
  "SurrenderedAllowances_comb", "FreeAllocations_comb"
)

#create the combined dataset with the columns of interests
EUTLOHA_comb <- copy(EUTLOHA_merge[, ..toextract_varnames])

#rename the columns according to the EUTL OHA 
setnames(EUTLOHA_comb, str_replace(toextract_varnames, pattern = "_comb", ""))

# #check that all the columns are present
# setdiff(names(EUTLOHA_ma99), names(EUTLOHA_comb))
# setdiff(names(EUTLOHA_comb), names(EUTLOHA_ma99))

#save the EUTLOHA_comb dataset in compressed (gzip) csv format
fwrite(EUTLOHA_comb,
       here("data/EUTLOHA_comb.csv.gz"))
