inherit gccgo

GO_PACKAGE_NAME = "github.com/digitallumens/goexamplepackage"

LICENSE="MIT"
LIC_FILES_CHKSUM = "file://${GO_PACKAGE_NAME}/LICENSE;md5=c53db1f34890af744e26b779a2dea6fb"

SRC_URI = "git://github.com/digitallumens/goexamplepackage.git;protocol=git;destsuffix=src/${GO_PACKAGE_NAME}"
SRCREV = "e562aa5a3fe4f9449b64833b914b70f77252a19e"

S := "${WORKDIR}/src"

GO_LIB_NAME = "${PN}"
GO_EXEC_NAME = "goexample"
