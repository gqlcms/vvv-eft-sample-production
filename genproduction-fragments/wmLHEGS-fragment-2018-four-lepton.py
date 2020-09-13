import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer(
    "ExternalLHEProducer",
    args=cms.vstring(["$GRIDPACK"]),
    nEvents=cms.untracked.uint32(5000),
    numberOfParameters=cms.uint32(1),
    outputFile=cms.string("cmsgrid_final.lhe"),
    scriptName=cms.FileInPath("GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh"),
)


from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *
from Configuration.Generator.Pythia8aMCatNLOSettings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *

generator = cms.EDFilter(
    "Pythia8HadronizerFilter",
    maxEventsToPrint=cms.untracked.int32(1),
    pythiaPylistVerbosity=cms.untracked.int32(1),
    filterEfficiency=cms.untracked.double(1.0),
    pythiaHepMCVerbosity=cms.untracked.bool(False),
    comEnergy=cms.double(13000.0),
    PythiaParameters=cms.PSet(
        pythia8CommonSettingsBlock,
        pythia8CP5SettingsBlock,
        pythia8aMCatNLOSettingsBlock,
        pythia8PSweightsSettingsBlock,
        processParameters=cms.vstring(
            "TimeShower:nPartonsInBorn = 0",  # number of coloured particles (before resonance decays) in born matrix element
            "23:mMin = 0.05",
            "24:mMin = 0.05",
            "ResonanceDecayFilter:filter = on",
            "ResonanceDecayFilter:exclusive = off", #off: require at least the specified number of daughters, on: require exactly the specified number of daughters
            "ResonanceDecayFilter:eMuAsEquivalent = off", #on: treat electrons and muons as equivalent
            "ResonanceDecayFilter:eMuTauAsEquivalent = on", #on: treat electrons, muons , and taus as equivalent
            "ResonanceDecayFilter:allNuAsEquivalent = on", #on: treat all three neutrino flavours as equivalent
            #'ResonanceDecayFilter:mothers =', #list of mothers not specified -> count all particles in hard process+resonance decays (better to avoid specifying mothers when including leptons from the lhe in counting, since intermediate resonances are not gauranteed to appear in general
            "ResonanceDecayFilter:daughters = 11,11,11,11"
        ),
        parameterSets=cms.vstring(
            "pythia8CommonSettings",
            "pythia8CP5Settings",
            "pythia8aMCatNLOSettings",
            "processParameters",
            "pythia8PSweightsSettings",
        ),
    ),
)


ProductionFilterSequence = cms.Sequence(generator)
