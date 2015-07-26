DESCRIPTION = "Go Programming Language Cross Compiler."
HOMEPAGE = "golang.org"
DEPENDS = "libgcc"
PROVIDES = "virtual/${TARGET_PREFIX}golang"
SRC_URI = "http://golang.org/dl/go${PV}.src.tar.gz"
S="${WORKDIR}/go"

do_compile () {
	export GOROOT_FINAL="${libdir}/go"
	export GOARCH="${TARGET_ARCH}"
	if [ "${TARGET_ARCH}" = "arm" ]
	then
		if [ `echo ${TUNE_PKGARCH} | cut -c 1-7` = "cortexa" ]
		then
			export GOARM="7"
		fi
	fi
	export GOOS="linux"
	export CGO_ENABLED="1"
	export CC="${BUILD_CC}"
	export CC_FOR_TARGET="${TARGET_SYS}-gcc --sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	export CXX_FOR_TARGET="${TARGET_SYS}-g++ --sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	cd src
	./make.bash
}

do_install () {
	# Install the executables into build system
	mkdir -p ${D}${bindir}
	cp -a bin/go ${D}${bindir}/
	mkdir -p ${D}${libdir}/go
	cp -a pkg ${D}${libdir}/go/
	cp -a include ${D}${libdir}/go/
	cp -a api ${D}${libdir}/go/
	cp -a src ${D}${libdir}/go/
}
