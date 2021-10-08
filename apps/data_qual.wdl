version 1.0

task data_qual {
    input {
        File? CHR
        File INPUT_BAM
        File INPUT_BAI
        String dockerImage
        String sample_name_base
        File script_s1a = "dx://file-G56y9jj0fX2x24b94ZbK4gVy"
    }
    command <<<
        sh ~{script_s1a} \
        ~{if defined(CHR) then "-c ~{CHR}" else ""} \
        -i ~{INPUT_BAM} -o ~{sample_name_base}.genomeCoverage
    >>>
    runtime {
        dx_instance_type: "mem1_ssd1_x8"
        docker: dockerImage
    }
    output {
        File genome_coverage="${sample_name_base}.genomeCoverage"
    }
}
