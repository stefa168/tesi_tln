import json
import glob
import os
import numpy as np
from scipy.stats import pearsonr

###############################################################################
# 1) Define label → numeric mappings for each ordinal field
###############################################################################
MAP_CLEARNESS = {
    "Completely clear": 2,
    "Mostly clear": 1,
    "Unclear": 0
}

MAP_LENGTH = {
    "Too long": 1,
    "Long enough": 2,
    "Too short": 0
}

MAP_USEFULNESS = {
    "Useful": 2,
    "Neither useful nor useless": 1,
    "Useless": 0
}

# 'Like' is binary, but we can treat it as ordinal (1 vs. 0)
MAP_LIKE = {
    "Yes": 1,
    "No": 0
}

# For convenience, keep references to these mappings in one dictionary:
DIMENSION_MAPPINGS = {
    "Answer Clearness": MAP_CLEARNESS,
    "Answer length": MAP_LENGTH,
    "Answer Usefulness": MAP_USEFULNESS,
    "Do you like the answer": MAP_LIKE
}

# We will name each dimension key as shorter strings:
DIMENSION_KEYS = {
    "Answer Clearness": "clearness",
    "Answer length": "length",
    "Answer Usefulness": "usefulness",
    "Do you like the answer": "like"
}


###############################################################################
# 2) Parsing function: extract the dimension ratings from the "options" field
###############################################################################
def parse_options(options_list):
    """
    Given the 'options' array from one JSON record,
    return a dict: { 'clearness': int, 'length': int, 'usefulness': int, 'like': int }.
    If a dimension is missing, it will be None.
    """
    result = {
        "clearness": None,
        "length": None,
        "usefulness": None,
        "like": None
    }

    for opt in options_list:
        label = opt.get("label", "")
        value = opt.get("value", "")

        # Find which dimension this label corresponds to
        # We match on partial text (since your example label includes parentheses)
        for dim_label, mapping_dict in DIMENSION_MAPPINGS.items():
            if dim_label in label:
                # Convert the value to a numeric code
                code = mapping_dict.get(value, None)

                # Assign to the correct result key
                dim_key = DIMENSION_KEYS[dim_label]
                result[dim_key] = code
                break  # stop checking other dimension labels

    return result


###############################################################################
# 3) Load all JSONL files, one per annotator, and store data
###############################################################################
def load_annotator_data(folder="annotations"):
    data = {}

    # You can adapt this glob pattern to match your filenames
    jsonl_files = glob.glob(os.path.join(folder, "*.jsonl"))
    # order the files by name
    jsonl_files.sort()

    for filename in jsonl_files:
        # Use the filename (without extension) as annotator name
        annotator_name = os.path.splitext(os.path.basename(filename))[0]

        data[annotator_name] = {}

        with open(filename, "r", encoding="utf-8") as f:
            print(f"doing file {filename} ...")
            for line in f:
                line = line.strip()
                if not line:
                    continue

                # Parse JSON
                record = json.loads(line)

                example_idx = record.get("example_idx", None)
                options = record.get("options", [])

                # Extract numeric codes for each dimension
                dims = parse_options(options)

                # Store in dictionary
                if example_idx is not None:
                    data[annotator_name][example_idx] = dims

    return data


###############################################################################
# 4) Compute pairwise Pearson correlation for each dimension among annotators
###############################################################################
def compute_pairwise_correlations(data, dimension_key):
    """
    Given:
      data[annotator_name][example_idx] = { 'clearness': ..., etc. }
      dimension_key is one of ('clearness', 'length', 'usefulness', 'like')
    Returns:
      A correlation matrix (N x N) where N = number of annotators.
      Annotators are returned in a list so you know the row/col mapping.
    """
    annotators = sorted(data.keys())
    n = len(annotators)
    corr_matrix = np.zeros((n, n), dtype=float)

    for i in range(n):
        corr_matrix[i, i] = 1.0  # self-correlation = 1

    # For each pair of annotators (i, j), gather their ratings
    for i in range(n):
        for j in range(n):
            # We only need to compute once for (i, j) because corr is symmetric
            annotator_i = annotators[i]
            annotator_j = annotators[j]

            # Gather matched example_idx’s they both rated
            common_examples = set(data[annotator_i].keys()) & set(data[annotator_j].keys())

            # For each common example, collect dimension ratings
            ratings_i = []
            ratings_j = []
            for ex_id in common_examples:
                val_i = data[annotator_i][ex_id].get(dimension_key, None)
                val_j = data[annotator_j][ex_id].get(dimension_key, None)
                # Only use if both are non-None
                if val_i is not None and val_j is not None:
                    ratings_i.append(val_i)
                    ratings_j.append(val_j)

            # If we have fewer than 2 overlapping points, correlation is undefined
            if len(ratings_i) < 2:
                corr_matrix[i, j] = np.nan
                corr_matrix[j, i] = np.nan
                continue

            # Check for constant array
            if len(set(ratings_i)) == 1 or len(set(ratings_j)) == 1:
                # You can choose to treat constant array correlation as 0 or skip
                corr_matrix[i, j] = 0.0  # or np.nan
                corr_matrix[j, i] = 0.0
                continue

            # Otherwise, compute Pearson
            r_val, _ = pearsonr(ratings_i, ratings_j)
            corr_matrix[i, j] = r_val
            corr_matrix[j, i] = r_val

    return annotators, corr_matrix


def main():
    # 1) Load all annotator data
    data = load_annotator_data(folder="eval_data")

    # 2) For each dimension, compute the pairwise correlation matrix
    for dimension_key in ["clearness", "length", "usefulness", "like"]:
        annotators, corr_matrix = compute_pairwise_correlations(data, dimension_key)

        print(f"\nPearson Correlation Matrix for dimension: {dimension_key.upper()}")
        print("Annotators (in row/column order):", annotators)
        print(corr_matrix)

        # (Optional) You might also compute an average correlation across all pairs
        # ignoring diagonal:
        upper_tri_indices = np.triu_indices_from(corr_matrix, k=1)
        avg_corr = np.mean(corr_matrix[upper_tri_indices])
        print(f"Average Pearson r for {dimension_key} = {avg_corr:.3f}")


if __name__ == "__main__":
    main()
