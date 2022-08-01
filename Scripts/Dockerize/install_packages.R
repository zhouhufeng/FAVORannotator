FROM bioconductor/bioconductor_docker:devel

RUN apt-get update
    RUN R -e 'BiocManager::install(ask = F)' && R -e 'BiocManager::install(c("gdsfmt", "SeqArray", "SeqVarTools", ask = F))'

RUN Rscript -e 'install.packages("readr")'
RUN Rscript -e 'install.packages("devtools")'

RUN Rscript -e 'devtools::install_github("zhengxwen/gdsfmt")'

