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

Step1_Data_Aug=1
Step2_LM_Pre=1
Step3_Lexicon_Pre=1
Step4_Subset_Aug_Pre=1
Step5_MFCC_Extract=1
Step6_Mono_train=1
Step7_Triphone_train=1
Step8_I_vector_Extract=1
Step9_Subset_final_Pre=1
Step10_TDNN_Pre=1
Step11_TDNN_train=1
Step12_Decoding=1

model_name=Wang_real_addnoise_LDV_caffeteria_n65_LDV_s60  
#路徑cd到S5
mfcc_conf_path=/work/jerryfat/kaldi-trunk/egs/chiangyihan/s5/data/LDV_VITS_asr/conf_forfun/mfcc_hires.conf
s5_root=$(pwd)
data=$(pwd)/data/TrainingData/${model_name}/final #change
data_root=$(pwd)/data/TrainingData/${model_name} 
               #change
nj=2 #CPU 線程
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

if [ $Step1_Data_Aug -eq 1 ]; then
echo -e "#####Start Augmentatiom preparation#####"
cd /work/jerryfat/kaldi-trunk/egs/chiangyihan/s5
utils/data/perturb_data_dir_speed_3way.sh $data_root/raw $data_root/speed
steps/nnet2/get_perturbed_feats.sh --feature-type mfcc conf/mfcc_hires.conf $data_root/perturb/mfcc $data_root/perturb/mfcc_perturb $data_root/speed $data_root/perturb/mfcc_dataset
# steps/nnet2/get_perturbed_feats.sh --feature-type mfcc $mfcc_conf_path $data_root/perturb/mfcc $data_root/perturb/mfcc_perturb $data_root/speed $data_root/perturb/mfcc_dataset

rm $data_root/perturb/mfcc_dataset-0.9-0.9/frame_shift
rm $data_root/perturb/mfcc_dataset-0.95-1.1/frame_shift
rm $data_root/perturb/mfcc_dataset-1.0-0.8/frame_shift
rm $data_root/perturb/mfcc_dataset-1.05-1.2/frame_shift
rm $data_root/perturb/mfcc_dataset-1.1-1.0/frame_shift
	
#combine mfcc augmentaion
utils/data/combine_data.sh $data_root/perturb/mfcc_dataset $data_root/perturb/mfcc_dataset-0.9-0.9 $data_root/perturb/mfcc_dataset-0.95-1.1 $data_root/perturb/mfcc_dataset-1.0-0.8 $data_root/perturb/mfcc_dataset-1.05-1.2 $data_root/perturb/mfcc_dataset-1.1-1.0

#combine all 
utils/data/combine_data.sh $data $data_root/perturb/mfcc_dataset $data_root/raw $data_root/speed
echo -e "#####End Augmentatiom preparation#####"
#augmentatiom end ###################################
fi

if [ $Step2_LM_Pre -eq 1 ]; then
echo -e "#####Start LM preparation#####"
cd $data_root
dos2unix *
cd $data
dos2unix *
mkdir -p local 
mkdir -p ./local/lm_learning
cd $s5_root #cd S5
cp $data_root/raw/text_raw $data/local/lm_learning/text_raw || exit 1
cd $data/local/lm_learning
ngram-count -order 3 -write-vocab vocab-full.txt -wbdiscount -text text_raw -lm lm.gz || exit 1
gunzip -q -f lm.gz || exit 1
ngram-count -order 3 -write-vocab vocab-full.txt -wbdiscount -text text_raw -lm lm.gz
echo "當前路徑為$(pwd)"
echo -e "#####End LM preparation#####"
#LM preparation end ####################################
fi

if [ $Step3_Lexicon_Pre -eq 1 ]; then
### dict Start###
echo -e "#####Start lexicon preparation#####"
echo "當前路徑為$(pwd)"
cd ../ #cd local
mkdir -p dict_learning
cp $data_root/lexicon.txt dict_learning/lexicon.txt || exit 1
dos2unix /work/jerryfat/kaldi-trunk/egs/chiangyihan/s5/data/cva_asr/data/test/local/dict_learning/lexicon.txt || exit 1 #change
cd dict_learning
echo SIL > silence_phones.txt || exit 1
echo SIL > optional_silence.txt || exit 1
grep -v -w sil lexicon.txt | awk '{for(n=2;n<=NF;n++) { p[$n]=1; }} END{for(x in p) {print x}}' | sort > nonsilence_phones.txt || exit 1 
dos2unix /work/jerryfat/kaldi-trunk/egs/chiangyihan/s5/data/cva_asr/data/test/local/dict_learning/nonsilence_phones.txt || exit 1  #change
echo -e "<unk>\tSIL" >> lexicon.txt  || exit 1
cd $s5_root #cd S5

utils/prepare_lang.sh $data/local/dict_learning '<unk>' $data/local/lang_learning $data/lang || exit 1
utils/format_lm.sh $data/lang $data/local/lm_learning/lm.gz $data/local/dict_learning/lexicon.txt $data/local/lang_test_learning || exit 1


echo -e "######End lexicon preparation######"
### dict End###
fi

if [ $Step4_Subset_Aug_Pre -eq 1 ]; then
# 製作增量後Subset for inside test #1000
# utils/subset_data_dir.sh $data_root/raw 1000 $data/inside_test || exit 1 
utils/subset_data_dir.sh $data_root/raw 50 $data/inside_test || exit 1 

dos2unix $data/text || exit 1               #change
dos2unix $data/inside_test/text || exit 1    #change

utils/fix_data_dir.sh $data
# 製作Over
fi

if [ $Step5_MFCC_Extract -eq 1 ]; then

### features extraction###
echo -e "#####Compute MFCC for training#####"
steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --nj $nj --cmd run.pl $data $data/log $data/feats || exit 1
# steps/make_mfcc.sh --mfcc-config $mfcc_conf_path --nj $nj --cmd run.pl $data $data/log $data/feats || exit 1
echo -e "#####Compute CMVN for training#####"
steps/compute_cmvn_stats.sh $data $data/log $data/feats || exit 1 #正規化
echo -e "#####Compute MFCC for Inside testing#####"
steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --nj $nj --cmd run.pl $data/inside_test $data/inside_test/log $data/inside_test/feats || exit 1
# steps/make_mfcc.sh --mfcc-config $mfcc_conf_path --nj $nj --cmd run.pl $data/inside_test $data/inside_test/log $data/inside_test/feats || exit 1
echo -e "#####Compute CMVN for Inside testing#####"
steps/compute_cmvn_stats.sh $data/inside_test $data/inside_test/log $data/inside_test/feats || exit 1 #正規化
utils/fix_data_dir.sh $data
cd $s5_root #cd S5
echo -e "#####Finish feature extracion#####"
### features extraction end###
fi

if [ $Step6_Mono_train -eq 1 ]; then
### Monophone start###
steps/train_mono.sh --cmd run.pl --nj $nj $data $data/local/lang_test_learning exp_learning/$model_name/mono || exit 1  #與train_mono.sh差別在beam (當音檔較大時調整)
utils/mkgraph.sh $data/local/lang_test_learning exp_learning/$model_name/mono exp_learning/$model_name/mono/graph || exit 1
echo -e "\n#####Start Decode #####"
steps/decode.sh --cmd run.pl --nj $nj --config conf/decode.config exp_learning/$model_name/mono/graph $data/inside_test exp_learning/$model_name/mono/decode || exit 1
echo -e "#####End Decode #####\n"
steps/align_si.sh --cmd run.pl --nj $nj $data $data/local/lang_test_learning exp_learning/$model_name/mono exp_learning/$model_name/mono_ali || exit 1
### Monophone End###
fi

if [ $Step7_Triphone_train -eq 1 ]; then
##Triphone DELTA start###
 steps/train_deltas.sh --cmd run.pl 2500 20000 $data $data/local/lang_test_learning exp_learning/$model_name/mono_ali exp_learning/$model_name/tri1 || exit 1
 utils/mkgraph.sh $data/local/lang_test_learning exp_learning/$model_name/tri1 exp_learning/$model_name/tri1/graph || exit 1
echo -e "\n#####Start Decode #####"
 steps/decode.sh --cmd run.pl --nj $nj --config conf/decode.config exp_learning/$model_name/tri1/graph $data/inside_test exp_learning/$model_name/tri1/decode_DELTA || exit 1
echo -e "#####End Decode #####\n"
 steps/align_si.sh --cmd run.pl --nj $nj $data $data/local/lang_test_learning exp_learning/$model_name/tri1 exp_learning/$model_name/tri1_ali || exit 1
##Triphone DELTA End###

##Triphone DELTA+DELTA+DELTA start###
 steps/train_deltas.sh --cmd run.pl 2500 20000 $data $data/local/lang_test_learning exp_learning/$model_name/tri1_ali exp_learning/$model_name/tri2 || exit 1
 utils/mkgraph.sh $data/local/lang_test_learning exp_learning/$model_name/tri2 exp_learning/$model_name/tri2/graph || exit 1
echo -e "\n#####Start Decode #####"
 steps/decode.sh --cmd run.pl --nj $nj --config conf/decode.config exp_learning/$model_name/tri2/graph $data/inside_test exp_learning/$model_name/tri2/decode_DELTA3 || exit 1
echo -e "#####End Decode #####\n"
 steps/align_si.sh --cmd run.pl --nj $nj $data $data/local/lang_test_learning exp_learning/$model_name/tri2 exp_learning/$model_name/tri2_ali || exit 1

##Triphone LDA+MLLT start##
 steps/train_lda_mllt.sh --cmd run.pl 2500 20000 $data $data/local/lang_test_learning exp_learning/$model_name/tri2_ali exp_learning/$model_name/tri3 || exit 1
 utils/mkgraph.sh $data/local/lang_test_learning exp_learning/$model_name/tri3 exp_learning/$model_name/tri3/graph || exit 1
 steps/decode.sh --cmd run.pl --nj $nj --config conf/decode.config exp_learning/$model_name/tri3/graph $data/inside_test exp_learning/$model_name/tri3/decode_LDA || exit 1
 steps/align_fmllr.sh --cmd run.pl --nj $nj $data $data/local/lang_test_learning exp_learning/$model_name/tri3 exp_learning/$model_name/tri3_ali || exit 1
##Triphone LDA+MLLT End###

##Triphone SAT start###
 steps/train_sat.sh --cmd run.pl 3500 100000 $data $data/local/lang_test_learning exp_learning/$model_name/tri3_ali exp_learning/$model_name/tri4 || exit 1
 utils/mkgraph.sh $data/local/lang_test_learning exp_learning/$model_name/tri4 exp_learning/$model_name/tri4/graph || exit 1
echo -e "\n#####Start Decode #####"
 steps/decode_fmllr.sh --cmd run.pl --nj $nj --config conf/decode.config exp_learning/$model_name/tri4/graph $data/inside_test exp_learning/$model_name/tri4/decode_SAT || exit 1
echo -e "#####End Decode #####\n"
 steps/align_fmllr.sh --cmd run.pl --nj $nj $data $data/local/lang_test_learning exp_learning/$model_name/tri4 exp_learning/$model_name/tri4_ali || exit 1
##Triphone DELTA End###
fi

if [ $Step8_I_vector_Extract -eq 1 ]; then
###Extract i-vector ###
echo -e "#####Compute Pitch#####"
utils/fix_data_dir.sh $data
steps/make_mfcc_pitch.sh --cmd run.pl --nj $nj --mfcc-config conf/mfcc_hires.conf $data $data/log $data/feats || exit 1
utils/fix_data_dir.sh $data
steps/make_mfcc_pitch.sh --cmd run.pl --nj $nj --mfcc-config conf/mfcc_hires.conf $data $data/log $data/feats || exit 1
# steps/make_mfcc_pitch.sh --cmd run.pl --nj $nj --mfcc-config $mfcc_conf_path $data $data/log $data/feats || exit 1
utils/data/limit_feature_dim.sh 0:39 $data $data/nopitch || exit 1
steps/compute_cmvn_stats.sh $data/nopitch $data/nopitch/log $data/nopitch/feats || exit 1


##Train i-Vector
##Computing a PCA transform from the hires data."
steps/online/nnet2/get_pca_transform.sh --cmd run.pl --splice-opts "--left-context=3 --right-context=3" --max-utts 10000 --subsample 2 $data/nopitch exp_learning/$model_name/nnet3/pca_transform|| exit 1
##Training the diagonal UBM. Use 512 Gaussians in the UBM.
steps/online/nnet2/train_diag_ubm.sh --cmd run.pl --nj $nj --num-frames 700000 --num-threads 16 $data/nopitch 128 exp_learning/$model_name/nnet3/pca_transform exp_learning/$model_name/nnet3/diag_ubm|| exit 1 #若資料量大128可以調成512
##Training the iVector extractor"
steps/online/nnet2/train_ivector_extractor.sh --cmd run.pl --nj $nj --num-processes 1 $data/nopitch exp_learning/$model_name/nnet3/diag_ubm exp_learning/$model_name/nnet3/extractor|| exit 1
##Extracting iVectors for training
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj $nj $data/nopitch exp_learning/$model_name/nnet3/extractor $data/nopitch/ivectors || exit 1
fi

if [ $Step9_Subset_final_Pre -eq 1 ]; then
##製作Subset for inside test
utils/subset_data_dir.sh $data/nopitch 250 $data/nopitch_inside || exit 1
steps/online/nnet2/extract_ivectors_online.sh --cmd run.pl --nj $nj $data/nopitch_inside exp_learning/$model_name/nnet3/extractor $data/nopitch_inside/ivectors || exit 1
fi

if [ $Step10_TDNN_Pre -eq 1 ]; then
##Prepare for chain model training
cp -r $data/local/lang_test_learning $data/local/lang_chain|| exit 1
silphonelist=$(cat $data/local/lang_chain/phones/silence.csl)|| exit 1
nonsilphonelist=$(cat $data/local/lang_chain/phones/nonsilence.csl)|| exit 1
#chmod -R 777 $data/local/lang_chain || exit 1
steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist > $data/local/lang_chain/topo|| exit 1

##Get alignment as lattice
steps/align_fmllr_lats.sh --nj $nj --cmd run.pl $data/nopitch $data/local/lang_test_learning exp_learning/$model_name/tri4 exp_learning/$model_name/lats|| exit 1
##Build tree
steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 --context-opts "--context-width=2 --central-position=1" --cmd run.pl 4200 $data/nopitch $data/local/lang_chain exp_learning/$model_name/tri4_ali exp_learning/$model_name/nnet3/tri4_biphone_tree|| exit 1
fi

if [ $Step11_TDNN_train -eq 1 ]; then
##Creating neural network config using the xconfig 
xent_regularize=0.1
num_targets=$(tree-info exp_learning/$model_name/nnet3/tri4_biphone_tree/tree | grep num-pdfs | awk '{print $2}') || exit 1
learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python) || exit 1
affine_opts="l2-regularize=0.0005 dropout-proportion=0.0 dropout-per-dim=true dropout-per-dim-continuous=true" || exit 1
tdnnf_opts="l2-regularize=0.0005 dropout-proportion=0.2 bypass-scale=0.75" || exit 1
linear_opts="l2-regularize=0.005 orthonormal-constraint=-1.0" || exit 1
prefinal_opts="l2-regularize=0.0005" || exit 1
output_opts="l2-regularize=0.00005" || exit 1

dir=exp_learning/$model_name/chain 

mkdir -p $dir/configs || exit 1

#echo $passward | sudo -S rm exp_learning/inside/chain/configs/network.xconfig
bash -c "cat > $dir/configs/network.xconfig" <<EOF
  input dim=100 name=ivector
  input dim=40 name=input
  
  ##two pick one
  ##1
  #fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat
  ##2
  #prevent Over-fitting
  idct-layer name=idct input=input dim=40 cepstral-lifter=22 affine-transform-file=$dir/configs/idct.mat
  batchnorm-component name=batchnorm0 input=idct
  spec-augment-layer name=spec-augment freq-max-proportion=0.5 time-zeroed-proportion=0.2 time-mask-max-frames=20
  delta-layer name=delta input=spec-augment
  no-op-component name=input2 input=Append(delta, Scale(0.4, ReplaceIndex(ivector, t, 0)))
  
  
  # the first splicing is moved before the lda layer, so no splicing here
  #How Many Layer
  relu-batchnorm-dropout-layer name=tdnn1 $affine_opts dim=128 
  tdnnf-layer name=tdnnf2 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  tdnnf-layer name=tdnnf3 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  tdnnf-layer name=tdnnf4 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  tdnnf-layer name=tdnnf5 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  tdnnf-layer name=tdnnf6 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  tdnnf-layer name=tdnnf7 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  tdnnf-layer name=tdnnf8 $tdnnf_opts dim=128 bottleneck-dim=70 time-stride=14
  tdnnf-layer name=tdnnf9 $tdnnf_opts dim=128 bottleneck-dim=60 time-stride=14
  tdnnf-layer name=tdnnf10 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  tdnnf-layer name=tdnnf11 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  #tdnnf-layer name=tdnnf12 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  #tdnnf-layer name=tdnnf13 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  #tdnnf-layer name=tdnnf14 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  #tdnnf-layer name=tdnnf15 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14
  #tdnnf-layer name=tdnnf16 $tdnnf_opts dim=128 bottleneck-dim=80 time-stride=14

  linear-component name=prefinal-l dim=128 $linear_opts
  
  prefinal-layer name=prefinal-chain input=prefinal-l $prefinal_opts big-dim=128 small-dim=64
  output-layer name=output include-log-softmax=false dim=$num_targets $output_opts
  
  prefinal-layer name=prefinal-xent input=prefinal-l $prefinal_opts big-dim=128 small-dim=64
  output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts
EOF


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
num_jub_fin=1
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
fi

if [ $Step12_Decoding -eq 1 ]; then
steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf --add-pitch false $data/local/lang_chain exp_learning/$model_name/nnet3/extractor ${dir} ${dir}_online
# steps/online/nnet3/prepare_online_decoding.sh --mfcc-config $mfcc_conf_path --add-pitch false $data/local/lang_chain exp_learning/$model_name/nnet3/extractor ${dir} ${dir}_online
steps/online/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --nj $nj --cmd run.pl $dir/graph $data/nopitch_inside ${dir}_online/decode

echo -e "\n#####Inside testing#####"
grep WER ${dir}_online/decode/scoring_kaldi/best_wer
#grep CER $dir/decode_finetune_tl/scoring_kaldi/best_cer
echo -e "#####Inside testing#####\n"

# echo -e "\n#####Outside testing#####"
# grep WER Testing/decode/scoring_kaldi/best_wer
#grep CER Testing/decode/scoring_kaldi/best_cer|| exit 1
# echo -e "#####Outside testing#####\n"

fi
