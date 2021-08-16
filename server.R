library(tidyverse)

data <- read_csv("goal_min.csv") %>%
    mutate(goal_club = ifelse(goal_club == "home", home_club, away_club)) %>%
    select(-goal_score)

function(input, output) {
    # Filter data based on selections
    
    datasetInput <- reactive(data)
    
    output$table <- DT::renderDataTable(DT::datatable({

        if (input$season != "All") {
            data <- data[data$season == input$season, ]
        }
        if (input$matchweek != "All") {
            data <- data[data$matchweek == input$matchweek, ]
        }
        if (input$goal_club != "All") {
            data <- data[data$goal_club == input$goal_club, ]
        }
        data
    }, 
    rownames = FALSE,
    style = "bootstrap",
    options = list(pageLength = 25)))
    
    output$downloadData <- downloadHandler(
        filename = function() {
            paste(input$data, "goals.csv", sep = "")
        },
        content = function(file) {
            write_csv(datasetInput(), file)
        }
    )
    
}