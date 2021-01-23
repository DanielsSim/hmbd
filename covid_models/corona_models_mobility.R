# Copyright (c) 2020 Daniel Heinrich
#   
#   Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#   
#   The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


setwd('D:/Daniel/corona_modelle/mobility') # output folder for plots
library('ggplot2')
library('cowplot')
library(tidyquant)
script_version <- '1.0'

library(sars2pack)
mobility <- google_mobility_data(accept_terms = TRUE)
npi <- acaps_government_measures_data()

data_source <- 'https://covid.ourworldindata.org/data/owid-covid-data.csv'
datafull <- read.csv(data_source)
#datafull <- read.csv('owid-covid-data.csv') # use local copy for code dev.
datafull$date <- as.Date(datafull$date)

countries <- c('Australia', 'Austria', 'Belgium', 'Brazil', 'Canada', 'Denmark', 
               'Finland', 'France', 'Germany', 'Greece', 'India', 'Israel',
               'Italy', 'Ireland','Japan', 'Netherlands', 'New Zealand',
               'Norway', 'Portugal', 'South Korea',
               'Spain', 'Sweden', 'Switzerland', 'United Kingdom',
               'United States')


# define IFR function for model 1
M1_date_ref <- as.double(as.Date('2020-06-01'))
M1_transition <- 30
M1_start_IFR <- 0.008 

# define compensation function for model 2
# model parameters:
M2_lower <- c(80,0.4)
M2_best_guess <- c(120,0.6)
M2_upper <- c(160,0.8)


targetcountry <- 'Germany' # will be overwritten below unless skipping loop for debugging

for (targetcountry in countries) {
  
  # move this country to a separate dataframe (df)
  df <- subset(datafull, location == targetcountry)
  df_mob <- subset(mobility, country_region == targetcountry & admin_level==0)
  df_npi <- subset(npi, country==targetcountry)
  df_npi$date <- as.Date(df_npi$date_implemented)
  df_npi$meas <- as.factor(df_npi$measure)

  # remove empty-data rows at end of dataframe
  while (is.na(df$new_cases[length(df$new_cases)])) {
    df <- df[-length(df$new_cases),]
  }
  
  # cleanup missing data
  df$pos_rate_raw <- df$positive_rate
  # infer missing positive rate values from next one (for up to 7 days)
  j <- 0
  for (i in (length(df$positive_rate)-1):1) {
    if(is.na(df$positive_rate[i])) {
      if (j < 7) 
        df$positive_rate[i] <- df$positive_rate[i+1]
      j <- j+1
    }
    else j <- 0
  }
  # infer still missing positive rate values from previous ones:
  for (i in 2:length(df$positive_rate)) {
    if(is.na(df$positive_rate[i]))
      df$positive_rate[i] <- df$positive_rate[i-1]
  }
  # replace _still_ missing data with 0.2:
  df$positive_rate[is.na(df$positive_rate)] <- 0.2
  
  # same cleanup process for vaccinations:
  for (i in 2:length(df$total_vaccinations)) {
    if(is.na(df$total_vaccinations[i]))
      df$total_vaccinations[i] <- df$total_vaccinations[i-1]
  }
  df$total_vaccinations[is.na(df$total_vaccinations)] <- 0
  
  
  # new_cases, new_deaths: remove na's
  df$new_cases_smoothed[is.na(df$new_cases_smoothed)] <- 0
  df$new_deaths_smoothed[is.na(df$new_deaths_smoothed)] <- 0

  # estimate cases with various models
  
  # raw data: reproduction rate R
  n <- length(df$new_cases_smoothed) # helpful for R estimates below
  n2 <- n-4
  df$R <- c(rep(0,4),(df$new_cases_smoothed[5:n]/df$new_cases_smoothed[1:n2])) 
  
  # model 1: estimate infections from a fatality rate of 0.6%
  df$M1_IFR <- M1_start_IFR*0.25*(3+tanh( (M1_date_ref 
                                           - as.double(df$date))/M1_transition))
  df$M1_new_cases <- df$new_deaths_smoothed / df$M1_IFR
  df$M1_accum_cases <- cumsum(df$M1_new_cases)
  df$M1_date <- df$date - 14
  df$M1_R <- c(rep(0,4),(df$M1_new_cases[5:n]/df$M1_new_cases[1:n2])) 
  # (reproduction rate std assumption: 4 days on avg)
  
  # model 2: estimate infections from cases and a test ratio-dependent factor
  df$M2_new_cases <- df$new_cases_smoothed * (1 + 
                                                df$positive_rate*M2_best_guess[1])^M2_best_guess[2]
  df$M2_new_cases_lower <- df$new_cases_smoothed * (1 + 
                                                      df$positive_rate*M2_lower[1])^M2_lower[2]
  df$M2_new_cases_upper <- df$new_cases_smoothed * (1 + 
                                                      df$positive_rate*M2_upper[1])^M2_upper[2]
  df$M2_accum_cases <- cumsum(df$M2_new_cases)
  df$M2_accum_cases_lower <- cumsum(df$M2_new_cases_lower)
  df$M2_accum_cases_upper <- cumsum(df$M2_new_cases_upper)
  df$M2_R <- c(rep(0,4),(df$M2_new_cases[5:n]/df$M2_new_cases[1:n2])) 
  
  # plot results
  p2 <- ggplot(data=df)+
    geom_path(aes(x=date, y=new_cases_smoothed, color='new_cases_smoothed'))+
    geom_path(aes(x=date, y=M2_new_cases, color="M2_new_cases"))+
    labs( x = "", y = "new infections")+
    scale_color_manual(name = "1-week mov. avg.",
                       values = c( "new_cases_smoothed" = "red", 
                                   "M2_new_cases" = rgb(.5,.5,.5)),
                       labels = c("M2_new_cases" ="infections (model 2)", 
                                  "new_cases_smoothed" = "official cases"))+ 
    theme(legend.position = c(0.92, 0.5))+
    coord_cartesian(ylim = c(10,max(df$M2_new_cases_upper)), xlim = c(as.Date('2020-03-01'), max(df$date)+60))+
    scale_y_continuous(trans='log10')
  
  p3 <- ggplot(data=df_mob)+
    geom_ma(aes(x=date,y=percent_change_from_baseline+100,
                  color = places_category), n=14, linetype="solid")+
    labs( x = "", y = "%")+
    theme(legend.position = c(0.92, 0.5))+
    coord_cartesian(xlim = c(as.Date('2020-03-01'), max(df$date)+60), ylim=c(20,400))+
    labs(color = "2-week mov. avg.")+
    scale_y_continuous(trans='log10')
  
  
  
  p4 <- ggplot(data=df)+
    geom_path(aes(x=date, y=M2_R), color=rgb(.5,.5,.5))+ 
    geom_path(aes(x=date, y=R), color='red')+
    coord_cartesian(ylim = c(0.4, 6), xlim = c(as.Date('2020-03-01'), max(df$date)+60))+
    labs( x="", y="reproduction rate R")+
    scale_y_continuous(trans='log10')
  
  
  # plot instruction taken from https://www.r-bloggers.com/2018/08/beyond-basic-r-plotting-with-ggplot2-and-multiple-plots-in-one-figure/
  p123 <- plot_grid(p2, p4, p3, ncol=1, rel_widths = c(1, 1, 1))
  title <- ggdraw() + draw_label(paste0(targetcountry, " (",
                                        round(df$population[1]/1e6, digits=1), 
                                        " M population, ", 
                                        round(max(df$total_deaths, na.rm=TRUE)/1000, digits=1), 
                                        " k deaths)"), fontface='bold')
  info <- ggdraw() + draw_label(paste0('corona_models_mobility.R script version ', script_version,
                                       ' | documentation: see hmbd.wordpress.com',
                                       ' | data from ourworldindata.org: ',
                                       data_source, ' | newest datapoint: ',
                                       max(df$date)), size=8, color=rgb(.5,.5,.5))
  info2 <- ggdraw() + draw_label(paste0('mobility data from Google mobility dataset', 
                                        ', https://www.google.com/covid19/mobility/'),
                                 size=8, color=rgb(.5,.5,.5))
  info3 <- ggdraw() + draw_label("",
                                 size=8, color=rgb(.5,.5,.5))
  plt <- plot_grid(title,p123, info, info2, info3, ncol=1, rel_heights = c(0.05, 1, 0.03, 0.03, 0.03))
  ggsave(paste(targetcountry, '.png', sep = ""), plot=plt, width=10, height=6, dpi=150)
}
