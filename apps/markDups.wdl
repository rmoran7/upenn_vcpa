version 1.0

task markDups {
  input {
    Array[File] input_bam
    String docker
    String sample_base
    File chr_regions
  }
  Int disk_gb = ceil((size(input_bam, "GB") + 1) * 3)
  command <<<
    sambamba merge --compression-level=9 ~{sample_base}.merged.bam ~{sep=" " input_bam}
    /usr/local/bam-non-primary-dedup dedup_lowmem --in ~{sample_base}.merged.bam --out ~{sample_base}.merged.dedup.bam \
    --force --excludeFlags 0xB00 && \
    sambamba index ~{sample_base}.merged.dedup.bam

    ####commented out as there is a bug in this version.
    #echo "getting genome coverage for merged file"
    #sambamba depth region \
    #-t $(nproc)\
    #--combined \
    #-L ~{chr_regions} \
    #-T 5 -T 10 -T 20 -T 30 -T 40 -T 50 ~{sample_base}.merged.dedup.bam >> ~{sample_base}.genomeCoverage.txt
  >>>

  output {
        File markedDup_bam="${sample_base}.merged.dedup.bam"
        File markedDup_bam_index="${sample_base}.merged.dedup.bam.bai"
        File? genCov = "${sample_base}.genomeCoverage.txt"
  }

  runtime {
    docker: docker
    dx_instance_type: "mem2_ssd2_v2_x16"
    disks: "local-disk ${disk_gb} SSD"
  }


}
