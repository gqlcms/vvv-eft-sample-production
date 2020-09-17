#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
YEAR=2018
NTHREADS=8
FILTER="inclusive"

while getopts "h?y:s:n:o:dcp:f:" opt; do
    case "$opt" in
    h|\?)
        echo 'triboson-production -y YEAR -s SAMPLE -n NEVENTS -o OUTPUT_DIR -p PILEUP_FILES [-d -c]

If the -d (dry run) flag is set, only the environment and the config file will be created.
otherwise, the cmsRun command will be executed.

The -c flag enables the cleanup of temporary directories in the end, which is recommended for
large scale production to save space.

PILEUP_FILES needs to be a file in which the the pileup files are listed, separated by newlines.
You can get this list with the dasgoclient:
    dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISpring15PrePremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v2-v2/GEN-SIM-DIGI-RAW" > pileup_files_2016.txt
    dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer17PrePremix-MCv2_correctPU_94X_mc2017_realistic_v9-v1/GEN-SIM-DIGI-RAW" > pileup_files_2017.txt
    dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW" > pileup_files_2018.txt'
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
    f)  FILTER=$OPTARG
        # filter should be either "inclusive", "single-lepton" or "double-lepton"
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

2016)  echo "The year is $YEAR"
    CONDITIONS=80X_mcRun2_asymptotic_2016_TrancheIV_v6
    CONDITIONS_FOR_GEN=$CONDITIONS
    CONDITIONS_FOR_PREMIX=$CONDITIONS
    CONDITIONS_FOR_RECO=$CONDITIONS
    CONDITIONS_FOR_MINI=94X_mcRun2_asymptotic_v3
    CONDITIONS_FOR_NANO=102X_mcRun2_asymptotic_v8
    CAMPAIGN=RunIISummer16
    ERA=Run2_${YEAR}
    MINIERA=$ERA,run2_miniAOD_80XLegacy
    NANOERA=$ERA,run2_nanoAOD_94X2016
    PREMIX_STEP=DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:@frozen2016
    RECO_STEP=RAW2DIGI,RECO,EI
    BEAMSPOT=Realistic50ns13TeVCollision # yes, 50 ns is not correct but this is also used in official 2016 MC productions
    CMSSW_VERSION_FOR_RECO=CMSSW_8_0_21
    CMSSW_VERSION_FOR_MINI=CMSSW_9_4_17
    CMSSW_VERSION_FOR_NANO=CMSSW_10_2_22
    ;;
2017)  echo "The year is $YEAR"
    CONDITIONS=94X_mc2017_realistic_v17
    CONDITIONS_FOR_GEN=$CONDITIONS
    CONDITIONS_FOR_PREMIX=$CONDITIONS
    CONDITIONS_FOR_RECO=$CONDITIONS
    CONDITIONS_FOR_MINI=$CONDITIONS
    CONDITIONS_FOR_NANO=102X_mc2017_realistic_v8
    BEAMSPOT=Realistic25ns13TeVEarly2017Collision
    CAMPAIGN=RunIIFall17
    ERA=Run2_${YEAR}
    MINIERA=$ERA,run2_miniAOD_94XFall17
    NANOERA=$ERA,run2_nanoAOD_94XMiniAODv2
    PREMIX_STEP=DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:2e34v40
    RECO_STEP=RAW2DIGI,L1Reco,RECO,RECOSIM,EI
    CMSSW_VERSION_FOR_RECO=CMSSW_9_4_17
    CMSSW_VERSION_FOR_MINI=CMSSW_9_4_17
    CMSSW_VERSION_FOR_NANO=CMSSW_10_2_22
    ;;
2018)  echo "The year is $YEAR"
    CONDITIONS=102X_upgrade2018_realistic_v20
    CONDITIONS_FOR_GEN=$CONDITIONS
    CONDITIONS_FOR_PREMIX=$CONDITIONS
    CONDITIONS_FOR_RECO=$CONDITIONS
    CONDITIONS_FOR_MINI=$CONDITIONS
    CONDITIONS_FOR_NANO=102X_upgrade2018_realistic_v20
    BEAMSPOT=Realistic25ns13TeVEarly2018Collision
    CAMPAIGN=RunIIAutumn18
    ERA=Run2_${YEAR}
    MINIERA=$ERA
    NANOERA=$ERA,run2_nanoAOD_102Xv1
    PREMIX_STEP=DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval$YEAR
    RECO_STEP=RAW2DIGI,L1Reco,RECO,RECOSIM,EI
    PREMIX_ARGS="--procModifiers premix_stage2 --geometry DB:Extended"
    RECO_ARGS="--procModifiers premix_stage2"
    CMSSW_VERSION_FOR_RECO=CMSSW_10_2_22
    CMSSW_VERSION_FOR_MINI=CMSSW_10_2_22
    CMSSW_VERSION_FOR_NANO=CMSSW_10_2_22
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

# The following part should not be manually configured

FRAGMENT_BASE_URL=https://raw.githubusercontent.com/guitargeek/vvv-eft-sample-production/master/genproduction-fragments
GRIDPACK_BASE_URL=https://rembserj.web.cern.ch/rembserj/genproduction/gridpacks

FRAGMENT=wmLHEGS-fragment-${YEAR}-${FILTER}.py
GRIDPACK=${SAMPLE}_20200605_slc7_amd64_gcc630_CMSSW_9_3_16_tarball.tar.xz

OUTNAME=$SAMPLE-${CAMPAIGN}wmLHEGS

# RUN_GENERIC_TARBALL_PATCH=run_generic_tarball_cvmfs.patch
# Alternative version of the patch which also makes the production not delete the LHE files
RUN_GENERIC_TARBALL_PATCH=run_generic_tarball_cvmfs-keep_lhe.patch

#OUTPUT_DIR=${SAMPLE}_${YEAR}_GEN-SIM_0001
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r $CMSSW_VERSION_FOR_NANO/src ] ; then
 echo release $CMSSW_VERSION_FOR_NANO already exists
else
scram p CMSSW $CMSSW_VERSION_FOR_NANO
fi
cd $CMSSW_VERSION_FOR_NANO/src
eval `scram runtime -sh`

# Patch to have the improved weight producer for NanoAOD
git cms-merge-topic guitargeek:LHEWeightsTableProducer_10_2_22

scram b -j8
cd ../../

# checkout cmssw version for reco
mkdir cmssw_for_reco
cd cmssw_for_reco
cmsrel $CMSSW_VERSION_FOR_RECO
cd $CMSSW_VERSION_FOR_RECO/src
cmsenv

# It's a bit unfortunate that we have to git cms-init indirectly just to patch one file..
# Just downloading this one file does not work because the package will be poisoned.
git cms-addpkg GeneratorInterface/LHEInterface

curl -s --insecure https://rembserj.web.cern.ch/rembserj/genproduction/patches/$RUN_GENERIC_TARBALL_PATCH --retry 2 --create-dirs -o $RUN_GENERIC_TARBALL_PATCH
[ -s $RUN_GENERIC_TARBALL_PATCH ] || exit $?;
patch GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh < $RUN_GENERIC_TARBALL_PATCH


curl -s --insecure $FRAGMENT_BASE_URL/$FRAGMENT --retry 2 --create-dirs -o Configuration/GenProduction/python/$FRAGMENT
[ -s Configuration/GenProduction/python/$FRAGMENT ] || exit $?;

scram b -j8
cd ../../..

#insert gridpack path info fragment
PWDESC=$(echo $PWD | sed 's_/_\\/_g')
sed -i "s/\$GRIDPACK/$PWDESC\/$GRIDPACK/g" cmssw_for_reco/$CMSSW_VERSION_FOR_RECO/src/Configuration/GenProduction/python/$FRAGMENT

curl -s --insecure $GRIDPACK_BASE_URL/$GRIDPACK --retry 2 --create-dirs -o $GRIDPACK
[ -s $GRIDPACK ] || exit $?;

STEP0_NAME=${SAMPLE}-${CAMPAIGN}wmLHEGS
STEP1_NAME=${SAMPLE}-${CAMPAIGN}DRPremix_step1
STEP2_NAME=${SAMPLE}-${CAMPAIGN}DRPremix
STEP3_NAME=${SAMPLE}-${CAMPAIGN}MiniAOD
STEP4_NAME=${SAMPLE}-${CAMPAIGN}NanoEDMAODv7
STEP5_NAME=${SAMPLE}-${CAMPAIGN}NanoAODv7

seed=$(($(date +%s) % 900000000))
cmsDriver.py Configuration/GenProduction/python/$FRAGMENT \
    --fileout file:${STEP0_NAME}.root \
    --mc \
    --eventcontent RAWSIM,LHE \
    --datatier GEN-SIM,LHE \
    --conditions $CONDITIONS_FOR_GEN \
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

python2 ${STEP0_NAME}_cfg.py

cmsDriver.py step1 \
    --filein file:${STEP0_NAME}.root \
    --fileout file:${STEP1_NAME}.root \
    --pileup_input "$PILEUP_INPUT" \
    --mc \
    --eventcontent PREMIXRAW \
    --datatier GEN-SIM-RAW \
    --conditions $CONDITIONS_FOR_PREMIX \
    --step $PREMIX_STEP \
    $PREMIX_ARGS \
    --nThreads $NTHREADS \
    --datamix PreMix \
    --era $ERA \
    --python_filename ${STEP1_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

python2 ${STEP1_NAME}_cfg.py

cmsDriver.py step2 \
    --filein file:${STEP1_NAME}.root \
    --fileout file:${STEP2_NAME}.root \
    --mc \
    --eventcontent AODSIM \
    --runUnscheduled \
    --datatier AODSIM \
    --conditions $CONDITIONS_FOR_RECO \
    --step $RECO_STEP \
    $RECO_ARGS \
    --nThreads $NTHREADS \
    --era $ERA \
    --python_filename ${STEP2_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

python2 ${STEP2_NAME}_cfg.py

# checkout cmssw version for mini
mkdir cmssw_for_mini
cd cmssw_for_mini
cmsrel $CMSSW_VERSION_FOR_MINI
cd $CMSSW_VERSION_FOR_MINI/src
cmsenv
cd ../../..

cmsDriver.py step1 \
    --filein file:${STEP2_NAME}.root \
    --fileout file:${STEP3_NAME}.root \
    --mc \
    --eventcontent MINIAODSIM \
    --runUnscheduled \
    --datatier MINIAODSIM \
    --conditions $CONDITIONS_FOR_MINI \
    --step PAT \
    --nThreads $NTHREADS \
    --geometry DB:Extended \
    --era $MINIERA \
    --python_filename ${STEP3_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

python2 ${STEP3_NAME}_cfg.py

# set gen/nano environment
cd $CMSSW_VERSION_FOR_NANO/src
cmsenv
cd ../..


cmsDriver.py step1 \
    --filein file:${STEP3_NAME}.root \
    --fileout file:${STEP4_NAME}.root \
    --mc \
    --eventcontent NANOEDMAODSIM \
    --datatier NANOAODSIM \
    --conditions $CONDITIONS_FOR_NANO \
    --step NANO \
    --nThreads $NTHREADS \
    --era $NANOERA \
    --python_filename ${STEP4_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

python2 ${STEP4_NAME}_cfg.py

cmsDriver.py step1 \
    --filein file:${STEP3_NAME}.root \
    --fileout file:${STEP5_NAME}.root \
    --mc \
    --eventcontent NANOAODSIM \
    --datatier NANOAODSIM \
    --conditions $CONDITIONS_FOR_NANO \
    --step NANO \
    --nThreads $NTHREADS \
    --era $NANOERA \
    --python_filename ${STEP5_NAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n $NEVENTS

# Validate the config files
python2 ${STEP5_NAME}_cfg.py

if [ "$DRY_RUN" ]
then
      exit 1
fi

# set again reco environment
cd cmssw_for_reco/$CMSSW_VERSION_FOR_RECO/src
cmsenv
cd ../../..


cmsRun ${STEP0_NAME}_cfg.py || exit $? ;

# Get out LHE files out of temporary directory, so we can check them out if the want
mv lheevent/cmsgrid_final.lhe $OUTNAME.lhe
gzip $OUTNAME.lhe
rm -rf $GRIDPACK
rm -rf lheevent

cmsRun ${STEP1_NAME}_cfg.py || exit $? ;
cmsRun ${STEP2_NAME}_cfg.py || exit $? ;

# set mini environment
cd cmssw_for_mini/$CMSSW_VERSION_FOR_MINI/src
cmsenv
cd ../../..

cmsRun ${STEP3_NAME}_cfg.py || exit $? ;

# set nano environment
cd $CMSSW_VERSION_FOR_NANO/src
cmsenv
cd ../..

cmsRun ${STEP4_NAME}_cfg.py || exit $? ;
cmsRun ${STEP5_NAME}_cfg.py || exit $? ;

# cleanup temporary working directories
if [ "$CLEANUP" ]
then
    # The full event after the premixig before recuding it to AOD is too large and too easy to recalculate to justify saving it
    rm ${STEP1_NAME}.root

    rm -rf $CMSSW_VERSION_FOR_NANO
    rm -rf cmssw_for_reco
    rm -rf cmssw_for_mini
    rm -rf *_cfg.py
fi
