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
test_data=data/ppg_hanhan_and_yating2wang/data/test                #change ppg
test_data2=data/ppg_hanhan_and_yating2wang/test/ci_iv         #change ppg
test_data3=data/ppg_hanhan_and_yating2wang/test/ci_iv_nopitch #change ppg
test_name=ppg_hanhan_and_yating2wang                             #change ppg
model_name=ppg_hanhan_and_yating2wang                        #change asr model
nj=1 #CPU 線程

#dos2unix $test_data3/text

utils/fix_data_dir.sh $test_data
#i-vector
echo -e "#normal_one"
steps/make_mfcc_pitch.sh --cmd run.pl --nj 1 --mfcc-config conf/mfcc_hires.conf $test_data $test_data2/log $test_data2/feats  || exit 1
steps/compute_cmvn_stats.sh $test_data $test_data2/log $test_data2/feats  || exit 1
utils/data/limit_feature_dim.sh 0:39 $test_data $test_data3  || exit 1
steps/compute_cmvn_stats.sh $test_data3 $test_data3/log $test_data3/feats  || exit 1


#echo -e "####Training the iVector extractor"
#steps/online/nnet2/train_ivector_extractor.sh --cmd run.pl --nj $nj --num-processes 1 $data3 exp_learning/$model_name/nnet3/extractor  || exit 1 

echo -e "##Extracting iVectors for testing normal_one"
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj 1 $test_data3 exp_learning/$model_name/nnet3/extractor $test_data3/ivectors  || exit 1

dir=exp_learning/$model_name/chain

#echo -e "#Online outside decoding normal_one"
steps/online/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --nj 1 --cmd run.pl $dir/graph $test_data3 exp_learning/$model_name/chain_online/decode_$test_name  || exit 1     #####outside

echo -e "####PPG"
#(生成ppg 圖像)
steps/nnet3/chain/get_phone_post.sh --nj $nj --remove-word-position-dependency true --online-ivector-dir $test_data3/ivectors exp_learning/$model_name/nnet3/tri4_biphone_tree exp_learning/$model_name/chain data/$model_name/data/test/lang $test_data3 exp_learning/chain/PPG_$test_name  || exit 1
#steps/nnet3/chain/get_phone_post.sh --nj 1 --remove-word-position-dependency true --use-xent-output true --online-ivector-dir data/ones/ivector exp_learning/inside/nnet3/tri4_biphone_tree exp_learning/inside/chain data/test/lang data/ones/mfcc exp_learning/chain/PPG_xent_ones  || exit 1
#steps/nnet3/chain/get_phone_post.sh --nj $nj --remove-word-position-dependency true --use-xent-output true --online-ivector-dir $test_data3/ivectors exp_learning/ci_asr_288_combine/nnet3/tri4_biphone_tree $dir data/ci_asr_288_combine_dtw/data/test/lang $test_data3 exp_learning/chain/PPG_xent_$test_name  || exit 1

echo -e "#Online outside decoding"
#(生成decode準確度)
steps/online/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --nj 1 --cmd run.pl $dir/graph $test_data3 ${dir}_online/decode_$test_name  || exit 1

