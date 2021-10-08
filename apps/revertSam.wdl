version 1.0

task RevertSam  {

  input {
    File input_bam
    File bwa_index_tar
    String dockerArg
    Int? memory = 32
    Int? threads=8
    String RG
  }

  String sample_name = basename(input_bam, ".bam")
  String metrics = sample_name + '.mrkilladapt.metrics.out'
  Int disk_gb = ceil((size(input_bam, "GB") + 1) * 5)
  String out_sam_name = sample_name +'.'+RG + '.reverted.marked.mapped.sam'

  command <<<
    RG_LINE=$(samtools view -H ~{input_bam} |grep  "^@RG" | grep -m 1 -P "ID:~{RG}" |sed 's/\t/\\t/g')
    set -euxo pipefail
    java -jar /opt/picard/picard.jar \
    RevertSam \
    OUTPUT_BY_READGROUP=false \
    RESTORE_ORIGINAL_QUALITIES=true \
    COMPRESSION_LEVEL=0 \
    SORT_ORDER=queryname \
    QUIET=true \
    VALIDATION_STRINGENCY=SILENT \
    INPUT= ~{input_bam} \
    OUTPUT= /dev/stdout |
    java -jar /opt/picard/picard.jar \
    MarkIlluminaAdapters \
    METRICS= ~{metrics} \
    COMPRESSION_LEVEL=0 \
    VALIDATION_STRINGENCY=SILENT \
    QUIET=true \
    INPUT=/dev/stdin   \
    OUTPUT= /dev/stdout |
    java -jar /opt/picard/picard.jar \
    SamToFastq \
    CLIPPING_ATTRIBUTE=XT \
    CLIPPING_ACTION=2 \
    INTERLEAVE=true \
    INCLUDE_NON_PF_READS=true \
    INCLUDE_NON_PRIMARY_ALIGNMENTS=false \
    COMPRESSION_LEVEL=0 \
    VALIDATION_STRINGENCY=SILENT \
    QUIET=true \
    INPUT=/dev/stdin  \
    FASTQ= ~{sample_name}.interleaved.fastq

    #RG_LINE=$(samtools view -H ~{input_bam} | grep "^@RG" | grep -m 1 -P "ID:~{RG}" | sed 's/\t/\\t/g')
    #create working example
    mkdir /home/dnanexus/work/bwa_index
    tar -zxvf ~{bwa_index_tar} -C /home/dnanexus/work/bwa_index
    bwa mem \
    -t ~{threads} \
    -K 100000000 \
    -Y \
    -R "$RG_LINE" \
    -p /home/dnanexus/work/bwa_index/GRCh38_full_analysis_set_plus_decoy_hla.fa \
    ~{sample_name}.interleaved.fastq > ~{out_sam_name}

    samtools sort --threads ~{threads} -l 0 -n -T ~{RG}.aligned.sorted.bam.1 --output-fmt SAM ~{out_sam_name} | \
    samblaster --addMateTags --ignoreUnmated | \
    samtools sort --threads ~{threads} -l 5 -T ~{RG}.aligned.sorted.bam.2 --output-fmt BAM -o ~{RG}.aligned.sorted.bam
  >>>

  output {
      File output_bam = "${RG}.aligned.sorted.bam"
      File mk_metrics = metrics
  }

  runtime {
    docker: dockerArg
    cpu: threads
    disks: "local-disk ~{disk_gb} SSD"
    memory: "~{memory} GB"
  }

  meta {name:"Roll back and map"}
}
