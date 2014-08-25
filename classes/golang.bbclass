RDEPENDS_${PN} += "virtual/${TARGET_PREFIX}golibs"
DEPENDS += "virtual/${TARGET_PREFIX}golang virtual/${TARGET_PREFIX}golibs"

GO_LIB_VERSION = "${PV}"
python __anonymous () {
    d.setVar('GO_LIB_VERSION_MAJOR', d.getVar('GO_LIB_VERSION',True).split('.')[0])
}

B = "${WORKDIR}/build"

PARALLEL_MAKE = ""

GCCGO = "${TARGET_PREFIX}gccgo"
OBJCOPY = "${TARGET_PREFIX}objcopy"

#Makefile: the executable (statically linked with this library)
def make_go_static_exec_file(pkg_name, pkg, dest, lib_pkgs, linker_flags):
    deps = " %s%s.o" % (dest+os.sep, pkg_name)
    if len(pkg['CgoFiles'])>0:
        deps += " %s%slib%s_cgo.a" % (dest+os.sep, pkg_name+os.sep, pkg['Name'])
    if len(pkg['CFiles'])>0:
        deps += " %s%slib%s_c.a" % (dest+os.sep, pkg_name+os.sep, pkg['Name'])
    exe_name = pkg_name[pkg_name.rfind(os.sep)+1:]
    dep = "%sbin%s: %s" % (dest+os.sep, os.sep+exe_name, deps)
    cmd = "\t$(GCCGO) $(CFLAGS) $(LDFLAGS) "
    cmd += "-o $@ $^ "
    if linker_flags:
        cmd += "%s " % (linker_flags)
    #Add deps for supporting packages
    for lpkg_name, lpkg in lib_pkgs.iteritems():
        dep += " %s%s.o" % (dest+os.sep, lpkg_name)
        if len(lpkg['CgoFiles'])>0:
            dep += " %s%slib%s_cgo.a" % (dest+os.sep, lpkg_name+os.sep, lpkg['Name'])
        if len(lpkg['CFiles'])>0:
            dep += " %s%slib%s_c.a" % (dest+os.sep, lpkg_name+os.sep, lpkg['Name'])
    #create bin output directory
    depdir = dest+os.sep+"bin"
    cmddir = "\tmkdir -p "+depdir
    dep += " | %s" % depdir
    #Make install
    install = ".PHONY : install-bin-%s\n" % exe_name
    install += "install-bin-%s : %sbin%s\n" % (exe_name, dest+os.sep, os.sep+exe_name)
    install += "\tinstall -d $(BIN_DIR)\n"
    install += "\tinstall $< $(BIN_DIR)\n"
    return dep+"\n"+cmd+"\n"+depdir+" ::\n"+cmddir+"\n"+install

#Makefile: the executable (dyanmically linked)
def make_go_dynamic_exec_file(pkg_name, pkg, dest, soname, linker_flags):
    deps = " %s%s.o" % (dest+os.sep, pkg_name)
    if len(pkg['CgoFiles'])>0:
        deps += " %s%slib%s_cgo.a" % (dest+os.sep, pkg_name+os.sep, pkg['Name'])
    if len(pkg['CFiles'])>0:
        deps += " %s%slib%s_c.a" % (dest+os.sep, pkg_name+os.sep, pkg['Name'])
    exe_name = pkg_name[pkg_name.rfind(os.sep)+1:]
    dep = "%sbin%s: %s" % (dest+os.sep, os.sep+exe_name, deps)
    cmd = "\t$(GCCGO) $(CFLAGS) $(LDFLAGS) "
    cmd += "-o $@ $^"
    if soname:
        cmd += "-L%s -l%s " % (dest, soname)
    if linker_flags:
        cmd += "%s " % (linker_flags)
    #create bin output directory
    depdir = dest+os.sep+"bin"
    cmddir = "\tmkdir -p "+depdir
    dep += " | %s" % depdir
    #if depends on so
    if soname:
        dep += " %slib%s.so" % (dest+os.sep, soname)
    #Make install
    install = ".PHONY : install-bin-%s\n" % exe_name
    install += "install-bin-%s : %sbin%s\n" % (exe_name, dest+os.sep, os.sep+exe_name)
    install += "\tinstall -d $(BIN_DIR)\n"
    install += "\tinstall $< $(BIN_DIR)\n"
    return dep+"\n"+cmd+"\n"+depdir+" ::\n"+cmddir+"\n"+install

#Makefile: the package output object file
def make_lib_files(so_name, version, version_full, pkgs, dest):
    deps = ""
    go_exports = ""
    for pkg_name, pkg in pkgs.iteritems():
        deps += " %s%s.o" % (dest+os.sep, pkg_name)
        go_exports += " %s%s.gox" % (dest+os.sep, pkg_name)
        if len(pkg['CgoFiles'])>0:
            deps += " %s%slib%s_cgo.o" % (dest+os.sep, pkg_name+os.sep, pkg['Name'])
        if len(pkg['CFiles'])>0:
            deps += " %s%slib%s_c.o" % (dest+os.sep, pkg_name+os.sep, pkg['Name'])
    dep = "%slib%s.so.%s :%s |%s" % (dest+os.sep, so_name, version_full, deps, go_exports)
    cmd = "\t$(GCCGO) -shared -fPIC -Wl,-soname,lib%s.so.%s -o $@ $^" % (so_name, version)
    all_rules = dep+"\n"+cmd+"\n"
    #link to major version
    dep = "%slib%s.so.%s : %slib%s.so.%s" % (dest+os.sep, so_name, version, dest+os.sep, so_name, version_full)
    cmd = "\tcd %s && ln -sf lib%s.so.%s lib%s.so.%s" % (dest, so_name, version_full, so_name, version)
    all_rules += dep+"\n"+cmd+"\n"
    #link to .so
    dep = "%slib%s.so : %slib%s.so.%s" % (dest+os.sep, so_name, dest+os.sep, so_name, version_full)
    cmd = "\tcd %s && ln -sf lib%s.so.%s lib%s.so" % (dest, so_name, version_full, so_name)
    all_rules += dep+"\n"+cmd+"\n"
    #Make install
    install = ".PHONY : install-lib%s\n" % so_name
    install += "install-lib%s : %slib%s.so.%s\n" % (so_name, dest+os.sep,so_name,version_full)
    install += "\tinstall -d $(LIB_DIR)\n"
    install += "\tinstall $< $(LIB_DIR)\n"
    install += "\tcd $(LIB_DIR) && ln -sf lib%s.so.%s lib%s.so.%s\n" % (so_name, version_full,
                                                                      so_name, version)
    install += "\tcd $(LIB_DIR) && ln -sf lib%s.so.%s lib%s.so\n" % (so_name, version_full,so_name)
    all_rules += install
    return all_rules

#Makefile: the go output object file for the package
def make_go_o_file(pkg_name, pkg, dest, base_name):
    dep = "%s%s.o :" % (dest+os.sep, pkg_name)
    go_files = map(lambda x: dest+os.sep+x, pkg['GoFiles']+pkg['CgoFiles'])
    build = ""
    for go in pkg['GoFiles']:
        d = " %s%s%s" % (pkg_name, os.sep, go)
        dep += d
        build += d
    for cgo in pkg['CgoFiles']:
        d = " %s%s%s%s_obj%s%s.cgo1.go" % (dest, os.sep, pkg_name, os.sep, os.sep, cgo[0:-3])
        dep += d
        build += d
    if len(pkg['CgoFiles']) > 0:
        d = " %s%s%s%s_obj%s_cgo_gotypes.go" % (dest, os.sep, pkg_name, os.sep, os.sep)
        dep += d
        build += d
    #package dependency order
    for i in pkg['Imports']:
        if i.startswith(base_name):
            dep += " %s%s%s.o" % (dest, os.sep,i)
    if pkg['Name']=='main':
        cmd = "\t$(GCCGO) $(CFLAGS) $(LDFLAGS) -fPIC -I%s -c -o $@ %s" % (dest, build)
    else:
        cmd = "\t$(GCCGO) $(CFLAGS) $(LDFLAGS) -fPIC -fgo-pkgpath=%s -I/usr/include -I%s -c -o $@ %s" % (pkg_name, dest, build)
    #Make containing dir if needed
    depdir = dest+os.sep+pkg_name[0:-(len(pkg['Name'])+1)]
    cmddir = "\tmkdir -p "+depdir
    dep += " | %s" % depdir
    #Make gox files
    dep_gox = "%s%s.gox : %s%s.o" % (dest+os.sep, pkg_name, dest+os.sep, pkg_name)
    cmd_gox = "\t${OBJCOPY} -j .go_export $^ $@"
    #Make install
    install = ".PHONY : install-%s\n" % pkg_name
    install += "install-%s : %s%s.gox\n" % (pkg_name, dest+os.sep,pkg_name)
    install += "\tinstall -d $(LIB_DIR)/%s\n" % (pkg_name[0:-len(pkg['Name'])])
    #install += "\t$(STRIP) %s%s.gox \n" % (dest+os.sep,pkg_name)
    install += "\tinstall %s%s.gox $(LIB_DIR)/%s.gox\n" % (dest+os.sep,pkg_name, pkg_name)
    return (dep+"\n"+cmd+"\n"+depdir+" ::\n"+cmddir+"\n"+dep_gox+"\n"+cmd_gox+"\n"+install)

#Makefile: the c output object file for the package
def make_c_a_file(pkg_name, pkg, dest):
    dep = "%s%slib%s_c.o :" % (dest+os.sep, pkg_name+os.sep, pkg['Name'])
    for c in pkg['CFiles']:
        dep += " %s%s.o" % (dest+os.sep+pkg_name+os.sep, c[0:-2])
    #cmd = "\t$(AR) rcs $@ $^"
    #cmd = "\t$(CC) -fPIC -nostdlib -o $@ $^"
    cmd = "\t$(LD) -r $^ -o $@"
    dep_o = "%s%%.o : %s%%.c" % (dest+os.sep+pkg_name+os.sep, pkg_name+os.sep)
    cmd_o = "\t$(CC) $(CFLAGS) $(LDFLAGS) -fPIC %s -I%s -c -o $@ $^" % (' '.join(pkg['CgoCFLAGS']), pkg_name)
    return dep+"\n"+cmd+"\n"+dep_o+"\n"+cmd_o+"\n"

#Makefile: the cgo wrapper output object file for the package
def make_cgo_o_file(pkg_name, pkg, dest):
    cgo_files = ['_cgo_defun.c','_cgo_export.c','_cgo_flags','_cgo_gotypes.go','_cgo_main.c']
    cgo_dir = "%s%s%s%s_obj%s" % (dest, os.sep, pkg_name, os.sep, os.sep)
    cgo_inputs = []
    for cgo_go in pkg['CgoFiles']:
        cgo = cgo_go[0:-3]
        cgo_files += [cgo+'.cgo1.go', cgo+'.cgo2.c']
        cgo_inputs += ["%s%s%s" % (pkg_name, os.sep, cgo_go)]
    #The go tool cgo call
    dep = " ".join(map(lambda x: cgo_dir+x, cgo_files))+" : "+" ".join(cgo_inputs)+" | "+dest+os.sep+pkg_name+os.sep+"_obj"
    objdir = "%s%s%s%s_obj" % (dest, os.sep, pkg_name, os.sep)
    cmd = "\tcd %s && GOARCH=arm go tool cgo -objdir=%s -gccgo=true -- -I%s %s %s" % (pkg_name, objdir, objdir, " ".join(pkg['CgoCFLAGS']), " ".join(pkg['CgoFiles']))
    all_rules = dep+"\n"+cmd+"\n"
    #Compile the temp .o file for the CGO import call 
    cgo_tmp_files = ['_cgo_main.o', '_cgo_export.o'] + map(lambda x: x[0:-3]+".cgo2.o", pkg['CgoFiles'])
    cgo_tmp_files = map(lambda x: cgo_dir+x, cgo_tmp_files) + map(lambda x: dest+os.sep+pkg_name+os.sep+x[0:-2]+".o", pkg['CFiles'])
    dep = "%s_cgo_tmp.o : %s" % (cgo_dir, " ".join(cgo_tmp_files))
    cmd = "\t$(CC) $(CFLAGS) $(LDFLAGS) -fPIC -o $@ $^"
    all_rules += dep+"\n"+cmd+"\n"
    #Generic c to o compilation rule
    dep = "%s%%.o: %s%%.c" % (cgo_dir, cgo_dir)
    cmd = "\t$(CC) $(CFLAGS) $(LDFLAGS) -fPIC %s -I%s -c -o $@ $^" % (' '.join(pkg['CgoCFLAGS']), pkg_name)
    all_rules += dep+"\n"+cmd+"\n"
    #Create cgo import .c file
    dep = "%s_cgo_import.c : %s_cgo_tmp.o" % (objdir+os.sep, objdir+os.sep)
    cmd = "\tcd %s && GOARCH=arm go tool cgo -objdir=%s -dynimport=\"%s_cgo_tmp.o\" -dynout=\"%s_cgo_import.c\"" % (pkg_name, objdir, objdir+os.sep, objdir+os.sep)
    all_rules += dep+"\n"+cmd+"\n"
    #Create cgo complete .a file for inclusion in package
    cgo_pkg_files = ['_cgo_export.o', '_cgo_import.o'] + map(lambda x: x[0:-3]+".cgo2.o", pkg['CgoFiles'])
    dep = "%s%slib%s_cgo.o : "%(dest+os.sep, pkg_name+os.sep, pkg['Name'])
    dep += " ".join(map(lambda x: objdir+os.sep+x, cgo_pkg_files))
    #cmd = "\t$(AR) rcs $@ $^"
    #cmd = "\t$(CC) -fPIC %s -I%s -o $@ -nostdlib $^" % (" ".join(pkg['CgoCFLAGS']), pkg_name)
    cmd = "\t$(LD) -r $^ -o $@"
    all_rules += dep+"\n"+cmd+"\n"
    #Create the _obj directory
    depdir = dest+os.sep+pkg_name+os.sep+"_obj :"
    cmddir = "\tmkdir -p "+dest+os.sep+pkg_name+os.sep+"_obj"
    all_rules += depdir+"\n"+cmddir+"\n"
    return all_rules

#Get the useful package environement settings
def get_package_env(pkg):
    from subprocess import Popen
    import subprocess
    proc = Popen(['go', 'list', '-f',
                  '{"GoFiles" : [{{range .GoFiles}} "{{.}}", {{end}}], "CgoFiles" : [{{range .CgoFiles}} "{{.}}", {{end}}], "CFiles" : [{{range .CFiles}} "{{.}}", {{end}}], "CgoCFLAGS" : [{{range .CgoCFLAGS}} "{{.}}", {{end}}], "CgoLDFLAGS" : [{{range .CgoLDFLAGS}} "{{.}}", {{end}}], "Imports" : [{{range .Imports}} "{{.}}", {{end}}], "Name" : "{{.Name}}"}',
                  pkg], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=go_env)
    out, err = proc.communicate()
    return eval(out)

#Get the package name for a directory
def get_package_name(d):
    from subprocess import Popen
    import subprocess
    proc = Popen(['go', 'list', '-f', '{{.ImportPath}}', d], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=go_env)
    out, err = proc.communicate()
    if proc.returncode != 0:
        return None
    else:
        return out.strip()

#Determine what go packages are here
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

#Return the source for a Makefile that builds the desired exec & libs
def gen_makefile(p, work, base_name, so_name, exec_name, version, version_major, linker_flags):
    pkg_names = get_packages(p)
    pkgs = {}
    makefile = ""
    for pkg_name in pkg_names:
        pkgs[pkg_name] = get_package_env(pkg_name)
    lib_pkg_names = filter(lambda n: pkgs[n]['Name']!='main', pkg_names)
    lib_pkgs = {k: pkgs[k] for k in lib_pkg_names}
    #all statement
    makefile += "all: "
    if (so_name):
        makefile += work+os.sep+"lib"+so_name+".so "
        makefile += work+os.sep+"lib"+so_name+".so."+version_major+" "
    if (exec_name):
        makefile += work+os.sep+"bin"+os.sep+exec_name+" "
    makefile += "\n"
    #install statement
    makefile += ".PHONY : install\n"
    makefile += "install : "
    if (exec_name):
        makefile += "install-bin-%s " % exec_name
    if (so_name):
        makefile += "install-lib%s " % so_name
    for pkg_name in lib_pkg_names:
        makefile += "install-%s " % pkg_name
    makefile += "\n"
    #make lib file
    if (so_name):
        makefile += make_lib_files(so_name, version_major, version, lib_pkgs, work)
    #make packages
    for pkg_name, pkg in pkgs.iteritems():
        if pkg['Name']=='main':
            if (so_name):
                makefile += make_go_dynamic_exec_file(pkg_name, pkg, work, so_name, linker_flags)
            else:
                makefile += make_go_static_exec_file(pkg_name, pkg, work, lib_pkgs, linker_flags)
        makefile += make_go_o_file(pkg_name, pkg, work, base_name)
        if len(pkg['CFiles'])>0:
            makefile += make_c_a_file(pkg_name, pkg, work)
        if len(pkg['CgoFiles'])>0:
            makefile += make_cgo_o_file(pkg_name, pkg, work)
    return makefile

python do_configure () {
    global go_env
    go_env = os.environ.copy()
    go_env["GOPATH"] = d.getVar("WORKDIR", True)
    s = d.getVar("S", True)
    b = d.getVar("B", True)
    base_name = d.getVar("GO_PACKAGE_NAME", True)
    so_name = d.getVar("GO_LIB_NAME", True)
    version = d.getVar("GO_LIB_VERSION", True)
    version_major = d.getVar("GO_LIB_VERSION_MAJOR", True)
    linker_flags = d.getVar("GO_LINKER", True)
    exec_name = d.getVar("GO_EXEC_NAME", True)
    makefile = gen_makefile(s, b, base_name, so_name, exec_name, version, version_major, linker_flags)
    with open(s+os.sep+"Makefile", "w") as f:
        f.write(makefile)
    print d.getVar("GCCGO", True)
}

base_do_compile() {
    export GCCGO="${GCCGO}"
    export OBJCOPY="${OBJCOPY}"
    cd ${S}
    if [ -e Makefile -o -e makefile -o -e GNUmakefile ]; then
        oe_runmake || die "make failed"
    else
        bbnote "nothing to compile"
    fi
}

do_install () {
    echo "${FILES_${PN}-dbg}"
    cd ${S}
    export INCLUDE_DIR="${D}${includedir}"
    export LIB_DIR="${D}${libdir}"
    export BIN_DIR="${D}${bindir}"
    if [ -e Makefile -o -e makefile -o -e GNUmakefile ]; then
        oe_runmake install || die "make failed"
    else
        bbnote "nothing to install"
    fi
}

#Keep debugging symbols in main package for go
#FILES_${PN} += "${bindir}/.debug"
FILES_${PN}-dev += "${libdir}/${GO_PACKAGE_NAME}*"
FILES_${PN}-dbg = " \
    ${libdir}/*/.debug ${libdir}/*/*/.debug \
    ${libdir}/*/*/*/.debug ${libdir}/*/*/*/*/.debug \
    ${libdir}/.debug /usr/src/debug"

#Override the default split_and_strip_files. GCCGO excutable files require debug symbols.

python split_and_strip_files () {
    import stat, errno

    dvar = d.getVar('PKGD', True)
    pn = d.getVar('PN', True)

    # We default to '.debug' style
    if d.getVar('PACKAGE_DEBUG_SPLIT_STYLE', True) == 'debug-file-directory':
        # Single debug-file-directory style debug info
        debugappend = ".debug"
        debugdir = ""
        debuglibdir = "/usr/lib/debug"
        debugsrcdir = "/usr/src/debug"
    elif d.getVar('PACKAGE_DEBUG_SPLIT_STYLE', True) == 'debug-without-src':
        # Original OE-core, a.k.a. ".debug", style debug info, but without sources in /usr/src/debug
        debugappend = ""
        debugdir = "/.debug"
        debuglibdir = ""
        debugsrcdir = ""
    else:
        # Original OE-core, a.k.a. ".debug", style debug info
        debugappend = ""
        debugdir = "/.debug"
        debuglibdir = ""
        debugsrcdir = "/usr/src/debug"

    sourcefile = d.expand("${WORKDIR}/debugsources.list")
    bb.utils.remove(sourcefile)

    os.chdir(dvar)

    # Return type (bits):
    # 0 - not elf
    # 1 - ELF
    # 2 - stripped
    # 4 - executable
    # 8 - shared library
    # 16 - kernel module
    def isELF(path):
        type = 0
        ret, result = oe.utils.getstatusoutput("file \"%s\"" % path.replace("\"", "\\\""))

        if ret:
            msg = "split_and_strip_files: 'file %s' failed" % path
            package_qa_handle_error("split-strip", msg, d)
            return type

        # Not stripped
        if "ELF" in result:
            type |= 1
            if "not stripped" not in result:
                type |= 2
            if "executable" in result:
                type |= 4
            if "shared" in result:
                type |= 8
        return type


    #
    # First lets figure out all of the files we may have to process ... do this only once!
    #
    elffiles = {}
    symlinks = {}
    hardlinks = {}
    kernmods = []
    libdir = os.path.abspath(dvar + os.sep + d.getVar("libdir", True))
    baselibdir = os.path.abspath(dvar + os.sep + d.getVar("base_libdir", True))
    if (d.getVar('INHIBIT_PACKAGE_STRIP', True) != '1'):
        for root, dirs, files in cpath.walk(dvar):
            for f in files:
                file = os.path.join(root, f)
                if file.endswith(".ko") and file.find("/lib/modules/") != -1:
                    kernmods.append(file)
                    continue

                # Skip debug files
                if debugappend and file.endswith(debugappend):
                    continue
                if debugdir and debugdir in os.path.dirname(file[len(dvar):]):
                    continue

                # Skip go bin files
                if root.endswith("bin"):
                    continue

                try:
                    ltarget = cpath.realpath(file, dvar, False)
                    s = cpath.lstat(ltarget)
                except OSError as e:
                    (err, strerror) = e.args
                    if err != errno.ENOENT:
                        raise
                    # Skip broken symlinks
                    continue
                if not s:
                    continue
                # Check its an excutable
                if (s[stat.ST_MODE] & stat.S_IXUSR) or (s[stat.ST_MODE] & stat.S_IXGRP) or (s[stat.ST_MODE] & stat.S_IXOTH) \
                        or ((file.startswith(libdir) or file.startswith(baselibdir)) and ".so" in f):
                    # If it's a symlink, and points to an ELF file, we capture the readlink target
                    if cpath.islink(file):
                        target = os.readlink(file)
                        if isELF(ltarget):
                            #bb.note("Sym: %s (%d)" % (ltarget, isELF(ltarget)))
                            symlinks[file] = target
                        continue
                    # It's a file (or hardlink), not a link
                    # ...but is it ELF, and is it already stripped?
                    elf_file = isELF(file)
                    if elf_file & 1:
                        if elf_file & 2:
                            if 'already-stripped' in (d.getVar('INSANE_SKIP_' + pn, True) or "").split():
                                bb.note("Skipping file %s from %s for already-stripped QA test" % (file[len(dvar):], pn))
                            else:
                                msg = "File '%s' from %s was already stripped, this will prevent future debugging!" % (file[len(dvar):], pn)
                                package_qa_handle_error("already-stripped", msg, d)
                            continue
                        # Check if it's a hard link to something else
                        if s.st_nlink > 1:
                            file_reference = "%d_%d" % (s.st_dev, s.st_ino)
                            # Hard link to something else
                            hardlinks[file] = file_reference
                            continue
                        elffiles[file] = elf_file

    #
    # First lets process debug splitting
    #
    if (d.getVar('INHIBIT_PACKAGE_DEBUG_SPLIT', True) != '1'):
        hardlinkmap = {}
        # For hardlinks, process only one of the files
        for file in hardlinks:
            file_reference = hardlinks[file]
            if file_reference not in hardlinkmap:
                # If this is a new file, add it as a reference, and
                # update it's type, so we can fall through and split
                elffiles[file] = isELF(file)
                hardlinkmap[file_reference] = file

        for file in elffiles:
            src = file[len(dvar):]
            dest = debuglibdir + os.path.dirname(src) + debugdir + "/" + os.path.basename(src) + debugappend
            fpath = dvar + dest

            # Split the file...
            bb.utils.mkdirhier(os.path.dirname(fpath))
            #bb.note("Split %s -> %s" % (file, fpath))
            # Only store off the hard link reference if we successfully split!
            splitdebuginfo(file, fpath, debugsrcdir, sourcefile, d)

        # Hardlink our debug symbols to the other hardlink copies
        for file in hardlinks:
            if file not in elffiles:
                src = file[len(dvar):]
                dest = debuglibdir + os.path.dirname(src) + debugdir + "/" + os.path.basename(src) + debugappend
                fpath = dvar + dest
                file_reference = hardlinks[file]
                target = hardlinkmap[file_reference][len(dvar):]
                ftarget = dvar + debuglibdir + os.path.dirname(target) + debugdir + "/" + os.path.basename(target) + debugappend
                bb.utils.mkdirhier(os.path.dirname(fpath))
                #bb.note("Link %s -> %s" % (fpath, ftarget))
                os.link(ftarget, fpath)

        # Create symlinks for all cases we were able to split symbols
        for file in symlinks:
            src = file[len(dvar):]
            dest = debuglibdir + os.path.dirname(src) + debugdir + "/" + os.path.basename(src) + debugappend
            fpath = dvar + dest
            # Skip it if the target doesn't exist
            try:
                s = os.stat(fpath)
            except OSError as e:
                (err, strerror) = e.args
                if err != errno.ENOENT:
                    raise
                continue

            ltarget = symlinks[file]
            lpath = os.path.dirname(ltarget)
            lbase = os.path.basename(ltarget)
            ftarget = ""
            if lpath and lpath != ".":
                ftarget += lpath + debugdir + "/"
            ftarget += lbase + debugappend
            if lpath.startswith(".."):
                ftarget = os.path.join("..", ftarget)
            bb.utils.mkdirhier(os.path.dirname(fpath))
            #bb.note("Symlink %s -> %s" % (fpath, ftarget))
            os.symlink(ftarget, fpath)

        # Process the debugsrcdir if requested...
        # This copies and places the referenced sources for later debugging...
        copydebugsources(debugsrcdir, d)
    #
    # End of debug splitting
    #

    #
    # Now lets go back over things and strip them
    #
    if (d.getVar('INHIBIT_PACKAGE_STRIP', True) != '1'):
        strip = d.getVar("STRIP", True)
        sfiles = []
        for file in elffiles:
            elf_file = int(elffiles[file])
            #bb.note("Strip %s" % file)
            sfiles.append((file, elf_file, strip))
        for f in kernmods:
            sfiles.append((f, 16, strip))


        import multiprocessing
        nproc = multiprocessing.cpu_count()
        pool = bb.utils.multiprocessingpool(nproc)
        processed = list(pool.imap(oe.package.runstrip, sfiles))
        pool.close()
        pool.join()

    #
    # End of strip
    #
}
