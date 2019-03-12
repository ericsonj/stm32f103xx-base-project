## PROJECT INFO
PROJECT=miniblink
PROJECTS_DIR=examples

## PROJECT SETTINGS
VERBOSE=n
FREERTOS=n

## MAKEFILE
DEF=PROJECT=$(PROJECT) PROJECTS_DIR=$(PROJECTS_DIR) VERBOSE=$(VERBOSE)

ifeq ($(VERBOSE),y)
	S=
else
	S=-s
endif

all:
	@$(MAKE) $(S) -C ../../ all $(DEF)

%:
	@$(MAKE) $(S) -C ../../ $@ $(DEF)
