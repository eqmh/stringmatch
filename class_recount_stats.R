# # This script checks for possible double counting in CPICS ROIs.

library(dplyr)

# specify the directory where the files are located
dir_path <- "~/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/TS.Master_selection"

# obtain a list of file names in the directory
file_names <- list.files(path = dir_path, pattern = ".txt", full.names = TRUE)

# loop over each file and import the tables (use this for DATES)
for (file in file_names) {
  table_name <- gsub(".txt", "", basename(file)) # get the name of the table from the file name
  assign(table_name, read.table(file = file, header = FALSE, sep = "\t") %>%
           mutate(date = as.POSIXct(substr(V1, start = 24, stop = 42), format="%Y%m%d_%H%M%S", tz="UTC")))
}

# List of class objects to be processed
class_names <- c("Acantharea", "Centric", "Ceratium", "Chaetoceros", "Chaetognaths", 
                 "Chain2", "Chain3", "Ostracods", "Copepods", "Decapods", "Echinoderms", 
                 "Guinardia", "Jellies", "Larvaceans", "Neocalyptrella", "Noctiluca", 
                 "pellets", "Polychaets", "Pteropods", "Tricho")

# Initialize an empty results data frame
results_table <- data.frame(Class = character(),
                            Count_Less_Than_1_Sec = numeric(),
                            Total_Count = numeric(),
                            Percent_Less_Than_1_Sec = numeric(),
                            stringsAsFactors = FALSE)

# Loop through each class data frame
for (class_name in class_names) {
  # Dynamically get the class data frame
  class_data <- get(paste0("class.", class_name))
  
  # Ensure the date column is in POSIXct format
  class_data$date <- as.POSIXct(class_data$date, format = "%Y-%m-%d %H:%M:%OS", tz = "UTC")
  
  # Calculate the time difference between consecutive date entries
  time_diff <- diff(class_data$date)
  
  # Count the number of instances where the time difference is less than 1 second
  count_less_than_1_sec <- sum(time_diff < 1, na.rm = TRUE)
  
  # Calculate the total number of date entries
  total_count <- nrow(class_data)
  
  # Calculate the percentage of time differences less than 1 second
  percent_less_than_1_sec <- (count_less_than_1_sec / total_count) * 100
  
  # Add the result to the results table
  results_table <- rbind(results_table, data.frame(Class = class_name,
                                                   Count_Less_Than_1_Sec = count_less_than_1_sec,
                                                   Total_Count = total_count,
                                                   Percent_Less_Than_1_Sec = round(percent_less_than_1_sec, 2)))
}

# Print the results table
print(results_table)

library(ggplot2)
# Create the scatter plot
plot <- ggplot(results_table, aes(x = Total_Count, y = Percent_Less_Than_1_Sec, label = Class)) +
  geom_point(size = 3, color = "blue") +  # Scatter points
  geom_text(vjust = -0.5, hjust = 0.5, size = 4) +  # Add class labels
  scale_x_log10() +
  labs(
    title = "Total Count vs. Percent of Close Date Entries",
    x = "Total Count",
    y = "Percent of Time Differences < 1 Second (%)"
  ) +
  theme_minimal() +
  theme(
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    plot.title = element_text(size = 16, hjust = 0.5)
  )

# Print the plot
print(plot)

############################################################################################################
# # This creates a table with possible recount percentages aggregated by date and hour
library(dplyr)
library(lubridate)

# Ensure the date column in class.Chain3 is in POSIXct format
class.Chain3$date <- as.POSIXct(class.Chain3$date, format = "%Y-%m-%d %H:%M:%OS", tz = "UTC")

# Extract day and hour components from the date-time column
class.Chain3 <- class.Chain3 %>%
  mutate(day_hour = floor_date(date, unit = "hour"))  # Round down to the nearest hour

# Group data by day-hour
aggregated_data <- class.Chain3 %>%
  arrange(date) %>%  # Ensure data is sorted by date
  group_by(day_hour) %>%
  summarise(
    class_total_count = n(),  # Total number of date-time objects in the group
    repeat_count = sum(diff(date) < 1, na.rm = TRUE)  # Count instances with time difference < 1 second
  ) %>%
  ungroup() %>%
  mutate(
    percent_repeat = (repeat_count / class_total_count) * 100  # Calculate percentage
  )

# Print the results
print(aggregated_data)

# Create the scatter plot
plot2 <- ggplot(aggregated_data, aes(x = class_total_count, y = percent_repeat)) +
  geom_point(size = 3, color = "blue") +  # Scatter points
  labs(
    title = "Chain3: Total Count vs. Percent of Close Date Entries",
    x = "Total Count",
    y = "Percent of Time Differences < 1 Second (%)"
  ) +
  theme_minimal() +
  theme(
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    plot.title = element_text(size = 16, hjust = 0.5)
  )

# Print the plot
print(plot2)


