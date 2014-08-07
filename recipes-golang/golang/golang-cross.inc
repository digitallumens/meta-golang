DESCRIPTION = "Go Programming Language Cross Compiler."
HOMEPAGE = "golang.org"
DEPENDS = "virtual/${TARGET_PREFIX}gcc"
PROVIDES = "virtual/${TARGET_PREFIX}go"

do_install () {
	# Install the executables into build system
	mkdir -p ${D}${bindir}
	cp -a bin/go ${D}${bindir}/
	mkdir -p ${D}${libdir}/go
	cp -a pkg ${D}${libdir}/go/
	cp -a include ${D}${libdir}/go/
	cp -a api ${D}${libdir}/go/
}
