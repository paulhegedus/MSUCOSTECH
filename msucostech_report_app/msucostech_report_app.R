## MSU EAL COSTECH Application
## Montana State University Environmental Analytical Laboratory data report application.
## 2021/01/22
##------------------------------------------------------------------------------------
## See the README on https://github.com/paulhegedus/MSUCOSTECH for more detailed information.This 
## application takes raw data exported from the MSU Costech ECS 4010 combustion analyzer and 
## imports the Summary Table as an input. The user also must supply inputs for the detection limit,
## uncertainty factors for nitrogen and carbon, and consensus values for nitrogen and carbon. 
##
## The application has one function and one button, 'Create Report', which imports the raw data 
## that the user specifies via a folder path and/or filename in the code, or browsing to Costech
## output in the Shiny app. The raw data is exported in the 'Summary Table' sheet of the generated 
## Excel report. The 'Standards' table/exported sheet contains the Standard D samples and the calculated mean, 
## standard deviation, coefficient of variation, and consensus metric calculated from the user 
## specified consensus factors for nitrogen and carbon. The 'Calibration Range' table/exported sheet 
## has the low and high calibration range values and the detection limit for each element. The 'Results' 
## table/exported sheet contains the total nitrogen and carbon weight percents, uncertainties, and flag
## if the observation falls within or outside of detectable or quantifiable limits. Additionally, the 
## inputs the user specified, or default values, are exported in the 'User Inputs' folder. 
##------------------------------------------------------------------------------------


library(shiny)
library(magrittr)
library(readxl)
library(openxlsx)
source("MSUCOSTECH_Report_fxns.R")

# Define UI for application that draws a histogram
ui <- fluidPage(
    tags$style(".checkbox-inline, .radio-inline {
    text-align: center;
    margin-left: 25px;
    margin-right: 25px;
    padding: 5px;
    width: 20%;} "),
    
    # Application title
    title = "MSU EAL Costech ECS 4010 Data Report Application",

    # Logos
    fluidRow(
        column(width = 1),
        column(width = 2, align = "center",
               tags$br(),
               #tags$br(),
               img(src = 'msu_eal_logo.png', height = '175px', width = '200px')
        ),
        column(width = 6, align = "center",
               tags$br(),
               h2("MSU EAL Costech Data Report Generator"),
               "Developed by the Environmental Analytical Laboratory for the Costech ECS 4010 - Montana State University",
               tags$br(),
               h6("Please contact Paul Hegedus for issues (paulhegedus@montana.edu). 
                  Copyright Montana State University. 
                  Updated 2021/01/22")
        ),
        column(width = 2,align = "center",
               tags$br(),
               tags$br(),
               #tags$br(),
               img(src = 'msu_coa_logo.png', height = '175px', width = '200px')
        ),
        column(width=1)
    ),
    hr(),
    
    fluidRow( 
        column(width = 12, align = "center",
               h5("See the README on https://github.com/paulhegedus/MSUCOSTECH for more detailed information. 
               This application takes raw data exported from the MSU Costech ECS 4010 combustion analyzer and 
               imports the Summary Table as an input. The user also must supply inputs for the detection limit, 
               uncertainty factors for nitrogen and carbon, and consensus values for nitrogen and carbon.
                  
               The application has one function and one button, 'Create Report', which imports the raw data 
               that the user specifies via a folder path and/or filename in the code, or browsing to Costech
               output in the Shiny app. The raw data is exported in the 'Summary Table' sheet of the generated 
               Excel report. The 'Standards' table/exported sheet contains the Standard D samples and the calculated mean, 
               standard deviation, coefficient of variation, and consensus metric calculated from the user 
               specified consensus factors for nitrogen and carbon. The 'Calibration Range' table/exported sheet 
               has the low and high calibration range values and the detection limit for each element. The 'Results' 
               table/exported sheet contains the total nitrogen and carbon weight percents, uncertainties, and flag
               if the observation falls within or outside of detectable or quantifiable limits. Additionally, the 
               inputs the user specified, or default values, are exported in the 'User Inputs' folder.")
        )
    ),
    hr(),
    
    fluidRow(
        column(align = "center", width = 1), 
        column(style='border-right: 1px solid black;height:930px;border-left: 1px solid black', 
               align = "center", width = 10,
               ## left side is for importing data
               h5("Follow the steps below sequentially to select the inputs required for creating a data 
                  report for the MSU EAL Costech ECS 4010. After all inputs have been specified, the user 
                  needs to browse to the location of the raw Costech data they want to generate a report 
                  for. After the Excel file (.xlsx or .xls) has been selected, the user can select the 
                  'Create Report' button to automatically generate and download the Excel data report."), 
               hr(),
               hr(),
               
               h5("Factor to divide the low calibration standard by to estimate 'below detection limit'."),
               sliderInput("det_limit_fctr", label = "Detection Limit Factor", min = 0, 
                           max = 5, value = 2.5, step = 0.25),
               hr(),
               
               h5("Estimate for the uncertainty of total nitrogen %. Provide as decimal."),
               sliderInput("N_uncertainty_fctr", label = "Total Nitrogen Uncertainty Factor", min = 0, 
                           max = 1, value = 0.1, step = 0.01),
               h5("Estimate for the uncertainty of total carbon %. Provide as decimal."),
               sliderInput("C_uncertainty_fctr", label = "Total Carbon Uncertainty Factor", min = 0, 
                           max = 1, value = 0.1, step = 0.05),
               hr(),
               hr(),
               
               h5("Consensus value for nitrogen derived from prior Costech standards, divided from the Standard D smaple weight % nitrogen to evaluate new measurements with prior Costech standard measurements."),
               numericInput("N_consensus_val", label = "Nitrogen Consensus Value", value = 0.15, 
                            min = 0, max = 100),
               h5("Consensus value for carbon derived from prior Costech standards, divided from the Standard D sample weight % carbon evaluate new measurements with prior Costech standard measurements."),
               numericInput("C_consensus_val", label = "Carbon Consensus Value", value = 2, 
                            min = 0, max = 100),
               hr(),

               fluidRow(
                   column(style='border-right: 1px solid black;height:100px;', 
                       align = "center", width = 6,
                       ## right side has button for data import and creating report
                       h3("Import Costech Data"),
                       # # Input: Select a file ----
                       fileInput("raw_dat", label = NULL,
                                 accept = c("xlsx",
                                            "xls"))
                   ),
                   column(
                       align = "center", width = 6,
                       h3("Export Data Report"),
                       downloadButton("export_report","Create Report")
                   )
               )
        ),
        column(align = "center", width = 1)
    ),
    hr()
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    # output$distPlot <- renderPlot({
    #     # generate bins based on input$bins from ui.R
    #     x    <- faithful[, 2]
    #     bins <- seq(min(x), max(x), length.out = input$bins + 1)
    # 
    #     # draw the histogram with the specified number of bins
    #     hist(x, breaks = bins, col = 'darkgray', border = 'white')
    # })
}

# Run the application 
shinyApp(ui = ui, server = server)
