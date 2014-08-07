SRC_URI = "http://golang.org/dl/go${PV}.src.tar.gz"
S="${WORKDIR}/go"

do_compile () {
	export GOROOT_FINAL="/usr/lib/go"
	export GOARCH="${TARGET_ARCH}"
	if [ "${TARGET_ARCH}" = "arm" ]
	then
		if [ `echo ${TUNE_PKGARCH} | cut -c 1-7` = "cortexa" ]
		then
			echo GOARM 7
			export GOARM="7"
		fi
	fi
	export GOOS="linux"
	export GO_GCFLAGS=""
	export GO_LDFLAGS=""
	export GO_CCFLAGS=""
	export CGO_ENABLED="1"
	export CC_FOR_TARGET="${TARGET_SYS}-gcc"
	export CXX_FOR_TARGET="${TARGET_SYS}-g++"
	cd src
	echo CC_FOR_TARGET ${CC_FOR_TARGET}
	./make.bash
}
