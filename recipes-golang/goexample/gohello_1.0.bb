inherit golang

GO_PACKAGE_NAME = "github.com/digitallumens/gohello"

LICENSE="MIT"
LIC_FILES_CHKSUM = "file://${GO_PACKAGE_NAME}/LICENSE;md5=c53db1f34890af744e26b779a2dea6fb"

SRC_URI = "git://github.com/digitallumens/gohello.git;protocol=git;destsuffix=src/${GO_PACKAGE_NAME}"
SRCREV = "056bfbc005a572daa62b4bf959f690e60bb96a5c"

S := "${WORKDIR}/src"

GO_EXEC_NAME = "${PN} gohello_pack"
GO_LINKER = "-lgoexamplepackage"

DEPENDS = "goexamplepackage"
RDEPENDS_${PN} += "goexamplepackage"
