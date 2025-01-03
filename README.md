# stringmatch
This script counts number of png files with file names that match specific string conditions. In this case, file names of png's are generated by date and time of collection of CPICS images. The goal is to match CPICS imagery to concurrent CTD variables using date and time information, calculate plankton concentrations, and create data visualizations.

Workflow:
- Download data from CPICS into 'cpics_img' in the office Mac Desktop
- Download lists of annotation into 'TS.Master_selection'
- Run img_distributor.md to copy annotated images into class folders and unclassified folder
- Run getmajorandminoraxis2024_4_PH.py (nioz folder) to extract deep features 
- Run photometa_pycode.Rmd to merge image records with cruise data and deep feature tables
- Place ecotaxa_sfer-mbon.txt into 'selected' folder containing all annotated images and zip compress
- Upload to Ecotaxa
- If metadata will be updated the ecotaxa_import.tsv file must be zip compressed, otherwise Ecotaxa does not recognize it.
