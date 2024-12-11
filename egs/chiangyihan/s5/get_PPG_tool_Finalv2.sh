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
s5_root=$(pwd)
data_root=$(pwd)/data
data_subdir=final
model_root=exp_learning

get_PPG=0
get_decode=1

MFCC_dim=40
test_model=LDV_VITS_asr_16k_synldv_synnorm_trueldv_s1org_s2org_s5org_G1000000
tree_model=LDV_VITS_asr_16k_synldv_synnorm_trueldv_s1org_s2org_s5org_G1000000

test_root=LDV_Corpus
test_file=Wang_True_LDV
# test_file_subdir=Wang_real_S3_LDV/inside
test_file_subdir=Wang_test/caffeteria/n75/LDV/s70
# test_name=MFCC${MFCC_dim}


mfcc_config_path=conf/mfcc_hires.conf
# mfcc_config_path=/work/jerryfat/kaldi-trunk/egs/chiangyihan/s5/data/$test_model/conf_forfun/mfcc_hires.conf

tree_dir=$model_root/$tree_model/nnet3
lang_dir=$data_root/$tree_model/$data_subdir
model_dir=$model_root/$test_model
dir=$model_dir/chain

echo -e \\n
echo -e tree_dir ":" $tree_dir \\n
echo -e lang_dir ":" $lang_dir \\n
echo -e test_model ":" $model_dir \\n


test_data=$data_root/$test_root/$test_file/$test_file_subdir
test_data_iv=$test_data/ivectors
test_data_iv_nopitch=$test_data/nopitch

rm $test_data/cmvn.scp $test_data/feats.scp $test_data/utt2dur $test_data/utt2num_frames $test_data/frame_shift
# cp $dir/final.mdl $test_data

#test_name=ppg_S1-T1_WANG_cut
#subdir=data/test
#test_model=cva_asr_new_aug
#modelsubdir=final

#test_data=data/$test_name/$subdir
#test_data_iv=$test_data/${test_name}_iv
#test_data_iv_nopitch=$test_data/${test_name}_iv_nopitch


nj=1 #CPU 線程

#dos2unix $test_data_iv_nopitch/text

echo -e "#normal_one"
utils/fix_data_dir.sh $test_data
steps/make_mfcc_pitch.sh --cmd run.pl --nj 1 --mfcc-config $mfcc_config_path $test_data $test_data_iv/log $test_data_iv/feats  || exit 1
steps/compute_cmvn_stats.sh $test_data $test_data_iv/log $test_data_iv/feats  || exit 1
if [ $MFCC_dim -eq 13 ]; then
echo -e \\n
echo -e "MFCC_dim:" "13"
utils/data/limit_feature_dim.sh 0:12 $test_data $test_data_iv_nopitch  || exit 1
elif [ $MFCC_dim -eq 40 ]; then
echo -e \\n
echo -e "MFCC_dim:" "40"
utils/data/limit_feature_dim.sh 0:39 $test_data $test_data_iv_nopitch  || exit 1
fi
# utils/data/limit_feature_dim.sh 0:39 $test_data $test_data_iv_nopitch  || exit 1
steps/compute_cmvn_stats.sh $test_data_iv_nopitch $test_data_iv_nopitch/log $test_data_iv_nopitch/feats  || exit 1

echo -e "##Extracting iVectors for testing normal_one"
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj 1 $test_data_iv_nopitch $tree_dir/extractor $test_data_iv_nopitch/ivectors  || exit 1


if [ $get_decode -eq 1 ]; then
echo -e "####Decoding"
save_path=$test_data/decode_${test_file}
# mkdir -p $save_path
# steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf --add-pitch false $lang_dir/local/lang_chain $tree_dir/extractor ${dir} $save_path
# steps/online/nnet3/prepare_online_decoding.sh --mfcc-config $mfcc_conf_path --add-pitch false $data/local/lang_chain exp_learning/$model_name/nnet3/extractor ${dir} ${dir}_online
# steps/online/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --nj $nj --cmd run.pl $dir/graph $test_data_iv_nopitch $save_path
steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
      --nj 1 --cmd "$decode_cmd" \
      --online-ivector-dir $test_data_iv_nopitch/ivectors \
      $dir/graph $test_data_iv_nopitch $save_path || exit 1;
fi

if [ $get_PPG -eq 1 ]; then
echo -e "####PPG"
save_path=$test_data/PPG_${test_file}
# simple PPG
steps/nnet3/chain/get_phone_post.sh --remove-word-position-dependency true --online-ivector-dir $test_data_iv_nopitch/ivectors $tree_dir/tri4_biphone_tree $model_dir/chain $lang_dir/lang $test_data_iv_nopitch $save_path  || exit 1
#for senom
#steps/nnet3/chain/get_phone_post.sh --nj $nj --remove-word-position-dependency true --use-xent-output true --online-ivector-#dir $test_data_iv_nopitch/ivectors exp_learning/inside/nnet3/tri4_biphone_tree exp_learning/inside/chain data/test/lang $test_data_iv_nopitch #exp_learning/chain/PPG_xent$test_name  || exit 1
#copy-feats ark:$save_path/phone_post.1.ark ark,t:$save_path/phone_post.1.csv
fi
