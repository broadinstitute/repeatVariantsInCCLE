workflow expansionhunter_wdl {
    # Input parameters
    File input_bam
    File input_bai
    File reference
    File expansionhunter_variant_catalog
    String sample_name = basename(input_bam,".bam")  
    # Runtime parameters

    call expansionhunter {
        input:
            input_bam = input_bam,
            input_bai = input_bai,
            reference = reference,
            sample_name = sample_name,
            expansionhunter_variant_catalog = expansionhunter_variant_catalog,
            input_bam_size = input_bam_size,
    }
}


task expansionhunter {
    # Input prameters
    File input_bam
    File input_bai
    File reference
    String sample_name    
    File expansionhunter_variant_catalog
    #runtime params
    Int diskGB = input_bam_size * 3
    Int? memory = 64
    Int? cpus = 16
    Int? preemptible_tries
    Int preemptible_count = select_first([preemptible_tries, 3])
    # File size
    Int input_bam_size = ceil(size(input_bam,   "GB"))
    command <<<

        set -euxo pipefail

        # Run ExpansionHunter
        ln -s ${input_bai} ${input_bam}.bai
        count=0
        
        for i in echo $(jq  -c '.[]' ${expansionhunter_variant_catalog}); do
        	echo $i >> $count.json;
            ((count++));
        done;
        ls home/*.json | parallel -j ${cpus} ExpansionHunter --reads ${input_bam} \
                --reference ${reference} \
                --variant-catalog {} \
                --output-prefix ${sample_name}\
                --sex ${sample_sex}
    >>>

    runtime {
        docker: "javadnoorbakhsh/expansionhunter"
        memory: "${memory} GB"
        cpu: ${cpus}
        disks: "local-disk ${diskGB} HDD"
        preemptible: preemptible_count
    }

    output {
        File output_json = "${sample_name}.json"
        File output_vcf = "${sample_name}.vcf"
    }
}