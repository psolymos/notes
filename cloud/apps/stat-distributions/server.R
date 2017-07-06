library(shiny)

shinyServer(function(input, output) {
    output$distPlot <- renderPlot({
        par(las = 1)
        set.seed(input$seed)
        if (input$distr == "Uniform" && input$b < input$a)
            stop("Maximum must be greater than Minimum")
        y <- switch(input$distr,
            "Bernoulli" = rbinom(1000, 1, input$p),
            "Binomial" = rbinom(1000, input$size, input$p),
            "Poisson" = rpois(1000, input$lambda),
            "Normal" = rnorm(1000, input$mu, sqrt(input$var)),
            "Lognormal" = rlnorm(1000, input$mu, sqrt(input$var)),
            "Uniform" = runif(1000, input$a, input$b),
            "Beta" = rbeta(1000, input$shape1, input$shape2),
            "Gamma" = rgamma(1000, input$shape, input$rate))
        yy <- y[1:input$n]
        x <- switch(input$distr,
            "Bernoulli" = c(0,1),
            "Binomial" = seq(0, max(yy)+1, by = 1),
            "Poisson" = seq(0, max(yy)+1, by = 1),
            "Normal" = seq(min(yy)-1, max(yy)+1, length.out = 1000),
            "Lognormal" = seq(0.0001, max(yy)+1, length.out = 1000),
            "Uniform" = seq(input$a+0.0001, input$b-0.0001, length.out = 1000),
            "Beta" = seq(0.0001, 0.9999, length.out = 1000),
            "Gamma" = seq(0.0001, max(yy), length.out = 1000))
        d <- switch(input$distr,
            "Bernoulli" = dbinom(x, 1, input$p),
            "Binomial" = dbinom(x, input$size, input$p),
            "Poisson" = dpois(x, input$lambda),
            "Normal" = dnorm(x, input$mu, sqrt(input$var)),
            "Lognormal" = dlnorm(x, input$mu, sqrt(input$var)),
            "Uniform" = dunif(x, input$a, input$b),
            "Beta" = dbeta(x, input$shape1, input$shape2),
            "Gamma" = dgamma(x, input$shape, input$rate))
        xlab <- "x"
        ylab <- "Density"
        main <- paste0(input$distr, " distribution (n = ", input$n, ")")
        if (input$distr %in% c("Bernoulli", "Binomial", "Poisson")) {
            tmp <- table(yy) / input$n
            plot(tmp, ylim=c(0, max(tmp, d)),
                ylab = ylab, xlab = xlab, main = main,
                col = "#cccccc", lwd = 10)
            points(x, d, pch = 21, col = "#c7254e", type = "b",
                lty = 2, cex = 2)
        } else {
            tmp <- hist(yy, plot = FALSE)
            hist(yy, freq = FALSE, ylim=c(0, max(tmp$density, d)),
                ylab = ylab, xlab = xlab, main = main,
                col = "#ecf0f1", border = "#cccccc")
            lines(x, d, lwd = 2, col = "#c7254e")
        }
    })
})
