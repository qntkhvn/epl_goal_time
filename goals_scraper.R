library(tidyverse)
library(rvest)
library(janitor)

get_match_info <- function(season, matchweek) {
  url <- paste0("https://www.transfermarkt.us/premier-league/spieltag/wettbewerb/GB1/plus/?saison_id=",
                season,
                "&spieltag=",
                matchweek)
  match_list <- url %>% 
    read_html() %>% 
    html_table() %>% 
    as_tibble_col(column_name = "match") %>%
    filter(unlist(map(match, ncol)) == 9) %>% 
    mutate(season = paste(season, season + 1, sep = "-"),
           matchweek = matchweek)
  return(match_list)
}

clean_match_info <- function(match_df) {
  
  match_raw <- match_df %>% 
    remove_empty(which = "cols") %>% 
    mutate(across(.cols = everything(), str_squish)) 
  
  match_score <- match_raw[1, ] %>% 
    pivot_longer(cols = everything()) %>% 
    transmute(value = str_remove_all(value, "\\s\\(\\d{1,2}.\\)|\\(\\d{1,2}.\\)\\s")) %>% 
    filter(value != "" & str_detect(value, "|\\d")) %>% 
    pull(value)
  
  home <- match_raw %>% 
    select(goal_scorer = X1, minute = X2, goal_score = X3) %>% 
    filter(str_detect(minute, "'") & goal_score != "") %>% 
    mutate(goal_club = "home")
  
  away <- match_raw %>% 
    select(goal_scorer = X5, minute = X4, goal_score = X3) %>% 
    filter(str_detect(minute, "'") & goal_score != "") %>% 
    mutate(goal_club = "away")
  
  match_clean <- home %>% 
    bind_rows(away) %>% 
    mutate(home_club = match_score[1],
           final_score = match_score[3],
           away_club = match_score[4]) %>% 
    arrange(goal_score) 
  
  return(match_clean)
}

# early seasons with 22 teams and 42 matchweeks

early_list <- list()
early_seasons <- 1992:1994
for(i in 1:length(early_seasons)) {
  early_list[[i]] <- map_df(1:42, get_match_info, season = early_seasons[i]) %>% 
    mutate(match = map(match, clean_match_info)) %>% 
    unnest(cols = c(match))
}

early_df <- early_list %>% 
  bind_rows()

# later seasons with 20 teams and 38 matchweeks

later_list <- list()
later_seasons <- 1995:2020
for(i in 1:length(later_seasons)) {
  later_list[[i]] <- map_df(1:38, get_match_info, season = later_seasons[i]) %>% 
    mutate(match = map(match, clean_match_info)) %>% 
    unnest(cols = c(match))
}

later_df <- later_list %>% 
  bind_rows()

full_df <- early_df %>% 
  bind_rows(later_df) 

# fix full data, mostly string issues

full_df_clean <- full_df %>% 
  mutate(goal_scorer = ifelse(str_detect(goal_scorer, "\\."), 
                              str_sub(goal_scorer, 
                                      end = str_locate(goal_scorer, "\\.")[, 1] - 2),
                              goal_scorer),
         goal_scorer = make_clean_names(goal_scorer, case = "title"),
         goal_scorer = map_chr(map(map(str_split(goal_scorer, " "), unique), paste), toString),
         goal_scorer = str_remove_all(goal_scorer, ",|_|\\d")) %>% 
  select(season, matchweek, home_club, away_club, final_score, goal_club, goal_score, goal_scorer, minute) %>% 
  filter(goal_scorer != "X") %>% 
  mutate(goal_scorer = map_chr(map(map(str_split(goal_scorer, " "), unique), paste), toString),
         goal_scorer = str_remove_all(goal_scorer, ","),
         goal_scorer = str_replace(goal_scorer, "Mc\\s", "Mc"),
         goal_scorer = str_replace(goal_scorer, "Da\\s", "Da"),
         goal_scorer = str_replace(goal_scorer, "\\sn\\s", " N'"),
         goal_scorer = str_replace(goal_scorer, "\\sd\\s", " D'"),
         goal_scorer = str_replace(goal_scorer, "\\sm\\s", " M'"),
         goal_scorer = str_replace(goal_scorer, "\\so\\s", " O'"),
         goal_scorer = str_replace(goal_scorer, "De Merit", "DeMerit"),
         goal_scorer = str_replace(goal_scorer, "N G", "N'G"),
         goal_scorer = str_replace(goal_scorer, "M B", "M'B"),
         goal_scorer = str_replace(goal_scorer, "O Neill", "O'Neill"),
         goal_scorer = str_replace(goal_scorer, "De Andre", "DeAndre"),
         goal_scorer = str_replace(goal_scorer, "Oko", "Jay Oko"),
         minute = ifelse(minute == "0'", "50'",
                         ifelse(minute == "92'", "90+2'", 
                                ifelse(minute == "3+1'", "3'",
                                       ifelse(minute == "6+1'", "6'",
                                              ifelse(minute == "46+1'", "45+1'", 
                                                     ifelse(minute == "120'", "90+4'", minute)))))),
         minute = str_remove(minute, "'"),
         final_score = str_replace(final_score, "postponed", "2:0"))

full_df_clean %>% 
  write_csv("goal_min.csv")
