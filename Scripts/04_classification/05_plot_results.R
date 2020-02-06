source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/classification.R"))
library(ggplot2)
library(dplyr)
library(ggpubr)
setwd(Sys.getenv("PT_DIR"))

###################
# Theme for journal
speech_communication_theme = theme(
  legend.position = "none",
  plot.margin = unit(c(0, 0, -3, -3), "mm"),
  axis.text.x = element_text(size = 7, face = "plain"),
  axis.text.y = element_text(size = 7, face = "plain"),
  axis.title.x = element_text(color = "grey20", size = 8, face = "plain"),
  axis.title.y = element_text(color = "grey20", size = 8, face = "plain")
)

###############################################
# Create custom statistical significance labels
create_stat_labels = function(df, y = "sense_mean", x = "feature_set", group_by = NULL, overwrite_y.position = c(), comparisons = list(c("baseline", "both"))){
  form = as.formula(paste(y, "~", x))
  if (is.null(group_by)){
    stat.test = compare_means(
      form,
      data = df,
      method = "t.test",
      p.adjust.method = 'bonferroni'
    )
  } else {
    stat.test = compare_means(
      form,
      data = df,
      method = "t.test",
      p.adjust.method = 'bonferroni',
      group.by = group_by
    )
  }

  for (r in 1:nrow(stat.test)){
    if (is.null(group_by)){
      group1_mean = mean(filter(df, (!!sym(x)) == stat.test$group1[r])$sense_mean, na.rm = T)
      group2_mean = mean(filter(df, (!!sym(x)) == stat.test$group2[r])$sense_mean, na.rm = T)
    } else {
      group1_mean = mean(filter(df, (!!sym(x)) == stat.test$group1[r], (!!sym(group_by)) == stat.test[[r, group_by]])$sense_mean, na.rm = T)
      group2_mean = mean(filter(df, (!!sym(x)) == stat.test$group2[r], (!!sym(group_by)) == stat.test[[r, group_by]])$sense_mean, na.rm = T)
    }
    val = round((group2_mean - group1_mean)*100, 1)
    if (val < 0){
      label = ""
    } else {
      label = "+"
    }
    label = paste0(label, " ",  val, "% (", stat.test$p.signif[r], ")")
    stat.test$label[r] = label
    stat.test$y.position[r] = 1.02
  }

  if (length(comparisons) > 0){
    filtered_df = NULL
    for (c in comparisons){
      filtered_df = rbind(filtered_df, filter(stat.test, group1 == c[1], group2 == c[2]))
    }
    stat.test = filtered_df
  }

  if (length(overwrite_y.position) == nrow(stat.test)){
    stat.test$y.position = overwrite_y.position
  }

  return(ggpubr::stat_pvalue_manual(data = stat.test, label = "label", size = 2.5))
}

##############
# Scramble
results = read.csv(paste0(Sys.getenv("PT_DIR"), "Results/03_classification/PELL_SCRAMBLE_3.csv"))
results$dataset = stringr::str_replace(stringr::str_replace(results$dataset, "PELL_MAN", 'normal'), "PELL_SCRAM", 'scrambled')

ggboxplot(results, x = 'dataset', y = 'sense_mean') +
  create_stat_labels(results, x = 'dataset', group_by = "name", overwrite_y.position = c(0.86,  0.82, 0.73), comparisons =  list()) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks=seq(0,1,0.2)) +
  labs(
    x = "",
    y = "Averaged sensitivity across emotions"
  ) +
  facet_grid(~ name) +
  theme(
    strip.text.x = element_text(size = 8, face = "bold"),
    strip.background = element_rect(color = "white", fill = "white"),
  ) +
  geom_hline(aes(yintercept = 1/6), linetype = 2) +
  speech_communication_theme
ggsave('Manuscript/images/scramble.pdf', device = cairo_pdf, width = 16, height = 7, units = "cm")

####################
# First PELL manual
PELL_man_base_both = read.csv(paste0(Sys.getenv("PT_DIR"), "Results/03_classification/PELL_MAN_base_both.csv"))

# If you want to have human accuracy scores
# human_accs = rbind(
#   read.csv('/Users/pol.van-rijn/MPI/02_running_projects/02_PhD/Conferences/R3_december_2019_MPI/Web/RAVDESS_accuracies.csv') %>% mutate(corpus = "RAVDESS"),
#   read.csv('/Users/pol.van-rijn/MPI/02_running_projects/02_PhD/Conferences/R3_december_2019_MPI/Web/PELL_accuracies.csv')  %>% mutate(corpus = "PELL"),
#   read.csv('/Users/pol.van-rijn/MPI/02_running_projects/02_PhD/Conferences/R3_december_2019_MPI/Web/CREMA-D_accuracies.csv')  %>% mutate(corpus = "CREMA-D")
# )

break_at = 0.6
start_at = break_at - 0.05
breaks = c(start_at, seq(break_at,1,0.2))
labels = paste0(c(0, seq(break_at,1,0.2))*100, "%")

ggboxplot(PELL_man_base_both, x = "feature_set", y = "sense_mean") +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.1), breaks = seq(0,1,0.2)) +
  speech_communication_theme +
  labs(x = "", y = "", title = "PELL") +
  scale_y_continuous(labels = labels, limits = c(start_at + 0.02, 1.1), breaks = breaks) +
  theme(
    axis.line.y = element_blank(),
    plot.title = element_text(size = 9, face = "bold", color = '#312783', hjust = 0.5)
  ) +
  annotate(geom = "segment", x = -Inf, xend = -Inf, y = -Inf, yend = Inf, color = "black", lwd = 1)+
  annotate(geom = "segment", x = -Inf, xend = -Inf, y =  -Inf, yend = break_at, linetype = "dashed", color = "white", lwd = 1) +
  create_stat_labels(PELL_man_base_both)
ggsave('Manuscript/images/PELL_both_baseline.pdf', device = cairo_pdf, width = 7.5, height = 5, units = "cm")

######################################
# Uncorrected corpora results
both_all = read.csv(paste0(Sys.getenv("PT_DIR"), "Results/03_classification/both_all.csv"))
new_all = read.csv(paste0(Sys.getenv("PT_DIR"), "Results/03_classification/new_dynamic_all.csv"))
new_all$feature_set = "new"
baseline_all = filter(rbind(
  read.csv(paste0(Sys.getenv("PT_DIR"), "Results/03_classification/PELL_base_both.csv")),
  read.csv(paste0(Sys.getenv("PT_DIR"), "Results/03_classification/CREMA-D_base_both.csv")),
  read.csv(paste0(Sys.getenv("PT_DIR"), "Results/03_classification/RAVDESS_base_both.csv"))
), feature_set == "baseline")


library(ggpubr)
df = rbind(
  baseline_all,
  both_all,
  new_all
)

ggboxplot(df, x = 'feature_set', y = 'sense_mean') +
  create_stat_labels(df, group_by = "corpus", overwrite_y.position = c(1.05,  0.78, 0.76)) +
  facet_grid(~ corpus) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1.1), breaks=seq(0,1,0.2)) +
  labs(
    x = "",
    y = "Averaged sensitivity across emotions"
  ) +
  theme(
    strip.text.x = element_text(size = 9, face = "bold", color = "#312783"),
    strip.background = element_rect(color = "white", fill = "white"),
  ) +
  geom_hline(aes(yintercept = 1/6), linetype = 2) +
  speech_communication_theme
ggsave('Manuscript/images/baseline_vs_both.pdf', device = cairo_pdf, width = 16, height = 7, units = "cm")
