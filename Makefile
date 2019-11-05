TERRA_PKGS = $(sort $(shell ls -d terra/*))

terra: $(TERRA_PKGS)

$(TERRA_PKGS):
	@echo "building -> $(basename $@)"
	@cd $@ ; abuild -r

clean:
	@rm -rf build

.PHONY: $(TERRA_PKGS) clean
