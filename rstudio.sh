docker run --rm \
    -v $(pwd):/home/rstudio/ \
    -p 8787:8787 \
    -e PASSWORD=lepav \
    lepav ;