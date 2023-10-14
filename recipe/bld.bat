@echo on

:: simple install prep
::   copy all warpx*.exe and warpx*.dll files
if not exist %LIBRARY_PREFIX%\bin md %LIBRARY_PREFIX%\bin
if errorlevel 1 exit 1

cmake ^
    -S %SRC_DIR% -B build                 ^
    %CMAKE_ARGS%                          ^
    -G "Ninja"                            ^
    -DCMAKE_BUILD_TYPE=Release            ^
    -DCMAKE_C_COMPILER=clang-cl           ^
    -DCMAKE_CXX_COMPILER=clang-cl         ^
    -DCMAKE_LINKER=lld-link               ^
    -DCMAKE_NM=llvm-nm                    ^
    -DCMAKE_VERBOSE_MAKEFILE=ON           ^
    -DPYINSTALLOPTIONS="--no-build-isolation"  ^
    -DPython_EXECUTABLE=%PYTHON%          ^
    -DpyAMReX_pybind11_internal=OFF       ^
    -DWarpX_amrex_repo=https://github.com/ax3l/amrex.git  ^
    -DWarpX_amrex_branch=fix-realvect-static-export  ^
    -DWarpX_pyamrex_repo=https://github.com/ax3l/pyamrex.git  ^
    -DWarpX_pyamrex_branch=topic-pip-nodeps  ^
    -DWarpX_ASCENT=OFF  ^
    -DWarpX_PYTHON=ON   ^
    -DWarpX_MPI=OFF     ^
    -DWarpX_OPENPMD=ON  ^
    -DWarpX_openpmd_internal=OFF ^
    -DWarpX_PSATD=ON    ^
    -DWarpX_QED=ON      ^
    -DWarpX_DIMS="1;2;RZ;3"
if errorlevel 1 exit 1

cmake --build build --config Release --parallel 2
if errorlevel 1 exit 1

:: install (libs)
cmake --build build --config Release --target install
if errorlevel 1 exit 1

for /r "build\bin" %%f in (*.exe) do (
    echo %%~nf
    dir
    copy build\bin\%%~nf.exe %LIBRARY_PREFIX%\bin\
    if errorlevel 1 exit 1
)
for /r "build\lib" %%f in (*.dll) do (
    echo %%~nf
    dir
    copy build\lib\%%~nf.dll %LIBRARY_PREFIX%\lib\
    if errorlevel 1 exit 1
)

rmdir /s /q build
:: future (if skipping AMReX headers) - inside above loop
::  cmake --build build --config Release --target install
::  if errorlevel 1 exit 1

:: add Python API (PICMI interface)
cmake --build build --config Release --target pyamrex_pip_install_nodeps
if errorlevel 1 exit 1

cmake --build build --config Release --target pip_install_nodeps
if errorlevel 1 exit 1
