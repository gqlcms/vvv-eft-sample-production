# EFT Sample Production for VVV Analysis
Tools, scripts and documentation to generate VVV samples for triboson analysis.

## Setup

1. Get a `CMSSW_10_2_22` environment.

2. Download Madgraph and quartic coupling model:
   ```bash
   wget https://launchpad.net/mg5amcnlo/2.0/2.6.x/+download/MG5_aMC_v2.6.7.tar.gz
   tar -xf MG5_aMC_v2.6.7.tar.gz
   cd MG5_aMC_v2_6_7
   cd models
   wget --no-check-certificate https://cms-project-generators.web.cern.ch/cms-project-generators/SM_Ltotal_Ind5v2020v2_UFO.zip
   unzip SM_Ltotal_Ind5v2020v2_UFO.zip
   cd ../..
   ```

3. Generate reweighting card (check out file for description of grid):
   ```
   python scripts/make_reweighting_card.py > reweight_card.dat
   python scripts/make_reweighting_card.py --include-zzzz-operators > reweight_card_zzz.dat
   ```
   The default version creates a grid with only T0, T1, and T2, the second version adds the T8 and T9 operators which only contribute to ZZZ.

4. Command Madgraph:
   ```
   import model SM_Ltotal_Ind5v2020v2_UFO
   define wpm = w+ w-
   generate p p > z z z NP=1
   output zzz
   launch
   ```
   Make the following edits in the cards:
   * enable madspin
   * set to 100k events
   * set nominal values of anomalous parameters to zero, except for FT9 to 5.0e-12 (or FT0 for non-ZZZ samples because FT9 has no effect)
     such that the high mass tails are sufficiently populated.
   * copy-paste the reweighting commands generated by the python script into the reweighting card

   This should be done also for WWW, WWZ, WZZ and not only ZZZ.

## Notes

* **Reweighting** 1 million events for one new point in operator space **takes 30 minutes**!
  Be careful to not have a too large grid.
* Don't run two instances of madgraph in the same directory when doing the reweightig! The first instance creates a temp directory `rwgt` which the others also try to read. The others will then crash.
* It seems the compiling step for MadSpin takes very very long when W-Bosons are in the final state. Avoid doing this for checks  of small sample size
