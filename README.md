# MSUCOSTECH
Montana State University Environmental Laboratory Shiny application for creating automated data reports from raw Costech ECS 4010 data.

Users must have R downloaded on the computer they are running the application from.(?) 

The application can be found at **URL**

### Inputs
The application takes a .xlsx with tabs for **Summary Table, ...**. When the user browses to their raw Costech data the Excel file is imported. The user also must provide inputs for the following parameters in the model;
  + Detection Limit Factor: To estimate 'below detection limit', what is the factor to divide the low calibration standard by? Default is 2.5.
  + Total Nitrogen Uncertainty Factor: Estimate for the uncertainty of total nitrogen %. Provide as decimal, default is 0.1.
  + Total Carbon Uncertainty Factor: Estimate for the uncertainty of total Carbon %. Provide as decimal, default is 0.05.
  + Nitrogen Consensus Value: Consensus value for nitrogen derived from prior Costech standards, divided from the measured standards to evaluate new measurements with prior Costech data. 
  + Carbon Consensus Value: Consensus value for carbon derived from prior Costech standards, divided from the measured standards to evaluate new measurements with prior Costech data. 

### Outputs
When raw data and inputs are provided, the user must select the 'Create Report' button. The output data report will be **automatically downloaded upon completion.** The output Excel sheet has tabs for **Results, Summary Table, Calibration Range, and Standards**. The Results table contains columns for the sample ID, the percent total nitrogen and carbon, uncertainties for nitrogen and carbon, and a flag for each indicating whether the observation was above or below the quantifiable limit ('aql', 'bql'), below the detection limit ('bdl'), or within detectable limits ('ok'). The uncertainties are calculated by multiplying the weight percent by the user specified uncertainty factor. The Summary Table contains the unmodified raw data. The Calibration Range table contains the low and high quantifiable limits for nitrogen and carbon, calculated from the minimum and maximum nitrogen and carbon values measured in the acetanalide samples. This table also contains the detection limit for nitrogen and carbon, calculated by dividing the low quantifiable limit by the user specified detection limit factor. The Standards table contains the sample ID, weight (mg), weight percent, and retention time for nitrogen and carbon for each observation. This table also has columns for the mean, standard deviation, and coefficient of variation for the measured standards and a consensus metric for each observation, calculated as the measured value divided by the user specified consensus value for nitrogen and carbon. 


