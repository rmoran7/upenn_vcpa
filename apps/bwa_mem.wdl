version 1.0
##specifically for FASTQ. Need to feed READ group info to this. Should also removce the concat to process each paired fastq seperately.

task cat_fastq {
    input {
      Array[File] input_fastq_gz
      String out_sample_name
      String read_group='_R1'
    }

    String outName = out_sample_name + read_group +'.combined.fastq.gz'

    command <<<
      set -euxo pipefail
      zcat ~{sep=' ' input_fastq_gz} | gzip --fast >> ~{outName}
    >>>

    output {
      File outFastq = outName
    }
}

task bwaMem  {

  input {
    File input_reads_r1
    File? input_reads_r2
    File bwa_index_tar
    String dockerArg
    Int? memory = 32
    Int? threads=8
    String sample_name_base
    String? read_group_id
    String? read_group_platform
    String? read_group_library
  }
  String read_group_id_str=select_first([read_group_id,sample_name_base])
  String read_group_platform_str=select_first([read_group_platform,'ILLUMINA'])
  String read_group_lib_str=select_first([read_group_library,read_group_id_str])
  #String RG_str = '@RG\tID:' +sample_name_base + '\tSM:' + sample_name_base
  String metrics = sample_name_base + '.mrkilladapt.metrics.out'
  Int disk_gb = ceil((size(select_all([input_reads_r1,input_reads_r2]), "GB") + 1) * 5)
  String out_sam_name = sample_name_base + '.mapped.sam'
  String read_group_opt="@RG\\tID:~{read_group_id_str}\\tPL:~{read_group_platform_str}\\tLB:~{read_group_lib_str}\\tSM:~{read_group_id}"
  command <<<
    set -euxo pipefail
    mkdir /home/dnanexus/work/bwa_index
    tar -zxvf ~{bwa_index_tar} -C /home/dnanexus/work/bwa_index
    bwa mem \
    -t ~{threads} \
    -K 100000000 \
    -Y \
    -R "~{read_group_opt}" \
    -p /home/dnanexus/work/bwa_index/GRCh38_full_analysis_set_plus_decoy_hla.fa \
    ~{input_reads_r1} \
    ~{if defined(input_reads_r2) then input_reads_r2 else ""} \
    > ~{out_sam_name}

  >>>

  output {
      File output_sam = out_sam_name
  }

  runtime {
    docker: dockerArg
    cpu: threads
    disks: "local-disk ~{disk_gb} SSD"
    memory: "~{memory} GB"
  }
}
