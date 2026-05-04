#!/bin/bash

# ------------------------------------------------------------
# AXI4-Lite UVM VIP Regression Script
# ------------------------------------------------------------

echo "=================================================="
echo " AXI4-Lite UVM Regression Started"
echo "=================================================="

# Go to sim directory
cd ../sim || exit 1

# Clean old files
echo "[INFO] Cleaning old simulation files..."
rm -rf simv simv.daidir csrc *.log ucli.key DVEfiles

# Compile
echo "[INFO] Compiling UVM testbench..."
vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps -f filelist.f -l compile_uvm.log

if [ $? -ne 0 ]; then
  echo "[FAIL] Compilation failed. Check sim/compile_uvm.log"
  exit 1
fi

echo "[PASS] Compilation successful"

# List of tests
tests=(
  axi4_lite_basic_test
  axi4_lite_multi_reg_test
  axi4_lite_invalid_addr_test
  axi4_lite_wstrb_test
  axi4_lite_random_test
)

pass_count=0
fail_count=0

# Run each test
for test in "${tests[@]}"
do
  log_file="${test}.log"

  echo "--------------------------------------------------"
  echo "[INFO] Running $test"
  echo "--------------------------------------------------"

  ./simv +UVM_TESTNAME=$test -l $log_file

  if grep -q "UVM_ERROR :    0" $log_file && grep -q "UVM_FATAL :    0" $log_file; then
    echo "[PASS] $test"
    pass_count=$((pass_count + 1))
  else
    echo "[FAIL] $test"
    fail_count=$((fail_count + 1))
  fi
done

echo "=================================================="
echo " Regression Summary"
echo "=================================================="
echo " Passed: $pass_count"
echo " Failed: $fail_count"
echo "=================================================="

if [ $fail_count -eq 0 ]; then
  echo " ALL TESTS PASSED"
  exit 0
else
  echo " SOME TESTS FAILED"
  exit 1
fi