set.seed(1)
n <- 100
x <- rnorm(n)

Mean <- mean(x)
SE <- sd(x) / sqrt(n)

B <- 200
M <- replicate(B, sample(x, n, replace=TRUE))
str(M)
MeanB <- colMeans(M)

SE
(SEB <- sd(MeanB))

hist(x)
abline(v=Mean, col=2)
abline(v=Mean+c(-SE, +SE), col=2, lty=2)
abline(v=Mean+c(-SEB, +SEB), col=4, lty=2)
