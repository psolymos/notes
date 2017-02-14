## package dependencies for reinstalling
pkglist <- c(
    ## creator, maintainer
    "mefa", "mefa4", "dclone", "dcmle", "detect", "sharx",
    "ResourceSelection", "PVAClone", "pbapply", "opticut", "intrval",
    ## "QPAD",
    ## author
    "vegan", "epiR", "plotrix", "adegenet",
    ## user
    "rgl", "mgcv", "scatterplot3d", "permute", "rjags", "ade4",
    "coda", "snow", "R2WinBUGS", "rlecuyer", "Formula", "maptools", "BRugs",
    "lme4", "R2OpenBUGS", "RODBC", "rgdal", "raster", "sp",
    "reshape", "simba", "labdsv", "Hmisc", "untb", "ggplot2",
    "ineq", "pscl", "rpart", "gbm", "glmnet", "knitr", "ellipse",
    "betareg", "pROC", "unmarked", "forecast", "labdsv", "untb",
    "devtools", "testthat", "akima", "rioja", "data.table", "partykit")

(toInst <- setdiff(pkglist, rownames(installed.packages())))

if (length(toInst) > 0)
    install.packages(toInst, repos="http://cran.at.r-project.org/")

#if (.Platform$OS.type != "windows")
#    install.packages("Aspell", repos = "http://www.omegahat.org/R")

update.packages(repos="http://cran.at.r-project.org/", ask=FALSE)
