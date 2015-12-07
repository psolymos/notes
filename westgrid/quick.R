#### preliminaries ####

if (!interactive()) {
.Last <- function() {
    if (getOption("CLUSTER_ACTIVE")) {
        stopCluster(cl)
        cat("active cluster stopped by .Last\n")
    } else {
        cat("no active cluster found\n")
    }
}
options("CLUSTER_ACTIVE" = FALSE)
}
library(snow)
if (!interactive())
    library(Rmpi)

## -------------------------- load libraries, source scripts on master --- START

library(opticut)
library(indicspecies)

## -------------------------- load libraries, source scripts on master --- END

if (!interactive())
    (args <- commandArgs(trailingOnly = TRUE))

TEST <- interactive()

ROOT <- getwd()

#### setup ####

nodes <- if (interactive())
    5 else as.numeric(args[1])
BBB <- if (TEST) 2 else 240 # = 4*5*12
ncl <- if (TEST) 2 else nodes*12

#### spawning the slaves ####

cl <- if (interactive())
    makeCluster(ncl) else makeMPIcluster(ncl)
if (!interactive())
    options("CLUSTER_ACTIVE" = TRUE)

#### actual script comes here ####

oc_sim_K2 <- 
function(b1=0.5, b2=0, b3=0.05, b4=0, mu0=10, n=100, pos=TRUE)
{
    K <- 2
    n <- 2*(n %/% 2)
    i <- 1:n
    h0 <- rep(LETTERS[1:2], each=n/2)
    j <- sample.int(n/2, round((n/2)*(b4/2)))
    h1 <- h0
    h1[j] <- h0[j+n/2]
    h1[j+n/2] <- h0[j]
    mu <- c(mu0*(1-b1), mu0)
    Mean <- rep(mu, each=n/2)
    ## this can remove group effects
    ## same pattern in each group
#    Conf <- runif(n, -0.5*diff(mu), 0.5*diff(mu))
    ## counteracts the habitat effect
    Conf <- runif(n,0,1) * rep(c(diff(mu), -diff(mu)), each=n/2)
    Noise <- rnorm(n, 0, 0.1*mu0)
    Y <- Mean + b2*Conf + b3*Noise    
    if (pos)
        Y[Y < 0] <- 0
    out <- data.frame(Y=Y, h0=h0, h1=h1, i=i, x=i-mean(i),
        Mean=Mean, Conf=Conf, Noise=Noise)
    attr(out, "settings") <- list(b1=b1, b2=b2, b3=b3, b4=b4, 
                                  K=K, n=n, mu0=mu0, pos=pos)
    out
}

est_fun1 <- function(..., R=999, level=0.95) {
    dat <- oc_sim_K2(...)
    m0 <- opticut(Y ~ 1, dat, strata=h1)$species[[1]]
    m1 <- opticut(Y ~ Conf, dat, strata=h1)$species[[1]]
    ## IndVal
    iv <- multipatt(data.frame(spp1=dat$Y), dat$h1, func = "IndVal.g", 
        duleg=TRUE, control = how(nperm=R))
    ## Phi coef
    rg <- multipatt(data.frame(spp1=dat$Y), dat$h1, func = "r.g", 
        duleg=TRUE, control = how(nperm=R))
    ## F-ratio
    fv <- anova(lm(Y ~ h1, dat))
    
    out <- matrix(NA, 5, 2)
    colnames(out) <- c("stat", "pass")
    rownames(out) <- c("I0", "IX", "IV", "PH", "FR")
    out[1,1] <- m0$I[1]
    out[1,2] <- ifelse(m0$logLR >= 2, 1, 0)
    out[2,1] <- m1$I[1]
    out[2,2] <- ifelse(m1$logLR >= 2, 1, 0)
    out[3,1] <- iv$sign[1,"stat"]
    out[3,2] <- ifelse(iv$sign[1,"p.value"] <= 1-level, 1, 0)
    out[4,1] <- rg$sign[1,"stat"]
    out[4,2] <- ifelse(rg$sign[1,"p.value"] <= 1-level, 1, 0)
    out[5,1] <- fv[1,"F value"]
    out[5,2] <- ifelse(fv[1,"Pr(>F)"] <= 1-level, 1, 0)
    if (rownames(m0) != "B")
        out[1,2] <- -out[1,2]
    if (rownames(m1) != "B")
        out[2,2] <- -out[2,2]
    if (iv$sign[1,"s.B"] != 1)
        out[3,2] <- -out[3,2]
    if (rg$sign[1,"s.B"] != 1)
        out[4,2] <- -out[4,2]
    ## F-ratio cannot tell which is low/high
    t(out)    
}

B <- 200

vals <- expand.grid(
    b2=seq(0, 1, by=0.1),
    b4=seq(0, 1, by=0.1))

vals2 <- expand.grid(
    b2=seq(0, 1, by=0.1),
    b4=seq(0, 1, by=0.1),
    b1=c(0.1, 0.5, 0.9),
    b3=c(0.1, 0.5, 1))

clusterExport(cl, c("est_fun1", "oc_sim_K2", "B","vals","vals2"))
clusterEvalQ(cl, library(opticut))
clusterEvalQ(cl, library(indicspecies))

## contrast (I)
res1 <- parLapply(cl, seq(0.1, 0.9, by=0.1), function(z) 
    replicate(B, est_fun1(b1=z)))

## confounding
res2 <- parLapply(cl, seq(0, 1, by=0.1), function(z) 
    replicate(B, est_fun1(b2=z)))

## noise
res3 <- parLapply(cl, seq(0.1, 1, by=0.1), function(z) 
    replicate(B, est_fun1(b3=z)))

## mixing
res4 <- parLapply(cl, seq(0, 1, by=0.1), function(z) 
    replicate(B, est_fun1(b4=z)))

## conf & mixing
res5 <- parLapply(cl, 1:nrow(vals), function(z) 
    replicate(B, est_fun1(b2=vals[z,1], b4=vals[z,2])))

## all
res6 <- parLapply(cl, 1:nrow(vals2), function(z) 
    replicate(B, est_fun1(b2=vals2[z,1], b4=vals2[z,2],
        b1=vals2[z,3], b3=vals2[z,4])))

save(vals, vals2, res1, res2, res3, res4, res5, res6, B,
    file="~/opticut/opticut-simuls.Rdata")


#### shutting down ####

stopCluster(cl)
if (!interactive()) {
    options("CLUSTER_ACTIVE" = FALSE)
    mpi.quit("no")
} else {
    quit("no")
}
