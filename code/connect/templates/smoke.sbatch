#!/bin/bash
#SBATCH -J jev-smoke
#SBATCH -p cu
#SBATCH -N 1
#SBATCH -c 2
#SBATCH --mem=2G
#SBATCH -t 00:10:00
#SBATCH -o smoke_%j.out
#SBATCH -e smoke_%j.err

echo "REACHED_NODE=$(hostname)"
echo "DATE=$(date -Is)"
echo "SLURM_JOB_ID=$SLURM_JOB_ID CPUS=$SLURM_CPUS_ON_NODE"
nproc
df -h /mnt | tail -1
python3 -c 'import sys; print("python", sys.version.split()[0])' 2>&1 || echo "no python3"
