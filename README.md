
# msucostech

Montana State University Environmental Laboratory Shiny application for
creating automated data reports from raw Costech ECS 4010 data.

Users must have R downloaded on the computer they are running the
application from **(?)**.

The application can be found at **URL**

### Inputs

The application takes a .xlsx with Result Table, Chromatogram Data,
Chromatogram Graph, and ‘Summary Table’ tabs. When the user browses to
their raw Costech data the ‘Summary Table’ of the Excel file is
imported. The user also must provide inputs for the following parameters
in the model;

  - **Detection Limit Factor:** Factor to divide the low calibration
    standard by to estimate ‘below detection limit’. Default is 2.5.
  - **Total Nitrogen Uncertainty Factor:** Estimate for the uncertainty
    of total nitrogen %. Provide as decimal, default is 0.1.
  - **Total Carbon Uncertainty Factor:** Estimate for the uncertainty of
    total Carbon %. Provide as decimal, default is 0.05.
  - **Nitrogen Consensus Value:** Consensus value for nitrogen derived
    from prior Costech standards, divided from the measured ‘Standards’
    to evaluate new measurements with prior Costech data. Default is
    0.15.
  - **Carbon Consensus Value:** Consensus value for carbon derived from
    prior Costech standards, divided from the measured ‘Standards’ to
    evaluate new measurements with prior Costech data. Default is 2.

The output Excel spreadsheet has a sheet called ‘User Inputs’ that
contains the entry the user provided. If the user does not provide one
of the inputs, the ‘User Inputs’ table will display the default value
used for the calculations.

### Workflow

The following image shows the workflow for creating the automated report
from the Costech. The workflow shows the inputs used in the code and
Shiny application, the functions used in the application code, and the
tables that compose the exported report.

<div class="figure" style="text-align: center">

<img src="/Users/PaulBriggs/Box/Hegedus/Projects/EAL/msucostech/msucostech_report_app/www/msucostech_workflow.png" alt="Workflow for the MSU EAL Costech automated data report. Green shapes in the image below characterize inputs, with ovals representing inputs that are also used in the Shiny application. Functions used in the application are shown in blue and temporary data is represented by yellow shapes. Sheets in the exported Excel report are shown in coral. All of the inputs are included in the 'User Inputs' table of the output." width="75%" />

<p class="caption">

Workflow for the MSU EAL Costech automated data report. Green shapes in
the image below characterize inputs, with ovals representing inputs that
are also used in the Shiny application. Functions used in the
application are shown in blue and temporary data is represented by
yellow shapes. Sheets in the exported Excel report are shown in coral.
All of the inputs are included in the ‘User Inputs’ table of the output.

</p>

</div>

The workflow begins by importing raw data (1). This uses either the
specified folder path and filename or just the filename, assuming it
includes the full path, to extract the ‘Summary Table’ sheet of the
specified Excel spreadsheet. Alternatively, this file is browsed to in
the Shiny application, and data is imported the same way. When the user
elects to create the data report, the raw data is immediately set aside
for export. The ‘Standards’ table is created using the raw data and
consensus values for nitrogen and carbon (2). Next, the ‘Calibration
Range’ table is generated using a subset of the raw data including only
the Acetanilide samples and the user specified detection limit factor
(3). After the ‘Calibration Range’ table is generated, the ‘Results’
table is created using the calibration values and the user specified
uncertainty factors (4). Finally, the data is packaged into an Excel
file and exported (5). For more detail, see below or peruse the code.

The scripts for the application and the code for creating the report are
contained in the ‘msucostech\_report\_app’ folder of this repository.
The ‘msucostech\_report\_app.R’ contains the application deployment and
‘msucostech\_report\_fxns.R’ contains the supporting code. The
following sections describe the arguments, process, and output for each
function;

  - **genUserInputsTab():** Arguments are the list of inputs specified
    by the user. If the user did not provide specifications for a
    parameter, the default values are used. This function creates a data
    frame with a column called ‘Input’ with the full input name, a
    column called ‘Abbreviation’ with the input abbreviation used in the
    code, and a column called ‘Entry’ with either the user specified
    value or the default value. This table is exported as the ‘User
    Inputs’ sheet in the Excel report.
  - **importRawDat():** Arguments are ‘raw\_dat\_filename’ character
    which is the file name for the raw data from the Costech ECS 4010,
    and an optional ‘raw\_dat\_folder\_path’ character which is a path
    to folder where the ‘.xlsx’ raw file is stored. This function
    imports the ‘Summary Table’ sheet, sets the column names, and
    returns the raw data frame. This requires the Costech outputs to
    remain standard. This data frame is exported in the ‘Summary Table’
    sheet of the report.
  - **genStandardsTab():** Arguments for this function are the
    ‘SummaryTable’ data frame which is the raw Costech data, a
    character vector of identifiers in SampleIDs for Standard D samples
    called ‘std\_d\_identifiers’. This is a baked in set of identifiers
    that include ‘Std\_D’, ‘Standard’, and ‘StdD’. The other two
    arguments are the nitrogen and carbon consensus values,
    ‘N\_consensus\_val’ and ‘C\_consensus\_val’, which are used to
    calculate the consensus metric for each sample. This function
    subsets Standard D samples from the raw data. Currently this process
    is performed via pattern matching expected codes used for Standard D
    samples using the ‘std\_d\_identifiers’ matched in the ‘SampleID’
    column. This is not case sensitive and requires a mild
    standardization of SampleIDs to be identifiable. The mean and
    standard deviation are calculated for nitrogen and carbon weight
    percentages and added as columns to the subset, (‘x\_mean’, ‘x\_sd’
    where ‘x’ is ‘N’ or ‘C’, respectively). The coefficient of variation
    for both elements are then calculated as the standard deviation
    divided by the mean and added as a column for each (‘x\_cv’ where
    ‘x’ is ‘N’ or ‘C’, respectively). Note that the mean, standard
    deviation, and coefficient of variation are constant for all rows of
    the A consensus metric is then derived in the ‘N\_consensus’ or
    ‘C\_consensus’ column by dividing each observation’s weight
    percent by the user specified consensus value for each element. The
    columns of the subset are grouped by element and then returned to
    the user. The returned data frame contains all of the columns in the
    raw data plus the four calculated above for each element. This adds
    eight columns to the ‘Standards’ table that is exported in the
    report.
  - **genCalRangeTab():** The arguments for this function are the
    ‘SummaryTable’ data frame which is the raw Costech data, a
    character vector of identifiers in SampleIDs for Acetanilide samples
    called ‘acet\_identifiers’. This is a baked in set of identifiers
    that include ‘Acetanilide’, ‘Acet’, ‘Acetan’, ‘Acetanalide’,
    ‘analide’. The third argument is the user specified detection
    limit factor, ‘det\_limit\_fctr’. This function subsets Acetanilide
    samples from the raw data. Currently this process is performed via
    pattern matching expected codes used for Acetanilide samples using
    the ‘acet\_identifiers’ matched in the ‘SampleID’ column. This is
    not case sensitive and requires a mild standardization of SampleIDs
    to be identifiable. An empty ‘Calibration Range’ table is generated
    with a column labeled ‘CalibrationRange’ with ‘N’ and ‘C’ to
    deliminate nitrogen and carbon limits and filled in with the
    following calculations. The low and high calibration ranges (‘Low’
    and ‘High’ columns, respectively) for each element are derived by
    the minimum and maximum weights (‘x\_Weight\_mg’ where ‘x’ is ‘N’ or
    ‘C’) in the Acetanilide subset. The ‘DetectionLimit’ column is
    calculated by dividing the low calibration range by the user
    specified detection limit factor, ‘det\_limit\_fctr’. This may be a
    temporary process until a data-driven approach is developed. After
    the ‘Calibration Range’ table has been completed, it is returned to
    the user. This is exported in the Excel spreadsheet report in the
    ‘Calibration Range’ sheet.
  - **genResultsTab():** The arguments for this function are the
    ‘SummaryTable’ data frame which is the raw Costech data, the
    ‘Calibration Range’ data frame created from the genCalRangeTab()
    function as ‘CalibrationRange’, the ‘std\_d\_identifiers’ and
    ‘acet\_identifiers’ character vectors specified as arguments in
    the functions above, and the uncertainty factors for nitrogen and
    carbon (‘N\_uncertainty\_fctr’, ‘C\_uncertainty\_fctr’,
    respectively). This function uses the identifiers for Standard D and
    Acetanilide samples to take all rows that aren’t these or a bypass,
    identified by ‘Bypass’ or ‘By pass’ in the SampleID. The ‘SampleID’,
    weight (‘x\_Weight\_mg’, where ‘x’ is ‘C’ or ‘N’) and weight
    percents (‘x\_Weight\_pct’, where ‘x’ is ‘C’ or ‘N’) are the columns
    taken from the raw data during the subsetting process. The weight
    percent columns are renamed to ‘%TN’ and ‘%TC’, respectively for
    each element. The nitrogen and carbon percent uncertainty are
    calculated and added to the table by multiplying the weight percent
    by the nitrogen or carbon uncertainty factor that was specified by
    the user. These are included as columns named ‘%TN uncertainty’ and
    ‘%TC uncertainty’. Using the weights in mg for each element, the
    flags (‘%TN flag’ and ‘%TC flag’) are derived by determining if the
    weight falls; first below the detection limit, and then within the
    bounds of the quantifiable limits. Observations are labeled ‘bdl’ if
    the measurement falls below the detection limit, ‘bql’ if the
    measurement falls below the lower quantifiable limit, ‘aql’ if the
    measurement exceeds the upper quantifiable limit, or ‘ok’ if it
    falls within the quantifiable limits. The detection and quantifiable
    detection limits for each element are taken from the
    ‘CalibrationRange’ table. The weight columns are removed from the
    ‘Results’ table, the columns are organized by element, and the
    ‘Results’ table is returned to the user. This table is exported in
    the ‘Results’ sheet of the Excel report.
  - **exportReport():** This function takes a list of outputs, labeled
    ‘Results’, ‘CalibrationRange’, ‘Standards’, ‘SummaryTable’, and
    ‘UserInputs’ from the functions above, in any order. This function
    then puts them into an Excel spreasheet that is exported to the
    user’s file system folder with sheets labeled as ‘Results’,
    ‘Calibration Range’, ‘Standards’, ‘Summary Table’, and ‘User
    Inputs’. The exported filename is a concatenation of the raw
    filename with ‘*REPORT*’ plus the date and time the report was
    generated.

### Outputs

When raw data and inputs are provided, the user must select the ‘Create
Report’ button. The output data report will be automatically downloaded
upon completion. The output Excel sheet has tabs for ‘Results’,
‘Calibration Range’, ‘Standards’, ‘Summary Table’, and ‘User Inputs’.
The ‘Results’ table contains the total nitrogen and carbon weight
percentages, uncertainties, and a flag for whether the observation falls
within the detectable limits. The ‘Calibration Range’ table contains the
low and high quantifiable limits and the detection limit for nitrogen
and carbon, calculated from the minimum and maximum nitrogen and carbon
values measured in the acetanalide samples. The ‘Standards’ table
includes the Standard D samples from the raw data with columns
containing the calculated mean, standard deviation, coefficient of
variation, and consensus with user specified consensus values for each
element. The ‘Summary Table’ contains the unmodified raw data and the
‘User Inputs’ table contains the parameters used in the calculations.
