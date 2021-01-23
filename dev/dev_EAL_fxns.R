## Functions for creating automated data reports for the MSU EAL Costech ECS 4010
## 1/22/2020

##-----------------------------------------------------------------------------
## generate user inputs table
genUserInputsTab <- function(raw_dat_filename,
                             raw_dat_folder_path = NA,
                             N_det_limit_fctr = 2,
                             C_det_limit_fctr = 10, 
                             N_uncertainty_fctr = 0.1,
                             C_uncertainty_fctr = 0.05,
                             N_consensus_fctr = 0.14,
                             C_consensus_fctr = 1.67) {
  UserInputs <- 
    data.frame(Input = c("Raw Data Filename", "Raw Data Path", 
                         "Nitrogen Detection Limit Factor", "Carbon Detection Limit Factor",
                         "%TN Uncertainty Factor", "%TC Uncertainty Factor", 
                         "N Consensus Value", "C Consensus Value"),
               Abbreviation = c("raw_dat_filename", "raw_dat_folder_path", 
                                "N_det_limit_fctr", "C_det_limit_fctr",
                                "N_uncertainty_fctr", "C_uncertainty_fctr", 
                                "N_consensus_fctr", "C_consensus_fctr"),
               Entry = c(raw_dat_filename,  raw_dat_folder_path, 
                         N_det_limit_fctr, C_det_limit_fctr,
                         N_uncertainty_fctr, C_uncertainty_fctr,
                         N_consensus_fctr, C_consensus_fctr))
  return(UserInputs)
} 
##-----------------------------------------------------------------------------
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
##-----------------------------------------------------------------------------
## generate standards table
genStandardsTab <- function(SummaryTable, 
                            std_d_identifiers = c("Std_D", "Standard", "StdD")) {
  ## 4a subset cols for ID, weight, weight %, retention time from temp raw by std_d identifiers
  Standards <- SummaryTable[grep(paste(std_d_identifiers, collapse = "|"),
                                 SummaryTable$SampleID,
                                 ignore.case = TRUE), ]
  return(Standards)
}
##-----------------------------------------------------------------------------
genCalRangeTab <- function(SummaryTable, 
                           Standards,
                           cal_identifiers = c('Acetanilide', 'Acet', 'Acetan', 
                                               'Acetanalide', 'analide', 
                                               'atropine', 'atro'), 
                           N_det_limit_fctr = 2,
                           C_det_limit_fctr = 10, 
                           N_consensus_fctr = 0.14, 
                           C_consensus_fctr = 1.67,
                           N_weight_content = 0.1036,
                           C_weight_content = 0.7109) {
  ## 5a create output$CalibrationRange table with cols for C/N, Low, High, DetectionLimit
  CalibrationRange <- data.frame(CalibrationRange = c("N", "C"),
                                 LowCalibration = rep(NA, 2),
                                 HighCalibration = rep(NA, 2),
                                 DetectionLimit = rep(NA, 2),
                                 StandardMean = rep(NA, 2),
                                 StandardSD = rep(NA, 2),
                                 StandardCV = rep(NA, 2),
                                 ConsensusValue = rep(NA, 2))
  ## 5b create acetanalide table with weights and SampleID
  cal_cols <- c("SampleID", "N_Weight_mg", "C_Weight_mg", "SampleAmount")
  cal_dat <- SummaryTable[grep(paste(cal_identifiers, collapse = "|"),
                                SummaryTable$SampleID,
                                ignore.case = TRUE), cal_cols]
  
  N <- grep("N", CalibrationRange$CalibrationRange)
  C <- grep("C", CalibrationRange$CalibrationRange)
  
  ## 5c1 get the min and max for C and N & put in low and high
  CalibrationRange[N, "LowCalibration"] <- 
    min(cal_dat$SampleAmount, na.rm = TRUE) * N_weight_content
  CalibrationRange[N, "HighCalibration"] <- 
    max(cal_dat$SampleAmount, na.rm = TRUE) * N_weight_content
  CalibrationRange[C, "LowCalibration"] <- 
    min(cal_dat$SampleAmount, na.rm = TRUE) * C_weight_content
  CalibrationRange[C, "HighCalibration"] <- 
    max(cal_dat$SampleAmount, na.rm = TRUE) * C_weight_content
  ## 5c2 calculate the DetectionLimit using the user specified factor & low rate
  CalibrationRange[N, "DetectionLimit"] <- 
    CalibrationRange[N, "LowCalibration"] / N_det_limit_fctr
  CalibrationRange[C, "DetectionLimit"] <- 
    CalibrationRange[C, "LowCalibration"] / C_det_limit_fctr
  
  ## 5d calculate the mean, sd, and CV for N & C from standard d samples
  ## 5e calculate the consensus value by dividing the mean standard d weight percent
  ## by the user input consensus factor for each element
  CalibrationRange[N, "StandardMean"] <- 
    mean(Standards$N_Weight_pct, na.rm = TRUE)
  CalibrationRange[N, "StandardSD"] <- 
    sd(Standards$N_Weight_pct, na.rm = TRUE)
  CalibrationRange[N, "StandardCV"] <- 
    CalibrationRange[N, "StandardSD"] / CalibrationRange[N, "StandardMean"]
  CalibrationRange[N, "ConsensusValue"] <- 
    CalibrationRange[N, "StandardMean"] / N_consensus_fctr
  CalibrationRange[C, "StandardMean"] <- 
    mean(Standards$C_Weight_pct, na.rm = TRUE)
  CalibrationRange[C, "StandardSD"] <- 
    sd(Standards$C_Weight_pct, na.rm = TRUE)
  CalibrationRange[C, "StandardCV"] <- 
    CalibrationRange[C, "StandardSD"] / CalibrationRange[C, "StandardMean"]
  CalibrationRange[C, "ConsensusValue"] <- 
    CalibrationRange[C, "StandardMean"] / C_consensus_fctr
  
  return(CalibrationRange)
}
##-----------------------------------------------------------------------------
genResultsTab <- function(SummaryTable, 
                          CalibrationRange,
                          cal_identifiers = c('Acetanilide', 'Acet', 'Acetan', 
                                              'Acetanalide', 'analide', 
                                              'atropine', 'atro'), 
                          std_d_identifiers = c("Std_D", "Standard", "StdD"), 
                          N_uncertainty_fctr = 0.1, 
                          C_uncertainty_fctr = 0.05) {
  ## 6a subset ID, %TN, %TC
  # subset raw dat by removing bypass, acet, and std_d. only take cols above
  not_results <- c(cal_identifiers, std_d_identifiers, "Bypass", "By pass")
  results_cols <- c("SampleID", "N_Weight_mg", "N_Weight_pct",
                    "C_Weight_mg", "C_Weight_pct")
  Results <- SummaryTable[-grep(paste(not_results, collapse = "|"),
                                SummaryTable$SampleID,
                                ignore.case = TRUE), results_cols]
  ## 6b add columns for %TN uncertainty, %TC uncertainty, 
  Results$TN_pct_uncertainty <- Results$N_Weight_pct * N_uncertainty_fctr
  Results$TC_pct_uncertainty <- Results$C_Weight_pct * C_uncertainty_fctr
  ## 6c add columns for %TN flag, %TC flag
  N <- grep("N", CalibrationRange$CalibrationRange)
  C <- grep("C", CalibrationRange$CalibrationRange)
  Results$TN_pct_flag <- 
    ifelse(Results$N_Weight_mg < CalibrationRange[N, "DetectionLimit"], "bdl", 
           ifelse(Results$N_Weight_mg > CalibrationRange[N, "HighCalibration"], "aql", 
                  ifelse(Results$N_Weight_mg < CalibrationRange[N, "LowCalibration"], "bql", 
                         "ok")))
  Results$TC_pct_flag <- 
    ifelse(Results$C_Weight_mg < CalibrationRange[C, "DetectionLimit"], "bdl", 
           ifelse(Results$C_Weight_mg > CalibrationRange[C, "HighCalibration"], "aql", 
                  ifelse(Results$C_Weight_mg < CalibrationRange[C, "LowCalibration"], "bql", 
                         "ok")))
  ## 6c remove unneeded columns
  Results$N_Weight_mg <- NULL
  Results$C_Weight_mg <- NULL
  ## 6d rearrange columns for readability (all N and C together) & rename
  cols <- c("SampleID", "N_Weight_pct", "TN_pct_uncertainty", "TN_pct_flag",
            "C_Weight_pct", "TC_pct_uncertainty", "TC_pct_flag")
  Results <- Results[, cols]
  names(Results) <- c("ID", "%TN", "%TN uncertainty", "%TN flag", 
                      "%TC", "%TC uncertainty", "%TC flag")
  
  return(Results)
}
##-----------------------------------------------------------------------------
exportReport <- function(output, raw_dat_filename, raw_dat_folder_path) {
  ## export as xlsx with tabs for each table
  ## use raw name + _report_date??
  output <- list("Results" = output$Results, 
                  "Calibration Range" = output$CalibrationRange,
                  "Standards" = output$Standards,
                  "Summary Table" = output$SummaryTable,
                  "User Inputs" = output$UserInputs)
  user_inputs <- output$`User Inputs`
  raw_dat_filename <- user_inputs[user_inputs$Abbreviation == 
                                    "raw_dat_filename", "Entry"]
  raw_dat_folder_path <- user_inputs[user_inputs$Abbreviation == 
                                       "raw_dat_folder_path", "Entry"]
  out_filename <- paste0(substr(raw_dat_filename, 
                                1, 
                                nchar(raw_dat_filename) - 5), 
                         "_REPORT_", Sys.time(), ".xlsx")
  out_path <- ifelse(is.null(raw_dat_folder_path), 
                     out_filename, 
                     paste0(raw_dat_folder_path, "/", out_filename))
  openxlsx::write.xlsx(output, file = out_path)
}
##-----------------------------------------------------------------------------




