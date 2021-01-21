## test space for developing functions for creating EAL data reports for 
## the costech
## 
## Paul Hegedus 1/19/2020

# parameters
cwd <- "/Users/PaulBriggs/Box/Hegedus/Projects/EAL/dev/"
det_limit_fctr <- 2.5 # 2 or 3
N_uncertainty_fctr <- 0.1
C_uncertainty_fctr <- 0.05 
N_consensus_val <- 0.15 # 0.14 or 0.15
C_consensus_val <- 2 # guess

## 1 import raw data
## get raw data file name in shiny?
raw_dat_name <- "PF_JG_Costech-20201016_prelim.xlsx" # not real raw but has Summary Table

## TODO: need to figure out how to parse and import this data
raw_dat <- readxl::read_excel(paste0(cwd, "/", raw_dat_name), sheet = "Summary Table")

## 2 make outputs (not needed in shiny?)
outputs <- list()

## 3a1 move raw to output$SummaryTable 
outputs$SummaryTable <- raw_dat
## 3a2 create output$CalibrationRange table with cols for C/N, Low, High, DetectionLimit
outputs$calibrationRange <- data.frame()
## 3b4 create output$Std_D table by subsetting cols for ID, weight, weight %, retention time from temp raw
## 3b5 create output$Results by subseting ID, %TN, %TC

## 4a1 subset acetanlide standards from temp raw
## 4a3 get the min and max for C and N & put in low and high
## 4a4 calculate the DetectionLimit using the user specified factor & low rate
## 4a5 discard acet standard subset

## 4b1 add columns for mean, sd, CV for N and C
## 4b2 rearrange columns for readability (all N and C together)
## 4b3 calculate the mean, sd, and CV for N and C
## 4b4 fill in sd, CV, N and C columns 
## 4b5 calculate the consensus by dividing the measure by the user input consensus value 

## 4c1 add columns for %TN uncertainty, %TC uncertainty, %TN flag, %TC flag
## 4c2 rearrange columns for readability (all N and C together)
## 4c3 calculate %TN & %TC uncertainty by multiplying %Tx by user specified factor
## 4c4 make temp cols for TN and TC weights from temp raw
## 4c5 calculate the %Tx flag by ifelse statements evaluating the TN and TC columns to CalibrationRange
## 4c6 remove temp cols TN and TC

## 5 package all tables into an output
## export as xlsx with tabs for each table
## use raw name + _report_date??



