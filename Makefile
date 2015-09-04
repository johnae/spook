PREFIX ?= /usr/local
UNAME := $(shell uname)
ARCH := $(shell uname -m)
ifeq ($(UNAME), Darwin)
ENABLE_LUA52COMPAT = sed -i '' 's/^\#XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/'
CFLAGS = -Wall -O2 -Wl
EXTRAS = -pagezero_size 10000 -image_base 100000000
else
ENABLE_LUA52COMPAT = sed -i 's/^\#XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/'
CFLAGS = -Wall -O2 -Wl,-E
EXTRAS = -lrt
endif
GITTAG = $(shell git tag -l --contains HEAD)
GITBRANCH = $(shell git symbolic-ref --short HEAD)
GITSHA = $(shell git rev-parse --short HEAD)
LUAJIT_SRC = deps/luajit/src
LUAJIT_LIBS = tools/luajit/lib
LUAJIT_INCLUDE = tools/luajit/include/luajit-2.0
LUAJIT_ARCHIVE = tools/luajit/lib/libluajit-5.1.a
LUAJIT = tools/luajit/bin/luajit
TOOLS=$(realpath tools)
LUAJIT_BIN = $(realpath ${LUAJIT})
LIBLUV = deps/luv
LIBLUV_DEPS = ${LIBLUV}/build/libluv.a ${LIBLUV}/build/libuv.a
LIBLUV_INCLUDE = deps/luv/src
LIBUV_INCLUDE = deps/luv/deps/libuv/include
ARCHIVES = $(LUAJIT_ARCHIVE)
OBJECTS = main lib vendor

.PHONY: release

all: version_tag ${LIBLUV_DEPS} ${LUAJIT} ${OBJECTS} spook test

spook:
	$(CC) $(CFLAGS) -fPIC -o spook app.c main.o lib.o vendor.o $(ARCHIVES) ${LIBLUV_DEPS} -I ${LIBUV_INCLUDE} -I ${LIBLUV_INCLUDE} -I ${LUAJIT_INCLUDE} -lm -ldl -lpthread $(EXTRAS)

rebuild: clean all

test:
	./spook -f spec/support/run_busted.lua

install: all
	cp spook $(PREFIX)/bin

version_tag:
	@if [ "$(GITTAG)" != "" ]; then echo "'$(GITTAG)'" > lib/version.moon; else echo "'$(GITSHA)-dirty'" > lib/version.moon; fi


${LIBLUV_DEPS}:
	git submodule update --init deps/luv
	cd deps/luv && \
		BUILD_MODULE=OFF WITH_SHARED_LUAJIT=OFF $(MAKE)

${LUAJIT}:
	git submodule update --init deps/luajit
	cd deps/luajit/src && \
		$(ENABLE_LUA52COMPAT) Makefile
	cd deps/luajit && \
		$(MAKE) PREFIX=${TOOLS}/luajit && \
		$(MAKE) install PREFIX=${TOOLS}/luajit
	cd deps/luajit/src && \
		git checkout Makefile

lib.lua:
	cd lib && \
		${LUAJIT_BIN} ../tools/pack.lua . > ../lib.lua

vendor.lua:
	cd vendor && \
		${LUAJIT_BIN} ../tools/pack.lua . > ../vendor.lua

${OBJECTS}: lib.lua vendor.lua
	${LUAJIT_BIN} -b $@.lua $@.o

clean-deps:
	rm -rf tools/luajit
	cd deps/luajit && \
		$(MAKE) clean

	cd deps/luv && \
		$(MAKE) clean

clean:
	rm -f spook main.o lib.o vendor.o vendor.lua lib.lua spook-*.gz lib/version.moon

tools/github-release:
	cd /tmp && \
		if [ "$(UNAME)" = "Darwin" ]; then wget https://github.com/aktau/github-release/releases/download/v0.5.3/darwin-amd64-github-release.tar.bz2 -O /tmp/github-release.tar.bz2 && tar jxf github-release.tar.bz2 && mv bin/darwin/amd64/github-release $(TOOLS)/github-release && chmod +x $(TOOLS)/github-release; fi && \
	if [ "$(UNAME)" = "Linux" ]; then wget https://github.com/aktau/github-release/releases/download/v0.5.3/linux-amd64-github-release.tar.bz2 -O /tmp/github-release.tar.bz2 && tar jxf github-release.tar.bz2 && mv bin/linux/amd64/github-release $(TOOLS)/github-release && chmod +x $(TOOLS)/github-release; fi
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
