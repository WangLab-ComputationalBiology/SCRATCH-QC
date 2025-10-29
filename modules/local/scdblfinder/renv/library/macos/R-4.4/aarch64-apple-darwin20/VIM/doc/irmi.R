## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 6,
  fig.align = "center"
)

## ----setup, message=F---------------------------------------------------------
library(VIM)
library(magrittr)
dataset <- sleep[, c("Dream", "NonD", "BodyWgt", "Span")]
dataset$BodyWgt <- log(dataset$BodyWgt)
dataset$Span <- log(dataset$Span)
aggr(dataset)

## -----------------------------------------------------------------------------
sapply(dataset, function(x) sum(is.na(x)))

## -----------------------------------------------------------------------------
imp_irmi <- irmi(dataset)
aggr(imp_irmi, delimiter = "_imp")

## ---- fig.height=5------------------------------------------------------------
imp_irmi[, c("NonD", "BodyWgt", "NonD_imp")] %>% 
  marginplot(delimiter = "_imp")

## ---- fig.height=5------------------------------------------------------------
imp_irmi[, c("Span", "BodyWgt", "Span_imp")] %>% 
  marginplot(delimiter = "_imp")

## -----------------------------------------------------------------------------
data(iris)
df <- iris
colnames(df) <- c("S.Length", "S.Width", "P.Length", "P.Width", "Species")
# randomly produce some missing values in the data
set.seed(1)
nbr_missing <- 50
y <- data.frame(row = sample(nrow(iris), size = nbr_missing, replace = TRUE),
                col = sample(ncol(iris), size = nbr_missing, replace = TRUE))
y <- y[!duplicated(y), ]
df[as.matrix(y)] <- NA

aggr(df)
sapply(df, function(x) sum(is.na(x)))

## -----------------------------------------------------------------------------
imp_irmi <- irmi(df)
aggr(imp_irmi, delimiter = "imp")

## ----echo=F,warning=F---------------------------------------------------------
library(reactable)

results <- cbind("TRUE1" = as.numeric(iris[as.matrix(y[which(y$col==1),])]),
                 "IMPUTED1" = round(as.numeric(imp_irmi[as.matrix(y[which(y$col==1),])]),2),
                 "TRUE2" = as.numeric(iris[as.matrix(y[which(y$col==2),])]),
                 "IMPUTED2" = round(as.numeric(imp_irmi[as.matrix(y[which(y$col==2),])]),2),
                 "TRUE3" = as.numeric(iris[as.matrix(y[which(y$col==3),])]),
                 "IMPUTED3" = round(as.numeric(imp_irmi[as.matrix(y[which(y$col==3),])]),2),
                 "TRUE4" = as.numeric(iris[as.matrix(y[which(y$col==4),])]),
                 "IMPUTED4" = round(as.numeric(imp_irmi[as.matrix(y[which(y$col==4),])]),2),
                 "TRUE5" = (iris[as.matrix(y[which(y$col==5),])]),
                 "IMPUTED5" = (imp_irmi[as.matrix(y[which(y$col==5),])]))[1:5,]

reactable(results, columns = list(
    TRUE1 = colDef(name = "True"),
    IMPUTED1 = colDef(name = "Imputed"),
    TRUE2 = colDef(name = "True"),
    IMPUTED2 = colDef(name = "Imputed"),
    TRUE3 = colDef(name = "True"),
    IMPUTED3 = colDef(name = "Imputed"),
    TRUE4 = colDef(name = "True"),
    IMPUTED4 = colDef(name = "Imputed"),
    TRUE5 = colDef(name = "True"),
    IMPUTED5 = colDef(name = "Imputed")
  ),
    columnGroups = list(
    colGroup(name = "S.Length", columns = c("TRUE1", "IMPUTED1")),
    colGroup(name = "S.Width", columns = c("TRUE2", "IMPUTED2")),
    colGroup(name = "P.Length", columns = c("TRUE3", "IMPUTED3")),
    colGroup(name = "P.Width", columns = c("TRUE4", "IMPUTED4")),
    colGroup(name = "Species", columns = c("TRUE5", "IMPUTED5"))
  ),
  striped = TRUE,
  highlight = TRUE,
  bordered = TRUE
)


