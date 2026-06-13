#!/bin/bash

echo -n "Purging modules... "
module purge
echo "Done"

conda deactivate
conda env remove -n jmh