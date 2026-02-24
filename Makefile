.PHONY: test check site reproduce first-project as-cran update-odin conflict-analysis conflict-all

test:
	R -q -e "devtools::test()"

check:
	R CMD build .
	R CMD check --no-manual vpdsus_*.tar.gz

site:
	XDG_CACHE_HOME=/tmp R -q -e "pkgdown::build_site(new_process = FALSE)"

reproduce:
	Rscript scripts/reproduce_analysis.R

first-project:
	Rscript scripts/first_project_demo.R

as-cran:
	R CMD build .
	R CMD check --as-cran --no-manual vpdsus_*.tar.gz

update-odin:
	Rscript scripts/update_odin_models.R

conflict-analysis:
	Rscript analysis/conflict/run_conflict_analysis.R

conflict-all: conflict-analysis
