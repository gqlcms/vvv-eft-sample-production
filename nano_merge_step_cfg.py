"""
This config has been generated (and manually fixed) with the following code snippet:

>> from Configuration.DataProcessing.Merge import mergeProcess
>> 
>> process = mergeProcess(
>>     infiles,
>>     process_name = "Merge",
>>     output_file = "Merged.root",
>>     output_lfn = None,
>>     newDQMIO = False,
>>     mergeNANO = True,
>>     bypassVersionCheck = False)
>>>
>> print(process.dumpPython())
"""

import FWCore.ParameterSet.Config as cms
import os
from PhysicsTools.NanoAOD.NanoAODEDMEventContent_cff import NANOAODSIMEventContent

nano_event_content = NANOAODSIMEventContent

start = 1
outfile = "file-001.root"
n_miniaod_files = 100

infiles = []
for i in range(start, start + n_miniaod_files):
    job_dir = "job-{0:05d}".format(i)
    base = "file:/home/llr/cms/rembser/scratch/production/WWW_dim8_20200605_inclusive_RunIIAutumn18/"
    infiles.append(base + os.path.join(job_dir, "WWW_dim8-RunIIAutumn18NanoEDMAODv7.root"))

process = cms.Process("Merge")

process.source = cms.Source(
    "PoolSource",
    bypassVersionCheck=cms.untracked.bool(False),
    fileNames=cms.untracked.vstring(infiles),
    duplicateCheckMode=cms.untracked.string("noDuplicateCheck"),  # default: checkAllFilesOpened
)

process.Merged = cms.OutputModule("NanoAODOutputModule",
    compressionAlgorithm = cms.untracked.string('LZMA'),
    compressionLevel = cms.untracked.int32(9),
    fileName = cms.untracked.string(outfile),
    outputCommands = cms.untracked.vstring(
        'drop *', 
        'keep *_lheWeightsTable_*_*', 
        'keep nanoaodFlatTable_*Table_*_*', 
        'keep edmTriggerResults_*_*_*', 
        'keep String_*_genModel_*', 
        'keep nanoaodMergeableCounterTable_*Table_*_*', 
        'keep nanoaodUniqueString_nanoMetadata_*_*'
    )
)

process.InitRootHandlers = cms.Service("InitRootHandlers", EnableIMT=cms.untracked.bool(False))

process.outputPath = cms.EndPath(process.Merged)
