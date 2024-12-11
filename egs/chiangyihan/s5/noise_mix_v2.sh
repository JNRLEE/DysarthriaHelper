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
nj=15 #CPU 線程

data=$(pwd)/data/LDV_Corpus/Wang_True_Mic/Wang_real_S5_Mic/n0/Mic/s70
noise=$(pwd)/data/LDV_Corpus/noise_list

result_root=$(pwd)/data/LDV_Corpus/add_noise_result
result_subdir=Wang_True_Mic/Wang_real_S5_Mic/n0/Mic/s70
result_final=$result_root/$result_subdir

echo -e "\n Target saving path:\n $result_final"

if [ ! -d "$result_final" ]; then
  echo -e "\n The target path does not exist;\n the corresponding folders will be automatically generated.\n"
  mkdir -m 755 -p $result_final
else
  echo -e "\n The target path already exist;\n subsequent instructions will be executed.\n"
fi

#獲取當前路徑存到data
echo "當前路徑為$data"

# Data Preparation,
#默認位置為S5中名為data的資料夾
echo -e "######Start data preparation#####"
utils/data/get_reco2dur.sh $data || exit 1
echo -e "reco2dur 做完"
utils/fix_data_dir.sh $data
echo -e "#####End data preparation#####"
#data preparation end ####################################
echo -e "#####start noise preparation#####"
utils/data/get_reco2dur.sh $noise || exit 1
echo -e "reco2dur 做完"
utils/fix_data_dir.sh $noise
echo -e "#####End noise preparation#####"

steps/data/augment_data_dir.py  \
--utt-suffix "noise" --fg-interval 1 \
--bg-snrs "15:10:5:0" --bg-noise-dir "$noise" \
$data $result_final  || exit 1

