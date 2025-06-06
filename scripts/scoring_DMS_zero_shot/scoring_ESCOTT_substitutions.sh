#!/bin/bash 

# scoring_ESCOTT_substitutions.sh
#
# Description:
# This script runs the ESCOTT prediction in a Docker container. It ensures that all necessary
# dependencies are available and sets up the environment for running the ESCOTT prediction.
# The script mounts the required directories into the Docker container, executes the prediction,
# and saves the output files.
#
# Prerequisites:
# - Docker must be installed on the host machine.
# - The user must have permission to run Docker commands.
# - The Docker image for ESCOTT with all dependencies must be pulled from Docker Hub using the following command:
#   docker pull tekpinar/prescott-docker:v1.6.0
#
# Note:
# The generated prediction files in the Docker container will have root ownership. After the execution,
# change the ownership of the files to the current user with the following command:
#   sudo chown -R $USER:$USER <DMS_output_score_folder>
#

# Source the configuration file
source ../zero_shot_config.sh

export DMS_index="Experiment index to run (e.g. 0, 1,...216)"
export DMS_output_score_folder="${DMS_output_score_folder_subs}/ESCOTT/"

# temporary folder for intermediate files generated by ESCOTT
# This folder will be removed after the execution
export TEMP_FOLDER="./escott_tmp/"  

# Docker image name
export DOCKER_IMAGE="tekpinar/prescott-docker:v1.6.0"

# using default NSEQS=40000 for DMS_index=147 returns all zeros due to very low
# sequence variation in the first portion of the MSA
if [ $DMS_index -eq 147 ]; then
    export NSEQS=182169
else
    export NSEQS=40000
fi

# Remove temporary folder on exit
trap 'rm -rf $TEMP_FOLDER' EXIT

# Run the compute_fitness.py script in the Docker container
docker run --rm \
-v $(dirname $(dirname $(dirname $(realpath $0)))):/root/ProteinGym \
-v $(realpath $DMS_reference_file_path_subs):/root/DMS_substitutions.csv \
-v $(realpath $DMS_data_folder_subs):/root/DMS_data \
-v $(realpath $DMS_MSA_data_folder):/root/MSA_data \
-v $(realpath $DMS_structure_folder):/root/structure_data \
-v $(realpath $DMS_output_score_folder):/root/output_scores \
-w /root/ProteinGym/scripts/scoring_DMS_zero_shot \
$DOCKER_IMAGE \
bash -c "
python3 -u ../../proteingym/baselines/escott/compute_fitness.py \
--DMS_index=$DMS_index \
--DMS_reference_file_path=/root/DMS_substitutions.csv \
--DMS_data_folder=/root/DMS_data \
--MSA_folder=/root/MSA_data \
--structure_data_folder=/root/structure_data \
--output_scores_folder=/root/output_scores \
--temp_folder=$TEMP_FOLDER \
--nseqs=$NSEQS"
