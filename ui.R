library(shiny)
library(DT)
library(Biobase)
library(shinyjs)
library(plotly)

options(shiny.maxRequestSize = 500*1024^2)

shinyUI(
  fluidPage(
    useShinyjs(),
      fluidRow(align='Top',
      column(2,
             fileInput("SRRcode1", label= h6("SRR"), width="300px", multiple = F)
      ),
      column(2,
             fileInput("SRRcode2", label = h6("SRR"), width = "300px", multiple = F)
             ),
      column(2,
             fileInput("listOfGenes", label=h6("Select List of Genes of Interest"),multiple =F)
      ),
      br(),
      br(),
      actionButton(inputId="SRAbutton", label="Go")
    ),
    br(),
    br(),
    br(),
    br(),
      div(
          h3("Normalized Gene Expression"),
          tabPanel("Gene Expression",DT::dataTableOutput("sra")),
          h3("Dot plots"),
          fluidRow(
            column(2, textInput("geneName", h6("Gene name"), value='', width = "200px")),
            br(),
            br(),
            column(2, actionButton(inputId = "dotPlotButton", label = "Go"))
          ),
          div(
              plotlyOutput("dotPlot",
                           height = "400px",
                           width = "400px")
          ),
          br(),br(),br(),br(),
          selectInput('geneSet', label=h3("Choose Gene Set for ssGSEA"),
                    c("H: Hallmark Gene Sets"="h.all.v6.1.symbols.gmt", "C1: Positional Gene Sets"="c1.all.v6.1.symbols.gmt", "C2: Curated Gene Sets"="c2.all.v6.1.symbols.gmt", 
                      "C3: Motif Gene Sets"="c3.all.v6.1.symbols.gmt", "C4: Computational Gene Sets"="c4.all.v6.1.symbols.gmt","C5: GO gene sets"="c5.all.v6.1.symbols.gmt", 
                      "C6: Oncogenic Signatures"="c6.all.v6.1.symbols.gmt", "C7: Immunologic Signatures"="c7.all.v6.1.symbols.gmt"), selected="h.all.v6.1.symbols.gmt"),
          div(
              mainPanel(
                tabPanel("Enriched Pathways",DT::dataTableOutput('ssgsea')),
                tabPanel("Pathway Heatmap",plotOutput("ssHeatmap", width='100%', height='800px'))
              )
          )
      )
  )
)




    