library(tidyverse)
library(hrbrthemes)
library(viridis)

# # Read data table
dir_path <- "~/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/ws_cruise_ctd"
file_name <- list.files(path = dir_path, pattern = "AOML_SFP_regional_WQ_surface_w_sscp.csv", full.names = TRUE)
sfp_df <- read.csv(file_name, fill = TRUE)

# # Load seascape color palette used with Matlab and extract RGB values for observed unique seascapes
# For NOAA machines
# palette_dir <- "/Users/enrique.montes/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/software/matlab/m_map/seascape_cm"
# For personal machine
palette_dir <- "~/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/software/matlab/m_map/seascape_cm"
palette_file <- list.files(path = palette_dir, pattern = "cmap1.csv", full.names = TRUE)
palette_df <- read.csv(palette_file, header = FALSE)
colnames(palette_df) <- c("r", "g", "b")
unique_seascapes <- sort(unique(na.omit(sfp_df$seascape_week)))
subset_palette_df <- palette_df[unique_seascapes, ]

# set RGB values for the plots
r_vals <- round(subset_palette_df$r * 255, 0)
g_vals <- round(subset_palette_df$g * 255, 0)
b_vals <- round(subset_palette_df$b * 255, 0)
custom_pal <- cbind(r_vals, g_vals, b_vals)
custom_pal_hex <- rgb(custom_pal[, 1], custom_pal[, 2], custom_pal[, 3], maxColorValue=255)

# filter out rows with NA values in column seascapes
df_filtered <- sfp_df[complete.cases(sfp_df$seascape_week),]

# Convert the 'x' column to character
df_filtered$seascape_week <- as.character(df_filtered$seascape_week)

# # Reorder seascape categories in X axis
df_filtered$seascape_week <- factor(df_filtered$seascape_week, levels = c("3", "7", "11", "13", "15", "17", "18", "21","27"))

# Define custom colors for each level
custom_colors <- c("3" = custom_pal_hex[1], "5" = custom_pal_hex[2], "7" = custom_pal_hex[3],
                   "11" = custom_pal_hex[4], "13" = custom_pal_hex[5], "15" = custom_pal_hex[6],
                   "17" = custom_pal_hex[7], "18" = custom_pal_hex[8], "21" = custom_pal_hex[9], 
                   "27" = custom_pal_hex[10])

# Filter out seascape class as desired
seascapes_to_exclude <- c("5", "17", "18")
df_filtered <- df_filtered[!(df_filtered$seascape_week %in% seascapes_to_exclude), ]
df_filtered <- df_filtered[complete.cases(df_filtered$seascape_week),]
df_filtered <- df_filtered[grepl("^\\d+\\.?\\d*$", df_filtered$chla), , drop = FALSE]

# Plot
# See https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html for color palette options
pp <- df_filtered %>%
  ggplot( aes(x=seascape_week, y=chla, fill=seascape_week)) +
  geom_jitter(color="grey", size=0.7, alpha=0.8) +
  geom_boxplot(outlier.shape = NA) +
  # geom_violin(outline.type = "blank") +
  # scale_fill_viridis(option="H", discrete = TRUE, alpha=0.6) +
  scale_fill_manual(values = custom_colors) +
  labs(x = "Seascape class") +
  labs(y = expression("[Chl-a] (mg/L)")) +
  # labs(y = expression("Salinity")) +
  # labs(y = expression(paste("Temperature (", degree, "C) at 1 m depth"))) +
  # labs(y = expression("DO (mg/L)")) +
  # labs(y = expression("NO"["x"] ~ mu*"M")) +
  # labs(y = expression("PO"["4"]^"3-" ~ mu*"M")) +
  # theme(axis.title.y = element_text(hjust = 1))
  # scale_x_discrete(labels= c("Tropical/Subtropical Upwelling", 
  #                          "Tropical Seas", 
  #                          "Warm, Blooms, High Nuts", 
  #                          "Tropical/Subtropical Transition", 
  #                          "Temperate Transition")) +
  theme_ipsum() +
  theme(
    legend.position="none",
    plot.title = element_text(size=11)
  ) +
  # ggtitle("A boxplot with jitter") +
  # theme(axis.text.x = element_text(angle = 45)) +
  ylim(0, 7) +
  theme(axis.text.x = element_text(size = 32),  # Set X-axis label font size
        axis.text.y = element_text(size = 32)) +
  theme(axis.title.x = element_text(size = 18),
        axis.title.y = element_text(size = 18)) +
  theme(legend.text = element_text(size = 32)) 
pp


################################################################################
# Perform principal component analysis 
library(ggalt)

sel_vars <- c(
  "seascape_week",
  # "temp",
  "year",
  "month",
  "salinity",
  "chla",
  "po4",
  "no3_no2")

# filter out rows with NA values in column seascapes
df_filtered_pca <- sfp_df[complete.cases(sfp_df[, sel_vars]), ]
exclude_seascapes <- c(5, 7, 11, 17, 18)
filt_df_pca <- df_filtered_pca[!df_filtered_pca$seascape_week %in%
                                 exclude_seascapes, sel_vars]

# Select numeric columns in filt_df_pca
numeric_cols <- sapply(filt_df_pca, is.numeric)
# Identify numeric columns except the first one
numeric_cols <- 3:ncol(filt_df_pca)

# Transform numeric columns to log scale
filt_df_pca[numeric_cols] <- lapply(filt_df_pca[numeric_cols], function(x) log(x + 1))

# Group by seascape_week and year, then compute the averages for salinity, chla, po4, and no3_no2
filt_df_pca_per_yr <- filt_df_pca %>%
  group_by(seascape_week, year, month) %>%
  summarize(avg_salinity = mean(salinity, na.rm = TRUE),
            avg_chla = mean(chla, na.rm = TRUE),
            avg_po4 = mean(po4, na.rm = TRUE),
            avg_no3_no2 = mean(no3_no2, na.rm = TRUE))

pca <- prcomp(filt_df_pca_per_yr[, c("avg_salinity", "avg_chla", "avg_po4", "avg_no3_no2")], scale. = TRUE)

# Extract PC1 and PC2 scores for each sampling event
pc_scores <- data.frame(seascape = as.character(filt_df_pca_per_yr$seascape_week), # for hydrography
                        PC1 = pca$x[, 1], 
                        PC2 = pca$x[, 2])

# Create the plot
pc_scores$seascape <- factor(pc_scores$seascape, levels = c("3", "13", "15", "21", "27"))
bb <- ggplot(pc_scores, aes(x = PC1, y = PC2, color = seascape)) + 
  geom_point() +
  labs(x = "PC1", y = "PC2", color = "Seascape") 

custom_colors_pca <- c("3" = custom_pal_hex[1], 
                       "13" = custom_pal_hex[5], 
                       "15" = custom_pal_hex[6], 
                       "21" = custom_pal_hex[9], 
                       "27" = custom_pal_hex[10])

# add circle around cluster of data points
yy <- ggplot(pc_scores, aes(x = PC1, y = PC2, color = seascape)) + 
  geom_point() +
  # stat_ellipse(aes(fill = seascape), level = 0.90, geom = "polygon", alpha = 0.3, color = "black") +
  scale_color_manual(values = custom_colors_pca) +
  scale_fill_manual(values = custom_colors_pca) +
  theme_classic() +
  # xlim(-2.5,3) +
  # ylim(-2.5,2.5) +
  xlim(-1,1.5) +
  ylim(-2,2) +
  geom_point(size=1) +
  guides(colour = guide_legend(override.aes = list(size=2))) + 
  theme(axis.text.x = element_text(size = 32),  # Set X-axis label font size
        axis.text.y = element_text(size = 32)) +
  theme(axis.title.x = element_text(size = 32),
        axis.title.y = element_text(size = 32)) +
  theme(legend.text = element_text(size = 32))

yy

################################################################################################
# # Create PCA with eigenvectors
# Extract principal component scores
pc_scores2 <- pca$x
# Extract eigenvectors
eigenvectors <- pca$rotation
# Calculate the percentage variance explained by each principal component
total_variance <- sum(pca$sdev^2)
pc_var_percent <- round(100 * (pca$sdev^2) / total_variance, 1)

# Convert seascape_week  to a factor
filt_df_pca_per_yr$seascape_week <- as.factor(filt_df_pca_per_yr$seascape_week)

# # For hydrography
qq <- ggplot(filt_df_pca_per_yr, aes(x = pc_scores2[,1], y = pc_scores2[,2], color = seascape_week)) +
  geom_point(size = 4) +
  scale_color_manual(values = custom_colors_pca) +
  geom_segment(aes(x = 0, y = 0, xend = eigenvectors[1, 1], yend = eigenvectors[2, 1]),
               arrow = arrow(length = unit(0.2, "inches")), color = "black") +  # Add vector for PC1
  geom_segment(aes(x = 0, y = 0, xend = eigenvectors[1, 2], yend = eigenvectors[2, 2]),
               arrow = arrow(length = unit(0.2, "inches")), color = "black") + # Add vector for PC2
  geom_segment(aes(x = 0, y = 0, xend = eigenvectors[1, 3], yend = eigenvectors[2, 3]),
               arrow = arrow(length = unit(0.2, "inches")), color = "black") + # Add vector for PC3
  geom_segment(aes(x = 0, y = 0, xend = eigenvectors[1, 4], yend = eigenvectors[2, 4]),
               arrow = arrow(length = unit(0.2, "inches")), color = "black") + # Add vector for PC4
  geom_text(aes(x = eigenvectors[1, 1], y = eigenvectors[2, 1], 
                label = paste("PC1 (", pc_var_percent[1], "%: Salinity)", sep = "")),
            vjust = -0.5, hjust = 0.5, color = "black") +  # Add label for PC1
  geom_text(aes(x = eigenvectors[1, 2], y = eigenvectors[2, 2], 
                label = paste("PC2 (", pc_var_percent[2], "%: Chla)", sep = "")),
            vjust = -0.5, hjust = 0.5, color = "black") +  # Add label for PC2
  geom_text(aes(x = eigenvectors[1, 3], y = eigenvectors[2, 3], 
                label = paste("PC3 (", pc_var_percent[3], "%: PO4)", sep = "")),
            vjust = -0.5, hjust = 0.5, color = "black") +  # Add label for PC3
  geom_text(aes(x = eigenvectors[1, 4], y = eigenvectors[2, 4], 
                label = paste("PC4 (", pc_var_percent[4], "%: NOx)", sep = "")),
            vjust = -0.5, hjust = 0.5, color = "black") +  # Add label for PC4
  labs(x = "PC1", y = "PC2", color = "X8.day.seascapes") +
  xlim(-1.5, 1.5) +
  ylim(-1.5, 1.5) +
  guides(colour = guide_legend(override.aes = list(size=2))) + 
  theme_classic() +
  theme(axis.text.x = element_text(size = 32),  # Set X-axis label font size
        axis.text.y = element_text(size = 32)) +
  theme(axis.title.x = element_text(size = 32),
        axis.title.y = element_text(size = 32)) +
  theme(legend.text = element_text(size = 32)) 
qq


################################################################################
# Perform Correspondence Analysis (CA) on the count data
# install.packages("ca")
library(CCA)

# Define selected variables for CA
sel_vars <- c(
  "seascape_week",
  # "temp",
  # "salinity",
  "chla",
  "po4",
  "no3_no2"
)

# Filter out rows with NA values in column seascape_week
df_filtered_ca <- sfp_df[complete.cases(sfp_df[, sel_vars]), ]
exclude_seascapes <- c(5, 7, 11, 17, 18)
filt_df_ca <- df_filtered_ca[!df_filtered_pca$seascape_week %in% exclude_seascapes, sel_vars]

# Perform correspondence analysis
ca_result <- ca(filt_df_ca[, -1])  # Exclude the first column (seascape_week)

# Extract Eigenvalues and Eigenvectors
eigenvalues <- ca_result$sv^2

# Extract column principal coordinates (column eigenvectors) for 
# information about the relationships between the variables
row_eigenvectors <- ca_result$rowcoord
row_eigenvectors_df <- as.data.frame(row_eigenvectors)

# Assuming seascape_week is present in the original data frame used for correspondence analysis
# Merge the seascape_week variable with column_eigenvectors_df
row_eigenvectors_df <- merge(column_eigenvectors_df, filt_df_ca[, c("seascape_week")], by = "row.names")

# Plot the first two column eigenvectors with color-coded observations
ggplot(row_eigenvectors_df, aes(x = Dim1, y = Dim2, color = as.factor(filt_df_ca$seascape_week))) +
  geom_point() +
  labs(x = "Column Eigenvector 1",
       y = "Column Eigenvector 2",
       color = "Seascape Week",
       title = "Correspondence Analysis: Column Eigenvectors with Observations") +
  scale_color_discrete(name = "Seascape Week")

