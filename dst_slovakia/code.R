setwd("C:R")
rm(list = ls()) 
load("C:data.Rda")
View(data)
library(ggplot2)
library(texreg)
library(sandwich)
library(lmtest)
library(gvlma)
library(AER)
library(fUnitRoots)
library(urca)
#adding price variable
library(readxl)
data$mc<-data$Price
price_data<-read_excel("C:price.xlsx", col_types = c("numeric", "numeric"))
data$Price<-price_data$Cena
data$pricecz<-price_data$cenacz
View(data)
#getting rid of missing values

data[is.na(data$brent)== TRUE,4]
data[is.na(data$Price)== TRUE,4]
data[is.na(data$cons)== TRUE,4]

data[is.na(data$temp_BA)== TRUE,4]
data[is.na(data$hum_BA)== TRUE,4]
data[is.na(data$press_BA)== TRUE,4]
data[is.na(data$sun_BA)== TRUE,4]
data[is.na(data$rain_BA)== TRUE,4]
data[is.na(data$intensity_BA)== TRUE,4]

#poprad
data[is.na(data$temp_PO)== TRUE,4]
data[is.na(data$hum_PO)== TRUE,4]
data[is.na(data$press_PO)== TRUE,4]
data[is.na(data$sun_PO)== TRUE,4]
data[is.na(data$rain_PO)== TRUE,4]
data[is.na(data$intensity_PO)== TRUE,4]
#kamenica
data[is.na(data$temp_KA)== TRUE,4]
data[is.na(data$hum_KA)== TRUE,4]
data[is.na(data$press_KA)== TRUE,4]
data[is.na(data$sun_KA)== TRUE,4]
data[is.na(data$rain_KA)== TRUE,4]
data[is.na(data$intensity_KA)== TRUE,4]
#sliac
data[is.na(data$temp_SL)== TRUE,4]
data[is.na(data$hum_SL)== TRUE,4]
data[is.na(data$press_SL)== TRUE,4]
data[is.na(data$sun_SL)== TRUE,4]
data[is.na(data$rain_Sl)== TRUE,4]
data[is.na(data$intensity_SL)== TRUE,4]

data$intensity_BA[is.na(data$intensity_BA)] <- 0
data$intensity_PO[is.na(data$intensity_PO)] <- 0
data$intensity_KA[is.na(data$intensity_KA)] <- 0
data$intensity_SL[is.na(data$intensity_SL)] <- 0
data$brent[is.na(data$brent)]<-1
n1<-69384

data <-data[rowSums(is.na(data))==0,]
View(data)
n2<-68437
(n1-n2)/24
data$brent[(data$brent)==1]<-NA
names(data)
947/n2

##Descriptive statistics
#consumption
mean(data$cons)
sd(data$cons)
min(data$cons)
max(data$cons)
#price
mean(data$Price)
sd(data$Price)
min(data$Price)
max(data$Price)
#brent
mean(data$brent[is.na(data$brent)==0])
sd(data$brent[is.na(data$brent)==0])
min(data$brent[is.na(data$brent)==0])
max(data$brent[is.na(data$brent)==0])

#temperature
mean(data$temp_BA)
sd(data$temp_BA)
min(data$temp_BA)
max(data$temp_BA)
#humidity
mean(data$hum_BA)
sd(data$hum_BA)
min(data$hum_BA)
max(data$hum_BA)
#pressure
mean(data$press_BA)
sd(data$press_BA)
min(data$press_BA)
max(data$press_BA)
#rain
mean(data$rain_BA)
sd(data$rain_BA)
min(data$rain_BA)
max(data$rain_BA)
#sun
mean(data$sun_BA)
sd(data$sun_BA)
min(data$sun_BA)
max(data$sun_BA)
#intensity
mean(data$intensity_BA)
sd(data$intensity_BA)
min(data$intensity_BA)
max(data$intensity_BA)

#Poprad
#temperature
mean(data$temp_PO)
sd(data$temp_PO)
min(data$temp_PO)
max(data$temp_PO)
#humidity
mean(data$hum_PO)
sd(data$hum_PO)
min(data$hum_PO)
max(data$hum_PO)
#pressure
mean(data$press_PO)
sd(data$press_PO)
min(data$press_PO)
max(data$press_PO)
#rain
mean(data$rain_PO)
sd(data$rain_PO)
min(data$rain_PO)
max(data$rain_PO)
#sun
mean(data$sun_PO)
sd(data$sun_PO)
min(data$sun_PO)
max(data$sun_PO)
#intensity
mean(data$intensity_PO)
sd(data$intensity_PO)
min(data$intensity_PO)
max(data$intensity_PO)

#Kamenica nad Cirochou
#temperature
mean(data$temp_KA)
sd(data$temp_KA)
min(data$temp_KA)
max(data$temp_KA)
#humidity
mean(data$hum_KA)
sd(data$hum_KA)
min(data$hum_KA)
max(data$hum_KA)
#pressure
mean(data$press_KA)
sd(data$press_KA)
min(data$press_KA)
max(data$press_KA)
#rain
mean(data$rain_KA)
sd(data$rain_KA)
min(data$rain_KA)
max(data$rain_KA)
#sun
mean(data$sun_KA)
sd(data$sun_KA)
min(data$sun_KA)
max(data$sun_KA)
#intensity
mean(data$intensity_KA)
sd(data$intensity_KA)
min(data$intensity_KA)
max(data$intensity_KA)

#Slia?
#temperature
mean(data$temp_SL)
sd(data$temp_SL)
min(data$temp_SL)
max(data$temp_SL)
#humidity
mean(data$hum_SL)
sd(data$hum_SL)
min(data$hum_SL)
max(data$hum_SL)
#pressure
mean(data$press_SL)
sd(data$press_SL)
min(data$press_SL)
max(data$press_SL)
#rain
mean(data$rain_Sl)
sd(data$rain_Sl)
min(data$rain_Sl)
max(data$rain_Sl)
#sun
mean(data$sun_SL)
sd(data$sun_SL)
min(data$sun_SL)
max(data$sun_SL)
#intensity
mean(data$intensity_SL)
sd(data$intensity_SL)
min(data$intensity_SL)
max(data$intensity_SL)




#log consumption
lcons<-log(data$cons)



# SK vazen? priemer
#vahy
ba<-0.41
sl<-0.29
ka<-0.14
po<-0.16

data$temp_avg<-ba*data$temp_BA+sl*data$temp_SL+ka*data$temp_KA+po*data$temp_PO
data$hum_avg<-ba*data$hum_BA+sl*data$hum_SL+ka*data$hum_KA+po*data$hum_PO
data$press_avg<-ba*data$press_BA+sl*data$press_SL+ka*data$press_KA+po*data$press_PO
data$sun_avg<-ba*data$sun_BA+sl*data$sun_SL+ka*data$sun_KA+po*data$sun_PO
data$rain_avg<-ba*data$rain_BA+sl*data$rain_Sl+ka*data$rain_KA+po*data$rain_PO
data$intensity_avg<-ba*data$intensity_BA+sl*data$intensity_SL+ka*data$intensity_KA+po*data$intensity_PO
data$temp_avg

mean(data$temp_avg)
mean(data$hum_avg)
mean(data$press_avg)
mean(data$sun_avg)
mean(data$rain_avg)
mean(data$intensity_avg)

sd(data$temp_avg)
sd(data$hum_avg)
sd(data$press_avg)
sd(data$sun_avg)
sd(data$rain_avg)
sd(data$intensity_avg)

min(data$temp_avg)
min(data$hum_avg)
min(data$press_avg)
min(data$sun_avg)
min(data$rain_avg)
min(data$intensity_avg)

max(data$temp_avg)
max(data$hum_avg)
max(data$press_avg)
max(data$sun_avg)
max(data$rain_avg)
max(data$intensity_avg)


#Heating and cooling degrees
degrees<-18-(data$temp_avg)
degrees
data$h_deg<-log(ifelse(degrees>0,abs(degrees),1))
data$c_deg<-log(ifelse(degrees<0,abs(degrees),1))

#summer dummy
summer<-ifelse(data$months_num==7 | data$months_num==8 | (data$months_num==6 & data$month_days>21) | (data$months_num==9 & data$month_days<21) ,1,0)
tail(summer)
data$summer<-summer

#HOLIDAYS
data$holidays<-ifelse((data$months_num==1 & data$month_days==1)|(data$months_num==1 & data$month_days==6)|(data$months_num==5 & data$month_days==1)|(data$months_num==5 & data$month_days==8)|(data$months_num==7 & data$month_days==5)|(data$months_num==8 & data$month_days==29)|(data$months_num==9 & data$month_days==1)|(data$months_num==9 & data$month_days==15)|(data$months_num==12 & data$month_days==24) |(data$months_num==12 & data$month_days==25)|(data$months_num==12 & data$month_days==26)|(data$months_num==12 & data$month_days==31)|(data$month_days==2 & data$months_num==4 & data$years==2010) | (data$month_days==5 & data$months_num==4 & data$years==2010) | (data$month_days==22 & data$months_num==4 & data$years==2011) | (data$month_days==25 & data$months_num==4 & data$years==2011) |(data$month_days==6 & data$months_num==4 & data$years==2012) | (data$month_days==9 & data$months_num==4 & data$years==2012) |(data$month_days=29 & data$months_num==3 & data$years==2013) | (data$month_days==1 & data$months_num==4 & data$years==2013)|(data$month_days==18 & data$months_num==4 & data$years==2014) | (data$month_days==21 & data$months_num==4 & data$years==2014) |(data$month_days==3 & data$months_num==4 & data$years==2015) | (data$month_days==6 & data$months_num==4 & data$years==2015) | (data$month_days==25 & data$months_num==3 & data$years==2016) | (data$month_days==28 & data$months_num==3 & data$years==2016) | (data$month_days==14 & data$months_num==4 & data$years==2017) | (data$month_days==17 & data$months_num==4 & data$years==2017),1,0)
#(data$month_days==2 & data$months_num==4 & data$years==2010) | (data$month_days==5 & data$months_num==4 & data$years==2010) |
#(data$month_days==22 & data$months_num==4 & data$years==2011) | (data$month_days==25 & data$months_num==4 & data$years==2011) |
#(data$month_days==6 & data$months_num==4 & data$years==2012) | (data$month_days==9 & data$months_num==4 & data$years==2012) |
#(data$month_days=29 & data$months_num==3 & data$years==2013) | (data$month_days==1 & data$months_num==4 & data$years==2013)
#(data$month_days==18 & data$months_num==4 & data$years==2014) | (data$month_days==21 & data$months_num==4 & data$years==2014) |
#(data$month_days==3 & data$months_num==4 & data$years==2015) | (data$month_days==6 & data$months_num==4 & data$years==2015) |
#(data$month_days==25 & data$months_num==3 & data$years==2016) | (data$month_days==28 & data$months_num==3 & data$years==2016)|
#(data$month_days==14 & data$months_num==4 & data$years==2017) | (data$month_days==17 & data$months_num==4 & data$years==2017)


#fitting sinus on data
cons<-data$cons
time<-c(1:length(data$cons))
plot(time,cons,xlim=c(1, 100))
plot(time,cons,xlim=c(1, 1000))
plot(time,cons,xlim=c(1, 10000))
plot(time,cons)
#1
ssp <- spectrum(cons)  
per <- 1/ssp$freq[ssp$spec==max(ssp$spec)]
reslm <- lm(cons ~ sin(2*pi/per*time)+cos(2*pi/per*time))
summary(reslm)

rg <- diff(range(cons))
plot(cons~time,ylim=c(min(cons)-0.1*rg,max(cons)+0.1*rg))
lines(fitted(reslm)~time,col="red",lty=15)

reslm2 <- lm(cons ~ sin(2*pi/per*time)+cos(2*pi/per*time)+sin(4*pi/per*time)+cos(4*pi/per*time))
summary(reslm2)
lines(fitted(reslm2)~time,col=3)
plot(cons~time,ylim=c(min(cons)-0.1*rg,max(cons)+0.1*rg))
data$sin<-fitted(reslm2) #sinus function fitted on data

#adding temperature squared
data$temp_avg_sq<-data$temp_avg^2








###################################

#FINAL VALIDITY
data_week<-data[data$week==1,]
data_valid<-data_week[data$hours==17,] #tu menim jednotliv? hodiny a pozer?m sa na significanciu
model_val_lm<-lm(log(cons) ~ Price+holidays+sin+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+DST,data=data_valid)
hac_val_test_lm<-coeftest(model_val_lm, vcov.=NeweyWest(model_val_lm, lag=24, prewhite=TRUE, adjust=TRUE, verbose=TRUE))
hac_val_test_lm

###################################








degrees<-18-(data$temp_avg)
data$h_deg<-(ifelse(degrees>0,abs(degrees),1))
data$c_deg<-(ifelse(degrees<0,abs(degrees),1))
data$temp_avg_sq<-data$temp_avg^2


#temperatures

data$temph1<-data$temp_avg*data$hour_1
data$temph2<-data$temp_avg*data$hour_2
data$temph3<-data$temp_avg*data$hour_3
data$temph4<-data$temp_avg*data$hour_4
data$temph5<-data$temp_avg*data$hour_5
data$temph6<-data$temp_avg*data$hour_6
data$temph7<-data$temp_avg*data$hour_7
data$temph8<-data$temp_avg*data$hour_8
data$temph9<-data$temp_avg*data$hour_9
data$temph10<-data$temp_avg*data$hour_10
data$temph11<-data$temp_avg*data$hour_11
data$temph12<-data$temp_avg*data$hour_12
data$temph13<-data$temp_avg*data$hour_13
data$temph14<-data$temp_avg*data$hour_14
data$temph15<-data$temp_avg*data$hour_15
data$temph16<-data$temp_avg*data$hour_16
data$temph17<-data$temp_avg*data$hour_17
data$temph18<-data$temp_avg*data$hour_18
data$temph19<-data$temp_avg*data$hour_19
data$temph20<-data$temp_avg*data$hour_20
data$temph21<-data$temp_avg*data$hour_21
data$temph22<-data$temp_avg*data$hour_22
data$temph23<-data$temp_avg*data$hour_23
data$temph24<-data$temp_avg*data$hour_24

data$temph1_sq<-(data$temp_avg*data$hour_1)^2
data$temph2_sq<-(data$temp_avg*data$hour_2)^2
data$temph3_sq<-(data$temp_avg*data$hour_3)^2
data$temph4_sq<-(data$temp_avg*data$hour_4)^2
data$temph5_sq<-(data$temp_avg*data$hour_5)^2
data$temph6_sq<-(data$temp_avg*data$hour_6)^2
data$temph7_sq<-(data$temp_avg*data$hour_7)^2
data$temph8_sq<-(data$temp_avg*data$hour_8)^2
data$temph9_sq<-(data$temp_avg*data$hour_9)^2
data$temph10_sq<-(data$temp_avg*data$hour_10)^2
data$temph11_sq<-(data$temp_avg*data$hour_11)^2
data$temph12_sq<-(data$temp_avg*data$hour_12)^2
data$temph13_sq<-(data$temp_avg*data$hour_13)^2
data$temph14_sq<-(data$temp_avg*data$hour_14)^2
data$temph15_sq<-(data$temp_avg*data$hour_15)^2
data$temph16_sq<-(data$temp_avg*data$hour_16)^2
data$temph17_sq<-(data$temp_avg*data$hour_17)^2
data$temph18_sq<-(data$temp_avg*data$hour_18)^2
data$temph19_sq<-(data$temp_avg*data$hour_19)^2
data$temph20_sq<-(data$temp_avg*data$hour_20)^2
data$temph21_sq<-(data$temp_avg*data$hour_21)^2
data$temph22_sq<-(data$temp_avg*data$hour_22)^2
data$temph23_sq<-(data$temp_avg*data$hour_23)^2
data$temph24_sq<-(data$temp_avg*data$hour_24)^2


treat_g<-rep(NA,length(data$hour))
for(i in 1:length(data$hour)){
  if (data$hour[i]=="01:00:00"){treat_g[i]<-0}
  else{if (data$hour[i]=="02:00:00"){treat_g[i]<-0}
    else{if (data$hour[i]=="03:00:00"){treat_g[i]<-1}
      else{if (data$hour[i]=="04:00:00"){treat_g[i]<-1}
        else{if (data$hour[i]=="05:00:00"){treat_g[i]<-1}
          else{if (data$hour[i]=="06:00:00"){treat_g[i]<-1}
            else{if (data$hour[i]=="07:00:00"){treat_g[i]<-1}
              else{if (data$hour[i]=="08:00:00"){treat_g[i]<-1}
                else{if (data$hour[i]=="09:00:00"){treat_g[i]<-1}
                  else{if (data$hour[i]=="10:00:00"){treat_g[i]<-1}
                    else{if (data$hour[i]=="11:00:00"){treat_g[i]<-1}
                      else{if (data$hour[i]=="12:00:00"){treat_g[i]<-0}
                        else{if (data$hour[i]=="13:00:00"){treat_g[i]<-0}
                          else{if (data$hour[i]=="14:00:00"){treat_g[i]<-0}
                            else{if (data$hour[i]=="15:00:00"){treat_g[i]<-1}
                              else{if (data$hour[i]=="16:00:00"){treat_g[i]<-1}
                                else{if (data$hour[i]=="17:00:00"){treat_g[i]<-1}
                                  else{if (data$hour[i]=="18:00:00"){treat_g[i]<-1}
                                    else{if (data$hour[i]=="19:00:00"){treat_g[i]<-1}
                                      else{if (data$hour[i]=="20:00:00"){treat_g[i]<-1}
                                        else{if (data$hour[i]=="21:00:00"){treat_g[i]<-1}
                                          else{if (data$hour[i]=="22:00:00"){treat_g[i]<-1}
                                            else{if (data$hour[i]=="23:00:00"){treat_g[i]<-1}
                                              else{if (data$hour[i]=="24:00:00"){treat_g[i]<-0}}}}}}}}}}}}}}}}}}}}}}}}}

data$treat_g<-treat_g
data$Effect<-data$DST*data$treat_g  #24,1,2,12,13,14


data$treat1<-data$treat_g*data$hour_1*data$DST
data$treat2<-data$treat_g*data$hour_2*data$DST
data$treat3<-data$treat_g*data$hour_3*data$DST
data$treat4<-data$treat_g*data$hour_4*data$DST
data$treat5<-data$treat_g*data$hour_5*data$DST
data$treat6<-data$treat_g*data$hour_6*data$DST
data$treat7<-data$treat_g*data$hour_7*data$DST
data$treat8<-data$treat_g*data$hour_8*data$DST
data$treat9<-data$treat_g*data$hour_9*data$DST
data$treat10<-data$treat_g*data$hour_10*data$DST
data$treat11<-data$treat_g*data$hour_11*data$DST
data$treat12<-data$treat_g*data$hour_12*data$DST
data$treat13<-data$treat_g*data$hour_13*data$DST
data$treat14<-data$treat_g*data$hour_14*data$DST
data$treat15<-data$treat_g*data$hour_15*data$DST
data$treat16<-data$treat_g*data$hour_16*data$DST
data$treat17<-data$treat_g*data$hour_17*data$DST
data$treat18<-data$treat_g*data$hour_18*data$DST
data$treat19<-data$treat_g*data$hour_19*data$DST
data$treat20<-data$treat_g*data$hour_20*data$DST
data$treat21<-data$treat_g*data$hour_21*data$DST
data$treat22<-data$treat_g*data$hour_22*data$DST
data$treat23<-data$treat_g*data$hour_23*data$DST
data$treat24<-data$treat_g*data$hour_24*data$DST


treat_g<-rep(NA,length(data$hour))
for(i in 1:length(data$hour)){
  if (data$hour[i]=="01:00:00"){treat_g[i]<-1}
  else{if (data$hour[i]=="02:00:00"){treat_g[i]<-1}
    else{if (data$hour[i]=="03:00:00"){treat_g[i]<-1}
      else{if (data$hour[i]=="04:00:00"){treat_g[i]<-1}
        else{if (data$hour[i]=="05:00:00"){treat_g[i]<-1}
          else{if (data$hour[i]=="06:00:00"){treat_g[i]<-1}
            else{if (data$hour[i]=="07:00:00"){treat_g[i]<-1}
              else{if (data$hour[i]=="08:00:00"){treat_g[i]<-1}
                else{if (data$hour[i]=="09:00:00"){treat_g[i]<-1}
                  else{if (data$hour[i]=="10:00:00"){treat_g[i]<-1}
                    else{if (data$hour[i]=="11:00:00"){treat_g[i]<-1}
                      else{if (data$hour[i]=="12:00:00"){treat_g[i]<-0}
                        else{if (data$hour[i]=="13:00:00"){treat_g[i]<-0}
                          else{if (data$hour[i]=="14:00:00"){treat_g[i]<-0}
                            else{if (data$hour[i]=="15:00:00"){treat_g[i]<-1}
                              else{if (data$hour[i]=="16:00:00"){treat_g[i]<-1}
                                else{if (data$hour[i]=="17:00:00"){treat_g[i]<-1}
                                  else{if (data$hour[i]=="18:00:00"){treat_g[i]<-1}
                                    else{if (data$hour[i]=="19:00:00"){treat_g[i]<-1}
                                      else{if (data$hour[i]=="20:00:00"){treat_g[i]<-1}
                                        else{if (data$hour[i]=="21:00:00"){treat_g[i]<-1}
                                          else{if (data$hour[i]=="22:00:00"){treat_g[i]<-1}
                                            else{if (data$hour[i]=="23:00:00"){treat_g[i]<-1}
                                              else{if (data$hour[i]=="24:00:00"){treat_g[i]<-1}}}}}}}}}}}}}}}}}}}}}}}}}

data$treat_g<-treat_g
data$Effect_2<-data$DST*data$treat_g  #12,13,14
data_week<-data[data$week==1,]

data$treat1_2<-data$treat_g*data$hour_1*data$DST
data$treat2_2<-data$treat_g*data$hour_2*data$DST
data$treat3_2<-data$treat_g*data$hour_3*data$DST
data$treat4_2<-data$treat_g*data$hour_4*data$DST
data$treat5_2<-data$treat_g*data$hour_5*data$DST
data$treat6_2<-data$treat_g*data$hour_6*data$DST
data$treat7_2<-data$treat_g*data$hour_7*data$DST
data$treat8_2<-data$treat_g*data$hour_8*data$DST
data$treat9_2<-data$treat_g*data$hour_9*data$DST
data$treat10_2<-data$treat_g*data$hour_10*data$DST
data$treat11_2<-data$treat_g*data$hour_11*data$DST
data$treat12_2<-data$treat_g*data$hour_12*data$DST
data$treat13_2<-data$treat_g*data$hour_13*data$DST
data$treat14_2<-data$treat_g*data$hour_14*data$DST
data$treat15_2<-data$treat_g*data$hour_15*data$DST
data$treat16_2<-data$treat_g*data$hour_16*data$DST
data$treat17_2<-data$treat_g*data$hour_17*data$DST
data$treat18_2<-data$treat_g*data$hour_18*data$DST
data$treat19_2<-data$treat_g*data$hour_19*data$DST
data$treat20_2<-data$treat_g*data$hour_20*data$DST
data$treat21_2<-data$treat_g*data$hour_21*data$DST
data$treat22_2<-data$treat_g*data$hour_22*data$DST
data$treat23_2<-data$treat_g*data$hour_23*data$DST
data$treat24_2<-data$treat_g*data$hour_24*data$DST

treat_g<-rep(NA,length(data$hour))
for(i in 1:length(data$hour)){
  if (data$hour[i]=="01:00:00"){treat_g[i]<-0}
  else{if (data$hour[i]=="02:00:00"){treat_g[i]<-0}
    else{if (data$hour[i]=="03:00:00"){treat_g[i]<-1}
      else{if (data$hour[i]=="04:00:00"){treat_g[i]<-1}
        else{if (data$hour[i]=="05:00:00"){treat_g[i]<-1}
          else{if (data$hour[i]=="06:00:00"){treat_g[i]<-1}
            else{if (data$hour[i]=="07:00:00"){treat_g[i]<-1}
              else{if (data$hour[i]=="08:00:00"){treat_g[i]<-1}
                else{if (data$hour[i]=="09:00:00"){treat_g[i]<-1}
                  else{if (data$hour[i]=="10:00:00"){treat_g[i]<-1}
                    else{if (data$hour[i]=="11:00:00"){treat_g[i]<-1}
                      else{if (data$hour[i]=="12:00:00"){treat_g[i]<-1}
                        else{if (data$hour[i]=="13:00:00"){treat_g[i]<-1}
                          else{if (data$hour[i]=="14:00:00"){treat_g[i]<-1}
                            else{if (data$hour[i]=="15:00:00"){treat_g[i]<-1}
                              else{if (data$hour[i]=="16:00:00"){treat_g[i]<-1}
                                else{if (data$hour[i]=="17:00:00"){treat_g[i]<-1}
                                  else{if (data$hour[i]=="18:00:00"){treat_g[i]<-1}
                                    else{if (data$hour[i]=="19:00:00"){treat_g[i]<-1}
                                      else{if (data$hour[i]=="20:00:00"){treat_g[i]<-1}
                                        else{if (data$hour[i]=="21:00:00"){treat_g[i]<-1}
                                          else{if (data$hour[i]=="22:00:00"){treat_g[i]<-1}
                                            else{if (data$hour[i]=="23:00:00"){treat_g[i]<-1}
                                              else{if (data$hour[i]=="24:00:00"){treat_g[i]<-0}}}}}}}}}}}}}}}}}}}}}}}}}

data$treat_g<-treat_g
data$Effect_3<-data$DST*data$treat_g  #24,1,2


data$treat1_3<-data$treat_g*data$hour_1*data$DST
data$treat2_3<-data$treat_g*data$hour_2*data$DST
data$treat3_3<-data$treat_g*data$hour_3*data$DST
data$treat4_3<-data$treat_g*data$hour_4*data$DST
data$treat5_3<-data$treat_g*data$hour_5*data$DST
data$treat6_3<-data$treat_g*data$hour_6*data$DST
data$treat7_3<-data$treat_g*data$hour_7*data$DST
data$treat8_3<-data$treat_g*data$hour_8*data$DST
data$treat9_3<-data$treat_g*data$hour_9*data$DST
data$treat10_3<-data$treat_g*data$hour_10*data$DST
data$treat11_3<-data$treat_g*data$hour_11*data$DST
data$treat12_3<-data$treat_g*data$hour_12*data$DST
data$treat13_3<-data$treat_g*data$hour_13*data$DST
data$treat14_3<-data$treat_g*data$hour_14*data$DST
data$treat15_3<-data$treat_g*data$hour_15*data$DST
data$treat16_3<-data$treat_g*data$hour_16*data$DST
data$treat17_3<-data$treat_g*data$hour_17*data$DST
data$treat18_3<-data$treat_g*data$hour_18*data$DST
data$treat19_3<-data$treat_g*data$hour_19*data$DST
data$treat20_3<-data$treat_g*data$hour_20*data$DST
data$treat21_3<-data$treat_g*data$hour_21*data$DST
data$treat22_3<-data$treat_g*data$hour_22*data$DST
data$treat23_3<-data$treat_g*data$hour_23*data$DST
data$treat24_3<-data$treat_g*data$hour_24*data$DST


############################################################################
###########################RESULTS#########################################
############################################################################

data_week<-data[data$week==1,]
degrees<-18-(data$temp_avg)
temp_avg_sq<-data$temp_avg*data$temp_avg
data$h_deg<-log(ifelse(degrees>0,abs(degrees),1))
data$c_deg<-log(ifelse(degrees<0,abs(degrees),1))
#control 12,13,14,24,1,2
model_1<-lm(log(cons)~DST+Price+weekend+holidays+sin+treat_g+Effect+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_1)
hac_model_1<-coeftest(model_1, vcov.=NeweyWest(model_1, lag=24, prewhite=TRUE, adjust=TRUE, verbose=TRUE))
hac_model_1 #overall -1.178  #week -1.20 
#control 12,13,14
model_2<-lm(log(cons)~DST+Price+weekend+holidays+sin+treat_g+Effect_2+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_2)
hac_model_2<-coeftest(model_2, vcov.=NeweyWest(model_2, lag=24, prewhite=TRUE, adjust=TRUE, verbose=TRUE))
hac_model_2 #overall -1.37   #week -1.349
#control 24,1,2
model_3<-lm(log(cons)~DST+Price+weekend+holidays+sin+treat_g+Effect_3+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_3)
hac_model_3<-coeftest(model_3, vcov.=NeweyWest(model_3, lag=24, prewhite=TRUE, adjust=TRUE, verbose=TRUE))
hac_model_3 #overall -0,79  #week -0.863
#control 11,12,13
#-1.27 %  #week -1.21 % #weekend -1.49%



#h/c degrees
#control 12,13,14,24,1,2
model_deg_1<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_deg_1)
hac_model_deg_1<-coeftest(model_deg_1, vcov.=NeweyWest(model_deg_1, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_deg_1 #overall -1.259 
#control 12,13,14
model_deg_2<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect_2+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_deg_2)
hac_model_deg_2<-coeftest(model_deg_2, vcov.=NeweyWest(model_deg_2, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_deg_2 #overall -1.647e-02 
#control 24,1,2
model_deg_3<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect_3+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_deg_3)
hac_model_deg_3<-coeftest(model_deg_3, vcov.=NeweyWest(model_deg_3, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_deg_3 #overall -0,6646
#control 11,12,13
#-1.45%  #week -1.43% #weekend -1.62%



#control 12,13,14,24,1,2
model_hourly_1<-lm(log(cons)~Price+weekend+holidays+DST+sin+treat_g+treat1+treat2+treat3+treat4+treat5+treat6+treat7+treat8+treat9+treat10+treat11+treat12+treat13+treat14+treat15+treat16+treat17+treat18+treat19+treat20+treat21+treat22+treat23+treat24+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+temph1+temph2+temph3+temph4+temph5+temph6+temph7+temph8+temph9+temph10+temph11+temph12+temph13+temph14+temph15+temph16+temph17+temph18+temph19+temph20+temph21+temph22+temph23+temph24+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016++hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_hourly_1)
hac_model_hourly_1<-coeftest(model_hourly_1, vcov.=NeweyWest(model_hourly_1, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_hourly_1 #summary vysledkov.doc

#control 12,13,14
model_hourly_2<-lm(log(cons)~Price+weekend+holidays+DST+sin+treat_g+treat1_2+treat2_2+treat3_2+treat4_2+treat5_2+treat6_2+treat7_2+treat8_2+treat9_2+treat10_2+treat11_2+treat12_2+treat13_2+treat14_2+treat15_2+treat16_2+treat17_2+treat18_2+treat19_2+treat20_2+treat21_2+treat22_2+treat23_2+treat24_2+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+temph1+temph2+temph3+temph4+temph5+temph6+temph7+temph8+temph9+temph10+temph11+temph12+temph13+temph14+temph15+temph16+temph17+temph18+temph19+temph20+temph21+temph22+temph23+temph24+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016++hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_hourly_2)
hac_model_hourly_2<-coeftest(model_hourly_2, vcov.=NeweyWest(model_hourly_2, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_hourly_2 #summary vysledkov.doc

#control 24,1,2
model_hourly_3<-lm(log(cons)~Price+weekend+holidays+DST+sin+treat_g+treat1_3+treat2_3+treat3_3+treat4_3+treat5_3+treat6_3+treat7_3+treat8_3+treat9_3+treat10_3+treat11_3+treat12_3+treat13_3+treat14_3+treat15_3+treat16_3+treat17_3+treat18_3+treat19_3+treat20_3+treat21_3+treat22_3+treat23_3+treat24_3+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+temph1+temph2+temph3+temph4+temph5+temph6+temph7+temph8+temph9+temph10+temph11+temph12+temph13+temph14+temph15+temph16+temph17+temph18+temph19+temph20+temph21+temph22+temph23+temph24+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016++hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_hourly_3)
hac_model_hourly_3<-coeftest(model_hourly_3, vcov.=NeweyWest(model_hourly_3, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_hourly_3 #summary vysledkov.doc


##################### FINAL RESULTS ################################


treat_g<-rep(NA,length(data$hour))
for(i in 1:length(data$hour)){
  if (data$hour[i]=="01:00:00"){treat_g[i]<-1}
  else{if (data$hour[i]=="02:00:00"){treat_g[i]<-1}
    else{if (data$hour[i]=="03:00:00"){treat_g[i]<-1}
      else{if (data$hour[i]=="04:00:00"){treat_g[i]<-1}
        else{if (data$hour[i]=="05:00:00"){treat_g[i]<-1}
          else{if (data$hour[i]=="06:00:00"){treat_g[i]<-1}
            else{if (data$hour[i]=="07:00:00"){treat_g[i]<-1}
              else{if (data$hour[i]=="08:00:00"){treat_g[i]<-1}
                else{if (data$hour[i]=="09:00:00"){treat_g[i]<-1}
                  else{if (data$hour[i]=="10:00:00"){treat_g[i]<-1}
                    else{if (data$hour[i]=="11:00:00"){treat_g[i]<-0}
                      else{if (data$hour[i]=="12:00:00"){treat_g[i]<-0}
                        else{if (data$hour[i]=="13:00:00"){treat_g[i]<-0}
                          else{if (data$hour[i]=="14:00:00"){treat_g[i]<-1}
                            else{if (data$hour[i]=="15:00:00"){treat_g[i]<-1}
                              else{if (data$hour[i]=="16:00:00"){treat_g[i]<-1}
                                else{if (data$hour[i]=="17:00:00"){treat_g[i]<-1}
                                  else{if (data$hour[i]=="18:00:00"){treat_g[i]<-1}
                                    else{if (data$hour[i]=="19:00:00"){treat_g[i]<-1}
                                      else{if (data$hour[i]=="20:00:00"){treat_g[i]<-1}
                                        else{if (data$hour[i]=="21:00:00"){treat_g[i]<-1}
                                          else{if (data$hour[i]=="22:00:00"){treat_g[i]<-1}
                                            else{if (data$hour[i]=="23:00:00"){treat_g[i]<-1}
                                              else{if (data$hour[i]=="24:00:00"){treat_g[i]<-1}}}}}}}}}}}}}}}}}}}}}}}}}

data$treat_g<-treat_g
data$Effect_final<-data$DST*data$treat_g  #24,1,2,12,13,14

data$treat1_final<-data$treat_g*data$hour_1*data$DST
data$treat2_final<-data$treat_g*data$hour_2*data$DST
data$treat3_final<-data$treat_g*data$hour_3*data$DST
data$treat4_final<-data$treat_g*data$hour_4*data$DST
data$treat5_final<-data$treat_g*data$hour_5*data$DST
data$treat6_final<-data$treat_g*data$hour_6*data$DST
data$treat7_final<-data$treat_g*data$hour_7*data$DST
data$treat8_final<-data$treat_g*data$hour_8*data$DST
data$treat9_final<-data$treat_g*data$hour_9*data$DST
data$treat10_final<-data$treat_g*data$hour_10*data$DST
data$treat11_final<-data$treat_g*data$hour_11*data$DST
data$treat12_final<-data$treat_g*data$hour_12*data$DST
data$treat13_final<-data$treat_g*data$hour_13*data$DST
data$treat14_final<-data$treat_g*data$hour_14*data$DST
data$treat15_final<-data$treat_g*data$hour_15*data$DST
data$treat16_final<-data$treat_g*data$hour_16*data$DST
data$treat17_final<-data$treat_g*data$hour_17*data$DST
data$treat18_final<-data$treat_g*data$hour_18*data$DST
data$treat19_final<-data$treat_g*data$hour_19*data$DST
data$treat20_final<-data$treat_g*data$hour_20*data$DST
data$treat21_final<-data$treat_g*data$hour_21*data$DST
data$treat22_final<-data$treat_g*data$hour_22*data$DST
data$treat23_final<-data$treat_g*data$hour_23*data$DST
data$treat24_final<-data$treat_g*data$hour_24*data$DST

data_week<-data[data$week==1,]
#temp
model_final<-lm(log(cons)~DST+Price+sin+treat_g+holidays+weekend+Effect_final+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
model_final_iv<-ivreg(log(cons)~Price+DST+sin+treat_g+holidays+weekend+Effect_final+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23|pricecz+DST+sin+treat_g+holidays+weekend+Effect_final+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_final_iv)
summary(model_final)
hac_model_final<-coeftest(model_final, vcov.=NeweyWest(model_final, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_final #-1.27 %  #week -1.21 % #weekend -1.48%  #UZ RIADNE CENY NIE MC

#deg
model_deg_final<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect_final+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
#model_deg_final_iv<-ivreg(log(cons)~Price+DST+sin+treat_g+weekend+holidays+Effect_final+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23|pricecz+DST+sin+treat_g+weekend+holidays+Effect_final+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
#summary(model_deg_final_iv)
summary(model_deg_final)
hac_model_deg_final<-coeftest(model_deg_final, vcov.=NeweyWest(model_deg_final, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_deg_final #-1.45%  #week -1.43% #weekend -1.61%

#hourly
model_hourly_final<-lm(log(cons)~Price+holidays+weekend+DST+sin+treat_g+treat1_final+treat2_final+treat3_final+treat4_final+treat5_final+treat6_final+treat7_final+treat8_final+treat9_final+treat10_final+treat11_final+treat12_final+treat13_final+treat14_final+treat15_final+treat16_final+treat17_final+treat18_final+treat19_final+treat20_final+treat21_final+treat22_final+treat23_final+treat24_final+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+temph1+temph2+temph3+temph4+temph5+temph6+temph7+temph8+temph9+temph10+temph11+temph12+temph13+temph14+temph15+temph16+temph17+temph18+temph19+temph20+temph21+temph22+temph23+temph24+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016++hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
hac_model_hourly_final<-coeftest(model_hourly_final, vcov.=NeweyWest(model_hourly_final, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_model_hourly_final    

#treat1_final   6.0907e-03  2.5813e-03   2.3595 0.0183010 *  
#treat2_final   4.1540e-03  2.8758e-03   1.4445 0.1486047    
#treat3_final   1.0781e-03  2.7837e-03   0.3873 0.6985458    
#treat4_final  -2.0324e-03  2.7265e-03  -0.7454 0.4560279    
#treat5_final  -5.6842e-03  2.5602e-03  -2.2202 0.0264084 *  
#treat6_final  -1.4461e-02  2.6060e-03  -5.5490 2.885e-08 ***
#treat7_final  -1.0819e-02  3.3939e-03  -3.1879 0.0014340 ** 
#treat8_final   2.0169e-03  3.1584e-03   0.6386 0.5231005    
#treat9_final   1.8112e-03  2.4166e-03   0.7495 0.4535548    
#treat10_final  7.0406e-04  1.4289e-03   0.4927 0.6221937    
#treat14_final  2.9936e-03  1.5375e-03   1.9471 0.0515282 .  
#treat15_final  2.8088e-03  1.9678e-03   1.4274 0.1534800    
#treat16_final -2.6358e-03  2.1285e-03  -1.2383 0.2156116    
#treat17_final -1.8724e-02  2.3550e-03  -7.9507 1.886e-15 ***
#treat18_final -2.9758e-02  2.5920e-03 -11.4805 < 2.2e-16 ***
#treat19_final -2.4153e-02  2.5962e-03  -9.3030 < 2.2e-16 ***
#treat20_final -6.3059e-03  2.4310e-03  -2.5940 0.0094892 ** 
#treat21_final  1.3125e-02  2.2708e-03   5.7798 7.513e-09 ***
#treat22_final  1.2665e-02  2.1659e-03   5.8475 5.016e-09 ***
#treat23_final  9.3714e-03  2.2768e-03   4.1160 3.860e-05 ***
#treat24_final  9.1347e-03  2.3784e-03   3.8406 0.0001228 ***

#week
#treat1_final   9.5928e-03  2.9843e-03   3.2144 0.0013081 ** 
#treat2_final   5.0586e-03  3.3085e-03   1.5290 0.1262831    
#treat3_final   1.7965e-03  3.2371e-03   0.5550 0.5789220    
#treat4_final  -1.3054e-03  3.1719e-03  -0.4115 0.6806741    
#treat5_final  -5.0427e-03  3.0293e-03  -1.6646 0.0959934 .  
#treat6_final  -1.2293e-02  2.9111e-03  -4.2229 2.417e-05 ***
#treat7_final  -7.1731e-03  2.9755e-03  -2.4108 0.0159227 *  
#treat8_final   5.7162e-03  2.7818e-03   2.0548 0.0399000 *  
#treat9_final   3.8602e-03  2.2516e-03   1.7144 0.0864543 .  
#treat10_final  1.7701e-03  1.5918e-03   1.1120 0.2661383    
#treat14_final  2.7880e-03  1.4023e-03   1.9882 0.0467945 *  
#treat15_final  7.9955e-04  1.7296e-03   0.4623 0.6438959    
#treat16_final -4.0264e-03  2.0591e-03  -1.9554 0.0505377 .  
#treat17_final -1.8458e-02  2.6166e-03  -7.0544 1.758e-12 ***
#treat18_final -2.9402e-02  2.9523e-03  -9.9590 < 2.2e-16 ***
#treat19_final -2.2514e-02  3.0754e-03  -7.3207 2.508e-13 ***
#treat20_final -2.9451e-03  2.9031e-03  -1.0145 0.3103633    
#treat21_final  1.8028e-02  2.7520e-03   6.5510 5.776e-11 ***
#treat22_final  1.6974e-02  2.6563e-03   6.3899 1.676e-10 ***
#treat23_final  1.3122e-02  2.7939e-03   4.6965 2.654e-06 ***
#treat24_final  1.3176e-02  2.8785e-03   4.5775 4.717e-06 ***




model_hourly_final$coefficients
effect_all<-c(0.60988,0.41540,0.10781,-0.20324,-0.56842,-1.4461,-1.0819,0.20169,0.18112,0.070406,0,0,0,0.29936,0.28088,-0.26358,-1.8724,-2.9758,-2.4153,-0.63059,1.3125,1.2665,0.93714,0.91347)
effect_save<-c(0,0,0,0,-0.56842,-1.4461,-1.0819,0,0,0,0,0,0,0,0,-0,-1.8724,-2.9758,-2.4153,-0.63059,0,0,0,0)
effect_notsave<-c(0.60988,0,0,0,0,0,0,0,0,0,0,0,0,0.29936,0,-0,-0,-0,-0,-0,1.3125,1.2665,0.93714,0.91347)
effect_notsignif<-c(0,0.41540,0.10781,-0.20324,0,0,0,0.20169,0.18112,0.070406,0,0,0,0.0,0.28088,-0.26358,0,0,-0,-0,0,0,0,0)
c<-c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24)
d<-rep(1,24)

effect_all<-c(0.60988,0.41540,0.10781,-0.20324,-0.56842,-1.4461,-1.0819,0.20169,0.18112,0.070406,0,0,0,0.29936,0.28088,-0.26358,-1.8724,-2.9758,-2.4153,-0.63059,1.3125,1.2665,0.93714,0.91347)
barplot(effect_all,horiz=TRUE,names = c, las = 2,xlim=c(-4,4),ylim=c(1,24),col="orange1")

barplot(effect_notsave,horiz=TRUE,names = c, las = 2,xlim=c(-4,4),ylim=c(1,24),col="orange1")
par(new = TRUE)
barplot(effect_save,horiz=TRUE,names = c, las = 2,xlim=c(-4,4),ylim=c(1,24),col="steelblue")
par(new = TRUE)
barplot(effect_notsignif,horiz=TRUE,names = c, las = 2,xlim=c(-4,4),ylim=c(1,24),col="grey",ylab="Hours",xlab="Effect in %")
legend(2,8, legend=c("Increase", "Decrease","Not Signifcant"),
       fill =c( "orange1","steelblue","grey"))
par(new = TRUE)


####FINANCIAL BENEFITS####
#2011#
simul_2011<-sum(data$cons[data$DST==1&data$y2011==1])*1.0156
cons_diff_2011<-simul_2011-sum(data$cons[data$DST==1&data$y2011==1])
price_2011<-mean(data$Price[data$DST==1&data$y2011==1])
financial_benefits_2011<-cons_diff_2011*price_2011
financial_benefits_2011
personal_benefits_2011<-financial_benefits_2011/5397036
personal_benefits_2011

#2012#
simul_2012<-sum(data$cons[data$DST==1&data$y2012==1])*1.0156
cons_diff_2012<-simul_2012-sum(data$cons[data$DST==1&data$y2012==1])
price_2012<-mean(data$Price[data$DST==1&data$y2012==1])
financial_benefits_2012<-cons_diff_2012*price_2012
financial_benefits_2012
personal_benefits_2012<-financial_benefits_2012/5397036
personal_benefits_2012

#2013#
simul_2013<-sum(data$cons[data$DST==1&data$y2013==1])*1.0156
cons_diff_2013<-simul_2013-sum(data$cons[data$DST==1&data$y2013==1])
price_2013<-mean(data$Price[data$DST==1&data$y2013==1])
financial_benefits_2013<-cons_diff_2013*price_2013
financial_benefits_2013
personal_benefits_2013<-financial_benefits_2013/5397036
personal_benefits_2013

#2014#
simul_2014<-sum(data$cons[data$DST==1&data$y2014==1])*1.0156
cons_diff_2014<-simul_2014-sum(data$cons[data$DST==1&data$y2014==1])
price_2014<-mean(data$Price[data$DST==1&data$y2014==1])
financial_benefits_2014<-cons_diff_2014*price_2014
financial_benefits_2014
personal_benefits_2014<-financial_benefits_2014/5397036
personal_benefits_2014

#2015#
simul_2015<-sum(data$cons[data$DST==1&data$y2015==1])*1.0156
cons_diff_2015<-simul_2015-sum(data$cons[data$DST==1&data$y2015==1])
price_2015<-mean(data$Price[data$DST==1&data$y2015==1])
financial_benefits_2015<-cons_diff_2015*price_2015
financial_benefits_2015
personal_benefits_2015<-financial_benefits_2015/5397036
personal_benefits_2015

#2016#
simul_2016<-sum(data$cons[data$DST==1&data$y2016==1])*101.56/100
cons_diff_2016<-simul_2016-sum(data$cons[data$DST==1&data$y2016==1])
price_2016<-mean(data$Price[data$DST==1&data$y2016==1])
financial_benefits_2016<-cons_diff_2016*price_2016
financial_benefits_2016
personal_benefits_2016<-financial_benefits_2016/5397036
personal_benefits_2016


financial_benefits_2011
financial_benefits_2012
financial_benefits_2013
financial_benefits_2014
financial_benefits_2015
financial_benefits_2016
#2010
simul_2010<-sum(data$cons[data$DST==1&data$y2010==1])*1.0156
cons_diff_2010<-simul_2010-sum(data$cons[data$DST==1&data$y2010==1])
price_2010<-mean(data$Price[data$DST==1&data$y2010==1])
financial_benefits_2010<-cons_diff_2010*price_2010
financial_benefits_2010
personal_benefits_2010<-financial_benefits_2010/5397036
personal_benefits_2010

(sum(data$cons[data$y2016==1])*price_2016)/81000000000
sum(data$cons[data$y2016==1&data$DST==1])*1.0127



##############LATEX################
library(texreg)
library(stargazer)
texreg(hac_model_final)
texreg(hac_model_final,hac_model_deg_final,longtable = TRUE)
texreg(hac_model_hourly_final)
stargazer(model_final,model_deg_final,no.space=TRUE)
stargazer(hac_model_hourly_final,hac_model_hourly_1,hac_model_hourly_2,hac_model_hourly_3,no.space =TRUE)

###########################HEATING COOLING ROBUSTNESS#####################x
degrees<-22-(data$temp_avg)
data$h_deg<-(ifelse(degrees>0,abs(degrees),0))
data$c_deg<-(ifelse(degrees<0,abs(degrees),0))
model_deg_final<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect_final+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_deg_final)

#15 -1.361e-02
#16  -1.428e-02
#17  -1.494e-02
#18  -1.559e-02
#19  -1.620e-02
#20  -1.669e-02
#21 -1.710e-02
#22 -1.725e-02
###########################no cooling degrees###########
degrees<-22-(data$temp_avg)
data$h_deg<-(ifelse(degrees>0,abs(degrees),0))
data$c_deg<-(ifelse(degrees<0,abs(degrees),0))
model_deg_final<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect_final+h_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(model_deg_final)

#15 -1.447e-02
#16  -1.510e-02
#17  -1.566e-02
#18  -1.616e-02
#19  -1.657e-02
#20  -1.686e-02
#21 -1.706e-02
#22 -1.720e-02


#######################################
##################grafy####################
######################################

#grafy s confidence intervalmi

###################################### Visual analysis ##################
#before change
data$month_days<-as.numeric(format(as.Date(data$date,format="%Y-%m-%d"), "%d"))
dcf<-function(d,m,y){
  data$cons[data$month_days==d & data$months_num==m & data$years==y]}
data$cons[data$month_days==1 & data$months_num==4 & data$years==2013]
a<-rep(NA,24)
s<-rep(NA,24)
error<-s<-rep(NA,24)


grg<-data.frame(rbind(dcf(24,3,2014),dcf(25,3,2014),dcf(26,3,2014),dcf(27,3,2014),dcf(28,3,2014)))


lower_grg_1<-rep(NA,24)
upper_grg_1<-rep(NA,24)
for(i in 1:24){
  halo<-cbind(grg$X1,grg$X2,grg$X3,grg$X4,grg$X5,grg$X6,grg$X7,grg$X8,grg$X9,grg$X10,grg$X11,grg$X12,grg$X13,grg$X14,grg$X15,grg$X16,grg$X17,grg$X18,grg$X19,grg$X20,grg$X21,grg$X22,grg$X23,grg$X24)
  a[i] <- mean(halo[,i])
  s[i] <- sd(halo[,i])
  n <- 5
  error[i] <- qnorm(0.975)*s[i]/sqrt(n)
  lower_grg_1[i]<- a[i]-error[i]
  upper_grg_1[i]<-a[i]+error[i]}

mean(halo[,1])

grg_final_1<-data.frame(cbind(dcf(24,3,2014),dcf(25,3,2014),dcf(26,3,2014),dcf(27,3,2014),dcf(28,3,2014)))
grg_final_1$mean<-(dcf(24,3,2014)+dcf(25,3,2014)+dcf(26,3,2014)+dcf(27,3,2014)+dcf(28,3,2014))/5
grg_final_1$lower<-lower_grg_1
grg_final_1$upper<-upper_grg_1
grg_final_1$hour<-seq(1:24) 

p<-ggplot(data=grg_final_1, aes(x=hour)) + geom_point(data=grg_final_1, aes(x=hour, y=mean)) + geom_line(data=grg_final_1, aes(x=hour, y=mean))
p<-p+geom_ribbon(aes(ymin=grg_final_1$lower, ymax=grg_final_1$upper), linetype=2, alpha=0.1)

#after change
grg2<-data.frame(rbind(dcf(31,3,2014),dcf(1,4,2014),dcf(2,4,2014),dcf(3,4,2014),dcf(4,4,2014)))

lower_grg_2<-rep(NA,24)
upper_grg_2<-rep(NA,24)
for(i in 1:24){
  halo<-cbind(grg2$X1,grg2$X2,grg2$X3,grg2$X4,grg2$X5,grg2$X6,grg2$X7,grg2$X8,grg2$X9,grg2$X10,grg2$X11,grg2$X12,grg2$X13,grg2$X14,grg2$X15,grg2$X16,grg2$X17,grg2$X18,grg2$X19,grg2$X20,grg2$X21,grg2$X22,grg2$X23,grg2$X24)
  a[i] <- mean(halo[,i])
  s[i] <- sd(halo[,i])
  n <- 5
  error[i] <- qnorm(0.975)*s[i]/sqrt(n)
  lower_grg_2[i]<- a[i]-error[i]
  upper_grg_2[i]<-a[i]+error[i]}



grg_final_2<-data.frame(cbind(dcf(31,3,2014),dcf(1,4,2014),dcf(2,4,2014),dcf(3,4,2014),dcf(4,4,2014)))
grg_final_2$mean<-(dcf(31,3,2014)+dcf(1,4,2014)+dcf(2,4,2014)+dcf(3,4,2014)+dcf(4,4,2014))/5
grg_final_2$lower<-lower_grg_2
grg_final_2$upper<-upper_grg_2
grg_final_2$hour<-seq(1:24) 
grg_final_2


p2<-ggplot(data=grg_final_2,aes(x=hour)) + geom_point(data=grg_final_2, aes(x=hour, y=mean)) + geom_line(data=grg_final_2, aes(x=hour, y=mean))
p2<-p2+geom_ribbon(aes(ymin=grg_final_2$lower, ymax=grg_final_2$upper), linetype=2, alpha=0.1)


#combined
p_final<-ggplot(data=grg_final_2,aes(x=hour)) + 
  geom_line(data=grg_final_2, aes(x=hour, y=mean),colour="orange1",size=1.2)+
  geom_ribbon(aes(ymin=grg_final_2$lower, ymax=grg_final_2$upper),fill ="orange1", linetype=2, alpha=0.2)+
  geom_line(data=grg_final_1, aes(x=hour, y=mean),colour="steelblue",size=1.2)+
  geom_ribbon(aes(ymin=grg_final_1$lower, ymax=grg_final_1$upper),fill ="steelblue", linetype=2, alpha=0.2)+
  xlab("Hours")+
  ylab("Consumption(MWh)")+
  theme(panel.background = element_rect(fill = "white",
                                        colour = "grey",
                                        size = 1, linetype = "solid"))+
  scale_x_continuous(minor_breaks = seq(0 , 24, 1),breaks=seq(0 , 24, 1))+
  scale_y_continuous(minor_breaks = seq(2600, 3800, 200),breaks =seq(2600, 3800, 200) )
p_final


#####################################
###################################### Visual analysis (ratio) ##################
######################################

#####with
ratio1<-data.frame(rbind(dcf(24,3,2014)/mean(dcf(24,3,2014)[c(12,13,11,24,1,2)]),dcf(25,3,2014)/mean(dcf(25,3,2014)[c(12,13,11,24,1,2)]),dcf(26,3,2014)/mean(dcf(26,3,2014)[c(12,13,11,24,1,2)]),dcf(27,3,2014)/mean(dcf(27,3,2014)[c(12,13,11,24,1,2)]),dcf(28,3,2014)/mean(dcf(28,3,2014)[c(12,13,11,24,1,2)])))
ratio1

lower_r_1<-rep(NA,24)
upper_r_1<-rep(NA,24)
for(i in 1:24){
  halo<-cbind(ratio1$X1,ratio1$X2,ratio1$X3,ratio1$X4,ratio1$X5,ratio1$X6,ratio1$X7,ratio1$X8,ratio1$X9,ratio1$X10,ratio1$X11,ratio1$X12,ratio1$X13,ratio1$X14,ratio1$X15,ratio1$X16,ratio1$X17,ratio1$X18,ratio1$X19,ratio1$X20,ratio1$X21,ratio1$X22,ratio1$X23,ratio1$X24)
  a[i] <- mean(halo[,i])
  s[i] <- sd(halo[,i])
  n <- 5
  error[i] <- qnorm(0.975)*s[i]/sqrt(n)
  lower_r_1[i]<- a[i]-error[i]
  upper_r_1[i]<-a[i]+error[i]}

ratio1<-data.frame(cbind(dcf(24,3,2014)/mean(dcf(24,3,2014)[c(12,13,11,24,1,2)]),dcf(25,3,2014)/mean(dcf(25,3,2014)[c(12,13,11,24,1,2)]),dcf(26,3,2014)/mean(dcf(26,3,2014)[c(12,13,11,24,1,2)]),dcf(27,3,2014)/mean(dcf(27,3,2014)[c(12,13,11,24,1,2)]),dcf(28,3,2014)/mean(dcf(28,3,2014)[c(12,13,11,24,1,2)])))
ratio1$mean<-(dcf(24,3,2014)/mean(dcf(24,3,2014)[c(12,13,11,24,1,2)])+dcf(25,3,2014)/mean(dcf(25,3,2014)[c(12,13,11,24,1,2)])+dcf(26,3,2014)/mean(dcf(26,3,2014)[c(12,13,11,24,1,2)])+dcf(27,3,2014)/mean(dcf(27,3,2014)[c(12,13,11,24,1,2)])+dcf(28,3,2014)/mean(dcf(28,3,2014)[c(12,13,11,24,1,2)]))/5
ratio1$lower<-lower_r_1
ratio1$upper<-upper_r_1
ratio1$hour<-seq(1:24) 
ratio1

#########without
#(dcf(31,3,2014),dcf(1,4,2014),dcf(2,4,2014),dcf(3,4,2014),dcf(4,4,2014)/mean(without_DST_spring[c(12,13,11,24,1,2)])

ratio2<-data.frame(rbind(dcf(31,3,2014)/mean(dcf(31,3,2014)[c(12,13,11,24,1,2)]),dcf(1,4,2014)/mean(dcf(1,4,2014)[c(12,13,11,24,1,2)]),dcf(2,4,2014)/mean(dcf(2,4,2014)[c(12,13,11,24,1,2)]),dcf(3,4,2014)/mean(dcf(3,4,2014)[c(12,13,11,24,1,2)]),dcf(4,4,2014)/mean(dcf(4,4,2014)[c(12,13,11,24,1,2)])))
ratio2
lower_r_2<-rep(NA,24)
upper_r_2<-rep(NA,24)
for(i in 1:24){
  halo<-cbind(ratio2$X1,ratio2$X2,ratio2$X3,ratio2$X4,ratio2$X5,ratio2$X6,ratio2$X7,ratio2$X8,ratio2$X9,ratio2$X10,ratio2$X11,ratio2$X12,ratio2$X13,ratio2$X14,ratio2$X15,ratio2$X16,ratio2$X17,ratio2$X18,ratio2$X19,ratio2$X20,ratio2$X21,ratio2$X22,ratio2$X23,ratio2$X24)
  a[i] <- mean(halo[,i])
  s[i] <- sd(halo[,i])
  n <- 5
  error[i] <- qnorm(0.975)*s[i]/sqrt(n)
  lower_r_2[i]<- a[i]-error[i]
  upper_r_2[i]<-a[i]+error[i]}


ratio2<-data.frame(cbind(dcf(31,3,2014)/mean(dcf(31,3,2014)[c(12,13,11,24,1,2)]),dcf(1,4,2014)/mean(dcf(1,4,2014)[c(12,13,11,24,1,2)]),dcf(2,4,2014)/mean(dcf(2,4,2014)[c(12,13,11,24,1,2)]),dcf(3,4,2014)/mean(dcf(3,4,2014)[c(12,13,11,24,1,2)]),dcf(4,4,2014)/mean(dcf(4,4,2014)[c(12,13,11,24,1,2)])))
ratio2$mean<-(dcf(31,3,2014)/mean((dcf(31,3,2014)[c(12,13,11,24,1,2)]))+dcf(1,4,2014)/mean(dcf(1,4,2014)[c(12,13,11,24,1,2)])+dcf(2,4,2014)/mean(dcf(2,4,2014)[c(12,13,11,24,1,2)])+dcf(3,4,2014)/mean(dcf(3,4,2014)[c(12,13,11,24,1,2)])+dcf(4,4,2014)/mean(dcf(4,4,2014)[c(12,13,11,24,1,2)]))/5
ratio2$lower<-lower_r_2
ratio2$upper<-upper_r_2
ratio2$hour<-seq(1:24) 
ratio2

##dohromady
r_final<-ggplot(data=ratio2,aes(x=hour)) + 
  geom_line(data=ratio2, aes(x=hour, y=mean),colour="orange1",size=1.2)+
  geom_ribbon(aes(ymin=ratio2$lower, ymax=ratio2$upper),fill ="orange1", linetype=2, alpha=0.15)+
  geom_line(data=ratio1, aes(x=hour, y=mean),colour="steelblue",size=1.2)+
  geom_ribbon(aes(ymin=ratio1$lower, ymax=ratio1$upper),fill ="steelblue", linetype=2, alpha=0.15)+
  xlab("Hours")+
  ylab("Ratio of electricity consumption")+
  theme(panel.background = element_rect(fill = "white",
                                        colour = "grey",
                                        size = 1, linetype = "solid"))+
  scale_x_continuous(minor_breaks = seq(0 , 24, 1),breaks=seq(0 , 24, 1))

r_final



p_final
r_final


##############################################################################
################################TESTS#########################################
###############################################################################

#####Serial Corelation###
lagpad <- function(x, k=1) {
  i<-is.vector(x)
  if(is.vector(x)) x<-matrix(x) else x<-matrix(x,nrow(x))
  if(k>0) {
    x <- rbind(matrix(rep(NA, k*ncol(x)),ncol=ncol(x)), matrix(x[1:(nrow(x)-k),], ncol=ncol(x)))
  }
  else {
    x <- rbind(matrix(x[(-k+1):(nrow(x)),], ncol=ncol(x)),matrix(rep(NA, -k*ncol(x)),ncol=ncol(x)))
  }
  if(i) x[1:length(x)] else x
}


u<-summary(model_final)$residuals
u_1<-lagpad(u,k=1)
summary(lm(u~u_1+DST+Price+sin+treat_g+holidays+weekend+Effect_final+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_12+hour_13+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23+hour_24,data=data))
stargazer(lm(u~u_1+DST+Price+sin+treat_g+holidays+weekend+Effect_final+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_12+hour_13+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23+hour_24,data=data),no.space = TRUE)
summary(lm(u~u_1))
library(lmtest)
DW<-dwtest(u~u_1)
DW
#heteroskedasticity
bptest(model_final)
gvlma(x = model_final) 





#hac_3<-coeftest(model_3, vcov.=NeweyWest(model_3, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
#hac_4<-coeftest(model_4, vcov.=NeweyWest(model_4, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
#hac_5<-coeftest(model_5, vcov.=NeweyWest(model_5, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
#hac_6<-coeftest(model_6, vcov.=NeweyWest(model_6, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))


###UNIT ROOT

library(fUnitRoots)
adfTest(data$cons,lags =24)

###STATIONARITY###
#cons
cons2<-lagpad(lcons,1)
summary(lm(lcons~cons2))
#temp
temp2<-lagpad(data$temp_avg,1)
summary(lm(temp_avg~temp2,data=data))
library(urca)
#cons
cons_stat_test<-ur.pp(data$cons,type = "Z-tau",model="trend")
cons_stat_test@cval
cons_stat_test@teststat
PP.test(data$cons)
#temp
temp_stat_test<-ur.pp(data$temp_avg,type = "Z-tau",model="trend")
temp_stat_test@cval
temp_stat_test@teststat
PP.test(data$temp_avg)
#hum
hum_stat_test<-ur.pp(data$hum_avg,type = "Z-tau",model="trend")
hum_stat_test@cval
hum_stat_test@teststat
PP.test(data$hum_avg)
#press
press_stat_test<-ur.pp(data$press_avg,type = "Z-tau",model="trend")
press_stat_test@cval
press_stat_test@teststat
PP.test(data$press_avg)
#sun
sun_stat_test<-ur.pp(data$sun_avg,type = "Z-tau",model="trend")
sun_stat_test@cval
sun_stat_test@teststat
PP.test(data$sun_avg)
#rain
rain_stat_test<-ur.pp(data$rain_avg,type = "Z-tau",model="trend")
rain_stat_test@cval
rain_stat_test@teststat
PP.test(data$rain_avg)
#intensity
intensity_stat_test<-ur.pp(data$intensity_avg,type = "Z-tau",model="trend")
intensity_stat_test@cval
intensity_stat_test@teststat
PP.test(data$intensity_avg)
#brent
brent_stat_test<-ur.pp(data$brent,type = "Z-tau",model="trend")
brent_stat_test@cval
brent_stat_test@teststat
br<-data[is.na(data$brent)==0,]
PP.test(br$brent)
#price
price_stat_test<-ur.pp(data$Price,type = "Z-tau",model="trend")
price_stat_test@cval
price_stat_test@teststat
PP.test(data$Price)
#production
prod_stat_test<-ur.pp(data$production,type = "Z-tau",model="trend")
prod_stat_test@cval
prod_stat_test@teststat
PP.test(data$production)


#heating and cooling degrees
#plot
library(ggplot2)


subset<-data[data$hours==21,]
Consumption<-(subset$cons)
Temperature<-subset$temp_avg
ggplot(subset, aes(y= Consumption, x = Temperature)) +
  geom_point()+
  geom_line(aes(x=18),col="orange1",lwd=1)+
  geom_smooth(aes(Temperature),color="blue3")+
  theme(
    panel.background = element_rect(fill = "white",
                                    colour = "grey",
                                    size = 0.5, linetype = "solid"))+
  scale_x_continuous(breaks=seq(-10 , 38, 2))  
Consumption<-log(subset$cons) #log
#reference value
#hodina->reference temperature
#1 ->16 #13->  21
#2-> 15 #14->  21
#3-> 15 #15-> 22
#4-> 16 #16-> 22
#5-> 16 #17-> 22
#6-> 15 #18-> 21
#7-> 15 #19-> 22
#8->17  #20-> 21
#9-> 18 #21-> 22
#10-> 20 # 22-> 18
#11-> 20  #23-> 16
#12-> 22  #24-> 15



####################################################################
####################################################################
##########################ROBUSTNESS CHECKS############
####################################################################
####################################################################


treat_g<-rep(NA,length(data$hour))
for(i in 1:length(data$hour)){
  if (data$hour[i]=="01:00:00"){treat_g[i]<-1}
  else{if (data$hour[i]=="02:00:00"){treat_g[i]<-1}
    else{if (data$hour[i]=="03:00:00"){treat_g[i]<-1}
      else{if (data$hour[i]=="04:00:00"){treat_g[i]<-1}
        else{if (data$hour[i]=="05:00:00"){treat_g[i]<-1}
          else{if (data$hour[i]=="06:00:00"){treat_g[i]<-1}
            else{if (data$hour[i]=="07:00:00"){treat_g[i]<-1}
              else{if (data$hour[i]=="08:00:00"){treat_g[i]<-1}
                else{if (data$hour[i]=="09:00:00"){treat_g[i]<-1}
                  else{if (data$hour[i]=="10:00:00"){treat_g[i]<-1}
                    else{if (data$hour[i]=="11:00:00"){treat_g[i]<-0}
                      else{if (data$hour[i]=="12:00:00"){treat_g[i]<-0}
                        else{if (data$hour[i]=="13:00:00"){treat_g[i]<-0}
                          else{if (data$hour[i]=="14:00:00"){treat_g[i]<-1}
                            else{if (data$hour[i]=="15:00:00"){treat_g[i]<-1}
                              else{if (data$hour[i]=="16:00:00"){treat_g[i]<-1}
                                else{if (data$hour[i]=="17:00:00"){treat_g[i]<-1}
                                  else{if (data$hour[i]=="18:00:00"){treat_g[i]<-1}
                                    else{if (data$hour[i]=="19:00:00"){treat_g[i]<-1}
                                      else{if (data$hour[i]=="20:00:00"){treat_g[i]<-1}
                                        else{if (data$hour[i]=="21:00:00"){treat_g[i]<-1}
                                          else{if (data$hour[i]=="22:00:00"){treat_g[i]<-1}
                                            else{if (data$hour[i]=="23:00:00"){treat_g[i]<-1}
                                              else{if (data$hour[i]=="24:00:00"){treat_g[i]<-1}}}}}}}}}}}}}}}}}}}}}}}}}

data$treat_g<-treat_g
data$Effect<-data$DST*data$treat_g  #11,12,13



#benchmark without price
Model_1<-lm(log(cons)~DST+weekend+holidays+sin+treat_g+Effect+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(Model_1) #Effect  
hac_Model_1<-coeftest(Model_1, vcov.=NeweyWest(Model_1, lag=24, prewhite=TRUE, adjust=TRUE, verbose=TRUE))
hac_Model_1

#benchmark without price
Model_2<-lm(log(cons)~DST+sin+treat_g+weekend+holidays+Effect+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(Model_2)#Effect      
hac_Model_2<-coeftest(Model_2, vcov.=NeweyWest(Model_2, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_Model_2

#Model 1
h_deg_sq = data$h_deg^2
c_deg_sq = data$c_deg^2
Model_3<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect+h_deg+h_deg_sq+c_deg+c_deg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(Model_3)#Effect   
hac_Model_3<-coeftest(Model_3, vcov.=NeweyWest(Model_3, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_Model_3

#Model 2
degrees_h<-15-(data$temp_avg)
degrees_c<-21-(data$temp_avg)
data$h_deg_new<-(ifelse(degrees_h>0,abs(degrees_h),0))
data$c_deg_new<-(ifelse(degrees_c<0,abs(degrees_c),0))
Model_4<-lm(log(cons)~DST+Price+sin+treat_g+weekend+holidays+Effect+h_deg_new+c_deg_new+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+summer+jan+feb+mar+apr+may+jun+jul+sep+oct+nov+dec+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(Model_4)#Effect     
hac_Model_4<-coeftest(Model_4, vcov.=NeweyWest(Model_4, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_Model_4

#Model 3
#sin only
ssp_cos <- spectrum(cons)  
per <- 1/ssp_cos$freq[ssp_cos$spec==max(ssp_cos$spec)]
reslm_sin_new <- lm(cons ~ sin(2*pi/per*time))
summary(reslm_cos)
rg_cos <- diff(range(cons))
plot(cons~time,ylim=c(min(cons)-0.1*rg_cos,max(cons)+0.1*rg_cos))
lines(fitted(reslm_cos)~time,col=4,lty=2)
data$sin_new<-fitted(reslm_sin_new)

#cos
ssp_cos <- spectrum(cons)  
per <- 1/ssp_cos$freq[ssp_cos$spec==max(ssp_cos$spec)]
reslm_cos <- lm(cons ~ cos(2*pi/per*time))
summary(reslm_cos)
rg_cos <- diff(range(cons))
plot(cons~time,ylim=c(min(cons)-0.1*rg_cos,max(cons)+0.1*rg_cos))
lines(fitted(reslm_cos)~time,col=4,lty=2)
data$cos<-fitted(reslm_cos)

Model_5<-lm(log(cons)~DST+Price+weekend+holidays+sin_new+cos+treat_g+Effect+temp_avg+temp_avg_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(Model_5) #Effect    
hac_Model_5<-coeftest(Model_5, vcov.=NeweyWest(Model_5, lag=24, prewhite=TRUE, adjust=TRUE, verbose=TRUE))
hac_Model_5

#Model 4: 
Model_6<-lm(log(cons)~DST+Price+sin_new+cos+treat_g+weekend+holidays+Effect+h_deg+c_deg+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(Model_6) #Effect      
hac_Model_6<-coeftest(Model_6, vcov.=NeweyWest(Model_6, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_Model_6

#Model 5
data$h_deg_new_sq<-data$h_deg_new^2
data$c_deg_new_sq<-data$c_deg_new^2

Model_7<-lm(log(cons)~DST+sin_new+cos+treat_g+weekend+holidays+Effect+h_deg_new+h_deg_new_sq+c_deg_new+c_deg_new_sq+hum_avg+press_avg+sun_avg+rain_avg+intensity_avg+y2010+y2011+y2012+y2013+y2014+y2015+y2016+hour_1+hour_2+hour_3+hour_4+hour_5+hour_6+hour_7+hour_8+hour_9+hour_10+hour_11+hour_12+hour_14+hour_15+hour_16+hour_17+hour_18+hour_19+hour_20+hour_21+hour_22+hour_23,data=data)
summary(Model_7) #Effect  
hac_Model_7<-coeftest(Model_7, vcov.=NeweyWest(Model_7, lag=24, prewhite=FALSE, adjust=TRUE, verbose=TRUE))
hac_Model_7



