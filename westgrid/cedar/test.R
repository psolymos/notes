library(snow)
library(Rmpi)

ns <- mpi.universe.size() - 1
cl <- makeMPIcluster(ns)
cl

clusterEvalQ(cl, rnorm(5))
parLapply(seq_len(cl), function(z) z^2)

stopCluster(cl)
mpi.quit("no")

