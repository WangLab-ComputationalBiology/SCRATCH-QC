## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.dev = "grDevices::png",
  dpi = 96L,
  dev.args = list(),
  fig.ext = "png",
  fig.width = 700 / 96,
  fig.height = NULL,
  fig.retina = 2L,
  fig.asp = 1 / 1.618,
  fig.align = "center"
)

## ----eval=FALSE---------------------------------------------------------------
#  install.packages("ggwordcloud")

## ----eval=FALSE---------------------------------------------------------------
#  devtools::install_github("lepennec/ggwordcloud")

## -----------------------------------------------------------------------------
library(ggwordcloud)
data("love_words_small")
data("love_words")

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word)) +
  geom_text_wordcloud() +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(43)
ggplot(love_words_small, aes(label = word)) +
  geom_text_wordcloud() +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud() +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud() +
  scale_size_area(max_size = 30) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud() +
  scale_radius(range = c(0, 30), limits = c(0, NA)) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud(area_corr = TRUE) +
  scale_size_area(max_size = 50) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 50) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 50, trans = power_trans(1/.7)) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 80) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area(rm_outside = TRUE) +
  scale_size_area(max_size = 80) +
  theme_minimal()

## -----------------------------------------------------------------------------
library(dplyr, quietly = TRUE)
love_words_small <- love_words_small %>%
  mutate(angle = 90 * sample(c(0, 1), n(), replace = TRUE, prob = c(60, 40)))

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(
  label = word, size = speakers,
  angle = angle
)) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 40) +
  theme_minimal()

## -----------------------------------------------------------------------------
love_words_small <- love_words_small %>%
  mutate(angle = 45 * sample(-2:2, n(), replace = TRUE, prob = c(1, 1, 4, 1, 1)))

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(
  label = word, size = speakers,
  angle = angle
)) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 40) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 40) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area(eccentricity = 1) +
  scale_size_area(max_size = 40) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area(eccentricity = .35) +
  scale_size_area(max_size = 40) +
  theme_minimal()

## -----------------------------------------------------------------------------
for (shape in c(
  "circle", "cardioid", "diamond",
  "square", "triangle-forward", "triangle-upright",
  "pentagon", "star"
)) {
  set.seed(42)
  print(ggplot(love_words_small, aes(label = word, size = speakers)) +
    geom_text_wordcloud_area(shape = shape) +
    scale_size_area(max_size = 40) +
    theme_minimal() + ggtitle(shape))
}

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(
  love_words_small,
  aes(
    label = word, size = speakers,
    color = factor(sample.int(10, nrow(love_words_small), replace = TRUE)),
    angle = angle
  )
) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 40) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(
  love_words_small,
  aes(
    label = word, size = speakers,
    color = speakers, angle = angle
  )
) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 40) +
  theme_minimal() +
  scale_color_gradient(low = "darkred", high = "red")

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers)) +
  geom_text_wordcloud_area(
    mask = png::readPNG(system.file("extdata/hearth.png",
      package = "ggwordcloud", mustWork = TRUE
    )),
    rm_outside = TRUE
  ) +
  scale_size_area(max_size = 42) +
  theme_minimal()

## -----------------------------------------------------------------------------
love_words <- love_words %>%
  mutate(angle = 45 * sample(-2:2, n(), replace = TRUE, prob = c(1, 1, 4, 1, 1)))

## ----warning=FALSE------------------------------------------------------------
set.seed(42)
ggplot(
  love_words,
  aes(
    label = word, size = speakers,
    color = speakers, angle = angle
  )
) +
  geom_text_wordcloud_area(
    mask = png::readPNG(system.file("extdata/hearth.png",
      package = "ggwordcloud", mustWork = TRUE
    )),
    rm_outside = TRUE
  ) +
  scale_size_area(max_size = 40) +
  theme_minimal() +
  scale_color_gradient(low = "darkred", high = "red")

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers,
                             label_content = sprintf("%s (%g)", word, speakers))) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 30) +
  theme_minimal()

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(love_words_small, aes(label = word, size = speakers,
                             label_content = sprintf("%s<span style='font-size:7.5pt'>(%g)</span>", word, speakers))) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 40) +
  theme_minimal()

## -----------------------------------------------------------------------------
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(tidyr, quietly = TRUE)
love_words_small_l <- love_words_small %>%
  gather(key = "type", value = "speakers", -name, -word, -angle, -iso_639_3) %>%
  arrange(desc(speakers))

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(
  love_words_small_l,
  aes(label = word, size = speakers)
) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 30) +
  theme_minimal() +
  facet_wrap(~type)

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(
  love_words_small_l,
  aes(
    label = word, size = speakers,
    x = type, color = type
  )
) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 30) +
  scale_x_discrete(breaks = NULL) +
  theme_minimal()

## -----------------------------------------------------------------------------
love_words_small_l <- love_words_small_l %>%
  group_by(type) %>%
  mutate(prop = speakers / sum(speakers)) %>%
  group_by(name, word) %>%
  mutate(propdelta = (prop - mean(prop)) / sqrt(mean(prop)))

## -----------------------------------------------------------------------------
set.seed(42)
ggplot(
  love_words_small_l,
  aes(
    label = word, size = abs(propdelta),
    color = propdelta < 0, angle_group = propdelta < 0
  )
) +
  geom_text_wordcloud_area() +
  scale_size_area(max_size = 30) +
  theme_minimal() +
  facet_wrap(~type)

## -----------------------------------------------------------------------------
set.seed(42)
ggwordcloud(love_words_small$word, love_words_small$speakers)

## -----------------------------------------------------------------------------
set.seed(42)
ggwordcloud2(love_words_small[, c("word", "speakers")], size = 2.5)

