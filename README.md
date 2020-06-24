# EFT Sample Production for VVV Analysis
Tools, scripts and documentation to generate VVV samples for triboson analysis.

## Instructions

### 1. Create gridpacks

**You can skip this step, the gridpacks are publicly available on [my website](https://rembserj.web.cern.ch/rembserj/genproduction/gridpacks/).**

How to create gridpacks from Madgraph in general: <https://twiki.cern.ch/twiki/bin/view/CMS/QuickGuideMadGraph5aMCatNLO>.

Creating a gridpack takes about 30 minutes each.

```
git clone git@github.com:cms-sw/genproductions.git genproductions
git clone git@github.com:Saptaparna/EFTAnalysis.git

CARDS_DIR=$PWD/Saptaparna/SignalGeneration/Dimension8/Cards

cd genproductions/bin/MadGraph5_aMCatNLO

./gridpack_generation.sh WWW_dim8 $CARDS_DIR/WWW  "local" "ALL" slc7_amd64_gcc630
./gridpack_generation.sh WWZ_dim8 $CARDS_DIR/WWZ  "local" "ALL" slc7_amd64_gcc630
./gridpack_generation.sh WZZ_dim8 $CARDS_DIR/WZZ/Production  "local" "ALL" slc7_amd64_gcc630
./gridpack_generation.sh ZZZ_dim8 $CARDS_DIR/ZZZ/Production  "local" "ALL" slc7_amd64_gcc630
```

When the gridpacks are ready, they should be copied to a place where they are available to all group members.
For now, they are on a [public personal website](https://rembserj.web.cern.ch/rembserj/genproduction/gridpacks/),
which also stores a ULR to the cards in the exact commit a given gridpack was generated with.

### 2. Get the pileup file list

For mixing pilup at GEN-SIM level with the signal, some root files from the following neutrino gun sample should be available:
```
PILEUP_DATASET=/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW

dasgoclient -query="file dataset=$PILEUP_DATASET" > pileup_files.txt
```
A list of files as obtained from the dasgoclient in the step above is needed as input for the production script.
Of course, not the whole dataset is required, as it is very large. Each file in the neutrino dataset contains about 800 events,
so the number of events in your production divided by 800 is the length of the required pileup file list.

Don't be surprised, getting the full list from the dasgoclient takes a few minutes.

**LLR environment**: the whole neutrino gun sample is available on the (Tier 3) T3 cluster, so the whole list of files can be used.

**UCSD environment**: one has to copy some neutrino gun files to the UCSD cluster before, which should then be listed in the file list. Note that the list needs at least two files, such that jobs with about 1000 events don't get many pileup duplicates.

### 3. Test the production locally

Download the [triboson_production.sh](https://github.com/guitargeek/vvv-eft-sample-production/blob/master/triboson_production.sh)
script from this repository. You can check out the options with `triboson_production.sh -h`.
The number of events should be low (`-n 10`), as 100 events would already take 1.5 hours in the gensim step.

```
sh triboson_production.sh -p pileup_files.txt -s WWW_dim8 -c -o $OUTPUT_DIR -n 10
```
* Change the path of pileup list file if needed.
* The sample (`-s` flag) can be any from the gridpack website linked above (the most recent date is hardcoded in the script).
* The output dir should better be non-existent or empty, otherwise the jobs will overwrite each others files.

**Hint:** it's good to check first locally that setting up the CMSSW environment succeeds (dry run flag `-d`). This just creates the configuration files for all steps without running them:

### 4. Submit the jobs

This step is probably different for LLR and UCSD, but in principle you should just need a little script that does the following:

1. Create 1 output directory for each job
2. Write a script that is to be submitted as a job into each output directory
3. Change into all output directories and submit the scripts as jobs

For LLR, this can be done with the [submit_jobs_llr.sh](https://github.com/guitargeek/vvv-eft-sample-production/blob/master/submit_jobs_llr.sh) script.

**Remember:** if you set the number of events (`-n` flag) to a number higher than 2 times 800, you need to change the production script such that includes more than two random pileup files from the list.

### 5. Merge the NANOEDMAOD files

To avoid overhead when opening many small NanoAOD files, the last step is to merge several NanoEDMAOD into one final NanoAOD file.

A suggestion is to merge the output of 100 jobs (assuming 1000 events per job), resulting in NanoAOD files that are about 200 MB large.

The merging step is very fast and can be done manually in the end by adapting the [nano_merge_step_cfg.py](https://github.com/guitargeek/vvv-eft-sample-production/blob/master/nano_merge_step_cfg.py) config.

The only difference between our merging step and what is done in central production is the disabled event dumplicate check (`duplicateCheckMode = "noDuplicateCheck"`), which we need to do because there is no mechanism in the triboson production script to avoid duplicate run/lumisection/event ID combinations. This would probably be easy to implement if I knew how, but it's also not really an issue.

## Known issues with the production

* TODO
