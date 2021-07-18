################################################################################
# Variables
################################################################################

DATETIME		:= $(shell date +"%Y%m%d_%H%M%S")
SELF_DIR    := $(dir $(lastword $(MAKEFILE_LIST)))
SHELL 			:= /bin/bash
# SHELL				:= $(SELF_DIR)/shell_wrapper.sh

# # Virtual Env dir
# VENV_DIR := $(MY_DIR)/.venv3
#
# # Ansible Dirs
# ANS_BASE := $(MY_DIR)/ansible
# ANS_DIR := $(ANS_BASE)/common
# PLAYS_DIR := $(ANS_BASE)/playbooks
#
# # Data Dirs
# DATA_DIR := $(MY_DIR)/data
#
# # Terraform Dir
# TF_DIR := $(MY_DIR)/terraform
#
# # Scripts Dir
# SCRIPTS_DIR := $(MY_DIR)/scripts
#
# # ANSIBLE_DEBUGGING := "-vvvv"
# ANSIBLE_DEBUGGING :=

PURPLE	:= $(shell tput setaf 129)
GRAY		:= $(shell tput setaf 245)
GREEN		:= $(shell tput setaf 34)
BLUE		:= $(shell tput setaf 25)
YELLOW	:= $(shell tput setaf 3)
WHITE		:= $(shell tput setaf 7)
RESET		:= $(shell tput sgr0)
export

################################################################################
# Macros / Methods
################################################################################

# check for executables in $PATH
REQUIRED_EXECUTABLES := ssh python3 gpg git-secret
K := $(foreach exec,$(REQUIRED_EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "Program $(exec) not in PATH")))

################################################################################
# Makefile TARGETS
################################################################################

.DEFAULT_GOAL := help

#
# Help
#
# based to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help list
help: ## This help
	@echo "${PURPLE}"
	@echo "  __  __       _    _____       _                                  "
	@echo " |  \/  | __ _| | _| ____|_ __ | |__   __ _ _ __   ___ ___ _ __    "
	@echo " | |\/| |/ _\` | |/ /  _| | '_ \| '_ \ / _\` | '_ \ / __/ _ \ '__| "
	@echo " | |  | | (_| |   <| |___| | | | | | | (_| | | | | (_|  __/ |      "
	@echo " |_|  |_|\__,_|_|\_\_____|_| |_|_| |_|\__,_|_| |_|\___\___|_|      "
	@echo ""
	@echo "                         ${BLUE} B > \frac{1}{n} \sum_{i=1}^{n} x_i"
	@echo "${RESET}"
	@echo "Usage: ${YELLOW}make${RESET} ${GREEN}<target(s)>${RESET}"
	@echo ""
	@echo "Targets:"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

list: ## list all Makefile targets
	@make -qp | grep -E '^[[:alnum:]_]+' | grep -Ev ' :?= ' | grep -E ':' | cut -d ':' -f 1 | sort | uniq

#
# Check ENV vars
#
.PHONY: check_env_%
check_env_%: ## check Environment Variable
	@ if [ "${${*}}" = "" ]; then \
			echo "Environment variable $* not set (make $*=.. target or export $*=.."; \
			exit 1; \
	fi

#
# virtual env tasks
#
.PHONY: venv venv_mkdir venv_remove check_venv
venv: check_env_VENV_DIR venv_mkdir ## install python dependencies
	@test -d $(VENV_DIR) && $(VENV_DIR)/bin/pip install --upgrade pip
	@test -d $(VENV_DIR) && $(VENV_DIR)/bin/pip install "ansible>=2.10,<2.11" "j2cli[yaml]" "pre-commit"

venv_mkdir: check_env_VENV_DIR venv_remove ## create new venv dir
	@test -d $(VENV_DIR) || python3 -m venv $(VENV_DIR)

venv_remove: check_env_VENV_DIR ## remove venv dir
	@-test -d $(VENV_DIR) && rm -rf $(VENV_DIR)

check_venv: ## check venv
	@test -d $(VENV_DIR) || $(MAKE) venv


#
# de-/encrypting
#
.PHONY: decrypt_all_files encrypt_all_files
decrypt_all_files: ## decrypt all files
	@git-secret reveal -f

encrypt_all_files: ## (re-)encrypt all files
	@git-secret hide -m -d
