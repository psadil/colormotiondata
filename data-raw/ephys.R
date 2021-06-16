library(tidyverse)

csvs <- fs::dir_ls(here::here("data-raw"), regexp = "allTrialFR[.]csv$")

parse_filename <- function(d){
  d %>%
    mutate(
      date = fs::path_file(date),
      date = str_extract(date, "[[:digit:]]+"),
      date = clock::date_parse(date, format = "%y%m%d"))
}


parse_cell <- function(file){
  vroom::vroom(
    file,
    id = "date",
    n_max = 1) %>%
    select(-starts_with("..."), -contains("units")) %>%
    pivot_longer(
      matches("^(V4)|(MT)"),
      names_pattern = "(V4|MT)e([[:digit:]]+)_([[:digit:]]+)",
      names_to = c("region","electrode","unit"),
      names_transform = list(
        region = ~factor(.x, levels = c("V4", "MT")),
        electrode = as.integer,
        unit = as.integer)) %>%
    parse_filename() %>%
    mutate(
      id = interaction(region, electrode, unit, lex.order = TRUE, drop=TRUE),
      id = as.numeric(id)) %>%
    select(-value)
}

parse_rates <- function(file){
  vroom::vroom(
    file,
    skip=1,
    id="date") %>%
    pivot_longer(
      matches("fix|cueE|cueL|sample"),
      names_pattern = "(fix|cueE|cueL|sample)...([[:digit:]]+)",
      names_to = c("period", "id"),
      names_transform = list(id=as.integer, period=factor),
      values_to = "firing_rate") %>%
    mutate(
      id = id - 6,
      id = ceiling(id/4),
      monkey = if_else(str_detect(file, "110120|110121"), "Rex", "Paula")) %>%
    parse_filename()
}

ephys <- tibble(
  rates = map(csvs, parse_rates),
  cells = map(csvs, parse_cell)) %>%
  mutate(out = map2(rates, cells, left_join, by = c("date", "id"))) %>%
  select(out) %>%
  unnest(out) %>%
  filter(!is.na(firing_rate)) %>%
  mutate(
    correct = correct == 1,
    id = interaction(date, region, electrode, unit),
    electrode = factor(electrode),
    task = factor(task, levels = c("C", "M"), labels = c("color", "motion")),
    color = as.numeric(as.character(factor(color, labels=c("-90", "-30", "-5", "0", "5", "30", "90")))),
    motion = as.numeric(as.character(factor(motion, labels=c("-90", "-30", "-5", "0", "5", "30", "90")))),
    period = fct_relevel(period, "fix", "cueE", "cueL", "sample")) %>%
  rename(trial = trials)

qs::qsave(ephys, here::here("data-raw", "ephys.qs"))

# usethis::use_data(ephys, overwrite = TRUE)
