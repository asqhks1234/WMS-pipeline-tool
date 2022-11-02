#!/bin/bash

#mataBAT2 option read
FILE_MB2=option/metabat2_option.txt
FILE_MB1=option/metabat1_option.txt
FILE_Max=option/maxbin_option.txt

idx=0
metabat2_option=(0 0)
metabat1_option=(0 0)
maxbin_option=(0 0)

#############################################

while read name option annotation
do
	metabat2_option[idx]=$option
	let "idx=idx+1"
done <$FILE_MB2

idx=0
while read name option annotation
do
	metabat1_option[idx]=$option
	let "idx=idx+1"
done <$FILE_MB1

idx=0
while read name option annotation
do
	maxbin_option[idx]=$option
	let "idx=idx+1"
done <$FILE_Max

#############################################

#echo ${metabat2_option[@]}
#metabat2 idx
#0 	minContig  
#1 	max_p
#2 	min_s
#3 	maxEdges
#4 	pTNF
#5 	noadd
#6 	seed
#7 	min_CV

#echo ${metabat1_option[@]}
#metabat1 idx
#0	minProb= 75		
#1	minBinned= 50	
#2	minCorr= 90		
#3	minSamples= 10		
#4	minCV= 1		
#5	minCVSum= 2		
#6	minClsSize= 200000	
#7	minContig= 2500		
#8	minContigBycorr= 1000	
#9	numThreads= 0		
#10	maxVarRatio= 0			
#11 	B= 20			
#12	pB= 50		
#13 	seed= 0			
#14	verysensive
#15	sensive
#16	specific
#17	veryspecific
#18	superspecific

echo ${maxbin_option[@]}
#0	min_contig_length
#1	max_iteration
#2	thread
#3	prob_threshold
#4	plotmarker
#5	markerset



################################################

help_message(){
	echo ""
	echo "Usage:"
	echo ""
	echo "	-i -o 옵션은 필수적으로 입력해주세요."
	echo "	customize 옵션을 사용시 toolname_option.txt을 수정하여 사용해주세요."
	echo "	customize 옵션을 올바른 범위로 사용해주세요"
	echo ""
	echo "Options:"
	echo ""
	echo "	-i STR assembly file( .fa )"
	echo "	-o STR output directory"
	echo ""
	echo "	--metabat2	run metabat2"
	echo "	--metabat1	run metabat1"
	echo "	--maxbin	run maxbin"
	echo ""
	echo "	--customize	run as user settings"
	echo ""
	echo ""
}

markers=107

read_type=paired

#binning_tool
metabat1=false
metabat2=false
maxbin=false
input_assembly=false
out=false
customize=false



while true; do
	case "$1" in
		-i) 		input_assembly=$2;	shift 2;; 
		-o) 		out=$2;			shift 2;;
		-h | --help) 	help_message; 		exit 1; shift 1;;
		--metabat1) 	metabat1=true; 		shift 1;;
		--metabat2)	metabat2=true; 		shift 1;;
		--maxbin) 	maxbin=true; 		shift 1;;
		--customize) 	customize=true; 	shift 1;;
		*) break;;
	esac
done

#echo "커스터마이즈	"$customize
#echo "쓰레드		"$thread
#echo "메타벳		"$metabat

########################################setting check#########################################################
#필수 옵션 확인
#커맨드라인 입력 확인
##############################################################################################################

#binning tool check
if [ $metabat1 = "false" ] && [ $metabat2 = "false" ] && [ $maxbin = "false" ]; then
	echo "적어도 1개이상의 비닝툴이 사용되어야 함"
	help_message;
	exit 1;
fi

# -i -o check
if [ $input_assembly = "false" ] || [ $out = "false" ]; then
	echo "-i, -o는 필수적인 옵션입니다. 입력이 되었는지 확인해야 함"
	help_message;
	exit 1;
fi

#file exists
if [ ! -s $input_assembly ]; then 
	echo "파일이 존재하지 않음"
	exit 1;
fi

#metaBAT1 옵션 1개만 사용해야함
if [ $metabat1 = "true" ]; then
	i=0
	idx=16
	#echo ${metabat1_option[idx]}
	while [ $idx -le 20 ]
       	do
		if [ ${metabat1_option[idx]} = "true" ]; then
			let "i=i+1"
		fi
		let "idx=idx+1"
	done	

	if [ $i -gt 1 ]; then
		echo "sensive 혹은 specific 옵션은 1개만 사용이 가능함"
		exit 1;
	fi
fi


#pair check
#




###############################################################################################################


#################################################set up########################################################


#1 아웃풋 디렉토리 체크 - 이미 있는지 확인
#없으면 만들고 있으면 
if [ ! -d $out ]; then 
	mkdir $out
else
	# 지우고 만든다? or checkM 을 돌려본다?(metaWRAP)
	echo "이미 존재하는 경로"
	#유효성 검사 - checkM
	#건너뛰기 할것인지 사용자의 입력을 받는다?
	#rm -r ${out}
fi

#원본파일 리버스와 포워드를 읽었다면, 정순 역순다 읽었는지 확인한다.
read_1="n"
read_2="n"
for file_number in "$@"; do
	if [[ $file_number == *"_1.fastq" ]]; then read_1="y"; fi
	if [[ $file_number == *"_2.fastq" ]]; then read_2="y"; fi
done
if [ $read_1 == "n" ] || [ $read_2 == "n" ]; then
	echo "*_1.fastq파일과 *_2.fastq파일이 모두 존재해야 합니다."
	exit 1;
fi

#위에서 읽은 파일이 정순과 역순이 모두 존재했지만, 갯수도 확인해야됨
read1_num=$( for num in "$@"; do echo $num | grep _1.fastq; done | wc -l)
read2_num=$( for num in "$@"; do echo $num | grep _2.fastq; done | wc -l)
if [ ! $read1_num == $read2_num ]; then echo "_1.fastq와 _2.fastq의 파일개수는 같아야합니다."; exit 1; fi




#if [ $metabat1 = "true" ] || [ $metabat2 = "true" ] ; then
	#jgi_summarize_bam_contig_depth
	#jgi_summarize_bam_contig_depths --output ${out}/files/metabat_depth.txt ${out}/files/*.bam
	#if [[$? -ne 0 ]]; then 
	#	echo "depth파일 만들기 실패"; 
	#	exit 1;
	#fi
#fi

###############################################################################################################



###############################################################################################################
#metabat2 running
if [ $metabat2 = "true" ]; then
	#customize check
	if [ $customize = "true" ]; then
		echo "use customize"
		exe="metabat -i ${input_assembly} -o ${out}/metabat2_bin/bin -m ${metabat2_option[0]} --maxP ${metabat2_option[1]} --minS ${metabat2_option[2]} --maxEdges ${metabat2_option[3]} --pTNF ${metabat2_option[4]} --seed ${metabat2_option[6]} -t ${metabat2_option[7]} --minClsSize ${metabat2_option[8]} --minCV ${metabat2_option[9]} --minCVSum ${metabat2_option[10]} --verbose"
		#true false 옵션 추가하는 if문 추가적으로 필요함
		#exe뒤에 옵션추가문을 넣고 
		${exe}
		if [[ $? -ne 0 ]]; then 
			echo "binning tool 실행중 오류 발생 "
			exit 1;
		fi
	else
		echo "normal use"
		metabat -i ${input_assembly} -o ${out}/metabat2_bin/bin -t ${metabat2_option[7]} -m ${metabat2_option[0]} --verbose
		if [[ $? -ne 0 ]]; then
			echo "binning tool 실행중 오류 발생 "
			exit 1;
		fi
	fi
	#customize end
fi
#metabat2 end
##################################################################################################################



###############################################################################################################
#metabat1 running

if [ $metabat1 = "true" ]; then
echo "	metaBAT1 running"

	#customize check
	#14	verysensive
	#15	sensive
	#16	specific
	#17	veryspecific
	#18	superspecific
	
	exe="metabat1 -i ${input_assembly} -o ${out}/metabat1_bin/bin --verbose"  
	if [ $customize = "true" ]; then

	echo "use customize"

	if [ ${metabat1_option[16]} = "true" ]; then 
		echo "verysensive"
		exe="$exe --verysensive"
		${exe}	
	elif [ ${metabat1_option[17]} = "true" ]; then
		echo "sensive"	
		exe="$exe --sensive"
		${exe}
	elif [ ${metabat1_option[18]} = "true" ]; then
		echo "specific"
		exe="$exe --specific"
		${exe}
	elif [ ${metabat1_option[19]} = "true" ]; then	
		echo "veryspecific"		
		exe="$exe --veryspecific"
		${exe}	
	elif [ ${metabat1_option[20]} = "true" ]; then	
		echo "superspecific"
		exe="$exe --superspecific"
		${exe}
	else
		#-a 옵션 추가할것 => .bam 파일 추가후 jgi돌리면 생성한 depth.txt로 만들고 사용
	exe="$exe --p1 ${metabat1_option[0]} --p2 ${metabat1_option[1]} --pB ${metabat1_option[2]} --minProb ${metabat1_option[3]} --minBinned ${metabat1_option[4]} --minCorr ${metabat1_option[5]} --minSamples ${metabat1_option[6]} --minCV ${metabat1_option[7]} --minCVSum ${metabat1_option[8]} --minClsSize ${metabat1_option[9]} --minContig ${metabat1_option[10]} --minContigBycorr ${metabat1_option[11]} -t ${metabat1_option[12]} --maxVarRatio ${metabat1_option[13]} -B ${metabat1_option[14]} --seed ${metabat1_option[15]}"		
	${exe}
	if [[ $? -ne 0 ]]; then 
		echo "binning tool 실행중 오류 발생 "
		exit 1;
	fi
	fi

else
		echo "normal use"
		#thread 추가
		exe="$exe -t ${metabat1_option[9]}"
		${exe}
		if [[ $? -ne 0 ]]; then
			echo "binning tool 실행중 오류 발생 "
			exit 1;
		fi
	fi
	#customize end
fi
#metabat1 end
##################################################################################################################



############################################  MAX_BIN  ###########################################################



####
        #jgi_summarize_bam_contig_depths --outputDepth ${out}/work_files/mb2_master_depth.txt --noIntraDepthVariance ${out}/work_files/*.bam
        #if [[ $? -ne 0 ]]; then error "Something went wrong with making contig depth file. Exiting."; fi

	#calculate total numper of columns
	#A=($(head -n 1 ${out}/work_files/mb2_master_depth.txt)) 
	#N=${#A[*]}
	
	# split the contig depth file into multiple files
	#comm "split master contig depth file into individual files for maxbin2 input"
	#if [ -f ${out}/work_files/mb2_abund_list.txt ]; then rm ${out}/work_files/mb2_abund_list.txt; fi
	#for i in $(seq 4 $N); do 
	#	sample=$(head -n 1 ${out}/work_files/mb2_master_depth.txt | cut -f $i)
	#	echo "processing $sample depth file..."
	#	grep -v totalAvgDepth ${out}/work_files/mb2_master_depth.txt | cut -f 1,$i > ${out}/work_files/mb2_${sample%.*}.txt
	#	if [[ $out == /* ]]; then
	#		echo ${out}/work_files/mb2_${sample%.*}.txt >> ${out}/work_files/mb2_abund_list.txt
	#	else
	#		echo $(pwd)/${out}/work_files/mb2_${sample%.*}.txt >> ${out}/work_files/mb2_abund_list.txt
	#	fi
	#done


####

#툴실행
if [ $maxbin = true ]; then
	mkdir ${out}/maxbin2_out
	
	if [ $customize = "true" ]; then
		if [ ${maxbin_option[4]} = "false" ]; then 
			run_MaxBin.pl -contig ${input_assembly} -min_contig_length ${maxbin_option[0]} -max_iteration ${maxbin_option[1]}  -thread ${maxbin_option[2]} -prob_threshold ${maxbin_option[3]} -markerset ${maxbin_option[5]} -out ${out}/maxbin2_out/bin -abund_list ${out}/work_files/mb2_abund_list.txt -verbose		
		else
			run_MaxBin.pl -contig ${input_assembly} -min_contig_length ${maxbin_option[0]} -max_iteration ${maxbin_option[1]}  -thread ${maxbin_option[2]} -prob_threshold ${maxbin_option[3]} -plotmarker -markerset ${maxbin_option[5]} -out ${out}/maxbin2_out/bin -abund_list ${out}/work_files/mb2_abund_list.txt -verbose
		fi
	else
	#normal use	
		run_MaxBin.pl -contig ${input_assembly} -out ${out}/maxbin2_out/bin -abund_list ${out}/work_files/mb2_abund_list.txt -verbose
	fi

	
	if [[ $? -ne 0 ]]; then echo "실행중 오류"; exit 1; fi
	if [[ $(ls ${out}/work_files/maxbin2_out/ | grep bin | grep .fasta | wc -l) -lt 1 ]]; then echo "MaxBin2 did not pruduce a single bin. Something went wrong. Exiting."; exit 1; fi

	mkdir ${out}/maxbin2_bins
	N=0
	for i in $(ls ${out}/maxbin2_out/ | grep bin | grep .fasta); do
		cp ${out}/maxbin2_out/$i ${out}/maxbin2_bins/bin.${N}.fa
		N=$((N + 1))
	done
fi
#Max_bin2
##################################################################################################################
