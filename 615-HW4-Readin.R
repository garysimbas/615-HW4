library(data.table)
library(lubridate)
library(ggplot2)
library(dplyr)

# a
# function to load buoy data for a given year
load_buoy <- function(year) {
  base_url <- "https://www.ndbc.noaa.gov/view_text_file.php?filename=44013h"
  suffix <- ".txt.gz&dir=data/historical/stdmet/"
  file_url <- paste0(base_url, year, suffix)
  
  # skip header lines based on year
  skip <- ifelse(year < 2007, 1, 2)
  
  # read column names
  headers <- scan(file_url, what = 'character', nlines = 1)
  
  # load the dataset with fill to handle missing columns
  buoy <- fread(file_url, header = FALSE, skip = skip, fill = TRUE)
  
  # adjust columns to match header count
  if (ncol(buoy) > length(headers)) {
    buoy <- buoy[, 1:length(headers), with = FALSE]
  } else if (ncol(buoy) < length(headers)) {
    for (i in 1:(length(headers) - ncol(buoy))) {
      buoy[, paste0("V", ncol(buoy) + i) := NA]
    }
  }
  
  # assign column names
  setnames(buoy, headers)
  
  # combine date and time into a single column
  buoy$datetime <- make_datetime(
    year = as.integer(buoy$YYYY), 
    month = as.integer(buoy$MM), 
    day = as.integer(buoy$DD), 
    hour = as.integer(buoy$hh), 
    min = as.integer(buoy$mm)
  )
  
  return(buoy)
}

# define years range
years <- 1985:2023

# load data for each year
buoy_list <- lapply(years, load_buoy)

# combine all yearly data
combined_buoy <- rbindlist(buoy_list, fill = TRUE)

fwrite(combined_buoy, "buoy_data.csv")
