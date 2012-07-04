BUNDLE=`which bundle`

#
# Targets
#

.PHONY: deps doc

all: deps

deps:
	$(BUNDLE) install

doc:
	$(BUNDLE) exec rake yard

