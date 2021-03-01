#!/bin/bash

. ../common.bash rt

SOURCES="RiRuntimeTest.v3"
EXE=RiRuntimeTest
N=$VIRGIL_LOC/rt/native
RT_SOURCES="$N/RiRuntime.v3 $N/NativeStackPrinter.v3 $N/NativeFileStream.v3"

function do_test() {
    set_os_sources $target
    T=$OUT/$target
    mkdir -p $T

    print_compiling "$target" RiRuntimeTest
    run_v3c $target -output=$T $SOURCES &> $T/compile.out
    check_no_red $? $T/compile.out

    print_compiling "$target-rt" RiRuntimeTest
    run_v3c "" -target=$target -output=$T -heap-size=1k -rt.sttables $SOURCES $OS_SOURCES $RT_SOURCES &> $T/rt.compile.out
    check_no_red $? $T/rt.compile.out

    print_compiling "$target-gc" RiRuntimeTest
    run_v3c "" -target=$target -output=$T -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $RT_SOURCES $GC_SOURCES &> $T/gc.compile.out
    check_no_red $? $T/gc.compile.out

    print_compiling "$target" CiRuntimeApi
    run_v3c $target -output=$T CiRuntimeApi.v3 &> $T/compile.out
    check_no_red $? $T/compile.out

    print_compiling "$target" FindFunc
    run_v3c $target -output=$T FindFunc.v3 &> $T/find.compile.out
    check_no_red $? $T/find.compile.out

    if [ -f "jit-${target}.v3" ]; then
	print_compiling "$target" JIT
	run_v3c $target -output=$T jit-$target.v3 &> $T/jit.compile.out
	check_no_red $? $T/jit.compile.out
    fi

    if [ -x $CONFIG/run-$target ]; then
	print_status Running "$target" CiRuntimeApi
	$T/CiRuntimeApi &> $T/run.out
	check $?

	print_status Running "$target" FindFunc
	$T/FindFunc &> $T/find.run.out
	check $?

	if [ -x $T/jit-$target ]; then
	    print_status Running "$target" JIT
	    $T/jit-$target &> $T/jit.run.out
	    check $?
	fi
    else
	print_status Running "$target"
	echo "${YELLOW}skipped${NORM}"
    fi
}

for target in $TEST_TARGETS; do
    if [ "$target" = x86-darwin ]; then
        do_test
    elif [ "$target" = x86-linux ]; then
        do_test
    elif [ "$target" = x86-64-linux ]; then
        do_test
    fi
done
