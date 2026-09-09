# load library
library(tidyverse)
library(ggpattern)

# load data
raw_menu <- read_csv("data/dinner_jan26_may14.csv")

# most popular single meal
most_popular <- raw_menu |> 
  group_by(item_name) |> 
  summarize(total = n()) |> 
  arrange(desc(total)) |> 
  slice(1) |>
  pull(item_name)

# search item_name to tag main ingredient
# group into categories
# order is hierarchical (helps with sausage vs fake sausage, diff kinds of tempeh)
menu <- raw_menu %>%
  mutate(main_ingredient = case_when(
    str_detect(item_name, regex("Beyond|Gardein|Chik|Impossible", ignore_case = TRUE)) ~ "Meat Substitute",
    str_detect(item_name, regex("Chicken|Pollo", ignore_case = TRUE)) ~ "Chicken",
    str_detect(item_name, regex("Beef|Steak|Brisket|Tri-Tip", ignore_case = TRUE)) ~ "Beef",
    str_detect(item_name, regex("Pork|Sausage|Bratwurst", ignore_case = TRUE)) ~ "Pork",
    str_detect(item_name, regex("Turkey", ignore_case = TRUE)) ~ "Turkey",
    str_detect(item_name, regex("Fish|Salmon", ignore_case = TRUE)) ~ "Fish",
    str_detect(item_name, regex("Tofu", ignore_case = TRUE)) ~ "Tofu",
    str_detect(item_name, regex("Mushroom|Portobello", ignore_case = TRUE)) ~ "Mushroom",
    str_detect(item_name, regex("Tempeh", ignore_case = TRUE)) &
      str_detect(item_name, regex("Chickpea|Garbanzo", ignore_case = TRUE)) ~ "Chickpea",
    str_detect(item_name, regex("Tempeh", ignore_case = TRUE)) &
      !str_detect(item_name, regex("Lentil", ignore_case = TRUE))~ "Soy Tempeh",
    str_detect(item_name, regex("Chickpea|Garbanzo", ignore_case = TRUE)) ~ "Chickpea",
    str_detect(item_name, regex("Lentil", ignore_case = TRUE)) ~ "Lentil",
    str_detect(item_name, regex("Bean", ignore_case = TRUE)) ~ "Bean",
    # real dishes with other main ingredient 
    item_name %in% c(
      "Garlic Roasted Lamb",
      "Stuffed Peppers with Smashed Potatoes",
      "Eggplant Stew over Polenta",
      "Seared Yams over Polenta",
      "Vegetable Pozole",
      "Pozole Chile Verde"
    ) ~ "Other",
    TRUE ~ NA_character_
  )) %>%
  # drop things like ice cream desserts that aren't dinner
  filter(!is.na(main_ingredient)) 

# summarize and arrange by count
summary_menu <- menu |> 
  group_by(main_ingredient) |> 
  summarize(count = n()) |> 
  arrange(desc(count))
summary_menu


# add meat vs veggie
# other has lamb, so it's a combo of both
food_type <- c(
  "Chicken" = "Meat",
  "Beef" = "Meat",
  "Pork" = "Meat",
  "Turkey" = "Meat",
  "Fish" = "Meat",
  "Mushroom" = "Veggie",
  "Tofu" = "Veggie",
  "Meat Substitute" = "Veggie",
  "Soy Tempeh" = "Veggie",
  "Chickpea" = "Veggie",
  "Lentil" = "Veggie",
  "Bean" = "Veggie",
  "Other" = "Mixed"
)

summary_menu <- summary_menu |>
  mutate(food = food_type[main_ingredient],
         food_pattern = case_when(food == "Mixed" ~ "Y",
                                  TRUE ~ "N"))

# horizontal bar plot
ingredient_plot <- summary_menu |>
  ggplot(aes(x = reorder(main_ingredient, count), y = count, fill = food, pattern = food_pattern)) +
  geom_col_pattern(
    color = NA,
    pattern_fill = "black",
    pattern_color = NA,
    pattern_density = 0.3,
    pattern_spacing = 0.03,
    pattern_angle = 45
  ) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(
    values = c("Meat" = "gray25", "Veggie" = "gray65", "Mixed" = "gray65"),
    breaks = c("Meat", "Veggie", "Mixed"),
    name = NULL
  ) +
  scale_pattern_manual(values = c("N" = "none", "Y" = "stripe")) +
  guides(
    pattern = "none",
    # this forces only "Both" to look striped
    fill = guide_legend(override.aes = list(pattern = c("none", "none", "stripe")))
  ) +
  labs(
    x = NULL, y = "Number of Times Served",
    title = "What's for Dinner?") +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(face = "bold", size = 28, hjust = 0.5),
    plot.subtitle = element_text(size = 13, color = "black", margin = margin(b = 10), hjust = 0.5),
    axis.text.x = element_text(color = "black", size = 12),
    axis.text.y = element_text(color = "black", size = 12, margin = margin(r = 0)),
    axis.title.x = element_text(face = "bold", size = 14),
    legend.text = element_text(size = 14),
    legend.position = "top",
    panel.grid.minor.y = element_blank(),
    panel.grid.major.y = element_blank()
  )

ingredient_plot

# save image and a vector copy for print 
ggsave("ingredient_plot.png", ingredient_plot, width = 8, height = 6)
ggsave("ingredient_plot.svg", ingredient_plot, width = 8, height = 6)
