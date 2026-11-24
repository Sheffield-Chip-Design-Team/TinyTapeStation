# Tiny Tapestation on the Digilent Nexys A7 (Vivado, batch mode).
#   make bit                         # build/tts_nexys_a7.bit, for the Nexys A7-100T
#   make bit PART=xc7a50tcsg324-1    # for the Nexys A7-50T
#   make clean
# The chip's sources come from ../../info.yaml (source_files), the same files Tiny
# Tapeout builds. Needs Vivado on PATH and Python 3 with PyYAML.

PART   ?= xc7a100tcsg324-1
ROOT   := $(abspath ../..)
SRCS   := $(shell python3 -c "import yaml; print(' '.join('$(ROOT)/src/' + f for f in yaml.safe_load(open('$(ROOT)/info.yaml'))['project']['source_files']))")

.PHONY: bit clean

bit:
	mkdir -p build
	vivado -mode batch -nojournal -log build/vivado.log -source build.tcl -tclargs $(PART) $(SRCS)

clean:
	rm -rf -- build .Xil
