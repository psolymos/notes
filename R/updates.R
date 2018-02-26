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
    "devtools", "testthat", "akima", "rioja", "data.table", "partykit",
    "mvtnorm", "DEoptim")

(toInst <- setdiff(pkglist, rownames(installed.packages())))

if (length(toInst) > 0)
    install.packages(toInst, repos="http://cran.at.r-project.org/")

#if (.Platform$OS.type != "windows")
#    install.packages("Aspell", repos = "http://www.omegahat.org/R")

update.packages(repos="http://cran.at.r-project.org/", ask=FALSE)

## create CRAN submission email template

submit_cran_template <- function(path = ".") {
    news <- readLines(file.path(path, "NEWS.md"))
    i <- which(startsWith(news, "##"))[1L:2L]
    latest <- news[i[1L]:(i[2L]-1)]
    latest <- latest[-1]
    latest <- latest[latest != ""]
#    latest <- latest[startsWith(latest, "*")]
    descr <- read.dcf(file.path(path, "DESCRIPTION"))
    ver <- unname(descr[1L,"Version"])
    pkg <- unname(descr[1L,"Package"])
    maint <- unname(descr[1L,"Maintainer"])
    out <- c(
        "Dear CRAN Maintainers,\n\n",
        "This is an update (version ", ver, ") of the ",
        pkg, " R extension package.\n\n",
        "The package includes the following changes:\n\n",
        paste(latest, collapse="\n"),
        "\n\nThe package tarball passed R CMD check --as-cran ",
        "without error/warning/note on Mac (current R), ",
        "Linux (old, current, devel), and Windows (current, devel R).\n\n",
        "Best wishes,\n\n",
        maint, "\npackage maintainer")
    out
}

cat(submit_cran_template("~/repos/mefa4"), sep="")
cat(submit_cran_template("~/repos/dclone"), sep="")
cat(submit_cran_template("~/repos/ResourceSelection"), sep="")

