rm(list = ls())

# Load the libraries 

library(mlbench)
library(qgraph)
library(Hmisc)

# Use data set 

data("BostonHousing")
dataset<-BostonHousing[,1:13]

# convert factor to numeric
dataset[,4] <- as.numeric(as.character(dataset[,4]))

# Calculate correlation
xCor<-cor(dataset)


# Visualize network
qgraph(xCor, shape="circle", posCol="darkgreen", negCol="darkred", layout="groups", vsize=10)
qgraph(xCor, shape="circle", posCol="darkgreen", negCol="darkred", layout="spring", vsize=10)
qgraph(xCor, shape="circle", posCol="darkgreen", negCol="darkred", layout="spring", vsize=10,edge.labels = TRUE)


#################################################################


