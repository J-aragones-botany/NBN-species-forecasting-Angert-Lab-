# Jacob Aragones, The University Of British Columbia
# NBN-Atlas SDM competition
# 11-06-2026
# GBIF observations for expanding the training dataset 

# check/set working directory

# Pkgs
library(rgbif)
library(stringr)
library(tidyverse)

# Occurrence Data ----

# Species names
# get directories
species_list <- list.dirs('data/NBN-atlas/species/', recursive = F)
species_names <- list.dirs('data/NBN-atlas/species/', full.names = F, recursive = F)

# List the occurrence records
species_records_list <- lapply(species_list, function(s){
  species_path <- list.files(s, pattern = '_processed\\.csv', full.names = T)
  read.csv(species_path)} 
)

# Add names to list
names(species_records_list) <- species_names

#### Get GBIF Data for all species ----

# seperate genus and species
name_df <- str_split_fixed(species_names, 
  pattern = "_", 
  n = 2 ) |> 
  as.data.frame() |> 
  rename(genus = 1,
         species = 2)

# Find GBIF backbones

name_search_results <- apply(name_df, 1, function(df){
  backbone <- name_backbone(genus = df['genus'], species = df['species']) }
 )

# Select columns to check accuracy
qual_columns <- c('usageKey', 'authorship', 'confidence', 'verbatim_species', 'verbatim_genus', 'genus', 'species')

# Compile into list of Dfs
taxon_name_qual_check <- lapply(name_search_results, function(s){
  s[qual_columns]
})

# Everything looks good pull everything from GBIF
usage_keys <- c()

for(t in taxon_name_qual_check) {
  usage_keys <- c(usage_keys, t$usageKey)
}

names(usage_keys) <- species_names

# Ok set up downloads
species_download_object <- occ_download(
  type = "and",
  pred_in("taxonKey", usage_keys),
  pred("hasCoordinate", TRUE),
  pred("occurrenceStatus","PRESENT"), 
  pred_gte("year", 1950),
  format = "SIMPLE_CSV")

occ_download_wait(species_download_object)
