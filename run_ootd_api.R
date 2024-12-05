library(plumber) 

# Load the Plumber API definition from the specified R script
run_api <- plumb("ootd_api.R")

# Start the API on port 8000
run_api$run(port = 8000)
