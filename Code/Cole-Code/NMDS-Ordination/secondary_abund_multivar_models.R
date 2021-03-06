########## 
##########
# This code contains the multivariate modeling component of the analysis presented in
# in Green et al. (2020) 
# A review on the use of traits in ecological research
##########
##########
# AUTHOR: Cole B. Brookson
# DATE OF CREATION: 2020-06-30
##########
##########

library(tidyverse)
library(vegan)
library(viridis)
library(mvabund)
library(here)

#separate the modeling into the P/A modeling (1/0) and then the abundance modeling
secondary_abundance = read_csv(here('./Data/Cole-Output-Data(readyforanalysis)/secondary_traits_dummy_abundance_models.csv'))

#split species and sites
secondary_abundance_sites = data.frame(secondary_abundance[,1:10])
secondary_abundance_species = data.frame(secondary_abundance[,11:ncol(secondary_abundance)])

#run actual ordination - try with both k = 2 & 3
#set.seed(0002)
# secondary_abundance_ord_k3 = metaMDS(secondary_abundance_species,
#                               #distance = 'bray',
#                               trymax = 1000,
#                               k = 4)
# saveRDS(secondary_abundance_ord_k3, here('./Model Output/Secondary_abundance/nMDS/secondary_abundance_ord.rds'))
secondary_abundance_ord_k4 = readRDS(here('./Model Output/Secondary_abundance/nMDS/secondary_abundance_ord.rds'))

############################## Plotting pipeline ###############################

#extract scores
secondary_ab_k4_scores <- data.frame(scores(secondary_abundance_ord_k4)) 
secondary_ab_k4_scores$points <- rownames(secondary_abundance_ord_k4) 
secondary_ab_scores = cbind(secondary_abundance_sites, secondary_ab_k4_scores)

secondary_ab_scores = 
  secondary_ab_scores[#excluded 14 rows here
    which(secondary_ab_scores$NMDS1 < 0.01 &
            secondary_ab_scores$NMDS1 > -0.01 &
            secondary_ab_scores$NMDS2 > -0.01 &
            secondary_ab_scores$NMDS2 < 0.01),]

hist(secondary_ab_scores$NMDS1)
hist(secondary_ab_scores$NMDS2)



#add species
secondary_ab_trait_scores = data.frame(scores(secondary_abundance_ord_k4, 'species'))
secondary_ab_trait_scores$species = rownames(secondary_ab_trait_scores)
secondary_ab_trait_scores$species[6] = 'life history'
secondary_ab_trait_scores$species[8] = 'resource acquisition'
str(secondary_ab_scores)

########### Get Hulls

secondary_ab_scores$Ecosystem = 
  as.factor(secondary_ab_scores$Ecosystem)
secondary_ab_scores$GlobalChangeCat = 
  as.factor(secondary_ab_scores$GlobalChangeCat)
secondary_ab_scores$Taxonomic = 
  as.factor(secondary_ab_scores$Taxonomic)
secondary_ab_scores$TOS = 
  as.factor(secondary_ab_scores$TOS)
secondary_ab_scores$Filter = 
  as.factor(secondary_ab_scores$Filter)
secondary_ab_scores$GlobalChange = 
  as.factor(secondary_ab_scores$GlobalChange)
secondary_ab_scores$PredictiveCat = 
  as.factor(secondary_ab_scores$PredictiveCat)

#ecosystem
eco = as.character(unique(secondary_ab_scores$Ecosystem))
for(i in 1:length(eco)) {
  temp = eco[i]
  df = secondary_ab_scores[
    secondary_ab_scores$Ecosystem == temp, 
  ][chull(secondary_ab_scores[
    secondary_ab_scores$Ecosystem == temp,
    c("NMDS1", "NMDS2")
  ]), ]
  assign(paste0('grp_sec_ab_eco_',temp), df)
}
hull_sec_ab_ecosystem = rbind(grp_sec_ab_eco_Terrestrial, grp_sec_ab_eco_Freshwater, 
                              grp_sec_ab_eco_Marine, grp_sec_ab_eco_Multiple)

#taxonomic
tax = as.character(unique(secondary_ab_scores$Taxonomic))
for(i in 1:length(tax)) {
  temp = tax[i]
  df = secondary_ab_scores[
    secondary_ab_scores$Taxonomic == temp, 
  ][chull(secondary_ab_scores[
    secondary_ab_scores$Taxonomic == temp,
    c("NMDS1", "NMDS2")
  ]), ]
  assign(paste0('grp_sec_ab_tax_',temp), df)
}
hull_sec_ab_taxonomic = rbind(grp_sec_ab_tax_Birds, grp_sec_ab_tax_Insects, 
                              grp_sec_ab_tax_Mammals, grp_sec_ab_tax_Multiple, 
                              grp_sec_ab_tax_Herpetofauna, grp_sec_ab_tax_Plants,
                              grp_sec_ab_tax_Plankton, grp_sec_ab_tax_Other, 
                              grp_sec_ab_tax_Fish)

#taxonomic group
#first make new classifications 
secondary_ab_scores = secondary_ab_scores %>% 
  mutate(TaxonomicGroup = 
           ifelse(secondary_ab_scores$Taxonomic %in% 
                    c('Mammals', 'Birds', 'Herpetofauna', 'Fish'), 'Vertebrates', 
                  ifelse(secondary_ab_scores$Taxonomic %in%
                           c('Insects', 'Plankton'), 'Invertebrates', 
                         ifelse(secondary_ab_scores$Taxonomic == 'Other', 'Other',
                                ifelse(secondary_ab_scores$Taxonomic == 'Multiple', 'Multiple',
                                       ifelse(secondary_ab_scores$Taxonomic == 'Plants', 'Plants', NA))))))
#now put them in the normal loop
tax_group = as.character(unique(secondary_ab_scores$TaxonomicGroup))
for(i in 1:length(tax_group)) {
  temp = tax_group[i]
  df = secondary_ab_scores[
    secondary_ab_scores$TaxonomicGroup == temp, 
  ][chull(secondary_ab_scores[
    secondary_ab_scores$TaxonomicGroup == temp,
    c("NMDS1", "NMDS2")
  ]), ]
  assign(paste0('grp_sec_ab_taxgroup_',temp), df)
}
hull_sec_ab_taxonomic_group = rbind(grp_sec_ab_taxgroup_Invertebrates, 
                                    grp_sec_ab_taxgroup_Multiple,
                                    grp_sec_ab_taxgroup_Other, 
                                    grp_sec_ab_taxgroup_Plants,
                                    grp_sec_ab_taxgroup_Vertebrates)

#TOS
levels(secondary_ab_scores$TOS)[levels(secondary_ab_scores$TOS)==
                                  'TModel']='Theory'
levels(secondary_ab_scores$TOS)[levels(secondary_ab_scores$TOS)==
                                  'QModel']='Observational'
tos = as.character(unique(secondary_ab_scores$TOS))
for(i in 1:length(tos)) {
  temp = tos[i]
  df = secondary_ab_scores[
    secondary_ab_scores$TOS == temp, 
  ][chull(secondary_ab_scores[
    secondary_ab_scores$TOS == temp,
    c("NMDS1", "NMDS2")
  ]), ]
  assign(paste0('grp_sec_ab_tos_',temp), df)
}
hull_sec_ab_tos = rbind(grp_sec_ab_tos_Observational, grp_sec_ab_tos_Experiment, 
                        grp_sec_ab_tos_Metanalysis, grp_sec_ab_tos_Theory, 
                        grp_sec_ab_tos_Review)

#Filter
levels(secondary_ab_scores$Filter)[levels(secondary_ab_scores$Filter)==
                                     "Fundamental"] <- "Abiotic"
levels(secondary_ab_scores$Filter)[levels(secondary_ab_scores$Filter)==
                                     "Physical"] <- "Dispersal"
levels(secondary_ab_scores$Filter)[levels(secondary_ab_scores$Filter)==
                                     "Ecological"] <- "Biotic"
fil = as.character(unique(secondary_ab_scores$Filter))
for(i in 1:length(fil)) {
  temp = fil[i]
  df = secondary_ab_scores[
    secondary_ab_scores$Filter == temp, 
  ][chull(secondary_ab_scores[
    secondary_ab_scores$Filter == temp,
    c("NMDS1", "NMDS2")
  ]), ]
  assign(paste0('grp_sec_ab_fil_',temp), df)
}
hull_sec_ab_fil = rbind(grp_sec_ab_fil_Abiotic, grp_sec_ab_fil_Biotic,
                        grp_sec_ab_fil_Dispersal, grp_sec_ab_fil_Trophic)

#global change category
levels(secondary_ab_scores$GlobalChange)[levels(secondary_ab_scores$GlobalChange)==
                                           0] <- "Not Assessed"
levels(secondary_ab_scores$GlobalChange)[levels(secondary_ab_scores$GlobalChange)==
                                         'Global Change Broad'] <- "Multiple"
levels(secondary_ab_scores$GlobalChange)[levels(secondary_ab_scores$GlobalChange)==
                                         'Global Change Multiple'] <- "Multiple"
gc = as.character(unique(secondary_ab_scores$GlobalChange))
for(i in 1:length(gc)) {
  temp = gc[i]
  df = secondary_ab_scores[
    secondary_ab_scores$GlobalChange == temp, 
  ][chull(secondary_ab_scores[
    secondary_ab_scores$GlobalChange == temp,
    c("NMDS1", "NMDS2")
  ]), ]
  assign(paste0('grp_sec_ab_gc_',temp), df)
}
hull_sec_ab_gc = rbind(`grp_sec_ab_gc_Climate Change`, grp_sec_ab_gc_Exploitation,
                       `grp_sec_ab_gc_Multiple`,
                       `grp_sec_ab_gc_Habitat Degredation`, grp_sec_ab_gc_Invasion,
                       `grp_sec_ab_gc_Not Assessed`)

#predictive category
pred = as.character(unique(secondary_ab_scores$PredictiveCat))
for(i in 1:length(pred)) {
  temp = pred[i]
  df = secondary_ab_scores[
    secondary_ab_scores$PredictiveCat == temp, 
  ][chull(secondary_ab_scores[
    secondary_ab_scores$PredictiveCat == temp,
    c("NMDS1", "NMDS2")
  ]), ]
  assign(paste0('grp_sec_ab_pred_',temp), df)
}
hull_sec_ab_pred = rbind(grp_sec_ab_pred_no, grp_sec_ab_pred_yes)

########### Make Plots

#ecosystem
secondary_ab_eco_plot <- ggplot() + 
  geom_polygon(data=hull_sec_ab_ecosystem, 
               aes(x=NMDS1,y=NMDS2, 
                   fill=Ecosystem, 
                   group=Ecosystem),alpha=0.30) + 
  geom_point(data=secondary_ab_scores, 
             aes(x=NMDS1,y=NMDS2, colour = Ecosystem), size=2) + 
  coord_equal() +
  theme_bw()  +
  theme(#axis.text.x = element_blank(),  
    #axis.text.y = element_blank(), 
    axis.ticks = element_blank(),  
    axis.title.x = element_text(size=18), 
    axis.title.y = element_text(size=18), 
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 18),
    panel.background = element_rect(fill = "white"), 
    panel.grid.major = element_blank(),  
    panel.grid.minor = element_blank(), 
    plot.background = element_blank()) +
  scale_fill_viridis(option = 'magma', discrete = TRUE, begin = 0.8, end = 0.2, 
                     name = "Ecosystem") +
  scale_colour_viridis(option = 'magma',discrete = TRUE, begin = 0.8, end = 0.2, 
                       name = "Ecosystem") 
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_eco_small.png'), 
       plot = secondary_ab_eco_plot, 
       width = 8, height = 8, dpi = 200)
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_eco_large.png'), 
       plot = secondary_ab_eco_plot, 
       width = 8, height = 8, dpi = 1200)

#tax group
secondary_ab_tax_plot <- ggplot() + 
  geom_polygon(data=hull_sec_ab_taxonomic_group, 
               aes(x=NMDS1,y=NMDS2, 
                   fill=TaxonomicGroup, 
                   group=TaxonomicGroup),alpha=0.30) + 
  geom_point(data=secondary_ab_scores, 
             aes(x=NMDS1,y=NMDS2, colour = TaxonomicGroup), size=2) + 
  coord_equal() +
  theme_bw()  +
  theme(axis.text.x = element_blank(),  
        axis.text.y = element_blank(), 
        axis.ticks = element_blank(),  
        axis.title.x = element_text(size=18), 
        axis.title.y = element_text(size=18), 
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        panel.background = element_rect(fill = "white"), 
        panel.grid.major = element_blank(),  
        panel.grid.minor = element_blank(), 
        plot.background = element_blank()) +
  scale_fill_viridis(option = 'magma', discrete = TRUE, begin = 0.8, end = 0.2, 
                     name = "Taxa") +
  scale_colour_viridis(option = 'magma',discrete = TRUE, begin = 0.8, end = 0.2, 
                       name = "Taxa")
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_tax_small.png'), 
       plot = secondary_ab_tax_plot, 
       width = 8, height = 8, dpi = 200)
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_tax_large.png'), 
       plot = secondary_ab_tax_plot, 
       width = 8, height = 8, dpi = 1200)

#TOS
secondary_ab_tos_plot <- ggplot() + 
  geom_polygon(data=hull_sec_ab_tos, 
               aes(x=NMDS1,y=NMDS2, 
                   fill=TOS, 
                   group=TOS),alpha=0.30) + 
  geom_point(data=secondary_ab_scores, 
             aes(x=NMDS1,y=NMDS2, colour = TOS), size=2) + 
  coord_equal() +
  theme_bw()  +
  theme(axis.text.x = element_blank(),  
        axis.text.y = element_blank(), 
        axis.ticks = element_blank(),  
        axis.title.x = element_text(size=18), 
        axis.title.y = element_text(size=18), 
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        panel.background = element_rect(fill = "white"), 
        panel.grid.major = element_blank(),  
        panel.grid.minor = element_blank(), 
        plot.background = element_blank()) +
  scale_fill_viridis(option = 'magma', discrete = TRUE, begin = 0.8, end = 0.2, 
                     name = "Study Type") +
  scale_colour_viridis(option = 'magma',discrete = TRUE, begin = 0.8, end = 0.2, 
                       name = "Study Type")
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_tos_small.png'), 
       plot = secondary_ab_tos_plot, 
       width = 8, height = 8, dpi = 200)
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_tos_large.png'), 
       plot = secondary_ab_tos_plot, 
       width = 8, height = 8, dpi = 1200)

#filter
secondary_ab_fil_plot <- ggplot() + 
  geom_polygon(data=hull_sec_ab_fil, 
               aes(x=NMDS1,y=NMDS2, 
                   fill=Filter, 
                   group=Filter),alpha=0.30) + 
  geom_point(data=secondary_ab_scores, 
             aes(x=NMDS1,y=NMDS2, colour = Filter), size=2) + 
  coord_equal() +
  theme_bw()  +
  theme(axis.text.x = element_blank(),  
        axis.text.y = element_blank(), 
        axis.ticks = element_blank(),  
        axis.title.x = element_text(size=18), 
        axis.title.y = element_text(size=18), 
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        panel.background = element_rect(fill = "white"), 
        panel.grid.major = element_blank(),  
        panel.grid.minor = element_blank(), 
        plot.background = element_blank()) +
  scale_fill_viridis(option = 'magma', discrete = TRUE, begin = 0.8, end = 0.2, 
                     name = "Filter") +
  scale_colour_viridis(option = 'magma',discrete = TRUE, begin = 0.8, end = 0.2, 
                       name = "Filter")
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_fil_small.png'), 
       plot = secondary_ab_fil_plot, 
       width = 8, height = 8, dpi = 200)
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_fil_large.png'), 
       plot = secondary_ab_fil_plot, 
       width = 8, height = 8, dpi = 1200)

#global change
secondary_ab_gc_plot <- ggplot() + 
  geom_polygon(data=hull_sec_ab_gc, 
               aes(x=NMDS1,y=NMDS2, 
                   fill=GlobalChange, 
                   group=GlobalChange), alpha=0.30) + 
  geom_point(data=secondary_ab_scores, 
             aes(x=NMDS1,y=NMDS2, colour = GlobalChange), size=2) + 
  coord_equal() +
  theme_bw()  +
  theme(axis.text.x = element_blank(),  
        axis.text.y = element_blank(), 
        axis.ticks = element_blank(),  
        axis.title.x = element_text(size=18), 
        axis.title.y = element_text(size=18), 
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        panel.background = element_rect(fill = "white"), 
        panel.grid.major = element_blank(),  
        panel.grid.minor = element_blank(), 
        plot.background = element_blank()) +
  scale_fill_viridis(option = 'magma', discrete = TRUE, begin = 0.8, end = 0.2, 
                     name = "Global Change Driver") +
  scale_colour_viridis(option = 'magma',discrete = TRUE, begin = 0.8, end = 0.2, 
                       name = "Global Change Driver")
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_gc_small.png'), 
       plot = secondary_ab_gc_plot, 
       width = 8, height = 8, dpi = 200)
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_gc_large.png'), 
       plot = secondary_ab_gc_plot, 
       width = 8, height = 8, dpi = 1200)

#predictive
secondary_ab_pred_plot <- ggplot() + 
  geom_polygon(data=hull_sec_ab_pred, 
               aes(x=NMDS1,y=NMDS2, 
                   fill=PredictiveCat, 
                   group=PredictiveCat), alpha=0.30) + 
  geom_point(data=secondary_ab_scores, 
             aes(x=NMDS1,y=NMDS2, colour = PredictiveCat), size=2) + 
  coord_equal() +
  theme_bw()  +
  theme(axis.text.x = element_blank(),  
        axis.text.y = element_blank(), 
        axis.ticks = element_blank(),  
        axis.title.x = element_text(size=18), 
        axis.title.y = element_text(size=18), 
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 18),
        panel.background = element_rect(fill = "white"), 
        panel.grid.major = element_blank(),  
        panel.grid.minor = element_blank(), 
        plot.background = element_blank()) +
  scale_fill_viridis(option = 'magma', discrete = TRUE, begin = 0.8, end = 0.2, 
                     name = "Predictive") +
  scale_colour_viridis(option = 'magma',discrete = TRUE, begin = 0.8, end = 0.2, 
                       name = "Predictive")
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_pred_small.png'), 
       plot = secondary_ab_pred_plot, 
       width = 8, height = 9, dpi = 200)
ggsave(here('./Figures/Secondary_abundance/secondary_ab_plot_pred_large.png'), 
       plot = secondary_ab_pred_plot, 
       width = 8, height = 9, dpi = 1200)


## Merge plots

## We need to save the ordinations so I don't have to rerun them for this task

#All 6 panels

review_nMDS_secondary_ab6 = 
  plot_grid(secondary_ab_tax_plot, secondary_ab_tos_plot, secondary_ab_eco_plot,
            secondary_ab_fil_plot, secondary_ab_gc_plot, secondary_ab_pred_plot,
            labels = c("A", "B", "C", "D", "E", "F"), 
            label_x = 0.12, vjust = 3.5, ncol = 2, 
            rel_widths = c(1, 1), align = "v")

ggsave(here('./Figures/Secondary_abundance/review_nMDS_secondary_ab6_small.png'), 
       plot = review_nMDS_secondary_ab6,
       width = 15, height = 12, dpi = 200)
ggsave(here('./Figures/Secondary_abundance/review_nMDS_secondary_ab6_large.png'), 
       plot = review_nMDS_secondary_ab6,
       width = 15, height = 12, dpi = 1200)



