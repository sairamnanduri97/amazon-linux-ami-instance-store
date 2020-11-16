PACKER_BINARY ?= packer
PACKER_VARIABLES := aws_region ami_name binary_bucket_name binary_bucket_region source_ami_id source_ami_owners arch instance_type security_group_id additional_yum_repos subnet_id
AMI_VERSION := 1.0


ami_name ?= amazonlinux-hardened-$(AMI_VERSION)-v$(shell date +'%Y%m%d')
arch ?= x86_64
aws_region ?= us-east-1
#subnet_id ?= subnet-e3d7b6cd
source_ami_id ?= $(shell aws ssm get-parameters \
    --names /aws/service/ami-amazon-linux-latest/amzn-ami-hvm-2018.03.0.20180811-x86_64-s3 \
    --region $(aws_region) --query "Parameters[].Value" --output text)

ifeq ($(arch), arm64)
instance_type ?= a1.large
else
instance_type ?= r3.large
endif

T_RED := \e[0;31m
T_GREEN := \e[0;32m
T_YELLOW := \e[0;33m
T_RESET := \e[0m


.PHONY: validate
validate:
	$(PACKER_BINARY) validate $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) amazon-linux.json

.PHONY: al
al: validate
	@echo "$(T_GREEN)Building $(T_YELLOW)$(ami_name)$(T_GREEN) on $(T_YELLOW)$(arch)$(T_RESET)"
	$(PACKER_BINARY) build $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) amazon-linux.json

.PHONY: test
test:
	./tools/run_ec2.sh