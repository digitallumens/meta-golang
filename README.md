# Go Programming Language OpenEmbedded/Yocto Layer

This layer adds a go support to the OpenEmbedded/Yocto build system.

It supports the following features:
* Build target GCCGo cross-compiler for host system
* Build target GCCGo runtime packages for installation
* Build target GC cross-compilter for host system
* Class for Go package dynamic libraries and Go executables using GCCGO
* CGO support for C files in GCCGO packages
* Dynamic Linking
* Strips executables but works around debug-symbol issue in GCCGO

Unimplemented features:
* Building recipes with the GC compiler
* CGO support for languages other than C
* Static GCCGO Libraries
* Dynamic libraries that link against other dynamic libraries (Next feature)

# Making a Golang recipe

The golang.bbclass attempts to handle converting Go source workspaces
into a Yocto compatible dynamicly linked environment.

All the source must meet the Go workspace formatting requirements:
* The containing directory name is the package or binary name.
* All files contained in a directory must be exclusively either
** package (directory name)
** package main
* Packages must be imported using absolute name space
* If it doesn't work with 'go install' in Go 1.2, it will not work here.

No matter what type of recipe that you want to make, you need to do
the following.

    inherit golang

This makes the recipe use the golang.bbclass

    GO_PACKAGE_NAME = "absolute/go/workspace/path/to/package"

This package name is the highest level directory which holds all the
go code for the workspace. It is typically the directory in your go
workspace starting from the 'src' directory to the directory that is
your version controlled code. This will typically look something like
"github.com/digitallumens/goexamplepackage". This is used to track if
import dependencies are from inside or outside this code base. Import
dependencies outside this directory will need to be provided by a
shared library.

    SRC_URI = "git:github.com/digitallumens/goexamplepackage.git;destsuffix=src/${GO_PACKAGE_NAME}"

Whatever mechanism that you use to fetch your code will need to place
the end result in a directory structure that matches the
GO_PACKAGE_NAME inside the 'src' directory. This is required by the Go
workspace expects all sources to be under 'src' of the GOPATH. Here
the GOPATH is set to ${WORKING} by the golang.bbclass.

    S := "${WORKDIR}/src"

This is must be this value currently. Perhaps it should be moved into
the golang.bbclass.

## Library recipes

All the non-main packages in GO_PACKAGE_NAME can be linked into a
single shared library. GOX files will be created in the development
packages to allow other recipes to build and link against the shared
library.

    GO_LIB_NAME = "${PN}"

This will create '/usr/lib/lib${GO_LIB_NAME}.so.${GO_LIB_VERSION}' and
'/usr/lib/${GO_PACKAGE_NAME}' GOX files. The GO_LIB_VERSION defaults
to ${PV}, and the GO_LIB_VERSION_MAJOR defaults to the highest field
of ${PV}. GO_LIB_VERSION can be set to something else, but the
GO_LIB_VERSION_MAJOR should also be set to match if you do so.

If you set GO_EXEC_NAME while GO_LIB_NAME is set, the resulting
binaries will be dynamically linked to the created shared library.

## Executable recipes

By default, no executables will be built or installed. A list of ones
that are desired can be passed to GO_EXEC_NAME.

    GO_EXEC_NAME = "${PN} gohello_pack"

This will find any 'main' packages which are named the same as items
in the list and install them. This continues to follow the Go 1.2
workspace convention where executables will have the same name as the
directory containing the 'main' package files.

    GO_LINKER = "-lgoexamplepackage"

You need to provide the linker flags to any shared libraries that
contain the needed external imports.

If GO_EXEC_NAME is set while GO_LIB_NAME is not set, the resulting
binaries will be statically linked against all internal Go
packages. The resulting binary will still by dynamically linked
against libgo, libgcc, libc, and any other libraries specified in
GO_LINKER.

# Theory of Operation.

The golang.bbclass tries to convert the implicit structure provided by
a Go workspace and convert it to a Makefile that follows the build
requirements. It relies on the 'go' application to the parsing and
validation of the package arrangement, but creates a makefile using
the embedded python code instead of allowing 'go' to do it's own
compilation. This allows for the construction of dynamically linked
libraries and executables which more closely track the packaging
methodology behind OpenEmbedded & Yocto.

There is currently a bug in GCCGO 4.8 and 4.9 that makes stripped
binaries fail to run. The golang.bbclass works around this by putting
an empty .debug_str section into the ELF files in /usr/bin after the
packaging split stage. The ramifications of this are not yet known,
but it is expected that errors during execution will not be cleanly
reported.

Debugging Go applications after being split has also not been
attempted.
