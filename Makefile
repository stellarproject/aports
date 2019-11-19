# Stellar Project Packages
#
# To build all: make terra
# To build a specific package: make terra/<package> (i.e. make terra/terraos-installer)
# To build all with buildkit: make buildkit
#   Note: this will build all packages and use a build cache.  The first run will take a long
#   time as it will build the kernel but subsequent builds should be cached efficiently.

PACKAGES?=$(sort $(shell ls -d terra/*))
SIGNING_PRIVATE_KEY?=
SIGNING_PUBLIC_KEY?=
MIRROR?=http://mirrors.gigenet.com/alpinelinux
PACKAGE_DIR?=${HOME}/packages
VAB_ARGS?=
OUTPUT_DIR?=./build

terra: $(PACKAGES)

$(PACKAGES):
	@echo "building -> $(basename $@)"
	@cd $@; abuild -c -r -R -P ${PACKAGE_DIR}

buildkit:
	@vab build --local --output ${OUTPUT_DIR} -a PACKAGE_DIR=${PACKAGE_DIR} -a "PACKAGES=${PACKAGES}" -a MIRROR="${MIRROR}" -a SIGNING_PRIVATE_KEY="$${SIGNING_PRIVATE_KEY}" -a SIGNING_PUBLIC_KEY="$${SIGNING_PUBLIC_KEY}" ${VAB_ARGS} .

clean:
	@rm -rf build

.PHONY: $(PACKAGES) buildkit terra clean
