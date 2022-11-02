#!/usr/bin/env bash
help_message() {
	echo "help_message"
}

spade=false
megahit=false
min_contig_length=1000
read1=false
read2=false
out=false
thread=1


while true; do
	case "$1" in
		-o) out=$2; shift 2;;
		-1) read1=$2; shift 2;;
		-2) read2=$2; shift 2;;
		-h | --help) help_message; exit 1; shift 1;;
		--megahit) megahit=true; shift 1;;
		--spade) spade=true; shift 1;;
		--) help_message; exit 1; shift; break ;;
		*) break;;
	esac
done

#필수 옵션 체크
if [ $out = "false" ] || [ $read1 = "false" ] || [ $read2 = "false" ]; then
	echo "아웃풋 디렉토리 및 1,2인풋이 필수로 필요합니다."
	echo $out $read1 $read2
	help_message
fi
#툴 사용 체크
if [ $spade = "false" ] && [ $megahit = "false" ]; then
	echo "1개 이상의 툴을 사용해야 합니다."
fi

#경로확인
if [ ! -d $out ]; then
	mkdir $out;
else
	echo "이미 존재하는 경로입니다."
fi

if [ $spade = "true" ]; then
	spades.py -1 ${read1} -2 ${read2} -o $out/spades

fi

if [ $megahit = "true" ]; then
	megahit -1 ${read1} -2 ${read2} -o $out/megahit
fi
