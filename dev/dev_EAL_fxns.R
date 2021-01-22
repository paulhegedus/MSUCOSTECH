## functions for creating automated data reporst for the costech ecs4010
## Paul Hegedus 1/19/2020

##------------------------------------------------------------------------------------
## generate user inputs table
genUserInputsTab <- function(inputs) {
  UserInputs <- data.frame(Input = c("Raw Data Filename", "Raw Data Path", 
                                     "Detection Limit Factor", "%TN Uncertainty Factor", 
                                     "%TC Uncertainty Factor", "N Consensus Value", 
                                     "C Consensus Value"),
                           Abbreviation = c("raw_dat_filename", "raw_dat_folder_path", 
                                            "det_limit_fctr", "N_uncertainty_fctr", 
                                            "C_uncertainty_fctr", "N_consensus_val", 
                                            "C_consensus_val"),
                           Entry = c(inputs$raw_dat_filename, inputs$raw_dat_folder_path, 
                                     inputs$det_limit_fctr, inputs$N_uncertainty_fctr, 
                                     inputs$C_uncertainty_fctr, inputs$N_consensus_val, 
                                     inputs$C_consensus_val))
  
  return(UserInputs)
} 
##------------------------------------------------------------------------------------
## import raw data
importRawDat <- function(raw_dat_filename, 
                         raw_dat_folder_path = NULL) {
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
  ## gather data from the SUmmary Table sheet, skip merged cells, 
  ## add column names, make data.frame
  raw_dat <- suppressMessages(readxl::read_excel(raw_path, 
                                                 sheet = "Summary Table",
                                                 skip = 3,
                                                 col_names = FALSE)) %>%
    `names<-`(raw_col_names) %>% 
    as.data.frame()
  
  return(raw_dat)
}
##------------------------------------------------------------------------------------
## generate standards table
genStandardsTab <- function(SummaryTable, 
                            std_d_identifiers, 
                            N_consensus_val, 
                            C_consensus_val) {
  ## 4a subset cols for ID, weight, weight %, retention time from temp raw by std_d identifiers
  Standards <- SummaryTable[grep(paste(std_d_identifiers, collapse = "|"),
                                 SummaryTable$SampleID,
                                 ignore.case = TRUE), ]
  ## 4b calculate the mean, sd, and CV for N & C
  ## 4c calculate the consensus by dividing the measure by the user input consensus value 
  Standards$N_mean <- mean(Standards$N_Weight_pct, na.rm = TRUE)
  Standards$N_sd <- sd(Standards$N_Weight_pct, na.rm = TRUE)
  Standards$N_cv <- Standards$N_sd / Standards$N_mean
  Standards$N_consensus <- Standards$N_Weight_pct / N_consensus_val
  Standards$C_mean <- mean(Standards$C_Weight_pct, na.rm = TRUE)
  Standards$C_sd <- sd(Standards$C_Weight_pct, na.rm = TRUE)
  Standards$C_cv <- Standards$C_sd / Standards$C_mean
  Standards$C_consensus <- Standards$C_Weight_pct / C_consensus_val
  ## 4d rearrange columns for readability (all N and C together)
  Standards <- cbind(Standards[, 1:12], Standards[, 20:23], 
                     Standards[, 13:19], Standards[, 24:27])
  
  return(Standards)
}
##------------------------------------------------------------------------------------
genCalRangeTab <- function(SummaryTable, 
                           acet_identifiers, 
                           det_limit_fctr) {
  ## 5a create output$CalibrationRange table with cols for C/N, Low, High, DetectionLimit
  CalibrationRange <- data.frame(CalibrationRange = c("N", "C"),
                                 Low = rep(NA, 2),
                                 High = rep(NA, 2),
                                 DetectionLimit = rep(NA, 2))
  ## 5b create acetanalide table with weights and SampleID
  acet_cols <- c("SampleID", "N_Weight_mg", "C_Weight_mg")
  acet_dat <- SummaryTable[grep(paste(acet_identifiers, collapse = "|"),
                                SummaryTable$SampleID,
                                ignore.case = TRUE), acet_cols]
  ## 5c1 get the min and max for C and N & put in low and high
  CalibrationRange[1, "Low"] <- min(acet_dat$N_Weight_mg, na.rm = TRUE)
  CalibrationRange[1, "High"] <- max(acet_dat$N_Weight_mg, na.rm = TRUE)
  CalibrationRange[2, "Low"] <- min(acet_dat$C_Weight_mg, na.rm = TRUE)
  CalibrationRange[2, "High"] <- max(acet_dat$C_Weight_mg, na.rm = TRUE)
  ## 5c2 calculate the DetectionLimit using the user specified factor & low rate
  CalibrationRange[1, "DetectionLimit"] <- CalibrationRange[1, "Low"] / det_limit_fctr
  CalibrationRange[2, "DetectionLimit"] <- CalibrationRange[2, "Low"] / det_limit_fctr
  
  return(CalibrationRange)
}
##------------------------------------------------------------------------------------
genResultsTab <- function(SummaryTable, 
                          CalibrationRange,
                          acet_identifiers, 
                          std_d_identifiers, 
                          N_uncertainty_fctr, 
                          C_uncertainty_fctr) {
  ## 6a subset ID, %TN, %TC
  # subset raw dat by removing bypass, acet, and std_d. only take cols above
  not_results <- c(acet_identifiers, std_d_identifiers, "Bypass", "By pass")
  results_cols <- c("SampleID", "N_Weight_mg", "N_Weight_pct", "C_Weight_mg", "C_Weight_pct")
  Results <- SummaryTable[-grep(paste(not_results, collapse = "|"),
                                SummaryTable$SampleID,
                                ignore.case = TRUE), results_cols]
  ## 6b add columns for %TN uncertainty, %TC uncertainty, 
  Results$TN_pct_uncertainty <- Results$N_Weight_pct * N_uncertainty_fctr
  Results$TC_pct_uncertainty <- Results$C_Weight_pct * C_uncertainty_fctr
  ## 6c add columns for %TN flag, %TC flag
  Results$TN_pct_flag <- 
    ifelse(Results$N_Weight_mg < CalibrationRange[1, "DetectionLimit"], "bdl", 
           ifelse(Results$N_Weight_mg > CalibrationRange[1, "High"], "aql", 
                  ifelse(Results$N_Weight_mg < CalibrationRange[1, "Low"], "bql", 
                         "ok")))
  Results$TC_pct_flag <- 
    ifelse(Results$C_Weight_mg < CalibrationRange[2, "Low"], "bql", 
           ifelse(Results$C_Weight_mg > CalibrationRange[2, "High"], "aql", 
                  ifelse(Results$C_Weight_mg < CalibrationRange[2, "DetectionLimit"], "bdl", 
                         "ok")))
  ## 6c remove unneeded columns
  Results$N_Weight_mg <- NULL
  Results$C_Weight_mg <- NULL
  ## 6d rearrange columns for readability (all N and C together) & rename
  Results <- cbind(Results[, 1:2], Results[, 4], Results[, 6], 
                   Results[, 3], Results[, 5], Results[, 7])
  names(Results) <- c("ID", "%TN", "%TN uncertainty", "%TN flag", 
                      "%TC", "%TC uncertainty", "%TC flag")
  
  return(Results)
}
##------------------------------------------------------------------------------------
exportReport <- function(outputs, raw_dat_filename, raw_dat_folder_path) {
  ## export as xlsx with tabs for each table
  ## use raw name + _report_date??
  outputs <- list("Results" = outputs$Results, 
                  "Calibration Range" = outputs$CalibrationRange,
                  "Standards" = outputs$Standards,
                  "Summary Table" = outputs$SummaryTable,
                  "User Inputs" = outputs$UserInputs)
  raw_dat_filename <- outputs$`User Inputs`[outputs$`User Inputs`$Abbreviation == "raw_dat_filename",
                                            "Entry"]
  raw_dat_folder_path <- outputs$`User Inputs`[outputs$`User Inputs`$Abbreviation == "raw_dat_folder_path",
                                               "Entry"]
  out_filename <- paste0(substr(raw_dat_filename, 
                                1, 
                                nchar(raw_dat_filename) - 5), 
                         "_REPORT_", Sys.time(), ".xlsx")
  out_path <- ifelse(is.null(raw_dat_folder_path), 
                     out_filename, 
                     paste0(raw_dat_folder_path, "/", out_filename))
  openxlsx::write.xlsx(outputs, file = out_path)
}
##------------------------------------------------------------------------------------




