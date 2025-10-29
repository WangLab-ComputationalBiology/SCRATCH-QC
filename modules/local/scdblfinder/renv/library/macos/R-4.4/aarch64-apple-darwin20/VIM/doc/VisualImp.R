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
dataset <- sleep[, c("Dream", "NonD", "BodyWgt", "Span")] # dataset with missings
dataset$BodyWgt <- log(dataset$BodyWgt)
dataset$Span <- log(dataset$Span)
imp_knn <- kNN(dataset) # dataset with imputed values

## -----------------------------------------------------------------------------
aggr(dataset) 
aggr(imp_knn, delimiter = "_imp") 

## -----------------------------------------------------------------------------
# for missing values
x <- sleep[, c("Exp", "NonD", "Sleep")]
barMiss(x, only.miss = FALSE)
# for imputed values
x_IMPUTED <- regressionImp(NonD ~ Sleep, data = x)
barMiss(x_IMPUTED, delimiter = "_imp", only.miss = FALSE)

## -----------------------------------------------------------------------------
dataset <- sleep[, c("Span", "NonD","Sleep")]
# for missing values
scattMiss(dataset[,-3])
# for imputed values
imp_regression <- regressionImp(NonD ~ Sleep, dataset)
scattMiss(imp_regression[,-3], delimiter = "_imp")

## -----------------------------------------------------------------------------

## for missing values
x <- sleep[, c("Span", "NonD","Sleep")]
histMiss(x, only.miss = FALSE)
# for imputed values
x_IMPUTED  <- regressionImp(NonD ~ Sleep, data = x)
histMiss(x_IMPUTED, delimiter = "_imp", only.miss = FALSE)


## ----warning=FALSE------------------------------------------------------------
x <- sleep[, c("Dream", "NonD","Sleep", "BodyWgt")]
x$BodyWgt <- log(x$BodyWgt)
# for missing values
matrixplot(x, sortby="BodyWgt")
# for imputed values - multiple variable imputation with regrssionImp()
x_IMPUTED  <- regressionImp(NonD + Dream ~ Sleep, data = x)
matrixplot(x_IMPUTED, delimiter = "_imp", sortby = "BodyWgt")

## -----------------------------------------------------------------------------
dataset <- sleep[, c("Dream", "NonD", "BodyWgt", "Span")]
dataset$BodyWgt <- log(dataset$BodyWgt)
dataset$Span <- log(dataset$Span)
imp_knn <- kNN(dataset, variable = "NonD") 
dataset[, c("NonD", "Span")] %>% 
  marginplot()
imp_knn[, c("NonD", "Span", "NonD_imp")] %>% 
  marginplot(delimiter = "_imp")

## ----warning=FALSE------------------------------------------------------------
## for missing values
x <- sleep[, 2:4]
x[, 1] <- log10(x[, 1])
marginmatrix(x)

## for imputed values
x_imp <- irmi(sleep[, 2:4])
x_imp[,1] <- log10(x_imp[, 1])
marginmatrix(x_imp, delimiter = "_imp")

