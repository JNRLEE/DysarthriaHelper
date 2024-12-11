#!/bin/bash
. ./path.sh
. ./cmd.sh
# Copyright 
# Apache 2.0
#檢查kaldi所需的東西
#cd kaldi/tools
#extras/check_dependencies.sh

# Caution: some of the graph creation steps use quite a bit of memory, so you
# should run this on a machine that has sufficient memory.

#路徑cd到S5

test_name=Ho2
model_name=tdnnf_Augment_128_64_14_0.2_yukang

test_data=data/$test_name
test_data2=$test_data/${test_name}_iv
test_data3=$test_data/${test_name}_iv_nopitch

save_path=$test_data/PPG_$test_name

nj=1 #CPU 線程

#dos2unix $test_data3/text

echo -e "#normal_one"
utils/fix_data_dir.sh $test_data
steps/make_mfcc_pitch.sh --cmd run.pl --nj 1 --mfcc-config conf/mfcc_hires.conf $test_data $test_data2/log $test_data2/feats  || exit 1
steps/compute_cmvn_stats.sh $test_data $test_data2/log $test_data2/feats  || exit 1
utils/data/limit_feature_dim.sh 0:39 $test_data $test_data3  || exit 1
steps/compute_cmvn_stats.sh $test_data3 $test_data3/log $test_data3/feats  || exit 1

echo -e "##Extracting iVectors for testing normal_one"
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj 1 $test_data3 exp_learning/$model_name/nnet3/extractor $test_data3/ivectors  || exit 1

root=exp_learning
dir=$root/$model_name
echo -e $dir

echo -e "####PPG"
# simple PPG
steps/nnet3/chain/get_phone_post.sh --remove-word-position-dependency true --online-ivector-dir $test_data3/ivectors $dir/nnet3/tri4_biphone_tree $dir/chain data/lang_learning $test_data3 $save_path  || exit 1

# for senom
#steps/nnet3/chain/get_phone_post.sh --nj $nj --remove-word-position-dependency true --use-xent-output true --online-ivector-#dir $test_data3/ivectors exp_learning/inside/nnet3/tri4_biphone_tree exp_learning/inside/chain data/test/lang $test_data3 #exp_learning/chain/PPG_xent$test_name  || exit 1

copy-feats ark:$save_path/phone_post.1.ark ark,t:$save_path/phone_post.1.csv