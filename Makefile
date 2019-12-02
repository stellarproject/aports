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
TAG?=edge
VERSION?=latest
ISO_EXTRA?=

terra: $(PACKAGES)

$(PACKAGES):
	@echo "building -> $(basename $@)"
	@cd $@; abuild -c -r -R -P ${PACKAGE_DIR}

buildkit:
	@vab build --local --output ${OUTPUT_DIR} -a PACKAGE_DIR=${PACKAGE_DIR} -a "PACKAGES=${PACKAGES}" -a MIRROR="${MIRROR}" -a SIGNING_PRIVATE_KEY="$${SIGNING_PRIVATE_KEY}" -a SIGNING_PUBLIC_KEY="$${SIGNING_PUBLIC_KEY}" ${VAB_ARGS} .

iso:
	@echo "building iso ${VERSION} (${TAG})"
	@cd scripts && sh mkimage.sh --tag ${TAG} --outdir ${OUTPUT_DIR} --arch x86_64 --repository ${MIRROR}/edge/main --repository ${MIRROR}/edge/testing --repository ${MIRROR}/edge/community ${ISO_EXTRA} --profile terra

clean:
	@rm -rf ${OUTPUT_DIR}

.PHONY: $(PACKAGES) buildkit iso terra clean
