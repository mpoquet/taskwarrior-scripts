#!/usr/bin/env nix-shell
#!nix-shell -i Rscript -A rEnv
library(docopt)
library(tidyverse)
library(viridis)
library(ggrepel)

'Draw a Gantt chart.

Usage:
  draw_gantt.R [options]

Options:
  --help                Show this screen.
  -o, --output <file>   Output Gantt image file.
  -i, --input <file>    Input CSV file. If unset, stdin is read instead.
  -p, --prefix <pre>    Only show tags starting with <pre>.
  -w, --width <value>   Output image width. [default: 16]
  -h, --height <value>  Output image height. [default: 9]
  -c, --color <column>  Color column (or NULL). [default: task_project]
  --no-legend           If set, always hide legend.
  --no-label            If set, disable task description labels.
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
    task_uuid="unknown"
))

plot_df = df %>% mutate(begin_y=0, end_y=1)
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
    plot = plot + guides(fill=FALSE, color=FALSE)
}

# Write output image.
width = as.numeric(args$'--width')
height = as.numeric(args$'--height')
if (is.null(args$'--output')) {
    stop("Writing the generated image to stdout is not implemented yet.")
} else {
    ggsave(args$'--output', plot=plot, width=width, height=height)
}
