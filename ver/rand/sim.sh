#!/bin/bash

TOP=jt7759

verilator -F ../../hdl/jt7759.f -cc test.cpp -exe --top-module $TOP --trace -DDEBUG
export CPPFLAGS="$CPPFLAGS -O3"


if ! make -j -C obj_dir -f V${TOP}.mk V${TOP} > make.log; then
    cat make.log
    exit $?
else
    rm make.log
fi

obj_dir/V$TOP
