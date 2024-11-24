#!/bin/bash
# Usage: ./run_pipeline.sh YOUR_ACCESS_KEY
YOUR_ACCESS_KEY=$1
export YOUR_ACCESS_KEY
export LOG_FILE="./log_file.log"  # Relative path to log file

# Ensure log file exists
touch "$LOG_FILE"

# Run R scripts
Rscript product_scraping.R
Rscript weatherstack_api.R >> "$LOG_FILE" 2>&1
Rscript etl.R >> "$LOG_FILE" 2>&1
Rscript run_ootd_api.R &
# Wait for API to start
sleep 5
# Call the /ootd endpoint
curl "http://127.0.0.1:8000/ootd" --output ~/Downloads/ootd_plot.png
echo "Outfit of the Day plot saved as ootd_plot.png in Downloads"
