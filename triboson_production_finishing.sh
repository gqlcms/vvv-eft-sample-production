#!/usr/bin/bash

# In case the steps after GEN-SIM failed for some reason (e.g. temporary
# problems with getting the pileup files), you can use this script to attempt
# the remaining steps again and clean up the  environment if successful.

cd CMSSW_10_2_22/src
eval `scramv1 runtime -sh`
cd ../..

cmsRun  WWW_dim8-RunIIAutumn18DRPremix_step1_cfg.py  || exit $? ;
cmsRun WWW_dim8-RunIIAutumn18DRPremix_cfg.py  || exit $? ;
cmsRun WWW_dim8-RunIIAutumn18MiniAOD_cfg.py  || exit $? ;
cmsRun WWW_dim8-RunIIAutumn18NanoAODv7_cfg.py  || exit $? ;
cmsRun WWW_dim8-RunIIAutumn18NanoEDMAODv7_cfg.py  || exit $? ;

rm -rf CMSSW_10_2_22 sub* triboson_production.sh WWW_dim8-RunIIAutumn18DRPremix_step1.root *.py
