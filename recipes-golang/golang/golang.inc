DESCRIPTION = "Go Programming Language Packages."
HOMEPAGE = "golang.org"
DEPENDS = "golang-native"
PROVIDES = "virtual/${TARGET_PREFIX}golang"
SRC_URI = "http://golang.org/dl/go${PV}.src.tar.gz"
SRC_URI = "https://storage.googleapis.com/golang/go${PV}.src.tar.gz"

S="${WORKDIR}/go"
INHIBIT_PACKAGE_STRIP = "1"

do_compile () {
        export GOROOT_BOOTSTRAP="${STAGING_LIBDIR_NATIVE}/go"
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
	export CGO_ENABLED="0"
	cd src
	./make.bash
	echo "Compiling CGO crap"	
	export CC="${TARGET_SYS}-gcc"
	export CGO_CFLAGS="--sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	export CXX="${TARGET_SYS}-gxx"
	export CGO_CXXFLAGS="--sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	export CGO_LDFLAGS="--sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	export CGO_ENABLED="1"
	export GOROOT="${S}"
	${S}/bin/go install std
}

do_install () {
	# Install the compiled arm libraries
	mkdir -p ${D}${libdir}/go/pkg
	cp -a ${S}/pkg/linux_${TARGET_ARCH} ${D}${libdir}/go/
}

FILES_${PN}-staticdev = "${libdir}/go"