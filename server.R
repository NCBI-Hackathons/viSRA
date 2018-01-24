library(shiny)
library(shinyjs)
library(DT)
library(GSVA)
library(GSEABase)
library(pheatmap)
library(ggplot2)
library(dplyr)
library(reshape2)
library(plotly)

# setwd('/Users/valdezkm/Documents/Hackathon')
# load('./viSRA_practice_data.RData')

shinyServer(function(input, output) {
  observeEvent(input$SRAbutton,
    isolate({
    listGenes = read.delim(input$listOfGenes$datapath, sep = '\n', header = F)
    write.table(listGenes, file = 'gene_name', sep = "\n", row.names = F, quote = F, col.names = F)
    output$msg <- renderText({
      while (!file.exists("gene_name")) {
        Sys.sleep(2)
      }
      cmd <- paste("", "sudo docker run -it -v `pwd`/data:/data biocontainers/desra desra_main.sh -d /data/blastdb/ref_GRCh38.p7_top_level -j 00002 -t 16")
      cmd_con <- pipe(cmd)
      readLines(cmd_con)
    })
  })
  )
  observeEvent(
    input$SRAbutton,
    isolate({ 
      write.csv(expression, file='normalized_data.csv')
      expression
    })
  )
  observeEvent(
    input$SRAbutton,
    isolate({
      SRA1 = read.delim(input$SRRcode1$datapath, sep = '\n', header = F)
      SRA2 = read.delim(input$SRRcode2$datapath, sep = '\n', header = F)
      write.table(SRA1, file = 'sra_cond1', sep = "\n", row.names = F, quote = F, col.names = F)
      write.table(SRA1, file = 'sra_cond2', sep = "\n", row.names = F, quote = F, col.names = F)
    })
  )
  observeEvent(input$SRAbutton,
    isolate({
    dat <- as.data.frame(expression)
    listGenes = read.delim(input$listOfGenes$datapath, sep = '\n', header = F)
    for (i in 1:length(listGenes[,1])) {
      gene = listGenes[i,1]
      jpeg(file = paste0(gene,".jpeg"))
      print(dat %>%
        mutate(geneID = rownames(dat)) %>%
        filter(geneID == toupper(gene)) %>%
        melt() %>%
        ggplot(aes(x = variable, y = value)) +
        geom_point() +
        theme_bw() +
        xlab("SRA ID") +
        ylab("Expression (TPM)") +
        ggtitle(paste(gene)))
      dev.off()
    }
    })
  )
  output$sra=DT::renderDataTable(DT::datatable(
    {
    expression
    })
  )
  output$ssgsea=DT::renderDataTable(DT::datatable(
    {
      geneSet =  getGmt(input$geneSet)
      ssResults = gsva(as.matrix(expression),geneSet,method='ssgsea')
      write.csv(ssResults, file = 'ssGSEA_pathways.csv')
    })
  )
  output$dotPlot <- renderPlotly({
    input$dotPlotButton
    isolate({
      dat <- as.data.frame(expression)
      d <- dat %>%
        mutate(geneID = rownames(dat)) %>%
        filter(geneID == toupper(input$geneName)) %>%
        melt() %>%
        ggplot(aes(x = variable, y = value)) +
        geom_point() +
        theme_bw() +
        xlab("SRA ID") +
        ylab("Expression (TPM)") +
        ggtitle(paste(input$geneName))
      d <- plotly_build(d)
      d$elementId <- NULL
      print(d)
    })
  })
  output$ssHeatmap=renderPlot(
    {
      geneSet =  getGmt(input$geneSet)
      ssResults = gsva(as.matrix(expression),geneSet,method='ssgsea')

      ssResults = ssResults[order(abs(ssResults[,1]-ssResults[,2]),decreasing = T),]
      ssResults = ssResults[1:50,]

      pheatmap(ssResults,drop_levels=TRUE,fontsize_col=10, fontsize_row = 7)
    })
})

