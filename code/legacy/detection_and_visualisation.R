# Basic Detection and Visualisation of Events
# 06/03/2022
# Jesse Phillips

# This script will use the example dataset within the heatwaveR package to detect
  # and visualise (using ggplot) marine- heatwaves and coldspells.

# Library -----------------------------------------------------------------
library(heatwaveR)
library(dplyr)
library(ggplot2)
library(plotly)

# Familiarise yourself with the necessary heatwaveR functions:
?ts2clm
?detect_event


# Data --------------------------------------------------------------------
heatwaveR::sst_WA # dataset containing SST in Western Australia region from 1982-01-01 to 2020-12-31

head(heatwaveR::sst_WA)


# Calculating MHWs --------------------------------------------------------

# Detect events in a time series
ts <- ts2clm(heatwaveR::sst_WA, climatologyPeriod = c('1982-01-01', '2011-12-31'))
mhw <- detect_event(ts)

# View just a few metrics
mhw$event %>% 
  dplyr::ungroup() %>% 
  dplyr::select(event_no, duration, date_start, date_peak, intensity_max, intensity_cumulative) %>% 
  dplyr::arrange(-intensity_max) %>% 
  head(5)


# Visualising MHWs --------------------------------------------------------

# Default MHW Visuals
  # Used directly on the output of detect_event()
event_line(mhw, spread = 180, metric = 'intensity_max', 
           start_date = '1982-01-01', end_date = '2011-12-31')

lolli_plot(mhw, metric = 'intensity_max')

# Custom MHW Visuals
  # Create ggplot and stack geoms (geom_flame() and geom_lolli() from heatwaveR package)

  # Select region of time series of interest
mhw2 <- mhw$climatology %>% 
  slice(10580:10720)

ggplot(mhw2, aes(x = t, y = temp, y2 = thresh)) + 
  geom_flame() +
  geom_text(aes(x = as.Date("2011-02-25"), y = 25.8, label = "the Destroyer\nof Kelps"))

ggplot(mhw$event, aes(x = date_start, y = intensity_max)) +
  geom_lolli(colour = 'salmon', colour_n = "red", n = 3) +
  geom_text(colour = 'black', aes(x = as.Date("2006-08-01"), y = 5,
                                  label = "The marine heatwaves\ntend to be left skewed in a \ngiven time series")) + 
  labs(y = expression(paste("Max. intensity [", degree, "C]")), x = NULL)

# Spicy MHW Visuals

  # It is necessary to give geom_flame() at least one row on either side of 
    # the event in order to calculate the polygon corners smoothly
mhw_top <- mhw2 %>% 
  slice(5:111)

ggplot(data = mhw2, aes(x = t)) +
  geom_flame(aes(y = temp, y2 = thresh, fill = 'all'), show.legend = T) +
  geom_flame(data = mhw_top, aes(y = temp, y2 = thresh, fill = 'top'), show.legend = T) +
  geom_line(aes(y = temp, colour = 'temp')) +
  geom_line(aes(y = thresh, colour = 'thresh')) +
  geom_line(aes(y = seas, colour = 'seas')) +
  scale_colour_manual(name = "Line Colour",
                      values = c('temp' = 'black',
                                 'thresh' = 'forestgreen',
                                 'seas' = 'grey80')) +
  scale_fill_manual(name = "Event Colour",
                    values = c('all' = 'salmon',
                               'top' = 'red')) +
  scale_x_date(date_labels = '%b %Y') +
  guides(colour = guide_legend(override.aes = list(fill = NA))) +
  labs(y = expression(paste("Temperature [", degree, "C]")), x = NULL)

  # When we don't want to highlight events less than standard 5 day length,
    # allowing for 2 day gap, use arguments n and n_gap respectively
mhw3 <- mhw$climatology %>% 
  slice(850:950)

ggplot(mhw3, aes(x = t, y = temp, y2 = thresh)) + 
  geom_flame(fill = 'black', alpha = 0.5) +
  # Note the use of n = 5 and n_gap = 2
  geom_flame(n = 5, n_gap = 2, fill = 'red', alpha = 0.5) + 
  ylim(c(22,25)) +
  geom_text(colour = 'black', aes(x = as.Date('1984-05-16'), y = 24.5),
            label = "Heat\n\n\nSpike")

  # Should we wish not to highlight any events with geom_lolli()
ggplot(mhw$event, aes(x = date_peak, y = intensity_max)) +
  geom_lolli(colour = 'firebrick') +
  labs(x = "Peak Date",
       y = expression(paste("Max. intensity [", degree, "C]")), x = NULL) +
  theme_linedraw()


# Calculating MCSs --------------------------------------------------------
# The data fed into the functions are the same, only we're searching for values
  # that fall below the 10th percentile, instead of above the 90th percentile

# First, calculate the cold spell
ts_10th <- ts2clm(sst_WA, climatologyPeriod = c('1982-01-10', '2011-12-31'), pctile = 10)
mcs <- detect_event(ts_10th, coldSpells = T)

# Then look at the top few events
mcs$event %>% 
  dplyr::ungroup() %>% 
  dplyr::select(event_no, duration, date_start, date_peak, intensity_mean, intensity_max, intensity_cumulative) %>% 
  dplyr::arrange(intensity_cumulative) %>% 
  head(5)


# Visualising MCSs --------------------------------------------------------

# Default MCS visuals 
event_line(mcs, spread = 200, metric = 'intensity_cumulative', 
           start_date = '1982-01-01', end_date = '2011-12-31')

lolli_plot(mcs, metric = 'intensity_cumulative', xaxis = 'event_no')


# Custom MCS Visuals
  # Select region of time series of interest 
mcs2 <- mcs$climatology %>% 
  slice(2900:3190)

  # Note that one must specify colour other than default 'salmon'
ggplot(mcs2, aes(x = t, y = thresh, y2 = temp)) +
  geom_flame(fill = 'steelblue3')

ggplot(mcs$event, aes(x = date_start, y = intensity_max)) + 
  geom_lolli(colour = 'steelblue3', colour_n = 'navy', n = 3) +
  labs(x = 'Start Date',
       y = expression(paste("Max. intensity [", degree, "C]")))


# Minty MCS Visuals
mcs_top <- mcs2 %>% 
  slice(125:202)

ggplot(data = mcs2, aes(x = t)) +
  geom_flame(aes(y = thresh, y2 = temp, fill = 'all'), show.legend = T) + 
  geom_flame(data = mcs_top, aes(y = thresh, y2 = temp, fill = 'top'), show.legend = T) +
  geom_line(aes(y = temp, colour = 'temp')) + 
  geom_line(aes(y = thresh, colour = 'thresh'), size = 1.0) + 
  geom_line(aes(y = seas, colour = 'seas'), size = 1.2) + 
  scale_colour_manual(name = 'Line Colour',
                      values = c('temp' = 'black','thresh' = 'forestgreen','seas' = 'grey80')) +
  scale_fill_manual(name = 'Event Colour',
                    values = c('all' = 'steelblue3', 'top' = 'navy')) + 
  scale_x_date(date_labels = '%b %Y') + 
  guides(colour = guide_legend(override.aes = list(fill = NA))) + 
  labs(y = expression(paste("Temperature [", degree, "C]")), x = NULL)

ggplot(mcs$event, aes(x = date_start, y = intensity_cumulative)) + 
  geom_lolli(colour = 'steelblue3', colour_n = 'navy', n = 7) + 
  labs(x = "Start Date", y = expression(paste("Cumulative intensity [", degree, "C x days]")))


# Interactive Visuals -----------------------------------------------------
  # This is where plotly package has to be loaded

# Function needed for making geom_flame() work with plotly
geom2trace.GeomFlame <- function(data,
                                 params,
                                 p) {
  
  x <- y <- y2 <- NULL
  
  # Create data.frame for ease of use
  data1 <- data.frame(x = data[["x"]],
                      y = data[["y"]],
                      y2 = data[["y2"]])
  
  # Grab parameters
  n <- params[["n"]]
  n_gap <- params[["n_gap"]]
  
  # Find events that meet minimum length requirement
  data_event <- heatwaveR::detect_event(data1, x = x, y = y,
                                        seasClim = y,
                                        threshClim = y2,
                                        minDuration = n,
                                        maxGap = n_gap,
                                        protoEvents = T)
  
  # Detect spikes
  data_event$screen <- base::ifelse(data_event$threshCriterion == FALSE, FALSE, 
                                    ifelse(data_event$event == FALSE, TRUE, FALSE))
  
  # Screen out spikes
  data1 <- data1[data_event$screen != TRUE,]
  
  # Prepare to find polygon corners
  x1 <- data1$y
  x2 <- data1$y2
  
  # # Find points where x1 is above x2 
  above <- x1 > x2
  above[above == TRUE] <- 1
  above[is.na(above)] <- 0
  
  # Points always intersect when above = TRUE, then FALSE or reverse
  intersect.points <- which(diff(above) != 0)
  
  # Find the slopes for each line segment
  x1.slopes <- x1[intersect.points + 1] - x1[intersect.points]
  x2.slopes <- x2[intersect.points + 1] - x2[intersect.points]
  
  # # Find the intersection for each segment
  x.points <- intersect.points + ((x2[intersect.points] - x1[intersect.points]) / (x1.slopes - x2.slopes))
  y.points <- x1[intersect.points] + (x1.slopes * (x.points - intersect.points))
  
  # Coerce x.points to the same scale as x
  x_gap <- data1$x[2] - data1$x[1]
  x.points <- data1$x[intersect.points] + (x_gap * (x.points - intersect.points))
  
  # Create new data.frame and merge to introduce new rows of data
  data2 <- data.frame(y = c(data1$y, y.points), x = c(data1$x, x.points))
  data2 <- data2[order(data2$x),]
  data3 <- base::merge(data1, data2, by = c("x", "y"), all.y = T)
  data3$y2[is.na(data3$y2)] <- data3$y[is.na(data3$y2)]
  
  # Remove missing values for better plotting
  data3$y[data3$y < data3$y2] <- NA
  missing_pos <- !stats::complete.cases(data3[c("x", "y", "y2")])
  ids <- cumsum(missing_pos) + 1
  ids[missing_pos] <- NA
  
  # Get the correct positions
  positions <- data.frame(x = c(data3$x, rev(data3$x)),
                          y = c(data3$y, rev(data3$y2)),
                          ids = c(ids, rev(ids)))
  
  # Convert to a format geom2trace is happy with
  positions <- plotly::group2NA(positions, groupNames = "ids")
  positions <- positions[stats::complete.cases(positions$ids),]
  positions <- dplyr::left_join(positions, data[,-c(2,3)], by = "x")
  if(length(stats::complete.cases(positions$PANEL)) > 1)
    positions$PANEL <- positions$PANEL[stats::complete.cases(positions$PANEL)][1]
  if(length(stats::complete.cases(positions$group)) > 1)
    positions$group <- positions$group[stats::complete.cases(positions$group)][1]
  
  # Run the plotly polygon code
  if(length(unique(positions$PANEL)) == 1){
    getFromNamespace("geom2trace.GeomPolygon", asNamespace("plotly"))(positions)
  } else{
    return()
  }
}

# Time series
ts_res <- heatwaveR::ts2clm(data = sst_WA, 
                            climatologyPeriod = c("1982-01-01", "2011-12-31"))
ts_res_sub <- ts_res[10500:10800,]

# Flame Figure
p <- ggplot(data = ts_res_sub, aes(x = t, y = temp)) +
  heatwaveR::geom_flame(aes(y2 = thresh), n = 5, n_gap = 2) + 
  geom_line(aes(y = temp)) + 
  geom_line(aes(y = thresh), colour = 'red') + 
  geom_line(aes(y = seas), colour = 'green') + 
  labs(x = "", y = "Temperature (°C)")

# Create interactive visuals
ggplotly(p)
