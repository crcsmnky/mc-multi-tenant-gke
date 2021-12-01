#!/bin/bash

# Ideally this script should be executed once to set up properly the project

# Enable Cloud Resource Manager API

# Initial one-off set up. This cannot be done via TF since it
# stores TF state.
gsutil mb gs://eca-team-summit-tfstate

