# What this package reproduces

Generated when the package was published, from its own targets and its own output, so
it cannot claim something the code does not do.

**149 of the 150 numbers this paper prints for these tables are reproduced.**

## Not matching the printed paper (1)

Cells are named as they are in `results.json`. The reason for each follows the table.

| cell | paper | this code |
|---|---|---|
| Text F3 mean of study-level medians (NOT reproduced, see run.R) | 0.0099 | 0.009999 |

The paper prints 0.0099. This code follows the authors' own line for the same quantity and gives 0.0099988, which rounds to 0.0100. It is not a truncation convention: across this paper's other reproduced numbers, 77 match under rounding and would fail under truncation.

## Reproduced (149)

| cell | paper | this code |
|---|---|---|
| T9 OLS SEPCC coef | -1.5708 | -1.570803 |
| T9 OLS SEPCC se | 0.8567 | 0.856737 |
| T9 OLS Samplesize coef | -0.0363 | -0.036294 |
| T9 OLS Samplesize se | 0.011 | 0.010999 |
| T9 OLS T coef | 0.0141 | 0.014134 |
| T9 OLS T se | 0.0107 | 0.010731 |
| T9 OLS sampleyear coef | 0.004 | 0.003996 |
| T9 OLS sampleyear se | 0.0033 | 0.003272 |
| T9 OLS developed coef | 0.1689 | 0.168872 |
| T9 OLS developed se | 0.0211 | 0.021073 |
| T9 OLS undeveloped coef | 0.1008 | 0.100807 |
| T9 OLS undeveloped se | 0.0166 | 0.016564 |
| T9 OLS quadratic coef | -0.008 | -0.008047 |
| T9 OLS quadratic se | 0.0204 | 0.020448 |
| T9 OLS endogeneity coef | 0.024 | 0.024024 |
| T9 OLS endogeneity se | 0.0292 | 0.029167 |
| T9 OLS macro coef | -0.004 | -0.003953 |
| T9 OLS macro se | 0.0364 | 0.036446 |
| T9 OLS someAveraged coef | -0.0023 | -0.002307 |
| T9 OLS someAveraged se | 0.0285 | 0.028497 |
| T9 OLS dummies coef | 0.2232 | 0.223247 |
| T9 OLS dummies se | 0.0373 | 0.037254 |
| T9 OLS NPL coef | 0.0299 | 0.029881 |
| T9 OLS NPL se | 0.0259 | 0.025949 |
| T9 OLS Zscore coef | 0.0116 | 0.011586 |
| T9 OLS Zscore se | 0.0249 | 0.024876 |
| T9 OLS profit_volat coef | 0.0284 | 0.028409 |
| T9 OLS profit_volat se | 0.0206 | 0.020591 |
| T9 OLS profitability coef | -0.0142 | -0.014156 |
| T9 OLS profitability se | 0.027 | 0.026974 |
| T9 OLS capitalization coef | 0.0184 | 0.018381 |
| T9 OLS capitalization se | 0.024 | 0.023967 |
| T9 OLS DtoD coef | -0.0157 | -0.015699 |
| T9 OLS DtoD se | 0.0337 | 0.033661 |
| T9 OLS Hstatistic coef | 0.1629 | 0.162936 |
| T9 OLS Hstatistic se | 0.0308 | 0.030815 |
| T9 OLS Boone coef | 0.001 | 0.001003 |
| T9 OLS Boone se | 0.0271 | 0.027086 |
| T9 OLS Concentration coef | 0.0351 | 0.035075 |
| T9 OLS Concentration se | 0.0356 | 0.03556 |
| T9 OLS Lerner coef | 0.0485 | 0.048507 |
| T9 OLS Lerner se | 0.0188 | 0.018761 |
| T9 OLS HHI coef | 0.0444 | 0.044395 |
| T9 OLS HHI se | 0.0257 | 0.025721 |
| T9 OLS Logit coef | -0.1481 | -0.148058 |
| T9 OLS Logit se | 0.0405 | 0.040491 |
| T9 OLS OLS coef | -0.0022 | -0.0022 |
| T9 OLS OLS se | 0.0218 | 0.021768 |
| T9 OLS FE coef | 0.0624 | 0.0624 |
| T9 OLS FE se | 0.0247 | 0.02468 |
| T9 OLS RE coef | 0.0317 | 0.031723 |
| T9 OLS RE se | 0.0382 | 0.038171 |
| T9 OLS GMM coef | 0.0014 | 0.001352 |
| T9 OLS GMM se | 0.0159 | 0.015937 |
| T9 OLS TSLS coef | 0.0393 | 0.039326 |
| T9 OLS TSLS se | 0.023 | 0.022961 |
| T9 OLS regulation coef | -0.0184 | -0.018432 |
| T9 OLS regulation se | 0.0138 | 0.013781 |
| T9 OLS ownership coef | -0.0341 | -0.034136 |
| T9 OLS ownership se | 0.0227 | 0.022712 |
| T9 OLS global coef | 0.0112 | 0.011195 |
| T9 OLS global se | 0.0176 | 0.017567 |
| T9 OLS citations coef | 0.0408 | 0.040778 |
| T9 OLS citations se | 0.0146 | 0.014614 |
| T9 OLS firstpub coef | 0.0159 | 0.015863 |
| T9 OLS firstpub se | 0.0067 | 0.006667 |
| T9 OLS IFrecursive coef | 0.089 | 0.088961 |
| T9 OLS IFrecursive se | 0.0363 | 0.036343 |
| T9 OLS reviewed_journal coef | -0.0042 | -0.004226 |
| T9 OLS reviewed_journal se | 0.0271 | 0.027107 |
| T9 OLS Constant coef | -0.135 | -0.134953 |
| T9 OLS Constant se | 0.1124 | 0.112408 |
| T9 OLS N | 598 | 598 |
| T9 OLS Studies | 31 | 31 |
| T9 FE SEPCC coef | -1.6234 | -1.623422 |
| T9 FE SEPCC se | 0.6912 | 0.691157 |
| T9 FE Samplesize coef | 0.0148 | 0.014829 |
| T9 FE Samplesize se | 0.0212 | 0.021245 |
| T9 FE T coef | -0.0511 | -0.051089 |
| T9 FE T se | 0.0268 | 0.026829 |
| T9 FE sampleyear coef | 0.0057 | 0.005718 |
| T9 FE sampleyear se | 0.0032 | 0.003178 |
| T9 FE undeveloped coef | 0.102 | 0.101999 |
| T9 FE undeveloped se | 0.076 | 0.075975 |
| T9 FE quadratic coef | -0.0071 | -0.007069 |
| T9 FE quadratic se | 0.0135 | 0.013486 |
| T9 FE endogeneity coef | -0.0292 | -0.029212 |
| T9 FE endogeneity se | 0.0163 | 0.016331 |
| T9 FE macro coef | 0.1882 | 0.188181 |
| T9 FE macro se | 0.0138 | 0.013833 |
| T9 FE someAveraged coef | 0.0226 | 0.022588 |
| T9 FE someAveraged se | 0.0151 | 0.015147 |
| T9 FE NPL coef | 0.0239 | 0.023928 |
| T9 FE NPL se | 0.0232 | 0.023163 |
| T9 FE Zscore coef | 0.0172 | 0.017234 |
| T9 FE Zscore se | 0.0228 | 0.022845 |
| T9 FE profit_volat coef | 0.0192 | 0.019191 |
| T9 FE profit_volat se | 0.0214 | 0.021426 |
| T9 FE profitability coef | -0.0048 | -0.004828 |
| T9 FE profitability se | 0.027 | 0.027049 |
| T9 FE capitalization coef | 0.0052 | 0.005241 |
| T9 FE capitalization se | 0.0254 | 0.025373 |
| T9 FE DtoD coef | 0.0217 | 0.021659 |
| T9 FE DtoD se | 0.0284 | 0.028437 |
| T9 FE Hstatistic coef | 0.0577 | 0.057678 |
| T9 FE Hstatistic se | 0.0201 | 0.020103 |
| T9 FE Boone coef | 0.0744 | 0.074448 |
| T9 FE Boone se | 0.0112 | 0.011241 |
| T9 FE Concentration coef | 0.0709 | 0.070853 |
| T9 FE Concentration se | 0.0346 | 0.034627 |
| T9 FE Lerner coef | 0.0721 | 0.072103 |
| T9 FE Lerner se | 0.0189 | 0.018877 |
| T9 FE HHI coef | 0.0654 | 0.065409 |
| T9 FE HHI se | 0.0252 | 0.025157 |
| T9 FE OLS coef | 0.0225 | 0.022501 |
| T9 FE OLS se | 0.0108 | 0.010757 |
| T9 FE FE coef | 0.0392 | 0.039182 |
| T9 FE FE se | 0.018 | 0.01804 |
| T9 FE RE coef | -0.0042 | -0.004189 |
| T9 FE RE se | 0.0182 | 0.018153 |
| T9 FE GMM coef | 0.0437 | 0.04374 |
| T9 FE GMM se | 0.0206 | 0.020645 |
| T9 FE TSLS coef | 0.0223 | 0.022346 |
| T9 FE TSLS se | 0.0186 | 0.018584 |
| T9 FE regulation coef | 0.0062 | 0.006158 |
| T9 FE regulation se | 0.0104 | 0.010405 |
| T9 FE ownership coef | -0.0193 | -0.019336 |
| T9 FE ownership se | 0.0311 | 0.031086 |
| T9 FE global coef | 0.0239 | 0.023909 |
| T9 FE global se | 0.0152 | 0.015161 |
| T9 FE Constant coef | -0.1783 | -0.178316 |
| T9 FE Constant se | 0.1656 | 0.165552 |
| T9 FE N | 598 | 598 |
| T9 FE Studies | 31 | 31 |
| Text T1 All mean PCC unweighted | -0.001 | -0.000865 |
| Text T1 All mean PCC weighted | -0.012 | -0.011836 |
| Text T1 Developed mean PCC unweighted | 0.02 | 0.02038 |
| Text T1 Developed mean PCC weighted | 0.011 | 0.010864 |
| Text T1 Undeveloped mean PCC unweighted | 0.001 | 0.000704 |
| Text T1 Undeveloped mean PCC weighted | -0.019 | -0.019304 |
| Text F3 Published mean PCC | 0.0116 | 0.011578 |
| T2 FE (unweighted, all) SEPCC coef | -1.671 | -1.670582 |
| T2 FE (unweighted, all) Constant coef | 0.044 | 0.044022 |
| T2 FE (unweighted, published) SEPCC coef | -1.898 | -1.897829 |
| T2 FE (unweighted, published) Constant coef | 0.073 | 0.073182 |
| T2 FE (weighted, all) SEPCC coef | -1.568 | -1.568468 |
| T2 FE (weighted, all) Constant coef | 0.034 | 0.034222 |
| T2 FE (weighted, published) SEPCC coef | -1.636 | -1.636389 |
| T2 FE (weighted, published) Constant coef | 0.044 | 0.043605 |

