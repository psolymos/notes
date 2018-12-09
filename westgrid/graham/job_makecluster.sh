#!/bin/bash
#SBATCH --account=def-psolymos  # replace this with your own account
#SBATCH --ntasks=4              # number of processes
#SBATCH --mem-per-cpu=512M      # memory; default unit is megabytes
#SBATCH --time=00:05:00         # time (HH:MM:SS)
#SBATCH --job-name=test_makecluster
#SBATCH --output=%x-%j.out
#SBATCH --mail-user=solymos@ualberta.ca
#SBATCH --mail-type=ALL

module nixpkgs/16.09
module load gcc/7.3.0
module load openmpi/3.1.2
module load r/3.5.1

# Export the nodes names. 
# If all processes are allocated on the same node, NODESLIST contains : node1 node1 node1 node1
export NODESLIST=$(echo $(srun hostname))
Rscript --vanilla test_makecluster.R 100

echo done
