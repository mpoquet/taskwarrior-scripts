#!/usr/bin/env nix-shell
#!nix-shell -i Rscript -A rEnv
library(docopt)
library(tidyverse)
library(viridis)
library(ggrepel)
library(lubridate)

'Draw a Gantt chart.

Usage:
  draw_gantt.R [options]

Options:
  --help                Show this screen.
  -o, --output <file>   Output Gantt image file.
  -i, --input <file>    Input CSV file. If unset, stdin is read instead.
  -w, --width <value>   Output image width. [default: 16]
  -h, --height <value>  Output image height. [default: 9]
  -c, --color <column>  Color column (or NULL). [default: task_project]
  --no-legend           If set, always hide legend.
  --no-label            If set, disable task description labels.
  --by-day              If set, display and split intervals by day.
' -> doc

args <- docopt(doc)
#print(args)

# Read data from CSV, either from stdin or from a given input file.
df = NULL
if (is.null(args$'--input')) {
    df = read_csv(file("stdin"))
} else {
    df = read_csv(args$'--input')
}

# Rename NA for unknown values.
df = df %>% replace_na(list(
    task_tags="unknown",
    task_project="unknown",
    task_status="unknown",
    task_uuid="unknown",
    timew_interval_end=now()
))

# Remove invalid intervals (just in case).
df = df %>%
    filter(timew_interval_start < timew_interval_end) %>% # positive intervals
    distinct(timew_interval_start, .keep_all=TRUE)

magic_monoday = NULL
if (args$'--by-day') {
    # Split datetimes into date and times.
    df = df %>% mutate(
        timew_interval_start_date=as_date(timew_interval_start),
        timew_interval_end_date=as_date(timew_interval_end),
        timew_interval_start_hms=hms::as.hms(timew_interval_start),
        timew_interval_end_hms=hms::as.hms(timew_interval_end)
    )

    # Splits an interval into several that do not breaks daily boundaries.
    # Result is stored as a string.
    # - Intervals are separated by "--".
    # - Each interval is "BEGIN_END", where BEGIN and END are datetimes.
    make_daily_intervals <- function(start_date, end_date) {
        curr_interval_start = start_date
        curr_interval_end = ceiling_date(start_date, unit="days", change_on_boundary=TRUE) - seconds(1)
        daily_df = tibble(start=curr_interval_start, end=curr_interval_end)

        while (as_date(curr_interval_start) < as_date(end_date)) {
            curr_interval_start = curr_interval_end + seconds(1)
            curr_interval_end = min(end_date, ceiling_date(curr_interval_start, unit="days", change_on_boundary=TRUE) - seconds(1))
            daily_df = daily_df %>% add_row(start=curr_interval_start, end=curr_interval_end)
        }

        daily_df = daily_df %>% mutate(interval=paste(start, '_', end, sep=''))
        return(paste(daily_df$interval, collapse='--'))
    }

    monoday = df %>% filter(timew_interval_start_date == timew_interval_end_date)
    multiday = df %>%
        filter(timew_interval_start_date < timew_interval_end_date) %>% # only keep intervals spanning on multiple days
        rowwise() %>% mutate(daily_intervals=make_daily_intervals(timew_interval_start, timew_interval_end)) %>% # compute a string representation of the interval split so intervals never cross the 00:00:00 boundary
        separate_rows(daily_intervals, sep='--') %>% # create a row for each required interval
        rowwise() %>% mutate(timew_interval_start=as_datetime(strsplit(daily_intervals, "_")[[1]][1]),     # update new_start and new_end as computed before.
                             timew_interval_end = as_datetime(strsplit(daily_intervals, "_")[[1]][2])) %>% # in python, this would be daily_intervals.split('_')[0] and daily_intervals.split('_')[1]
        select(-daily_intervals) %>% # remove temporary garbage
        mutate( # update date/times that became invalid because of the split
            timew_interval_start_date=as_date(timew_interval_start),
            timew_interval_end_date=as_date(timew_interval_end),
            timew_interval_start_hms=hms::as.hms(timew_interval_start),
            timew_interval_end_hms=hms::as.hms(timew_interval_end)
        )
    magic_monoday = bind_rows(monoday, multiday)
} else {
    magic_monoday = df
}

plot_df = magic_monoday %>% mutate(
    begin_y=0,
    end_y=1,
)
color_column = args$'--color'

# Generate the desired plot.
plot = plot_df %>% ggplot() +
    geom_rect(aes_string(fill=color_column,
                         xmin="timew_interval_start", xmax="timew_interval_end",
                         ymin="begin_y", ymax="end_y"))

# Add a label on each task?
if (!args$'--no-label') {
    plot = plot +
        geom_label_repel(aes(x=timew_interval_start+(timew_interval_end-timew_interval_start)/2,
                             y=0.5,
                             label=task_description),
                             direction='y')
}

# Theme configuration.
plot = plot + theme_bw() +
    theme(panel.border = element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_line(colour = "black"),
          axis.text.y = element_blank(),
          axis.title.y = element_blank(),
          axis.ticks.y = element_blank()
    ) +
    scale_fill_viridis(discrete=TRUE) +
    xlab("Time")

# Remove legend?
if (args$'--no-legend') {
    plot = plot + guides(fill=FALSE)
}

# Write output image.
width = as.numeric(args$'--width')
height = as.numeric(args$'--height')
if (is.null(args$'--output')) {
    stop("Writing the generated image to stdout is not implemented yet.")
} else {
    ggsave(args$'--output', plot=plot, width=width, height=height)
}
