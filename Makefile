UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
CFLAGS = -Wall -O2 -Wl
EXTRAS = -pagezero_size 10000 -image_base 100000000
else
CFLAGS = -Wall -O2 -Wl,-E
EXTRAS =
endif
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
OBJECTS = main lib

all: ${LIBLUV_DEPS} ${LUAJIT} ${OBJECTS} spook

spook:
	$(CC) $(CFLAGS) -fPIC -o spook app.c main.o lib.o $(ARCHIVES) ${LIBLUV_DEPS} -I ${LIBUV_INCLUDE} -I ${LIBLUV_INCLUDE} -I ${LUAJIT_INCLUDE} -lm -ldl -lpthread $(EXTRAS)

${LIBLUV_DEPS}:
	git submodule update --init deps/luv
	cd deps/luv && \
		BUILD_MODULE=OFF WITH_SHARED_LUAJIT=OFF $(MAKE)

${LUAJIT}:
	git submodule update --init deps/luajit
	cd deps/luajit && \
		$(MAKE) PREFIX=${TOOLS}/luajit && \
		$(MAKE) install PREFIX=${TOOLS}/luajit

lib.lua:
	cd src && \
		${LUAJIT_BIN} ../tools/pack.lua . > ../lib.lua

${OBJECTS}: lib.lua
	${LUAJIT_BIN} -b $@.lua $@.o

clean-deps:
	rm -rf tools/luajit
	cd deps/luajit && \
		$(MAKE) clean

	cd deps/luv && \
		$(MAKE) clean

clean:
	rm -f spook main.o lib.o lib.lua

