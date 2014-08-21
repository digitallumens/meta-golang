inherit golang

GO_PACKAGE_NAME = "github.com/digitallumens/goexamplepackage"

LICENSE="MIT"
LIC_FILES_CHKSUM = "file://${GO_PACKAGE_NAME}/LICENSE;md5=c53db1f34890af744e26b779a2dea6fb"

SRC_URI = "git://github.com/digitallumens/goexamplepackage.git;protocol=git;destsuffix=src/${GO_PACKAGE_NAME}"
SRCREV = "862e985df07eb4703b9a972019d3ebc17a345748"

S := "${WORKDIR}/src"

