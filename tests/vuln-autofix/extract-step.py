"""Print the `run` script of the step with the given id from the vuln-autofix workflow."""
import sys

import yaml

workflow, step_id = sys.argv[1], sys.argv[2]
with open(workflow, encoding="utf-8") as f:
    jobs = yaml.safe_load(f)["jobs"]
print(next(s["run"] for job in jobs.values() for s in job["steps"] if s.get("id") == step_id))
