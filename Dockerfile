FROM rocker/rstudio

RUN apt-get update &&  \
    apt-get install -y --no-install-recommends python3-dev libpq-dev gcc \
    libgeos-dev libpng-dev libgdal-dev libudunits2-dev libsqlite3-dev libproj-dev\ 
    default-jre default-jdk \
    libproj-dev gdal-bin && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements .

RUN Rscript requirements.R 

COPY . .
