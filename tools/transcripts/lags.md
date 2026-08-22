# Transmission Lags of Monetary Policy: A Meta-Analysis

## FRONTMATTER

Tomas Havranek^{a,b} and Marek Rusnak^{b,c}

^{a}Research Department, Czech National Bank
^{b}Institute of Economic Studies, Charles University, Prague
^{c}Financial Stability Department, Czech National Bank

^{*}We are grateful to Adam Elbourne, Bill Gavine, and Jakob de Haan for sending us additional data and Oxana Babecka-Kucharcukova, Marek Jarocinski, Jacques Poot, and two anonymous referees of the International Journal of Central Banking for comments on previous versions of the manuscript. Tomas Havranek acknowledges support from the Czech Science Foundation (grant #P402/12/G097). Marek Rusnak acknowledges support from the Grant Agency of Charles University (grant #267011). An online appendix with data, R and Stata code, and a list of excluded studies is available at http://meta-analysis.cz/lags/index.html. The views expressed here are ours and not necessarily those of the Czech National Bank. Corresponding author: Tomas Havranek, tomas.havranek@cnb.cz or tomas.havranek@ies-prague.org.

## ABSTRACT

The transmission of monetary policy to the economy is generally thought to have long and variable lags. In this paper we quantitatively review the modern literature on monetary transmission to provide stylized facts on the average lag length and the sources of variability. We collect sixty-seven published studies and examine when prices bottom out after a monetary contraction. The average transmission lag is twenty-nine months, and the maximum decrease in prices reaches 0.9 percent on average after a 1-percentage-point hike in the policy rate. Transmission lags are longer in developed economies (twenty-five to fifty months) than in post-transition economies (ten to twenty months). We find that the factor most effective in explaining this heterogeneity is financial development: greater financial development is associated with slower transmission.

**JEL Codes**: C83, E52.

## 1. Introduction

Policymakers need to know how long it takes before their actions fully transmit to the economy and what determines the speed of transmission. A common claim about the transmission mechanism of monetary policy is that it has “long and variable” lags (Friedman 1972; Batini and Nelson 2001; Goodhart 2001). This view has been embraced by many central banks and taken into account during their decision making: most inflation-targeting central banks have adopted a value between twelve and twenty-four months as their policy horizon (see, for example, Bank of England 1999; European Central Bank 2010). Theoretical models usually imply transmission lags of similar length (Taylor and Wieland 2012), but the results of empirical studies vary widely.

In this paper we quantitatively survey studies that employ vector autoregression (VAR) methods to investigate the effects of monetary policy shocks on the price level. We refer to the horizon at which the response of prices becomes the strongest as the transmission lag, and collect 198 estimates from sixty-seven published studies. The estimates of transmission lags in our sample are indeed variable, and we examine the sources of variability. The meta-analysis approach allows us to investigate both how transmission lags differ across countries and how different estimation methodologies within the VAR framework affect the results. Meta-analysis is a set of tools for summarizing the existing empirical evidence; it has been regularly employed in medical research, but its application has only recently spread to the social sciences, including economics (Stanley 2001; Disdier and Head 2008; Card, Kluve, and Weber 2010; Havranek and Irsova 2011). By bringing together evidence from a large number of studies that use different methods, meta-analysis can extract robust results from a heterogeneous literature.

Several researchers have previously investigated the cross-country differences in monetary transmission. Ehrmann (2000) examines thirteen member countries of the European Union and finds relatively fast transmission to prices for most of the countries: between two and eight quarters. Only France, Italy, and the United Kingdom exhibit transmission lags between twelve and twenty quarters. In contrast, Mojon and Peersman (2003) find that the effects of monetary policy shocks in European economies are much more delayed, with the maximum reaction occurring between sixteen and twenty quarters after the shock. Concerning cross-country differences, Mojon and Peersman (2003) argue that the confidence intervals are too wide to draw any strong conclusions, but they call for further testing of the heterogeneity of impulse responses. Boivin, Giannoni, and Mojon (2009) update the results and conclude that the adoption of the euro contributed to lower heterogeneity in monetary transmission among the member countries.

Cecchetti (1999) finds that for a sample of advanced countries, transmission lags vary between one and twelve quarters. He links the country-specific strength of monetary policy to a number of indicators of financial structure but does not attempt to explain the variation in transmission lags. In a similar vein, Elbourne and de Haan (2006) investigate ten new EU member countries and find that the maximum effects of monetary policy shocks on prices occur between one and ten quarters after the shock. These papers typically look at a small set of countries at a specific point in time; in contrast, we collect estimates of transmission lags from a vast literature that provides evidence for thirty different economies during several decades. Moreover, while some of the previous studies seek to explain the differences in the strength of transmission, they remain silent about the factors driving transmission speed.

In this paper we attempt to fill this gap and associate the differences in transmission lags with a number of country and study characteristics. Our results suggest that the transmission lags reported in the literature really do vary substantially: the average lag, corrected for misspecification in some studies, is twenty-nine months, with a standard deviation of nineteen months. Post-transition economies in our sample exhibit significantly faster transmission than advanced economies, and the only robust country-specific determinant of the length of transmission is the degree of financial development. In developed countries, financial institutions have more opportunities to hedge against surprises in monetary policy stance, causing greater delays in the transmission of monetary policy shocks. Concerning variables that describe the methods used by primary studies, the frequency of the data employed matters for the reported transmission lags. Our results suggest that researchers who use monthly data instead of quarterly data report systematically faster transmission.

The remainder of the paper is structured as follows. Section 2 presents descriptive evidence concerning the differences in transmission lags. Section 3 links the variation in transmission lags to thirty country- and study-specific variables. Section 4 contains robustness checks. Section 5 summarizes the implications of our key results.

## 2. Estimating the Average Lag

We attempt to gather all published studies on monetary transmission that fulfill the following three inclusion criteria. First, the study must present an impulse response of the price level to a shock in the policy rate (that is, we exclude impulse responses of the inflation rate). Second, the impulse response in the study must correspond to a 1-percentage-point shock in the interest rate, or the size of the monetary policy shock must be presented so that we can normalize the response. Third, we only include studies that present confidence intervals around the impulse responses---as a simple indicator of quality. The primary studies fulfilling the inclusion criteria are listed in table 1. More details describing the search strategy can be found in a related paper (Rusnak, Havranek, and Horvath 2013), examining which method choices are associated with reporting the “price puzzle” (the short-term increase in the price level following a monetary contraction).

After imposition of the inclusion criteria, our database contains 198 impulse responses taken from sixty-seven previously published studies and provides evidence on the monetary transmission mechanism for thirty countries, mostly developed and post-transition economies. The database is available in the online appendix (http://meta-analysis.cz/lags/index.html). For each impulse response, we evaluate the horizon at which the decrease in prices following the monetary contraction reaches its maximum. The literature reports two general types of impulse responses, both of which are depicted in figure 1. The left-hand panel shows a hump-shaped (also called U-shaped) impulse response: prices decrease and bounce back after some time following a monetary policy shock; the monetary contraction stabilizes prices at a lower level or the effect gradually dies out. The dashed line denotes the maximum effect, and we label the corresponding number of months passed since the monetary contraction as the transmission lag. In contrast, the right-hand panel shows a strictly decreasing impulse response: prices neither stabilize nor bounce back within the time frame reported by the authors (impulse response functions are usually constructed for a five-year horizon). In this case the response of the price level becomes the strongest in the last reported horizon, so we label the last horizon as the transmission lag.

TABLE 1. List of Primary Studies

|  |  |
| --- | --- |
| Andries (2008) | Jang & Ogaki (2004) |
| Anzuini & Levy (2007) | Jaroncinski (2010) |
| Arin & Jolly (2005) | Jarocinski & Smets (2008) |
| Bagliano & Favero (1998, 1999) | Kim (2001, 2002) |
| Banbura, Giannone, & Reichlin (2010) | Krusec (2010) |
| Belviso & Milani (2006) | Kubo (2008) |
| Bernanke, Boivin, & Eliasz (2005) | Lagana & Mountford (2005) |
| Bernanke, Gertler, & Watson (1997) | Leeper, Sims, & Zha (1996) |
| Boivin & Giannoni (2009) | Lange (2010) |
| Borys, Horvath, & Franta (2009) | Li, Iscan, & Xu (2010) |
| Bredin & O’Reilly (2004) | McMillin (2001) |
| Brissimis & Magginas (2006) | Mertens (2008) |
| Brunner (2000) | Minella (2003) |
| Buckle et al. (2007) | Mojon (2008) |
| Cespedes, Lima, & Maka (2008) | Mojon & Peersman (2001) |
| Christiano, Eichenbaum, & Evans (1996, 1999) | Mountford (2005) |
| Cushman & Zha (1997) | Nakashima (2006) |
| De Arcangelis & Di Giorgio (2001) | Normandin & Phaneuf (2004) |
| Dedola & Lippi (2005) | Oros & Roocea-Turcu (2009) |
| Eichenbaum (1992) | Peersman (2004, 2005) |
| Eickmeier, Hofmann, & Worms (2009) | Peersman & Smets (2001) |
| Elbourne (2008) | Peersman & Straub (2009) |
| Elbourne & de Haan (2006, 2009) | Pobre (2003) |
| European Forecasting Network (2004) | Rafiq & Mallick (2008) |
| Forni & Gambetti (2010) | Romer & Romer (2004) |
| Fujiwara (2004) | Shioji (2000) |
| Gan & Soon (2003) | Sims & Zha (1998) |
| Hanson (2004) | Smets (1997) |
| Horvath & Rusnak (2009) | Sousa & Zaghini (2008) |
| Hulsewig, Mayer, & Wollmershauser (2006) | Vargas-Silva (2008) |
|  | Voss & Willard (2009) |
|  | Wu (2003) |
Notes: The search for primary studies was terminated on September 15, 2010. A list of excluded studies, with reasons for exclusion, is available in the online appendix.

FIGURE 1. Stylized Impulse Responses. Notes: The figure depicts stylized examples of the price level’s response to a 1-percentage-point increase in the policy rate. The dashed lines denote the number of months to the maximum decrease in prices.

Researchers often discuss the number of months to the maximum decrease in prices in the case of hump-shaped impulse responses. On the other hand, researchers rarely interpret the timing of the maximum decrease in prices for strictly decreasing impulse responses, as the implied transmission lag often seems implausibly long. Moreover, a strictly decreasing response may indicate non-stationarity of the estimated VAR system (Lütkepohl 2005). Nevertheless, we do not limit our analysis to hump-shaped impulse responses since both types are commonly reported: in the data set we have 100 estimates of transmission lags taken from hump-shaped impulse responses and 98 estimates taken from strictly decreasing impulse responses. We do not prefer any particular shape of the impulse response and focus on inference concerning the average transmission lag, but we additionally report results corresponding solely to hump-shaped impulse responses.

Figure 2 depicts the kernel density plot of the collected estimates; the figure demonstrates that the transmission lags taken from hump-shaped impulse responses are, on average, substantially shorter than the lags taken from strictly decreasing impulse response functions. Numerical details on summary statistics are reported in table 2. The average of all collected transmission lags is 33.5 months, but the average reaches 49.1 months for transmission lags taken from strictly decreasing impulse responses and 18.2 months for hump-shaped impulse responses. In other words, the decrease in prices following a monetary contraction becomes the strongest, on average, after two years and three quarters. Our data also suggest that the average magnitude of the maximum decrease in prices following a 1-percentage-point increase in the policy rate is 0.9 percent (for a detailed meta-analysis of the strength of monetary transmission at different horizons, see Rusnak, Havranek, and Horvath 2013).

FIGURE 2. Kernel Density of the Estimated Transmission Lags. Notes: The figure is constructed using the Epanechnikov kernel function. The solid vertical line denotes the average number of months to the maximum decrease in prices taken from all the impulse responses. The dashed line on the left denotes the average taken from the hump-shaped impulse responses. The dashed line on the right denotes the average taken from the strictly decreasing impulse response functions.

TABLE 2. Summary Statistics of the Estimated Transmission Lags

| Variable | Obs. | Mean | Median | Std. Dev. | Min. | Max. |
| --- | --- | --- | --- | --- | --- | --- |
| Estimates from all Impulse Responses | 198 | 33.5 | 37 | 19.4 | 1 | 60 |
| Hump-Shaped Impulse Responses | 100 | 18.2 | 15 | 14.1 | 1 | 57 |
| Strictly Decreasing Impulse Responses | 98 | 49.1 | 48 | 8.6 | 24 | 60 |

TABLE 3. Transmission Lags Differ across Countries

| Economy | Average Transmission Lag |
| --- | --- |
| *Developed Economies* |  |
| United States | 42.2 |
| Euro Area | 48.4 |
| Japan | 51.3 |
| Germany | 33.4 |
| United Kingdom | 40.4 |
| France | 51.3 |
| Italy | 26.6 |
| *Post-Transition Economies* |  |
| Poland | 18.7 |
| Czech Republic | 14.8 |
| Hungary | 17.9 |
| Slovakia | 10.7 |
| Slovenia | 17.6 |
Notes: The table shows the average number of months to the maximum decrease in prices taken from all the impulse responses reported for the corresponding country. We only show results for countries for which the literature has reported at least five impulse responses.

The average of 33.5 is constructed based on data for thirty different countries. To investigate whether transmission lags vary across countries, we report country-specific averages in table 3 (we only show results for countries for which we have collected at least five observations from the literature). We divide the countries into two groups: developed economies and post-transition economies.^{1} From the table it is apparent that developed countries display much longer transmission lags than post-transition countries. The developed country with the fastest transmission of monetary policy actions is Italy: the corresponding transmission lag reaches 26.6 months. The slowest transmission is found for Japan and France, with a transmission lag equal to 51.3 months. In general, the transmission lags for developed countries seem to vary between approximately twenty-five and fifty months. These values sharply contrast with the results for post-transition countries, where all reported transmission lags lie between ten and twenty months. The result is in line with Jarocinski (2010), who investigates cross-country differences in transmission and finds that post-communist economies exhibit faster transmission than Western European countries. We examine the possible sources of the cross-country heterogeneity in the next section.

## 3. Explaining the Differences

Two general reasons may explain why the reported transmission lags vary: First, structural differences across countries may cause genuine differences in the speed of transmission. Second, characteristics of the data and other aspects of the methodology employed in the primary studies, such as specification and estimation characteristics, may have a systematic influence on the reported transmission lag.

We collected thirty-three potential explanatory variables. Several structural characteristics that may account for cross-country differences in the monetary transmission mechanism have been suggested in the literature (Dornbusch et al. 1998; Cecchetti 1999; Ehrmann et al. 2003). Therefore, to control for these structural differences we include *GDP per Capita* to represent the country's overall level of the development, *GDP Growth* and *Inflation* to reflect other macroeconomic conditions in the economy, *Financial Development* to capture the importance of the financial structure, *Openness* to cover the exchange rate channel of the transmission mechanism, and *Central Bank Independence* to capture the influence of the institutional setting and credibility on monetary transmission. These variables are computed as averages over the periods that correspond to the estimation periods of the primary studies. The sources of the data for these variables are Penn World Tables, the World Bank's World Development Indicators, and the International Monetary Fund's International Financial Statistics; the central bank independence index is extracted from Arnone et al. (2009). We also include variables that control for data, methodology, and publication characteristics of the primary studies. The definitions of the variables are provided in table 4 together with their summary statistics.

Rather than estimating a regression with an ad hoc subset of explanatory variables, we formally address the model uncertainty inherent in meta-analysis (in other words, many method variables may be important for the reported speed of transmission, but no theory helps us select which ones). There are at least two drawbacks to using simple regression in situations where many potential explanatory variables exist. First, if we put all potential variables into one regression, the standard errors get inflated since many redundant variables are included. Second, sequential testing (or the "general-to-specific" approach) brings about the possibility of excluding relevant variables.

TABLE 4. Description and Summary Statistics of Explanatory Variables

| Variable | Description | Mean | Std. Dev. |
|---|---|---|---|
| *Country Characteristics* |  |  |  |
| GDP per Capita | The logarithm of the country's real GDP per capita. | 9.880 | 0.415 |
| GDP Growth | The average growth rate of the country's real GDP. | 2.644 | 1.042 |
| Inflation | The average inflation of the country. | 0.078 | 0.145 |
| Financial Dev. | The financial development of the country measured by (domestic credit to private sector)/GDP. | 0.835 | 0.408 |
| Openness | The trade openness of the country measured by (exports + imports)/GDP. | 0.452 | 0.397 |
| CB Independence | A measure of central bank independence (Arnone et al. 2009) | 0.773 | 0.145 |
| *Data Characteristics* |  |  |  |
| Monthly | = 1 if monthly data are used. | 0.626 | 0.485 |
| No. of Observations | The logarithm of the number of observations used. | 4.876 | 0.661 |
| Average Year | The average year of the data used (2000 as a base). | −9.053 | 7.779 |

TABLE 4 (continued). Description and Summary Statistics of Explanatory Variables

| Variable | Description | Mean | Std. Dev. |
|---|---|---|---|
| *Specification Characteristics* |  |  |  |
| GDP Deflator | = 1 if the GDP deflator is used instead of the consumer price index as a measure of prices. | 0.172 | 0.378 |
| Single Regime | = 1 if the VAR is estimated over a period of a single monetary policy regime. | 0.293 | 0.456 |
| No. of Lags | The number of lags in the model, normalized by frequency: lags/frequency. | 0.614 | 0.373 |
| Commodity Prices | = 1 if a commodity price index is included. | 0.626 | 0.485 |
| Money | = 1 if a monetary aggregate is included. | 0.545 | 0.499 |
| Foreign Variables | = 1 if at least one foreign variable is included. | 0.444 | 0.498 |
| Time Trend | = 1 if a time trend is included. | 0.131 | 0.339 |
| Seasonal | = 1 if seasonal dummies are included. | 0.146 | 0.354 |
| No. of Variables | The logarithm of the number of endogenous variables included in the VAR. | 1.748 | 0.391 |
| Industrial Prod. | = 1 if industrial production is used as a measure of economic activity. | 0.429 | 0.496 |
| Output Gap | = 1 if the output gap is used as a measure of economic activity. | 0.030 | 0.172 |
| Other Measures | = 1 if another measure of economic activity is used (employment, expenditures). | 0.121 | 0.327 |
| *Estimation Characteristics* |  |  |  |
| BVAR | = 1 if a Bayesian VAR is estimated. | 0.121 | 0.327 |
| FAVAR | = 1 if a factor-augmented VAR is estimated. | 0.051 | 0.220 |
| SVAR | = 1 if non-recursive identification is employed. | 0.313 | 0.465 |
| Sign Restrictions | = 1 if sign restrictions are employed. | 0.152 | 0.359 |

TABLE 4 (continued). Description and Summary Statistics of Explanatory Variables

| Variable | Description | Mean | Std. Dev. |
|---|---|---|---|
| *Publication Characteristics* |  |  |  |
| Strictly Decreasing | The reported impulse response function is strictly decreasing (that is, it shows the maximum decrease in prices in the last displayed horizon). | 0.495 | 0.501 |
| Price Puzzle | The reported impulse response exhibits the price puzzle. | 0.530 | 0.500 |
| Study Citations | The logarithm of [(Google Scholar citations of the study)/(age of the study) + 1]. | 1.875 | 1.292 |
| Impact | The recursive RePEc impact factor of the outlet. | 0.900 | 2.417 |
| Central Banker | = 1 if at least one co-author is affiliated with a central bank. | 0.424 | 0.495 |
| Policymaker | = 1 if at least one co-author is affiliated with a Ministry of Finance, IMF, OECD, or BIS. | 0.061 | 0.239 |
| Native | = 1 if at least one co-author is native to the investigated country. | 0.449 | 0.499 |
| Publication Year | The year of publication (2000 as a base). | 4.894 | 3.889 |
**Note:** The sources of data for country characteristics are Penn World Tables, the World Bank's World Development Indicators, and the International Monetary Fund's International Financial Statistics.

To address these issues, Bayesian model averaging (BMA) is employed frequently in the literature on the determinants of economic growth (Fernandez, Ley, and Steel 2001; Sala-I-Martin, Doppelhofer, and Miller 2004; Durlauf, Kourtellos, and Tan 2008; Feldkircher and Zeugner 2009; Eicher, Papageorgiou, and Raftery 2011). Recently, BMA has been used to address other questions as well (see Moral-Benito 2011 for a survey). The idea of BMA is to go through all possible combinations of regressors and weight them according to their model fit. BMA thus provides results robust to model uncertainty, which arises when little or nothing is known ex ante about the correct set of explanatory variables. An accessible introduction to BMA can be found in Koop (2003); technical details concerning the implementation of the method are provided by Feldkircher and Zeugner (2009).

Because we consider thirty-three potential explanatory variables, it is not technically feasible to enumerate all $2^{33}$ of their possible combinations; on a typical personal computer this would take several months. In such cases, Markov chain Monte Carlo methods are used to go through the most important models. We employ the priors suggested by Eicher, Papageorgiou, and Raftery (2011), who recommend using the uniform model prior and the unit information prior for the parameters, since these priors perform well in forecasting exercises. Following Fernandez, Ley, and Steel (2001), we run the estimation with 200 million iterations, ensuring a good degree of convergence. Appendix 1 provides diagnostics of our BMA estimation; the online appendix provides R and Stata codes.

The results of the BMA estimation are reported graphically in figure 3. The columns represent individual regression models where the transmission lag is regressed on variables for which the corresponding cell is not blank. For example, the explanatory variables in the first model from the left are *Financial Development*, *Strictly Decreasing*, *Monthly*, *CB Independence*, *Impact*, and *Price Puzzle*. The width of the columns is proportional to the so-called posterior model probabilities; that is, it captures the weight each model gets in the BMA exercise. The figure only shows the 5,000 models with the highest posterior model probabilities. The best models are displayed on the left-hand side and are relatively parsimonious compared with those with low posterior model probabilities. Explanatory variables in the figure are displayed in descending order according to their posterior inclusion probabilities (the sum of the posterior probabilities of the models they are included in). In other words, the variables at the top of the figure are robustly important for the explanation of the variation in transmission lags, whereas the variables at the bottom of the figure do not matter much.

FIGURE 3. Bayesian Model Averaging, Model Inclusion. Notes: Response variable: transmission lag (the number of months to the maximum decrease in prices taken from the impulse responses). Columns denote individual models; variables are sorted by posterior inclusion probability in descending order. Blue color (darker in grayscale) = the variable is included and the estimated sign is positive. Red color (lighter in grayscale) = the variable is included and the estimated sign is negative. No color = the variable is not included in the model. The horizontal axis measures cumulative posterior model probabilities. Only the 5,000 models with the highest posterior model probabilities are shown.

The color (shading in the print version of this paper) of the cell corresponding to each variable included in a model represents the estimated sign of the regression parameter. Blue (darker in grayscale) denotes a positive sign, and red (lighter in grayscale) denotes a negative sign. For example, in the first model from the left the estimated regression sign is positive for *Financial Development*, positive for *Strictly Decreasing*, negative for *Monthly*, positive for *CB Independence*, negative for *Impact*, and positive for *Price Puzzle*. As can be seen from the figure, variables with high posterior inclusion probabilities usually exhibit quite stable regression signs. Nevertheless, for a more precise discussion of the importance of individual variables (analogous to statistical significance in the frequentist case), we need to turn to the numerical results of the BMA estimation, reported in table 5.

Table 5 shows the posterior means (weighted averages of the models displayed in figure 3) for all regression parameters and the corresponding posterior standard deviations. According to Masanjala and Papageorgiou (2008), variables with the ratio of the posterior mean to the posterior standard deviation larger than 1.3 can be considered effective (or "statistically significant" in the frequentist case). There are only three such variables: *Financial Development*, *Monthly*, and *Strictly Decreasing*. First, our results suggest that a higher degree of financial development in the country is associated with slower transmission of monetary policy shocks to the price level. Moreover, when researchers use monthly data in the VAR system, they are more likely to report shorter transmission lags. The BMA exercise also corroborates that the transmission lags taken from strictly decreasing impulse responses are much longer than the lags taken from hump-shaped impulse responses; the difference is approximately twenty-six months.

While many of the method characteristics appear to be relatively unimportant for the explanation of the reported transmission lags, a few (for example, *Sign Restrictions* or *Output Gap*) have moderate posterior inclusion probabilities. Because some of the method choices are generally considered misspecifications in the literature, we use the results of the BMA estimation to filter out the effects of these misspecifications from the average transmission lag. In other words, we define an ideal study with "best-practice" methodology and maximum publication characteristics (for example, the impact factor and the number of citations). Then we plug the chosen values of the explanatory variables into the results of the BMA estimation and evaluate the implied transmission lag.

TABLE 5. Why Do Transmission Lags Vary?

| Variable | PIP | Posterior Mean | Posterior Std. Dev. | Standardized Coef. |
|---|---|---|---|---|
| *Country Characteristics* |  |  |  |  |
| GDP per Capita | 0.099 | −0.447 | 1.647 | −0.0096 |
| GDP Growth | 0.087 | 0.111 | 0.444 | 0.0059 |
| Inflation | 0.053 | −0.337 | 1.918 | −0.0025 |
| **Financial Dev.** | **1.000** | **12.492** | **3.166** | **0.2630** |
| Openness | 0.029 | −0.056 | 0.631 | −0.0011 |
| CB Independence | 0.705 | 13.370 | 10.412 | 0.1002 |
| *Data Characteristics* |  |  |  |  |
| **Monthly** | **0.730** | **−4.175** | **3.036** | **−0.1045** |
| No. of Observations | 0.127 | −0.362 | 1.136 | −0.0123 |
| Average Year | 0.032 | 0.003 | 0.030 | 0.0012 |
| *Specification Characteristics* |  |  |  |  |
| GDP Deflator | 0.035 | −0.052 | 0.584 | −0.0010 |
| Single Regime | 0.031 | 0.039 | 0.395 | 0.0009 |
| No. of Lags | 0.023 | 0.014 | 0.436 | 0.0003 |
| Commodity Prices | 0.022 | −0.009 | 0.246 | −0.0002 |
| Money | 0.026 | −0.011 | 0.286 | −0.0003 |
| Foreign Variables | 0.030 | 0.039 | 0.385 | 0.0010 |
| Time Trend | 0.472 | 3.681 | 4.480 | 0.0643 |
| Seasonal | 0.020 | −0.004 | 0.307 | −0.0001 |
| No. of Variables | 0.028 | 0.036 | 0.400 | 0.0007 |
| Industrial Prod. | 0.025 | 0.008 | 0.352 | 0.0002 |
| Output Gap | 0.189 | −1.464 | 3.566 | −0.0130 |
| Other Measures | 0.059 | 0.199 | 1.038 | 0.0034 |
| *Estimation Characteristics* |  |  |  |  |
| BVAR | 0.096 | 0.337 | 1.278 | 0.0057 |
| FAVAR | 0.068 | 0.304 | 1.444 | 0.0034 |
| SVAR | 0.153 | −0.468 | 1.303 | −0.0112 |
| Sign Restrictions | 0.200 | 0.954 | 2.232 | 0.0177 |

TABLE 5 (continued).

| Variable | PIP | Posterior Mean | Posterior Std. Dev. | Standardized Coef. |
|---|---|---|---|---|
| *Publication Characteristics* | | | | |
| **Strictly Decreasing** | **1.000** | **26.122** | **1.798** | **0.6757** |
| Price Puzzle | 0.383 | 1.359 | 1.999 | 0.0351 |
| Study Citations | 0.039 | −0.005 | 0.205 | −0.0003 |
| Impact | 0.423 | −0.305 | 0.414 | −0.0381 |
| Central Banker | 0.044 | 0.075 | 0.497 | 0.0019 |
| Policymaker | 0.149 | 0.858 | 2.426 | 0.0106 |
| Native | 0.091 | −0.221 | 0.865 | −0.0057 |
| Publication Year | 0.048 | 0.011 | 0.070 | 0.0022 |
| Constant | 1.000 | 7.271 | NA | 0.3752 |
Notes: Estimated by Bayesian model averaging. Response variable: transmission lag (the number of months to the maximum decrease in prices taken from impulse responses). PIP = posterior inclusion probability. The posterior mean is analogous to the estimate of the regression coefficient in a standard regression; the posterior standard deviation is analogous to the standard error of the regression coefficient in a standard regression. Variables with posterior mean larger than 1.3 posterior standard deviations are typeset in bold; we consider such variables effective (following Masanjala & Papageorgiou 2008).

For the definition of the "ideal" study we prefer the use of more observations in the VAR system (that is, we plug in the sample maximum for variable *No. of Observations*), more recent data (*Average Year*), the estimation of the VAR system over a period of a single monetary policy regime (*Single Regime*), the inclusion of commodity prices in the VAR system (*Commodity Prices*), the inclusion of foreign variables (*Foreign*), the inclusion of seasonal dummies (*Seasonal*), the inclusion of more variables in the VAR (*No. of Variables*), the use of the output gap as a measure of economic activity (*Output Gap*; *Industrial Production* and *Other Measures* are set to zero), the use of Bayesian VAR (*BVAR*), the use of sign restrictions (*Sign Restrictions*; *FAVAR* and *SVAR* are set to zero), more citations of the study (*Study Citations*), and a higher impact factor (*Impact*). All other variables are set to their sample means.

The average transmission lag implied by our definition of the ideal study is 29.2 months, which is less than the simple average by approximately 4 months. The estimated transmission lag hardly changes when FAVAR or SVAR are chosen for the definition of best-practice methodology; the result is also robust to other marginal changes to the definition. On the other hand, the implied transmission lag decreases greatly if one prefers hump-shaped impulse responses: in this case the estimated value is only 16.3 months. Moreover, if one prefers impulse responses that do not exhibit the price puzzle, the implied value diminishes by another month. In sum, when the effect of misspecifications is filtered out and one does not prefer any particular type of impulse response, our results suggest that prices bottom out approximately two-and-a-half years after a monetary contraction.

## 4. Robustness Checks and Additional Results

Our analysis, based on the results of BMA, attributes the differences in transmission lags between (and within) developed and post-transition countries to differences in the level of financial development. The BMA exercise carried out in the previous section controls for methodology and other aspects associated with estimating impulse responses. Nevertheless, it is still useful to illustrate that the differences in results between developed and post-transition countries are not caused by differences in the frequency of reporting strictly decreasing impulse responses or impulse responses showing the price puzzle. To this end, we replicate table 3 but only focus on the sub-samples of impulse responses that are hump shaped (table 6) or that do not exhibit the price puzzle (table 7).

The tables show that developed countries exhibit longer transmission lags even if strictly decreasing impulse responses or impulse responses showing the price puzzle are disregarded. But the difference is smaller for the sub-sample of hump-shaped impulse responses, where some developed countries (for example, Italy) exhibit shorter transmission lags than some post-transition countries (for example, Poland). There are two potential explanations of this result. First, compared with table 3, now we only have approximately half the number of observations, and for some countries we are even left with less than five impulse responses, which makes the average number imprecise. Second, strictly decreasing impulse responses, which are associated with longer transmission lags, are more often reported for developed economies than for post-transition economies. The reason is that shorter data spans are available for post-transition countries, which makes researchers often choose monthly data. Since monthly data are associated with shorter reported lags, researchers investigating monetary transmission in post-transition countries are less likely to report strictly decreasing impulse responses. Nevertheless, in the BMA estimation we control for data frequency as well as for the shape of the impulse response, and financial development still emerges as the most important factor causing cross-country differences in transmission lags.

TABLE 6. Transmission Lags Differ across Countries (hump-shaped impulse responses)

| Economy | Average Transmission Lag |
|---|---|
| *Developed Economies* | |
| United States | 23.2 |
| Euro Area | 39.5 |
| Japan | 40.5 |
| Germany | 19.4 |
| United Kingdom | 10.0 |
| France | 24.0 |
| Italy | 9.2 |
| *Post-Transition Economies* | |
| Poland | 15.4 |
| Czech Republic | 14.8 |
| Hungary | 14.4 |
| Slovakia | 5.0 |
| Slovenia | 13.0 |
Notes: The table shows the average number of months to the maximum decrease in prices taken from the impulse responses reported for the corresponding country. Strictly decreasing impulse responses are omitted from this analysis.

In our baseline model from the previous section we combine data from hump-shaped and strictly decreasing impulse response functions. For strictly decreasing impulse responses, however, our definition of the transmission lag (the maximum effect of a monetary contraction on prices) is influenced by the reporting window chosen by researchers. To see whether the result concerning financial development is robust to omitting data from strictly decreasing impulse response functions, we repeat the BMA estimation from the previous section using a sub-sample of hump-shaped impulse responses.

TABLE 7. Transmission Lags Differ across Countries (responses not showing the price puzzle)

| Economy | Average Transmission Lag |
|---|---|
| *Developed Economies* | |
| United States | 40.5 |
| Euro Area | 49.2 |
| Japan | 57.0 |
| Germany | 34.5 |
| United Kingdom | 10.0 |
| France | 52.8 |
| Italy | 30.0 |
| *Post-Transition Economies* | |
| Poland | 14.0 |
| Czech Republic | 8.8 |
| Hungary | 15.4 |
| Slovakia | 10.7 |
| Slovenia | 17.8 |
Notes: The table shows the average number of months to the maximum decrease in prices taken from the impulse responses reported for the corresponding country. Impulse responses exhibiting the price puzzle are omitted from this analysis.

The results are presented graphically in figure 4. The variable corresponding to financial development retains its estimated sign from the baseline model and still represents the most important country-level factor explaining the differences in monetary transmission lags. Compared with the baseline model, in this specification additional method variables seem to be important. The use of other measures than GDP, the output gap, or industrial production as a proxy for economic activity is associated with slower reported transmission. The choice to represent prices by the GDP deflator instead of the consumer price index on average translates into longer transmission lags. Also, the inclusion of foreign variables in the VAR system makes researchers report slower transmission.

FIGURE 4. Bayesian Model Averaging, Model Inclusion (hump-shaped impulse responses). Notes: Response variable: transmission lag (the number of months to the maximum decrease in prices taken from the impulse responses). Only transmission lags from hump-shaped impulse responses are included in the estimation. Columns denote individual models; variables are sorted by posterior inclusion probability in descending order. Blue color (darker in grayscale) = the variable is included and the estimated sign is positive. Red color (lighter in grayscale) = the variable is included and the estimated sign is negative. No color = the variable is not included in the model. The horizontal axis measures cumulative posterior model probabilities. Only the 5,000 models with the highest posterior model probabilities are shown.

By excluding all strictly decreasing impulse responses, however, we lose half of the information contained in our data set. For this reason we consider a second way of taking into account the effect of the reporting window: censored regression. The reporting window of primary studies is often set to five years, so we use sixty months as the upper limit and estimate the regression using the Tobit model. (Changing the upper limit to three or four years, the amount of time sometimes used as the reporting window, does not qualitatively affect the results.) Unfortunately, it is cumbersome to estimate Tobit using BMA. Thus, we estimate a general model with all potential explanatory variables and then employ the general-to-specific approach. The general model is reported in table 12 in appendix 2. The inclusion of all potential explanatory variables, many of which may not be important for explanation of the differences in transmission lags, inflates the standard errors of the relevant variables. Hence, in the next step we eliminate the insignificant variables one by one, starting from the least significant variable. As mentioned before, the general-to-specific approach is far from perfect—but in this case it represents an easy alternative to BMA.

The results presented in table 8 and table 12 corroborate that, even using this methodology, financial development is highly important for the explanation of transmission lags; in both specifications it is significant at the 1 percent level. The use of monthly data is associated with faster reported transmission, which is also consistent with the baseline model. In line with our results from the previous sections, table 8 suggests that impulse responses exhibiting the price puzzle are likely to show longer transmission lags. In contrast to the baseline model, some other variables seem to be important as well: *GDP per Capita*, *Inflation*, and *Openness*, among others. Because, however, the results concerning these variables are not confirmed by other specifications, we do not want to put much emphasis on these variables. The variable *Strictly Decreasing*, which was crucial for the baseline BMA estimation, is omitted from the present analysis because it defines the censoring process.

TABLE 8. Censored Regression, Specific Model

| Response Variable: Transmission Lag | | |
|---|---|---|
| GDP per Capita | −11.48^{**} | (4.793) |
| Price Puzzle | 4.667^{**} | (2.343) |
| Inflation | −17.25^{**} | (8.739) |
| Financial Dev. | 21.61^{***} | (5.375) |
| Openness | −12.67^{***} | (4.670) |
| CB Independence | 29.38^{***} | (10.64) |
| Monthly | −12.04^{***} | (3.821) |
| No. of Observations | 6.526^{**} | (2.951) |
| Policymaker | 12.37^{**} | (5.012) |
| Constant | 86.58^{**} | (43.69) |
| Observations | 198 | |
Notes: Standard errors in parentheses. Estimated by Tobit with the upper limit for transmission lags equal to sixty months. The specific model is a result of the backward stepwise regression procedure applied to the general model, which is reported in appendix 2 (the cut-off level for p-values was 0.1). ^{***}, ^{**}, and ^{*} denote significance at the 1 percent, 5 percent, and 10 percent levels, respectively.

So far we have analyzed the time it takes before a monetary contraction translates into the maximum effect on the price level. The extent of the maximum effect, however, varies a lot across different impulse responses. Therefore, as a complement to the previous analysis, we collect data on how long it takes before a 1-percentage-point increase in the policy rate leads to a decrease in the price level of 0.1 percent. This number was chosen because most of the impulse response functions in our sample (173 out of 198) reach this level at some point. In contrast, if we chose a value of 0.5 percent, for example, we would have to disregard almost two-thirds of all the impulse responses.

The results of the BMA estimation using the new response variable are reported in figure 5. Again, the shape of the impulse response and the frequency of the data used in the VAR system seem to be associated with the reported transmission lag. Financial development still belongs among the most important country-level variables, together with central bank independence and trade openness. According to this specification, monetary transmission is faster in countries that are more open to international trade and that have a more independent central bank; these results may point at the importance of the exchange rate and expectation channels of monetary transmission. Additionally, some method variables matter for the estimated transmission lag: for example, the use of sign restrictions, structural VAR, and seasonal adjustment. Our results also suggest that articles published in journals with a high impact factor tend to present faster monetary transmission.

FIGURE 5. Bayesian Model Averaging, Model Inclusion (time to –0.1 percent decrease in prices). Notes: Response variable: the number of months to a –0.1 percent decrease in prices following a 1-percentage-point increase in the policy rate. Columns denote individual models; variables are sorted by posterior inclusion probability in descending order. Blue color (darker in grayscale) = the variable is included and the estimated sign is positive. Red color (lighter in grayscale) = the variable is included and the estimated sign is negative. No color = the variable is not included in the model. The horizontal axis measures cumulative posterior model probabilities. Only the 5,000 models with the highest posterior model probabilities are shown.

## 5. Concluding Remarks

Building on a sample of sixty-seven previous empirical studies, we examine why the reported transmission lags of monetary policy vary. Our results suggest that the cross-country variation in transmission is robustly associated with differences in financial development. To explain the variation of results between different studies for the same country, the frequency of the data used is important: the use of monthly data makes researchers report transmission faster by four months, holding other things constant. This is in line with Ghysels (2012), who shows that responses from low- and high-frequency VARs may indeed differ due to mixed-frequency sampling or temporal aggregation of shocks. The shape of the impulse response matters as well. Strictly decreasing impulse responses, which may suggest that the underlying VAR system is not stationary, exhibit much longer transmission lags.

The key result of our meta-analysis is that a higher degree of financial development translates into slower transmission of monetary policy. The finding can be interpreted in the following way. If financial institutions lack opportunities to protect themselves against unexpected monetary policy actions (due to either low levels of capitalization or low sophistication of financial instruments provided by the undeveloped financial system), they need to react immediately to monetary policy shocks, thus speeding up the transmission. In financially developed countries, in contrast, financial institutions have more opportunities to hedge against surprises in monetary policy stance, causing greater delays in the transmission of monetary policy shocks.

More generally, our results imply that monetary transmission may slow down as the financial system of emerging countries develops, since financial innovations allow banks to protect better against surprise shocks in monetary policy.

## Appendix 1. Diagnostics of Bayesian Model Averaging

TABLE 9. Summary of BMA Estimation (baseline model)

| *Mean No. Regressors* | *Draws* | *Burn-Ins* | *Time* |
| --- | --- | --- | --- |
| 8.1261 | $2 \cdot 10^{8}$ | $1 \cdot 10^{8}$ | 11.88852 hours |
| *No. Models Visited* | *Modelspace* | *Visited* | *Topmodels* |
| 83,511,152 | $8.6 \cdot 10^{9}$ | 0.97% | 34% |
| *Corr. PMP* | *No. Obs.* | *Model Prior* | *g-Prior* |
| 0.9999 | 198 | Uniform/16.5 | UIP |
| *Shrinkage Stats* | | | |
| Av. = 0.995 | | | |
**Note:** UIP = unit information prior, PMP = posterior model probability.

FIGURE 6. Model Size and Convergence (baseline model)

TABLE 10. Summary of BMA Estimation (hump-shaped impulse responses)

| *Mean No. Regressors* | *Draws* | *Burn-Ins* | *Time* |
| --- | --- | --- | --- |
| 10.7143 | $2 \cdot 10^{8}$ | $1 \cdot 10^{8}$ | 12.15215 hours |
| *No. Models Visited* | *Modelspace* | *Visited* | *Topmodels* |
| 104,093,439 | $4.3 \cdot 10^{9}$ | 2.4% | 16% |
| *Corr. PMP* | *No. Obs.* | *Model Prior* | *g-Prior* |
| 0.9997 | 100 | Uniform/16 | UIP |
| *Shrinkage Stats* | | | |
| Av. = 0.9901 | | | |
**Note:** UIP = unit information prior, PMP = posterior model probability.

FIGURE 7. Model Size and Convergence (hump-shaped impulse responses)

TABLE 11. Summary of BMA Estimation (time to −0.1 percent decrease in prices)

| *Mean No. Regressors* | *Draws* | *Burn-Ins* | *Time* |
| --- | --- | --- | --- |
| 9.6899 | $2 \cdot 10^{8}$ | $1 \cdot 10^{8}$ | 12.0976 hours |
| *No. Models Visited* | *Modelspace* | *Visited* | *Topmodels* |
| 87,125,827 | $8.6 \cdot 10^{9}$ | 1% | 30% |
| *Corr. PMP* | *No. Obs.* | *Model Prior* | *g-Prior* |
| 0.9999 | 173 | Uniform/16.5 | UIP |
| *Shrinkage Stats* | | | |
| Av. = 0.9943 | | | |
**Note:** UIP = unit information prior, PMP = posterior model probability.

FIGURE 8. Model Size and Convergence (time to –0.1 percent decrease in prices)

## Appendix 2. Results of Censored Regression

TABLE 12. Censored Regression, General Model (all variables are included)

| **Response Variable: Transmission Lag** | | |
| --- | --- | --- |
| *Country Characteristics* | | |
| GDP per Capita | −9.792^{*} | (5.192) |
| GDP Growth | 1.512 | (1.346) |
| Inflation | −17.41^{**} | (8.695) |
| Financial Dev. | 22.17^{***} | (6.084) |
| Openness | −11.16^{**} | (5.595) |
| CB Independence | 30.20^{**} | (12.27) |
| *Data Characteristics* | | |
| Monthly | −4.402 | (6.920) |
| No. of Observations | 4.287 | (5.186) |
| Average Year | −0.168 | (0.367) |
| *Specification Characteristics* | | |
| GDP Deflator | 5.102 | (4.281) |
| Single Regime | 4.143 | (3.497) |
| No. of Lags | 8.132^{*} | (4.744) |
| Commodity Prices | −1.284 | (2.861) |
| Money | 1.768 | (2.949) |
| Foreign Variables | 4.102 | (3.400) |
| Time Trend | 2.700 | (5.791) |
| Seasonal | 7.231^{*} | (4.057) |
| No. of Variables | 1.352 | (3.536) |
| Industrial Prod. | −6.785^{*} | (3.904) |
| Output Gap | −10.41 | (7.681) |
| Other Measures | −6.246 | (5.017) |
| *Estimation Characteristics* | | |
| BVAR | −1.147 | (5.094) |
| FAVAR | 14.53^{**} | (6.525) |
| SVAR | −4.243 | (3.008) |
| Sign Restrictions | −3.270 | (5.163) |

TABLE 12. (Continued)

| **Response Variable: Transmission Lag** | | |
| --- | --- | --- |
| *Publication Characteristics* | | |
| Price Puzzle | 3.651 | (2.537) |
| Study Citations | −0.717 | (1.734) |
| Impact | −0.742 | (0.699) |
| Central Banker | 5.313 | (3.633) |
| Policymaker | 9.024 | (6.137) |
| Native | −1.996 | (3.043) |
| Publication Year | 0.0475 | (0.453) |
| Constant | 62.32 | (50.10) |
| Observations | 198 | |
**Notes:** Standard errors in parentheses. Estimated by Tobit with the upper limit for transmission lags equal to sixty months. ^{***}, ^{**}, and ^{*} denote significance at the 1 percent, 5 percent, and 10 percent levels, respectively.

## REFERENCES

Andries, M. A. 2008. “Monetary Policy Transmission Mechanism in Romania—A VAR Approach.” *Theoretical and Applied Economics* 11 (528): 250–60.

Anzuini, A., and A. Levy. 2007. “Monetary Policy Shocks in the New EU Members: A VAR Approach.” *Applied Economics* 39 (9): 1147–61.

Arin, K. P., and S. P. Jolly. 2005. “Trans-Tasman Transmission of Monetary Shocks: Evidence from a VAR Approach.” *Atlantic Economic Journal* 33 (3): 267–83.

Arnone, M., B. J. Laurens, J.-F. Segalotto, and M. Sommer. 2009. “Central Bank Autonomy: Lessons from Global Trends.” *IMF Staff Papers* 56 (2): 263–96.

Bagliano, F. C., and C. A. Favero. 1998. “Measuring Monetary Policy with VAR Models: An Evaluation.” *European Economic Review* 42 (6): 1069–1112.

———. 1999. “Information from Financial Markets and VAR Measures of Monetary Policy.” *European Economic Review* 43 (4–6): 825–37.

Banbura, M., D. Giannone, and L. Reichlin. 2010. “Large Bayesian VARs.” *Journal of Applied Econometrics* 25 (1): 71–92.

Bank of England. 1999. “The Transmission Mechanism of Monetary Policy.” Paper by the Monetary Policy Committee. (April).

Batini, N., and E. Nelson. 2001. “The Lag from Monetary Policy Actions to Inflation: Friedman Revisited.” *International Finance* 4 (32): 381–400.

Belviso, F., and F. Milani. 2006. “Structural Factor-Augmented VARs (SFAVARs) and the Effects of Monetary Policy.” *B.E. Journal of Macroeconomics* 6 (3): 1–44.

Bernanke, B., J. Boivin, and P. S. Eliasz. 2005. “Measuring the Effects of Monetary Policy: A Factor-Augmented Vector Autoregressive (FAVAR) Approach.” *Quarterly Journal of Economics* 120 (1): 387–422.

Bernanke, B. S., M. Gertler, and M. Watson. 1997. “Systemic Monetary Policy and the Effects of Oil Price Shocks.” *Brookings Papers on Economic Activity* 1 (1): 91–142.

Boivin, J., and M. P. Giannoni. 2009. “Global Forces and Monetary Policy Effectiveness.” In *International Dimensions of Monetary Policy*, 429–78. National Bureau of Economic Research, Inc.

Boivin, J., M. P. Giannoni, and B. Mojon. 2009. “How Has the Euro Changed the Monetary Transmission Mechanism?” In *NBER Macroeconomics Annual 2008*, ed. D. Acemoglu, K. Rogoff, and M. Woodford, 1–51. National Bureau of Economic Research, Inc.

Borys, M., R. Horvath, and M. Franta. 2009. “The Effects of Monetary Policy in the Czech Republic: An Empirical Study.” *Empirica* 36 (4): 419–43.

Bredin, D., and G. O’Reilly. 2004. “An Analysis of the Transmission Mechanism of Monetary Policy in Ireland.” *Applied Economics* 36 (1): 49–58.

Brissimis, S. N., and N. S. Magginas. 2006. “Forward-Looking Information in VAR Models and the Price Puzzle.” *Journal of Monetary Economics* 53 (6): 1225–34.

Brunner, A. D. 2000. “On the Derivation of Monetary Policy Shocks: Should We Throw the VAR Out with the Bath Water?” *Journal of Money, Credit and Banking* 32 (2): 254–79.

Buckle, R. A., K. Kim, H. Kirkham, N. McLellan, and J. Sharma. 2007. “A Structural VAR Business Cycle Model for a Volatile Small Open Economy.” *Economic Modelling* 24 (6): 990–1017.

Card, D., J. Kluve, and A. Weber. 2010. “Active Labour Market Policy Evaluations: A Meta-Analysis.” *Economic Journal* 120 (548): F452–F477.

Cecchetti, S. G. 1999. “Legal Structure, Financial Structure, and the Monetary Policy Transmission Mechanism.” *Economic Policy Review* (Federal Reserve Bank of New York) 5 (2): 9–28.

Cespedes, B., E. Lima, and A. Maka. 2008. “Monetary Policy, Inflation and the Level of Economic Activity in Brazil after the Real Plan: Stylized Facts from SVAR Models.” *Revista Brasileira de Economia* 62 (2): 123–60.

Christiano, L. J., M. Eichenbaum, and C. Evans. 1996. “The Effects of Monetary Policy Shocks: Evidence from the Flow of Funds.” *Review of Economics and Statistics* 78 (1): 16–34.

———. 1999. “Monetary Policy Shocks: What Have We Learned and to What End?” In *Handbook of Macroeconomics*, Vol. 1, ed. J. B. Taylor and M. Woodford, 65–148. Elsevier.

Cushman, D. O., and T. Zha. 1997. “Identifying Monetary Policy in a Small Open Economy under Flexible Exchange Rates.” *Journal of Monetary Economics* 39 (3): 433–48.

De Arcangelis, G., and G. Di Giorgio. 2001. “Measuring Monetary Policy Shocks in a Small Open Economy.” *Economic Notes* 30 (1): 81–107.

Dedola, L., and F. Lippi. 2005. “The Monetary Transmission Mechanism: Evidence from the Industries of Five OECD Countries.” *European Economic Review* 49 (6): 1543–69.

Disdier, A.-C., and K. Head. 2008. “The Puzzling Persistence of the Distance Effect on Bilateral Trade.” *Review of Economics and Statistics* 90 (1): 37–48.

Dornbusch, R., C. Favero, F. Giavazzi, H. Genberg, and A. K. Rose. 1998. “Immediate Challenges for the European Central Bank.” *Economic Policy* 13 (26): 17–64.

Durlauf, S., A. Kourtellos, and C. Tan. 2008. “Are Any Growth Theories Robust?” *Economic Journal* 118 (527): 329–46.

European Forecasting Network. 2004. “Monetary Transmission in Acceding Countries.” In *The Euro Area and the Acceding Countries*, 97–142 (annex 4). European University Institute.

Ehrmann, M. 2000. “Comparing Monetary Policy Transmission across European Countries.” *Review of World Economics* 136 (1): 58–83.

Ehrmann, M., L. Gambacorta, J. Martinez-Pages, P. Sevestre, and A. Worms. 2003. “The Effects of Monetary Policy in the Euro Area.” *Oxford Review of Economic Policy* 19 (1): 58–72.

Eichenbaum, M. 1992. “Comment on ‘Interpreting the Macroeconomic Time Series Facts: The Effects of Monetary Policy’.” *European Economic Review* 36 (5): 1001–11.

Eicher, T. S., C. Papageorgiou, and A. E. Raftery. 2011. “Default Priors and Predictive Performance in Bayesian Model Averaging, with Application to Growth Determinants.” *Journal of Applied Econometrics* 26 (1): 30–55.

Eickmeier, S., B. Hofmann, and A. Worms. 2009. “Macroeconomic Fluctuations and Bank Lending: Evidence for Germany and the Euro Area.” *German Economic Review* 10: 193–223.

Elbourne, A. 2008. “The UK Housing Market and the Monetary Policy Transmission Mechanism: An SVAR Approach.” *Journal of Housing Economics* 17 (1): 65–87.

Elbourne, A., and J. de Haan. 2006. “Financial Structure and Monetary Policy Transmission in Transition Countries.” *Journal of Comparative Economics* 34 (1): 1–23.

———. 2009. “Modeling Monetary Policy Transmission in Acceding Countries: Vector Autoregression versus Structural Vector Autoregression.” *Emerging Markets Finance and Trade* 45 (2): 4–20.

European Central Bank. 2010. “Monthly Bulletin.” (May).

Feldkircher, M., and S. Zeugner. 2009. “Benchmark Priors Revisited: On Adaptive Shrinkage and the Supermodel Effect in Bayesian Model Averaging.” IMF Working Paper No. 09/202.

Fernandez, C., E. Ley, and M. F. J. Steel. 2001. “Model Uncertainty in Cross-Country Growth Regressions.” *Journal of Applied Econometrics* 16 (5): 563–76.

Forni, M., and L. Gambetti. 2010. “The Dynamic Effects of Monetary Policy: A Structural Factor Model Approach.” *Journal of Monetary Economics* 57 (2): 203–16.

Friedman, M. 1972. “Have Monetary Policies Failed?” *American Economic Review* 62 (2): 11–18.

Fujiwara, I. 2004. “Output Composition of the Monetary Policy Transmission Mechanism in Japan.” *Topics in Macroeconomics* 4 (1): 1–21.

Gan, W. B., and L. Y. Soon. 2003. “Characterizing the Monetary Transmission Mechanism in a Small Open Economy: The Case of Malaysia.” *Singapore Economic Review* 48 (2): 113–34.

Ghysels, E. 2012. “Macroeconomics and the Reality of Mixed Frequency Data.” Mimeo, Department of Economics, University of North Carolina (UNC) at Chapel Hill.

Goodhart, C. A. 2001. “Monetary Transmission Lags and the Formulation of the Policy Decision on Interest Rates.” *Review* (Federal Reserve Bank of St. Louis) 83 (4): 165–86.

Hanson, M. S. 2004. “The ‘Price Puzzle’ Reconsidered.” *Journal of Monetary Economics* 51 (7): 1385–1413.

Havranek, T., and Z. Irsova. 2011. “Estimating Vertical Spillovers from FDI: Why Results Vary and What the True Effect Is.” *Journal of International Economics* 85 (2): 234–44.

Horvath, R., and M. Rusnak. 2009. “How Important Are Foreign Shocks in a Small Open Economy? The Case of Slovakia.” *Global Economy Journal* 9 (1): Article 5.

Hulsewig, O., E. Mayer, and T. Wollmershauser. 2006. “Bank Loan Supply and Monetary Policy Transmission in Germany: An Assessment Based on Matching Impulse Responses.” *Journal of Banking and Finance* 30 (1): 2893–2910.

Jang, K., and M. Ogaki. 2004. “The Effects of Monetary Policy Shocks on Exchange Rates: A Structural Vector Error Correction Model Approach.” *Journal of the Japanese and International Economies* 18 (1): 99–114.

Jarocinski, M. 2010. “Responses to Monetary Policy Shocks in the East and the West of Europe: A Comparison.” *Journal of Applied Econometrics* 25 (5): 833–68.

Jarocinski, M., and F. R. Smets. 2008. “House Prices and the Stance of Monetary Policy.” *Review* (Federal Reserve Bank of St. Louis) 90 (4): 339–65.

Kim, S. 2001. “International Transmission of U.S. Monetary Policy Shocks: Evidence from VARs.” *Journal of Monetary Economics* 48 (2): 339–72.

———. 2002. “Exchange Rate Stabilization in the ERM: Identifying European Monetary Policy Reactions.” *Journal of International Money and Finance* 21 (3): 413–34.

Koop, G. 2003. *Bayesian Econometrics*. John Wiley & Sons.

Krusec, D. 2010. “The ‘Price Puzzle’ in the Monetary Transmission VARs with Long-Run Restrictions.” *Economics Letters* 106 (3): 147–50.

Kubo, A. 2008. “Macroeconomic Impact of Monetary Policy Shocks: Evidence from Recent Experience in Thailand.” *Journal of Asian Economics* 19 (1): 83–91.

Lagana, G., and A. Mountford. 2005. “Measuring Monetary Policy in the UK: A Factor-Augmented Vector Autoregression Model Approach.” *Manchester School* 73 (s1): 77–98.

Lange, R. H. 2010. “Regime-Switching Monetary Policy in Canada.” *Journal of Macroeconomics* 32 (3): 782–96.

Leeper, E. M., C. A. Sims, and T. Zha. 1996. “What Does Monetary Policy Do?” *Brookings Papers on Economic Activity* 27 (2): 1–78.

Li, Y. D., T. B. Iscan, and K. Xu. 2010. “The Impact of Monetary Policy Shocks on Stock Prices: Evidence from Canada and the United States.” *Journal of International Money and Finance* 29 (5): 876–96.

Lütkepohl, H. 2005. *New Introduction to Multiple Time Series Analysis*. Springer-Verlag.

Masanjala, W. H., and C. Papageorgiou. 2008. “Rough and Lonely Road to Prosperity: A Reexamination of the Sources of Growth in Africa Using Bayesian Model Averaging.” *Journal of Applied Econometrics* 23 (5): 671–82.

McMillan, W. D. 2001. “The Effects of Monetary Policy Shocks: Comparing Contemporaneous versus Long-Run Identifying Restrictions.” *Southern Economic Journal* 67 (3): 618–36.

Mertens, K. 2008. “Deposit Rate Ceilings and Monetary Transmission in the US.” *Journal of Monetary Economics* 55 (7): 1290–1302.

Minella, A. 2003. “Monetary Policy and Inflation in Brazil (1975–2000): A VAR Estimation.” *Revista Brasileira de Economia* 57 (3): 605–35.

Mojon, B. 2008. “When Did Unsystematic Monetary Policy Have an Effect on Inflation?” *European Economic Review* 52 (3): 487–97.

Mojon, B., and G. Peersman. 2001. “A VAR Description of the Effects of Monetary Policy in the Individual Countries of the Euro Area.” ECB Working Paper No. 92.

———. 2003. “A VAR Description of the Effects of Monetary Policy in the Individual Countries of the Euro Area.” In *Monetary Policy Transmission in the Euro Area*, ed. A. K. I. Angeloni and B. Mojon, 56–74 (chapter 1). Cambridge University Press.

Moral-Benito, E. 2011. “Model Averaging in Economics.” Banco de Espana Working Paper No. 1123.

Mountford, A. 2005. “Leaning into the Wind: A Structural VAR Investigation of UK Monetary Policy.” *Oxford Bulletin of Economics and Statistics* 67 (5): 597–621.

Nakashima, K. 2006. “The Bank of Japan’s Operating Procedures and the Identification of Monetary Policy Shocks: A Reexamination Using the Bernanke-Mihov Approach.” *Journal of the Japanese and International Economies* 20 (3): 406–33.

Normandin, M., and L. Phaneuf. 2004. “Monetary Policy Shocks: Testing Identification Conditions under Time-Varying Conditional Volatility.” *Journal of Monetary Economics* 51 (6): 1217–43.

Oros, C., and C. Romocea-Turcu. 2009. “The Monetary Transmission Mechanisms in the CEECs: A Structural VAR Approach.” *Applied Econometrics and International Development* 9 (2): 73–86.

Peersman, G. 2004. “The Transmission of Monetary Policy in the Euro Area: Are the Effects Different across Countries?” *Oxford Bulletin of Economics and Statistics* 66 (3): 285–30.

———. 2005. “What Caused the Early Millennium Slowdown? Evidence Based on Vector Autoregressions.” *Journal of Applied Econometrics* 20 (2): 185–207.

Peersman, G., and F. Smets. 2001. “The Monetary Transmission Mechanism in the Euro Area: More Evidence from VAR Analysis.” ECB Working Paper No. 91.

Peersman, G., and R. Straub. 2009. “Technology Shocks and Robust Sign Restrictions in a Euro Area SVAR.” *International Economic Review* 50 (3): 727–50.

Pobre, M. L. 2003. “Sources of Shocks and Monetary Policy in the 1997 Asian Crisis: The Case of Korea and Thailand.” *Osaka Economic Papers* 53 (3): 362–73.

Rafiq, M. A., and S. K. Mallick. 2008. “The Effect of Monetary Policy on Output in EMU3: A Sign Restriction Approach.” *Journal of Macroeconomics* 30 (4): 1756–91.

Romer, C. D., and D. H. Romer. 2004. “A New Measure of Monetary Shocks: Derivation and Implications.” *American Economic Review* 94 (4): 1055–84.

Rusnak, M., T. Havranek, and R. Horvath. 2013. “How to Solve the Price Puzzle? A Meta-Analysis.” *Journal of Money, Credit and Banking* 45 (1): 37–70.

Sala-I-Martin, X., G. Doppelhofer, and R. I. Miller. 2004. “Determinants of Long-Term Growth: A Bayesian Averaging of Classical Estimates (BACE) Approach.” *American Economic Review* 94 (4): 813–35.

Shioji, E. 2000. “Identifying Monetary Policy Shocks in Japan.” *Journal of the Japanese and International Economies* 14 (1): 22–42.

Sims, C. A., and T. Zha. 1998. “Bayesian Methods for Dynamic Multivariate Models.” *International Economic Review* 39 (4): 949–68.

Smets, F. 1997. “Measuring Monetary Policy Shocks in France, Germany and Italy: The Role of the Exchange Rate.” *Swiss Journal of Economics and Statistics* 133 (3): 597–616.

Sousa, J., and A. Zaghini. 2008. “Monetary Policy Shocks in the Euro Area and Global Liquidity Spillovers.” *International Journal of Finance and Economics* 13 (3): 205–18.

Stanley, T. D. 2001. “Wheat from Chaff: Meta-Analysis as Quantitative Literature Review.” *Journal of Economic Perspectives* 15 (3): 131–50.

Taylor, J. B., and V. Wieland. 2012. “Surprising Comparative Properties of Monetary Models: Results from a New Model Database.” *Review of Economics and Statistics* 94 (3): 800–816.

Vargas-Silva, C. 2008. “Monetary Policy and the US Housing Market: A VAR Analysis Imposing Sign Restrictions.” *Journal of Macroeconomics* 30 (3): 97–90.

Voss, G., and L. Willard. 2009. “Monetary Policy and the Exchange Rate: Evidence from a Two-Country Model.” *Journal of Macroeconomics* 31 (4): 708–20.

Wu, T. 2003. “Stylized Facts on Nominal Term Structure and Business Cycles: An Empirical VAR Study.” *Applied Economics* 35 (8): 901–06.

## ENDNOTES

1. The definition of the two groups is somewhat problematic. The Czech Republic, for example, has been considered a developed economy by the World Bank since 2006. We include the country in the second group because pre-2006 time series constitute the bulk of the data used by studies in our sample.
