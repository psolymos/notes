source("globals.R")

#TODO: add common footer? Might not if using iframe
ui <- tagList(
    navbarPage(
      "Kriging Demo",
      theme = shinytheme("paper"),  # <--- To use a theme, uncomment this
#      tabPanel("Home", shiny::includeMarkdown("home.md")),
      tabPanel("Upload",
        sidebarPanel(
          fileInput("file", "Choose CSV File",
            multiple = FALSE,
            accept = c(
                "text/csv",
                "text/comma-separated-values,text/plain",
                ".csv")
          ),
          checkboxInput("header", "Header", TRUE),
          tags$hr(),
          checkboxInput('example', 'Use demo data', FALSE),
          tags$hr(),
          selectInput("col_X",label = 'Longitude (WGS 84):',""),
          selectInput("col_Y",label = 'Latitude (WGS 84):',""),
          selectInput("col_Z",label = 'Measurements:',"")
        ),
        mainPanel(
          dataTableOutput("mytable")
        )
      ),
      tabPanel("Edit", # m1
        fluidRow(
          column(8, editModUI("editor")),
          column(4,
            #h3("Data summary"),
            plotOutput("selectstat")
            #useShinyjs(),
            #extendShinyjs(text = jscode, functions = c("closeWindow")),
            #actionButton("close", "Stop app")
          )
        )
      ),
      tabPanel("Model", # vbest
        fluidRow(
          column(4,
            h3("Variogram"),
            plotOutput("vgramPlot", height = "250px"),
            tags$hr(),
#            sliderInput("resolution",
#              label="# cells in largest extent:",
#              min=10, max=200, value=Nmax, round = TRUE),
            downloadButton("downloadData", "Download")
          ),
          column(8,
            h3("Prediction"),
            leafletOutput("mymap")
          )
        )
      )
    )
)

server <- function(input, output, session) {

  values <- reactiveValues(dat=NULL, Input=NULL,
    lambda=NULL, alpha=NULL, m1=NULL, edits=NULL,
    v=NULL, vbest=NULL, BestModel=NULL, r=NULL)

## Upload

  myData <- reactive({
      if (is.null(input$file)) {
        if (input$example) {
          return(read.csv("xyz.csv"))
        } else {
          return(NULL)
        }
      } else {
        if (input$example) {
          return(read.csv("xyz.csv"))
        } else {
#            updateNumericInput(session, "col_X", NA)
#            updateNumericInput(session, "col_Y", NA)
#            updateNumericInput(session, "col_Z", NA)
            dat <-  read.csv(input$file$datapath, header=input$header)
            if (nrow(dat) > nmax)
                dat <- dat[sample.int(nrow(dat), nmax),]
            values$dat <- dat
            return(dat)
        }
      }
  })
  observe({
       updateSelectInput(
        session,
        "col_X",
        label='Longitude (WGS 84):',
        choices=c('None', names(myData())),
        selected=names(myData())[1L]
        )
  })
  observe({
       updateSelectInput(
        session,
        "col_Y",
        label='Latitude (WGS 84):',
        choices=c('None', names(myData())),
        selected=names(myData())[2L]
        )
  })
  observe({
       updateSelectInput(
        session,
        "col_Z",
        label='Measurements:',
        choices=c('None', names(myData())),
        selected=names(myData())[3L]
        )
  })
  output$mytable <- DT::renderDataTable(
    DT::datatable(myData(), options = list(pageLength = 10))
  )

## Subset

  myInput <- reactive({
    req(myData())
    #print(str(myData()))
    Input <- normalize_input(myData(),
      input$col_X, input$col_Y, input$col_Z, input_CRS)
    Input@data$Variable <- bct(Input@data$Z)
    values$lambda <- attr(Input@data$Variable, "lambda")
    values$alpha <- attr(Input@data$Variable, "alpha")
    Input@data$subset <- TRUE
    m1 <- mapview(Input, zcol="Variable", cex=padd(Input@data$Z)*5)
    edits <- callModule(editMod, "editor", m1@map)
    values$Input <- Input
    values$m1 <- m1
    values$edits <- edits
    m1
  })
  output$selectstat <- renderPlot({
    req(myData(), myInput(), values$edits()$finished)
#    print(str(myData()))
    pl <- as(values$edits()$finished, "Spatial")
    o <- !is.na(over(values$Input, pl)[,1])
    req(sum(o) > nmin)
    Input <- values$Input
    Input@data$subset <- ifelse(o, 1, 0)
    values$Input <- Input

    x <- Input[o,]
    v <- sample_variogram(x, "Best")
    vbest <- v$fit[[which.min(v$SSErr)]]
    values$v <- v
    values$vbest <- vbest
    values$BestModel <- names(v$fit)[which.min(v$SSErr)]

    bb <- bbox(x)
    Step <- max(apply(bb, 1, diff)) / Nmax # input$resolution
    xseq <- seq(bb[1,1], bb[1,2], by=Step)
    yseq <- seq(bb[2,1], bb[2,2], by=Step)
    pr <- expand.grid(X=xseq, Y=yseq)
    coordinates(pr) <- ~ X + Y
    proj4string(pr) <- proj4string(x)
    ## prediction grid in convex hull
    tmp <- coordinates(x)
    poly <- tmp[chull(tmp), ]
    poly <- rbind(poly, poly[1, ])
    chpoly <- SpatialPolygons(list(Polygons(list(Polygon(poly)), ID = "poly")))
    proj4string(chpoly) <- proj4string(x)
    inside <- !is.na(over(pr, chpoly))
    prk <- data.frame(coordinates(pr))
    gridded(prk) <- ~ X + Y
    proj4string(prk) <- proj4string(pr)
    k <- krige(Variable ~ 1, locations=x, newdata=prk, model=vbest)
    if (all(is.na(k@data[,1]))) {
        k <- idw(Variable ~ 1, locations=x, newdata=prk, idp=2)
        values$BestModel <- "IDW"
    }
    colnames(k@data) <- c("pred", "var")
    k@data$backtr <- inv_bct(k@data$pred, values$lambda, values$alpha)
    k@data[!inside,] <- NA
    values$r <- raster(k, 3) # backtr
#    values$prk <- prk
#    values$inside <- inside

    plot_density(Input@data$Variable, o,
        main="Normalized data summary")
  })

  observeEvent(input$close, {
    #js$closeWindow()
    stopApp()
  })

## Model

  output$vgramPlot <- renderPlot({
    req(myInput())
    if (!is.null(values$v)) {
        v <- values$v
        vbest <- values$vbest
        BestModel <- values$BestModel
        plot(v$variogram, v$fit[[which.min(v$SSErr)]],
            main=paste0("Model: ", BestModel, " (n=",
            nrow(values$Input[values$Input@data$subset,]), ")"))
    } else NULL

  })

  output$mymap <- renderLeaflet({
    req(myInput())
    if (!is.null(values$r)) {
        Prediction <- values$r
        mapview(Prediction, legend=TRUE,
            alpha.regions=opacity, legend.opacity = 0.8)@map
    } else NULL

  })

  output$downloadData <- downloadHandler(
    filename = function() {
        paste0("kriging-output-", Sys.Date(), ".tif")
    },
    content = function(file) {
        writeRaster(values$r, file, overwrite=TRUE)
    }
  )

  session$onSessionEnded(stopApp)

}

shinyApp(ui, server)
