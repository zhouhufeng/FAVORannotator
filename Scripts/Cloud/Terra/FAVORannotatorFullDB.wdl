workflow FAVORannotator{ 

	File InputaGDS
	Int  CHRN
  
    call FunctionalAnnotation {
    	input: 
        	InputaGDS=InputaGDS, CHRN=CHRN
    }

}

task FunctionalAnnotation{

    Int CHRN            
    File InputaGDS       
    File? FAVORannotator = "gs://fc-secure-38f900cb-e5ed-481d-b866-6c98b7e5e7ea/FAVORannotatorTerraFullDB.R"
    
    runtime{
      docker: "zilinli/staarpipeline:0.9.6"
      memory: "56G"
      cpu: "1"
      zones: "us-central1-c us-central1-b"
      disks: "local-disk " + 500 + " HDD"
      preemptible: 1
    }
    
    command {
      curl https://sh.rustup.rs -sSf | sh -s -- -y
      source $HOME/.cargo/env
      cargo install xsv
      echo ${InputaGDS}
      echo ${CHRN}
			df -a -h
      Rscript ${FAVORannotator} ${InputaGDS} ${CHRN}
      echo "Finished: in wdl r scripts"   
      df -a -h
      mv ${InputaGDS} AnnotatedOutput.${CHRN}.agds
    }
    
    output {
     	File OutputResults = "AnnotatedOutput.${CHRN}.agds"
    }
}
