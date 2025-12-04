# DS400_Final_Project

### Members:
#### Faith Hardie

Hi my name is Faith Hardie and I am a third year student at Chaminade University. My major is Data Science and Visualization, with 3 certificates in Computer Science, Health, and Criminal Justice.  After I graduate I plan to apply the skills I learned to a career in the DoD, or pursue a masters. I hope to incorporate the critical thinking skills and hard skills I learned in DS-400 to approach statistical analysis in an unbiased, methodical manner. 

#### Elora Tonaki

 I’m Elora Tonaki and I’m a fourth-year student at Chaminade University of Honolulu. My major is Data Science, and I’m minoring in Computer Science. I’m interested in working with health data. So after graduation, I plan to find a career where I can apply my skills in Python,  Machine Learning, and use the statistical analysis I’ve learned in DS-400 where it’s needed.
 
### Introduction: 
Early-onset dementia is a neurodegenerative disorder with symptoms that include memory problems, difficulty with language, problem-solving issues, personality changes, and visual problems. Early diagnosis of the onset of dementia can help improve a patient's quality of life, even though there is no cure. With this in mind, our project aims to determine the most crucial early predictors of the onset of dementia, whether a single strongest predictor or interactions between predictors. The source of our data can be found here: [https://sites.wustl.edu/oasisbrains/home/oasis-1/](url)

### Variables of interest:

Age: The age of different subjects with and without signs of dementia.
MMSE (Mini-Mental State Examination): A measure used to account for variations in head size by normalizing brain volume using total intracranial volume (TIV).
CDR (Clinical Dementia Rating): The CDR scale is used to stage the severity of dementia, with specific scores indicating different levels of cognitive and functional impairment. 0 = non dementia; 0.5 – very mild dementia; 1 = mild dementia; 2 = moderate dementia.  
nWBV (Normalized Whole Brain Volume): A 30-point questionnaire used as a screening tool to assess cognitive impairment, measuring aspects like memory, orientation, attention, and language. 

### Methods: 
All our analysis can be found in bayesiandementia.qmd. We first went through our data cleaning process by remove missing values and isolating our variables of interest in a new, cleaned dataset. We changed the CDR column to 0.5< and 0.5> to prepare it for our logistic regression models, while still keeping the integrity and meaning behind the scale. 
Next, we explored our Data using GGplot boxplots and violin plots, as well as others. Most pertinent to our models, we created a visualization to distinguish the size difference in our two dementia values, so that we could attribute weight to our models (instead of 0, 1.5 (50%) we noticed the split was more like ½-⅔, so updated this prior to 0,1.65.)  Next, we created 3 GLM models, each more complex than the other, to best distinguish the different effect variables had on a patient's dementia outcome. Finally, we compared each model’s outcome to determine the strongest predictive variable.

For my details on the methods, visit the qmd file. 

### Conclusion
The Bayesian analysis showed that Age and Mini Mental State Evaluation (MMSE) are the most important and consistent predictors of dementia in this dataset. Adding other variables like Normalized Whole Brain Volume (nWBV) and sex did not improve predictions, as their effects were uncertain and barely changed the predicted probabilities. Model 1, which includes only Age and MMSE, is the best choice: it is simple, easy to interpret, and performs just as well as the more complex models, highlighting that extra predictors do not provide meaningful benefit.

We expected that lower MMSE and nWBV would both increase dementia risk, with nWBV being especially important in younger people. The results confirmed MMSE as a strong predictor, but nWBV didn’t really add anything, and its interaction with age wasn’t meaningful. This shows that Age and MMSE explain most of what matters, and the extra factors we thought would help don’t actually improve predictions.



  



