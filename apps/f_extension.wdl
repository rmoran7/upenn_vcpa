version 1.0

task f_extension {
  input {
    File input_f
  }

  command <<<
    set -euxo pipefail
    f=$(basename -- "~{input_f}")
    file_extension="${f##*.}"
    if [[ "${file_extension}" == "bam" ]]
    then
      f_format="bam"
    else
      f_format="fastq"
    fi
    echo $f_format
  >>>

  output {
    Array[String] format_f_arr=read_lines(stdout())
  }
}
