# Time series of zooplankton abundance in the Florida Keys, 
# collected by the South Florida Program (NOAA/AOML) and the Marine Biodiversity
# Observation Network (MBON)

# OBIS data source: https://obis.org/dataset/afef5da2-614b-4208-aee6-c2413ed5ab76

library(robis)

# Get the data from OBIS
plankton_df <- occurrence(datasetid = 'afef5da2-614b-4208-aee6-c2413ed5ab76')

# Generate species list
ssp_list <- as.data.frame(unique(plankton_df$scientificName))