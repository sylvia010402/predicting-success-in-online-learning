install.packages("mice")
install.packages("missForest")
install.packages("paletteer")
install.packages("patchwork")
install.packages("lubridate")
library(lubridate)
library(patchwork)
library(paletteer)
library(mice)
library(missForest)
library(ggplot2)
library("RColorBrewer")
display.brewer.all()

MOOC <- read.csv("/Users/le/Desktop/2025 Spring/S022_R_Project/data/MOOC.csv")
summary(MOOC)
str(MOOC)


# Check for variable types
MOOC %>% 
  summarise(across(everything(), ~ class(.))) %>% 
  pivot_longer(everything(),
               names_to = "variable",
               values_to = "class") %>% 
  print(width = Inf)


#print out a table showing missingness
MOOC %>% 
  summarise(across(everything(), list(
    missing_count = ~sum(is.na(.)),
    missing_prop  = ~mean(is.na(.))
  ))) %>%
  pivot_longer(everything(),
               names_to = c("variable", ".value"),
               names_sep = "_missing_") %>% 
  print(n = Inf)

# #binary variables
# MOOC %>% select(c("registered", "viewed", "explored", "certified", "incomplete_flag")) %>% 
#   summary()
# 
# #numerical variables
# MOOC %>% select ( c( "YoB", "grade", "nevents", "nforum_posts",
#                   "ndays_act", "nplay_video", "nchapters")) %>% 
#   summary()
# 
# #categorical variables
# MOOC %>% select(c( "course_id", "userid_DI", "final_cc_cname_DI", 
#                   "start_time_DI", "last_event_DI", "LoE_DI", "gender")) %>% 
#   summary()
# 

#variable conversions
#convert to dates
MOOC$start_time_DI <- mdy(MOOC$start_time_DI)
MOOC$last_event_DI <- mdy(MOOC$last_event_DI)

# #convert to numeric (for imputation)
MOOC$last_event_DI_numeric <- as.numeric(MOOC$last_event_DI)

#convert integer into binary variables
MOOC$registered <- ifelse(MOOC$registered == 1, 1, 0)
MOOC$viewed <- ifelse(MOOC$viewed == 1, 1, 0)
MOOC$explored <- ifelse(MOOC$explored == 1, 1, 0)
MOOC$certified <- ifelse(MOOC$certified == 1, 1, 0)

# #convert to factors
MOOC$registered <- as.factor(MOOC$registered)
MOOC$viewed <- as.factor(MOOC$viewed)
MOOC$explored <- as.factor(MOOC$explored)
MOOC$certified <- as.factor(MOOC$certified)

summary(MOOC$nplay_video)
# #if need to discard any values a priori
# nearZeroVar(MOOC, saveMetrics = TRUE)
# mice::md.pattern()

summary(MOOC$LoE_DI)
str(MOOC$LoE_DI)
unique(MOOC$LoE_DI)
MOOC$LoE_DI[MOOC$LoE_DI == ""] <- NA  # Replace "" with NA



summary(MOOC$gender)
str(MOOC$gender)
unique(MOOC$gender)
MOOC$gender[MOOC$gender == ""] <- NA  # Replace "" with NA

#convert into factors 
MOOC <- MOOC %>%
  mutate(across(where(is.character), as.factor))


#imcomplete flag
MOOC <- MOOC %>%
  mutate(incomplete_flag = ifelse(is.na(incomplete_flag), 0, incomplete_flag))
MOOC <- MOOC %>% filter(incomplete_flag == 0)





#############################
#1. winsorizing

  #YoB
# low_YoB <- quantile(MOOC$YoB, 0.01, na.rm = TRUE)
high_YoB <- quantile(MOOC$YoB, 0.99, na.rm = TRUE)
MOOC$YoB_winsor <- pmin(MOOC$YoB, high_YoB)
# MOOC$YoB_winsor <- pmin( pmax(MOOC$YoB, low_YoB), high_YoB)
summary(MOOC$YoB)
summary(MOOC$YoB_winsor)

#plot the distribution for discrete variable
ggplot(MOOC, aes(x = YoB_winsor)) +
  geom_histogram()
  


  #nevents
# Winsorize at 10st and 90th percentiles
# low_event <- quantile(MOOC$nevents, 0.1, na.rm = TRUE)
high_event <- quantile(MOOC$nevents, 0.9, na.rm = TRUE)
MOOC$nevents_winsor <- pmin(MOOC$nevents, high_event)
summary(MOOC$nevents)
summary(MOOC$nevents_winsor)

#plot the distribution
ggplot(MOOC, aes(x = nevents_winsor)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "lightblue", color = "black") 

  
  #nplay_video
summary(MOOC$nplay_video)
high_nvideo <- quantile(MOOC$nplay_video, 0.9, na.rm = TRUE)
MOOC$nplay_video_winsor <- pmin(MOOC$nplay_video, high_nvideo)
summary(MOOC$nplay_video)
summary(MOOC$nplay_video_winsor)

  #plot the distribution
ggplot(MOOC, aes(x = nplay_video_winsor)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "lightblue", color = "black") 


  #grade
high_grade <- quantile(MOOC$grade, 0.999, na.rm = TRUE)
MOOC$grade_winsor <- pmin(MOOC$grade, high_grade)
summary(MOOC$grade)
summary(MOOC$grade_winsor)

 #plot the distribution
ggplot(MOOC, aes(x = grade_winsor)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "lightblue", color = "black") 



#2. normalize and log transform
MOOC$nevents_log <- log1p(MOOC$nevents_winsor) 
MOOC$nplay_video_log <- log1p(MOOC$nplay_video_winsor) 
MOOC$ndays_act_log <- log1p(MOOC$ndays_act) 
MOOC$grade_log <- log1p(MOOC$grade_winsor) 
MOOC$nchapters_log <- log1p(MOOC$nchapters)
MOOC$nforum_posts_log <- log1p(MOOC$nforum_posts)



#######################################################################################

#2. Imputation

#impute for others using mice
#1. select the missing rows
MOOC_missing <- MOOC %>%
  select(YoB_winsor, grade_log, nevents_log, nplay_video_log, LoE_DI, ndays_act_log, nchapters_log, gender, last_event_DI_numeric)

str(MOOC_missing) 


init = mice(MOOC_missing, maxit = 0)  
meth = init$method
meth

summary(MOOC$nplay_video)

#2. impute
 #method 1: mice
set.seed(420)
MOOC_impute <- mice(MOOC_missing, m = 5, method = meth , maxit = 5, seed = 123)
summary(MOOC_impute)
MOOC_missing <- complete(MOOC_impute)
summary(MOOC_missing)

#convert back to date
MOOC_missing$last_event_DI <- as.Date(MOOC_missing$last_event_DI_numeric, origin = "1970-01-01")
class(MOOC_missing$last_event_DI)

#insert back to MOOC
MOOC$YoB <- MOOC_missing$YoB_winsor
MOOC$grade_log <- MOOC_missing$grade_log
MOOC$nevents_log <- MOOC_missing$nevents_log
MOOC$nplay_video_log <- MOOC_missing$nplay_video_log
MOOC$LoE_DI <- MOOC_missing$LoE_DI
MOOC$ndays_act_log <- MOOC_missing$ndays_act_log
MOOC$nchapters_log <- MOOC_missing$nchapters_log
MOOC$gender <- MOOC_missing$gender
MOOC$last_event_DI <- MOOC_missing$last_event_DI



MOOC <- MOOC %>% select(-c(grade, nevents, nplay_video, ndays_act, nchapters, roles, last_event_DI_numeric,
                           YoB_winsor, nevents_winsor, nplay_video_winsor, grade_winsor ) ) 

#remove registered and imcomplete flag (since they are all 1 and 0)
MOOC <- MOOC %>% select(-c(registered, incomplete_flag))
summary(MOOC)
str(MOOC)



write.csv(MOOC, "MOOC_cleaned.csv", row.names = FALSE)


sort(sample(5,3))

sort(sample(5,3))

1




