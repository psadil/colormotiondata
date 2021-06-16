prep_data <- function(file){
  qs::qread(file)  |>
    dplyr::filter(correct) |>
    dplyr::group_by(date, color, task, period, region, electrode, unit, id) |>
    dplyr::summarise(
      firing_rate = mean(firing_rate),
      .groups = "drop") |>
    tidyr::pivot_wider(names_from = task, values_from = firing_rate, names_prefix = "task_") |>
    dplyr::filter(!is.na(task_color), !is.na(task_motion)) |>
    dplyr::mutate(color = factor(color)) |>
    # dplyr::group_nest(id) |>
    # dplyr::slice_head(n = 100) |>
    # dplyr::mutate(id = forcats::fct_drop(id)) |>
    # tidyr::unnest(data) |>
    dplyr::filter(period == "cueL") |>
    dplyr::select(id, color, task_color, task_motion) |>
    dplyr::mutate(
      task_color = task_color / 10,
      task_motion = task_motion / 10)
}

sample_and_prep_for_save <- function(model){
  fit <- model$sample(
    chains = 4,
    parallel_chains = 2,
    seed = 1,
    iter_sampling = 1000,
    iter_warmup = 1000,
    adapt_delta = 0.9)
  fit$draws()
  fit$sampler_diagnostics()
  fit
}
