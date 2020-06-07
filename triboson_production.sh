#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
YEAR=2018
NTHREADS=8

while getopts "h?y:s:n:o:dcp:" opt; do
    case "$opt" in
    h|\?)
        echo 'triboson-production -y YEAR -s SAMPLE -n NEVENTS -o OUTPUT_DIR -p PILEUP_FILES [-d -c]

If the -d (dry run) flag is set, only the environment and the config file will be created.
otherwise, the cmsRun command will be executed.

The -c flag enables the cleanup of temporary directories in the end, which is recommended for
large scale production to save space.

PILEUP_FILES needs to be a file in which the the pileup files are listed, separated by newlines.
You can get this list with the dasgoclient:
    dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW" > pileup_files.txt'
        exit 0
        ;;
    y)  YEAR=$OPTARG
        # e.g. 2016, 2017, 2018
        ;;
    s)  SAMPLE=$OPTARG
        # e.g. WWW_dim8, WZZ_dim8, WWZ_dim8 or ZZZ_dim8
        ;;
    p)  PILEUP_FILES=$OPTARG
        ;;
    d)  DRY_RUN=1
        # cleanup temporary files in the end, recommended for large scale production
        ;;
    c)  CLEANUP=1
        # Only setup but exit script before actually running cmsRun
        ;;
    o)  OUTPUT_DIR=$OPTARG
        # Output directory of this production
        ;;
    n)  NEVENTS=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

if [ -z "$NEVENTS" ]
then
      echo "-n NEVENTS not specified!"
      exit 1
fi

if [ -f "$PILEUP_FILES" ]; then
    echo "$PILEUP_FILES exist"
else 
    echo "$PILEUP_FILES does not exist!"
    exit 1
fi

PILEUP_INPUT=$(shuf -n 2 $PILEUP_FILES | tr '\n' ',')
PILEUP_INPUT=${PILEUP_INPUT::-1}

if [[ "$PILEUP_INPUT" = *?.root ]]; then
    echo "Pileup input looks OK"
else
    echo "Something unexpected happened with the pileup input!"
    exit 1
fi

case "$YEAR" in

2016)  echo "The year $YEAR is not supported!"
    CONDITIONS=80X_mcRun2_asymptotic_2016_TrancheIV_v8
    BEAMSPOT=Realistic50ns13TeVCollision # yes, 50 ns is not correct but this is also used in official 2016 MC productions
    exit 1
    ;;
2017)  echo "The year $YEAR is not supported!"
    CONDITIONS=94X_mc2017_realistic_v17
    BEAMSPOT=Realistic25ns13TeVEarly2017Collision
    exit 1
    ;;
2018)  echo "The year is $YEAR"
    CONDITIONS=102X_upgrade2018_realistic_v20
    BEAMSPOT=Realistic25ns13TeVEarly2018Collision
    CAMPAIGN=RunIIAutumn18
    ;;
*) echo "Year $YEAR is not valid, did you forget to specify it with the -y option?"
   exit 1
   ;;
esac

if [ "$DRY_RUN" ]
then
      echo "Script will be exited after config file is generated"
else
      echo "The full script will be run, including the cmsRun command and cleaning on the directory"
      if [ "$CLEANUP" ]
      then
            echo "Temporary files and directories will be cleaned up after script is finished"
      else
            echo "No files and directories will be cleaned up in the end,"
            echo "which is not recommended for large scale production (consider setting the -c flag)."
      fi
fi


CMSSW_VERSION=CMSSW_10_2_22

# The following part should not be manually configured

ERA=Run2_${YEAR}
NANOERA=$ERA,run2_nanoAOD_102Xv1

FRAGMENT_BASE_URL=https://rembserj.web.cern.ch/rembserj/genproduction/fragments
GRIDPACK_BASE_URL=https://rembserj.web.cern.ch/rembserj/genproduction/gridpacks

FRAGMENT=wmLHEGS-fragment-${YEAR}.py
GRIDPACK=${SAMPLE}_20200605_slc7_amd64_gcc630_CMSSW_9_3_16_tarball.tar.xz

OUTNAME=$SAMPLE-${CAMPAIGN}wmLHEGS

# RUN_GENERIC_TARBALL_PATCH=run_generic_tarball_cvmfs.patch
# Alternative version of the patch which also makes the production not delete the LHE files
RUN_GENERIC_TARBALL_PATCH=run_generic_tarball_cvmfs-keep_lhe.patch

#OUTPUT_DIR=${SAMPLE}_${YEAR}_GEN-SIM_0001
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r $CMSSW_VERSION/src ] ; then
 echo release $CMSSW_VERSION already exists
else
scram p CMSSW $CMSSW_VERSION
fi
cd $CMSSW_VERSION/src
eval `scram runtime -sh`

# Patch to have the improved weight producer for NanoAOD
git cms-merge-topic guitargeek:LHEWeightsTableProducer_10_2_22

# It's a bit unfortunate that we have to git cms-init indirectly just to patch one file..
# Just downloading this one file does not work because the package will be poisoned.
git cms-addpkg GeneratorInterface/LHEInterface

curl -s --insecure https://rembserj.web.cern.ch/rembserj/genproduction/patches/$RUN_GENERIC_TARBALL_PATCH --retry 2 --create-dirs -o $RUN_GENERIC_TARBALL_PATCH
[ -s $RUN_GENERIC_TARBALL_PATCH ] || exit $?;
patch GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh < $RUN_GENERIC_TARBALL_PATCH


curl -s --insecure $FRAGMENT_BASE_URL/$FRAGMENT --retry 2 --create-dirs -o Configuration/GenProduction/python/$FRAGMENT
[ -s Configuration/GenProduction/python/$FRAGMENT ] || exit $?;

scram b -j8
cd ../../

#insert gridpack path info fragment
PWDESC=$(echo $PWD | sed 's_/_\\/_g')
sed -i "s/\$GRIDPACK/$PWDESC\/$GRIDPACK/g" $CMSSW_VERSION/src/Configuration/GenProduction/python/$FRAGMENT

curl -s --insecure $GRIDPACK_BASE_URL/$GRIDPACK --retry 2 --create-dirs -o $GRIDPACK
[ -s $GRIDPACK ] || exit $?;


STEP0_NAME=${SAMPLE}-${CAMPAIGN}wmLHEGS
STEP1_NAME=${SAMPLE}-${CAMPAIGN}DRPremix_step1
STEP2_NAME=${SAMPLE}-${CAMPAIGN}DRPremix
STEP3_NAME=${SAMPLE}-${CAMPAIGN}MiniAOD
STEP4_NAME=${SAMPLE}-${CAMPAIGN}NanoAODv7

seed=$(($(date +%s)))
cmsDriver.py Configuration/GenProduction/python/$FRAGMENT \
    --fileout file:${STEP0_NAME}.root \
    --mc \
    --eventcontent RAWSIM,LHE \
    --datatier GEN-SIM,LHE \
    --conditions $CONDITIONS \
    --beamspot $BEAMSPOT \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --nThreads $NTHREADS \
    --era $ERA \
    --python_filename ${STEP0_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${seed})" \
    -n $NEVENTS

cmsDriver.py step1 \
    --filein file:${STEP0_NAME}.root \
    --fileout file:${STEP1_NAME}.root \
    --pileup_input "$PILEUP_INPUT" \
    --mc \
    --eventcontent PREMIXRAW \
    --datatier GEN-SIM-RAW \
    --conditions $CONDITIONS \
    --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval$YEAR \
    --procModifiers premix_stage2 \
    --nThreads $NTHREADS \
    --geometry DB:Extended \
    --datamix PreMix \
    --era $ERA \
    --python_filename ${STEP1_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

cmsDriver.py step2 \
    --filein file:${STEP1_NAME}.root \
    --fileout file:${STEP2_NAME}.root \
    --mc \
    --eventcontent AODSIM \
    --runUnscheduled \
    --datatier AODSIM \
    --conditions $CONDITIONS \
    --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI \
    --procModifiers premix_stage2 \
    --nThreads $NTHREADS \
    --era $ERA \
    --python_filename ${STEP2_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

cmsDriver.py step1 \
    --filein file:${STEP2_NAME}.root \
    --fileout file:${STEP3_NAME}.root \
    --mc \
    --eventcontent MINIAODSIM \
    --runUnscheduled \
    --datatier MINIAODSIM \
    --conditions $CONDITIONS \
    --step PAT \
    --nThreads $NTHREADS \
    --geometry DB:Extended \
    --era $ERA \
    --python_filename ${STEP3_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

cmsDriver.py step1 \
    --filein file:${STEP3_NAME}.root \
    --fileout file:${STEP4_NAME}.root \
    --mc \
    --eventcontent NANOAODSIM \
    --datatier NANOAODSIM \
    --conditions $CONDITIONS \
    --step NANO \
    --nThreads $NTHREADS \
    --era $NANOERA \
    --python_filename ${STEP4_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

# Validate the config files
python2 ${STEP0_NAME}_cfg.py
python2 ${STEP1_NAME}_cfg.py
python2 ${STEP2_NAME}_cfg.py
python2 ${STEP3_NAME}_cfg.py
python2 ${STEP4_NAME}_cfg.py

if [ "$DRY_RUN" ]
then
      exit 1
fi

cmsRun ${STEP0_NAME}_cfg.py || exit $? ;

# Get out LHE files out of temporary directory, so we can check them out if the want
mv lheevent/cmsgrid_final.lhe $OUTNAME.lhe
gzip $OUTNAME.lhe
rm -rf $GRIDPACK
rm -rf lheevent

cmsRun ${STEP1_NAME}_cfg.py || exit $? ;
cmsRun ${STEP2_NAME}_cfg.py || exit $? ;
cmsRun ${STEP3_NAME}_cfg.py || exit $? ;
cmsRun ${STEP4_NAME}_cfg.py || exit $? ;

# cleanup temporary working directories
if [ "$CLEANUP" ]
then
    # The full event after the premixig before recuding it to AOD is too large and too easy to recalculate to justify saving it
    rm ${STEP1_NAME}.root
    rm -rf $CMSSW_VERSION
fi
