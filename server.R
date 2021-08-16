library(tidyverse)

data <- read_csv("goal_min.csv") %>% 
    select(-goal_score) %>% 
    mutate(goal_club = ifelse(goal_club == "home", home_club, away_club),
           minute = factor(minute, levels = c(1:45, paste("45", 1:7, sep = "+"),
                                              46:90, paste("90", 1:12, sep = "+"))))

function(input, output) {
    
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
    colnames = c("Season", "Matchweek", "Home Club", "Away Club", 
                 "Final Score", "Goal Club", "Goal Scorer", "Minute"),
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