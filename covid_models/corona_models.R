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


setwd('D:/Daniel/corona_modelle') # output folder for plots
library('ggplot2')
library('cowplot')
script_version <- '1.0'

data_source <- 'https://covid.ourworldindata.org/data/owid-covid-data.csv'
datafull <- read.csv(data_source)
#datafull <- read.csv('owid-covid-data.csv') # use local copy for code dev.
datafull$date <- as.Date(datafull$date)

countries <- c('Australia', 'Austria', 'Belgium', 'Brazil', 'Canada', 'China',
               'Denmark', 
               'Finland', 'France', 'Germany', 'Greece', 'India', 'Iceland', 
               'Italy', 'Japan', 'Netherlands', 'New Zealand',
               'Norway', 'Portugal', 'Russia', 'South Africa', 'South Korea',
               'Spain', 'Sweden', 'Switzerland', 'Taiwan', 'United Kingdom',
               'United States')


# plot IFR function for model 1
datafull$date_num <- as.double(datafull$date)
M1_date_ref <- as.double(as.Date('2020-06-01'))
M1_date_plot <- as.Date('2020-01-01')+(0:365)
M1_transition <- 30
M1_start_IFR <- 0.008 
M1_IFR <- M1_start_IFR*0.25*(3+tanh( (M1_date_ref - as.double(M1_date_plot))/M1_transition))
p1 <- ggplot()+
  geom_path(aes(x=M1_date_plot, y=M1_IFR*100), color="black")+
  coord_cartesian(ylim = c(0, 1.5))+ ggtitle('model 1 main assumption')+
  labs( x = "", y = "infection fatality rate in %")
ggsave("_model1_IFR_function.png", plot=p1, width=6, height=4, dpi=150)

# plot compensation function for model 2
# model parameters:
M2_lower <- c(80,0.4)
M2_best_guess <- c(120,0.6)
M2_upper <- c(160,0.8)
pos_rate <- 0.001*(1:500)
M2_ratio_lower = (1 + pos_rate*M2_lower[1])^M2_lower[2]
M2_ratio_best_guess = (1 + pos_rate*M2_best_guess[1])^M2_best_guess[2]
M2_ratio_upper = (1 + pos_rate*M2_upper[1])^M2_upper[2]
p1 <- ggplot()+
  geom_ribbon(aes(x=pos_rate*100, ymax=M2_ratio_upper, ymin=M2_ratio_lower), 
              fill=rgb(.8,.8,.8))+
  geom_path(aes(x=pos_rate*100, y=M2_ratio_best_guess), color=rgb(.5,.5,.5))+
  ggtitle('model 2 main assumption')+
  labs( x = "ratio of positive tests in %", y = "ratio actual / detected cases")
p2 <- p1 + scale_y_continuous(trans='log10') + scale_x_continuous(trans='log10')
#plt <- plot_grid(p1,p2, nrow=1)
ggsave("_model2_ratio_function.png", plot=p2, width=6, height=4, dpi=150)


targetcountry <- 'Germany' # will be overwritten below unless skipping loop for debugging

for (targetcountry in countries) {

# move this country to a separate dataframe (df)
df <- subset(datafull, location == targetcountry)

# cleanup missing data
df$pos_rate_raw <- df$positive_rate
# infer missing positive rate values from previous ones:
for (i in 2:length(df$positive_rate)) {
  if(is.na(df$positive_rate[i]))
    df$positive_rate[i] <- df$positive_rate[i-1]
}
# replace _still_ missing data with 0.2:
df$positive_rate[is.na(df$positive_rate)] <- 0.2
# new_cases, new_deaths:
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

p1 <- ggplot(data=df)+
  geom_path(aes(x=date, y=total_cases/1e6, color='total_cases'))+
  geom_ribbon(aes(x=date, ymax=M2_accum_cases_upper/1e6, ymin=M2_accum_cases_lower/1e6), 
              fill=rgb(.8,.8,.8))+
  geom_path(aes(x=date, y=M2_accum_cases/1e6, color='M2_accum_cases'))+
  geom_path(aes(x=M1_date, y=M1_accum_cases/1e6, color='M1_accum_cases'))+
  labs( x = "", y = "total infections in millions") +
  scale_color_manual(name = NULL,
                     values = c( "total_cases" = "red", 
                                 "M1_accum_cases" = "black", 
                                 "M2_accum_cases" = rgb(.5,.5,.5) ),
                     labels = c("M2_accum_cases" ="model 2: cases = f(tests, pos. ratio)", 
                                "M1_accum_cases" = "model 1: cases = f(deaths, IFR)", 
                                "total_cases" = "official data (new cases: 7-day avg)"))+
  theme(legend.position = c(0.35, 0.85))


p2 <- ggplot(data=df)+
  geom_path(aes(x=date, y=new_cases_smoothed/1e3), color='red')+
  geom_ribbon(aes(x=date, ymax=M2_new_cases_upper/1e3, ymin=M2_new_cases_lower/1e3), 
              fill=rgb(.8,.8,.8))+
  geom_path(aes(x=date, y=M2_new_cases/1e3), color=rgb(.5,.5,.5))+
  geom_path(aes(x=M1_date, y=M1_new_cases/1e3), color='black')+
  labs( x = "", y = "new infections in thousands")
  
p31 <- ggplot(data=df)+
  geom_path(aes(x=date, y=positive_rate*100), color=rgb(.5,.5,.5))+
  geom_path(aes(x=date, y=pos_rate_raw*100), color='red')+
  coord_cartesian(ylim = c(0, 30))+
  labs( x="", y="pos test rate in %")

p32 <- ggplot(data=df)+
  geom_path(aes(x=date, y=M2_R), color=rgb(.5,.5,.5))+ 
  geom_path(aes(x=date, y=R), color='red')+
  coord_cartesian(ylim = c(0, 3))+
  labs( x="", y="reproduction rate R")


# plot instruction taken from https://www.r-bloggers.com/2018/08/beyond-basic-r-plotting-with-ggplot2-and-multiple-plots-in-one-figure/
p3 <- plot_grid(p31, p32, ncol=1)
#p4 <- plot_grid(p41, p42, ncol=1)
p123 <- plot_grid(p1, p2, p3, nrow=1, rel_widths = c(1, 1, 0.6))
title <- ggdraw() + draw_label(paste0(targetcountry, " (",
                                      round(df$population[1]/1e6, digits=1), 
                                      " M population, ", 
                                      round(df$total_deaths[n]/1000, digits=1), 
                                      " k deaths)"), fontface='bold')
info <- ggdraw() + draw_label(paste0('corona_models.R script version ', script_version, 
                                     ' | data from ourworldindata.org: ',
                                     data_source, ' | newest datapoint: ',
                                     max(df$date)), size=8, color=rgb(.5,.5,.5))
plt <- plot_grid(title,p123, info, ncol=1, rel_heights = c(0.1, 1, 0.05))
ggsave(paste(targetcountry, '.png', sep = ""), plot=plt, width=12, height=5, dpi=150)
}
