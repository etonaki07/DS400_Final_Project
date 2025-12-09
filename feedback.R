# ========================================
# Bayesian Dementia Analysis - Simplified
# Focus: Understanding Feature Relationships
# ========================================

# —————— LIBRARIES —————— #
library(tidyverse)
library(rstanarm)
library(bayesplot)
library(modelr)
library(broom.mixed)

# —————— DATA LOADING & CLEANING —————— #
data <- read_csv("merged_oasis_data.csv")

oasis_model <- data %>%
  select(Age, `M/F`, CDR, nWBV, MMSE) %>%
  na.omit() %>%
  rename(sex = `M/F`) %>%
  mutate(
    dementia_numeric = ifelse(CDR == 0, 0, 1),
    # Standardize continuous predictors for comparable effects
    Age_scaled = as.numeric(scale(Age)),
    MMSE_scaled = as.numeric(scale(MMSE)),
    nWBV_scaled = as.numeric(scale(nWBV))
  )

# —————— EXPLORATORY PLOTS —————— #
# Quick look at raw relationships
p1 <- ggplot(oasis_model, aes(x = factor(dementia_numeric), y = MMSE)) +
  geom_boxplot(fill = "coral", alpha = 0.6) +
  labs(title = "MMSE by Dementia Status", 
       x = "Dementia (0=No, 1=Yes)", y = "MMSE Score") +
  theme_minimal()

p2 <- ggplot(oasis_model, aes(x = factor(dementia_numeric), y = Age)) +
  geom_boxplot(fill = "steelblue", alpha = 0.6) +
  labs(title = "Age by Dementia Status", 
       x = "Dementia (0=No, 1=Yes)", y = "Age") +
  theme_minimal()

library(patchwork)
p1 + p2

# —————— BAYESIAN MODEL —————— #
# Using SCALED predictors for comparable effect sizes
model1 <- stan_glm(
  dementia_numeric ~ Age_scaled + MMSE_scaled,
  data = oasis_model,
  family = binomial,
  prior_intercept = normal(0, 1.65),
  prior = normal(0, 1, autoscale = TRUE),
  chains = 4,
  iter = 10000,
  seed = 84735
)

print(model1)

# —————— 1. COEFFICIENT PLOT —————— #
# Shows effect magnitude and uncertainty
mcmc_intervals(model1, 
               pars = c("Age_scaled", "MMSE_scaled"),
               prob = 0.8,
               prob_outer = 0.95) +
  labs(title = "Posterior Distributions of Coefficients",
       subtitle = "Effects of 1 SD change in each predictor (log-odds scale)") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal()

# —————— 2. ODDS RATIOS —————— #
# Interpret as multiplicative effects on odds
cat("\n=== ODDS RATIOS (for 1 SD change) ===\n")
or_results <- exp(posterior_interval(model1, 
                                     pars = c("Age_scaled", "MMSE_scaled"), 
                                     prob = 0.95))
print(or_results)

# Median odds ratios
or_median <- exp(coef(model1)[c("Age_scaled", "MMSE_scaled")])
cat("\nMedian Odds Ratios:\n")
print(or_median)

# —————— 3. MARGINAL EFFECTS PLOTS —————— #
# Most intuitive: shows actual probability changes

# Effect of MMSE (holding Age constant at median)
cat("\n=== Creating Marginal Effects Plots ===\n")

mmse_grid <- data_grid(oasis_model,
                       MMSE = seq_range(MMSE, n = 100),
                       Age = median(Age)) %>%
  mutate(
    Age_scaled = (Age - mean(oasis_model$Age)) / sd(oasis_model$Age),
    MMSE_scaled = (MMSE - mean(oasis_model$MMSE)) / sd(oasis_model$MMSE)
  )

mmse_preds <- posterior_epred(model1, newdata = mmse_grid)

mmse_plot_data <- mmse_grid %>%
  mutate(
    prob = colMeans(mmse_preds),
    lower = apply(mmse_preds, 2, quantile, 0.025),
    upper = apply(mmse_preds, 2, quantile, 0.975)
  )

plot_mmse <- ggplot(mmse_plot_data, aes(x = MMSE, y = prob)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.3, fill = "coral") +
  geom_line(color = "coral", size = 1.5) +
  labs(title = "Effect of MMSE on Dementia Probability",
       subtitle = paste("Holding Age at median (", round(median(oasis_model$Age), 1), " years)", sep = ""),
       y = "Predicted Probability of Dementia",
       x = "MMSE Score") +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_minimal()

# Effect of Age (holding MMSE constant at median)
age_grid <- data_grid(oasis_model,
                      Age = seq_range(Age, n = 100),
                      MMSE = median(MMSE)) %>%
  mutate(
    Age_scaled = (Age - mean(oasis_model$Age)) / sd(oasis_model$Age),
    MMSE_scaled = (MMSE - mean(oasis_model$MMSE)) / sd(oasis_model$MMSE)
  )

age_preds <- posterior_epred(model1, newdata = age_grid)

age_plot_data <- age_grid %>%
  mutate(
    prob = colMeans(age_preds),
    lower = apply(age_preds, 2, quantile, 0.025),
    upper = apply(age_preds, 2, quantile, 0.975)
  )

plot_age <- ggplot(age_plot_data, aes(x = Age, y = prob)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.3, fill = "steelblue") +
  geom_line(color = "steelblue", size = 1.5) +
  labs(title = "Effect of Age on Dementia Probability",
       subtitle = paste("Holding MMSE at median (", round(median(oasis_model$MMSE), 1), ")", sep = ""),
       y = "Predicted Probability of Dementia",
       x = "Age (years)") +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_minimal()

# Display both plots
plot_age / plot_mmse

# —————— 4. REAL-WORLD IMPACT ASSESSMENT —————— #
cat("\n=== REAL-WORLD IMPACT ===\n")

# Compare low vs high MMSE
low_mmse_data <- oasis_model %>% 
  mutate(
    MMSE = quantile(MMSE, 0.1),
    MMSE_scaled = (MMSE - mean(oasis_model$MMSE)) / sd(oasis_model$MMSE)
  )

high_mmse_data <- oasis_model %>% 
  mutate(
    MMSE = quantile(MMSE, 0.9),
    MMSE_scaled = (MMSE - mean(oasis_model$MMSE)) / sd(oasis_model$MMSE)
  )

pred_low_mmse <- colMeans(posterior_epred(model1, newdata = low_mmse_data))
pred_high_mmse <- colMeans(posterior_epred(model1, newdata = high_mmse_data))

cat("\nMMSE Impact:\n")
cat("Low MMSE (10th percentile =", round(quantile(oasis_model$MMSE, 0.1), 1), "):\n")
cat("  Average predicted probability:", round(mean(pred_low_mmse) * 100, 1), "%\n")
cat("High MMSE (90th percentile =", round(quantile(oasis_model$MMSE, 0.9), 1), "):\n")
cat("  Average predicted probability:", round(mean(pred_high_mmse) * 100, 1), "%\n")
cat("Absolute difference:", round((mean(pred_low_mmse) - mean(pred_high_mmse)) * 100, 1), 
    "percentage points\n")

# Compare young vs old
young_data <- oasis_model %>% 
  mutate(
    Age = quantile(Age, 0.1),
    Age_scaled = (Age - mean(oasis_model$Age)) / sd(oasis_model$Age)
  )

old_data <- oasis_model %>% 
  mutate(
    Age = quantile(Age, 0.9),
    Age_scaled = (Age - mean(oasis_model$Age)) / sd(oasis_model$Age)
  )

pred_young <- colMeans(posterior_epred(model1, newdata = young_data))
pred_old <- colMeans(posterior_epred(model1, newdata = old_data))

cat("\nAge Impact:\n")
cat("Young (10th percentile =", round(quantile(oasis_model$Age, 0.1), 1), " years):\n")
cat("  Average predicted probability:", round(mean(pred_young) * 100, 1), "%\n")
cat("Old (90th percentile =", round(quantile(oasis_model$Age, 0.9), 1), " years):\n")
cat("  Average predicted probability:", round(mean(pred_old) * 100, 1), "%\n")
cat("Absolute difference:", round((mean(pred_old) - mean(pred_young)) * 100, 1), 
    "percentage points\n")

# —————— 5. MODEL SUMMARY TABLE —————— #
cat("\n=== MODEL SUMMARY TABLE ===\n")

model_summary <- tidy(model1, conf.int = TRUE, conf.level = 0.95) %>%
  filter(term %in% c("Age_scaled", "MMSE_scaled")) %>%
  mutate(
    odds_ratio = exp(estimate),
    or_lower = exp(conf.low),
    or_upper = exp(conf.high)
  ) %>%
  select(term, estimate, odds_ratio, or_lower, or_upper)

print(model_summary)

cat("\n=== INTERPRETATION GUIDE ===\n")
cat("Odds Ratios are for 1 standard deviation change in predictor:\n")
cat("- Age SD =", round(sd(oasis_model$Age), 1), "years\n")
cat("- MMSE SD =", round(sd(oasis_model$MMSE), 1), "points\n")
cat("\nOR > 1 = increases odds of dementia\n")
cat("OR < 1 = decreases odds of dementia\n")
cat("OR = 1 = no effect\n")

