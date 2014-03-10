NAME               = fpmpi_$(ROLLCOMPILER)_$(ROLLMPI)_$(ROLLNETWORK)
VERSION            = 2.3
RELEASE            = 1
PKGROOT            = /opt/$(ROLLMPI)/$(ROLLCOMPILER)/$(ROLLNETWORK)
RPM.EXTRAS         = AutoReq:No

SRC_SUBDIR         = fpmpi

SOURCE_NAME        = fpmpi
SOURCE_VERSION     = $(VERSION)
SOURCE_SUFFIX      = tar.gz
SOURCE_PKG         = $(SOURCE_NAME)-$(SOURCE_VERSION).$(SOURCE_SUFFIX)
SOURCE_DIR         = $(SOURCE_PKG:%.$(SOURCE_SUFFIX)=%)

TAR_GZ_PKGS        = $(SOURCE_PKG)
