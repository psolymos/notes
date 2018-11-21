library(parallel)

# Create an array from the NODESLIST environnement variable
if (interactive()) {
    nodeslist <- 2
} else {
    nodeslist <- unlist(strsplit(Sys.getenv("NODESLIST"), split=" "))
}

# Create the cluster with the nodes name. One process per count of node name.
# nodeslist = node1 node1 node2 node2, means we are starting 2 processes on node1, likewise on node2.
cl <- makePSOCKcluster(nodeslist, type = "PSOCK") 

x <- iris[which(iris[,5] != "setosa"), c(1,5)]
fun <- function(i, DATA) {
    xi <- DATA[sample(100, 100, replace=TRUE),]
    mod <- glm(xi[,2] ~ xi[,1], family=binomial(logit))
    coef(mod)
}

res <- parLapply(cl, seq_len(nodeslist), fun, DATA=x)
save(res, "~/test/test.RData")

# Don't forget to release resources
stopCluster(cl)
