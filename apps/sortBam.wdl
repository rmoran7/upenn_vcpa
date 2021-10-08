version 1.0

import "/Users/rmoran-cf/Desktop/tools/upenn/tasks/compile/sambamba.wdl" as sambam

workflow vcpa {

  input {

    File reads
    File ? reads_r2
    String outputPath = basename(inputBam, ".bam") + ".sorted.bam"
    Boolean sortByName = false
    String? filter_rg_str
    String dockerImage =

  }

  task f_extension {
    input {
      File input_f
    }
    command <<<
      set -euxo pipefail
      file_extension="~{input_f##*.}"
      if [[ "${file_extension}" == "bam" ]]; then
        f_format="bam"
      else
        f_format="fastq"
      echo $f_format
    >>>

    output {
      String format_= read_lines(stdout())
    }
  }
  call f_extension as in_for {
    input :
      input_f=reads
  }

  if (in_for=='bam') {
    call sambam as init_sort {
      input :
        inputBam = reads,
        sortByName = true,
        filter_rg = filter_rg_str
    }

    call
  }
}
