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
data=$(pwd)/data/cva_asr_new_aug2/final  #change
data_root=$(pwd)/data/cva_asr_new_aug2
model_name=cva_asr_new_aug2                  #change
nj=10 #CPU 線程
passward=qwertyuiop #使用者密碼

#獲取當前路徑存到data
echo "當前路徑為$data"

# 製作Subset for inside test
# utils/subset_data_dir.sh $data_root/raw 200 $data_root/raw/inside_test || exit 1

# dos2unix $data_root/raw/text || exit 1               #change
# dos2unix $data_root/raw/inside_test/text || exit 1    #change

# utils/fix_data_dir.sh $data_root
# echo -e "#####End data preparation#####"
#data preparation end ####################################

##Creating neural network config using the xconfig 
xent_regularize=0.1
num_targets=$(tree-info exp_learning/$model_name/nnet3/tri4_biphone_tree/tree | grep num-pdfs | awk '{print $2}') || exit 1
learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python) || exit 1
affine_opts="l2-regularize=0.0005 dropout-proportion=0.0 dropout-per-dim=true dropout-per-dim-continuous=true" || exit 1
tdnnf_opts="l2-regularize=0.0005 dropout-proportion=0.2 bypass-scale=0.75" || exit 1
linear_opts="l2-regularize=0.005 orthonormal-constraint=-1.0" || exit 1
prefinal_opts="l2-regularize=0.0005" || exit 1
output_opts="l2-regularize=0.00005" || exit 1

# dir=exp_learning/$model_name/chain 
dir=exp_learning/cva_asr_new_aug_s20/chain 

mkdir -p $dir/configs || exit 1

#echo $passward | sudo -S rm exp_learning/inside/chain/configs/network.xconfig
bash -c "cat > $dir/configs/network.xconfig" <<EOF
  input dim=100 name=ivector
  input dim=40 name=input
  
  ##二擇一
  ##1
  fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat
  ##2
  #據說避免 Over-fitting
  #idct-layer name=idct input=input dim=40 cepstral-lifter=22 affine-transform-file=$dir/configs/idct.mat
  #batchnorm-component name=batchnorm0 input=idct
  #spec-augment-layer name=spec-augment freq-max-proportion=0.5 time-zeroed-proportion=0.2 time-mask-max-frames=20
  #delta-layer name=delta input=spec-augment
  #no-op-component name=input2 input=Append(delta, Scale(0.4, ReplaceIndex(ivector, t, 0)))
  
  
  # the first splicing is moved before the lda layer, so no splicing here
  #幾層NN
  relu-batchnorm-dropout-layer name=tdnn1 $affine_opts dim=128 
  tdnnf-layer name=tdnnf2 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf3 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf4 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf5 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf6 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf7 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf8 $tdnnf_opts dim=128 bottleneck-dim=70 time-stride=20
  tdnnf-layer name=tdnnf9 $tdnnf_opts dim=128 bottleneck-dim=60 time-stride=20
  tdnnf-layer name=tdnnf10 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf11 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf12 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf13 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  tdnnf-layer name=tdnnf14 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  #tdnnf-layer name=tdnnf15 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20
  #tdnnf-layer name=tdnnf16 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=20

  linear-component name=prefinal-l dim=128 $linear_opts
  
  prefinal-layer name=prefinal-chain input=prefinal-l $prefinal_opts big-dim=128 small-dim=64
  output-layer name=output include-log-softmax=false dim=$num_targets $output_opts
  
  prefinal-layer name=prefinal-xent input=prefinal-l $prefinal_opts big-dim=128 small-dim=64
  output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts
EOF

#15~3
steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs || exit 1

train_stage=-10 || exit 1
train_ivector_dir=$data/nopitch/ivectors || exit 1
common_egs_dir=
get_egs_stage=-10 || exit 1
frames_per_eg=50 || exit 1
dropout_schedule='0,0@0.20,0.5@0.50,0' || exit 1
remove_egs=true
train_data_dir=$data/nopitch || exit 1
tree_dir=exp_learning/$model_name/nnet3/tri4_biphone_tree || exit 1
lat_dir=exp_learning/$model_name/lats || exit 1

##### nnet3 參數調整###
batch=200
epoch=5
num_jub_ini=1
num_jub_fin=2
###################$##

steps/nnet3/chain/train.py --stage $train_stage \
    --cmd run.pl \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.0 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --egs.dir "$common_egs_dir" \
    --egs.stage $get_egs_stage \
    --egs.opts "--frames-overlap-per-eg 0 --constrained false" \
    --egs.chunk-width $frames_per_eg \
    --trainer.dropout-schedule $dropout_schedule \
    --trainer.add-option="--optimization.memory-compression-level=2" \
    --trainer.num-chunk-per-minibatch $batch \
    --trainer.frames-per-iter 2500000 \
    --trainer.num-epochs $epoch \
    --trainer.optimization.num-jobs-initial $num_jub_ini \
    --trainer.optimization.num-jobs-final $num_jub_fin \
    --trainer.optimization.initial-effective-lrate 0.02 \
    --trainer.optimization.final-effective-lrate 0.0002 \
    --trainer.max-param-change 2.0 \
    --cleanup.remove-egs $remove_egs \
    --feat-dir $train_data_dir \
    --tree-dir $tree_dir \
    --lat-dir $lat_dir \
	--use-gpu=wait \
    --dir $dir || exit 1

#Build graph for decoding
utils/mkgraph.sh --self-loop-scale 1.0 $data/local/lang_chain $dir $dir/graph || exit 1
steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf --add-pitch false $data/local/lang_chain exp_learning/$model_name/nnet3/extractor ${dir} ${dir}_online

steps/online/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --nj $nj --cmd run.pl $dir/graph $data/nopitch_inside ${dir}_online/decode
