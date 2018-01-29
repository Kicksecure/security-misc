#!/usr/bin/make -f

## Copyright (C) 2012 - 2018 Patrick Schleizer <adrelanos@riseup.net>
## See the file COPYING for copying conditions.

## genmkfile - Makefile - version 1.5

## This is a copy.
## master location:
## https://github.com/Whonix/genmkfile/blob/master/usr/share/genmkfile/Makefile

GENMKFILE_PATH ?= /usr/share/genmkfile
GENMKFILE_ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

export GENMKFILE_PATH
export GENMKFILE_ROOT_DIR

include $(GENMKFILE_PATH)/makefile-full
