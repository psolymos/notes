if (FALSE) {
pkgList <- c(
    "raster",
    "rgdal",
    "rgeos",
    "sp",
    "gstat",
    "viridis",
    "leaflet",
    "geoR",
    "MASS",
    "maptools",
    "mapedit",
    "mapview",
    "sf",
    "shiny",
    "shinythemes",
    "DT",
    "markdown",
    "shinyjs")
(toInst <- setdiff(pkgList, rownames(installed.packages())))
if (length(toInst) > 0)
    install.packages(toInst, repos="http://cran.at.r-project.org/")
#update.packages(repos="http://cran.at.r-project.org/", ask=FALSE)
}

## load required packages ----------------------------------
library(raster)
library(rgdal)
library(rgeos)
library(sp)
library(gstat)
library(viridis)
library(leaflet)
library(geoR)
library(MASS)
library(maptools)
#library(mgcv)
#library(fields)
library(mapedit)
library(mapview)
library(sf)
library(shiny)
library(shinythemes)
library(DT)
library(markdown)
#library(shinyjs)

## https://github.com/daattali/advanced-shiny/tree/master/close-window
#jscode <- "shinyjs.closeWindow = function() { window.close(); }"

## global variables preset ----------------------------------

## default CRS for input data
input_crs <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
#input_crs <- "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs"
## column names for default input data
#col_X <- "X"
#col_Y <- "Y"
#col_Z <- "Z"
## resolution in greated dimansion
Nmax <- 50
## minimum sample size for kriging
nmin <- 10
nmax <- 1000
## opacity for leaflet
opacity <- 0.75
## variogram model
Model <- "Best"
## default color
col_fun1 <- viridis
col_fun2 <- magma

## define functions ----------------------------------

## simulate default data
simulate_grf <- function(nsim=500) {
    xsim <- c(-110, -120)
    ysim <- c(55, 60)
    dat <- data.frame(
        X=runif(nsim, min(xsim), max(xsim)),
        Y=runif(nsim, min(ysim), max(ysim)))
    dat$Z <- grf(nrow(dat), grid=as.matrix(dat[,c("X", "Y")]), nsim=1,
        cov.model = "matern", cov.pars=c(1, 1))$data
    dat
}

## normalize input data
normalize_input <- function(dat, col_X, col_Y, col_Z, input_CRS) {
    x <- dat[,c(col_X, col_Y, col_Z)]
    colnames(x) <- c("X", "Y", "Z")
    x <- x[rowSums(is.na(x))==0,] # check!
    ## project spatial data
    coordinates(x) <- ~ X + Y # string
    proj4string(x) <- CRS(input_crs)
    x
}

## symbol scaling
padd <- function(x) {
    x <- x - min(x)
    x <- x / max(x)
    x <- 0.2 + 0.8*x
    x
}

## density for all + subset
plot_density <- function(z, o, ...) {
    d0 <- density(z)
    d0$y <- d0$y / max(d0$y)
    d <- density(z[o])
    d$y <- d$y / max(d$y)
    plot(d0$x, d0$y, type="n", axes=FALSE, xlab="Value", ylab="Density",
        ylim=c(0, 1.25), ...)
    axis(1)
    box()
    polygon(d0$x, d0$y, border="#FF0000FF", col="#FF000080")
    polygon(d$x, d$y, border="#0000FFFF", col="#0000FF80")
    legend("topleft", fill=c("#FF000080", "#0000FF80"),
        legend=c(paste0("All (n=", length(z), ")"),
            paste0("Subset (n=", sum(o), ")")),
        border=c("#FF0000FF", "#0000FFFF"), bty="n")
    invisible(NULL)
}

## sample variogram
sample_variogram <- function(x, Model) {
    vgtypes <- switch(Model,
        "Best"=c("Exp", "Sph", "Gau", "Mat"),
        "Exp"="Exp",
        "Sph"="Sph",
        "Gau"="Gau",
        "Mat"="Mat")
    v0 <- variogram(Variable ~ 1, x)
    vv <- suppressWarnings(lapply(vgtypes, function(z)
        try(fit.variogram(v0, model=vgm(model=z), fit.kappa=TRUE), silent=TRUE)))
    names(vv) <- vgtypes
    vv <- vv[!sapply(vv, inherits, "try-error")]
    SSErr <- sapply(vv, attr, "SSErr")
    #barplot(SSErr)
    list(variogram=v0, fit=vv, SSErr=SSErr)
}

## provide figures
colorit <- function(x, col_fun=heat.colors, quantiles=TRUE, n=100) {
    br <- if (quantiles) {
        quantile(x, seq(0, 1, by=1/n))
    } else {
        seq(min(x, na.rm=TRUE), max(x, na.rm=TRUE),
            by=diff(range(x, na.rm=TRUE))/n)
    }
    substr(col_fun(n)[findInterval(x, br, all.inside=TRUE)], 1, 7)
}

## Box-Cox transform
bct <- function(x) {
    alpha <- if (any(x <= 0))
        1-min(x) else 0
    x <- x + alpha
    bc <- boxcox(x ~ 1,
        lambda = seq(-2, 2, 1/10), plotit = FALSE)
    lambda <- bc$x[which.max(bc$y)]
    out <- if (lambda == 0)
        log(x) else ((x^lambda) - 1)/lambda
    attr(out, "lambda") <- lambda
    attr(out, "alpha") <- alpha
    out
}

inv_bct <- function(x, lambda, alpha) {
    if (is.na(lambda)) {
        out <- x
    } else {
        out <- if (lambda == 0)
            exp(x) else (lambda*x + 1)^(1/lambda)
    }
    out - alpha
}
