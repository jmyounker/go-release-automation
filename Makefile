.PHONY: build-rpm build-deb

DOCKER_RPM := theblobshop/be:centos-7.4
DOCKER_DEB := theblobshop/be:debian-stretch-20171210

PUBLISHER_HOST := theblobshop.com
PUBLISHER_USER := jeff
PUBLISHER_SITE := theblobshop.com

BUILD_DIR := $(shell pwd)/build
PKG_DIR := $(shell pwd)/package

clean: 
	rm -rf $(BUILD_DIR)
	rm -rf $(PKG_DIR)

build-image-centos:
	packer build centos.json

build-image-debian:
	packer build debian.json

build-images: build-image-centos build-image-debian
	echo "building images"

test-images: package-rpm package-deb
	echo "running builds on images"

images-all: build-images test-images
	echo "building images and running tests"

require-pkg:
ifndef PKG
	$(error "envar PKG required (e.g. export PKG=github.com/jmyounker/vers)" )
endif

build-vars: require-pkg
	$(eval APP_NAME := $(shell basename $(PKG)))

build-package: build-vars
	if [ ! -d $(PKG_DIR) ]; then mkdir $(PKG_DIR); fi

package-rpm: build-vars build-package
	docker run -it --rm --mount type=bind,source=$(PKG_DIR),target=/package $(DOCKER_RPM) su -l build -c 'go get $(PKG); cd $$GOPATH/src/$(PKG); make clean package-rpm; cp target/package/* /package'

package-deb: build-vars build-package
	docker run -it --rm --mount type=bind,source=$(PKG_DIR),target=/package $(DOCKER_DEB) su -l build -c 'go get $(PKG); cd $$GOPATH/src/$(PKG); make clean package-deb; cp target/package/* /package'

build-dir: build-vars
	if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR); fi

build-go-dir: build-vars build-dir
	if [ ! -d $(BUILD_DIR)/go ]; then mkdir $(BUILD_DIR)/go; fi

package-osx: build-go-dir
	$(eval GOPATH := $(BUILD_DIR)/go)
	echo $(GOPATH)
	GOPATH=$(GOPATH) go get $(PKG)
	cd $(GOPATH)/src/$(PKG); GOPATH=$(GOPATH) make clean package-osx
	cp $(GOPATH)/src/$(PKG)/target/package/* $(PKG_DIR)

upload: build-vars
	[ -f $(PKG_DIR)/*.rpm ] && scp $(PKG_DIR)/*.rpm $(PUBLISHER_USER)@$(PUBLISHER_HOST):$(PUBLISHER_SITE)/downloads/$(APP_NAME)/rpm
	[ -f $(PKG_DIR)/*.deb ] && scp $(PKG_DIR)/*.deb $(PUBLISHER_USER)@$(PUBLISHER_HOST):$(PUBLISHER_SITE)/downloads/$(APP_NAME)/deb
	[ -f $(PKG_DIR)/*.pkg ] && scp $(PKG_DIR)/*.pkg $(PUBLISHER_USER)@$(PUBLISHER_HOST):$(PUBLISHER_SITE)/downloads/$(APP_NAME)/osx

make-release-repo: build-vars
	ssh $(PUBLISHER_USER)@$(PUBLISHER_HOST) install -d -o $(PUBLISHER_USER) -g $(PUBLISHER_USER) -m 0755 $(PUBLISHER_SITE)/downloads/$(APP_NAME)
	ssh $(PUBLISHER_USER)@$(PUBLISHER_HOST) install -d -o $(PUBLISHER_USER) -g $(PUBLISHER_USER) -m 0755 $(PUBLISHER_SITE)/downloads/$(APP_NAME)/rpm
	ssh $(PUBLISHER_USER)@$(PUBLISHER_HOST) install -d -o $(PUBLISHER_USER) -g $(PUBLISHER_USER) -m 0755 $(PUBLISHER_SITE)/downloads/$(APP_NAME)/deb
	ssh $(PUBLISHER_USER)@$(PUBLISHER_HOST) install -d -o $(PUBLISHER_USER) -g $(PUBLISHER_USER) -m 0755 $(PUBLISHER_SITE)/downloads/$(APP_NAME)/osx

release: package-rpm package-deb package-osx upload


