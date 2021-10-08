version 1.0

import "sambamba.wdl" as sambam
import "revertSam.wdl" as revSam
import "f_extension.wdl" as suffix
import "bwa_mem.wdl" as bwa
import "markDups.wdl" as mkdup
import "GATK_bsqr.wdl" as bsqr
import "gVCF.wdl" as haplo


workflow vcpa {

  input {

    Array[File]+ reads
    Array[File]? reads_r2
    Boolean sortByName = true
    Array[String] filter_rg_arr
    String dockerImage='dx://file-G5B7J0j0fX2VV184Gjq1B565'
    File ref_index_tar='dx://file-G5B7G9j0jFF7y8ZJPGY8x6FB'
    String sample_name_str
    File regions_file='dx://file-G5K57BQ0fX2g4b3jGJ102VvZ'
  }


  call suffix.f_extension as ftype {
    input :
      input_f=reads[0]
  }

    if (ftype.format_f_arr[0]=='bam') {
      scatter (filter_rg_str in filter_rg_arr) {
        call sambam.Sort as init_sort {
          input :
            inputBam = reads[0],
            sortByName = true,
            filter_rg = filter_rg_str,
            dockerImage = dockerImage
        }

        call revSam.RevertSam as rev_sam {
          input :
            RG=filter_rg_str,
            input_bam=init_sort.outputBam,
            dockerArg=dockerImage,
            bwa_index_tar=ref_index_tar
        }
      }

      call mkdup.markDups as dedup {
        input :
          input_bam=rev_sam.output_bam,
          docker=dockerImage,
          sample_base=sample_name_str,
          chr_regions=regions_file
      }
    }

  ##ignoreing FASTQ for now until clear how read groups work
  if (ftype.format_f_arr[0]=='fastq') {
    Int num_files= length(reads)
    if (num_files >1) {
      call bwa.cat_fastq as comFastq_r1 {
        input :
          input_fastq_gz=reads,
          out_sample_name=sample_name_str
      }

      if (defined(reads_r2)) {
        call bwa.cat_fastq as comFastq_r2 {
          input :
            input_fastq_gz=select_first([reads_r2]),
            out_sample_name=sample_name_str,
            read_group='_R2'
        }
        File? r2_reads_for_mapping=select_first([comFastq_r2.outFastq, select_first([reads_r2])[0]])
      }
    }
    File r1_reads_for_mapping=select_first([comFastq_r1.outFastq, reads[0]])

    call bwa.bwaMem as bmem {
      input :
        input_reads_r1=r1_reads_for_mapping,
        input_reads_r2=r2_reads_for_mapping,
        dockerArg=dockerImage,
        bwa_index_tar=ref_index_tar,
        sample_name_base=sample_name_str
    }
  }

  #Array[File] mapped_bam=select_first([bmem.output_sam,rev_sam.output_bam])


  #call task 2a
  call bsqr.GATK_bsqr as gatk_bsqr {
    input :
      INPUT_BAM=dedup.markedDup_bam,
      INPUT_BAI=dedup.markedDup_bam_index,
      sample_base=sample_name_str
  }

  call haplo.gVCF as calling {
    input :
      INPUT_BAM=gatk_bsqr.bam,
      intervals_file=regions_file,
      sample_base=sample_name_str
  }

  #call task 2b

  #add outputs for tasks as you increment testing

  output {
      File? out_bam= gatk_bsqr.bam
      File ? vcf_out = calling.gvcf
      File? cov_qc = dedup.genCov

  }
}
