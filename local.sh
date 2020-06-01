#!/bin/bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc630
if [ -r CMSSW_9_3_4/src ] ; then 
 echo release CMSSW_9_3_4 already exists
else
scram p CMSSW CMSSW_9_3_4
fi
cd CMSSW_9_3_4/src
eval `scram runtime -sh`

# curl -s --insecure https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/SMP-RunIIFall17wmLHEGS-00059 --retry 2 --create-dirs -o Configuration/GenProduction/python/SMP-RunIIFall17wmLHEGS-00059-fragment.py 
# [ -s Configuration/GenProduction/python/SMP-RunIIFall17wmLHEGS-00059-fragment.py ] || exit $?;

echo "" > MY_FRAGMENT.py
echo "import FWCore.ParameterSet.Config as cms" >> MY_FRAGMENT.py
echo ""
echo "externalLHEProducer = cms.EDProducer(\"ExternalLHEProducer\"," >> MY_FRAGMENT.py
echo "    args = cms.vstring('/nfs-7/userdata/yxiang/VBSWWH_slc6_amd64_gcc630_CMSSW_9_3_4_tarball.tar.xz')," >> MY_FRAGMENT.py
echo "    nEvents = cms.untracked.uint32(10000)," >> MY_FRAGMENT.py
echo "    numberOfParameters = cms.uint32(1)," >> MY_FRAGMENT.py
echo "    outputFile = cms.string('cmsgrid_final.lhe')," >> MY_FRAGMENT.py
echo "    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')" >> MY_FRAGMENT.py
echo ")" >> MY_FRAGMENT.py
echo "from Configuration.Generator.Pythia8CommonSettings_cfi import *" >> MY_FRAGMENT.py
echo "from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *" >> MY_FRAGMENT.py
echo "from Configuration.Generator.Pythia8aMCatNLOSettings_cfi import *" >> MY_FRAGMENT.py
echo "" >> MY_FRAGMENT.py
echo "generator = cms.EDFilter(\"Pythia8HadronizerFilter\"," >> MY_FRAGMENT.py
echo "                         maxEventsToPrint = cms.untracked.int32(1)," >> MY_FRAGMENT.py
echo "                         pythiaPylistVerbosity = cms.untracked.int32(1)," >> MY_FRAGMENT.py
echo "                         filterEfficiency = cms.untracked.double(1.0)," >> MY_FRAGMENT.py
echo "                         pythiaHepMCVerbosity = cms.untracked.bool(False)," >> MY_FRAGMENT.py
echo "                         comEnergy = cms.double(13000.)," >> MY_FRAGMENT.py
echo "                         PythiaParameters = cms.PSet(" >> MY_FRAGMENT.py
echo "                            pythia8CommonSettingsBlock," >> MY_FRAGMENT.py
echo "                            pythia8CP5SettingsBlock," >> MY_FRAGMENT.py
echo "                            pythia8aMCatNLOSettingsBlock," >> MY_FRAGMENT.py
echo "                            processParameters = cms.vstring(" >> MY_FRAGMENT.py
echo "                                'TimeShower:nPartonsInBorn = 0', #number of coloured particles (before resonance decays) in born matrix element" >> MY_FRAGMENT.py
echo "                                )," >> MY_FRAGMENT.py
echo "                            parameterSets = cms.vstring('pythia8CommonSettings'," >> MY_FRAGMENT.py
echo "                                    'pythia8CP5Settings'," >> MY_FRAGMENT.py
echo "                                    'pythia8aMCatNLOSettings'," >> MY_FRAGMENT.py
echo "                                    'processParameters'," >> MY_FRAGMENT.py
echo "                                    )" >> MY_FRAGMENT.py
echo "                            )" >> MY_FRAGMENT.py
echo "                         )" >> MY_FRAGMENT.py
echo "ProductionFilterSequence = cms.Sequence(generator)" >> MY_FRAGMENT.py


mkdir -p Configuration/GenProduction/python
cp MY_FRAGMENT.py Configuration/GenProduction/python/SMP-RunIIFall17wmLHEGS-00059-fragment.py
scram b
cd ../../
cmsDriver.py Configuration/GenProduction/python/SMP-RunIIFall17wmLHEGS-00059-fragment.py \
    --fileout file:file_GEN-SIM__LHE.root \
    --mc \
    --eventcontent RAWSIM,LHE \
    --datatier GEN-SIM,LHE \
    --conditions 93X_mc2017_realistic_v3 \
    --beamspot Realistic25ns13TeVEarly2017Collision \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --era Run2_2017 \
    --python_filename SMP-RunIIFall17wmLHEGS-00059_1_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n 10000 || exit $? ;
cmsRun -e -j GEN-SIM,LHE.xml SMP-RunIIFall17wmLHEGS-00059_1_cfg.py
#!/bin/bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc630
if [ -r CMSSW_9_4_0_patch1/src ] ; then
 echo release CMSSW_9_4_0_patch1 already exists
else
scram p CMSSW CMSSW_9_4_0_patch1
fi
cd CMSSW_9_4_0_patch1/src
eval `scram runtime -sh`


scram b
cd ../../
cmsDriver.py step1 \
    --filein file:file_GEN-SIM__LHE.root \
    --fileout file:file_GEN-SIM-RAW.root \
    --pileup_input "file:/hadoop/cms/store/user/phchang/pileupfiles/F4CEFFB5-FC0E-E811-A015-0025905B857E.root" \
    --mc \
    --eventcontent PREMIXRAW \
    --datatier GEN-SIM-RAW \
    --conditions 94X_mc2017_realistic_v11 \
    --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:2e34v40 \
    --nThreads 8 \
    --datamix PreMix \
    --era Run2_2017 \
    --python_filename SMP-RunIIFall17DRPremix-00015_1_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n 10000 || exit $? ;
cmsRun -e -j GEN-SIM-RAW.xml SMP-RunIIFall17DRPremix-00015_1_cfg.py

cmsDriver.py step2 \
    --filein file:file_GEN-SIM-RAW.root \
    --fileout file:file_AODSIM.root \
    --mc \
    --eventcontent AODSIM \
    --runUnscheduled \
    --datatier AODSIM \
    --conditions 94X_mc2017_realistic_v11 \
    --step RAW2DIGI,RECO,RECOSIM,EI \
    --nThreads 8 \
    --era Run2_2017 \
    --python_filename SMP-RunIIFall17DRPremix-00015_2_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n 10000 || exit $? ;
cmsRun -e -j AODSIM.xml SMP-RunIIFall17DRPremix-00015_2_cfg.py
#!/bin/bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc630
if [ -r CMSSW_9_4_6_patch1/src ] ; then
 echo release CMSSW_9_4_6_patch1 already exists
else
scram p CMSSW CMSSW_9_4_6_patch1
fi
cd CMSSW_9_4_6_patch1/src
eval `scram runtime -sh`


scram b
cd ../../
cmsDriver.py step1 \
    --filein file:file_AODSIM.root \
    --fileout file:file_MINIAODSIM.root \
    --mc \
    --eventcontent MINIAODSIM \
    --runUnscheduled \
    --datatier MINIAODSIM \
    --conditions 94X_mc2017_realistic_v14 \
    --step PAT \
    --nThreads 4 \
    --scenario pp \
    --era Run2_2017,run2_miniAOD_94XFall17 \
    --python_filename SMP-RunIIFall17MiniAODv2-00024_1_cfg.py \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    -n 10000 || exit $? ;
cmsRun -e -j MINIAODSIM.xml SMP-RunIIFall17MiniAODv2-00024_1_cfg.py
