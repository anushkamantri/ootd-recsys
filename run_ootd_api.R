library(plumber)

run_api <- plumb("ootd_api.R")
run_api$run(host = "0.0.0.0", port=8000)