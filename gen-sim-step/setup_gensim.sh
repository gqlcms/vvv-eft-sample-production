#!/bin/bash

# Ecexute this script in clean directory.

SAMPLE=$1 # e.g. WWW_dim8, WZZ_dim8, WWZ_dim8 or ZZZ_dim8
YEAR=$2 # e.g 2016, 2017 or 2018

echo "The sample is $SAMPLE"

case "$YEAR" in

2016)  echo "The year is $YEAR"
    CONDITIONS=80X_mcRun2_asymptotic_2016_TrancheIV_v8
    BEAMSPOT=Realistic50ns13TeVCollision # yes, 50 ns is not correct but this is also used in official 2016 MC productions
    ;;
2017)  echo "The year is $YEAR"
    CONDITIONS=94X_mc2017_realistic_v17
    BEAMSPOT=Realistic25ns13TeVEarly2017Collision
    ;;
2018)  echo "The year is $YEAR"
    CONDITIONS=102X_upgrade2018_realistic_v20 \
    BEAMSPOT=Realistic25ns13TeVEarly2018Collision \
    ;;
*) echo "Year $YEAR is not valid"
   exit
   ;;
esac

CMSSW_VERSION=CMSSW_10_2_22
N_EVENTS=100

#export SCRAM_ARCH=slc6_amd64_gcc700

# The following part should not be manually configured

ERA=Run2_${YEAR}

FRAGMENT_BASE_URL=https://rembserj.web.cern.ch/rembserj/genproduction/fragments
GRIDPACK_BASE_URL=https://rembserj.web.cern.ch/rembserj/genproduction/gridpacks

FRAGMENT=wmLHEGS-fragment-${YEAR}.py
GRIDPACK=${SAMPLE}_20200602_slc7_amd64_gcc630_CMSSW_9_3_16_tarball.tar.xz

OUTNAME=$SAMPLE-$YEAR-wmLHEGS

# RUN_GENERIC_TARBALL_PATCH=run_generic_tarball_cvmfs.patch
# Alternative version of the patch which also makes the production not delete the LHE files
RUN_GENERIC_TARBALL_PATCH=run_generic_tarball_cvmfs-keep_lhe.patch

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r $CMSSW_VERSION/src ] ; then
 echo release $CMSSW_VERSION already exists
else
scram p CMSSW $CMSSW_VERSION
fi
cd $CMSSW_VERSION/src
eval `scram runtime -sh`

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

seed=$(($(date +%s) % 100 + 1))
cmsDriver.py Configuration/GenProduction/python/$FRAGMENT \
    --fileout file:$OUTNAME.root \
    --mc \
    --eventcontent RAWSIM,LHE \
    --datatier GEN-SIM,LHE \
    --conditions $CONDITIONS \
    --beamspot $BEAMSPOT \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --era $ERA \
    --python_filename ${OUTNAME}_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${seed})" \
    -n $N_EVENTS \
    || exit $? ;

# Validate the config file
python2 ${OUTNAME}_cfg.py
