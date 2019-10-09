
set APP_DIR=%~dp0..

if not exist %APP_DIR%\lua_classes goto SRC

ren %APP_DIR%\lua_src_compiled lua
rd /s /q %APP_DIR%\lua_src
rd /s /q %APP_DIR%\lua_classes

goto END

:SRC
Your Lua code has not been compiled. Launch compile to do that.

:END
