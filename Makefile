.PHONY: clean conda lint requirements version

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME = $(notdir $(CURDIR))
MACRO_PROJECT_NAME = $(shell echo ${PROJECT_NAME} | cut -d . -f1)
PYTHON_VERSION = 3.8.11
SHELL=/bin/bash

ifeq (,$(shell which conda))
HAS_CONDA=False
else
HAS_CONDA=True
endif

requirements:
	pip install --upgrade pip
	pip install -U pip setuptools wheel
	pip install .'[dev,lint,test]'

install:
	pip install .

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "build" -exec rm -rf {} +
	find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	conda env remove -n $(PROJECT_NAME) -y

## Lint using flake8
lint:
	flake8 --count --config=setup.cfg

## Set up python interpreter environment
conda:
ifeq (True,$(HAS_CONDA))
	@echo ">>> Detected conda, creating conda environment."
	conda create --name $(PROJECT_NAME) python=$(PYTHON_VERSION) -y
	@echo -e ">>> New conda env created. Activate with:\nsource activate $(PROJECT_NAME)"
else
	@echo -e ">>> ERROR: Conda not found.\n"
endif

init:
ifeq (${input_file}, ${""})
	python -m image_search.app_init
else
	python -m image_search.app_init --input_file ${input_file}
endif

cli:
	python -m image_search.app_cli

web:
	python -m image_search.app_web

## Update project version ($increment=[major|minor|patch])
version:
ifeq ($(shell git branch | grep \* | cut -d ' ' -f2), main)
	python scripts/version_maker.py ${increment}
else
	@echo -e ">>> ERROR: no new version applied.\n"
endif


#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
