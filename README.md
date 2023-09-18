# Intro

These scripts were designed to run mobile proxy apps (apps serving as residential proxy nodes) as docker containers as well as capturing their resource consumption and network usage. 

# Thanks and Acknowledgements
This project was based on [android-emulator](https://github.com/tracer0tong/android-emulator), which unfortunately was out of maintainance. A more up-to-date project is https://github.com/google/android-emulator-container-scripts.

# Deployment and Usage

## Install Docker 

Please following the instructions from Docker official website to install Docker on your respective OS.

If your OS is Ubuntu, you may simply run the *install_docker_ubuntu.sh* script.

## Create the Docker images

Given the Docker facilities installed, the next step is to create a Docker image. Here, we have provided two Docker files to facilitate this process. One is the *Dockerfile*, and the other is *Dockerfile.arm64*, depending on whether you want to run a ARM-based Android emulator or not. 

## Execute an Android APK file

*auto_script_example.sh* presents an example regarding how to execute a mobile proxy Android app in a Docker container. 
More configurations can be specified, as illustrated in *auto_scripts_general/start_init.sh*. 

```bash
# APK_TAG is used to distinguish resulting logs of different execution rounds
./auto_script_example.sh APK_FILE APK_TAG [RESULT_DIR]
```

Also, a customized script suite is provided (*auto_scripts_luminati*) for running proxy apps of Luminati,
due to their unique technical mechanisms and the resulting challenges for running and profiling them.
