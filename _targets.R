library(targets)
library(stantargets)


source(here::here("R", "target-utils.R"))

# Set target-specific options such as packages.
tar_option_set(
  packages = "nmmr",
  format = "qs")

# End this file with a list of target objects.
list(
  tar_target(raw_data, here::here("data-raw", "ephys.qs"), format = "file"),
  tar_target(color, prep_data(raw_data)),
  tar_target(m, Deming$new(color, task_color, task_motion, tuning_var = color, id_var = id)),
  tar_target(
    m_prior,
    Deming$new(
      color,
      task_color, task_motion,
      tuning_var = color, id_var = id,
      prior = DemingPrior$new(prior_only = 1, sample_yrep = 1))),
  tar_target(ppc, m_prior$sample(chains=1)),
  tar_target(fit, sample_and_prep_for_save(m))
)



