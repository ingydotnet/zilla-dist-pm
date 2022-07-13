SHELL := bash

ZILD := \
    clean \
    cpan \
    cpanshell \
    dist \
    distdir \
    distshell \
    disttest \
    install \
    release \
    test \
    update \

DOCKER_IMAGE := alpine-test-yamlscript-perl

default:

.PHONY: test
$(ZILD):
	zild $@
