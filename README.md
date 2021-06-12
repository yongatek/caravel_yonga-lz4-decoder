# YONGA-LZ4 Decoder

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

Table of contents
=================

- [Overview](#overview)
- [Running Simulation](#running-simulation)
- [Checklist for Open-MPW Two Submission](#checklist-for-open-mpw-two-submission)

Overview
========

YONGA-LZ4 Decoder is an implementation of the decoder of the popular [LZ4](https://github.com/lz4/lz4) compression algorithm.

Running Simulation
========

### Wishbone Test

* This test is meant to verify that we can read and write to the YONGA-LZ4 Decoder through the WISHBONE port. The firmware first writes a compressed data stream to input FIFO of the YONGA-LZ4 Decoder, then reads decoded data stream from output FIFO of the YONGA-LZ4 Decoder.

To run RTL simulation, 

```bash
cd $UPRJ_ROOT
make verify-wb_test
```

Checklist for Open-MPW Two Submission
=================================

-  [x] The project repo adheres to the same directory structure in this
   repo
-  [x] The project repo contain info.yaml at the project root
-  [x] Top level macro is named ``user_project_wrapper``
-  [x] Full Chip Simulation passes for RTL and GL (gate-level)
-  [x] The hardened Macros are LVS and DRC clean
-  [x] The hardened ``user_project_wrapper`` adheres to the same pin
   order specified at [pin_order](https://github.com/efabless/caravel/blob/master/openlane/user_project_wrapper_empty/pin_order.cfg)
-  [x] XOR check passes with zero total difference.
-  [x] Openlane summary reports are retained under ./signoff/
