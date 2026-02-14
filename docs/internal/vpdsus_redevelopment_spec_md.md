# vpdsus: Full Redevelopment Specification
Authoritative redevelopment roadmap

This document supersedes the current repository state and integrates:

- The detailed critique notes on current shortcomings
- The intended stepped pedagogical and mechanistic design described in prior discussion

Date: 13 February 2026
Status: Binding redevelopment specification

---

# 1. Executive Summary

The current `vpdsus` repository contains useful scaffolding but does not meet the intended specification.

Critical deficiencies:

- Mechanistic modelling is not truly implemented (bookkeeping is not a transmission model)
- odin2 and dust2 are not treated as core Imports
- Vignettes are too brief and non-explanatory
- No complete end-to-end analysis artefact
- README reads like internal development notes
- targets example behaves like a test, not a research workflow

This document defines the required end-state and strict milestone roadmap.

---

# 2. Non-Negotiable Architectural Principles

## 2.1 Mechanistic modelling is core

- odin2, dust2, and required inference tools must be in:
  - Imports
  - Remotes (or Additional_repositories)
- No conditional availability logic
- CI must install and compile models automatically

## 2.2 Two-layer structure

Layer 1: Deterministic package layer (offline-friendly)  
Layer 2: Live analysis layer (analysis/ + targets/)

Vignettes must run offline.  
Live WHO/WPP downloads belong in analysis/.

## 2.3 Fully stepped workflow

Every stage must connect cleanly:

Data → Panel → Susceptibility → Ranking → Modelling → Mechanistic inference

---

# 3. Required End-State Workflows

## Workflow A: WHO-Style Risk Scanning

1. Indicator discovery
2. Coverage retrieval
3. Case retrieval
4. Demography retrieval (WPP)
5. Harmonised panel construction
6. Susceptibility estimation (multiple methods)
7. WHO-style multi-panel ranking figure

Deliverables:
- Dedicated vignette
- Example dataset
- Composite dashboard figure

---


## Workflow B: Susceptibility to Outbreak Modelling

1. Construct modelling panel
2. Define outbreak outcome(s)
3. Fit multiple models (logistic and negative binomial minimum)
4. Rolling-origin validation
5. Calibration and ROC plots

Deliverables:
- Full vignette
- Tidy model outputs
- Evaluation plots

---


## Workflow C: Mechanistic Susceptibility Inference

1. Map panel to SIRV inputs
2. Run odin2 model (annual timestep initially)
3. Calibrate reporting fraction rho
4. Optional calibration of beta
5. Infer susceptibility trajectory
6. Compare against simpler methods

Deliverables:
- Fully functional SIRV odin2 template
- Calibration routine
- Vignette with complete worked example

---

# 4. Mechanistic Model Specification (Mandatory)

Minimum required model:

Annual SIRV with:

Compartments:
- S
- I
- R
- V

Flows:
- Births → S
- Vaccination → V
- Infection S → I
- Recovery I → R
- Mortality in all compartments
- Reporting fraction rho

Must output:
- Reported cases
- Susceptible counts
- Susceptible proportion

Bookkeeping recurrences alone are not sufficient.

Optional extension:
- Two-age-group version (0–4, 5+)
- Ageing flows
- Age-specific vaccination

---

# 5. Repository Layout (Required)

vpdsus/
  R/
  inst/
    extdata/
    odin/
  vignettes/
  analysis/
    targets/
    reports/
  tests/
  .github/

Example panel must:
- Derive from real WHO and WPP data
- Include provenance
- Be reproducible via script

---

# 6. API Blueprint (Final Form)

Data access:
- gho_find_indicator()
- get_coverage()
- get_cases()
- get_country_metadata()

Demography:
- get_demography()
- summarise_age_groups()

Panel:
- build_panel_from_sources()
- panel_validate()

Susceptibility:
- estimate_susceptible_static()
- estimate_susceptible_cohort()
- estimate_susceptible_case_balance()
- estimate_susceptible_mechanistic()
- estimate_susceptible()

Ranking and plots:
- risk_rank()
- plot_coverage_rank_by_region()
- plot_susceptible_stack_by_age()
- plot_who_style_dashboard()

Outbreak modelling:
- make_modelling_panel()
- fit_outbreak_models()
- evaluate_models()

Mechanistic:
- odin2_prepare_inputs()
- odin2_simulate()
- fit_mechanistic_model()
- infer_susceptibility_mechanistic()

---

# 7. Vignette Standards

Each vignette must:

- Explain purpose clearly
- Describe equations in plain language
- Explain assumptions explicitly
- Print intermediate tables
- Interpret outputs

Minimum standard: substantial tutorial, not a short code snippet.

---

# 8. Milestone Roadmap

M0 – Repository reset  
M1 – Data access finalised  
M2 – Real demography backend  
M3 – One-line panel builder  
M4 – Susceptibility suite polished  
M5 – WHO-style composite outputs  
M6 – Outbreak modelling with evaluation  
M7 – Proper SIRV odin2 implementation  
M8 – Public release with full live-data report  

Each milestone must pass CI.

---

# 9. Definition of Done

The package is complete when:

- Fresh GitHub install succeeds
- Vignettes run fully offline
- WHO-style dashboard reproduced
- Outbreak models evaluated with rolling validation
- Mechanistic inference runs without conditional logic
- targets pipeline regenerates full report

No manual editing required.

---

End of specification.
