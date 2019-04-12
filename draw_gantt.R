#!/usr/bin/env Rscript
library(docopt)
library(tidyverse)
library(viridis)

'Draw a Gantt chart.

Usage:
  draw_gantt.R [options]

Options:
  --help             Show this screen.
  -o, --output <file>   Output Gantt image file.
  -i, --input <file>    Input CSV file. If unset, stdin is read instead.
  -p, --prefix <pre>    Only show tags starting with <pre>.
  -w, --width <value>   Output image width. [default: 6]
  -h, --height <value>  Output image height. [default: 4]
' -> doc

args <- docopt(doc)
print(args)

# Read data from CSV, either from stdin or from a given input file.
df = NULL
if (is.null(args$'--input')) {
    df = read_csv(file("stdin"))
} else {
    df = read_csv(args$'--input')
}

# Associate unique numbers to tags
tag_id_mapping = df %>%
    distinct(tag) %>%
    mutate(tag_id=row_number(),
           tag_id_center=tag_id + 0.5,
           color_id=as.integer(row_number() %% 7))

plot_df = inner_join(df, tag_id_mapping) %>%
    mutate(begin_y = as.double(tag_id), end_y = tag_id + 0.9)

plot = plot_df %>% ggplot() +
    geom_rect(aes(xmin=start, xmax=end,
                  ymin=begin_y, ymax=end_y,
                  fill=color_id
    )) +
    theme_bw() +
    theme(panel.border = element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_line(colour = "black")
    ) +
    guides(fill=FALSE) +
    scale_fill_viridis() +
    scale_y_continuous(breaks=tag_id_mapping$'tag_id_center',
                       labels=tag_id_mapping$'tag')

# Write output image.
width = as.numeric(args$'--width')
height = as.numeric(args$'--height')
print(width)
print(height)
if (is.null(args$'--output')) {
    plot
    #ggsave(stdout(), plot=plot, device="png", width=width, height=height)
} else {
    ggsave(args$'--output', plot=plot, width=width, height=height)
}
