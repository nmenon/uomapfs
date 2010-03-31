#
# Make file for compiling uomapfs
#
# (C) Copyright 2010
# Texas Instruments, <www.ti.com>
# Nishanth Menon <nm@ti.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation version 2.
#
# This program is distributed .as is. WITHOUT ANY WARRANTY of any kind,
# whether express or implied; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA

# Handle verbose
ifeq ("$(origin V)", "command line")
  VERBOSE = $(V)
endif
ifndef VERBOSE
  VERBOSE = 0
endif
Q := $(if $(VERBOSE:1=),@)

# Our default directories
SCRIPT_DIR := scripts
CONFIG_DIR := configs

# Our standard scripts
MAKECONFIG := $(SCRIPT_DIR)/make.config

# Phony rules
.PHONY: all distclean clean

all:

%config:
	$(Q)$(MAKECONFIG) $(if $(VERBOSE:0=),-v) -d $(CONFIG_DIR) -c $@
