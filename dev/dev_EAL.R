## test space for developing functions for creating EAL data reports for 
## the costech
## 
## Paul Hegedus 1/19/2020
##------------------------------------------------------------------------------------
library(magrittr)
library(readxl)
library(openxlsx)
source("/Users/PaulBriggs/Box/Hegedus/Projects/EAL/MSUCOSTECH/dev/dev_EAL_fxns.R")
##------------------------------------------------------------------------------------
# 1 set parameters
input <- list()
input$raw_dat_folder_path <- "/Users/PaulBriggs/Box/Hegedus/Projects/EAL/MSUCOSTECH/dev/data/"
input$det_limit_fctr <- 2.5 # 2 or 3
input$N_uncertainty_fctr <- 0.1
input$C_uncertainty_fctr <- 0.05 
input$N_consensus_val <- 0.15 # 0.14 or 0.15
input$C_consensus_val <- 2 # guess
input$raw_dat_filename <- "PF_JG_Costech-20201016_prelim.xlsx" #  "20201007_OFPE_WHM20.xls" # 
## ^TODO^:get raw data file name ^ in shiny?
##------------------------------------------------------------------------------------
## 2 make output (not needed in shiny? is reactiveValues data) - updates reactively
output <- list()
output$UserInputs <- genUserInputsTab(input)
##------------------------------------------------------------------------------------
## 3 import raw data - when browse to file function used
# get data
output$SummaryTable <- importRawDat(input$raw_dat_filename, 
                                     input$raw_dat_folder_path)
##------------------------------------------------------------------------------------
## 4 create output$Standards table 
std_d_identifiers <- c("Std_D", "Standard", "StdD") 
# ^TODO^: more sophisticated method for identifiying standard Ds
output$Standards <- genStandardsTab(output$SummaryTable, 
                                     std_d_identifiers, 
                                     input$N_consensus_val,
                                     input$C_consensus_val)
##------------------------------------------------------------------------------------
## 5 make calibration table
acet_identifiers <- c("Acetanilide", "Acet", "Acetan", "Acetanalide", "analide") 
# ^TODO^: more sophisticated method for acetanilide identifiers
output$CalibrationRange <- genCalRangeTab(output$SummaryTable, 
                                           acet_identifiers, 
                                           input$det_limit_fctr)
##------------------------------------------------------------------------------------
## 6 create output$Results 
output$Results <- genResultsTab(output$SummaryTable,
                                 output$CalibrationRange,
                                 acet_identifiers,
                                 std_d_identifiers,
                                 input$N_uncertainty_fctr,
                                 input$C_uncertainty_fctr)

##------------------------------------------------------------------------------------
## 7 package all tables into an output
exportReport(output)







