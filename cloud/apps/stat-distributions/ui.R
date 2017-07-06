library(shiny)

shinyUI(fluidPage(

  titlePanel("Statistical Distributions"),

  sidebarLayout(
    sidebarPanel(

      selectInput("distr", "Distribution",
                  choices=c(Bernoulli = "Bernoulli",
            Binomial = "Binomial",
            Poisson = "Poisson",
            Normal = "Normal",
            Lognormal = "Lognormal",
            Uniform = "Uniform",
            Beta = "Beta",
            Gamma = "Gamma")),
      hr(),

#      radioButtons(
#          "distr", "Distribution",
#          c(Bernoulli = "Bernoulli",
#            Binomial = "Binomial",
#            Poisson = "Poisson",
#            Normal = "Normal",
#            Lognormal = "Lognormal",
#            Uniform = "Uniform",
#            Beta = "Beta",
#            Gamma = "Gamma")),
      sliderInput("n", label = "Sample size",
                  min = 10, max = 1000, value = 100, step = 10),
      sliderInput("seed", label = "Random seed",
                  min = 0, max = 100, value = 0, step = 10),
      ## Bernoulli
      conditionalPanel(
        condition = "input.distr == 'Bernoulli'",
          sliderInput("p", label = "Probability",
                  min = 0, max = 1, value = 0.3, step = 0.05)),
      ## Binomial
      conditionalPanel(
        condition = "input.distr == 'Binomial'",
          sliderInput("p", label = "Probability",
                  min = 0, max = 1, value = 0.3, step = 0.05),
          sliderInput("size", label = "Size",
                  min = 1, max = 1000, value = 10, step = 50)),
      ## Poisson
      conditionalPanel(
        condition = "input.distr == 'Poisson'",
          sliderInput("lambda", label = "Mean/Rate",
                  min = 0, max = 100, value = 5, step = 5)),
      ## Normal
      conditionalPanel(
        condition = "input.distr == 'Normal'",
          sliderInput("mu", label = "Mean",
                  min = -10, max = 10, value = 0, step = 1),
          sliderInput("var", label = "Variance",
                  min = 0.001, max = 10, value = 1, step = 0.5)),
      ## Logormal
      conditionalPanel(
        condition = "input.distr == 'Lognormal'",
          sliderInput("mu", label = "Mean",
                  min = -10, max = 10, value = -1, step = 1),
          sliderInput("var", label = "Variance",
                  min = -10, max = 10, value = 1, step = 1)),
      ## Uniform
      conditionalPanel(
        condition = "input.distr == 'Uniform'",
          sliderInput("a", label = "Minimum",
                  min = -10, max = 10, value = -1, step = 0.5),
          sliderInput("b", label = "Maximum",
                  min = -10, max = 10, value = 1, step = 0.5)),
      ## Beta
      conditionalPanel(
        condition = "input.distr == 'Beta'",
          sliderInput("shape1", label = "Shape 2",
                  min = 0, max = 10, value = 1, step = 0.5),
          sliderInput("shape2", label = "Shape 1",
                  min = 0, max = 10, value = 1, step = 0.5)),
      ## Gamma
      conditionalPanel(
        condition = "input.distr == 'Gamma'",
          sliderInput("shape", label = "Shape",
                  min = 0.001, max = 10, value = 1, step = 0.5),
          sliderInput("rate", label = "Rate",
                  min = 0.001, max = 10, value = 1, step = 0.5))
      ),

      mainPanel(plotOutput("distPlot"))
  )

))

