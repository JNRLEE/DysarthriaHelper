# This file was generated using the following command:
# ./configure --mathlib=ATLAS

CONFIGURE_VERSION := 11

# Toolchain configuration

CXX = g++
AR = ar
AS = as
RANLIB = ranlib

# Base configuration

DEBUG_LEVEL = 1
DOUBLE_PRECISION = 0
OPENFSTINC = /work/jerryfat/kaldi-trunk/tools/openfst-1.6.7/include
OPENFSTLIBS = /work/jerryfat/kaldi-trunk/tools/openfst-1.6.7/lib/libfst.so
OPENFSTLDFLAGS = -Wl,-rpath=/work/jerryfat/kaldi-trunk/tools/openfst-1.6.7/lib

CUBROOT = /work/jerryfat/kaldi-trunk/tools/cub-1.8.0
WITH_CUDADECODER = 1

ATLASINC = /work/jerryfat/kaldi-trunk/tools/ATLAS_headers/include
ATLASLIBS = /usr/lib64/atlas/libsatlas.so.3 /usr/lib64/atlas/libtatlas.so.3 -Wl,-rpath=/usr/lib64/atlas

# ATLAS specific Linux configuration

ifndef DEBUG_LEVEL
$(error DEBUG_LEVEL not defined.)
endif
ifndef DOUBLE_PRECISION
$(error DOUBLE_PRECISION not defined.)
endif
ifndef OPENFSTINC
$(error OPENFSTINC not defined.)
endif
ifndef OPENFSTLIBS
$(error OPENFSTLIBS not defined.)
endif
ifndef ATLASINC
$(error ATLASINC not defined.)
endif
ifndef ATLASLIBS
$(error ATLASLIBS not defined.)
endif

CXXFLAGS = -std=c++11 -I.. -isystem $(OPENFSTINC) -O1 $(EXTRA_CXXFLAGS) \
           -Wall -Wno-sign-compare -Wno-unused-local-typedefs \
           -Wno-deprecated-declarations -Winit-self \
           -DKALDI_DOUBLEPRECISION=$(DOUBLE_PRECISION) \
           -DHAVE_EXECINFO_H=1 -DHAVE_CXXABI_H -DHAVE_ATLAS -I$(ATLASINC) \
           -msse -msse2 -pthread \
           -g

ifeq ($(KALDI_FLAVOR), dynamic)
CXXFLAGS += -fPIC
endif

ifeq ($(DEBUG_LEVEL), 0)
CXXFLAGS += -DNDEBUG
endif
ifeq ($(DEBUG_LEVEL), 2)
CXXFLAGS += -O0 -DKALDI_PARANOID
endif

# Compiler specific flags
COMPILER = $(shell $(CXX) -v 2>&1)
ifeq ($(findstring clang,$(COMPILER)),clang)
# Suppress annoying clang warnings that are perfectly valid per spec.
CXXFLAGS += -Wno-mismatched-tags
endif

LDFLAGS = $(EXTRA_LDFLAGS) $(OPENFSTLDFLAGS) $(ATLASLDFLAGS) -rdynamic
LDLIBS = $(EXTRA_LDLIBS) $(OPENFSTLIBS) $(ATLASLIBS) -lm -lpthread -ldl

# CUDA configuration

CUDA = true
CUDATKDIR = /usr/local/cuda
CUDA_ARCH = -gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75

ifndef DOUBLE_PRECISION
$(error DOUBLE_PRECISION not defined.)
endif
ifndef CUDATKDIR
$(error CUDATKDIR not defined.)
endif

CXXFLAGS += -DHAVE_CUDA -I$(CUDATKDIR)/include -fPIC -pthread -isystem $(OPENFSTINC)

CUDA_INCLUDE= -I$(CUDATKDIR)/include -I$(CUBROOT)
CUDA_FLAGS = --machine 64 -DHAVE_CUDA \
             -ccbin $(CXX) -DKALDI_DOUBLEPRECISION=$(DOUBLE_PRECISION) \
             -std=c++11 -DCUDA_API_PER_THREAD_DEFAULT_STREAM  -lineinfo \
             --verbose -Xcompiler "$(CXXFLAGS)"

CUDA_LDFLAGS += -L$(CUDATKDIR)/lib64 -Wl,-rpath,$(CUDATKDIR)/lib64
CUDA_LDLIBS += -lcublas -lcusparse -lcudart -lcurand -lcufft -lnvToolsExt #LDLIBS : The .so libs are loaded later than static libs in implicit rule
CUDA_LDLIBS += -lcusolver

# Environment configuration

