## Functions for creating automated data reports for the MSU EAL Costech ECS 4010
## 1/23/2020

##-----------------------------------------------------------------------------
# Arguments are the parameters provided by the user for the report generation. 
# These include all the parameters defined in the Inputs section above. Argument 
# names are 'raw_dat_filename', 'raw_dat_folder_path',  'det_limit_fctr', 
# 'N_uncertainty_fctr', 'C_uncertainty_fctr', 'N_consensus_fctr', and 
# 'C_consensus_fctr'. If the user did not provide specifications for a parameter, 
# the default values are used. This function creates a data frame with a column 
# called 'Input' with the full input name, a column called 'Abbreviation' with 
# the input abbreviation used in the code, and a column called 'Entry' with 
# either the user specified value or the default value. This table is exported 
# as the 'User Inputs' sheet in the Excel report.
.genUserInputsTab <- function(raw_dat_filename,
                             raw_dat_folder_path = NULL,
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
# Arguments are 'raw_dat_filename' character, which is the file name for the raw 
# data from the Costech ECS 4010, and an optional 'raw_dat_folder_path' character
# which is a path to folder where the '.xlsx' raw file is stored (this is only 
# really used in the script form, but still optional). This function imports the 
# 'Summary Table' sheet in the provided Excel file path, sets the column names via
# a predetermined MSU EAL Costech format to remove merged cells, and returns the 
# raw data frame. This requires the Costech outputs to remain standard. This data 
# frame is exported in the 'Summary Table' sheet of the report. 
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
# Arguments for this function are the 'SummaryTable' data frame which is the raw 
# Costech data, a character vector of identifiers potentially in the 'SampleID's
# for Standard D samples called 'std_d_identifiers'. This is a baked in set of 
# identifiers that include 'Std_D', 'Standard', and 'StdD'. This function subsets 
# Standard D samples from the raw data. Currently this process is performed via
# pattern matching the expected codes used for Standard D samples using the 
# 'std_d_identifiers' matched in the 'SampleID' column. This is not case 
# sensitive and requires a mild standardization of SampleIDs to be identifiable. 
# The returned data frame contains all of the columns in the raw data. Thus,
# the 'Standards' table exported in the report is identical to the 'Summary Table' 
# but should only have Standard D samples.
genStandardsTab <- function(SummaryTable, 
                            std_d_identifiers = c("Std_D", "Standard", "StdD")) {
  ## 4a subset cols for ID, weight, weight %, retention time from temp raw by std_d identifiers
  Standards <- SummaryTable[grep(paste(std_d_identifiers, collapse = "|"),
                                 SummaryTable$SampleID,
                                 ignore.case = TRUE), ]
  return(Standards)
}
##-----------------------------------------------------------------------------
# The arguments for this function are the 'SummaryTable' data frame, which is the 
# raw Costech data, the 'Standards' table or a data frame with only Standard D 
# samples subsetted from raw Costech data, a character vector of identifiers
# possibly in the 'SampleID's column for calibration samples called 'cal_identifiers'. 
# This is a baked in set of identifiers that include 'Acetanilide', 'Acet', 'Acetan',
# 'Acetanalide', 'analide', 'atropine', 'atro' for common calibration standards such 
# as Acetanilide or Atropine. The third and fourth arguments are the user specified 
# detection limit factor for each element ('N_det_limit_fctr' and 'C_det_limit_fctr'),
# and the final two arguments are the nitrogen and carbon consensus factors, 
# 'N_consensus_fctr' and 'C_consensus_fctr', which are used to calculate the consensus 
# value of the standard samples for each element. This function subsets calibration 
# samples from the raw data. Currently this process is performed via pattern matching 
# expected codes used for calibration samples using the 'cal_identifiers' matched in 
# the 'SampleID' column. This is not case sensitive and requires a mild standardization
# of 'SampleID's to be identifiable. An empty 'Calibration Range' table is generated
# with a column labeled 'CalibrationRange' with 'N' and 'C' to deliminate nitrogen 
# and carbon limits and filled in with the following calculations. The low and high 
# calibration ranges ('LowCalibration' and 'HighCalibration' columns) for each element
# are derived by multiplying the minimum and maximum calibration sample amounts 
# ('Sample Amount' in the 'Summary Table') by 0.1036 for nitrogen and 0.7109 for 
# carbon. These values are baked into the application and used because the calibration 
# standard weights are measured. This means there is uncertainty in the measured 
# weights by the Costech, and so the weight of the samples measured prior to Costech 
# analysis are used multiplied by 10.36% and 71.09% for nitrogen and carbon, 
# respectively, as a more accurate measure of the weight of nitrogen and carbon in 
# the calibration samples. The 'DetectionLimit' column is calculated by dividing the 
# low calibration range by the user specified detection limit factor for each element 
# ('N_det_limit_fctr' or 'C_det_limit_fctr', respectively). This may be a temporary 
# process until a data-driven approach is developed. The mean and standard deviation 
# are calculated from the weight percentages in the 'Standards' table for nitrogen and
# carbon, and are placed in the appropriate rows of the 'Calibration Range' table in 
# columns labeled 'StandardMean' and 'StandardSD', respectively. The coefficient of 
# variation for both elements are then calculated as the standard deviation divided by 
# the mean and added as a column labeled 'StandardCV'. A consensus value is then derived 
# in the 'ConsensusValue' column by dividing the mean weight percent of the Standard D 
# samples for each element ('StandardMean') by the user specified consensus factor 
# for each element ('N_consensus_fctr', 'C_consensus_fctr'). After the 'Calibration Range'
# table has been completed, it is returned to the user. This is exported in the Excel 
# spreadsheet report in the 'Calibration Range' sheet. 
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
# The arguments for this function are the 'SummaryTable' data frame which is the 
# raw Costech data, the 'Calibration Range' data frame created from the 
# genCalRangeTab() function as 'CalibrationRange', the 'std_d_identifiers'
# and 'cal_identifiers' character vectors specified as arguments in the functions 
# above, and the uncertainty factors for nitrogen and carbon ('N_uncertainty_fctr'
# and 'C_uncertainty_fctr', respectively). This function uses the identifiers for
# Standard D and calibration samples to take all rows that aren't these or a bypass,
# identified by 'Bypass' or 'By pass' in the SampleID. The 'SampleID', weight 
# ('x_Weight_mg', where 'x' is 'C' or 'N') and weight percents ('x_Weight_pct',
# where 'x' is 'C' or 'N') are the columns taken from the raw data during the
# subsetting process. The weight percent columns are renamed to '%TN' and '%TC', 
# respectively for each element. The nitrogen and carbon percent uncertainty are 
# calculated and added to the table by multiplying the weight percent by the 
# nitrogen or carbon uncertainty factor that was specified by the user. These
# are included as columns named '%TN uncertainty' and '%TC uncertainty'. Using 
# the weights in mg for each element, the flags ('%TN flag' and '%TC flag') are 
# derived by determining if the weight falls; first below the detection limit, 
# and then within the bounds of the quantifiable limits. Observations are labeled
# 'bdl' if the measurement falls below the detection limit, 'bql' if the measurement 
# falls below the lower quantifiable limit, 'aql' if the measurement exceeds the 
# upper quantifiable limit, or 'ok' if it falls within the quantifiable limits. 
# The detection and quantifiable detection limits for each element are taken 
# from the 'CalibrationRange' table. The weight columns are removed from the 
# 'Results' table, the columns are organized by element, and the 'Results' table 
# is returned to the user. This table is exported in the 'Results' sheet of the 
# Excel report.
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
# This function takes a list of outputs, labeled 'Results', 'CalibrationRange', 
# 'Standards', 'SummaryTable', and 'UserInputs' from the functions above, in 
# any order. This function then puts them into an Excel spreasheet that is 
# exported to the user's file system folder with sheets labeled as 'Results', 
# 'Calibration Range', 'Standards', 'Summary Table', and 'User Inputs'. The 
# exported filename is a concatenation of the raw filename with '_REPORT_' 
# plus the date and time the report was generated. The report is saved in the 
# same directory as the raw data that was imported.
.exportReport <- function(output, raw_dat_filename, raw_dat_folder_path = NULL) {
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
  out_filename <- .makeReportFilename(raw_dat_filename)
  out_filename <- ifelse(is.null(raw_dat_folder_path), 
                     out_filename, 
                     paste0(raw_dat_folder_path, "/", out_filename))
  openxlsx::write.xlsx(output, file = out_filename)
}
##-----------------------------------------------------------------------------
## undocmuented function to make a report filename from a folder path and/or filename
.makeReportFilename <- function(raw_dat_filename) {
    ext_nchar <- ifelse(grepl(".xlsx", raw_dat_filename), 5, 4)
    out_filename <- paste0(
      substr(raw_dat_filename, 1, nchar(raw_dat_filename) - ext_nchar), 
      "_REPORT_", Sys.time(), ".xlsx"
    )
    return(out_filename)
}
##-----------------------------------------------------------------------------



