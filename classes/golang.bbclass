
def get_package_name(d):
    from subprocess import Popen
    import subprocess
    proc = Popen(['go', 'list', '-f', '{{.ImportPath}}', d], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=go_env)
    out, err = proc.communicate()
    if proc.returncode != 0:
        return None
    else:
        return out.strip()

def get_packages(p):
    packages = []
    for root, dirs, files in os.walk(p):
        for dirn in dirs:
            '''Determine if package'''
            b = root[len(p)+1:]
            pkg_name = get_package_name(b+os.sep+dirn)
            if pkg_name:
                packages.append(pkg_name)
    return packages

python do_configure () {
    global go_env
    go_env = os.environ.copy()
    go_env["GOPATH"] = d.getVar("WORKDIR", True)
    pkgs = get_packages(d.getVar("S", True))
    print pkgs
}

do_compile () {
    echo "compiling"
}

do_install () {
    echo "installing"
}
