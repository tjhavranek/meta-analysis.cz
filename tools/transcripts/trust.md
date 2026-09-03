## FRONTMATTER

Jiri Schwarz^{a}, Tomas Havranek^{b,c,d}, Zuzana Irsova^{a}, and Jiri Novak^{b}

^{a}Anglo-American University, Prague

^{b}Institute of Economic Studies, Charles University, Prague

^{c}Centre for Economic Policy Research, London

^{d}Meta-Research Innovation Center, Stanford

August 9, 2026

## ABSTRACT

Reported estimates of the size premium, the tendency of smaller firms to earn higher average returns than larger firms, vary widely across studies, countries, periods, and designs. We examine whether generalized trust and rule of law help account for that heterogeneity. Small firms are more opaque and more dependent on outside finance, so the enforcement and information environment should matter more for them than for large firms. We study 1,613 reported size-slope estimates from 105 studies and 31 countries. The meta-regressions control for study design, specification, precision, publication context, and market and macro-financial conditions; Bayesian model averaging assesses uncertainty over the control set. The more stable association is with rule of law, and it runs against the intuitive expectation that better legal institutions shrink the premium: stronger rule of law is associated with more negative reported size slopes, hence larger conventional size premia. The trust association is conditional and less precisely estimated: where rule of law is weak, higher generalized trust is linked to less negative reported slopes (and thus a weaker premium), and this link fades as rule of law strengthens. Formal and informal institutions thus help organize part of the disagreement in this literature, although the analysis concerns variation in reported estimates and does not identify causal effects.

## KEYWORDS: size premium; trust; rule of law; meta-analysis; Bayesian model averaging

**JEL codes:** G12; G15; C83

## 1 Introduction

The size premium is one of the oldest empirical regularities in asset pricing (Banz, 1981; Fama & French, 1992), yet its reported magnitude differs sharply across markets, periods, and research designs. We ask whether generalized trust and rule of law help organize the disagreement in what the literature reports.

Since the early evidence on size, many studies have reported that small firms earn higher average returns than large firms. Later work has questioned the stability, interpretation, and independent role of size once measurement choices, market microstructure, other anomalies, and data-mining concerns are taken seriously (Hou et al., 2020; Roll, 1981; Schwert, 2003). A researcher looking for a single calibration number, or for a simple verdict on the anomaly, quickly encounters a literature in which plausible estimates point in different directions.

Institutions are a candidate source of that heterogeneity because small firms are especially exposed to frictions that formal rules and informal norms can amplify or soften. Smaller firms tend to be more opaque, less collateralized, more dependent on local finance, and less able to absorb the fixed costs of compliance, disclosure, litigation, and contract enforcement (Beck et al., 2005, 2008; Berger & Udell, 1998; Hadlock & Pierce, 2010; Iliev, 2010). Rule of law captures the formal side of this environment: predictable courts, secure property rights, investor protection, and credible enforcement of contracts, which can reduce uncertainty, deepen markets, and support outside finance (Acemoglu & Johnson, 2005; Hail & Leuz, 2006; La Porta et al., 1998, 2002, 2006; Levine, 2005; North, 1990; Stulz, 1999, 2005). But its effect on the size premium is not one-directional: stronger legal and regulatory systems may also make small-firm risks more visible, impose fixed compliance burdens that fall more heavily on smaller firms, and price small-firm risk more cleanly (Gao et al., 2009; Iliev, 2010; Leuz, 2007).

Generalized trust captures a different, informal side of the same environment. Informal constraints and social norms shape exchange alongside formal law (Greif, 1994; North, 1990; Tabellini, 2010). Trust can lower the cost of transacting when contracts are incomplete, monitoring is costly, or counterparties are hard to verify (Arrow, 1972; Coleman, 1988; Fukuyama, 1995; Putnam, 1993), even if some of what surveys call trust reflects calculated expectations about risk (Williamson, 1993). For financial markets the empirical link is well documented: generalized trust is associated with stock market participation, credit access, disclosure credibility, and financing terms (Bottazzi et al., 2016; Guiso et al., 2004, 2008, 2009; Pevzner et al., 2015). These channels should matter most for small and opaque firms, whose investors and lenders rely more heavily on soft information, perceived honesty, and informal assurance (Beck et al., 2005; Berger & Udell, 1995; Gupta et al., 2018; Hasan et al., 2017). This is why the analysis focuses on generalized trust and treats family trust separately as a placebo measure of particularized, non-market trust (Alesina & Giuliano, 2010; Banfield, 1958; Delhey et al., 2011; Uslaner, 2002).

Cross-country asset-pricing studies document that the size effect differs across markets (Fama & French, 2012, 2017; Mishra et al., 2022), and institutional finance links trust and legal quality to participation, disclosure, and the cost of capital. Yet these literatures have not, to our knowledge, tested whether generalized trust and rule of law account for part of the heterogeneity in reported size-premium estimates. We assemble an estimate-level dataset of 1,613 reported size slopes and match each estimate to generalized trust from the European Values Study and World Values Survey (EVS/WVS) and rule of law from the Worldwide Governance Indicators (WGI). The size coefficients are drawn from the inventory coded by Astakhov et al. (2019); the institutional layer and the analysis are new. We estimate the direct trust and rule-of-law associations in reported size slopes. We then test whether the trust association changes with formal legal quality, conditioning on study design, specification choices, estimate precision, and macro-financial conditions.

The substitution logic yields a conditional prediction: generalized trust may substitute for weak formal enforcement by making investors and creditors more willing to transact with small, opaque firms even when legal protection is limited (Aghion et al., 2010; Guiso et al., 2004; Li et al., 2019; Pevzner et al., 2015). In such environments, higher trust should be associated with a smaller size premium. As rule of law improves, the marginal role of trust should fade because formal institutions already provide more of the enforcement and disclosure infrastructure that market participants need (Ahlerup et al., 2009; Bjørnskov, 2022). The proposed substitution is specific to the small-firm financing margin and yields no causal claim about the true size premium. Other settings find complementarity or mixed interactions between trust and law (Bartling et al., 2025; Bloom et al., 2012; Carlin et al., 2009; Cruz-García & Peiró-Palomino, 2019). Our empirical prediction is correspondingly narrow: generalized trust should have its strongest association with reported size coefficients where rule of law is weaker.

The intuitive expectation is that better legal institutions ease the frictions that bind small firms and so shrink the premium. The data say the opposite. The clearest result is that stronger rule of law is associated with more negative reported size slopes, that is, with larger conventional size premia, and the association holds even after excluding estimates from the United States. It is consistent with cleaner pricing of small-firm risk and with fixed compliance costs that fall regressively on size. Generalized trust adds a second, more tentative pattern: it is associated with less negative slopes where rule of law is weak, and this association fades as rule of law improves. The interaction is imprecise under clustered inference and thins out without the U.S. sample. Bayesian model averaging preserves the same posterior signs under control-set uncertainty. These are associations in reported estimates, not causal effects. Section 2 sets out the mechanism; Sections 3–6 take it to the data; Sections 7 and 8 interpret and conclude.

The data and code used to reproduce every table and figure are available in an online appendix at https://meta-analysis.cz/trust and archived at https://doi.org/10.5281/zenodo.21486177. The package starts from the frozen, analysis-ready estimate-level data, runs with a single command, and reproduces every reported number, so the analysis can be inspected from the matched-data stage onward. The paper follows the MAER-Net reporting guidelines for meta-analysis in economics as updated for artificial intelligence (Cook et al., 2026b), together with the accompanying principles for AI use (Cook et al., 2026a). Appendix D records where the requirements are met and lists the points on which we depart from them, most of which follow from starting at the estimate level rather than from a new literature search.

## 2 Background and Hypotheses

### 2.1 The Size Premium and Reported Estimates

The size premium refers to the tendency for smaller firms to earn higher average returns than larger firms. What the literature disputes is the magnitude and stability of that gap across markets, periods, and specifications. The estimates used in this analysis are reported slopes on firm size, so more negative reported size coefficients imply a stronger size premium throughout this paper. Banz (1981) first documented a negative relation between firm size and stock returns that could not be explained by market beta alone (Black, 1972; Lintner, 1965; Sharpe, 1964). Reinganum (1981) and Keim (1983) showed that the pattern also appeared alongside other cross-sectional anomalies and displayed distinctive seasonal and small-firm concentration features. Fama and French (1992, 1993) later placed the effect at the center of the modern factor-pricing literature through the small-minus-big factor, and size remains one of the canonical characteristics used to describe the cross-section (Harvey et al., 2016). That canonical status matters here because it establishes firm size as a recurring dimension of priced return differences rather than as a one-off anomaly confined to a single market or period.

The literature also portrays the size premium as unstable across periods, markets, and empirical specifications. Debate continues over whether the premium is weak, hidden, affected by measurement design, or absorbed by other characteristics (Roll, 1981; Schwert, 2003). van Dijk (2011) reviews the large body of evidence and emphasizes its uneven strength across countries. That diversity appears in both developed and emerging markets: Barry et al. (2002) find that size and value effects are less robust in emerging equity markets than in the canonical U.S. evidence, while Hou et al. (2011) show that the set of empirically successful return predictors differs materially across countries. Fama and French (2012, 2017) likewise show that the role of size varies across international markets and factor-model specifications. Even within the U.S. literature, the time profile is disputed: some evidence points to attenuation after the original discovery, whereas other work argues that expected and realized size premia can diverge because small firms are hit by unfavorable profitability shocks (Asness et al., 2018; Hou & van Dijk, 2019). The unresolved debate leaves substantial heterogeneity in measured size effects as the central fact to be explained; the institutional environment is one candidate explanation for it.

The reported estimates themselves have been collected at the estimate level by Astakhov et al. (2019), who document publication bias, study-design effects, and substantial residual heterogeneity. Two facts from that inventory matter here: the literature is large enough to support a formal meta-regression, and the variation in reported size effects is a real empirical pattern that invites systematic explanation. We do not re-estimate publication bias; the residual heterogeneity is what we try to explain.

Our object of analysis is the set of reported estimate-level size coefficients. Their variation may reflect economic heterogeneity as well as differences in sample construction, econometric specification, publication incentives, and other features of the research process. We ask whether part of the remaining variation lines up with the institutional environments in which small firms raise capital, disclose information, and bear enforcement frictions. Generalized trust and rule of law capture two relevant features of those environments.

### 2.2 Trust as an Informal Institution

If the heterogeneity in reported size coefficients partly reflects the institutional environments in which firms seek finance, then generalized trust is a natural place to begin. In the institutional-economics tradition, trust belongs to the domain of informal institutions: it is embedded in social norms, expectations, and repeated patterns of behavior that shape how readily economic actors engage in impersonal exchange (North, 1990). This is why the classical trust literature treats it as economically consequential rather than merely sociological background. Arrow (1972) argues that trust is present in virtually every commercial transaction because contracts are incomplete and opportunism is costly to police ex ante. Coleman (1988, 1990) frames trust as a form of social capital that lowers monitoring and agency costs, while Putnam (1993, 2000) and Fukuyama (1995) connect generalized trust to the broader capacity of societies to sustain cooperation beyond narrow personal networks. When exchange depends on the willingness of strangers to transact under imperfect information, trust can plausibly affect financing conditions and, through them, reported size coefficients.

That claim depends on distinguishing generalized trust from particularized trust. For financial markets the relevant concept is the broader belief that unknown counterparties will usually honor obligations and refrain from exploitation, rather than trust confined to family, kin, or familiar in-groups. This distinction runs from Banfield's (1958) contrast between civic cooperation and "amoral familism" to Uslaner's (2002) emphasis on moralistic trust. It continues in the radius-of-trust concept of Delhey et al. (2011) and in Alesina and Giuliano's (2010) evidence that strong family ties can substitute for, rather than reinforce, generalized trust. It is also consistent with the organizational evidence in La Porta et al. (1997b) and the historical contrast in Greif (1994) between trust confined to narrow groups and institutions that support broader anonymous exchange. This distinction is central here because asset markets are arm's-length settings. They require investors, lenders, and intermediaries to deal with firms and managers they do not know personally.

The concept nevertheless requires discipline. Williamson (1993) warns that some of what researchers label trust may instead be calculative expectations about the probability of defection. That caution is useful, but it does not eliminate the empirical relevance of survey-based generalized trust. Cross-country evidence shows that such measures predict economic performance and development over and above simple proxies for risk-taking or contemporary formal institutions (Algan & Cahuc, 2010; Knack & Keefer, 1997; Tabellini, 2010). In finance, the evidence is more specific. Guiso et al. (2004) show that social capital is associated with greater use of formal financial instruments and institutional credit, Guiso et al. (2008) trace part of the stock-market participation margin to the perceived probability of being cheated, and Guiso et al. (2009) extend the same logic to international exchange. Related work links trust to greater household participation in equity markets, more credible disclosure, and less frictive financing relationships (Bottazzi et al., 2016; Bricker & Li, 2023; Georgarakos & Pasini, 2011; Pevzner et al., 2015). These studies point to an economic role for generalized trust: it plausibly lowers the cost of initiating and monitoring financial transactions between parties who do not know one another.

Crisis-period corporate finance points the same way: firms with stronger CSR capital earned higher stock returns in the 2008–2009 crisis (Lins et al., 2017) and could issue bonds at lower spreads and longer maturities (Amiraslani et al., 2023). CSR is not identical to generalized social trust, but both patterns are consistent with trust-relevant reputational capital lowering financing premia when formal contracting and verification are under stress.

That mechanism should matter especially for small firms. The previous subsection emphasized that reported size coefficients are likely to vary with the frictions faced by firms that are more opaque, less collateralized, and more dependent on local or relationship-based finance. Trust fits naturally into that margin because it is most valuable when hard information is scarce and counterparties must rely more heavily on soft information, reputation, and perceived honesty. The most direct supporting evidence comes from Hasan et al. (2017), who show that higher local social capital is associated with lower loan spreads and bond yields. Gupta et al. (2018) similarly link social capital to a lower implied cost of equity, and Li et al. (2019) show that trust reduces IPO underpricing particularly for smaller and growth-oriented firms. These are not direct tests of the size premium itself, but they motivate our test of whether trust covaries with reported size slopes. If trust disproportionately relaxes the financing and information frictions borne by small firms, variation in generalized trust is a credible candidate for explaining heterogeneity in reported size-premium estimates.

### 2.3 Rule of Law as a Formal Institution

If trust captures the informal side of market exchange, rule of law captures the formal side. In institutional economics, formal rules matter because impersonal exchange does not scale without credible enforcement of contracts, predictable adjudication, and reasonably secure property rights (Acemoglu et al., 2001, 2005; North, 1990). The law-and-finance literature translates that general insight into a financial-markets setting. La Porta et al. (1997a, 1998, 1999, 2000, 2002) show that legal origin, investor protection, and enforcement quality are closely linked to ownership structures, market development, valuation, and the ability of outside investors to supply capital. Later work emphasizes that disclosure obligations and enforcement standards are core parts of the institutional environment that make securities markets usable for dispersed investors (Djankov et al., 2003, 2008; La Porta et al., 2006, 2008). That is why we use rule of law, rather than a broader governance measure, as the formal-institution anchor. It maps most directly to the set of formal arrangements that should matter for reported size coefficients: contract enforcement, shareholder protection, legal recourse, and the credibility of disclosure.

These mechanisms suggest an obvious channel through which stronger rule of law could reduce the size premium. Small firms are typically more opaque, more locally exposed, and more dependent on external finance that is difficult to secure when investors fear expropriation or weak enforcement. Improvements in formal legal institutions can therefore relax frictions that bind more tightly for smaller firms than for larger ones. Cross-country studies show that better legal environments and financial development expand firms' access to long-term external finance, lower the sensitivity of investment to internal funds, and reduce the financing obstacles reported by the smallest firms in particular (Beck & Levine, 2005; Beck et al., 2003, 2005, 2008; Demirgüç-Kunt & Maksimovic, 1998, 2002; Love, 2003). The same logic appears in asset-pricing and governance evidence: stronger legal institutions are associated with lower costs of equity, more credible access to outside capital, and less severe governance penalties for firms that cannot easily contract around domestic institutional weakness (Doidge et al., 2007; Hail & Leuz, 2006, 2009; Himmelberg et al., 2002; Stulz, 1999, 2005). Through this channel, better rule of law should compress the size premium by reducing the financing, contracting, and information disadvantages that fall most heavily on small firms.

But that prediction is not the only one supported by the literature. Stronger legal environments can also make the reported size effect more pronounced. One reason is that the same legal architecture that protects investors also imposes fixed disclosure, auditing, and compliance costs whose incidence is regressive in firm size. Iliev (2010) shows that tighter internal-control compliance requirements under Sarbanes-Oxley generated substantial cost increases and negative valuation effects around the relevant threshold. Gao et al. (2009) document that firms respond strategically to avoid those burdens. More generally, stronger enforcement can raise the informational precision with which small-firm risk is priced. Better disclosure regimes, lower earnings opacity, and more credible enforcement may reduce noise without eliminating the underlying risks borne by smaller firms, thereby sharpening rather than muting the contrast between small and large stocks (Bhattacharya & Daouk, 2002; Hail & Leuz, 2006; Leuz et al., 2003). In that sense, formal legal development can cut both ways. It may ease financing frictions that otherwise inflate small-firm required returns, but it may also formalize market participation, impose scale-sensitive compliance burdens, and make size-related risk premia easier to detect in reported estimates.

The implication is that rule of law should not be treated here as a simple "good institutions" variable with a mechanically signed effect on the reported size slope (Beck et al., 2005; Gao et al., 2009; Hail & Leuz, 2006; Iliev, 2010). This ambiguity matters for the design: the formal institutional environment must be analyzed on its own terms before generalized trust is brought back in. If rule of law already performs part of the work that informal trust performs in weaker institutional settings, then the relevant hypothesis is not purely additive.

### 2.4 Institutional Substitution and Testable Predictions

The preceding subsections imply that trust and rule of law are not two interchangeable measures of institutional quality. They support exchange through different margins. Generalized trust can reduce the perceived danger of dealing with unfamiliar counterparties when information is soft and contracts are incomplete, while rule of law supplies formal enforcement, investor protection, and predictable legal recourse. If these functions overlap, the relevant prediction is conditional rather than simply additive: trust should matter most where formal enforcement is weaker, because in those settings informal assurance can partly substitute for legal infrastructure that investors and creditors otherwise lack.

This substitution logic has direct support in the trust-and-finance literature. Guiso et al. (2004) show that social capital is especially strongly associated with financial development where legal enforcement is weak, while Ahlerup et al. (2009) and Bjørnskov (2022) find that trust contributes more to growth and productivity in weaker institutional environments. The same mechanism is consistent with Aghion et al. (2010), who link distrust and regulation in a self-reinforcing equilibrium: where people expect opportunistic behavior, societies demand more formal control, and formal control can in turn crowd out trust. Applied to the size premium, this literature suggests that generalized trust may be most relevant for small, opaque firms precisely in countries where courts, disclosure enforcement, and investor protection provide less reliable assurance.

The hypothesis is nevertheless not that informal and formal institutions are always substitutes. Models of trust, regulation, and investment allow both substitution and complementarity, depending on the level of social capital and the credibility of legal enforcement (Carlin et al., 2009). Empirical work on private credit also finds cases in which trust works through stronger formal institutions rather than replacing them (Cruz-García & Peiró-Palomino, 2019), and experimental evidence points to complementarity between trust and contract enforcement in some exchange environments (Bartling et al., 2025). More generally, social norms and legal enforcement can reinforce one another when laws are legitimate and broadly followed (Acemoglu & Jackson, 2017). These competing views rule out a mechanical prediction that more trust and better law must always move reported size coefficients in the same direction. The empirical question is instead whether the reported size-premium literature displays the particular conditional pattern implied by institutional substitution.

Two testable propositions follow from the substitution argument and the sign convention used in this paper: where rule of law is weak, higher generalized trust should be associated with less negative reported size slopes, and thus a weaker premium (more negative estimates imply a stronger one); and this trust association should decline as rule of law improves. In the interaction specification below, that corresponds to a positive trust association at low rule of law and a negative trust-by-rule-of-law interaction. Rule of law remains part of the empirical specification because it is the formal-institution anchor of the argument, but the literature does not imply a single directional prediction for its direct association with reported size slopes: stronger formal institutions can ease small-firm financing frictions, but they can also make small-firm risk, disclosure obligations, and fixed compliance costs more visible in market prices. We treat the substitution pattern as a sign-consistent prediction to be tested cautiously. The direct rule-of-law association is theoretically ambiguous: the friction-easing channel and the pricing-and-compliance channel imply opposite signs for the reported slope, so the estimated sign carries information about which channel dominates in the reported estimates.

## 3 Data and Variables

The estimated size premium varies widely across studies, countries, sample periods, and specifications. Using an estimate-level dataset that extends Astakhov et al. (2019) with institutional and macro-financial measures, we ask which country-, study-, and model-level characteristics explain that variation, with particular attention to trust and rule of law. Table 1 summarizes the data sources and the main variables.

### 3.1 Size-Premium Estimates and Primary-Study Specifications

The main dependent variable comes from primary asset-pricing studies that ask how stock returns vary with firm size. Each reported size coefficient becomes one observation in the meta-analysis. Astakhov et al. (2019) report 1,746 such estimates from 102 published studies, plus a working-paper extension of 10 studies and 167 estimates, together with information on the study, sample period, country, empirical specification, estimation method, and reported precision. We start from that inventory, including the working-paper extension, use the reported coefficients as the outcome to be explained, and augment the estimate-level data with institutional and macro-financial variables.

In the underlying literature, firm size is usually measured as the market value of equity, commonly transformed by the natural logarithm because the cross-sectional distribution of firm values is highly skewed (Astakhov et al., 2019). Because larger firms sit higher on the size scale, a more negative reported slope means that small firms earn relatively more than large firms. Less negative slopes therefore mean a weaker premium.

Primary studies estimate the size premium in two main ways. The first approach estimates a slope on firm size in a return regression, often in the Fama–MacBeth tradition and alongside market beta or other firm characteristics (Blume, 1970; Fama & MacBeth, 1973):

$$ R_{kt} = \gamma_{0t} + \gamma_{1t}\widehat{\beta}_{k} + \gamma_{2t}\log(ME_{kt}) + Z_{kt}'\delta_{t} + u_{kt}. $$ (1)

Here $k$ indexes firms and $t$ indexes periods, $ME_{kt}$ denotes market equity, and $Z_{kt}$ collects any additional firm characteristics included by the primary study. The size coefficient, $\gamma_{2t}$, or its time-series average across cross-sections is the object that enters the meta-analysis when it is reported with sufficient precision information.

The second approach estimates the size premium through sorted portfolios or a small-minus-big factor return (Fama & French, 1993). We use reported regression slopes rather than raw small-minus-big premia (as in Astakhov et al., 2019), because they retain the estimate-level standard errors needed for meta-regression, stay close to the marginal relation between returns and size, and depend less on portfolio-construction choices than raw factor or portfolio premia, which can also compress the within-sample variation that regression slopes retain (Berk, 2000; Fama & French, 2008; Lo & MacKinlay, 1990). The dependent variable is therefore the reported slope on firm size, not a small-firm-minus-large-firm return, and the sign is reversed relative to conventional premium language: stronger conventional size premia appear as more negative size slopes.

Following the source inventory, we use the reported coefficients in the units used by the primary studies rather than converting them into a common annualized effect size. Return definitions and horizons, and in some cases the construction of size, therefore vary across observations. Our dependent variable should accordingly be read as a reported-slope outcome, not as repeated measurements of one cardinal premium. The meta-regression conditions on the coded study-design and specification differences available in the inventory, and the illustrative magnitude in Section 7 is likewise expressed only in reported-slope space.

Keeping the evidence at the estimate level retains the heterogeneity of the literature, since studies differ in markets, periods, specifications, reporting choices, and estimation methods. It also creates a clear limit. The 1,613 rows are not independent observations; many come from the same study or the same country. For that reason, we report inference clustered separately by study and by country. The robustness section returns to the consequences of the highly unbalanced sample.

### 3.2 Trust Measures

To measure the trust environment around each estimate, we draw on the Integrated Values Surveys assembled from the European Values Study (EVS) Trend File 1981–2017 and the World Values Survey (WVS) Trend File 1981–2022 (EVS, 2022; Haerpfer et al., 2022). These dates give the outer span of the underlying surveys; the data do not form a balanced annual panel. EVS ends earlier than WVS, countries enter in different waves, fieldwork years are uneven, and not every trust question appears in every country-year survey. We therefore create a trust index for each observed country-year by averaging multiple trust questions, each taken from its nearest available survey year.

The baseline trust index is meant to capture measured generalized interpersonal trust rather than one exact survey wording. To reduce researcher discretion in index construction, it uses all available EVS/WVS questions that directly ask about trust in people or social groups, except for trust in family, which is kept for the placebo test below. It does not use trust or confidence in specific formal institutions, such as the army, police, or courts, because those items are closer to institutional confidence than to generalized interpersonal trust. The index should still be read as a cross-country proxy, since survey trust measures can raise comparability concerns across cultural settings (Reeskens & Hooghe, 2008).

The resulting index has seven components. The broadest item is the standard generalized-trust question: “Generally speaking, would you say that most people can be trusted or that you can’t be too careful in dealing with people?” The country-year measure is the share answering “most people can be trusted.” The other six components are country-year means of questions about trust in named groups. Five come from the more recent survey waves, which use the four-point prompt asking whether respondents trust the group “completely, somewhat, not very much or not at all”; the groups are people in the respondent’s neighborhood, people known personally, people met for the first time, people of another religion, and people of another nationality. The remaining item comes from earlier survey waves and asks whether respondents trust other people in their country on a five-point scale ranging from “trust completely” to “not trust at all.”

The index construction follows the same logic for each country-year component. Nonsubstantive responses such as no answer, don’t know, not applicable, and not asked are treated as missing. For the multi-category trust items, lower raw response values indicate greater trust, so the country-year means are reversed before standardization. The share answering that most people can be trusted already increases with trust and is not reversed. Each component is standardized as a z-score over the observed country-year survey cells: we subtract that component’s mean and divide by its standard deviation, omitting missing cells from both calculations. The generalized-trust index is then the row mean of the available standardized components. Component coverage varies across country-year cells, and the components of a given cell can come from different survey years, so cells with fewer observed components measure generalized trust more noisily. A country-year receives a missing index only when none of the seven components is observed. Higher values therefore indicate more measured generalized trust.

Holding family trust out of the main index also gives a direct check on our interpretation. Trust inside the family is conceptually different from the broader nonfamily trust captured by the generalized-trust index, which spans acquaintances, neighbors, and strangers. The literature distinguishes generalized trust, which supports impersonal exchange, from particularized trust, which remains confined to family and close networks (Alesina & Giuliano, 2010; Banfield, 1958; Delhey et al., 2011; Uslaner, 2002). We therefore use family trust as a placebo: if the main pattern simply reflected the inclusion of any survey-based trust measure, family trust should produce a similar result. The placebo index uses two EVS/WVS items. The item from earlier survey waves asks how much respondents trust their family, with answers from “trust them completely” to “do not trust them at all.” The item from more recent survey waves uses the same named-group prompt as above for “your family,” with answers from “trust completely” to “do not trust at all.” These two country-year means are reversed where necessary, standardized, and averaged in the same way as the generalized-trust components. The robustness checks below show that the marginal effects of family trust do not reproduce the conditional substitution pattern found for generalized trust.

### 3.3 Rule of Law and Other Institutional Measures

Formal institutions are measured with the Worldwide Governance Indicators (WGI). Their rule-of-law series summarizes perceptions of contract enforcement, property rights, the courts, and the likelihood of crime and violence (Kaufmann & Kraay, 2024; World Bank, 2025a, 2025b). It is the natural counterpart to generalized trust in this paper because it maps most directly onto the formal enforcement mechanisms emphasized by law-and-finance and institutional-economics research (Hail & Leuz, 2006; La Porta et al., 1998, 2006; North, 1990).

Each country-year observation is matched to the nearest available WGI year. The analysis also includes government effectiveness, regulatory quality, and control of corruption from the same source. Those measures return later as alternative formal-institution checks. Rule of law remains the baseline because it is closest to the legal enforcement and investor-protection channel in the hypothesis. For samples predating survey or WGI coverage, the nearest available value is necessarily measured later.

### 3.4 Meta-Regression Moderators and Sample Construction

Reported size slopes vary for reasons that are broader than the institutional mechanism studied in this paper. Primary studies use different return definitions, sample windows, trimming rules, estimation methods, portfolio constructions, control variables, publication outlets, and market environments. The meta-regression therefore treats the institutional variables as one candidate explanation among several. The moderators below follow the logic of the primary size-premium literature and of meta-analytic work on asset-pricing estimates: they describe how the estimate was produced, which return predictors the primary study allowed for, how precise the estimate is, how prominent the study is in the literature, and what market environment the estimate represents (Astakhov et al., 2019; Bajzik et al., 2020; Fama & French, 1992, 1993; Irsova et al., 2024; van Dijk, 2011).

One moderator family captures study design and data construction. Size estimates can differ in how the size variable and the sample are set up: studies define size relative to a sample average, cover different calendar periods, use longer or shorter samples, and trim extreme observations. They can also differ in how returns and the regression are specified, using excess rather than raw returns, individual stocks rather than portfolios, January-only returns, or a demeaned independent variable. These distinctions matter because the size premium has been linked to seasonality, microcap concentration, time variation, and the way noisy firm-level returns are aggregated (Banz, 1981; Hou & van Dijk, 2019; Keim, 1983; Knez & Ready, 1997; Reinganum, 1981; van Dijk, 2011). We code these features with indicator variables for the relevant design choices and continuous variables for the midpoint and length of the sample period.

A second family captures the primary-study estimation method. Fama–MacBeth regressions remain a standard tool for estimating average cross-sectional return relations because they run repeated cross-sections and then summarize the coefficient series over time (Fama & French, 1992; Fama & MacBeth, 1973). Other studies report pooled or ordinary least squares specifications. Methodological differences can affect both the level of the reported slope and its precision, especially when return shocks are correlated across firms or when standard errors are adjusted differently across studies (Astakhov et al., 2019). The meta-regression therefore includes indicators for Fama–MacBeth and ordinary least squares estimation.

A third family records the asset-pricing controls included in the primary specification. This block is central because the size premium is partly entangled with other firm characteristics. Book-to-market, market beta, momentum, profitability, investment-related characteristics, leverage, and liquidity can each absorb part of what would otherwise appear as a size slope. So can volatility, price levels, information variables, ownership, growth, distress, and additional size controls (Amihud, 2002; Asness et al., 2018; Basu, 1983; Bhandari, 1988; Carhart, 1997; Dichev, 1998; Fama & French, 1992, 1993, 2015; Hou & van Dijk, 2019; Jegadeesh & Titman, 1993). The analysis codes these controls as broad indicator groups, so the main text refers to the economic family rather than to every underlying variable name. The detailed grouping is reported in Appendix Table 10.

A fourth family covers publication and precision context: Astakhov et al. (2019) identify publication bias in the size-premium literature, and publication bias in meta-analysis is commonly diagnosed through a systematic relation between a reported estimate and its standard error (Stanley, 2005, 2008). In the absence of such selection, sampling imprecision should not by itself predict the reported coefficient once the underlying effect and study design are accounted for. The meta-regression therefore includes the reported standard error as a precision moderator. Publication outlet and citation counts are included for a different reason: highly visible studies and more cited estimates may use more standardized designs, may be more likely to report statistically significant effects, or may come from literatures in which certain specifications became canonical. We therefore control for reported precision, journal impact, and citations without interpreting them as causal determinants of the true size premium.

Finally, size effects may differ across macro-financial environments, including interest-rate conditions, aggregate market volatility, financial development, income levels, and growth conditions. These variables are also relevant for the institutional interpretation because financial development and macroeconomic conditions affect the financing constraints and risk exposures of small firms (Beck et al., 2005, 2008; Hail & Leuz, 2006; Levine, 2005). The baseline specification therefore includes bond yields, market-return volatility, private credit to GDP, GDP per capita, and GDP growth as country-period controls.

Some continuous measures enter the regression after simple transformations that make their scales easier to compare. The midpoint of each study’s sample period is expressed relative to the sample average. Sample length and citation counts are logged because they are highly skewed. GDP per capita is also logged, private credit is expressed as a ratio rather than a percentage, and market volatility and GDP growth are multiplied by 100 so that they enter in percentage-point units. Variable and control-group definitions are reported in Appendix Tables 9 and 10; the main text groups them by the economic reason for including them.

The final sample is the part of the collected literature that can be linked cleanly to the institutional and control information needed for the baseline specification. Our starting pool includes Astakhov et al. (2019)’s published-study inventory and its working-paper extension (the count reconciliation is in Appendix A). Because trust and rule of law are measured at the country level, we drop estimates that pool several countries together. We also exclude estimates with sample midpoints before 1960, observations with missing institutional or control information, and observations that become non-finite after the log transformations. The complete-case analysis sample contains 1,613 estimates from 105 studies and 31 countries. It is highly unbalanced: the United States accounts for 1,115 observations, or 69.1% of the sample. The design remains useful for studying reported estimates, although this imbalance precludes a clean cross-country causal interpretation. Appendix Table 6 reports the source-study counts in the final analysis sample.

TABLE 1. Data Sources and Main Variables

| Object | Source | Construction and role | Coverage |
| --- | --- | --- | --- |
| Reported size coefficients | Astakhov et al. (2019) | Reported slopes from regressions of returns on firm size; dependent variable | 1,613 |
| Generalized trust index | EVS/WVS | Row mean of seven standardized generalized-trust components; informal-institution moderator | 1,613 |
| Rule of law | WGI | Nearest-year country match to WGI rule-of-law estimate; formal-institution moderator | 1,613 |
| Study and estimate controls | Astakhov et al. (2019) | Design, specification, precision, and publication-context controls | 1,613 |
| Macro-financial controls | Country-year controls linked to the Astakhov et al. (2019) estimates | Market and macroeconomic conditions, transformed as in the preferred specification | 1,613 |
| Family-trust placebo | EVS/WVS | Row mean of standardized family-trust items; placebo institutional index | 1,613 |
Notes: Coverage is measured in the complete-case analysis sample used in the baseline specification. EVS/WVS denotes European Values Study/World Values Survey; WGI denotes Worldwide Governance Indicators.

Reported size slopes and standard errors have long tails, typical of primary-study estimates pooled across papers. The baseline specifications therefore apply mild 1/99 winsorization to these two variables after the complete-case sample is formed. Table 2 reports the unwinsorized distribution of the analysis sample. The empirical strategy and robustness sections describe the tail treatment and its checks.

TABLE 2. Summary Statistics in the Analysis Sample

| Variable | Mean | SD | Min. | P25 | Median | P75 | Max. |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Size slope | -0.091 | 0.472 | -3.600 | -0.101 | -0.005 | -0.000 | 4.447 |
| Standard error | 0.089 | 0.278 | 0.000 | 0.001 | 0.023 | 0.054 | 3.789 |
| Generalized trust index | 0.762 | 0.504 | -1.001 | 0.900 | 0.900 | 0.993 | 1.886 |
| Rule of law | 1.407 | 0.413 | -1.290 | 1.500 | 1.500 | 1.500 | 1.951 |
| Family-trust placebo index | 0.045 | 0.269 | -1.152 | -0.039 | -0.039 | -0.039 | 1.208 |
Notes: The table reports the unwinsorized distribution of the 1,613-observation complete-case analysis sample. The sample contains 105 studies and 31 countries; 1,115 observations, or 69.1%, are from the United States. Because of this weight, the estimate-level quantiles of the institutional variables are pinned at the U.S. values; the country-level quantiles used for interpretation are reported in Appendix Table 7. The statistics use the same transformations as the baseline interaction specification. Values are shown to three decimals; the 75th percentile of the size slope is negative but smaller than 0.0005 in magnitude.

## 4 Empirical Strategy

### 4.1 Baseline Meta-Regression

We ask whether trust and rule of law retain a systematic association with reported size slopes once the other sources of meta-analytic heterogeneity are held constant.

The specification follows directly from the conditional-substitution argument developed above. If generalized trust partly substitutes for weak formal enforcement, its association with the reported size slope should depend on rule of law. A purely additive specification would miss that possibility, so the baseline includes trust, rule of law, and their interaction. The institutional coefficients are estimated from cross-country and over-time variation in the matched institutional measures, with study and specification differences entering through the controls; the coefficients describe conditional associations in the literature.

The baseline estimating equation is:

$$ \hat{\beta}^{\mathrm{size}}_{ijc} = \alpha + \beta_{1}\mathrm{Trust}_{ijc} + \beta_{2}\mathrm{RuleOfLaw}_{ijc} + \beta_{3}\left(\mathrm{Trust}_{ijc} \times \mathrm{RuleOfLaw}_{ijc}\right) + X_{ijc}'\gamma + \varepsilon_{ijc}. $$ (2)

In Equation (2), $i$ indexes an estimate, $j$ indexes the study from which the estimate is drawn, and $c$ indexes the country to which the estimate refers. The dependent variable, $\hat{\beta}^{\mathrm{size}}_{ijc}$, is the reported size coefficient collected by Astakhov et al. (2019) (the $\gamma_{2t}$ of Equation (1) or its time-series average for Fama–MacBeth estimates, and the analogous size slope for pooled and least-squares specifications). Because the underlying coefficient is a slope on firm size, more negative values imply a stronger conventional small-minus-big premium.

The variables $\mathrm{Trust}_{ijc}$ and $\mathrm{RuleOfLaw}_{ijc}$ denote the generalized-trust index and the rule-of-law measure assigned to the estimate’s country and sample timing. They are left uncentered in the preferred specification. Here $\beta_{1}$ is the trust association when rule of law is zero, and $\beta_{2}$ the rule-of-law association when trust is zero. These are useful anchors, but the economically meaningful quantities are the marginal effects over the observed support.

The vector $X_{ijc}$ collects the remaining sources of meta-analytic heterogeneity discussed in the data section. These include study-design indicators, asset-pricing specification choices, estimate precision, journal impact and citation measures, market characteristics, and macro-financial controls. We include the reported standard error as the precision moderator used in funnel-asymmetry diagnostics (Stanley, 2005, 2008), together with journal impact and citations. We do not fit a full selection model, because the target is the institutional moderators of reported slopes, not the bias-corrected mean size premium. The baseline estimator is unweighted ordinary least squares.

Before estimation, the reported size slope and its standard error are winsorized at the 1st and 99th percentiles within the final complete-case model frame.^{1} This mild tail treatment limits the leverage of extreme reported coefficients and imprecise estimates while leaving the analysis sample and the institutional variables unchanged. Since many estimates come from the same studies and countries, the results section reports the same point estimates with two cluster-robust covariance matrices: one clustered by study and one clustered by country. This presentation keeps the identifying variation transparent and avoids treating the 1,613 estimate-level observations as independent country-level evidence.

### 4.2 Marginal-Effect Definitions

Because the baseline model contains an interaction, the raw main-effect coefficients do not by themselves answer the substantive question. The coefficient on trust is evaluated at a zero value of rule of law, and the coefficient on rule of law is evaluated at a zero value of the trust index. Those values are interpretable reference points for an uncentered specification, but the economic question is how the trust association evolves as formal legal quality changes over the observed support of the data.

For this reason, the empirical interpretation is based on marginal effects. The first marginal effect asks how the reported size slope changes with trust at a given level of rule of law. The second asks how it changes with rule of law at a given level of trust.

$$ \frac{\partial \hat{\beta}^{\mathrm{size}}}{\partial \mathrm{Trust}} = \beta_1 + \beta_3 \mathrm{RuleOfLaw}, $$ (3)

$$ \frac{\partial \hat{\beta}^{\mathrm{size}}}{\partial \mathrm{RuleOfLaw}} = \beta_2 + \beta_3 \mathrm{Trust}. $$ (4)

For each marginal effect, uncertainty is computed from the covariance matrix of the relevant linear combination of coefficients. The plotted confidence bands use the same study-clustered and country-clustered covariance matrices as the OLS tables. The figures also show the observed support of the conditioning variable, so the reader can distinguish parts of the interaction surface that are well represented in the data from extrapolated regions.

### 4.3 Model Uncertainty

Meta-regressions face substantial model uncertainty because the literature supplies many plausible controls and only limited theory about which study-design variables must appear in every specification. A single full-control OLS regression is transparent, but it can give a misleading sense of precision if the institutional pattern depends on a particular control set. To address this concern, the analysis also uses Bayesian model averaging (BMA), a standard tool in economic meta-analysis (Eicher et al., 2011; Raftery et al., 1997; Zeugner & Feldkircher, 2015).

The BMA exercise keeps the dependent variable, institutional variables, transformations, and tail treatment aligned with the baseline OLS specification. It samples models over the control variables in $X_{ijc}$, while forcing generalized trust, rule of law, and their interaction to appear in every sampled model. We fix the institutional block deliberately. The design does not ask whether trust and rule of law survive selection against a menu of unrelated controls; it asks whether their sign pattern is sensitive to uncertainty about the other moderators. Consequently, posterior inclusion probabilities (PIP) of one for the institutional terms are mechanical and should not be read as evidence that BMA selected those terms from the data.

The baseline BMA uses the BRIC *g*-prior, a random model-size prior, and birth-death Markov chain Monte Carlo. The reported BMA uses 100,000 burn-in draws, 200,000 retained iterations, and is configured to store up to 5,000 best models. Coefficients are summarized as posterior means and posterior intervals after averaging across the sampled model space. For interaction interpretation, marginal-effect intervals are computed from posterior covariance terms so that the uncertainty in linear combinations such as $\beta_1 + \beta_3 \mathrm{RuleOfLaw}$ is treated consistently.^{2}

The BMA results are used as model-uncertainty evidence, not as a substitute for clustered OLS inference. Their uncertainty bands are Bayesian posterior intervals under the specified priors and model space; they are not study-clustered or country-clustered standard errors. They also do not resolve the observational nature of the design, the limited institutional variation, or the sample-composition issues examined later. Their role is narrower. They show whether the preferred pattern is qualitatively stable when the large set of study-design and macro controls is not treated as fixed with certainty.

## 5 Results

### 5.1 Descriptive Heterogeneity

Reported size slopes differ sharply across countries (Figure 1), which is why a heterogeneity analysis is warranted. The analysis sample contains 1,613 reported size slopes from 105 studies and 31 countries. In the unwinsorized sample, the mean reported slope is −0.091, with a standard deviation of 0.472. The 1/99 winsorized outcome used in the baseline regression ranges from about −1.735 to 1.330. These numbers are large relative to the average estimate and indicate that the literature contains much more than small sampling fluctuations around a single common size effect.

The dispersion is economically meaningful: a more negative reported coefficient means a stronger size premium. The cross-country box plot should nevertheless be read descriptively. The sample is highly unbalanced: the United States contributes 1,115 observations, or 69.1% of the analysis sample. The figure therefore motivates the meta-regression but does not by itself establish a country-level institutional relationship.

### 5.2 Baseline Institutional Meta-Regression

The clearest pattern in the data is that stronger rule of law goes with a larger conventional size premium across much of the relevant trust support (Table 3): the rule-of-law coefficient is negative and conventionally informative under both study- and country-clustered inference. This is consistent with formalization, disclosure, and risk-pricing channels, and with the possibility that better legal systems make small-firm risks more visible.

FIGURE 1. Reported Size Slopes Vary Widely across Countries

Notes: The figure shows the distribution of 1/99 winsorized reported size slopes in the preferred complete-case sample for countries with at least five estimates. Countries are ordered by their median winsorized size slope. Outlier points are not drawn, but all country observations enter the box summaries. More negative slopes imply larger conventional size premia.

The trust interaction corresponds to the substitution hypothesis. Its negative sign means that the trust association declines as rule of law rises. The marginal effect of trust combines the trust coefficient with the interaction at each level of rule of law, so Figure 2 provides the substantive interpretation. The interaction coefficient itself is imprecise: the study-clustered *p*-value is 0.138, and the country-clustered *p*-value is 0.139.

We treat the institutional variables as a block, not as separable causes: trust, rule of law, and broad development move together empirically, so the baseline interaction should not be read as a clean decomposition of independent institutional causes.

TABLE 3. Baseline Institutional Meta-Regression: Rule of Law as the More Stable Association

| | Study-clustered | | | Country-clustered | | |
|---|---|---|---|---|---|---|
| | Estimate | SE | *p*-value | Estimate | SE | *p*-value |
| Generalized trust | 0.146 | 0.086 | 0.091 | 0.146 | 0.112 | 0.192 |
| Rule of law | -0.168 | 0.077 | 0.028 | -0.168 | 0.070 | 0.016 |
| Generalized trust × rule of law | -0.108 | 0.073 | 0.138 | -0.108 | 0.073 | 0.139 |
| Controls | Yes | | | Yes | | |
| Observations | 1,613 | | | 1,613 | | |
| Studies | 105 | | | 105 | | |
| Countries | 31 | | | 31 | | |
Notes: The dependent variable is the 1/99 winsorized reported size slope. Winsorization is applied after forming the complete-case model frame. The table reports the same OLS point estimates with alternative cluster-robust covariance matrices. Controls include the study-design, asset-pricing specification, precision, publication-context, market, and macro-financial moderators described above. See Appendix Table 11 for the full set of results. More negative reported slopes imply larger conventional size premia.

### 5.3 Marginal Effects and Interpretation

Figure 2 translates the interaction into the two conditional associations that matter for the economic interpretation. Panel (a) shows that the marginal effect of generalized trust on the reported size slope is largest in weaker-rule-of-law settings and declines as rule of law improves. At average or median rule of law, the implied trust effect is close to zero and is not statistically distinguishable from zero. The positive trust association is therefore not an average-sample result. At the plotted 90% confidence level, it is positive only over low rule-of-law values, approximately from −1.00 to 0.42 under study-clustered inference, and no part of the country-clustered band lies entirely above zero. The figure is consistent with higher trust going with a smaller premium where formal legal institutions are weaker, but that part of the evidence is narrow and sensitive to the clustering dimension.

(a) Marginal effect of generalized trust over rule of law (b) Marginal effect of rule of law over generalized trust

FIGURE 2. Marginal Effects, Baseline OLS: the Estimated Trust Association Declines with Rule of Law

Notes: The figures report marginal effects implied by the baseline OLS interaction model. Bands are 90% confidence intervals computed from the relevant clustered covariance matrix. Support points are plotted on the zero line. Positive effects increase the reported size slope and therefore imply weaker conventional size premia; negative effects imply stronger conventional size premia.

Panel (b) shows the complementary marginal effect of rule of law. This association is more consistently negative. The rule-of-law effect becomes more negative as generalized trust rises, and the 90% confidence band excludes zero over much of the observed trust support: approximately from −0.35 to 1.89 with study-clustered inference and from −0.48 to 1.89 with country-clustered inference. Because negative effects make the reported size slope more negative, this pattern implies a stronger conventional size premium in higher-rule-of-law environments over most of the relevant trust range. This finding is not the simple claim that all better institutions reduce the size premium. Rather, the evidence suggests that generalized trust and formal legal quality enter the reported size-premium literature in a conditional way: the trust association is concentrated in weak-formal-institution settings, while the rule-of-law association is more visible across the main support of the trust index.

Figure 3 summarizes the same pattern as a joint institutional surface, holding the other controls fixed. The lowest fitted institutional contributions appear where rule of law is high and trust is moderate or high, which corresponds to more negative reported size slopes and hence larger conventional size premia. The positive trust contribution is concentrated in weaker-rule-of-law settings and declines as the formal legal environment improves. The plot displays the interaction over the observed support; it does not map the total size premium in each country.

FIGURE 3. The Fitted Institutional Contribution Is Most Negative Where Rule of Law Is High

Notes: The figure isolates the fitted contribution of the generalized-trust, rule-of-law, and interaction terms from the baseline OLS regression. It is not the total fitted size slope. Points show observed combinations of trust and rule of law.

### 5.4 Bayesian Model Averaging

Table 4 reports the Bayesian model-averaging counterpart to the baseline OLS specification. The exercise varies the study-design, specification, precision, publication-context, market, and macro-financial controls included in the meta-regression while keeping the dependent and institutional variables fixed. It assesses whether the institutional sign pattern persists under control-set uncertainty.

TABLE 4. Bayesian Model Averaging: Posterior Signs Match the Baseline OLS Pattern

| Variable | Mean | SD | 90% low | 90% high |
|---|---|---|---|---|
| Rule of law | -0.126 | 0.046 | -0.202 | -0.050 |
| Generalized trust | 0.135 | 0.066 | 0.026 | 0.244 |
| Generalized trust × rule of law | -0.092 | 0.043 | -0.162 | -0.021 |
Notes: The table reports primary MCMC-frequency BMA posterior summaries. The institutional variables are forced into every sampled model, so their posterior inclusion probabilities equal one by design and are not reported as selection evidence. Posterior intervals are Bayesian model-averaged intervals, not cluster-robust confidence intervals.

The BMA posterior means carry the same signs as the OLS point estimates: positive for trust, negative for rule of law and for the interaction. The 90% posterior intervals for all three institutional terms exclude zero under the reported BMA specification. Because these are model-averaged posterior intervals that treat the 1,613 estimates as independent observations, they leave the clustered-inference limitations unresolved. Figure 4 reports the corresponding posterior marginal effects. The posterior trust marginal effect is positive over lower rule-of-law values, approximately from −1.29 to 0.84, and fades around the high-rule-of-law mass of the sample. The posterior rule-of-law marginal effect is negative over much of the trust support, approximately from −0.52 to 1.89. Appendix Table 11 reports the full OLS and BMA coefficient summaries, and Appendix Figure 5 shows the broader model-averaged coefficient pattern.

FIGURE 4. Marginal Effects, Bayesian Model Averaging: the Sign Pattern Persists under Control-Set Uncertainty

Notes: The figures report posterior marginal effects implied by the baseline Bayesian model-averaging interaction specification. Bands are 90% posterior intervals computed from model-averaged posterior covariance terms. Support points are plotted on the zero line. Positive effects increase the reported size slope and therefore imply weaker conventional size premia; negative effects imply stronger conventional size premia.

Stepping back from the BMA exercise, the remainder of this section summarizes the results as a whole. Reported size-premium estimates are not organized by a simple additive story in which all favorable institutions move the premium in the same direction. Rule of law is the more stable finding: its association with the reported size slope holds under both clusterings. The trust finding is less stable: trust is positively associated with the slope mainly where rule of law is low, which implies a weaker premium in weaker formal-institutional settings. The BMA exercise is useful because it preserves this sign pattern under control-set uncertainty; it does not remove the sample-dependence and clustering uncertainty that remain visible in OLS.

The full results in Appendix Table 11 also show that the institutional terms are not the only systematic sources of heterogeneity. The most stable non-institutional patterns are concentrated in study design, sample construction, and primary-study specification choices. Estimates based on individual-stock samples and January-return specifications are associated with more negative reported size slopes, which corresponds to larger conventional size premia. Momentum controls are also associated with more negative reported size slopes. By contrast, trimming, value controls, price controls, and higher GDP per capita are associated with less negative reported slopes, implying smaller conventional size premia conditional on the other moderators. These variables are the clearest cases where OLS significance and high BMA posterior inclusion probabilities point in the same direction. Market-characteristic controls also have a strong positive OLS association, but their BMA evidence is less decisive once the rest of the control set is treated as uncertain.

## 6 Robustness and Diagnostics

The preceding section reports a rule-of-law association and a conditional trust pattern in reported size-premium estimates. This section asks how far that pattern changes when the analysis alters the measurement of trust and formal institutions, the control set, the tail treatment, the weighting and inference choices, and the composition of the estimate-level sample. Because the baseline specification applies mild 1/99 winsorization to the reported size slope and standard error, Table 5 includes both the no-winsorization benchmark and the more aggressive 5/95 stress test.

Two rows in Table 5 replace the smooth interaction with a median-split low-rule-of-law indicator. In those specifications, the trust coefficient is the trust slope above the rule-of-law median, the low-rule-of-law coefficient is the intercept shift below the median at average trust, and the interaction is the additional trust slope in the lower-rule-of-law regime. Because the dependent variable remains the reported size slope, a positive median-split interaction means that the trust slope is more positive below the rule-of-law median than above it. Whether trust is associated with a smaller premium below the median depends on the sum of the trust and interaction coefficients.

The collapsed specifications answer a different question. They average the estimate-level data to one observation per country, or to one observation per study-country cell, and then re-estimate the institutional interaction on those aggregates. They therefore test whether the same pattern is visible after removing much of the within-country and within-study estimate-level variation that identifies the baseline meta-regression.

TABLE 5. Robustness and Diagnostics: Rule of Law Is the More Stable of the Two Institutional Terms

| Check | Trust/focal coef. | Formal-institution coef. | Interaction coef. | Main reading |
|---|---|---|---|---|
| Flat-data OLS | 0.173 | -0.196 | -0.121 | Larger interaction when trust is treated as persistent |
| | (0.114) | (0.018) | (0.061) | |
| Residualized trust | 0.150 | -0.031 | -0.153 | Larger interaction after removing linear overlap |
| | (0.133) | (0.699) | (0.051) | |
| Reduced-control OLS | 0.058 | -0.110 | -0.043 | Same signs using high-PIP controls only |
| | (0.306) | (0.043) | (0.284) | |
| No winsorization OLS | 0.161 | -0.183 | -0.104 | Pattern is not created by tail treatment |
| | (0.147) | (0.011) | (0.150) | |
| 5/95 winsorized OLS | 0.058 | -0.056 | -0.036 | Aggressive compression attenuates the result |
| | (0.149) | (0.018) | (0.158) | |
| Precision-weighted limiting diagnostic | -0.001 | 0.000 | 0.001 | Coefficients collapse under concentrated weights |
| | (0.516) | (0.906) | (0.250) | |
| Family-trust placebo | 0.041 | -0.134 | -0.059 | Marginal effects do not reproduce the conditional substitution pattern |
| | (0.462) | (0.021) | (0.101) | |
| Regulatory-quality substitute | -0.053 | 0.078 | -0.030 | No comparable association |
| | (0.660) | (0.115) | (0.700) | |
| Government-effectiveness substitute | -0.024 | 0.020 | -0.031 | No comparable association |
| | (0.821) | (0.738) | (0.673) | |
| Control-of-corruption substitute | -0.054 | 0.145 | -0.051 | No comparable association |
| | (0.645) | (0.307) | (0.378) | |
| Low-rule-of-law median split, 1/99 winsorized | -0.089 | 0.087 | 0.078 | Weak under baseline tail treatment |
| | (0.338) | (0.189) | (0.479) | |
| Low-rule-of-law median split, 5/95 winsorized | -0.064 | 0.007 | 0.075 | Stronger only under aggressive tail treatment |
| | (0.036) | (0.726) | (0.034) | |
| Non-U.S. OLS | 0.036 | -0.058 | -0.011 | Continuous interaction collapses |
| | (0.448) | (0.039) | (0.798) | |
| Collapsed country and study-country evidence | – | – | -0.027 | No strong collapsed cross-country relationship |
| | | | (0.637); | |
| | | | -0.091 | |
| | | | (0.183) | |
Notes: The dependent variable is the reported size slope. Values in parentheses are *p*-values for the coefficient directly above them. Unless otherwise stated, estimates use 1/99 winsorization and country-clustered inference. Positive coefficients imply weaker conventional size premia, negative coefficients stronger premia. The no-winsorization and 5/95 rows report the designated tail-treatment benchmarks. The flat-data row summarizes generalized trust as a persistent country-level environment instead of matching it to the nearest survey year. The precision-weighted limiting diagnostic weights estimates by the inverse of the squared reported standard error. The collapsed row reports ordinary least squares estimates for country-level and study-country-level specifications. The focal coefficient is generalized trust except in the family-trust placebo and residualized-trust rows; in the median-split rows it is the generalized-trust slope above the rule-of-law median. The formal-institution coefficient is rule of law except in the WGI-substitute rows and median-split rows. The reading of the family-trust row comes from the covariance-adjusted marginal effects over the observed rule-of-law support, discussed below. The reduced-control row reports the 0.5 posterior-inclusion-probability threshold specification, which selects standard error, trimming, individual-stock sample, January returns, value controls, momentum controls, price controls, market-characteristic controls, and GDP per capita; the 0.8 threshold drops the market-characteristic control and gives the same qualitative result. Because this reduced specification omits several controls with missing observations, its complete-case sample contains 1,649 estimates from 105 studies and 42 countries.

## ENDNOTES

1. In the 1,613-observation model frame, 1/99 winsorization clips 17 observations in the lower tail and 16 observations in the upper tail of each variable. For the reported size slope, the support changes from [−3.600, 4.447] to [−1.735, 1.330], while the mean and standard deviation change from −0.091 and 0.472 to −0.087 and 0.344. For the standard error, the support changes from [3.05 × 10−7, 3.789] to [0.000123, 1.614], while the mean and standard deviation change from 0.089 and 0.278 to 0.084 and 0.226.

2. The standard output of the `BMS` package reports posterior means and marginal posterior standard deviations, but it does not report the cross-coefficient posterior covariances needed for interaction marginal effects. The BMA calculation therefore retains posterior cross-moments for the institutional coefficient block during the Markov chain. The resulting summaries were checked against the package's native output before using the retained covariance terms to form the marginal-effect intervals.

Three diagnostics are especially useful for interpreting the interaction. First, when survey-based trust is summarized as a persistent country-level trust environment (the flat-data OLS row), the smooth OLS interaction becomes more negative than in the baseline, −0.121. It is also closer to conventional significance under country clustering, with $p = 0.061$. This is the result one would expect if the relevant trust signal is slow moving. Nearest-survey-year matching is useful for preserving timing, but it can also add measurement noise when trust and legal institutions mainly vary across countries rather than within countries over short horizons. The flat-data check therefore suggests that the pattern is not driven by fine survey timing, and that it is at least as visible when trust is measured as a stable country-level informal institution.

Second, the residualized-trust diagnostic addresses a different concern: that generalized trust is simply proxying for rule of law or broad development. To this end, generalized trust is first purged of its linear association with rule of law, GDP per capita, and GDP growth, and the interaction model is then re-estimated using the remaining component of trust. The interaction again becomes larger in magnitude, −0.153, with $p = 0.051$ under country clustering. The residualized variable cannot be interpreted in the same way as raw generalized trust, so the exercise does not answer the same substantive question as the main specification. Its value is diagnostic: removing the linear component of trust most directly shared with rule of law and development does not eliminate the conditional sign pattern. This makes it less likely that the baseline interaction is only a proxy for broad country development or institutional quality.

Third, the alternative-WGI checks probe the specificity of the formal-institution result. Rule of law was chosen because the literature shows that enforcement, investor protection, legal recourse, and disclosure credibility are the formal mechanisms most relevant for small-firm financing and risk pricing. Regulatory quality, government effectiveness, and control of corruption are broader governance measures with a less direct connection to that mechanism. These substitutes do not reproduce the rule-of-law coefficient. Without a formal comparison across specifications, that pattern is consistent with rule-of-law specificity but also with measurement differences across the correlated WGI indicators.

The baseline pattern is not a by-product of a narrow modeling choice. A reduced-control OLS specification using only the controls with high posterior inclusion probabilities keeps the same signs, although the interaction is weaker than in the full-control specification and it runs on a wider complete-case sample of 1,649 estimates from 42 countries. Removing winsorization leaves the continuous interaction almost unchanged, indicating that the baseline sign pattern is not created by mild tail treatment. The family-trust placebo replaces generalized trust with particularized family trust. Its interpretation comes from the marginal effects and their 90% confidence intervals. Under study clustering, the family-trust effect is statistically indistinguishable from zero throughout the observed range of rule of law. For generalized trust, the effect is positive and statistically significant where rule of law is low. Under country clustering, family trust is never significantly positive. Its marginal effect becomes significantly negative only within a narrow range at the top of the rule-of-law distribution, which runs against the substitution hypothesis. The family-trust placebo therefore does not show the conditional pattern found for generalized trust.

The interpretation weakens under the remaining checks. The 5/95 winsorized specification materially compresses the support of the dependent variable and attenuates the continuous interaction, making it a deliberately severe stress test. The median-split specifications are secondary: under baseline tail treatment the additional low-rule-of-law trust slope is positive but weak, and under aggressive tail treatment it becomes sharper. This pattern is consistent with a stronger premium-reducing trust association where formal legal quality is weaker, although the threshold evidence depends on both threshold design and tail treatment.

The country-clustered $p$-values in Table 5 should also be read against the small number and uneven size of country clusters. In the 1/99 baseline, rule of law's country-clustered $p$-value rises from 0.016 to 0.058–0.100 under the few-cluster corrections, while trust and the interaction stay well short of significance throughout (Appendix Table 8). Rule of law remains the strongest institutional association but weakens to borderline evidence under the few-cluster checks. The interaction keeps the expected sign without becoming statistically informative.

The precision-weighted limiting diagnostic asks whether the institutional pattern is concentrated among the most precise reported estimates. Re-estimating the baseline by inverse-variance WLS moves the institutional coefficients essentially to zero. We read this as a limiting diagnostic rather than a robustness check, for two reasons. First, inverse-variance weighting is a weak guide to a study's informativeness in observational meta-regression: a reported standard error captures within-study sampling precision. That precision is inflated in large panels with correlated errors and says little about model uncertainty or the between-study heterogeneity that dominates a cross-country sample, so the most heavily weighted estimates need not be the most reliable. Second, the weights here are extremely concentrated: the effective sample size is about 119, and the top 5% of observations carry about 65% of total weight. The weighted estimand therefore reflects a small precision-selected subsample rather than the literature as a whole. For these reasons the baseline is deliberately unweighted, and we report the precision-weighted result for completeness rather than as a preferred specification.

Sample composition presents the clearest limitation. There are 49 distinct non-U.S. trust and rule-of-law value pairs in the analysis sample, so the non-U.S. institutional support is thin relative to the estimate count. In the non-U.S. diagnostic, rule of law remains negative and conventionally informative under country clustering, but the continuous interaction falls from about −0.108 to about −0.011 and is far from statistically informative. The rule-of-law association is therefore more stable than the trust-by-rule-of-law interaction. The interaction's generality depends heavily on sample composition. The collapsed country and study-country checks point in the same negative direction as the baseline smooth interaction, but they are statistically weak. The interaction emerges most clearly from the estimate-level meta-regression, which retains variation across study designs and reported estimates; a small cross-country comparison of average slopes supplies little statistical information.

## 7 Discussion

The results describe institutional heterogeneity in reported size-premium estimates, not the underlying small-minus-big return premium. Rule of law has the more stable institutional association, and its direction runs against the naive prior: stronger rule of law goes with more negative reported size slopes and therefore with larger conventional size premia. The trust result is conditional. Generalized trust is associated with a less negative reported size slope mainly where rule of law is weaker, and that association fades as formal legal quality rises. The OLS interaction is imprecise under clustered inference. The BMA exercise preserves the same posterior sign pattern under control-set uncertainty.

For illustration, we convert the fitted interaction into movements in the reported slope. Using country-level institutional quantiles avoids letting the heavily represented U.S. observations determine the comparison. Appendix Table 7 reports the quantiles used for this calculation. Moving generalized trust from the country-level 25th percentile to the 75th percentile is an increase of about 1.45 index units. In a low-rule-of-law environment, around the country-level 25th percentile, the baseline coefficients imply that such a trust increase corresponds to an increase of about 0.18 in the reported size slope. Because more negative slopes imply larger conventional size premia, this is a premium-reducing association. To see how large that movement is, start from the 25th percentile of reported slopes, −0.101 (close to the country-weighted baseline mean). Adding 0.18 gives an implied slope of about 0.08, which sits around the 93rd percentile of the observed slope distribution. The fitted trust movement thus spans the 25th to the 93rd percentile, an interval containing roughly two thirds of the baseline estimation sample.

At the country-level 75th percentile of rule of law, by contrast, the same trust shift implies a fitted movement of about −0.04, reflecting the attenuation and partial reversal that follow from the negative interaction.

The mechanism is most plausible when trust and rule of law are treated as distinct institutional margins rather than as a single scale of "good institutions." The trust literature makes two separate points. At the institutional level, informal constraints help structure exchange alongside formal rules (North, 1990), and commercial exchange often requires confidence when contracts cannot specify or enforce every contingency (Arrow, 1972). At the financial-market level, this logic has concrete margins. Social capital is associated with greater stockholding, check use, and access to institutional credit, with stronger effects where legal enforcement is weaker (Guiso et al., 2004). Individual trust predicts stock-market participation through the perceived risk of being cheated (Guiso et al., 2008). Societal trust makes corporate earnings announcements more informative to investors (Pevzner et al., 2015). These channels make generalized trust a plausible force reducing information and participation frictions around small, opaque firms, though financial-market experience can also feed back into generalized trust itself (Jha et al., 2025).

Formal enforcement works through a different margin. Legal protection and enforcement shape investor protection and ownership structures across countries (La Porta et al., 1998), and stronger legal institutions and securities regulation are associated with lower implied costs of equity capital (Hail & Leuz, 2006). Firm-level evidence also shows why this should matter for size: financial, legal, and corruption obstacles constrain growth most strongly for the smallest firms, and better financial and institutional development weakens those constraints (Beck et al., 2005). But formalization can also be costly in a size-asymmetric way. Evidence from SOX Section 404 suggests that compliance imposed real costs and reduced the market value of small firms (Iliev, 2010). Bright-line regulatory exemptions gave some small firms incentives to remain below compliance thresholds (Gao et al., 2009). The interaction is consistent with a conditional-substitution reading: informal assurance appears most relevant where formal enforcement is weaker. Stronger formal institutions can both relax financing frictions and make small-firm risks or fixed compliance burdens more visible. That does not mean that trust and law are always substitutes. Other settings document complementarity or mixed interactions (Bartling et al., 2025; Bloom et al., 2012; Carlin et al., 2009; Cruz-García & Peiró-Palomino, 2019). Our claim is confined to the way reported size-slope estimates line up with institutional environments in this meta-analytic sample.

The diagnostics help interpret the result but also define its scope. The flat-data and residualized-trust checks keep the same interaction sign and produce larger interaction magnitudes, suggesting that the result is not simply an artifact of fine survey timing or of trust proxying mechanically for rule of law and development. The family-trust marginal effects do not reproduce the conditional substitution pattern found for generalized trust. At the same time, the precision-weighted diagnostic is the exception, though a limited one for the reasons discussed above: the pattern is clearest in the unweighted meta-regression and fades under the highly concentrated inverse-variance weights. The non-U.S. and collapsed-sample checks also show that the evidence is too sample-dependent to sustain a broad cross-country claim.

## 8 Conclusion

We ask whether part of the heterogeneity in reported size-premium estimates is organized by institutions. We assemble 1,613 reported size-slope estimates from 105 studies and 31 countries, extending the estimate-level inventory of Astakhov et al. (2019), and match them to generalized trust from EVS/WVS and rule of law from the Worldwide Governance Indicators, with study-design, specification, precision, publication-context, market, and macro-financial controls.

The main institutional result is the rule-of-law association. Over much of the observed trust support, stronger rule of law is associated with more negative reported size slopes and therefore with larger conventional size premia; the association holds under both study- and country-clustered inference and survives dropping the U.S. sample. That direction is consistent with cleaner pricing of small-firm risk where enforcement is strong, and with disclosure and compliance costs that are fixed in size and therefore heavier for small firms. The trust result is conditional: generalized trust is associated with less negative reported size slopes when rule of law is weak. Under the paper's sign convention, that means a smaller conventional size premium where formal institutions are weak. The negative trust-by-rule-of-law interaction indicates that this trust association weakens as rule of law improves.

The evidence offers cautious support for an institutional-substitution interpretation: where formal enforcement is weak, informal assurance can partly stand in for it, and that role recedes as courts and disclosure rules become more reliable. Bayesian model averaging preserves the posterior signs under control-set uncertainty. Among the diagnostics, the rule-of-law association is the more stable of the two. Even so, the rule-of-law association weakens under few-cluster corrections and vanishes under concentrated inverse-variance weighting. That weighting is a weak diagnostic in this observational setting rather than a robustness failure. The trust-by-rule-of-law interaction weakens once the U.S. sample is removed and under precision weighting. Although the analysis neither identifies causal institutional effects nor establishes a general cross-country relationship, trust and rule of law help account for part of the disagreement in reported size-premium estimates. Future work would benefit most from broader non-U.S. evidence and from designs with cleaner identifying variation, such as within-country institutional reforms or cross-listing settings.

**Data and code availability.** The data and code that reproduce all results in this paper are available in the replication package at https://meta-analysis.cz/trust and archived at https://doi.org/10.5281/zenodo.21486177.

**Artificial intelligence use.** Claude Opus 4.8 and Claude Fable 5 by Anthropic, through Claude Code, and GPT-5.6 Sol by OpenAI, through Codex CLI, assisted in preparing and checking the analysis code, cross-checking and correcting the reported numbers, and editing the text. The data were collected by hand and without AI. All results were produced by running the authors' own code on the frozen dataset and can be reproduced from the public replication package. The authors are responsible for all of the paper's content.

## A Source Inventory and Diagnostic Support

The source inventory begins with Astakhov et al. (2019)'s published-study meta-analysis and its working-paper extension. The main published-study inventory contains 1,746 estimates from 102 studies. Appendix C of that source adds 10 further working-paper studies with 167 additional estimates. The analysis in this paper starts from the source inventory that includes both components, then applies the single-country restriction, the exclusion of estimates with sample midpoints before 1960, the institutional and control-variable matching requirements, and the complete-case restrictions used in the baseline specification. This produces 1,613 estimates from 105 studies and 31 countries. The 105-study count is therefore not a subset of the 102 published studies: all 10 Appendix C working-paper studies remain represented in the final sample, contributing 137 of the included estimates, while some studies from the published inventory do not enter the final complete-case analysis sample. Classifications are frozen at the source inventory's collection date, so an entry listed below as a working paper may since have been published (Hou & van Dijk, 2019).

TABLE 6. Studies Represented in the Final Analysis Sample, Ranked by Contributed Estimates

| Reference | Included estimates |
| --- | --- |
| Chui, A. C. W., & Wei, K. C. J. (1998). Book-to-market, firm size, and the turn-of-the-year effect: Evidence from Pacific-Basin emerging markets. *Pacific-Basin Finance Journal*, *6*(3-4), 275–293 | 64 |
| Gaunt, C., Gray, P., & McIvor, J. (2000). The impact of share price on seasonality and size anomalies in Australian equity returns. *Accounting & Finance*, *40*(1), 33–50 | 60 |
| Avramov, D., & Chordia, T. (2006). Asset pricing models and financial market anomalies. *Review of Financial Studies*, *19*(3), 1001–1040 | 54 |
| Chan, L. K. C., Hamao, Y., & Lakonishok, J. (1991). Fundamentals and stock returns in Japan. *The Journal of Finance*, *46*(5), 1739–1764 | 47 |
| Hur, J., Pettengill, G., & Singh, V. (2014). Market states and the risk-based explanation of the size premium. *Journal of Empirical Finance*, *28*, 139–150 | 38 |
| Serra, A. P. (2003). The cross-sectional determinants of returns: Evidence from emerging markets' stocks. *Journal of Emerging Market Finance*, *2*(2), 123–162 | 38 |
| Chordia, T., Subrahmanyam, A., & Anshuman, V. R. (2001). Trading activity and expected stock returns. *Journal of Financial Economics*, *59*(1), 3–32 | 36 |
| Bryant, P. S., & Eleswarapu, V. R. (1997). Cross-sectional determinants of New Zealand share market returns. *Accounting & Finance*, *37*(2), 181–205 | 36 |

TABLE 6 (continued).

| Reference | Included estimates |
| --- | --- |
| An, L., Wang, H., Wang, J., & Yu, J. (2018). *Lottery-related anomalies: The role of reference-dependent preferences* (PBCSF-NIFR Research Paper No. 15-04). PBC School of Finance, Tsinghua University | 36 |
| Novy-Marx, R. (2013). The other side of value: The gross profitability premium. *Journal of Financial Economics*, *108*(1), 1–28 | 34 |
| Moskowitz, T. J., & Grinblatt, M. (1999). Do industries explain momentum? *The Journal of Finance*, *54*(4), 1249–1290 | 32 |
| Fama, E. F., & French, K. R. (1992). The cross-section of expected stock returns. *The Journal of Finance*, *47*(2), 427–465 | 30 |
| Cooper, M. J., Gulen, H., & Schill, M. J. (2008). Asset growth and the cross-section of stock returns. *The Journal of Finance*, *63*(4), 1609–1651 | 28 |
| Jaffe, J., Keim, D. B., & Westerfield, R. (1989). Earnings yields, market values, and stock returns. *The Journal of Finance*, *44*(1), 135–148 | 28 |
| Chan, A., & Chui, A. P. L. (1996). An empirical re-examination of the cross-section of expected returns: UK evidence. *Journal of Business Finance & Accounting*, *23*(9-10), 1435–1452 | 28 |
| Datar, V. T., Naik, N. Y., & Radcliffe, R. (1998). Liquidity and stock returns: An alternative test. *Journal of Financial Markets*, *1*(2), 203–219 | 26 |
| Brennan, M. J., Chordia, T., & Subrahmanyam, A. (2004). Cross-sectional determinants of expected returns. In *The legacy of Fischer Black* (pp. 161–186). Oxford University Press | 26 |
| Brennan, M. J., Chordia, T., & Subrahmanyam, A. (1998). Alternative factor specifications, security characteristics, and the cross-section of expected stock returns. *Journal of Financial Economics*, *49*(3), 345–373 | 25 |
| Ang, A., Hodrick, R. J., Xing, Y., & Zhang, X. (2009). High idiosyncratic volatility and low returns: International and further U.S. evidence. *Journal of Financial Economics*, *91*(1), 1–23 | 25 |
| Penman, S. H., Richardson, S. A., & Tuna, İ. (2007). The book-to-price effect in stock returns: Accounting for leverage. *Journal of Accounting Research*, *45*(2), 427–467 | 24 |
| Bhandari, L. C. (1988). Debt/equity ratio and expected common stock returns: Empirical evidence. *The Journal of Finance*, *43*(2), 507–528 | 24 |
| Eleswarapu, V. R., & Reinganum, M. R. (1993). The seasonal behavior of the liquidity premium in asset pricing. *Journal of Financial Economics*, *34*(3), 373–386 | 24 |
| Kim, D. (1997). A reexamination of firm size, book-to-market, and earnings price in the cross-section of expected stock returns. *The Journal of Financial and Quantitative Analysis*, *32*(4), 463–489 | 24 |

| Reference | Included estimates |
| --- | --- |
| George, T. J., & Hwang, C.-Y. (2010). A resolution of the distress risk and leverage puzzles in the cross section of stock returns. *Journal of Financial Economics*, *96*(1), 56–79 | 22 |
| Edmans, A., Li, L., & Zhang, C. (2014). *Employee satisfaction, labor market flexibility, and stock returns around the world* (NBER Working Paper No. 20300). National Bureau of Economic Research | 22 |
| Ruenzi, S., & Weigert, F. (2011). *Extreme dependence structures and the cross-section of expected stock returns* (EFA 2011 Meetings Paper). European Finance Association | 22 |
| Eleswarapu, V. R. (1997). Cost of transacting and expected returns in the Nasdaq market. *The Journal of Finance*, *52*(5), 2113–2127 | 21 |
| Wahlroos, B., & Berglund, T. (1986). Anomalies and equilibrium returns in a small stock market. *Journal of Business Research*, *14*(5), 423–440 | 21 |
| Asparouhova, E., Bessembinder, H., & Kalcheva, I. (2013). Noisy prices and inference regarding returns. *The Journal of Finance*, *68*(2), 665–714 | 20 |
| Knez, P. J., & Ready, M. J. (1997). On the robustness of size and book-to-market in cross-sectional regressions. *The Journal of Finance*, *52*(4), 1355–1382 | 20 |
| Loughran, T. (1997). Book-to-market across firm size, exchange, and seasonality: Is there an effect? *The Journal of Financial and Quantitative Analysis*, *32*(3), 249–268 | 20 |
| Easley, D., Hvidkjaer, S., & O'Hara, M. (2002). Is information risk a determinant of asset returns? *The Journal of Finance*, *57*(5), 2185–2221 | 20 |
| Pontiff, J., & Woodgate, A. (2008). Share issuance and cross-sectional returns. *The Journal of Finance*, *63*(2), 921–945 | 20 |
| Lakonishok, J., & Shapiro, A. C. (1986). Systematic risk, total risk and size as determinants of stock market returns. *Journal of Banking & Finance*, *10*(1), 115–132 | 20 |
| Garza-Gómez, X., Hodoshima, J., & Kunimura, M. (1998). Does size really matter in Japan? *Financial Analysts Journal*, *54*(6), 22–34 | 20 |
| Chang, R., Guan, L., Chen, J., Kan, K. L., & Anderson, H. (2007). Size, book/market ratio and risk factor returns: Evidence from China A-Share market. *Managerial Finance*, *33*(8), 574–594 | 20 |
| Brennan, M. J., Chordia, T., Subrahmanyam, A., & Tong, Q. (2012). Sell-order liquidity and the cross-section of expected stock returns. *Journal of Financial Economics*, *105*(3), 523–541 | 20 |
| Chan, K. C., & Chen, N.-F. (1988). An unconditional asset-pricing test and the role of firm size as an instrumental variable for risk. *The Journal of Finance*, *43*(2), 309–325 | 19 |

| Reference | Included estimates |
| --- | --- |
| Burlacu, R., Fontaine, P., Jimenez-Garcès, S., & Seasholes, M. S. (2012). Risk and the cross section of stock returns. *Journal of Financial Economics*, *105*(3), 511–522 | 19 |
| Heston, S. L., Rouwenhorst, K. G., & Wessels, R. E. (1999). The role of beta and size in the cross-section of European stock returns. *European Financial Management*, *5*(1), 9–27 | 18 |
| Elfakhani, S., Lockwood, L. J., & Zaher, T. S. (1998). Small firm and value effects in the Canadian stock market. *Journal of Financial Research*, *21*(3), 277–291 | 18 |
| Ho, R. Y.-w., Strange, R., & Piesse, J. (2006). On the conditional pricing effects of beta, size, and book-to-market equity in the Hong Kong market. *Journal of International Financial Markets, Institutions and Money*, *16*(3), 199–214 | 18 |
| Howton, S. W., & Peterson, D. R. (1998). An examination of cross-sectional realized stock returns using a varying-risk beta model. *Financial Review*, *33*(3), 199–212 | 18 |
| Fan, X., & Liu, M. (2005). Understanding size and the book-to-market ratio: An empirical exploration of Berk’s critique. *Journal of Financial Research*, *28*(4), 503–518 | 17 |
| Hou, K., van Dijk, M. A., & Zhang, Y. (2012). The implied cost of capital: A new approach. *Journal of Accounting and Economics*, *53*(3), 504–526 | 15 |
| Acharya, V., & Pedersen, L. (2005). Asset pricing with liquidity risk. *Journal of Financial Economics*, *77*(2), 375–410 | 15 |
| Mondria, J., & Wu, T. (2011). *Asymmetric attention and stock returns* (AFA 2012 Chicago Meetings Paper). American Finance Association | 15 |
| Pettengill, G., Sundaram, S., & Mathur, I. (2002). Payment for risk: Constant beta vs. dual-beta models. *Financial Review*, *37*(2), 123–135 | 14 |
| Bali, T. G., Cakici, N., & Whitelaw, R. F. (2011). Maxing out: Stocks as lotteries and the cross-section of expected returns. *Journal of Financial Economics*, *99*(2), 427–446 | 12 |
| Hou, K., & Moskowitz, T. J. (2005). Market frictions, price delay, and the cross-section of expected returns. *Review of Financial Studies*, *18*(3), 981–1020 | 12 |
| Pinfold, J. F., Wilson, W. R., & Li, Q. (2001). Book-to-market and size as determinants of returns in small illiquid markets. *Financial Services Review*, *10*(1-4), 291–302 | 12 |
| Claessens, S., Dasgupta, S., & Glen, J. (1995). *The cross-section of stock returns: Evidence from the emerging markets* (Policy Research Working Paper No. 1505). World Bank | 11 |
| Diavatopoulos, D., Doran, J. S., & Peterson, D. R. (2008). The information content in implied idiosyncratic volatility and the cross-section of stock returns: Evidence from the option markets. *Journal of Futures Markets*, *28*(11), 1013–1039 | 11 |
| Whited, T. M., & Wu, G. (2006). Financial constraints risk. *Review of Financial Studies*, *19*(2), 531–559 | 10 |
| Jensen, G. R., & Mercer, J. M. (2002). Monetary policy and the cross-section of expected stock returns. *Journal of Financial Research*, *25*(1), 125–139 | 10 |
| Diether, K. B., Malloy, C. J., & Scherbina, A. (2002). Differences of opinion and the cross section of stock returns. *The Journal of Finance*, *57*(5), 2113–2141 | 10 |
| Kothari, S. P., Shanken, J., & Sloan, R. G. (1995). Another look at the cross-section of expected stock returns. *The Journal of Finance*, *50*(1), 185–224 | 10 |
| Dissanaike, G. (2002). Does the size effect explain the UK winner-loser effect? *Journal of Business Finance & Accounting*, *29*(1-2), 139–154 | 10 |
| Green, J., Hand, J. R. M., & Zhang, X. F. (2014). *The remarkable multidimensionality in the cross-section of expected U.S. stock returns* (SSRN Working Paper). Social Science Research Network | 10 |
| Strong, N., & Xu, X. G. (1997). Explaining the cross-section of UK expected stock returns. *The British Accounting Review*, *29*(1), 1–23 | 9 |
| Chen, J., Hong, H., & Stein, J. C. (2002). Breadth of ownership and stock returns. *Journal of Financial Economics*, *66*(2-3), 171–205 | 9 |
| Hodoshima, J., Garza-Gómez, X., & Kunimura, M. (2000). Cross-sectional regression analysis of return and beta in Japan. *Journal of Economics and Business*, *52*(6), 515–533 | 9 |
| Eisdorfer, A., Goyal, A., & Zhdanov, A. (2015). *Misvaluation and return anomalies in distress stocks* (SSRN Working Paper). Social Science Research Network | 9 |
| Hou, K., & van Dijk, M. A. (2018). *Resurrecting the size effect: Firm size, profitability shocks, and expected stock returns* (Working Paper). Charles A. Dice Center for Research in Financial Economics | 9 |
| Fu, F. (2009). Idiosyncratic risk and the cross-section of expected stock returns. *Journal of Financial Economics*, *91*(1), 24–37 | 8 |
| Ferson, W. E., & Harvey, C. R. (1999). Conditioning variables and the cross section of stock returns. *The Journal of Finance*, *54*(4), 1325–1360 | 8 |
| Dichev, I. D. (1998). Is the risk of bankruptcy a systematic risk? *The Journal of Finance*, *53*(3), 1131–1147 | 8 |
| Chan, L. K. C., Hamao, Y., & Lakonishok, J. (1993). Can fundamentals predict Japanese stock returns? *Financial Analysts Journal*, *49*(4), 63–69 | 8 |
| Cooper, M. J., Gulen, H., & Rau, P. R. (2016). *Performance for pay? The relation between CEO incentive compensation and future stock price performance* (SSRN Working Paper). Social Science Research Network | 8 |
| Amel-Zadeh, A. (2011). The return of the size anomaly: Evidence from the German stock market. *European Financial Management*, *17*(1), 145–182 | 7 |
| Phalippou, L. (2007). Can risk-based theories explain the value premium? *Review of Finance*, *11*(2), 143–166 | 7 |
| Jagannathan, R., & Wang, Y. (2007). Lazy investors, discretionary consumption, and the cross-section of stock returns. *The Journal of Finance*, *62*(4), 1623–1661 | 7 |
| Anderson, C. W., & Garcia-Feijóo, L. (2006). Empirical evidence on capital investment, growth options, and security returns. *The Journal of Finance*, *61*(1), 171–194 | 6 |
| Loughran, T., & Ritter, J. R. (1995). The new issues puzzle. *The Journal of Finance*, *50*(1), 23–51 | 6 |
| Waszczuk, A. (2013). A risk-based explanation of return patterns–Evidence from the Polish stock market. *Emerging Markets Review*, *15*, 186–210 | 6 |
| Jegadeesh, N. (1992). Does market risk really explain the size effect? *The Journal of Financial and Quantitative Analysis*, *27*(3), 337–351 | 6 |
| Amihud, Y., & Mendelson, H. (1989). The effects of beta, bid-ask spread, residual risk, and size on stock returns. *The Journal of Finance*, *44*(2), 479–486 | 6 |
| Tinic, S. M., & West, R. R. (1986). Risk, return, and equilibrium: A revisit. *Journal of Political Economy*, *94*(1), 126–147 | 6 |
| Fama, E. F., & French, K. R. (2008). Dissecting anomalies. *The Journal of Finance*, *63*(4), 1653–1678 | 5 |
| Ang, A., Chen, J., & Xing, Y. (2006). Downside risk. *Review of Financial Studies*, *19*(4), 1191–1239 | 5 |
| Horowitz, J. L., Loughran, T., & Savin, N. E. (2000a). The disappearing size effect. *Research in Economics*, *54*(1), 83–100 | 5 |
| Chan, K. C., Chen, N.-F., & Hsieh, D. A. (1985). An exploratory investigation of the firm size effect. *Journal of Financial Economics*, *14*(3), 451–471 | 5 |
| Demirtas, K. O., & Guner, A. B. (2008). Can overreaction explain part of the size premium? *International Journal of Revenue Management*, *2*(3), 234–253 | 5 |
| Amihud, Y. (2002). Illiquidity and stock returns: Cross-section and time-series effects. *Journal of Financial Markets*, *5*(1), 31–56 | 4 |
| Nagel, S. (2005). Short sales, institutional investors and the cross-section of stock returns. *Journal of Financial Economics*, *78*(2), 277–309 | 4 |
| Herrera, M. J., & Lockwood, L. J. (1994). The size effect in the Mexican stock market. *Journal of Banking & Finance*, *18*(4), 621–632 | 4 |
| Bagella, M., Becchetti, L., & Carpentieri, A. (2000). “The first shall be last”. Size and value strategy premia at the London Stock Exchange. *Journal of Banking & Finance*, *24*(6), 893–919 | 4 |
| Lakonishok, J., Shleifer, A., & Vishny, R. W. (1994). Contrarian investment, extrapolation, and risk. *The Journal of Finance*, *49*(5), 1541–1578 | 4 |
| Reinganum, M. R. (1982). A direct test of Roll’s conjecture on the firm size effect. *The Journal of Finance*, *37*(1), 27–35 | 4 |
| Barry, C. B., & Brown, S. J. (1984). Differential information and the small firm effect. *Journal of Financial Economics*, *13*(2), 283–294 | 4 |
| Jagannathan, R., & Wang, Z. (1996). The conditional CAPM and the cross-section of expected returns. *The Journal of Finance*, *51*(1), 3–53 | 4 |
| Cooper, M. J., Gulen, H., & Ovtchinnikov, A. V. (2010). Corporate political contributions and stock returns. *The Journal of Finance*, *65*(2), 687–724 | 4 |
| Cremers, K. J. M., Nair, V. B., & John, K. (2009). Takeovers and the cross-section of returns. *Review of Financial Studies*, *22*(4), 1409–1445 | 4 |
| Penman, S. H., Reggiani, F., Richardson, S. A., & Tuna, A. İ. (2015). *An accounting-based characteristic model for asset pricing* (SSRN Working Paper). Social Science Research Network | 4 |
| Banz, R. W. (1981). The relationship between return and market value of common stocks. *Journal of Financial Economics*, *9*(1), 3–18 | 3 |
| La Porta, R. (1996). Expectations and the cross-section of stock returns. *The Journal of Finance*, *51*(5), 1715–1742 | 3 |
| Doeswijk, R. Q. (1997). Contrarian investment in the Dutch stock market. *De Economist*, *145*(4), 573–598 | 3 |
| Hou, K., Karolyi, G. A., & Kho, B.-C. (2011). What factors drive global stock returns? *The Review of Financial Studies*, *24*(8), 2527–2574 | 2 |
| Fletcher, J. (1997). An examination of the cross-sectional relationship of beta and return: UK evidence. *Journal of Economics and Business*, *49*(3), 211–221 | 2 |
| Chan, K. C., & Chen, N.-F. (1991). Structural and return characteristics of small and large firms. *The Journal of Finance*, *46*(4), 1467–1484 | 2 |
| Vos, E., & Pepper, B. (1997). The size and book to market effects in New Zealand. *New Zealand Investment Analyst*, *18*, 35–45 | 2 |
| Da, Z. (2009). Cash flow, consumption risk, and the cross-section of stock returns. *The Journal of Finance*, *64*(2), 923–956 | 2 |
| Han, B., & Zhou, Y. (2012). *Variance risk premium and cross-section of stock returns* (Unpublished working paper). University of Texas at Austin | 2 |
| Horowitz, J. L., Loughran, T., & Savin, N. E. (2000b). Three analyses of the firm size premium. *Journal of Empirical Finance*, *7*(2), 143–153 | 1 |
| Chan, L. K. C., Karceski, J., & Lakonishok, J. (1998). The risk and return from factors. *The Journal of Financial and Quantitative Analysis*, *33*(2), 159–188 | 1 |
Notes: The table lists the studies represented in the final analysis sample and the number of estimates included from each study. The source inventory follows Astakhov et al. (2019).

TABLE 7. Country-Level Institutional Quantiles Used in the Magnitude Calculation
| Variable | P25 | Median | P75 |
| --- | --- | --- | --- |
| Generalized trust | -0.490 | 0.139 | 0.958 |
| Rule of law | 0.171 | 1.056 | 1.625 |
Notes: Quantiles are computed over countries represented in the final analysis sample, rather than over estimate-level observations. They are used only to scale the illustrative fitted magnitudes reported in the text.

TABLE 8. Small-Cluster Inference for Baseline Institutional Terms
| Term | CR1 *p* | CR2/Satt. *p* | Wild boot. *p* |
| --- | --- | --- | --- |
| Generalized trust | 0.192 | 0.359 | 0.420 |
| Rule of law | 0.016 | 0.100 | 0.058 |
| Generalized trust × rule of law | 0.139 | 0.319 | 0.305 |
Notes: The diagnostics use the 1/99 winsorized baseline specification and country clustering. CR1 is the conventional country-clustered reference used in the main table. CR2/Satterthwaite and null-imposed restricted wild-cluster bootstrap *p*-values probe the sensitivity of inference to the limited and uneven country-cluster structure. The bootstrap uses Rademacher weights and 99,999 draws.

## B Variable Definitions

TABLE 9. Variable Dictionary
| Variable or group | Definition |
| --- | --- |
| Size slope | Reported coefficient on firm size inherited from Astakhov et al. (2019); more negative values imply a larger conventional size premium. |
| Standard error | Reported or reconstructed standard error of the size-slope estimate. |
| Generalized trust index | Average of standardized EVS/WVS country-year measures of generalized trust. The index combines the standard “most people can be trusted” item with survey questions on trust in neighbors, personally known people, people met for the first time, people of another religion, people of another nationality, and people in the respondent’s country. |
| Family-trust placebo index | Average of standardized EVS/WVS country-year measures of trust in family, used as a particularized-trust placebo. |
| Rule of law | WGI rule-of-law estimate matched by country and nearest year. |
| Alternative WGI measures | Government effectiveness, regulatory quality, and control of corruption; used in robustness checks. |
Notes: For the generalized- and family-trust indexes, higher values denote higher trust; for rule of law and the alternative WGI measures, higher values denote stronger institutional quality.

TABLE 10. Control Variable Groups
| Group | Variables |
| --- | --- |
| Study design and estimate controls | Relative-size coding, sample midyear, sample length, trimming, OLS and Fama–MacBeth indicators, excess-return coding, individual-stock indicator, January indicator, publication impact, citations, and independent-variable demeaning. |
| Asset-pricing specification controls | Indicators for value, systematic risk, momentum, leverage, profitability, liquidity, volatility, price, market characteristics, market state, information, ownership, growth, distress, and size controls. |
| Macro-financial controls | Bond yield, market-return volatility, private credit to GDP, GDP per capita, and GDP growth. |
Notes: Continuous controls are transformed as described in Section 3.4. Relative to the moderator families named in the main text, the precision moderator (the reported standard error, Table 9) enters the specification alongside these groups, publication context (publication impact and citations) is listed within the study-design row, and the market-characteristic and market-state indicators within the asset-pricing row.

## C Additional Tables and Figures

FIGURE 5. Bayesian Model-Averaged Coefficient Summary

Notes: The figure is the model-inclusion plot of the `BMS` package. Columns are sampled models ordered by cumulative posterior model probability, rows are variables ordered by posterior inclusion probability, and the plot title reports the number of distinct models the sampler retained. Blue marks inclusion with a positive coefficient, red marks inclusion with a negative coefficient, and white marks exclusion. Institutional terms are forced into every sampled model by design; posterior inclusion probabilities for the remaining controls reflect model uncertainty over the control set.

TABLE 11. Full Baseline OLS and BMA Meta-Regression (All Controls)
| Variable | OLS: Coef. | OLS: Study SE | OLS: Country SE | BMA: Post. Mean | BMA: Post. SD | BMA: PIP |
| --- | --- | --- | --- | --- | --- | --- |
| Intercept | −1.565 | 0.572*** | 0.435*** | −1.335 | – | 1.000 |
| *Precision and coding* | | | | | | |
| Standard error | −0.139 | 0.306 | 0.160 | −0.158 | 0.040 | 0.992 |
| Relative-size coding | 0.051 | 0.048 | 0.020** | 0.005 | 0.021 | 0.063 |

TABLE 11 (continued).
| Variable | OLS: Coef. | OLS: Study SE | OLS: Country SE | BMA: Post. Mean | BMA: Post. SD | BMA: PIP |
| --- | --- | --- | --- | --- | --- | --- |
| *Sample period and data treatment* | | | | | | |
| Sample midyear | −0.002 | 0.002 | 0.003 | −0.000 | 0.000 | 0.028 |
| Log sample length | −0.027 | 0.037 | 0.026 | −0.000 | 0.002 | 0.013 |
| Any trimming | 0.110 | 0.048** | 0.019*** | 0.109 | 0.019 | 1.000 |
| *Estimator and return specification* | | | | | | |
| OLS estimator | 0.001 | 0.033 | 0.016 | −0.000 | 0.002 | 0.012 |
| Fama–MacBeth estimator | 0.049 | 0.042 | 0.021** | 0.001 | 0.009 | 0.036 |
| Excess-return specification | −0.031 | 0.037 | 0.019 | −0.001 | 0.005 | 0.027 |
| Individual-stock sample | −0.164 | 0.060*** | 0.018*** | −0.130 | 0.019 | 1.000 |
| January-return specification | −0.350 | 0.154** | 0.155** | −0.345 | 0.035 | 1.000 |
| *Publication context* | | | | | | |
| Journal impact | 0.001 | 0.037 | 0.010 | 0.000 | 0.001 | 0.012 |
| Log citations | −0.005 | 0.015 | 0.005 | 0.000 | 0.001 | 0.015 |
| *Primary-study controls* | | | | | | |
| Demeaned size variable | 0.060 | 0.057 | 0.020*** | 0.001 | 0.009 | 0.019 |
| Value controls | 0.150 | 0.047*** | 0.029*** | 0.139 | 0.020 | 1.000 |
| Systematic-risk controls | 0.012 | 0.031 | 0.010 | 0.000 | 0.004 | 0.023 |
| Momentum controls | −0.128 | 0.057** | 0.018*** | −0.153 | 0.024 | 1.000 |
| Leverage controls | 0.006 | 0.047 | 0.031 | 0.000 | 0.004 | 0.013 |
| Profitability controls | −0.026 | 0.053 | 0.031 | −0.000 | 0.004 | 0.015 |
| Liquidity controls | −0.040 | 0.064 | 0.008*** | −0.001 | 0.006 | 0.030 |
| Volatility controls | −0.022 | 0.062 | 0.014 | −0.000 | 0.003 | 0.014 |
| Price controls | 0.150 | 0.048*** | 0.028*** | 0.133 | 0.026 | 0.999 |
| Market-characteristic controls | 0.152 | 0.040*** | 0.008*** | 0.122 | 0.089 | 0.715 |
| Market-state controls | −0.117 | 0.062* | 0.023*** | −0.008 | 0.033 | 0.078 |
| Information controls | 0.038 | 0.056 | 0.026 | −0.000 | 0.007 | 0.018 |
| Ownership controls | −0.213 | 0.224 | 0.071*** | −0.077 | 0.087 | 0.488 |
| Growth controls | −0.027 | 0.060 | 0.009*** | −0.000 | 0.005 | 0.012 |
| Distress controls | −0.092 | 0.059 | 0.032*** | −0.001 | 0.010 | 0.022 |
| Additional size controls | 0.115 | 0.067* | 0.022*** | 0.003 | 0.018 | 0.042 |
| *Macro-financial controls* | | | | | | |
| Bond yield | 0.007 | 0.005 | 0.004 | 0.002 | 0.004 | 0.290 |
| Market-return volatility | −0.016 | 0.028 | 0.017 | −0.000 | 0.002 | 0.013 |
| Private credit to GDP | −0.030 | 0.072 | 0.069 | −0.001 | 0.008 | 0.020 |
| Log GDP per capita | 0.175 | 0.069** | 0.050*** | 0.140 | 0.026 | 1.000 |
| GDP growth | 0.025 | 0.056 | 0.063 | 0.000 | 0.004 | 0.017 |
| *Institutional variables* | | | | | | |
| Generalized trust | 0.146 | 0.086* | 0.112 | 0.135 | 0.066 | 1.000 |
| Rule of law | −0.168 | 0.077** | 0.070** | −0.126 | 0.046 | 1.000 |
| Generalized trust × rule of law | −0.108 | 0.073 | 0.073 | −0.092 | 0.043 | 1.000 |
Notes: The dependent variable is the 1/99 winsorized reported size slope. The OLS coefficient is identical across the OLS columns because both columns estimate the same model; only the cluster-robust covariance matrix changes. Study SE uses study-clustered inference and Country SE uses country-clustered inference. Significance stars correspond to the relevant clustering column: ^{*} p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01. BMA columns report posterior means, posterior standard deviations, and posterior inclusion probabilities from the baseline Bayesian model averaging specification. The intercept is always included in BMA, so its PIP is one and no posterior standard deviation is reported by the coefficient summary of the `BMS` package used for the BMA estimation. The sample contains 1,613 estimates from 105 studies and 31 countries. Several study-design indicators vary mostly within country, so their country-clustered standard errors can be much smaller than their study-clustered counterparts.

## D Reporting and AI-Use Compliance

This appendix records how the paper meets the MAER-Net reporting guidelines for meta-analysis in economics as updated for artificial intelligence (Cook et al., 2026b) and the accompanying principles for AI use (Cook et al., 2026a), and where it departs from them.

#### Research question and effect size.

Section 2 states the hypotheses and the sign predictions. Section 3 defines the effect size as the reported regression slope on firm size, states the sign convention used throughout, and identifies the reported standard error as the precision measure. Equations (1) and (2) give the primary-study specification and the meta-regression. The reported slopes are not converted to a common cardinal metric; Section 3 gives the reason, which is that the estimates come from heterogeneous primary specifications and units, so the analysis is carried out, and interpreted, in reported-slope space.

#### Search, screening, and coding.

We do not conduct a new literature search. The estimate-level inventory, including the search, the inclusion and exclusion rules, and the coding of study and design characteristics, is inherited from Astakhov et al. (2019), which documents how that inventory was assembled; Appendix A states what we take from that source and which restrictions we then apply. This paper therefore supplies no PRISMA flow diagram of its own, and it neither identifies the coders of the underlying estimates nor reports a measure of their agreement. No AI took part in searching, screening, or coding, because none of those steps was carried out here.

#### Coded variables, meta-regression, and bias.

Table 9 defines the focal variables and Table 10 groups the control set; Table 2 reports descriptive statistics for the outcome, the reported standard error, and the institutional variables, and Table 1 reports sources and coverage. Definitions and descriptive statistics are not tabulated for every coded moderator. The full meta-regression is reported in Appendix Table 11, with Bayesian model averaging over the control set as the stated strategy for handling model uncertainty. Publication and precision context enters through the reported standard error and the related moderators; we do not re-estimate publication bias, which Astakhov et al. (2019) document for this inventory.

Dependence across estimates is handled with study- and country-clustered standard errors and with the small-cluster corrections in Table 8. Precision weighting is probed separately by the inverse-variance diagnostic. The winsorization rule used to limit the influence of outliers is stated in Section 4.

**Interpretation and sharing.** Figures 1 to 3 display the distribution of effect sizes and the fitted marginal effects, with the observed support of the conditioning variable shown so that extrapolated regions can be told apart. Table 5 reports the robustness checks. Section 7 discusses economic significance and the limits of the design. The data and code are archived and citable, and reproduce every reported number.

**AI use.** The declaration at the end of the paper names the models, their versions, and the interfaces through which they were used. Data collection was entirely human: the estimate-level inventory was hand-collected in the source study, and the institutional layer was assembled and matched to it by the authors. AI entered only afterwards, and assisted with preparing and checking analysis code, with cross-checking and correcting reported numbers against the output of that code, and with editing prose. It did not select, screen, or code studies; the specifications were chosen by the authors. No table or figure was produced end to end without human validation. Every reported number was produced by running the authors' own code on the frozen dataset. Dates of use and model settings are not recorded for each individual application. The authors are accountable for the content, and can supply prompts and interaction logs to an editor or referee on request.

**Departures.** The paper departs from the guidelines at five points. First, reported slopes are not converted to a common cardinal metric. Second, there is no new search, screening, or coding, and so no PRISMA flow diagram, no coder identities, and no inter-coder agreement measure. Third, definitions and descriptive statistics are not tabulated for every coded moderator, and Table 1 does not name provider-level sources for the macro-financial controls. Fourth, there is no new publication-bias investigation; the paper relies on the evidence reported for the source inventory, while still controlling for precision in the meta-regression. Fifth, dates of use and model settings are not recorded for each AI application. The guidelines allow exceptions when accompanied by a rationale. For all but the last departure, the reason is the same: the paper begins from an existing estimate-level inventory, and its contribution is the institutional layer matched to those estimates.

## REFERENCES

Acemoglu, D., & Jackson, M. O. (2017). Social norms and the enforcement of laws. *Journal of the European Economic Association, 15*(2), 245–295.

Acemoglu, D., & Johnson, S. (2005). Unbundling institutions. *Journal of Political Economy, 113*(5), 949–995.

Acemoglu, D., Johnson, S., & Robinson, J. A. (2001). The colonial origins of comparative development: An empirical investigation. *American Economic Review, 91*(5), 1369–1401.

Acemoglu, D., Johnson, S., & Robinson, J. A. (2005). Institutions as the fundamental cause of long-run growth. In *Handbook of economic growth* (pp. 385–472, Vol. 1A). Elsevier.

Aghion, P., Algan, Y., Cahuc, P., & Shleifer, A. (2010). Regulation and distrust. *Quarterly Journal of Economics, 125*(3), 1015–1049.

Ahlerup, P., Olsson, O., & Yanagizawa, D. (2009). Social capital vs institutions in the growth process. *European Journal of Political Economy, 25*(1), 1–14.

Alesina, A., & Giuliano, P. (2010). The power of the family. *Journal of Economic Growth, 15*(2), 93–125.

Algan, Y., & Cahuc, P. (2010). Inherited trust and growth. *American Economic Review, 100*(5), 2060–2092.

Amihud, Y. (2002). Illiquidity and stock returns: Cross-section and time-series effects. *Journal of Financial Markets, 5*(1), 31–56.

Amiraslani, H., Lins, K. V., Servaes, H., & Tamayo, A. (2023). Trust, social capital, and the bond market benefits of ESG performance. *Review of Accounting Studies, 28*(2), 421–462.

Arrow, K. J. (1972). Gifts and exchanges. *Philosophy and Public Affairs, 1*(4), 343–362.

Asness, C. S., Frazzini, A., Israel, R., Moskowitz, T. J., & Pedersen, L. H. (2018). Size matters, if you control your junk. *Journal of Financial Economics, 129*(3), 479–509.

Astakhov, A., Havranek, T., & Novak, J. (2019). Firm size and stock returns: A quantitative survey. *Journal of Economic Surveys, 33*(5), 1463–1492.

Bajzik, J., Havranek, T., Irsova, Z., & Schwarz, J. (2020). Estimating the Armington elasticity: The importance of study design and publication bias. *Journal of International Economics, 127*, 103383.

Banfield, E. C. (1958). *The moral basis of a backward society.* Free Press.

Banz, R. W. (1981). The relationship between return and market value of common stocks. *Journal of Financial Economics, 9*(1), 3–18.

Barry, C. B., Goldreyer, E., Lockwood, L., & Rodriguez, M. (2002). Robustness of size and value effects in emerging equity markets, 1985–2000. *Emerging Markets Review, 3*(1), 1–30.

Bartling, B., Fehr, E., Huffman, D., & Netzer, N. (2025). The complementarity between trust and contract enforcement. *The Economic Journal*, Article ueaf077.

Basu, S. (1983). The relationship between earnings' yield, market value and return for NYSE common stocks: Further evidence. *Journal of Financial Economics, 12*(1), 129–156.

Beck, T., & Levine, R. (2005). Legal institutions and financial development. In *Handbook of new institutional economics.* Springer.

Beck, T., Demirgüç-Kunt, A., & Levine, R. (2003). Law, endowments, and finance. *Journal of Financial Economics, 70*(2), 137–181.

Beck, T., Demirgüç-Kunt, A., & Maksimovic, V. (2005). Financial and legal constraints to growth: Does firm size matter? *The Journal of Finance, 60*(1), 137–177.

Beck, T., Demirgüç-Kunt, A., & Maksimovic, V. (2008). Financing patterns around the world: Are small firms different? *Journal of Financial Economics, 89*(3), 467–487.

Berger, A. N., & Udell, G. F. (1995). Relationship lending and lines of credit in small firm finance. *The Journal of Business, 68*(3), 351–381.

Berger, A. N., & Udell, G. F. (1998). The economics of small business finance: The roles of private equity and debt markets in the financial growth cycle. *Journal of Banking & Finance, 22*(6–8), 613–673.

Berk, J. B. (2000). Sorting out sorts. *The Journal of Finance, 55*(1), 407–427.

Bhandari, L. C. (1988). Debt/equity ratio and expected common stock returns: Empirical evidence. *The Journal of Finance, 43*(2), 507–528.

Bhattacharya, U., & Daouk, H. (2002). The world price of insider trading. *The Journal of Finance, 57*(1), 75–108.

Bjørnskov, C. (2022). Social trust and patterns of growth. *Southern Economic Journal, 89*(1), 216–237.

Black, F. (1972). Capital market equilibrium with restricted borrowing. *Journal of Business, 45*(3), 444–455.

Bloom, N., Sadun, R., & Van Reenen, J. (2012). The organization of firms across countries. *The Quarterly Journal of Economics, 127*(4), 1663–1705.

Blume, M. E. (1970). Portfolio theory: A step toward its practical application. *Journal of Business, 43*(2), 152–173.

Bottazzi, L., Da Rin, M., & Hellmann, T. (2016). The importance of trust for investment: Evidence from venture capital. *Review of Financial Studies, 29*(9), 2283–2318.

Bricker, J., & Li, G. (2023). *Credit scores, social trust, and stock market participation* (tech. rep.). Finance and Economics Discussion Series 2017-008r1. Board of Governors of the Federal Reserve System.

Carhart, M. M. (1997). On persistence in mutual fund performance. *The Journal of Finance, 52*(1), 57–82.

Carlin, B. I., Dorobantu, F., & Viswanathan, S. (2009). Public trust, the law, and financial investment. *Journal of Financial Economics, 92*(3), 321–341.

Coleman, J. S. (1988). Social capital in the creation of human capital. *American Journal of Sociology, 94*(Supplement), S95–S120.

Coleman, J. S. (1990). *Foundations of social theory.* Harvard University Press.

Cook, N., Bartos, F., Bom, P. R. D., Gechert, S., Kantova, K., Geyer-Klingeberg, J., Havranek, T., Irsova, Z., Luskova, M., Opatrny, M., Prante, F., Rachinger, H. J., & Stanley, T. D. (2026a). Guidance for the use of AI in the meta-analysis of economics research. *Journal of Economic Surveys.*

Cook, N., Bartos, F., Bom, P. R. D., Gechert, S., Kantova, K., Geyer-Klingeberg, J., Havranek, T., Irsova, Z., Luskova, M., Opatrny, M., Prante, F., Rachinger, H. J., & Stanley, T. D. (2026b). Reporting guidelines for meta-analysis in economics---updated for AI. *Journal of Economic Surveys.*

Cruz-García, P., & Peiró-Palomino, J. (2019). Informal, formal institutions and credit: Complements or substitutes? *Journal of Institutional Economics, 15*(4), 649–671.

Delhey, J., Newton, K., & Welzel, C. (2011). How general is trust in 'most people'? Solving the radius of trust problem. *American Sociological Review, 76*(5), 786–807.

Demirgüç-Kunt, A., & Maksimovic, V. (1998). Law, finance, and firm growth. *The Journal of Finance, 53*(6), 2107–2137.

Demirgüç-Kunt, A., & Maksimovic, V. (2002). Funding growth in bank-based and market-based financial systems: Evidence from firm-level data. *Journal of Financial Economics, 65*(3), 337–363.

Dichev, I. D. (1998). Is the risk of bankruptcy a systematic risk? *The Journal of Finance, 53*(3), 1131–1147.

Djankov, S., La Porta, R., Lopez-de-Silanes, F., & Shleifer, A. (2003). Courts: The Lex Mundi project. *Quarterly Journal of Economics, 118*(2), 453–517.

Djankov, S., La Porta, R., Lopez-de-Silanes, F., & Shleifer, A. (2008). The law and economics of self-dealing. *Journal of Financial Economics, 88*(3), 430–465.

Doidge, C., Karolyi, G. A., & Stulz, R. M. (2007). Why do countries matter so much for corporate governance? *Journal of Financial Economics, 86*(1), 1–39.

Eicher, T. S., Papageorgiou, C., & Raftery, A. E. (2011). Default priors and predictive performance in Bayesian model averaging, with application to growth determinants. *Journal of Applied Econometrics, 26*(1), 30–55.

EVS. (2022). *EVS trend file 1981–2017* [ZA7503 Data file Version 3.0.0]. Cologne, GESIS Data Archive.

Fama, E. F., & French, K. R. (1992). The cross-section of expected stock returns. *The Journal of Finance, 47*(2), 427–465.

Fama, E. F., & French, K. R. (1993). Common risk factors in the returns on stocks and bonds. *Journal of Financial Economics, 33*(1), 3–56.

Fama, E. F., & French, K. R. (2008). Dissecting anomalies. *The Journal of Finance, 63*(4), 1653–1678.

Fama, E. F., & French, K. R. (2012). Size, value, and momentum in international stock returns. *Journal of Financial Economics, 105*(3), 457–472.

Fama, E. F., & French, K. R. (2015). A five-factor asset pricing model. *Journal of Financial Economics, 116*(1), 1–22.

Fama, E. F., & French, K. R. (2017). International tests of a five-factor asset pricing model. *Journal of Financial Economics, 123*(3), 441–463.

Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. *Journal of Political Economy, 81*(3), 607–636.

Fukuyama, F. (1995). *Trust: The social virtues and the creation of prosperity.* Free Press.

Gao, F., Wu, J. S., & Zimmerman, J. (2009). Unintended consequences of granting small firms exemptions from securities regulation: Evidence from the Sarbanes-Oxley Act. *Journal of Accounting Research, 47*(2), 459–506.

Georgarakos, D., & Pasini, G. (2011). Trust, sociability, and stock market participation. *Review of Finance, 15*(4), 693–725.

Greif, A. (1994). Cultural beliefs and the organization of society: A historical and theoretical reflection on collectivist and individualist societies. *Journal of Political Economy, 102*(5), 912–950.

Guiso, L., Sapienza, P., & Zingales, L. (2004). The role of social capital in financial development. *American Economic Review, 94*(3), 526–556.

Guiso, L., Sapienza, P., & Zingales, L. (2008). Trusting the stock market. *The Journal of Finance, 63*(6), 2557–2600.

Guiso, L., Sapienza, P., & Zingales, L. (2009). Cultural biases in economic exchange? *Quarterly Journal of Economics, 124*(3), 1095–1131.

Gupta, A., Raman, K., & Shang, C. (2018). Social capital and the cost of equity. *Journal of Banking & Finance, 87*, 102–117.

Hadlock, C. J., & Pierce, J. R. (2010). New evidence on measuring financial constraints: Moving beyond the KZ Index. *Review of Financial Studies, 23*(5), 1909–1940.

Haerpfer, C., Inglehart, R., Moreno, A., Welzel, C., Kizilova, K., Diez-Medrano, J., Lagos, M., Norris, P., Ponarin, E., Puranen, B., et al. (Eds.). (2022). *World Values Survey trend file (1981–2022) cross-national data-set* [Version 4.0.0]. Madrid, Spain, Vienna, Austria, JD Systems Institute; WVSA Secretariat.

Hail, L., & Leuz, C. (2006). International differences in the cost of equity capital: Do legal institutions and securities regulation matter? *Journal of Accounting Research, 44*(3), 485–531.

Hail, L., & Leuz, C. (2009). Cost of capital effects and changes in growth expectations around U.S. cross-listings. *Journal of Financial Economics, 93*(3), 428–454.

Harvey, C. R., Liu, Y., & Zhu, H. (2016). ...and the cross-section of expected returns. *Review of Financial Studies, 29*(1), 5–68.

Hasan, I., Hoi, C. K. S., Wu, Q., & Zhang, H. (2017). Social capital and debt contracting: Evidence from bank loans and public bonds. *Journal of Financial and Quantitative Analysis, 52*(3), 1017–1047.

Himmelberg, C. P., Hubbard, R. G., & Love, I. (2002). *Investor protection, ownership, and the cost of capital* (Policy Research Working Paper No. 2834). World Bank.

Hou, K., Karolyi, G. A., & Kho, B.-C. (2011). What factors drive global stock returns? *The Review of Financial Studies, 24*(8), 2527–2574.

Hou, K., & van Dijk, M. A. (2019). Resurrecting the size effect: Firm size, profitability shocks, and expected stock returns. *The Review of Financial Studies, 32*(7), 2850–2889.

Hou, K., Xue, C., & Zhang, L. (2020). Replicating anomalies. *The Review of Financial Studies, 33*(5), 2019–2133.

Iliev, P. (2010). The effect of SOX Section 404: Costs, earnings quality, and stock prices. *The Journal of Finance, 65*(3), 1163–1196.

Irsova, Z., Doucouliagos, H., Havranek, T., & Stanley, T. D. (2024). Meta-analysis of social science research: A practitioner's guide. *Journal of Economic Surveys, 38*(5), 1547–1566.

Jegadeesh, N., & Titman, S. (1993). Returns to buying winners and selling losers: Implications for stock market efficiency. *The Journal of Finance, 48*(1), 65–91.

Jha, S., Shayo, M., & Weiss, C. M. (2025). Financial market exposure increases generalized trust. *Journal of Public Economics, 242*, 105303.

Kaufmann, D., & Kraay, A. C. (2024). *The Worldwide Governance Indicators: Methodology and 2024 update* (Policy Research Working Paper No. 10952). World Bank Group. Washington, DC.

Keim, D. B. (1983). Size-related anomalies and stock return seasonality. *Journal of Financial Economics, 12*(1), 13–32.

Knack, S., & Keefer, P. (1997). Does social capital have an economic payoff? A cross-country investigation. *The Quarterly Journal of Economics, 112*(4), 1251–1288.

Knez, P. J., & Ready, M. J. (1997). On the robustness of size and book-to-market in cross-sectional regressions. *The Journal of Finance, 52*(4), 1355–1382.

La Porta, R., Lopez-de-Silanes, F., & Shleifer, A. (1999). Corporate ownership around the world. *The Journal of Finance, 54*(2), 471–517.

La Porta, R., Lopez-de-Silanes, F., & Shleifer, A. (2006). What works in securities laws? *The Journal of Finance, 61*(1), 1–32.

La Porta, R., Lopez-de-Silanes, F., & Shleifer, A. (2008). The economic consequences of legal origins. *Journal of Economic Literature, 46*(2), 285–332.

La Porta, R., Lopez-de-Silanes, F., Shleifer, A., & Vishny, R. W. (1997a). Legal determinants of external finance. *The Journal of Finance, 52*(3), 1131–1150.

La Porta, R., Lopez-de-Silanes, F., Shleifer, A., & Vishny, R. W. (1997b). Trust in large organizations. *American Economic Review Papers and Proceedings, 87*(2), 333–338.

La Porta, R., Lopez-de-Silanes, F., Shleifer, A., & Vishny, R. W. (1998). Law and finance. *Journal of Political Economy, 106*(6), 1113–1155.

La Porta, R., Lopez-de-Silanes, F., Shleifer, A., & Vishny, R. W. (2000). Investor protection and corporate governance. *Journal of Financial Economics, 58*(1–2), 3–27.

La Porta, R., Lopez-de-Silanes, F., Shleifer, A., & Vishny, R. W. (2002). Investor protection and corporate valuation. *The Journal of Finance, 57*(3), 1147–1170.

Leuz, C. (2007). Was the Sarbanes-Oxley Act of 2002 really this costly? A discussion of evidence from event returns and going-private decisions. *Journal of Accounting and Economics, 44*(1–2), 146–165.

Leuz, C., Nanda, D., & Wysocki, P. D. (2003). Earnings management and investor protection: An international comparison. *Journal of Financial Economics, 69*(3), 505–527.

Levine, R. (2005). Finance and growth: Theory and evidence. In *Handbook of economic growth* (pp. 865–934, Vol. 1A). Elsevier.

Li, X., Wang, S. S., & Wang, X. (2019). Trust and IPO underpricing. *Journal of Corporate Finance, 56*, 224–248.

Lins, K. V., Servaes, H., & Tamayo, A. (2017). Social capital, trust, and firm performance: The value of corporate social responsibility during the financial crisis. *The Journal of Finance, 72*(4), 1785–1824.

Lintner, J. (1965). The valuation of risk assets and the selection of risky investments in stock portfolios and capital budgets. *Review of Economics and Statistics, 47*(1), 13–37.

Lo, A. W., & MacKinlay, A. C. (1990). Data-snooping biases in tests of financial asset pricing models. *The Review of Financial Studies, 3*(3), 431–467.

Love, I. (2003). Financial development and financing constraints: International evidence from the structural investment model. *Review of Financial Studies, 16*(3), 765–791.

Mishra, A. V., Sharma, G., & Sehgal, S. (2022). Does financial integration impact performance of equity anomalies? *Cogent Economics & Finance, 10*(1), 2111802.

North, D. C. (1990). *Institutions, institutional change and economic performance.* Cambridge University Press.

Pevzner, M., Xie, F., & Xin, X. (2015). When firms talk, do investors listen? The role of trust in stock market reactions to corporate earnings announcements. *Journal of Financial Economics, 117*(1), 190–223.

Putnam, R. D. (1993). *Making democracy work: Civic traditions in modern Italy.* Princeton University Press.

Putnam, R. D. (2000). *Bowling alone: The collapse and revival of American community.* Simon & Schuster.

Raftery, A. E., Madigan, D., & Hoeting, J. A. (1997). Bayesian model averaging for linear regression models. *Journal of the American Statistical Association, 92*(437), 179–191.

Reeskens, T., & Hooghe, M. (2008). Cross-cultural measurement equivalence of generalized trust. Evidence from the European Social Survey (2002 and 2004). *Social Indicators Research, 85*(3), 515–532.

Reinganum, M. R. (1981). Misspecification of capital asset pricing: Empirical anomalies based on earnings yields and market values. *Journal of Financial Economics, 9*(1), 19–46.

Roll, R. (1981). A possible explanation of the small firm effect. *The Journal of Finance, 36*(4), 879–888.

Schwert, G. W. (2003). Anomalies and market efficiency. In G. M. Constantinides, M. Harris, & R. M. Stulz (Eds.), *Handbook of the economics of finance* (pp. 939–974, Vol. 1B). Elsevier.

Sharpe, W. F. (1964). Capital asset prices: A theory of market equilibrium under conditions of risk. *The Journal of Finance, 19*(3), 425–442.

Stanley, T. D. (2005). Beyond publication bias. *Journal of Economic Surveys, 19*(3), 309–345.

Stanley, T. D. (2008). Meta-regression methods for detecting and estimating empirical effects in the presence of publication selection. *Oxford Bulletin of Economics and Statistics, 70*(1), 103–127.

Stulz, R. M. (1999). Globalization, corporate finance, and the cost of capital. *Journal of Applied Corporate Finance, 12*(3), 8–25.

Stulz, R. M. (2005). The limits of financial globalization. *The Journal of Finance, 60*(4), 1595–1638.

Tabellini, G. (2010). Culture and institutions: Economic development in the regions of Europe. *Journal of the European Economic Association, 8*(4), 677–716.

Uslaner, E. M. (2002). *The moral foundations of trust.* Cambridge University Press.

van Dijk, M. A. (2011). Is size dead? A review of the size effect in equity returns. *Journal of Banking & Finance, 35*(12), 3263–3274.

Williamson, O. E. (1993). Calculativeness, trust, and economic organization. *The Journal of Law and Economics, 36*(1, Part 2), 453–486.

World Bank. (2025a). *Worldwide Governance Indicators, 2025 revision.*

World Bank. (2025b). *The Worldwide Governance Indicators: Revised methodology for measuring governance using perception data.* World Bank Group. Washington, DC.

Zeugner, S., & Feldkircher, M. (2015). Bayesian model averaging employing fixed and flexible priors: The BMS package for R. *Journal of Statistical Software, 68*(4), 1–37.
