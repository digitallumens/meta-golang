DESCRIPTION = "Go Programming Language Cross Compiler."
HOMEPAGE = "golang.org"
SRC_URI = "http://golang.org/dl/go${PV}.src.tar.gz"
SRC_URI = "https://storage.googleapis.com/golang/go${PV}.src.tar.gz"

inherit native
S="${WORKDIR}/go"

do_compile () {
        export GOROOT_BOOTSTRAP=`go env | grep GOROOT | cut -c 9-`
	export GOROOT_BOOTSTRAP="${GOROOT_BOOTSTRAP%\"}"
	export GOROOT_FINAL="${libdir}/go"
	export CGO_ENABLED="0"
	cd src
	./make.bash
}

do_install () {
	# Install the executables into build system
	#echo "${D}${bindir}"
	mkdir -p ${D}${bindir}
	cp -a bin/go ${D}${bindir}/
	mkdir -p ${D}${libdir}/go
	cp -a pkg ${D}${libdir}/go/
	cp -a src ${D}${libdir}/go/
	mkdir ${D}${libdir}/go/bin
	ln -s ../../../bin/go ${D}${libdir}/go/bin/go
}
