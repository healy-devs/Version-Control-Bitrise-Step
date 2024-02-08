# Update Version and Push Changes Step

## Description

This step automates the process of updating the version number in the pubspec.yaml file of a Flutter project based on the specified version type or custom version number. It then pushes the changes to the Git repository.

## Requirements

- Flutter project
- Git repository

## Inputs

- `version_type`: Select the type of version update (major, minor, or patch). Optional.
- `custom_version`: Specify a custom version number in the format x.x.x (e.g., 1.2.3). Optional.

## Outputs

- `new_version_number`: The updated version number after the changes are made.

## Usage

Add this step to your Bitrise workflow and configure the inputs as needed.

```yaml
steps:
  - git::https://github.com/healy-devs/Version-Control-Bitrise-Step@main:
        inputs:
         - BITRISE_VERSION_TYPE: patch
         - commit_version_changes: "false"
