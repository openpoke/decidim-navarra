#!/bin/bash

# Execute from project root path.
# This script updates the contents of vendor/ansible with the last
# version in ansible-decidim-navarra and generates a commit with the
# changes in this repository

rm -rf vendor/ansible
git clone git@github.com:PopulateTools/ansible-decidim-navarra.git vendor/ansible
rm -rf vendor/ansible/.git
rm vendor/ansible/.gitignore
git reset
git add vendor/ansible
git commit -m "Update ansible"
