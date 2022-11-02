#!/bin/bash


help_message () {
	echo ""
	echo "Usage: read_qc [options] -1 reads_1.fastq -2 reads_2.fastq -o output_dir"
	echo "Note: the read files have to be named in the name_1.fastq/name_2.fastq convention."
	echo "Options:"
	echo ""
	echo "	-1 STR          forward fastq reads"
	echo "	-2 STR          reverse fastq reads" 
	echo "	-o STR          output directory"
	echo "	-t INT          number of threads (default=1)"
	echo "	-x STR		prefix of host index in bmtagger database folder (default=hg38)"
	echo ""
	echo "	--skip-bmtagger		dont remove human sequences with bmtagger"
	echo "	--skip-trimming		dont trim sequences with trimgalore"
	echo "	--skip-pre-qc-report	dont make FastQC report of input sequences"
	echo "	--skip-post-qc-report	dont make FastQC report of final sequences"
	echo "";}

########################################################################################################
########################               LOADING IN THE PARAMETERS                ########################
########################################################################################################



# default params
threads=1; out="false"; reads_1="false"; reads_2="false"
bmtagger=true; trim=true; pre_qc_report=true; post_qc_report=true
HOST=hg38

# load in params
OPTS=`getopt -o ht:o:1:2:x: --long help,skip-trimming,skip-bmtagger,skip-pre-qc-report,skip-post-qc-report -- "$@"`
# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# loop through input params
while true; do
	case "$1" in
		-t) threads=$2; shift 2;;
		-o) out=$2; shift 2;;
		-1) reads_1=$2; shift 2;;
		-2) reads_2=$2; shift 2;;
		-x) HOST=$2; shift 2;;
		-h | --help) help_message; exit 1; shift 1;;
		--skip-trimming) trim=false; shift 1;;
		--skip-bmtagger) bmtagger=false; shift 1;;
		--skip-pre-qc-report) pre_qc_report=false; shift 1;;
		--skip-post-qc-report) post_qc_report=false; shift 1;;
		--) help_message; exit 1; shift; break ;;
		*) break;;
	esac
done


########################################################################################################
########################           MAKING SURE EVERYTHING IS SET UP             ########################
########################################################################################################

# check if all parameters are entered
if [ "$out" = "false" ] || [ "$reads_1" = "false" ] || [ "$reads_2" = "false" ]; then 
	help_message; exit 1
fi

if [ "$reads_1" = "$reads_2" ]; then
	error "The forward and reverse reads are the same file. Exiting pipeline."
fi


if [ ! -s ${BMTAGGER_DB}/${HOST}.bitmask ] && [ "$bmtagger" = "true" ]; then
	error "${BMTAGGER_DB}/${HOST}.bitmask file doesnt exist. Please configure your bmtagger genome index"
fi

########################################################################################################
########################                    BEGIN PIPELINE!                     ########################
########################################################################################################
if [ ! -s $reads_1 ]; then error "$reads_1 file does not exist. Exiting..."; fi
if [ ! -s $reads_2 ]; then error "$reads_2 file does not exist. Exiting..."; fi



if [ ! -d $out ]; then
        mkdir $out;
else
        echo "Warning: $out already exists."
fi

if [ "$pre_qc_report" = true ]; then
	########################################################################################################
	########################                 MAKING PRE-QC REPORT                   ########################
	########################################################################################################
        announcement "MAKING PRE-QC REPORT"
	
	mkdir ${out}/pre-QC_report
	fastqc -q -t $threads -o ${out}/pre-QC_report -f fastq $reads_1 $reads_2
	
	if [ $? -ne 0 ]; then error "Something went wrong with making pre-QC fastqc report. Exiting."; fi
	rm ${out}/pre-QC_report/*zip
	comm "pre-qc report saved to: ${out}/pre-QC_report"
fi

if [ "$trim" = true ]; then
	########################################################################################################
	########################                 RUNNING TRIM-GALORE                    ########################
	########################################################################################################
        announcement "RUNNING TRIM-GALORE"

	trim_galore --no_report_file --paired -o $out $reads_1 $reads_2
	
	tmp=${reads_1%_*}; sample=${tmp##*/}
	
	# Fix the naming of the trimmed reads files:
	mv ${out}/${sample}_1_val_1.fq ${out}/trimmed_1.fastq
	mv ${out}/${sample}_2_val_2.fq ${out}/trimmed_2.fastq
	if [[ ! -s ${out}/trimmed_1.fastq ]]; then error "Something went wrong with trimming the reads. Exiting."; fi
	comm "Trimmed reads saved to: ${out}/trimmed_1.fastq and ${out}/trimmed_2.fastq"
	
	reads_1=${out}/trimmed_1.fastq
	reads_2=${out}/trimmed_2.fastq
	
	rm ${out}/${sample}_1_trimmed.fq ${out}/${sample}_2_trimmed.fq
fi

if [ "$bmtagger" = true ]; then
	########################################################################################################
	########################               REMOVING HOST SEQUENCES                  ########################
	########################################################################################################
        announcement "REMOVING HOST SEQUENCES WITH BMTAGGER"

	mkdir ${out}/bmtagger_tmp
	comm "running bmtagger with ${BMTAGGER_DB}/${HOST}.bitmask ${BMTAGGER_DB}/${HOST}.srprism indexes..."
	bmtagger.sh -b ${BMTAGGER_DB}/${HOST}.bitmask -x ${BMTAGGER_DB}/${HOST}.srprism -T ${out}/bmtagger_tmp -q1\
	 -1 $reads_1 -2 $reads_2\
	 -o ${out}/${sample}.bmtagger.list
	if [[ $? -ne 0 ]]; then error "Something went wrong with running Bmtagger! Exiting."; fi
	if [[ ! -s ${out}/${sample}.bmtagger.list ]]; then warning "No contamination reads found, which is very unlikely."; fi



	

	rm -r ${out}/bmtagger_tmp
	rm ${out}/${sample}.bmtagger.list
	reads_1=${out}/${sample}_1.clean.fastq
	reads_2=${out}/${sample}_2.clean.fastq

	rm ${out}/trimmed_1.fastq ${out}/trimmed_2.fastq
fi	

mv $reads_1 ${out}/final_pure_reads_1.fastq
mv $reads_2 ${out}/final_pure_reads_2.fastq
comm "Contamination-free and trimmed reads are stored in: ${out}/final_pure_reads_1.fastq and ${out}/final_pure_reads_2.fastq"


if [ "$post_qc_report" = true ]; then
	########################################################################################################
	########################                 MAKING POST-QC REPORT                  ########################
	########################################################################################################
        announcement "MAKING POST-QC REPORT"
	
	mkdir ${out}/post-QC_report
	fastqc -t $threads -o ${out}/post-QC_report -f fastq ${out}/final_pure_reads_1.fastq and ${out}/final_pure_reads_2.fastq
	
	if [ $? -ne 0 ]; then error "Something went wrong with making post-QC fastqc report. Exiting."; fi
	rm ${out}/post-QC_report/*zip
	comm "post-qc report saved to: ${out}/post-QC_report"
fi

########################################################################################################
########################              READ QC PIPELINE COMPLETE!!!              ########################
########################################################################################################
announcement "READ QC PIPELINE COMPLETE!!!"
