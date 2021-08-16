library(tidyverse)
library(shinythemes)

data <- read_csv("goal_min.csv") %>% 
    mutate(goal_club = ifelse(goal_club == "home", home_club, away_club))



fluidPage(
    
    theme = shinytheme("flatly"),
    
    titlePanel("EPL Goal Scoring Time"),
    
    sidebarLayout(
        
        sidebarPanel(
            
            p("This Shiny app contains data on all goal scoring instances in the English Premier League, 
              from the inaugural season in 1992–93, to 2020-21, the most recently completed season."),
            
            HTML("<p>The data were obtained from <a href='https://www.transfermarkt.us/premier-league/spieltag/wettbewerb/GB1'>transfermarkt</a>,
                 and the scraping script is available on <a href='https://github.com/qntkhvn'>GitHub</a>.
                 In this dataset, the most important feature is the scoring time (in minute) of each goal. As improbable as it may seem, 
                 
                 this piece of information does not come in a nicely clean, publicly data format. </p>"),
            
            HTML("<p>(A personal story: When I was working on my <a href='https://bookdown.org/theqdata/honors_thesis'>undergraduate honors thesis</a> on modeling EPL goal scoring, 
                 due to the amount of time and most importantly data science skills I had back then, I couldn't either find an dataset on scoring time, or
                 scrape the extremely messy data from the web, so I ended up collecting the data by hand. Thus, this is my motivation behind this app.)</p>"),
            
            p("Download the full data here"),
            
            downloadButton("downloadData", ".csv")
        ),
        
        mainPanel(
            
            fluidRow(
                column(4,
                       selectInput("season",
                                   "Season",
                                   c("All",
                                     unique(as.character(data$season))))
                ),
                column(4,
                       selectInput("matchweek",
                                   "Matchweek",
                                   c("All",
                                     unique(as.character(data$matchweek))))
                ),
                column(4,
                       selectInput("goal_club",
                                   "Club",
                                   c("All",
                                     sort(unique(as.character(data$goal_club)))))
                )
            ),
            DT::dataTableOutput("table"),
            strong("*Last Updated August 15, 2021")
        )
    )
    
    # Create a new Row in the UI for selectInputs

    # Create a new row for the table.
)