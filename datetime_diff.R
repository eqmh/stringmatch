library(lubridate)
library(here)

source(here::here("lib/sources.R"))

datetime_table <- read.csv('datetime_array.csv', fill = TRUE, stringsAsFactors = FALSE)
colnames(datetime_table) <- c("year", "month", "day", "hour", "minute", "second")

# Check and convert columns to numeric (integer) type
datetime_table$year <- as.integer(datetime_table$year)
datetime_table$month <- as.integer(datetime_table$month)
datetime_table$day <- as.integer(datetime_table$day)
datetime_table$hour <- as.integer(datetime_table$hour)
datetime_table$minute <- as.integer(datetime_table$minute)
datetime_table$second <- as.integer(datetime_table$second)

# Check the structure of the data (optional, for debugging)
str(datetime_table)

# Create datetime object using make_datetime
datetime <- make_datetime(
  year = datetime_table$year,
  month = datetime_table$month,
  day = datetime_table$day,
  hour = datetime_table$hour,
  min = datetime_table$minute,
  sec = datetime_table$second
)

# Print the result
print(datetime)

# Convert the differences to hours
time_diff <- diff(datetime)
time_diff_hours <- as.numeric(time_diff) / 60
print(time_diff_hours)
print(which.max(time_diff_hours))
