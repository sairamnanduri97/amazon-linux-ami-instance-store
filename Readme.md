# Hardened Amazon Linux 2 AMI 
## What do you need to run
 - packer
 - make
 - AWS account with admin rights

## Packer install on macOS
```
brew tap hashicorp/tap
brew install hashicorp/tap/packer
brew upgrade hashicorp/tap/packer
packer --version
```

## Technologies used
- Packer
- Ansible

## AMI Includes
- Latest Amazon Base AMI
- All latest kernal updates
- CIS benchmarks 2.0
- SSM agent
- CloudWatch Agent
- Amazon Inspector

## How to run

- Make sure you have access to AWS account 
    ```
    aws sts get-caller-identity
    ``` 
- Check the make version (make -v). if should be GNU Make 4 otherwise, you can install with brew install make. And make sure /usr/local/opt/make/libexec/gnubin is in PATH 
    ```
    export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
    ```
- Run make command
```
make al
```
## How to test
Run below to get a ec2 created with latest ami owned by current accout.
Need to update sg and key name.
```
./tools/run_ec2.sh
```

