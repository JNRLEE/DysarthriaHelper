#!/bin/bash
. ./path.sh
. ./cmd.sh
# Copyright 
# Apache 2.0
#檢查kaldi所需的東西
#cd kaldi/tools
#extras/check_dependencies.sh

#要手動將exp/chain/tdnn_1d_sp/final.mdl 拷貝到
#路徑cd到S5

data=data/CCC_retrain/test_raw/XieWL/test_1
model_root=exp_learning
model_name=CCC_retrain
dir=exp_learning/CCC_retrain
graph_dir=$dir/chain/graph
extractor_dir=$dir/nnet3/extractor
nj=1
cp $dir/chain/final.mdl $data

echo -e "\n#####Compute MFCC #####"
steps/make_mfcc_pitch.sh --cmd run.pl --nj $nj --mfcc-config conf/mfcc_hires.conf $data $data/log $data/feats || exit 1
utils/data/limit_feature_dim.sh 0:39 $data $data/nopitch || exit 1
steps/compute_cmvn_stats.sh $data/nopitch $data/nopitch/log $data/nopitch/feats || exit 1
echo -e "#####Compute MFCC #####\n"

echo -e "\n#####Compute i-vector#####"
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj $nj $data/nopitch \
$extractor_dir \
$data/ivectors || exit 1
echo -e "#####End ivector#####\n\n"

steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
      --nj 1 --cmd "$decode_cmd" \
      --online-ivector-dir $data/ivectors \
      $graph_dir $data/nopitch $data/decode || exit 1;