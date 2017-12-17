Go Release Scripts
==================
A makefile automating release work for simple go programs.

Produces releases for a go product packaged as RPMs, debs,
or OSX .pkgs.

Contains packer scripts to build docker containers for
CentOS and Debian.  RPM and deb release steps use these
containers to build and package.

OSX packages are built locally.  I do this because development
happens on OSX, and this tooling is run from OSX.


Usage
-----
Build, package, and upload:

```
PKG=YOUR_PACKAGE_NAME make release
```

For example:
```
PKG=github.com/jmyounker/vers make release
```

Create a new release directories:

```
PKG=github.com/jmyounker/vers make create-release-repo
```

Create new docker images:
```
make build-images
```

You can test images, but that requires a package:
```
PKG=github.com/jmyounker/vers make test-images
```

Notes
-----
The packages are delivered to
`~PUBLISHER_USER/PUBLISHER_SITE/downloads/PKG_NAME/(rpm|deb|osx)` 
which is expected to surface them at
`http(s)://PUBLISHER_SITE/downloads/PKG_NAME/(rpm|deb|osx)`.
