#include <stdio.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "uv.h"
#include "luv.h"

int main(int argc, char **argv)
{
  int status;
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  lua_newtable(L);
  int i;
  for(i = 0; i < argc; i++)
  {
    lua_pushinteger(L, i + 1);
    lua_pushstring(L, argv[i]);
    lua_settable(L, -3);
  }
  lua_setglobal(L, "argv");

  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_remove(L, -2); // Remove package
  // Store uv module definition at preload.uv
  lua_pushcfunction(L, luaopen_luv);
  lua_setfield(L, -2, "uv");
  lua_getglobal(L, "require");
  lua_pushliteral(L, "main");
  status = lua_pcall(L, 1, 0, 0);
  if (status) {
    fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
    return 1;
  }
  return 0;
}
