DEPENDS += "golang"
INHIBIT_PACKAGE_STRIP = "1"

S="${WORKDIR}"
GO_PACKAGES = ""

#Compile & Install
def install(pkgs, go_env):
    import subprocess
    go = go_env["GO"]
    subprocess.check_call([go, 'install', '-v', '-x']+pkgs, stdout=sys.stdout, stderr=sys.stderr, env=go_env)

#Get the package name for a directory
def get_package_name(d,go_env):
    from subprocess import Popen
    import subprocess
    go = go_env["GO"]
    proc = Popen([go, 'list', '-f', '{{.ImportPath}}', d], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=go_env)
    out, err = proc.communicate()
    if proc.returncode != 0:
        #print "out: "+out
        #print "err: "+err
        return None
    else:
        return out.strip()

#Determine what go packages are here
def get_packages(p,go_env):
    packages = []
    for root, dirs, files in os.walk(p):
        for dirn in dirs:
            '''Determine if package'''
            b = root[len(p)+1:]
            pkg_name = get_package_name(b+os.sep+dirn,go_env)
            if pkg_name:
                packages.append(pkg_name)
            #print "%s = %s" % (b+os.sep+dirn, pkg_name)
    return packages

do_configure() {
    echo "Nothing to do"
}

python do_compile() {
    sysroot_target = d.getVar("STAGING_DIR_TARGET", True)
    sysroot_native = d.getVar("STAGING_DIR_NATIVE", True)
    target_cc_arch = d.getVar("TARGET_CC_ARCH", True)
    go_env = os.environ.copy()
    go_env["GO"] = sysroot_native+d.getVar("bindir",True)+"/go"
    print "go: "+go_env["GO"]
    go_env["GOROOT"] = sysroot_native+d.getVar("libdir",True)+"/go"
    go_env["GOPATH"] = d.getVar("WORKDIR",True)+":"+sysroot_target+d.getVar("libdir", True)+"/go"
    go_env["GOARCH"] = d.getVar("TARGET_ARCH",True)
    if d.getVar("TARGET_ARCH",True) == "arm":
        if d.getVar("TUNE_PKGARCH", True).startswith("coretexa"):
            go_env["GOARM"] = "7"
    #export GOOS="linux"
    go_env["GOOS"] = "linux"
    go_env["CC"] = d.getVar("TARGET_SYS", True)+"-gcc"
    go_env["CGO_CFLAGS"] = "--sysroot="+sysroot_target+" "+target_cc_arch
    go_env["CXX"] = d.getVar("TARGET_SYS", True)+"-gxx"
    go_env["CGO_CXXFLAGS"] = "--sysroot="+sysroot_target+" "+target_cc_arch
    go_env["CGO_LDFLAGS"] = "--sysroot="+sysroot_target+" "+target_cc_arch
    go_env["CGO_ENABLED"] = "1"

    pkgs = d.getVar("GO_PACKAGES", True).split()

    if len(pkgs)==0:
        pkgs = get_packages(d.getVar("S",True), go_env)

    install(pkgs, go_env)
}

do_install() {
    if [ -d ${WORKDIR}/bin ] ; then
        mkdir -p ${D}${bindir}
        cp -a ${WORKDIR}/bin/* ${D}${bindir}
    fi
    mkdir -p ${D}${libdir}/go
    mkdir -p ${D}${libdir}/go/src
    cd ${WORKDIR}/src
    find . -regex '.*\(go\|h\|c\)$' -exec cp --parents \{\} ${D}${libdir}/go/src/ \;
    cp -r ${WORKDIR}/pkg ${D}${libdir}/go/
}

FILES_${PN}-staticdev = "${libdir}/go"
