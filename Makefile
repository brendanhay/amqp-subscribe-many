BUNDLE=`which bundle`

#
# Targets
#

.PHONY: deps test doc

all: deps test

deps:
	$(BUNDLE) install

test:
	$(BUNDLE) exec rake test

doc:
	$(BUNDLE) exec rake yard

