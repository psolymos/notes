
T <- 10
n <- 4
IF <- 2

pap <- numeric(T*n*2)
cit <- numeric(T*n*2)
tim <- numeric(T*n*2)

i <- 1
for (t in 1:T) {
    nt <- max(1, rpois(1, n))
    IFt <- rpois(nt, IF)
    tim[i:(i+nt-1)] <- t
    pap[i:(i+nt-1)] <- IFt
    citt <- suppressWarnings(rpois(length(pap), pap))
    cit <- cit+citt
    i <- i+nt
}

tmp <- data.frame(tim, pap, cit)
tmp <- tmp[tmp$tim>0,]
tmp <- aggregate(tmp, list(tmp$tim), sum)[,-2]
tmp$cpap <- cumsum(tmp$pap)
tmp$ccit <- cumsum(tmp$cit)

plot(tmp$Group.1, tmp$cpap, type="l", col=2, ylim=c(0, max(tmp$ccit,tmp$cpap)))
lines(tmp$Group.1, tmp$ccit, col=4)
