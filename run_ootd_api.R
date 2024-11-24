library(plumber)

run_api <- plumb("ootd_api.R")
run_api$run(port=8000)