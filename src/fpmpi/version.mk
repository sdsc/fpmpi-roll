ifndef ROLLCOMPILER
  ROLLCOMPILER = gnu
endif
COMPILERNAME := $(firstword $(subst /, ,$(ROLLCOMPILER)))

ifndef ROLLMPI
  ROLLMPI = openmpi
endif
MPINAME := $(firstword $(subst /, ,$(ROLLMPI)))

NAME           = fpmpi_$(COMPILERNAME)_$(MPINAME)
VERSION        = 2.3
RELEASE        = 3
# Installed in MPI directory
PKGROOT        = /

SRC_SUBDIR     = fpmpi

SOURCE_NAME    = fpmpi
SOURCE_SUFFIX  = tar.gz
SOURCE_VERSION = $(VERSION)
SOURCE_PKG     = $(SOURCE_NAME)-$(SOURCE_VERSION).$(SOURCE_SUFFIX)
SOURCE_DIR     = $(SOURCE_PKG:%.$(SOURCE_SUFFIX)=%)

TAR_GZ_PKGS    = $(SOURCE_PKG)

RPM.EXTRAS     = AutoReq:No
