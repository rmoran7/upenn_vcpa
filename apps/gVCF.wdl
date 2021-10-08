version 1.0

task gVCF {
    input {
        File? INPUT_BAM
        File script_s2b = "dx://file-G5PFK900fX2xf4yXGfB9jkX6"
        File REF_FASTA = "dx://file-G4P7y3Q0fX2bf29J3gjKB0Q5"
        File REF_FAI = "dx://file-G5BGX880yqj9bPQ8JVykf95y"
        File REF_DICT = "dx://file-G5BK2X80JPvyjy9f19vp60PY"
        File DBSNP = "dx://file-G5BJ3Zj0X8Z2B49y3x38BYfg"
        File DBSNP_tbi = "dx://file-G5BJ3Zj0X8ZGQfV13Gy4PXY6"
	      File intervals_file
        String sample_base
    }

    String output_vcf_name=  sample_base + ".g.vcf.gz"

    command <<<
        mkdir -p ./tmp/logs
        mkdir -p /mnt/data/NGS/jar/gatk-3.7
        mkdir -p /mnt/data/NGS/ref/hg38
        find / -name GenomeAnalysisTK.jar -exec ln -sfn {} /mnt/data/NGS/jar/gatk-3.7/GenomeAnalysisTK.jar ';'
        cp ~{REF_FASTA} /mnt/data/NGS/ref/hg38/
        cp ~{REF_FAI} /mnt/data/NGS/ref/hg38/
        cp ~{REF_DICT} /mnt/data/NGS/ref/hg38/
        cp ~{DBSNP} /mnt/data/NGS/ref/hg38/
        cp ~{DBSNP_tbi} /mnt/data/NGS/ref/hg38/
        cp ~{INPUT_BAM} .
        sh ~{script_s2b} -t $(nproc) -i `basename ~{INPUT_BAM}` -o ~{output_vcf_name} -c ~{intervals_file}
    >>>
    runtime {
        dx_instance_type: "mem2_ssd1_v2_x32"
        docker: "ghhenry/upenn_gatk_custom_v1"
    }
    output {
        File gvcf=output_vcf_name
    }
}
