:: !!! Use only Java8

set SCRIPT_DIR=%~dp0..
set APP_DIR=%~dp0..
set JAVA_HOME=C:\progra~1\Java\jdk1.8.0_131

if exist %APP_DIR%\lua_classes goto BIN
mkdir %APP_DIR%\lua_classes

cd %APP_DIR%

set JAVA_OPTS=-cp %~dp0luaj-jse-2.0.3.jar;%~dp0bcel-5.2.jar
%JAVA_HOME%\bin\java %JAVA_OPTS% luajc -l -s %APP_DIR%\ -d %APP_DIR%\lua_classes lua\*
for %%p in (configurator, configurator/const, configurator/MetaModels, interpreter, plugin_mechanism, repo_browser, reporter, testing, traits) do %JAVA_HOME%\bin\java %JAVA_OPTS% luajc -l -s %APP_DIR% -d %APP_DIR%\lua_classes -p %%p ..\lua\%%p\*

%JAVA_HOME%\bin\java %JAVA_OPTS% luajc -l -s %APP_DIR%\ -d %APP_DIR%\lua_classes lua\libs\*
for %%p in (busted, busted/languages, busted/output, luassert, luassert/formatters, luassert/languages, socket, xavante) do %JAVA_HOME%\bin\java %JAVA_OPTS% luajc -l -s %APP_DIR%\ -d %APP_DIR%\lua_classes -p %%p ..\lua\libs\%%p\*

for /D %%d in (%APP_DIR%\lua_classes\*.*) do rd /s /q %%d

:: LuLPeg does not work with compiled Lua classes
del %APP_DIR%\lua_classes\LuLPeg*.class
mkdir %APP_DIR%\lua_src
copy %~dp0LuLPeg.lua %APP_DIR%\lua_src\

ren %APP_DIR%\lua lua_src_compiled

cd %SCRIPT_DIR
echo current: %CD%

goto END

:BIN
echo Your Lua code has been already compiled. Launch uncompile to clean up.

:END
