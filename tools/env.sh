export IRSTLM=/work/jerryfat/kaldi-trunk/tools/irstlm
export PATH=${PATH}:${IRSTLM}/bin
export LIBLBFGS=/work/jerryfat/kaldi-trunk/tools/liblbfgs-1.10
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:${LIBLBFGS}/lib/.libs
export SRILM=/work/jerryfat/kaldi-trunk/tools/srilm
export PATH=${PATH}:${SRILM}/bin:${SRILM}/bin/i686-m64
export PATH=$PATH:/work/jerryfat/kaldi-trunk/tools/kaldi_lm
