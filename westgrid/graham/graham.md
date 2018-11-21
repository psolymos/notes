# Using cedar/graham

Modified after this [page](https://docs.computecanada.ca/wiki/R):

## Load modules

Latest version of R is 3.5 at the time of writing.
Use OpenMPI version 1.10.7 which is needed to spawn processes correctly (the default MPI module 2.1.1 has a problem with that at present).

```
module nixpkgs/16.09
module load gcc/7.3.0
module load openmpi/3.1.2
module load r/3.5.1
```


## Download latest version of Rmpi package

```
wget https://cran.r-project.org/src/contrib/Rmpi_0.6-9.tar.gz
```

## Install Rmpi

Specify the directory where you want to install the package files

```
mkdir -p ~/local/R_libs/
export R_LIBS=~/local/R_libs/
```

Set site profile location and file (useful to set CRAN mirror):

```
echo "local({r <- getOption(\"repos\")
      r[\"CRAN\"] <- \"https://cloud.r-project.org/\"
      options(repos=r)})" > ~/local/Rprofile.site
export R_PROFILE=~/local/Rprofile.site
```

Run the install command

```
R CMD INSTALL --configure-args="--with-Rmpi-include=$EBROOTOPENMPI/include   --with-Rmpi-libpath=$EBROOTOPENMPI/lib --with-Rmpi-type='OPENMPI' " Rmpi_0.6-9.tar.gz
```

If all went well, remove the tar file: `rm Rmpi_0.6-9.tar.gz`

Now start R in interactive mode: type `R` and hit enter.

Install any other packages.
With the R environmental variables properly set, we should not be prompted
to enter library path or mirror:

```
install.packages("lme4")
```

Use the `.sh` and `.R` file in this folder to test.

`cd` into the dir and submit the job: `sbatch job_makecluster.sh`.
