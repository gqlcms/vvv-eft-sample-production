import argparse

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--include-zzzz-operators', action='store_true')

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


def to_string(x):
    return str(x).replace("-", "m").replace(".", "p")


def make_reweighting_commands(value_dict):
    """Takes a dictionary of parameters and their values which should be set to specific values.
    Model parameters not in the dictionary are set to zero.
    """

    descr = []

    label = []
    for name, value in value_dict.items():
        descr.append(f"{name} : {value}")
        label.append(f"{name}_{to_string(value)}")

    descr = ", ".join(descr)
    label = "__".join(label)

    print(f"# {descr}")
    print(f"launch --rwgt_name=EFT__{label}")

    for name, lhacode in parameters_with_lhacode.items():
        value = 0.0
        if name in value_dict:
            value = float(value_dict[name])
        print(f"set anoinputs {lhacode} {value}e-12 # {name}")


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
values = [0, 1, 5, 100]

# add negative values
values = values + [-x for x in values if not x == 0]

print("change mode NLO    # Define type of Reweighting. For LO sample this command")
print('                   # has no effect since only "LO" mode is allowed.')
print("")
print("change helicity False # has also been done in the example I got from Kenneth")
print("change rwgt_dir rwgt")
print("")

i_reweight = 0

if args.include_zzzz_operators:
    for ft0 in values:
        for ft1 in values:
            for ft2 in values:
                for ft8 in values:
                    for ft9 in values:
                        value_dict = {"FT0": ft0, "FT1": ft1, "FT2": ft2, "FT8": ft8, "FT9": ft9}

                        if accept(list(value_dict.values())):
                            i_reweight += 1

                            make_reweighting_commands(value_dict)
                            print("")
else:
    for ft0 in values:
        for ft1 in values:
            for ft2 in values:
                value_dict = {"FT0": ft0, "FT1": ft1, "FT2": ft2}

                if accept(list(value_dict.values())):
                    i_reweight += 1

                    make_reweighting_commands(value_dict)
                    print("")
