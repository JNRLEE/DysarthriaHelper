#2020/01/06 SBPLAB KALDI ASR run.bash
# 韓季言 寫
#用法 1.將此檔放到S5 2.將音檔放到S5/data/wav 
#3.將text ,text_raw, lexicon放在S5 4.在命令列打 bash run.sh 5.run.sh為此檔檔名

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

data=$(pwd)/data/T_01
model=$(pwd)

nj=1 #CPU 線程


#獲取當前路徑存到data
echo "當前路徑為$data"

# Data Preparation,
#默認位置為S5中名為data的資料夾
echo -e "######Start data preparation#####"
find $data -type f -name "*.wav" > path_raw || exit 1
sort -u path_raw > $data/path || exit 1 #-u 去除重複
rm path_raw
#做完path
echo -e "path"
head -5 $data/path
echo -e "\n"

cp $data/path $data/id_raw || exit 1
sed -e 's/\.wav//' $data/id_raw | cut -d / -f 10  > $data/id  || exit 1
# 資料夾深度為8   /data2/Jerryfat/kaldi/egs/DNN/s5/data/formosa/YX_20170622_064.wav
rm $data/id_raw
#做完id
echo -e "id"
head -5 $data/id
echo -e "檢查path 和 id"
wc -l $data/path $data/id 

paste $data/id $data/path > $data/wav.scp || exit 1
paste $data/id $data/id >$data/utt2spk || exit 1
utils/utt2spk_to_spk2utt.pl $data/utt2spk > $data/spk2utt || exit 1
echo -e "wav.scp utt2spk spk2utt 做完"
utils/fix_data_dir.sh $data

#:%s/\w\+^I// 去除tab之前的文字

#dos2unix text_raw || exit 1
#paste $data/id text_raw > $data/text || exit 1
#sort $data/text

echo -e "#####End data preparation#####"

###Extract &MFCC i-vector ###
echo -e "\n#####Compute MFCC #####"
steps/make_mfcc_pitch.sh --cmd run.pl --nj $nj --mfcc-config conf/mfcc_hires.conf $data $data/log $data/feats || exit 1
utils/data/limit_feature_dim.sh 0:39 $data $data/nopitch || exit 1
steps/compute_cmvn_stats.sh $data/nopitch $data/nopitch/log $data/nopitch/feats || exit 1
echo -e "#####Compute MFCC #####\n"
echo -e "\n#####Compute i-vector#####"
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj $nj $data/nopitch $model/exp_learning/ci_test_asr2ppg_20210819/nnet3/extractor $data/nopitch/ivectors|| exit 1
echo -e "#####End ivector#####\n"

dir=$model/exp_learning/ASRRR
mkdir $model/exp_learning/${dir}
steps/online/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --nj $nj --cmd run.pl $dir/graph $data/nopitch ${dir}/decode

