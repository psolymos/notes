# Tell all slaves to return a message identifying themselves:

library("Rmpi")

sprintf("TEST mpi.universe.size() =  %i", mpi.universe.size())
ns <- mpi.universe.size() - 1
sprintf("TEST attempt to spawn %i slaves", ns)
mpi.spawn.Rslaves(nslaves=ns)
mpi.remote.exec(paste("I am",mpi.comm.rank(),"of",mpi.comm.size()))
mpi.remote.exec(paste(mpi.comm.get.parent()))

#Send execution commands to the slaves:

x<-5

# These would all be pretty correlated one would think:

x<-mpi.remote.exec(rnorm,x)
length(x)
x

mpi.parLapply(seq_len(ns), function(z) z^2)

# see what the heck is going on with snow

# In MPI configurations where process spawning is not available and something like mpirun is used to start a master and a set of slaves the corresponding cluster will have been pre-constructed and can be obtained with getMPIcluster. It is also possible to obtain a reference to the running cluster using makeCluster or makeMPIcluster. In this case the count argument can be omitted; if it is supplied, it must equal the number of nodes in the cluster. This interface is still experimental and subject to change.

#library(snow)
#cl <- makeMPIcluster(ns)
#cl
#clusterEvalQ(cl, rnorm(5))
#stopCluster(cl)

sessionInfo()

mpi.close.Rslaves()
mpi.quit()



