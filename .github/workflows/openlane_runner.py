#!/usr/bin/python3
import os
import subprocess
import sys

if 'flow.tcl' in sys.argv[1]:
    (build_root, work) = os.path.split(os.getcwd())

    image = "edalize/openlane-sky130:v0.12"

    prefix = ["docker", "run",
              "-v", f"{build_root}:/project",
              "-u", f"{os.getuid()}:{os.getgid()}",
              "-w", f"/project/{work}",
              image]
    sys.exit(subprocess.call(prefix+sys.argv[1:]))
