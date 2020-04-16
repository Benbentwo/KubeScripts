#! /bin/bash

script_folder=$(dirname $0)
mkdir -p $(dirname $script_folder/nodes/pod-summary.tsv)

kubectl get po --all-namespaces -o wide --sort-by='{.spec.nodeName}' | sed -e 's/  */\'$'\t/g' > $script_folder/nodes/pod-summary.tsv
