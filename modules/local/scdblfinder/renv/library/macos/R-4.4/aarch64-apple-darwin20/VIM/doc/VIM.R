## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5,
  fig.align = "center"
)

## ----setup, message=FALSE, fig.height = 3-------------------------------------
library(VIM)
data(sleep)
a <- aggr(sleep, plot = FALSE)
plot(a, numbers = TRUE, prop = FALSE)

## -----------------------------------------------------------------------------
x <- sleep[, c("Dream", "Sleep")]
marginplot(x)

## -----------------------------------------------------------------------------
x_imputed <- kNN(x)

## -----------------------------------------------------------------------------
marginplot(x_imputed, delimiter = "_imp")

