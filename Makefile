PREFIX ?= /usr/local
UNAME := $(shell uname | tr 'A-Z' 'a-z')
ARCH := $(shell uname -m)
SPOOK_BASE_DIR := $(shell pwd)
CFLAGS = -Wall -O2 -Wl,-E
ifeq ($(ARCH), x86_64)
LJXCFLAGS = -DLUAJIT_ENABLE_LUA52COMPAT -DLUAJIT_ENABLE_GC64
else
LJXCFLAGS = -DLUAJIT_ENABLE_LUA52COMPAT
endif
ifeq ($(UNAME), darwin)
CFLAGS = -Wall -O2 -Wl
ifneq ($(ARCH), x86_64)
EXTRAS = -pagezero_size 10000 -image_base 100000000
endif
endif
ifeq ($(UNAME), linux)		
EXTRAS = -ldl
endif
GITTAG := $(shell git tag -l --contains HEAD)
GITBRANCH := $(shell git symbolic-ref --short HEAD)
GITSHA := $(shell git rev-parse --short HEAD)
ifeq ($(GITTAG), )
SPOOK_VERSION := $(GITSHA)-dirty
else
SPOOK_VERSION := $(GITTAG)
endif
LUAJIT_INCLUDE := tools/luajit/include/luajit-2.1
LUAJIT_ARCHIVE := tools/luajit/lib/libluajit-5.1.a
LUAJIT := tools/luajit/bin/luajit
TOOLS := $(realpath tools)
## this has to be expanded dynamically since luajit
## needs to be built first
LUAJIT_BIN = $(realpath $(LUAJIT))
ARCHIVES := $(LUAJIT_ARCHIVE)
OBJECTS := main.o lib.o vendor.o

.PHONY: all clean clean-deps rebuild release test

all: spook

spook: $(OBJECTS)
	@echo "BUILDING SPOOK"
	$(CC) $(CFLAGS) -fPIC -o spook app.c $(OBJECTS) $(ARCHIVES) -I $(LUAJIT_INCLUDE) -lm $(EXTRAS)

rebuild: clean all

test: spook
	$(LUAJIT_BIN) spec/support/run_busted.lua spec

lint: spook
	$(LUAJIT_BIN) spec/support/run_linter.lua lib/*.moon lib/bsd/*.moon lib/linux/*.moon
	$(LUAJIT_BIN) spec/support/run_linter.lua spec/*.moon

install: all
	cp spook $(PREFIX)/bin

lib/version.moon:
	@echo "VERSION TAGGING: $(SPOOK_VERSION)"
	@echo "'$(SPOOK_VERSION)'" > lib/version.moon

$(LUAJIT):
	@echo "BUILDING LUAJIT"
	git submodule update --init deps/luajit
	$(MAKE) -C deps/luajit XCFLAGS="$(LJXCFLAGS)" PREFIX=$(TOOLS)/luajit
	$(MAKE) -C deps/luajit install PREFIX=$(TOOLS)/luajit
	ln -sf $(TOOLS)/luajit/bin/luajit-2.1.0-beta3 $(TOOLS)/luajit/bin/luajit

main.lua: $(LUAJIT)
	@echo "BUILDING main.lua"
	SPOOK_BASE_DIR=$(SPOOK_BASE_DIR) $(LUAJIT_BIN) ./tools/compile_moon.lua main.moon > main.lua

lib.lua: lib/version.moon $(LUAJIT)
	@echo "BUILDING lib.lua"
	cd lib && \
		SPOOK_BASE_DIR=$(SPOOK_BASE_DIR) $(LUAJIT_BIN) ../tools/pack.lua . > ../lib.lua

vendor.lua: $(LUAJIT)
	@echo "BUILDING vendor.lua"
	cd vendor && \
		OS=$(UNAME) SPOOK_BASE_DIR=$(SPOOK_BASE_DIR) $(LUAJIT_BIN) ../tools/pack.lua . > ../vendor.lua

%.o: %.lua
	@echo "BUILDING luajit bytecode from $*.lua"
	$(LUAJIT_BIN) -b $*.lua $*.o

clean-deps:
	rm -rf tools/luajit
	cd deps/luajit && \
		$(MAKE) clean

clean:
	rm -f $(OBJECTS)
	rm -f main.lua vendor.lua lib.lua
	rm -f spook spook-*.gz lib/version.moon

tools/github-release:
	cd /tmp && \
		if [ "$(UNAME)" = "darwin" ]; then wget https://github.com/aktau/github-release/releases/download/v0.5.3/darwin-amd64-github-release.tar.bz2 -O /tmp/github-release.tar.bz2 && tar jxf github-release.tar.bz2 && mv bin/darwin/amd64/github-release $(TOOLS)/github-release && chmod +x $(TOOLS)/github-release; fi && \
	if [ "$(UNAME)" = "linux" ]; then wget https://github.com/aktau/github-release/releases/download/v0.5.3/linux-amd64-github-release.tar.bz2 -O /tmp/github-release.tar.bz2 && tar jxf github-release.tar.bz2 && mv bin/linux/amd64/github-release $(TOOLS)/github-release && chmod +x $(TOOLS)/github-release; fi
	rm -rf /tmp/bin /tmp/*gitub-release*

release-create: tools/github-release
	@if [ "$(GITTAG)" = "" ]; then echo "You've not checked out a git tag" && exit 1; fi
	$(TOOLS)/github-release release \
		--tag $(GITTAG) \
		--name "Release $(GITTAG)" \
		--description "Release $(GITTAG)"

prerelease-create: tools/github-release
	@if [ "$(GITTAG)" = "" ]; then echo "You've not checked out a git tag" && exit 1; fi
	$(TOOLS)/github-release release \
		--tag $(GITTAG) \
		--name "Release $(GITTAG)" \
		--description "Release $(GITTAG)" \
		--pre-release

release-upload: tools/github-release rebuild
	@if [ "$(GITTAG)" = "" ]; then echo "You've not checked out a git tag" && exit 1; fi
	gzip -c spook > spook-$(GITTAG)-$(UNAME)-$(ARCH).gz
	$(TOOLS)/github-release upload \
		--tag $(GITTAG) \
		--name "spook-$(GITTAG)-$(UNAME)-$(ARCH).gz" \
		--file "spook-$(GITTAG)-$(UNAME)-$(ARCH).gz"
	rm -f spook-$(GITTAG)-$(UNAME)-$(ARCH).gz
