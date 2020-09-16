import argparse
from dataclasses import dataclass

parser = argparse.ArgumentParser(description="Generate reweighting cards for dim8 EFT studies.")
parser.add_argument("--wwww", action="store_true")
parser.add_argument("--zzzz", action="store_true")
parser.add_argument("--wwzz", action="store_true")

args = parser.parse_args()

parameters_with_lhacode = {
    "FS0": 1,
    "FS1": 2,
    "FS2": 3,
    "FM0": 4,
    "FM1": 5,
    "FM2": 6,
    "FM3": 7,
    "FM4": 8,
    "FM5": 9,
    "FM6": 10,
    "FM7": 11,
    "FT0": 12,
    "FT1": 13,
    "FT2": 14,
    "FT3": 15,
    "FT4": 16,
    "FT5": 17,
    "FT6": 18,
    "FT7": 19,
    "FT8": 20,
    "FT9": 21,
}

# The information which operator plays a role in which coupling, so we can "prune" them if not needed
# We don't know where FS2, FT3 and FT4 come into play, to let's pretend they play a role everywhere
# http://feynrules.irmp.ucl.ac.be/attachment/wiki/AnomalousGaugeCoupling/quartic.pdf
wwww_operators = {"FS0", "FS1", "FM0", "FM1", "FM6", "FM7", "FT0", "FT1", "FT2"}
wwzz_operators = wwww_operators.union({"FM2", "FM3", "FM4", "FM5", "FT5", "FT6", "FT7"})
zzzz_operators = wwzz_operators.union({"FT8", "FT9"})
all_operators = wwww_operators.union(wwzz_operators).union(zzzz_operators)

# Make sure we didn't forget any physical operators
assert len(all_operators) + 3 == len(parameters_with_lhacode)

# The operators which are allowed with the flags from the commandline
allowed_operators = set()
if args.wwww:
    allowed_operators = allowed_operators.union(wwww_operators)
if args.wwzz:
    allowed_operators = allowed_operators.union(wwzz_operators)
if args.zzzz:
    allowed_operators = allowed_operators.union(zzzz_operators)


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


def accept(values):
    n_nonzero = len(values) - values.count(0)

    # We don't need to have more than two operators != zeros,
    # because there is no intereference between more than two
    # operators
    if n_nonzero > 2:
        return False

    # It's also not necessary to have negative operator values
    # in case two operators are non-zero.  We need these points
    # only for the interference term and one sample per
    # operator pair is enough, so we might as well choose the
    # positive quadrant.
    if n_nonzero == 2:
        if any([x < 0 for x in values]):
            return False

    # We could reduce the grid more, but it's good to have some
    # redundancy for cross checks and to avoid the situation
    # where the choice of the grid causes numerical
    # instabilites.
    return True


# We start with an n-dimensional grid of these values for each operator, plus
# the same values with a minus sign.  Then, we remove most of the points again
# (see comments in the loop).
# values = [0, 1, 5, 100]
values = [0, 1, 5]

# add negative values
values = values + [-x for x in values if not x == 0]

i_reweight = 0

reweightings = []

# For the 3 most sensitive operators, we like to have a grid
# so we could also measure correlations
for ft0 in values:
    for ft1 in values:
        for ft2 in values:
            value_dict = {"FT0": ft0, "FT1": ft1, "FT2": ft2}

            if accept(list(value_dict.values())):
                i_reweight += 1

                reweightings.append(ReweightingInfo(value_dict))

# We would like to add at least plus/minus 1 for each possible parameter
for name in parameters_with_lhacode.keys():
    reweightings.append(ReweightingInfo({name: 1}))
    reweightings.append(ReweightingInfo({name: -1}))

# Don't forget the standard model!
reweightings.append(ReweightingInfo({}))


def is_allowed(reweighting):
    return all([op in allowed_operators for op in reweighting.operators])


reweightings = filter(is_allowed, reweightings)

# Remove duplicate grid points
reweightings = sorted(list(set(reweightings)))

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
