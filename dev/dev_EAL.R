## test space for developing functions for creating EAL data reports for 
## the costech
## 
## Paul Hegedus 1/19/2020

library(magrittr)
library(readxl)
##------------------------------------------------------------------------------------

# 1 set parameters
raw_dat_folder_path <- "/Users/PaulBriggs/Box/Hegedus/Projects/EAL/MSUCOSTECH/dev/data/"
det_limit_fctr <- 2.5 # 2 or 3
N_uncertainty_fctr <- 0.1
C_uncertainty_fctr <- 0.05 
N_consensus_val <- 0.15 # 0.14 or 0.15
C_consensus_val <- 2 # guess
raw_dat_filename <- "PF_JG_Costech-20201016_prelim.xlsx" ## TODO:get raw data file name ^ in shiny?
##------------------------------------------------------------------------------------

## 2 make outputs (not needed in shiny? is reactiveValues data) - updates reactively
outputs <- list()
outputs$UserInputs <- data.frame(Input = c("Raw Data File", "Detection Limit Factor", 
                                   "%TN Uncertainty Factor", "%TC Uncertainty Factor",
                                   "N Consensus Value", "C Consensus Value"),
                         Abbreviation = c("raw_dat_filename", "det_limit_fctr", 
                                          "N_uncertainty_fctr", "C_uncertainty_fctr",
                                          "N_consensus_val", "C_consensus_val"),
                         Entry = c(raw_dat_filename, det_limit_fctr,
                                   N_uncertainty_fctr, C_uncertainty_fctr,
                                   N_consensus_val, C_consensus_val))
##------------------------------------------------------------------------------------

## 3 import raw data - when browse to file function used
# get data
importRawDat <- function(raw_dat_filename, raw_dat_folder_path = NULL) {
  ## path to the data. uses just the raw_dat_filename if no folder path is given
  raw_path <- ifelse(is.null(raw_dat_folder_path), 
                     raw_dat_filename, 
                     paste0(raw_dat_folder_path, "/", raw_dat_filename))
  ## make column names - based on costech raw data and done to avoid merged columns
  raw_col_names <- c("FullID", "Setting", "Sample", "SampleID", "SampleAmount",
                     "N_RetenTime_min", "N_Response", "N_Weight_mg", "N_Weight_pct", 
                     "N_PeakType", "N_Element_Name", "N_Carbon_Resp_Ratio",
                     "C_RetenTime_min", "C_Response", "C_Weight_mg", "C_Weight_pct", 
                     "C_PeakType", "C_Element_Name", "C_Carbon_Resp_Ratio")
  ## gather data from the SUmmary Table sheet, skip merged cells, add column names, make data.frame
  raw_dat <- suppressMessages(readxl::read_excel(raw_path, 
                                                 sheet = "Summary Table",
                                                 skip = 3,
                                                 col_names = FALSE)) %>%
    `names<-`(raw_col_names) %>% 
    as.data.frame()
  return(raw_dat)
}
outputs$SummaryTable <- importRawDat(raw_dat_filename, raw_dat_folder_path)
##------------------------------------------------------------------------------------

## 4 make calibration table
## 4a create output$CalibrationRange table with cols for C/N, Low, High, DetectionLimit
outputs$CalibrationRange <- data.frame(CalibrationRange = c("N", "C"),
                                       Low = rep(NA, 2),
                                       High = rep(NA, 2),
                                       DetectionLimit = rep(NA, 2))
## 4b create acetanalide table with weights and SampleID
# TODO: more sophisticated method for acetanilide identifiers
acet_identifiers <- c("Acetanilide", "Acet", "Acetan", "Acetanalide", "analide") 
acet_cols <- c("SampleID", "N_Weight_mg", "C_Weight_mg")
acet_dat <- outputs$SummaryTable[grep(paste(acet_identifiers, collapse = "|"),
                         outputs$SummaryTable$SampleID,
                         ignore.case = TRUE), acet_cols]
## 4c1 get the min and max for C and N & put in low and high
outputs$CalibrationRange[1, "Low"] <- min(acet_dat$N_Weight_mg, na.rm = TRUE)
outputs$CalibrationRange[1, "High"] <- max(acet_dat$N_Weight_mg, na.rm = TRUE)
outputs$CalibrationRange[2, "Low"] <- min(acet_dat$C_Weight_mg, na.rm = TRUE)
outputs$CalibrationRange[2, "High"] <- max(acet_dat$C_Weight_mg, na.rm = TRUE)
## 4c2 calculate the DetectionLimit using the user specified factor & low rate
outputs$CalibrationRange[1, "DetectionLimit"] <- outputs$CalibrationRange[1, "Low"] / det_limit_fctr
outputs$CalibrationRange[2, "DetectionLimit"] <- outputs$CalibrationRange[2, "Low"] / det_limit_fctr
## 4c3 discard acet standard subset
rm(acet_dat, acet_identifiers, acet_cols)

makeCalRangeTab <- function(summary_tab) {
  
}

outputs$CalibrationRange <- makeCalRangeTab(outputs$SummaryTable)
##------------------------------------------------------------------------------------

## 5 create output$Standards table 
## 5a subset cols for ID, weight, weight %, retention time from temp raw by std_d identifiers
std_d_identifiers <- c("Std_D", "Standard", "StdD") 
# ^TODO^: more sophisticated method for identifiying standard Ds
outputs$Standards <- outputs$SummaryTable[grep(paste(std_d_identifiers, collapse = "|"),
                                  outputs$SummaryTable$SampleID,
                                  ignore.case = TRUE), ]
## 5b calculate the mean, sd, and CV for N and C
outputs$Standards$N_mean <- mean(outputs$Standards$N_Weight_pct, na.rm = TRUE)
outputs$Standards$N_sd <- sd(outputs$Standards$N_Weight_pct, na.rm = TRUE)
outputs$Standards$N_cv <- outputs$Standards$N_sd / outputs$Standards$N_mean
outputs$Standards$N_consensus <- outputs$Standards$N_Weight_pct / N_consensus_val
outputs$Standards$C_mean <- mean(outputs$Standards$C_Weight_pct, na.rm = TRUE)
outputs$Standards$C_sd <- sd(outputs$Standards$C_Weight_pct, na.rm = TRUE)
outputs$Standards$C_cv <- outputs$Standards$C_sd / outputs$Standards$C_mean
## 5c calculate the consensus by dividing the measure by the user input consensus value 
outputs$Standards$C_consensus <- outputs$Standards$C_Weight_pct / C_consensus_val
## 5d rearrange columns for readability (all N and C together)
outputs$Standards <- cbind(outputs$Standards[, 1:12], outputs$Standards[, 20:23], 
                           outputs$Standards[, 13:19], outputs$Standards[, 24:27])
rm(std_d_identifiers)
##------------------------------------------------------------------------------------

## 6 create output$Results 
## 6a subset ID, %TN, %TC
# subset raw dat by removing bypass, acet, and std_d. only take cols above
not_results <- c(acet_identifiers, std_d_identifiers, "Bypass", "By pass")
results_cols <- c("SampleID", "N_Weight_mg", "N_Weight_pct", "C_Weight_mg", "C_Weight_pct")
Results <- outputs$SummaryTable[-grep(paste(not_results, collapse = "|"),
                                outputs$SummaryTable$SampleID,
                                ignore.case = TRUE), results_cols]
## 6b add columns for %TN uncertainty, %TC uncertainty, 
Results$TN_pct_uncertainty <- Results$N_Weight_pct * N_uncertainty_fctr
Results$TC_pct_uncertainty <- Results$C_Weight_pct * C_uncertainty_fctr
## 6c add columns for %TN flag, %TC flag
Results$TN_pct_flag <- ifelse(Results$N_Weight_mg < outputs$CalibrationRange[1, "DetectionLimit"], "bdl", 
                              ifelse(Results$N_Weight_mg > outputs$CalibrationRange[1, "High"], "aql", 
                                     ifelse(Results$N_Weight_mg < outputs$CalibrationRange[1, "Low"], "bql", 
                                            "ok")))
Results$TC_pct_flag <- ifelse(Results$C_Weight_mg < outputs$CalibrationRange[2, "Low"], "bql", 
                              ifelse(Results$C_Weight_mg > outputs$CalibrationRange[2, "High"], "aql", 
                                     ifelse(Results$C_Weight_mg < outputs$CalibrationRange[2, "DetectionLimit"], "bdl", 
                                            "ok")))
## 6c remove unneeded columns
Results$N_Weight_mg <- NULL
Results$C_Weight_mg <- NULL
## 6d rearrange columns for readability (all N and C together) & rename
Results <- cbind(Results[, 1:2], Results[, 4], Results[, 6], Results[, 3], Results[, 5], Results[, 7])
names(Results) <- c("ID", "%TN", "%TN uncertainty", "%TN flag", "%TC", "%TC uncertainty", "%TC flag")
rm(not_results, results_cols)
##------------------------------------------------------------------------------------

## 7 package all tables into an output
## export as xlsx with tabs for each table
## use raw name + _report_date??


