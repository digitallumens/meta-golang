DESCRIPTION = "Go Programming Language Packages."
HOMEPAGE = "golang.org"
DEPENDS = "golang-native"
PROVIDES = "virtual/${TARGET_PREFIX}golang"
SRC_URI = "http://golang.org/dl/go${PV}.src.tar.gz"
SRC_URI = "https://storage.googleapis.com/golang/go${PV}.src.tar.gz"

S="${WORKDIR}/go"

# Go uses a funny GOROOT approach, so to prepare for cross compiling,
# we just pre-emptively rebuild the standard library
do_compile () {
	export GOARCH="${TARGET_ARCH}"
	if [ "${TARGET_ARCH}" = "arm" ]
	then
		if [ `echo ${TUNE_PKGARCH} | cut -c 1-7` = "cortexa" ]
		then
			export GOARM="7"
		fi
	fi
	export GOOS="linux"
	export CC="${TARGET_SYS}-gcc"
	export CGO_CFLAGS="--sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	export CXX="${TARGET_SYS}-gxx"
	export CGO_CXXFLAGS="--sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	export CGO_LDFLAGS="--sysroot=${STAGING_DIR_TARGET} ${TARGET_CC_ARCH}"
	export CGO_ENABLED="1"
	go install std
}

do_install () {
}
