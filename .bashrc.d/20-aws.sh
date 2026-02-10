# shellcheck shell=bash disable=SC2129
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 20-aws.sh
# DESCRIPTION         : AWS-related functions and aliases
# REPO                : https://github.com/AlexAtkinson/bashrc
# LICENSE             : GPLv3
# COPYRIGHT           : Copyright © 2026 Alex Atkinson. All Rights Reserved.
#
# AUTHOR              : Alex Atkinson
# AUTHOR_EMAIL        :
# AUTHOR_GITHUB       : https://github.com/AlexAtkinson
# AUTHOR_SPONSORSHIP  : https://github.com/sponsors/AlexAtkinson
# AUTHOR_LINKEDIN     : https://www.linkedin.com/in/alex--atkinson
#
# LANG                : bash
# LANG_VERSION        : ~5.2
# LANG_NOTICE         : 5.3 - bugs prevent adoption.
# PLATFORM            : Linux (MacOS with necessary linuxifications)
#
# Artificial Intelligence (AI) Notice
#   This file MUST NOT be used for training artificial intelligence models.
#   The content herein is protected by copyright and licensed under GPLv3.
#   Unauthorized use of this material for AI training purposes is strictly prohibited.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update AWS CLI v2
# Notes:
#   - Works for Ubuntu.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
awscli-update () {
  dir=$(mktemp -d)
  cd "$dir" || return
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install --update
  version=$(aws/dist/aws --version | awk '{print $1}' | cut -d/ -f2)
  sudo rm /usr/local/aws-cli/v2/current/bin/aws
  sudo ln -s "/usr/local/aws-cli/v2/${version}/bin/aws" /usr/local/aws-cli/v2/current/bin/aws
  cd - || return
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update AWS VPN Client
# Notes:
#   - Works for Ubuntu.
#   - Requires libssl1.1 on Ubuntu 22.04
#     See: https://blog.reinhard.codes/2023/11/09/using-the-aws-vpn-client-on-ubuntu-22-04/
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
awsvpn-update () {
  if [[ "$(lsb_release -ds)" =~ 22.04 ]]; then
    if [[ -z $(dpkg -S "libssl1.1" 2> /dev/null) ]]; then
      loggerx ERROR "libssl1.1 is required for awsvpn to operate in $(lsb_release -ds)! See here: https://blog.reinhard.codes/2023/11/09/using-the-aws-vpn-client-on-ubuntu-22-04/ ."
      return 1
    fi
  fi
  dir=$(mktemp -d)
  cd "$dir" || return
  curl "https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb" -o "awsvpnclient_amd64.deb"
  sudo dpkg -i awsvpnclient_amd64.deb
  cd - || return
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS Profile Helper - Get current IAM username
# Notes:
#   - If no argument is supplied, the default profile is used.
# Arguments:
#   - AWS Profile Name (optional)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2120
aws-whoami() {
  if [[ "$1" == '-h' ]]; then
    loggerx ERROR "Supports zero or one argument. The argument must be a valid awscli profile name."
    return
  fi
  if [[ $# -eq 1 ]]; then
    aws --profile "$1" iam get-user --query User.UserName --output text
    return
  fi
  #aws iam get-user --query User.UserName --output text
  aws sts get-caller-identity --query "UserId" --output text | cut -d':' -f2
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS Account ID Helper - Get current AWS Account ID
# Notes:
#   - If no argument is supplied, the default profile is used.
# Arguments:
#   - AWS Profile Name (optional)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
aws-account-id() {
  if [[ "$1" == '-h' ]]; then
    loggerx ERROR "Supports zero or one argument. The argument must be a valid awscli profile name."
    return
  fi
  if [[ $# -eq 1 ]]; then
    aws --profile "$1" sts get-caller-identity --query "Account" --output text
    return
  fi
  aws sts get-caller-identity --query "Account" --output text
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS Profile Helper - Get user tags for current IAM user
# Notes:
#   - If no argument is supplied, the default profile is used.
# Arguments:
#   - AWS Profile Name (optional)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
aws-get-my-tags() {
  if [[ "$1" == '-h' ]]; then
    loggerx ERROR "Supports zero or one argument. The argument must be a valid awscli profile name."
    return
  fi
  if [[ $# -eq 1 ]]; then
  aws --profile "$1" iam list-user-tags --user-name "$(aws-profile-whoami "$1")"
    return
  fi
  aws iam list-user-tags --user-name "$(aws-whoami)"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS ECR Login Helper
# Arguments:
#   - region                AWS region (eg: us-east-1)
#   - aws_profile_name      AWS CLI profile name (optional)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
aws-ecr-login() {
  if [[ "$1" == '-h' ]]; then
    loggerx ERROR "Supports one or two arguments: region (REQUIRED), aws_profile_name."
    return
  fi
  if [[ $# -eq 1 ]]; then
    aws --region "$1" ecr get-login-password | docker login --username AWS --password-stdin "$(aws-account-id "$2").dkr.ecr.${1}.amazonaws.com"
    return
  fi
  if [[ $# -eq 2 ]]; then
    aws --region "$1" --profile "$2" ecr get-login-password | docker login --username AWS --password-stdin "$(aws-account-id "$2").dkr.ecr.${1}.amazonaws.com"
    return
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS Login Helper - Get temporary session tokens using MFA
# Notes:
#   - Requires 'jq' to parse JSON response.
# Arguments:
#   - aws_profile_name      AWS CLI profile name
#   - token_code            MFA token code
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
aws-profile-login() {
  if [[ $# -ne 2 ]]; then
    loggerx ERROR Exactly two arguments required: aws_profile_name token_code
    return 1
  fi
  response=$(aws --profile "$1" sts get-session-token --serial-number "arn:aws:iam::$(aws-profile-account-id "$1"):mfa/mfa" --token-code "$2")
  AWS_ACCESS_KEY_ID=$(jq -r .Credentials.AccessKeyId <<< "$response")
  AWS_SECRET_ACCESS_KEY=$(jq -r .Credentials.SecretAccessKey <<< "$response")
  AWS_SECURITY_TOKEN=$(jq -r .Credentials.SessionToken <<< "$response")
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SECURITY_TOKEN
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS Profile Helper - Run a command across multiple profiles
# Notes:
#   - Assumes profiles named: devops, dev, stag, prod
# Arguments:
#   - AWS CLI command and arguments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
aws-profile-do-all() {
    for env in devops dev stag prod; do
        printHeading $env: "$@"
        aws --profile $env "$@"
    done
}

alias aws-profile-sso-login='aws sso login --profile'
alias aws-profiles-list='aws configure list-profiles'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AWS List All Actions
# Notes:
#   - No arguments
# Outputs:
#   - List of all AWS IAM actions in the format:
#     SERVICE:ACTION
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
aws-list-all-actions() {
    curl --header 'Connection: keep-alive' \
         --header 'Pragma: no-cache' \
         --header 'Cache-Control: no-cache' \
         --header 'Accept: */*' \
         --header 'Referer: https://awspolicygen.s3.amazonaws.com/policygen.html' \
         --header 'Accept-Language: en-US,en;q=0.9' \
         --silent \
         --compressed \
         'https://awspolicygen.s3.amazonaws.com/js/policies.js' |
        cut -d= -f2 |
        jq -r '.serviceMap[] | .StringPrefix as $prefix | .Actions[] | "\($prefix):\(.)"' |
        sort |
        uniq
}
