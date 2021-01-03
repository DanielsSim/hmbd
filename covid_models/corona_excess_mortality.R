# Copyright (c) 2021 Daniel Heinrich
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

# import data
data_source_mortality <- 'https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/excess_mortality/excess_mortality.csv'
data_mort <- read.csv(data_source_mortality)
data_source <- 'https://covid.ourworldindata.org/data/owid-covid-data.csv'
datafull <- read.csv(data_source)

# modify data
data_mort <- subset(data_mort, location !="England & Wales")
data_mort <- subset(data_mort, location !="Northern Ireland")
data_mort$date <- as.Date(data_mort$date)
datafull$date <- as.Date(datafull$date)

data_mort$location <- as.factor(data_mort$location)
datafull$location <- as.factor(datafull$location)
df <- merge(data_mort, datafull)

p1 <- ggplot(data=df)+
  geom_path(aes(x=date, 
                y=Cumulative.excess.deaths..all.ages), 
                color='black')+
  geom_path(aes(x=date, y=total_deaths), color='red')+
  labs( x = "", y = "accumulated deaths")+
  facet_wrap(~location, scales='free_y')

title <- ggdraw() + 
  draw_label('COVID-19 deaths are additional deaths that did not occur in previous years',
             size=18, fontface='bold')
l <- ggdraw() + 
  draw_label('official covid deaths for each country', 
             size=14, color='red', x=0.25, hjust=1)+
  draw_label(paste0('excess mortality (deaths minus ',
                    'average deaths over the last 5 years, ',
                    'negative if fewer people died compared to previous years)'), 
             size=14, color='black', x=0.27, hjust=0)
info <- ggdraw() + 
  draw_label(paste0('corona_excess_mortality.R script version ', script_version,
                    ' | documentation: see hmbd.wordpress.com',
                    ' | data from ourworldindata.org: ',
                    'excess_mortality.csv, owid-covid-data.csv',
                    ' | script run on: ', date()), 
             size=12, color=rgb(.5,.5,.5))
plt <- plot_grid(title, l, p1, info, ncol=1, rel_heights = c(0.06, 0.03, 1, 0.03))
ggsave('_excess_mortality.png', plot=plt, width=16, height=12, dpi=150)
