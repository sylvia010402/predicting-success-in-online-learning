# Data Dictionary: HarvardX-MITx MOOC Dataset

## Dataset Overview

This dataset captures student-level data from the first year of HarvardX and MITx MOOCs (Fall 2012 - Summer 2013). Each row represents one enrolled student across 13 courses from both institutions. Due to person de-identification issues, we could not retrive the user data for the courses titled MITx. 

## Course Information

| Institution | Course Code | Short Title | Full Title | Semester |
|-------------|-------------|-------------|------------|----------|
| HarvardX | CB22x | HeroesX | The Ancient Greek Hero | Spring-Summer 2013 |
| HarvardX | CS50x | - | Introduction to Computer Science I | Fall 2012 - Spring 2013 |
| HarvardX | ER22x | JusticeX | Justice | Spring-Summer 2013 |
| HarvardX | PH207x | HealthStat | Health in Numbers: Quantitative Methods in Clinical & Public Health Research | Fall 2012 |
| HarvardX | PH278x | HealthEnv | Human Health and Global Environmental Change | Summer 2013 |
| MITx | 14.73x | Poverty | The Challenges of Global Poverty | Spring 2013 |
| MITx | 2.01x | Structures | Elements of Structures | Spring-Summer 2013 |
| MITx | 3.091x | SSChem | Introduction to Solid State Chemistry | Fall 2012 and Spring 2013 |
| MITx | 6.002x | Circuits | Circuits and Electronics | Fall 2012 and Spring 2013 |
| MITx | 6.00x | CS | Introduction to Computer Science and Programming | Fall 2012 and Spring 2013 |
| MITx | 7.00x | Biology | Introduction to Biology - The Secret of Life | Spring 2013 |
| MITx | 8.02x | E&M | Electricity and Magnetism | Spring 2013 |
| MITx | 8.MReV | MechRev | Mechanics Review | Summer 2013 |

## Variable Definitions

### Data Source Notes
- **Administrative**: Variables from edX system or computed by research team
- **User-provided**: Variables from student registration questions
- **"_DI" suffix**: Variable was transformed during de-identification process
- **"NA" values**: Student created account before registration question was available
- **Blank values**: Student declined to provide information

---

## Identification Variables

**`course_id`** (administrative, string)  
Identifies institution, course name, and semester  
*Example: "HarvardX/CB22x/2013_Spring"*

**`userid_DI`** (administrative, string)  
De-identified student ID with dataset identifier and random number  
*Example: "MHxPC130442623"*

---

## Engagement Level Variables (Target Variables)

**`registered`** (administrative, 0/1)  
Registered for course (=1 for all records)

**`viewed`** (administrative, 0/1)  
Accessed the 'Courseware' tab containing videos, problem sets, and exams

**`explored`** (administrative, 0/1)  
Accessed at least half of the chapters in the courseware

**`certified`** (administrative, 0/1)  
Earned a certificate (cutoff varies from 50%-80% depending on course)

---

## Behavioral Engagement Variables

**`nevents`** (administrative, integer)  
Number of interactions with the course recorded in tracking logs  
*Example: "502"*

**`ndays_act`** (administrative, integer)  
Number of unique days student interacted with course  
*Example: "16"*

**`nplay_video`** (administrative, integer)  
Number of video play events within the course  
*Example: "52"*

**`nchapters`** (administrative, integer)  
Number of chapters accessed within the Courseware  
*Example: "12"*

**`nforum_posts`** (administrative, integer)  
Number of posts to the Discussion Forum  
*Example: "8"*

---

## Demographic Variables

**`LoE`** (user-provided, categorical)  
Highest level of education completed  
*Values: "Less than Secondary", "Secondary", "Bachelor's", "Master's", "Doctorate"*

**`YoB`** (user-provided, string)  
Year of birth  
*Example: "1980"*

**`gender`** (user-provided, categorical)  
Gender identity  
*Values: m (male), f (female), o (other)*

**`final_cc_cname_DI`** (mixed administrative/user-provided, string)  
Country name (from IP address or student-provided address)  
*Examples: "Other South Asia", "Russian Federation"*

---

## Administrative Variables

**`grade`** (administrative, float)  
Final grade in the course (0 to 1 scale)  
*Example: "0.87"*

**`start_time_DI`** (administrative, date)  
Date of course registration  
*Example: "12/19/12"*

**`last_event_DI`** (administrative, date)  
Date of last interaction with course (blank if no interactions beyond registration)  
*Example: "11/17/13"*

**`roles`** (administrative, string)  
Staff and instructor identifiers (blank in this release)

**`inconsistent_flag`** (administrative, 0/1)  
Identifies records with internal inconsistencies due to data issues. Some records have null values for `nevents` but non-null values for `ndays_act`, `nforum_posts`, or `nchapters` due to different data sources (tracking logs vs. Courseware Student Module).

---

## Data Quality Notes

- **Missing Values**: Common in user-provided demographic variables
- **Extreme Outliers**: Engagement variables are heavily right-skewed
- **Data Inconsistencies**: Some records flagged due to tracking log issues
- **Course Variations**: CS50x has minimal tracking logs as content was hosted outside edX platform

## Key Insights for Analysis

- **Target Variable**: `certified` (only ~2.5% of students earn certificates)
- **Primary Predictors**: Engagement behaviors (`ndays_act`, `nchapters`, `explored`)
- **Secondary Predictors**: Demographics (`LoE`, `YoB`, `gender`)
- **Data Challenges**: Extreme class imbalance, missing values, skewed distributions
