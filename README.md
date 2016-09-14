# Go Programming Language OpenEmbedded/Yocto Layer

This layer adds a go support to the OpenEmbedded/Yocto build system.

Go Compiler versions:
* Go1.7 via native GC

It supports the following features:
* Build GC compiler for native system
* Build golang static runtime packages for target system
* Class for Go package static libraries and Go executables using GC
* GC Static Linking

Unimplemented features:
* GCCGO recipes. See GCCGO branch

# Making a GC Golang recipe

All the source must meet the Go workspace formatting requirements:
* The containing directory name is the package or binary name.
* Packages must be imported using absolute name space
* If it doesn't work with 'go install' in Go 1.5, it will not work here.

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
