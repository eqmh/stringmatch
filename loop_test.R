library(dplyr)

# specify the directory where the files are located
dir_path <- "/Users/enrique.montes/Google Drive/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/TS.Master_selection"

# obtain a list of file names in the directory
file_names <- list.files(path = dir_path, pattern = ".txt", full.names = TRUE)

# loop over each file and import the tables (use this for DATES)
for (file in file_names) {
  table_name <- gsub(".txt", "", basename(file)) # get the name of the table from the file name
  assign(table_name, read.table(file = file, header = FALSE, sep = "\t") %>%
           mutate(date = as.POSIXct(substr(V1, start = 24, stop = 38), format="%Y%m%d_%H%M%S", tz="UTC")))
}

library(tidyverse)
library(lubridate)

# Directory where the CTD metadata is located
dir_path2 <- "/Users/enrique.montes/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/ws_cruise_ctd"
file_name <- list.files(path = dir_path2, pattern = "ctd_meta_v3.csv", full.names = TRUE)
ctd_meta <- read.csv(file_name, fill = TRUE)

# # USE WITH ctd_meta_v3.csv
dt_list <- as.POSIXct(paste(ctd_meta$year,
                            sprintf("%02d", ctd_meta$month),
                            sprintf("%02d", ctd_meta$day),
                            ctd_meta$time_gmt),
                      format = "%Y%m%d %I:%M:%S %p",
                      tz = "UTC")

# Preallocate the data frame
conc_occ_final <- data.frame(date = character(), Echinoderms = numeric(), stringsAsFactors = FALSE)

# Create an empty list to store results
result_list <- list()

# Iterate over dt_list intervals (up to second to last object)
for (i in 1:(length(dt_list) - 1)) {
  
  # Subset Echinoderms for dates within the current interval
  echino_subset <- subset(class.Echinoderms, date >= dt_list[i]-300 & date < dt_list[i]+600)
  echino_count <- nrow(echino_subset)
  
  # Add date and count to the result list
  result_list[[i]] <- data.frame(date = dt_list[i], 
                                 Echinoderms = echino_count)
}

# Combine the results into a data frame
conc_occ_final <- do.call(rbind, result_list)
