% High Performance Computing with Westgrid: a gentle into for ecologists
% Peter Solymos (solymos@ualberta.ca)
% August 12, 2013 (version 2)




Introduction
============

We often face 'embarrassingly parallel problems' when using computer intensive
approaches, such as bootstrap and MCMC, or doing simulations.
In these cases, computing time scales linearly with the number of replicates.
Most situations are easy to break down into independent subsets, that can be run
without knowledge about other parts of the instance. For example,
independent bootstrap runs, MCMC chains, simulation settings can be run
on different instances of a program or on different computers, and 
results can be combined later. These are the types of problems that are easiest
to parallelize.

In this tutorial, I am walking through a bootstrap example and show how to
use Westgrid to speed up calculations. I assume that you have a valid
[Compute Canada](https://computecanada.ca/) user ID active on 
[Westgrid](https://www.westgrid.ca/). I am only considering the Jasper
system on Westgrid, as specification of Jasper fit what I am doing
(most importantly it has R and JAGS with quite recent versions,
and it has support for MPI through Rmpi).

Toy example
===========

Simulation
----------

Here I am considering an RSPF model and simulated data set, because
this way I can demonstrate how to install an R package on Westgrid:


```r
if (!require(ResourceSelection)) install.packages("ResourceSelection", 
    repos = "http://cran.at.r-project.org/")
library(ResourceSelection)
n.used <- 1000
m <- 10
n <- n.used * m
set.seed(1234)
x <- data.frame(x1 = rnorm(n), x2 = runif(n))
cfs <- c(1.5, -1, 0.5)
dat <- simulateUsedAvail(x, cfs, n.used, m, link = "logit")
str(dat)
```


Bootstrap example
------------------

On a single machine it is quite common to have multiple cores
that allows to do 2-4-8-fold parallelization depending on
the number of cores and memory.

We create resampled row IDs for used points outside of the function, 
the function takes a vector of IDs as argument. This way we can compare
results from sequential and parallel runs.


```r
set.seed(1234)
B <- 19
ids <- replicate(B, c(sample(which(dat$status == 1), sum(dat$status), 
    replace = TRUE), which(dat$status == 0)))
rspfBootFun <- function(i) {
    m <- suppressWarnings(rspf(status ~ . - status, dat[ids[, 
        i], ], m = 0, B = 0))
    coef(m)
}
```


### Sequential runs


```r
rspfBootFun(1)
summary(t(sapply(1:B, rspfBootFun)))
```


### Parallel runs


```r
library(snow)
ncl <- 2
cl <- makeCluster(2)
clusterEvalQ(cl, library(ResourceSelection))
clusterExport(cl, c("dat", "ids"))
res <- parSapply(cl, 1:B, rspfBootFun)
stopCluster(cl)
summary(t(res))
```


Now that we know how to parallelize a problem, it is time to learn how to 
scale it up with Westgrid. Fo this, we'll use the simulated data
and the bootstrap ID matrix:


```r
save(dat, ids, file = "rspfdata.Rdata")
```


Using Westgrid
=====================

We need SSH (secure shell) for logging in, and 
SFTP/PSFTP for transferring files. 
These come by default in Linux/Unix systems, and we need to install 
[PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/) on Windows.

Passing data to Westgrid
------------------------

Screen shots are available here:
[http://panpalitta.wordpress.com/tag/westgrid/](http://panpalitta.wordpress.com/tag/westgrid/)

* Open PSFTP,
* type `open username@jasper.westgrid.ca`. Replace `username`
  with your username, `jasper` with any other facility.
  It will prompt for your password, then you are in.
* Use the `lcd` (local directory) command to navigate
  to the directory with the file you want to transfer:
  `lcd c:\path\to\files`.
* Use the `put` command to transfer a local file to the directory
  names `test` on the server:
  `put rspfdata.Rdata text/rspfdata.Rdata`.
* `exit` or say `bye` to close the connection.


Logging into Westgrid
---------------------

* Open PuTTY.
* Type host name as `username@jasper.westgrid.ca`,
  type in password when prompted.
* Navigate into the `test` directory: `cd test`,
* see if our data file is listed, type `ls`.

Running jobs through R
----------------------

For running R, we need to load the module by typing
`module load application/R/3.0.0`. This loads
R and related Intel compilers (additional compiler
might be required of source packages have
compiled code), plus JAGS is also loaded.

To start an interactive R session, just navigate
into the folder where the scripts are using `cd` and type `R`
(this way that folder will be the working directory).

Once R starts, we need to install the snow package,
that is how we are going to access the Rmpi interface to
the MPI (Message Passing Interface). The rlecuyer package also
comes handy for parallel random numbers,
and of course we need ResourceSelection for the toy example
(right click seems to paste from clipboard onto SSH screen
in PuTTY):


```r
if (!require(snow)) 
    install.packages("snow", 
        repos = "http://cran.at.r-project.org/")
library(snow)
if (!require(rlecuyer)) 
    install.packages("rlecuyer", 
        repos = "http://cran.at.r-project.org/")
library(rlecuyer)
library(Rmpi)
if (!require(ResourceSelection)) 
    install.packages("ResourceSelection", 
        repos = "http://cran.at.r-project.org/")
library(ResourceSelection)
```


We can either specify the `lib` argument, or just
accept the directory R offers (we have no admin privileges
on the grid, so custom installed R packages are going to be
stored in a directory within the home folder).

Here is how we spawn workers interactively:


```r
ncl <- 19
cl <- makeMPIcluster(ncl)
```


Now let us check if the data file is visible


```r
clusterEvalQ(cl, list.files())
```


Let us load the data and do the analysis:


```r
clusterEvalQ(cl, library(ResourceSelection))
clusterEvalQ(cl, load("rspfdata.Rdata"))
rspfBootFun <- function(i) {
    m <- suppressWarnings(rspf(status ~ . - status, dat[ids[, 
        i], ], m = 0, B = 0))
    coef(m)
}
B <- 19
res <- parSapply(cl, 1:B, rspfBootFun)
stopCluster(cl)
summary(t(res))
```


The other options described before (using apply and sapply) 
should work similarly, but you need to take care of passing
bootstrap IDs to the workers (and don't need to worry about
random numbers).

Finally, save results and exit R. Here we use `mpi.quit` so that
slaves re shut down properly:


```r
save(res, file = "rspfresults00.Rdata")
mpi.quit("no")
```


Exit SSH: `exit`.

Running jobs in batch mode
--------------------------

We are going to submit a job to the grid. For this we need an R scipt file,
and another file that sets up the submission. 

### Testing a sequential program

First we figure out if the code runs fine in sequential mode. 
For this, here is the R code, let's save it in a file called `stest.R`:


```r
if (!require(snow)) 
    install.packages("snow", 
        repos = "http://cran.at.r-project.org/")
library(snow)
if (!require(rlecuyer)) 
    install.packages("rlecuyer", 
        repos = "http://cran.at.r-project.org/")
library(rlecuyer)
library(Rmpi)
if (!require(ResourceSelection)) 
    install.packages("ResourceSelection", 
        repos = "http://cran.at.r-project.org/")
library(ResourceSelection)
load("rspfdata.Rdata")
rspfBoot1 <- function() {
    id <- c(sample(which(dat$status == 1), 
        sum(dat$status), replace = TRUE), 
        which(dat$status == 0))
    m <- suppressWarnings(rspf(status ~ . - status, dat[id, ], 
        m = 0, B = 0))
    coef(m)
}
B <- 19
res <- lapply(1:B, function(z) rspfBoot1())
save(res, file = "rspfresults01.Rdata")
q("no")
```


And here is the shell commend we need to put in a file `stest.pbs`
(see the tutorial [here](https://www.westgrid.ca/support/running_jobs) 
for more info):

```
#!/bin/bash
#PBS -S /bin/bash
#PBS -N seqTest
#PBS -o seqTest.out
#PBS -e seqTest.err
#PBS -M solymos@ualberta.ca
#PBS -m n
#PBS -l walltime=10:00:00
#PBS -l procs=1

cd $PBS_O_WORKDIR
echo "Current working directory is `pwd`"

echo "Node file: $PBS_NODEFILE :"
cat $PBS_NODEFILE

echo "loading R module"
module load application/R/3.0.0

echo "Starting run at: `date`"

R --vanilla < stest.R

echo "Program finished with exit code $? at: `date`"
```

This will print out relevant text that can help in debugging.
Let's walk through the lines.

The 1st line states that it is a shell script:

```
#!/bin/bash
```

This line specifies the shell to run the script in:

```
#PBS -S /bin/bash
```

This line specifies the name of the job:

```
#PBS -N seqTest
```

This is the name for the 2 output files:

```
#PBS -o seqTest.out
#PBS -e seqTest.err
```

E-mail of the user if we want messages when there are problems.
The `#PBS -m n` means no e-mail messages, 
`#PBS -m bea` would mean that send message when the job
**b**egins, when there is an **e**rror or when the script **a**borts:

```
#PBS -M solymos@ualberta.ca
#PBS -m n
```

Set the max walltime until the job is allowed to run (this is system specific,
jasper currently has 72 hours as limit):

```
#PBS -l walltime=10:00:00
```

The number of processors, now only one for sequential job:

```
#PBS -l procs=1
```

Print out the working directory and
the node file (which are stored as a system variable):

```
cd $PBS_O_WORKDIR
echo "Current working directory is `pwd`"

echo "Node file: $PBS_NODEFILE :"
cat $PBS_NODEFILE
```

Load the R module, so that R is now available for the work:

```
echo "loading R module"
module load application/R/3.0.0
```

Date and time when the job has started:

```
echo "Starting run at: `date`"
```

Simply run the `stest.R` file in R, `--vanilla` mean that R won't
load any previously saved session:

```
R --vanilla < stest.R
```

Date and time when the job has finished and exit status (0 means OK):

```
echo "Program finished with exit code $? at: `date`"
```

To submit the job, go into SSH and type `qsub stest.pbs`.
We can check the place and status of your jobs in the queue by
`showq -u username`. We can delete a job by `qdel jobid`.

Then wait for the results: the 2 files we specified earlier 
(`seqTest.err` end `seqTest.out`) and the R data output 
(`rspfresults01.Rdata`).

### Testing a parallel program

Now it is time to use more processors and test the parallel version.

Here is the R sctipt file, saved as `test.R`:

```r
.Last <- function() {
    if (getOption("CLUSTER_ACTIVE")) {
        stopCluster(cl)
        cat("active cluster stopped by .Last\n")
    } else {
        cat("no active cluster found\n")
    }
}
options(CLUSTER_ACTIVE = FALSE)
getOption("CLUSTER_ACTIVE")
if (!require(snow)) 
    install.packages("snow", 
        repos = "http://cran.at.r-project.org/")
library(snow)
if (!require(rlecuyer)) 
    install.packages("rlecuyer", 
        repos = "http://cran.at.r-project.org/")
library(rlecuyer)
library(Rmpi)
if (!require(ResourceSelection)) 
    install.packages("ResourceSelection", 
        repos = "http://cran.at.r-project.org/")
library(ResourceSelection)
ncl <- 4
cl <- makeMPIcluster(ncl)
options(CLUSTER_ACTIVE = TRUE)
getOption("CLUSTER_ACTIVE")
print(cl)
clusterEvalQ(cl, load("rspfdata.Rdata"))
clusterEvalQ(cl, library(ResourceSelection))
rspfBoot1 <- function() {
    id <- c(sample(which(dat$status == 1), 
        sum(dat$status), replace = TRUE), 
        which(dat$status == 0))
    m <- suppressWarnings(rspf(status ~ . - status, dat[id, ], 
        m = 0, B = 0))
    coef(m)
}
clusterExport(cl, "rspfBoot1")
clusterSetupRNG(cl, type = "RNGstream")
B <- 19
res <- parLapply(cl, 1:B, function(z) rspfBoot1())
stopCluster(cl)
options(CLUSTER_ACTIVE = FALSE)
getOption("CLUSTER_ACTIVE")
save(res, file = "rspfresults02.Rdata")
mpi.quit("no")
```


Note tha tthere is a `.Last` function. This helps creaning up
the work when R quits unexpectedly. So that workers will be
shut down properly. We use `mpi.quit` for the same reason.

The corresponding shell script is saved in the file `test.pbs`:

```
#!/bin/bash
#PBS -S /bin/bash
#PBS -N parTest
#PBS -o parTest.out
#PBS -e parTest.err
#PBS -M solymos@ualberta.ca
#PBS -m n
#PBS -l walltime=10:00:00
#PBS -l procs=19

cd $PBS_O_WORKDIR
echo "Current working directory is `pwd`"

echo "Node file: $PBS_NODEFILE :"
cat $PBS_NODEFILE

echo "loading R module"
module load application/R/3.0.0

echo "Starting run at: `date`"

mpiexec -n 1 R --vanilla < test.R

echo "Program finished with exit code $? at: `date`"
```

All are the same as in the sequential shell file, except for the number of 
processors requested is now 19, and R is called through mpiexec.
Note that we ask for only one worker for the master process (`mpiexec -n 1`).
The slaves are going to be spawned by the R process.

If the job is done, the results should appear 
(`parTest.err` end `parTest.out`, `rspfresults02.Rdata`).
Exit status 0 in the output file `parTest.out` is a good sign.

Getting back the results
------------------------

* Open PSFTP,
* type `open username@jasper.westgrid.ca`. Replace `username`
  with your username, `jasper` with any other facility.
  It will prompt for your password, then you are in.
* Use the `lcd` (local directory) command to navigate
  to the directory with the file you want to transfer:
  `lcd c:\path\to\files`.
* Navigate into the directory with the results on the remote
  location using `cd`.
* Use the `get` command to transfer the file from the server to the 
  local directory:
  `get rspfresults02.Rdata`.
* You should be able to see the file now in your local folder.
* Do this with any other output files.
* `exit` or say `bye` to close the connection.

Useful resources
----------------

* Screen shots for SSH and PSFTP: [http://panpalitta.wordpress.com/tag/westgrid/](http://panpalitta.wordpress.com/tag/westgrid/)

* R howto: [https://www.westgrid.ca/support/software/r](https://www.westgrid.ca/support/software/r)

* About Jasper: [https://www.westgrid.ca/support/quickstart/jasper](https://www.westgrid.ca/support/quickstart/jasper)

* Tutorial about runnin jobs on Westgrid: [https://www.westgrid.ca/support/running_jobs](https://www.westgrid.ca/support/running_jobs)

* Rmpi tutorial: [http://math.acadiau.ca/ACMMaC/Rmpi/index.html](http://math.acadiau.ca/ACMMaC/Rmpi/index.html)

* Rmpi and snow tutorial: [http://people.stat.sfu.ca/\~mtpratol/computing.html](http://people.stat.sfu.ca/~mtpratol/computing.html)

* General westgrid tutorial: [http://www.sfu.ca/\~mawerder/geeks/westgrid.html](http://www.sfu.ca/~mawerder/geeks/westgrid.html)

