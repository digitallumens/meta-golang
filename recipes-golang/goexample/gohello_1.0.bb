inherit golang

GO_PACKAGE_NAME = "github.com/digitallumens/gohello"

LICENSE="MIT"
LIC_FILES_CHKSUM = "file://${GO_PACKAGE_NAME}/LICENSE;md5=c53db1f34890af744e26b779a2dea6fb"

SRC_URI = "git://github.com/digitallumens/gohello.git;protocol=git;destsuffix=src/${GO_PACKAGE_NAME}"
SRCREV = "d2632da454ae7923e6ad03f6550a735307ba8828"

S := "${WORKDIR}/src"

GO_EXEC_NAME = "${PN}"
GO_LINKER = "-lgoexamplepackage"

DEPENDS = "goexamplepackage"
RDEPENDS_${PN} += "goexamplepackage"
