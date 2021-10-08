version 1.0

task Markdup {
    input {
        Array[File] inputBams
        String outputPath
        Int compressionLevel = 8
        Boolean removeDuplicates = false
        Int? hashTableSize
        Int? overFlowListSize
        Int threads = 2
        Int memory = 7

        String dockerImage = "quay.io/biocontainers/sambamba:0.7.1--h148d290_2"
    }

    String bamIndexPath = sub(outputPath, ".bam$", ".bai")

    command {
        set -euxo pipefail
        mkdir -p "$(dirname ~{outputPath})"
        sambamba markdup \
        --nthreads ~{threads} \
        -l ~{compressionLevel} \
        ~{true="-r" false="" removeDuplicates} \
        ~{"--hash-table-size " + hashTableSize} \
        ~{"--overflow-list-size " + overFlowListSize} \
        ~{sep=' ' inputBams} ~{outputPath}
        # index file.
        mv ~{outputPath}.bai ~{bamIndexPath}
    }

    output {
        File outputBam = outputPath
        File outputBamIndex = bamIndexPath
    }

    runtime {
        cpu: threads
        memory: "~{memory} GB"
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        inputBams: {description: "The input BAM files.", category: "required"}
        outputPath: {description: "Output directory path + output file.", category: "required"}
        compressionLevel: {description: "Compression level from 0 (uncompressed) to 9 (best).", category: "advanced"}
        removeDuplicates: {description: "Whether to remove the duplicates (instead of only marking them).", category: "advanced"}
        hashTableSize: {description: "Sets sambamba's hash table size.", category: "advanced"}
        overFlowListSize: {description: "Sets sambamba's overflow list size.", category: "advanced"}
        threads: {description: "The number of threads that will be used for this task.", category: "advanced"}
        memory: {description: "The amount of memory available to the job in megabytes.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputBam: {description: "Sorted BAM file."}
        outputBamIndex: {description: "Sorted BAM file index."}
    }
}

task Sort {
    input {
        File inputBam
        String outputPath = basename(inputBam, ".bam") + ".sorted.bam"
        Boolean sortByName = false
        String? filter_rg
        Int compressionLevel = 1
        Int memoryPerThreadGb = 3
        Int threads = 2
        Int memory = 1 + threads * memoryPerThreadGb
        String dockerImage = "quay.io/biocontainers/sambamba:0.7.1--h148d290_2"
    }

    # Select first needed as outputPath is optional input (bug in cromwell).
    String bamIndexPath = sub(select_first([outputPath]), ".bam$", ".bai")

    command {
        set -euxo pipefail
        mkdir -p "$(dirname ~{outputPath})"

        sambamba sort \
        -l ~{compressionLevel} \
        ~{true="-n" false="" sortByName} \
        ~{"--nthreads " + threads} \
        --filter "[RG]=='~{filter_rg}'" \
        -m ~{memoryPerThreadGb}G \
        -o ~{outputPath} \
        ~{inputBam}
    }

    output {
        File outputBam = outputPath
    }

    runtime {
        cpu: threads
        memory: "~{memory} GB"
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        inputBam: {description: "The input SAM file.", category: "required"}
        outputPath: {description: "Output directory path + output file.", category: "required"}
        filter_rg : {description: "To filter on RG tag , provide REGEX as string", category: "optional"}
        sortByName: {description: "Sort the inputBam by read name instead of position.", category: "advanced"}
        compressionLevel: {description: "Compression level from 0 (uncompressed) to 9 (best).", category: "advanced"}
        memoryPerThreadGb: {description: "The amount of memory used per sort thread in gigabytes.", category: "advanced"}
        threads: {description: "The number of threads that will be used for this task.", category: "advanced"}
        memory: {description: "The amount of memory available to the job in gigabytes.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputBam: {description: "Sorted BAM file."}
    }
}
