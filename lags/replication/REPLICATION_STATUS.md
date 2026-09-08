# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**208 of the 218 numbers this paper prints for these tables are reproduced.**

## Not matching the printed paper (2)

Cells are named as they are in `results.json`. The reason for each follows the table.

| cell | paper | this code |
|---|---|---|
| Table 2 [Estimates from all Impulse Responses]: Mean | 33.5 | 33.449495 |
| Table 2 [Hump-Shaped Impulse Responses]: Std. Dev. | 14.1 | 14.035579 |

The sample mean of the transmission lag on the cleaned sample is 33.449495 months, which is 33.4 at one decimal, not the 33.5 the paper prints here and repeats twice in the text. Every other cell of this row -- 198 observations, median 37, standard deviation 19.4, minimum 1, maximum 60 -- reproduces exactly, as do both other rows' means, so the sample is the intended one. The gap is 0.05 months.

The standard deviation of the transmission lag over the 100 hump-shaped impulse responses is 14.035579, i.e. 14.0 at one decimal, against a printed 14.1. The other five cells of this row reproduce exactly, including the count of 100 and the maximum of 57, and censoring at sixty months does not touch this subsample, so the same 100 values give both the reproduced and the unreproduced cells.

## Not produced by this code (8)

| cell | paper | this code |
|---|---|---|
| Table 5 [Financial Dev.]: Posterior Mean | 12.492 | not computed |
| Table 5 [Monthly]: Posterior Mean | -4.175 | not computed |
| Table 5 [Strictly Decreasing]: Posterior Mean | 26.122 | not computed |
| Abstract: average transmission lag (months) | 29 | not computed |
| Section 3: implied lag for the ideal study (months) | 29.2 | not computed |
| Section 3: implied lag preferring hump-shaped responses (months) | 16.3 | not computed |
| Abstract: maximum decrease in prices (percent) | 0.9 | not computed |
| Section 4: impulse responses reaching a -0.1 percent decrease (of 198) | 173 | not computed |

Bayesian model averaging over the thirty-three candidate regressors, run as an MCMC birth-death sampler with 100 million burn-in and 200 million recorded draws under a uniform model prior and the unit information prior. The model space has 2^33 members, so it cannot be enumerated and the posterior means are the output of one stochastic chain rather than a closed-form quantity. A fresh chain would return its own numbers, which are not the paper's.

Bayesian model averaging over the thirty-three candidate regressors, run as an MCMC birth-death sampler with 100 million burn-in and 200 million recorded draws under a uniform model prior and the unit information prior. The model space has 2^33 members, so it cannot be enumerated and the posterior means are the output of one stochastic chain rather than a closed-form quantity. A fresh chain would return its own numbers, which are not the paper's. This figure is a linear combination of those posterior means evaluated at the paper's best-practice values, so it inherits the chain.

Bayesian model averaging over the thirty-three candidate regressors, run as an MCMC birth-death sampler with 100 million burn-in and 200 million recorded draws under a uniform model prior and the unit information prior. The model space has 2^33 members, so it cannot be enumerated and the posterior means are the output of one stochastic chain rather than a closed-form quantity. A fresh chain would return its own numbers, which are not the paper's. The same best-practice combination, printed to one decimal. Evaluating it from Table 5's own printed posterior means and this sample's means and maxima gives 29.184, which is the printed 29.2; that is arithmetic on the paper's published output, not a reproduction of the estimation behind it.

Bayesian model averaging over the thirty-three candidate regressors, run as an MCMC birth-death sampler with 100 million burn-in and 200 million recorded draws under a uniform model prior and the unit information prior. The model space has 2^33 members, so it cannot be enumerated and the posterior means are the output of one stochastic chain rather than a closed-form quantity. A fresh chain would return its own numbers, which are not the paper's. Same combination with Strictly Decreasing set to zero. Evaluated from Table 5's printed posterior means it gives 16.255, i.e. the printed 16.3, which also settles which BMA the sentence refers to: the baseline one of Table 5 with the shape dummy switched off, not the separate hump-shaped-subsample estimation of figure 4.

The response column the authors summarise here is the normalised maximum decrease in prices, carried in the published file as MBR. Its mean over the 198 estimates is -0.011993, i.e. 1.20 percent in the percentage-point units the companion paper's script uses (res = 100*res), against the 0.9 percent printed. No scaling of that column reconciles both this figure and the count of 173 below, so the published columns do not carry the series behind the sentence.

The response variable behind this count -- the number of months to a -0.1 percent decrease in prices, used for figure 5 and table 11 -- is not among the published columns. The closest available construction, counting the estimates whose normalised maximum decrease reaches 0.1 percent, gives 171.

## Reproduced (208)

| cell | paper | this code |
|---|---|---|
| Table 2 [Estimates from all Impulse Responses]: Obs. | 198 | 198 |
| Table 2 [Estimates from all Impulse Responses]: Median | 37 | 37 |
| Table 2 [Estimates from all Impulse Responses]: Std. Dev. | 19.4 | 19.377232 |
| Table 2 [Estimates from all Impulse Responses]: Min. | 1 | 1 |
| Table 2 [Estimates from all Impulse Responses]: Max. | 60 | 60 |
| Table 2 [Hump-Shaped Impulse Responses]: Obs. | 100 | 100 |
| Table 2 [Hump-Shaped Impulse Responses]: Mean | 18.2 | 18.15 |
| Table 2 [Hump-Shaped Impulse Responses]: Median | 15 | 15 |
| Table 2 [Hump-Shaped Impulse Responses]: Min. | 1 | 1 |
| Table 2 [Hump-Shaped Impulse Responses]: Max. | 57 | 57 |
| Table 2 [Strictly Decreasing Impulse Responses]: Obs. | 98 | 98 |
| Table 2 [Strictly Decreasing Impulse Responses]: Mean | 49.1 | 49.061224 |
| Table 2 [Strictly Decreasing Impulse Responses]: Median | 48 | 48 |
| Table 2 [Strictly Decreasing Impulse Responses]: Std. Dev. | 8.6 | 8.599708 |
| Table 2 [Strictly Decreasing Impulse Responses]: Min. | 24 | 24 |
| Table 2 [Strictly Decreasing Impulse Responses]: Max. | 60 | 60 |
| Table 3 [United States]: Average Transmission Lag | 42.2 | 42.15625 |
| Table 3 [Euro Area]: Average Transmission Lag | 48.4 | 48.375 |
| Table 3 [Japan]: Average Transmission Lag | 51.3 | 51.333333 |
| Table 3 [Germany]: Average Transmission Lag | 33.4 | 33.4 |
| Table 3 [United Kingdom]: Average Transmission Lag | 40.4 | 40.428571 |
| Table 3 [France]: Average Transmission Lag | 51.3 | 51.285714 |
| Table 3 [Italy]: Average Transmission Lag | 26.6 | 26.625 |
| Table 3 [Poland]: Average Transmission Lag | 18.7 | 18.666667 |
| Table 3 [Czech Republic]: Average Transmission Lag | 14.8 | 14.785714 |
| Table 3 [Hungary]: Average Transmission Lag | 17.9 | 17.875 |
| Table 3 [Slovakia]: Average Transmission Lag | 10.7 | 10.714286 |
| Table 3 [Slovenia]: Average Transmission Lag | 17.6 | 17.6 |
| Table 6 [United States]: Average Transmission Lag | 23.2 | 23.230769 |
| Table 6 [Euro Area]: Average Transmission Lag | 39.5 | 39.5 |
| Table 6 [Japan]: Average Transmission Lag | 40.5 | 40.5 |
| Table 6 [Germany]: Average Transmission Lag | 19.4 | 19.4 |
| Table 6 [United Kingdom]: Average Transmission Lag | 10 | 10 |
| Table 6 [France]: Average Transmission Lag | 24 | 24 |
| Table 6 [Italy]: Average Transmission Lag | 9.2 | 9.2 |
| Table 6 [Poland]: Average Transmission Lag | 15.4 | 15.375 |
| Table 6 [Czech Republic]: Average Transmission Lag | 14.8 | 14.785714 |
| Table 6 [Hungary]: Average Transmission Lag | 14.4 | 14.428571 |
| Table 6 [Slovakia]: Average Transmission Lag | 5 | 5 |
| Table 6 [Slovenia]: Average Transmission Lag | 13 | 13 |
| Table 7 [United States]: Average Transmission Lag | 40.5 | 40.52381 |
| Table 7 [Euro Area]: Average Transmission Lag | 49.2 | 49.2 |
| Table 7 [Japan]: Average Transmission Lag | 57 | 57 |
| Table 7 [Germany]: Average Transmission Lag | 34.5 | 34.5 |
| Table 7 [United Kingdom]: Average Transmission Lag | 10 | 10 |
| Table 7 [France]: Average Transmission Lag | 52.8 | 52.8 |
| Table 7 [Italy]: Average Transmission Lag | 30 | 30 |
| Table 7 [Poland]: Average Transmission Lag | 14 | 14 |
| Table 7 [Czech Republic]: Average Transmission Lag | 8.8 | 8.8 |
| Table 7 [Hungary]: Average Transmission Lag | 15.4 | 15.4 |
| Table 7 [Slovakia]: Average Transmission Lag | 10.7 | 10.714286 |
| Table 7 [Slovenia]: Average Transmission Lag | 17.8 | 17.75 |
| Table 4 [GDP per Capita]: Mean | 9.88 | 9.879611 |
| Table 4 [GDP per Capita]: Std. Dev. | 0.415 | 0.415199 |
| Table 4 [GDP Growth]: Mean | 2.644 | 2.644003 |
| Table 4 [GDP Growth]: Std. Dev. | 1.042 | 1.042281 |
| Table 4 [Inflation]: Mean | 0.078 | 0.077943 |
| Table 4 [Inflation]: Std. Dev. | 0.145 | 0.144574 |
| Table 4 [Financial Dev.]: Mean | 0.835 | 0.834527 |
| Table 4 [Financial Dev.]: Std. Dev. | 0.408 | 0.408014 |
| Table 4 [Openness]: Mean | 0.452 | 0.452296 |
| Table 4 [Openness]: Std. Dev. | 0.397 | 0.397112 |
| Table 4 [CB Independence]: Mean | 0.773 | 0.772525 |
| Table 4 [CB Independence]: Std. Dev. | 0.145 | 0.145256 |
| Table 4 [Monthly]: Mean | 0.626 | 0.626263 |
| Table 4 [Monthly]: Std. Dev. | 0.485 | 0.485022 |
| Table 4 [No. of Observations]: Mean | 4.876 | 4.875975 |
| Table 4 [No. of Observations]: Std. Dev. | 0.661 | 0.660798 |
| Table 4 [Average Year]: Mean | -9.053 | -9.05303 |
| Table 4 [Average Year]: Std. Dev. | 7.779 | 7.779053 |
| Table 4 [GDP Deflator]: Mean | 0.172 | 0.171717 |
| Table 4 [GDP Deflator]: Std. Dev. | 0.378 | 0.37809 |
| Table 4 [Single Regime]: Mean | 0.293 | 0.292929 |
| Table 4 [Single Regime]: Std. Dev. | 0.456 | 0.45626 |
| Table 4 [No. of Lags]: Mean | 0.614 | 0.614478 |
| Table 4 [No. of Lags]: Std. Dev. | 0.373 | 0.373356 |
| Table 4 [Commodity Prices]: Mean | 0.626 | 0.626263 |
| Table 4 [Commodity Prices]: Std. Dev. | 0.485 | 0.485022 |
| Table 4 [Money]: Mean | 0.545 | 0.545455 |
| Table 4 [Money]: Std. Dev. | 0.499 | 0.499192 |
| Table 4 [Foreign Variables]: Mean | 0.444 | 0.444444 |
| Table 4 [Foreign Variables]: Std. Dev. | 0.498 | 0.498164 |
| Table 4 [Time Trend]: Mean | 0.131 | 0.131313 |
| Table 4 [Time Trend]: Std. Dev. | 0.339 | 0.338599 |
| Table 4 [Seasonal]: Mean | 0.146 | 0.146465 |
| Table 4 [Seasonal]: Std. Dev. | 0.354 | 0.354468 |
| Table 4 [No. of Variables]: Mean | 1.748 | 1.748388 |
| Table 4 [No. of Variables]: Std. Dev. | 0.391 | 0.390613 |
| Table 4 [Industrial Prod.]: Mean | 0.429 | 0.429293 |
| Table 4 [Industrial Prod.]: Std. Dev. | 0.496 | 0.49623 |
| Table 4 [Output Gap]: Mean | 0.03 | 0.030303 |
| Table 4 [Output Gap]: Std. Dev. | 0.172 | 0.171854 |
| Table 4 [Other Measures]: Mean | 0.121 | 0.121212 |
| Table 4 [Other Measures]: Std. Dev. | 0.327 | 0.327201 |
| Table 4 [BVAR]: Mean | 0.121 | 0.121212 |
| Table 4 [BVAR]: Std. Dev. | 0.327 | 0.327201 |
| Table 4 [FAVAR]: Mean | 0.051 | 0.050505 |
| Table 4 [FAVAR]: Std. Dev. | 0.22 | 0.21954 |
| Table 4 [SVAR]: Mean | 0.313 | 0.313131 |
| Table 4 [SVAR]: Std. Dev. | 0.465 | 0.464943 |
| Table 4 [Sign Restrictions]: Mean | 0.152 | 0.151515 |
| Table 4 [Sign Restrictions]: Std. Dev. | 0.359 | 0.359459 |
| Table 4 [Strictly Decreasing]: Mean | 0.495 | 0.494949 |
| Table 4 [Strictly Decreasing]: Std. Dev. | 0.501 | 0.501242 |
| Table 4 [Price Puzzle]: Mean | 0.53 | 0.530303 |
| Table 4 [Price Puzzle]: Std. Dev. | 0.5 | 0.500346 |
| Table 4 [Study Citations]: Mean | 1.875 | 1.87545 |
| Table 4 [Study Citations]: Std. Dev. | 1.292 | 1.292026 |
| Table 4 [Impact]: Mean | 0.9 | 0.899924 |
| Table 4 [Impact]: Std. Dev. | 2.417 | 2.416899 |
| Table 4 [Central Banker]: Mean | 0.424 | 0.424242 |
| Table 4 [Central Banker]: Std. Dev. | 0.495 | 0.49548 |
| Table 4 [Policymaker]: Mean | 0.061 | 0.060606 |
| Table 4 [Policymaker]: Std. Dev. | 0.239 | 0.239211 |
| Table 4 [Native]: Mean | 0.449 | 0.449495 |
| Table 4 [Native]: Std. Dev. | 0.499 | 0.498704 |
| Table 4 [Publication Year]: Mean | 4.894 | 4.893939 |
| Table 4 [Publication Year]: Std. Dev. | 3.889 | 3.888531 |
| Table 8 [GDP per Capita]: coef | -11.48 | -11.477577 |
| Table 8 [GDP per Capita]: se | 4.793 | 4.792741 |
| Table 8 [Price Puzzle]: coef | 4.667 | 4.666871 |
| Table 8 [Price Puzzle]: se | 2.343 | 2.343193 |
| Table 8 [Inflation]: coef | -17.25 | -17.247138 |
| Table 8 [Inflation]: se | 8.739 | 8.738762 |
| Table 8 [Financial Dev.]: coef | 21.61 | 21.605932 |
| Table 8 [Financial Dev.]: se | 5.375 | 5.375226 |
| Table 8 [Openness]: coef | -12.67 | -12.665548 |
| Table 8 [Openness]: se | 4.67 | 4.670481 |
| Table 8 [CB Independence]: coef | 29.38 | 29.38131 |
| Table 8 [CB Independence]: se | 10.64 | 10.636398 |
| Table 8 [Monthly]: coef | -12.04 | -12.041738 |
| Table 8 [Monthly]: se | 3.821 | 3.821023 |
| Table 8 [No. of Observations]: coef | 6.526 | 6.526428 |
| Table 8 [No. of Observations]: se | 2.951 | 2.950617 |
| Table 8 [Policymaker]: coef | 12.37 | 12.372632 |
| Table 8 [Policymaker]: se | 5.012 | 5.011521 |
| Table 8 [Constant]: coef | 86.58 | 86.583402 |
| Table 8 [Constant]: se | 43.69 | 43.694099 |
| Table 8: Observations | 198 | 198 |
| Table 12 [GDP per Capita]: coef | -9.792 | -9.791907 |
| Table 12 [GDP per Capita]: se | 5.192 | 5.192385 |
| Table 12 [GDP Growth]: coef | 1.512 | 1.511679 |
| Table 12 [GDP Growth]: se | 1.346 | 1.345639 |
| Table 12 [Inflation]: coef | -17.41 | -17.412215 |
| Table 12 [Inflation]: se | 8.695 | 8.695205 |
| Table 12 [Financial Dev.]: coef | 22.17 | 22.168113 |
| Table 12 [Financial Dev.]: se | 6.084 | 6.083698 |
| Table 12 [Openness]: coef | -11.16 | -11.158497 |
| Table 12 [Openness]: se | 5.595 | 5.595221 |
| Table 12 [CB Independence]: coef | 30.2 | 30.197673 |
| Table 12 [CB Independence]: se | 12.27 | 12.26723 |
| Table 12 [Monthly]: coef | -4.402 | -4.401623 |
| Table 12 [Monthly]: se | 6.92 | 6.920176 |
| Table 12 [No. of Observations]: coef | 4.287 | 4.287126 |
| Table 12 [No. of Observations]: se | 5.186 | 5.186493 |
| Table 12 [Average Year]: coef | -0.168 | -0.167792 |
| Table 12 [Average Year]: se | 0.367 | 0.366963 |
| Table 12 [GDP Deflator]: coef | 5.102 | 5.102285 |
| Table 12 [GDP Deflator]: se | 4.281 | 4.281341 |
| Table 12 [Single Regime]: coef | 4.143 | 4.143464 |
| Table 12 [Single Regime]: se | 3.497 | 3.497286 |
| Table 12 [No. of Lags]: coef | 8.132 | 8.132281 |
| Table 12 [No. of Lags]: se | 4.744 | 4.743873 |
| Table 12 [Commodity Prices]: coef | -1.284 | -1.283731 |
| Table 12 [Commodity Prices]: se | 2.861 | 2.861362 |
| Table 12 [Money]: coef | 1.768 | 1.768474 |
| Table 12 [Money]: se | 2.949 | 2.948753 |
| Table 12 [Foreign Variables]: coef | 4.102 | 4.102378 |
| Table 12 [Foreign Variables]: se | 3.4 | 3.399514 |
| Table 12 [Time Trend]: coef | 2.7 | 2.700024 |
| Table 12 [Time Trend]: se | 5.791 | 5.791496 |
| Table 12 [Seasonal]: coef | 7.231 | 7.231464 |
| Table 12 [Seasonal]: se | 4.057 | 4.056972 |
| Table 12 [No. of Variables]: coef | 1.352 | 1.351985 |
| Table 12 [No. of Variables]: se | 3.536 | 3.536419 |
| Table 12 [Industrial Prod.]: coef | -6.785 | -6.784833 |
| Table 12 [Industrial Prod.]: se | 3.904 | 3.904262 |
| Table 12 [Output Gap]: coef | -10.41 | -10.405356 |
| Table 12 [Output Gap]: se | 7.681 | 7.681324 |
| Table 12 [Other Measures]: coef | -6.246 | -6.246379 |
| Table 12 [Other Measures]: se | 5.017 | 5.01683 |
| Table 12 [BVAR]: coef | -1.147 | -1.147097 |
| Table 12 [BVAR]: se | 5.094 | 5.093807 |
| Table 12 [FAVAR]: coef | 14.53 | 14.53417 |
| Table 12 [FAVAR]: se | 6.525 | 6.524715 |
| Table 12 [SVAR]: coef | -4.243 | -4.242606 |
| Table 12 [SVAR]: se | 3.008 | 3.008017 |
| Table 12 [Sign Restrictions]: coef | -3.27 | -3.27028 |
| Table 12 [Sign Restrictions]: se | 5.163 | 5.163337 |
| Table 12 [Price Puzzle]: coef | 3.651 | 3.651455 |
| Table 12 [Price Puzzle]: se | 2.537 | 2.537158 |
| Table 12 [Study Citations]: coef | -0.717 | -0.717315 |
| Table 12 [Study Citations]: se | 1.734 | 1.734302 |
| Table 12 [Impact]: coef | -0.742 | -0.742345 |
| Table 12 [Impact]: se | 0.699 | 0.698563 |
| Table 12 [Central Banker]: coef | 5.313 | 5.313186 |
| Table 12 [Central Banker]: se | 3.633 | 3.63252 |
| Table 12 [Policymaker]: coef | 9.024 | 9.024468 |
| Table 12 [Policymaker]: se | 6.137 | 6.137272 |
| Table 12 [Native]: coef | -1.996 | -1.995717 |
| Table 12 [Native]: se | 3.043 | 3.042736 |
| Table 12 [Publication Year]: coef | 0.0475 | 0.047467 |
| Table 12 [Publication Year]: se | 0.453 | 0.452503 |
| Table 12 [Constant]: coef | 62.32 | 62.318454 |
| Table 12 [Constant]: se | 50.1 | 50.103301 |
| Table 12: Observations | 198 | 198 |
| Primary studies in the sample | 67 | 67 |
| Countries covered | 30 | 30 |

