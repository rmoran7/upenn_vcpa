version 1.0

task GATK_bsqr {
    input {
        File? INPUT_BAM
        File? INPUT_BAI
        File script_s2a = "dx://file-G5JgXBj0fX2XG1bQ3Q8PbyJk"
        File REF_FASTA = "dx://file-G4P7y3Q0fX2bf29J3gjKB0Q5"
        File REF_FAI = "dx://file-G5BGX880yqj9bPQ8JVykf95y"
        File REF_DICT = "dx://file-G5BK2X80JPvyjy9f19vp60PY"
        File DBSNP = "dx://file-G5BJ3Zj0X8Z2B49y3x38BYfg"
        File DBSNP_tbi = "dx://file-G5BJ3Zj0X8ZGQfV13Gy4PXY6"
        File KNOWN = "dx://file-G4P7y080fX2bf29J3gjKB0PX"
        File KNOWN_tbi = "dx://file-G4P7y000fX2QPP21Jzf98ffb"
        File GOLD = "dx://file-G4P7y0Q0fX2yFFxgPfqPPFkk"
        File GOLD_tbi = "dx://file-G4P7y080fX2y6vBY8Bvy6Zv4"
        String sample_base

    }
    command <<<
        mkdir -p /mnt/data/NGS/jar/gatk-3.7
        mkdir -p /mnt/data/NGS/ref/hg38
        find / -name GenomeAnalysisTK.jar -exec ln -sfn {} /mnt/data/NGS/jar/gatk-3.7/GenomeAnalysisTK.jar ';'
        cp ~{REF_FASTA} /mnt/data/NGS/ref/hg38/
        cp ~{REF_FAI} /mnt/data/NGS/ref/hg38/
        cp ~{REF_DICT} /mnt/data/NGS/ref/hg38/
        cp ~{DBSNP} /mnt/data/NGS/ref/hg38/
        cp ~{DBSNP_tbi} /mnt/data/NGS/ref/hg38/
        cp ~{KNOWN} /mnt/data/NGS/ref/hg38/
        cp ~{KNOWN_tbi} /mnt/data/NGS/ref/hg38/
        cp ~{GOLD} /mnt/data/NGS/ref/hg38/
        cp ~{GOLD_tbi} /mnt/data/NGS/ref/hg38/
        cp ~{INPUT_BAM} .
        cp ~{INPUT_BAI} .
        sh ~{script_s2a} -t $(nproc) -i `basename ~{INPUT_BAM}` -o output.cram
    >>>
    runtime {
        dx_instance_type: "mem2_ssd1_v2_x32"
        docker: "ghhenry/upenn_gatk_custom_v1"
    }
    output {
        File bam=basename(INPUT_BAM)+".indelrealign.bam"
    }
}
