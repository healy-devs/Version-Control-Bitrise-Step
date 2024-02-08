# Update Version and Push Changes Step

## Description

This step updates the version number in the pubspec.yaml file based on the specified version type or custom version number, and then pushes the changes to the Git repository.

## Requirements

- Flutter project
- Git repository


## Inputs

- **Version Type**: Select the type of version update:
    - Major: Increment the major version number by 1 (e.g., x.0.0).
    - Minor: Increment the minor version number by 1 (e.g., 0.x.0).
    - Patch: Increment the patch version number by 1 (e.g., 0.0.x).

- **Custom Version Number**: A custom version number to use instead of the version type. If you specify a custom version number, the version type will be ignored.

- **Commit Changes**: Choose whether to commit the changes to the Git repository.
    - If enabled, the step will commit the changes to the Git repository. Default is true.

- **Commit Message**: Specify the commit message to use for the changes. If not provided, a default message will be used.

- **Commit Author Name**: Specify the name of the author for the commit. If not provided, the default author will be used.

- **Commit Author Email**: Specify the email of the author for the commit. If not provided, the default author will be used.

- **Branch Name**: Name of the branch to create for the changes. If not provided, a default branch name will be used.

## Example Usage

```yaml
steps:
  - update-version-and-push-changes:
      title: Update Version and Push Changes
      inputs:
        - BITRISE_VERSION_TYPE: patch
        - custom_version_number: ""
        - commit_version_changes: "true"
        - commit_message: "Bump version"
        - commit_author_name: "John Doe"
        - commit_author_email: "john.doe@example.com"
        - branch_name: "Release/1.0.0"

