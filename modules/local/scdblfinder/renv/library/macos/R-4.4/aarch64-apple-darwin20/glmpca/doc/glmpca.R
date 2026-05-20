## -----------------------------------------------------------------------------
library(ggplot2); theme_set(theme_bw())
require(glmpca)

## -----------------------------------------------------------------------------
set.seed(202)
ngenes <- 5000 #must be divisible by 10
ngenes_informative<-ngenes*.1
ncells <- 50 #number of cells per cluster, must be divisible by 2
nclust<- 3
# simulate two batches with different depths
batch<-rep(1:2, each = nclust*ncells/2)
ncounts <- rpois(ncells*nclust, lambda = 1000*batch)
# generate profiles for 3 clusters
profiles_informative <- replicate(nclust, exp(rnorm(ngenes_informative)))
profiles_const<-matrix(ncol=nclust,rep(exp(rnorm(ngenes-ngenes_informative)),nclust))
profiles <- rbind(profiles_informative,profiles_const)
# generate cluster labels
clust <- sample(rep(1:3, each = ncells))
# generate single-cell transcriptomes 
counts <- sapply(seq_along(clust), function(i){
	rmultinom(1, ncounts[i], prob = profiles[,clust[i]])
})
rownames(counts) <- paste("gene", seq(nrow(counts)), sep = "_")
colnames(counts) <- paste("cell", seq(ncol(counts)), sep = "_")
# clean up rows
Y <- counts[rowSums(counts) > 0, ]
sz<-colSums(Y)
Ycpm<-1e6*t(t(Y)/sz)
Yl2<-log2(1+Ycpm)
z<-log10(sz)
pz<-1-colMeans(Y>0)
cm<-data.frame(total_counts=sz,zero_frac=pz,clust=factor(clust),batch=factor(batch))

## ---- fig.width=6, fig.height=4-----------------------------------------------
set.seed(202)
system.time(res1<-glmpca(Y,2,fam="poi")) #about 9 seconds
print(res1)
pd1<-cbind(cm,res1$factors,dimreduce="glmpca-poi")
#check optimizer decreased deviance
plot(res1$dev,type="l",xlab="iterations",ylab="Poisson deviance")

## ---- fig.width=6, fig.height=4-----------------------------------------------
set.seed(202)
system.time(res2<-glmpca(Y,2,fam="nb")) #about 32 seconds
print(res2)
pd2<-cbind(cm,res2$factors,dimreduce="glmpca-nb")
#check optimizer decreased deviance
plot(res2$dev,type="l",xlab="iterations",ylab="negative binomial deviance")

## -----------------------------------------------------------------------------
#standard PCA
system.time(res3<-prcomp(log2(1+t(Ycpm)),center=TRUE,scale.=TRUE,rank.=2)) #<1 sec
pca_factors<-res3$x
colnames(pca_factors)<-paste0("dim",1:2)
pd3<-cbind(cm,pca_factors,dimreduce="pca-logcpm")

## ---- fig.width=6, fig.height=15----------------------------------------------
pd<-rbind(pd1,pd2,pd3)
#visualize results
ggplot(pd,aes(x=dim1,y=dim2,colour=clust,shape=batch))+geom_point(size=4)+facet_wrap(~dimreduce,scales="free",nrow=3)

## ---- fig.width=6, fig.height=4-----------------------------------------------
nbres<-res2
names(nbres)
dim(Y)
dim(nbres$factors)
dim(nbres$loadings)
dim(nbres$coefX)
hist(nbres$coefX[,1],breaks=100,main="feature-specific intercepts")
print(nbres$glmpca_family)

