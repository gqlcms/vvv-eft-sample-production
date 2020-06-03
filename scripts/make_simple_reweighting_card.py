import argparse
from dataclasses import dataclass

parameters_with_lhacode = {
    # "FS0": 1,
    # "FS1": 2,
    # "FS2": 3,
    # "FM0": 4,
    # "FM1": 5,
    # "FM2": 6,
    # "FM3": 7,
    # "FM4": 8,
    # "FM5": 9,
    # "FM6": 10,
    # "FM7": 11,
    "FT0": 12,
    # "FT1": 13,
    # "FT2": 14,
    # "FT3": 15,
    # "FT4": 16,
    # "FT5": 17,
    # "FT6": 18,
    # "FT7": 19,
    "FT8": 20,
    "FT9": 21,
}

def to_string(x):
    return str(x).replace("-", "m").replace(".", "p")


class ReweightingInfo(object):
    def __init__(self, parameters):
        """Takes a dictionary of parameters and their values which should be set to specific values.
        Model parameters not in the dictionary are set to zero.
        """
        # clean parameters which are set to zero
        parameters = {name: x for name, x in parameters.items() if x != 0}

        descr = []
        label = []

        for name in sorted(parameters.keys()):
            value = parameters[name]
            descr.append(f"{name} : {value}")
            label.append(f"{name}_{to_string(value)}")

        descr = ", ".join(descr)
        label = "__".join(label)

        if descr == "":
            descr = "Standard Model"
            label = "SM"

        text = [f"launch --rwgt_name=EFT__{label}"]

        for name, lhacode in parameters_with_lhacode.items():
            value = 0.0
            if name in parameters:
                value = float(parameters[name])
            text.append(f"set anoinputs {lhacode} {value}e-12 # {name}")

        self.label = label
        self.text = "\n".join(text)
        self.description = descr
        self.operators = set(parameters.keys())

    def __eq__(self, other):
        return self.label == other.label

    def __ge__(self, other):
        return self.label > other.label

    def __lt__(self, other):
        return self.label < other.label

    def __hash__(self):
        return hash(self.label)

reweightings = list()

# Don't forget the standard model!
reweightings.append(ReweightingInfo({}))

for x in [-10, -5, -1, 0, 1, 5, 10]:
    reweightings.append(ReweightingInfo({"FT0" : x}))

# for x in [-100, -50, -10, 10, 50, 100]:
    # reweightings.append(ReweightingInfo({"FT0" : x}))

# for name in ["FT8", "FT9"]:
    # for x in [-100, -50, -10, 10, 50, 100]:
        # reweightings.append(ReweightingInfo({name : x}))

# reweightings.append(ReweightingInfo({"FT8" : 50, "FT9" : 50}))


reweighting_card = """change mode NLO    # Define type of Reweighting. For LO sample this command
                   # has no effect since only "LO" mode is allowed.

change helicity False # has also been done in the example I got from Kenneth
change rwgt_dir rwgt
"""

for i_reweighting, reweighting in enumerate(reweightings):
    reweighting_card = (
        reweighting_card
        + f"# [{i_reweighting+1}/{len(reweightings)}] "
        + reweighting.description
        + "\n"
        + reweighting.text
        + "\n\n"
    )

print(reweighting_card)
