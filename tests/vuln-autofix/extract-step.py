"""Print the `run` script of the step with the given id from the vuln-autofix workflow."""
import sys

import yaml

workflow, step_id = sys.argv[1], sys.argv[2]
with open(workflow, encoding="utf-8") as f:
    steps = yaml.safe_load(f)["jobs"]["autofix"]["steps"]
print(next(s["run"] for s in steps if s.get("id") == step_id))
