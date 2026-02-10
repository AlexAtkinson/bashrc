# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 12-kubernetes.sh
# DESCRIPTION         : Kubernetes Configuration
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

# shellcheck disable=1090
source <(kubectl completion bash)                           # Enable kubectl bash completion

alias k=kubectl
alias kdelp="kubectl delete pod"
alias kdesp="kubectl describe pod"
alias kcd="kubectl create deployment"
alias kgd="kubectl get deploy"
alias kgs="kubectl get svc"
alias kgp="kubectl get pod"
alias wkgp="watch kubectl get pod"
alias kgpw="kubectl get pod -o wide"
alias kl="kubectl logs"
alias kds="kubectl delete svc"
alias ke="kubectl exec -it"
alias kpfd="kubectl port-forward deploy"
alias k="kubectl"
alias kp="kubectl port-forward"
alias kcfm="kubeconform"
alias kcfms="kubeconform -summary -output json"

kubectlns() {
  local CTX NS
  CTX=$(kubectl config current-context)
  NS="$1"

  NS=$(kubectl get namespace "$NS" --no-headers --output=go-template='{{.metadata.name}}' 2>/dev/null)
  if [ -z "$NS" ]; then
    loggerx WARNING "Namespace ($1) not found! Setting default namespace."
    NS="default"
  fi

  kubectl config set-context "$CTX" --namespace="$NS"
}
