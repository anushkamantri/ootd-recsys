#!/bin/bash
# Usage: ./run_pipeline.sh YOUR_ACCESS_KEY
# Pipeline script for the Outfit Recommendation System

# Check if API key is provided
if [ -z "$1" ]; then
    echo "Usage: $0 YOUR_API_KEY"
    exit 1
fi

YOUR_ACCESS_KEY=$1
export YOUR_ACCESS_KEY
export LOG_FILE="./log_file.log"

# Ensure the log file exists
touch "$LOG_FILE"

# Ensure the output directory exists
mkdir -p output

# Run R scripts for scraping, API calls, and ETL
Rscript weatherstack_api.R >> "$LOG_FILE" 2>&1
Rscript product_scraping.R
Rscript etl.R >> "$LOG_FILE" 2>&1

# Start the API server
Rscript run_ootd_api.R >> "$LOG_FILE" 2>&1 &

# Wait for the server to initialize
sleep 5

# Call the /ootd endpoint and save the output plot
curl "http://127.0.0.1:8000/ootd" --output output/ootd_plot.png
echo "Outfit of the Day plot saved as ootd_plot.png in the output directory!"
