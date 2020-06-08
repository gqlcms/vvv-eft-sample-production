#!/bin/bash

# 1 to 10 inclusive
END=10
for ((i=1;i<=END;i++)); do
    OUT_DIR=`printf %05d $i`
    mkdir $OUT_DIR
    cd $OUT_DIR

    PILEUP_FILES_FILE=/grid_mnt/data_cms/rembser/production-test-multithread/pileup_files.txt
    SCRIPT=/grid_mnt/data_cms/rembser/production-test-multithread/triboson_production.sh
    OUTPUT_DIR=/grid_mnt/data_cms/rembser/production-test-multithread/$OUT_DIR

    cp $SCRIPT $OUTPUT_DIR/

    echo "#!/bin/bash

cd $OUTPUT_DIR 
sh triboson_production.sh -p $PILEUP_FILES_FILE -s WWW_dim8 -c -o $OUTPUT_DIR -n 1000" > submit_$OUT_DIR.sh

    t3submit submit_$OUT_DIR.sh
    sleep 1

    cd ..

done
