# Docker image for Android builds on Gitlab CI

This Docker image serves as an environment for running Android builds on Gitlab CI in Ackee workspace.

Contains:
- Java 17 environment
- NVM with default node version to 12.2.0
- Latest 8 Android version SDKs + Platform CLI tools
- gcloud CLI tool
- danger-kotlin
- Flutter 3.24.3 binaries
- [Git LFS](https://git-lfs.com/)
