library(dplyr)
library(tidyverse)
library(lubridate)
library(dplyr)

# specify the directory where the files are located
dir_path <- "~/enriquemontes01@gmail.com - Google Drive/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/TS.Master_selection/"

# obtain a list of file names in the directory
file_names <- list.files(path = dir_path, pattern = ".txt", full.names = TRUE)

# loop over each file and import the tables (use this for DATES)
for (file in file_names) {
  table_name <- gsub(".txt", "", basename(file)) # get the name of the table from the file name
  assign(table_name, read.table(file = file, header = FALSE, sep = "\t") %>%
           mutate(date = as.POSIXct(substr(V1, start = 24, stop = 36), format="%Y%m%d_%H%M", tz="UTC")))
}

# Directory where the CTD metadata is located
dir_path2 <- "~/enriquemontes01@gmail.com - Google Drive/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/ws_cruise_ctd/"
file_name <- list.files(path = dir_path2, pattern = "ctd_meta_v2.csv", full.names = TRUE)
ctd_meta <- read.csv(file_name, fill = TRUE)

dt_list <-ctd_meta$GMT.datetime %>% as.POSIXct(unique_all, format="%Y%m%d_%H%M", tz="UTC")
test <-  as.data.frame(dt_list)

# Create empty data frame to store results
conc_occ_final <- data.frame(date = character(), count = numeric())

# Iterate over dt_list intervals
for (i in 197:(length(dt_list))) {
  
  # Subset A for dates within current interval
  chaetog_subset <- subset(class.Chaetognaths, date >= dt_list[i] & date < dt_list[i+1])
  chaetog_count <- nrow(chaetog_subset)
  print(chaetog_count)
  
  # Add date and count to results data frame
  result <- data.frame(date = dt_list[i], 
                       Chaetognaths = chaetog_count)
  conc_occ_final <- do.call(rbind, list(conc_occ_final, result))
} 
