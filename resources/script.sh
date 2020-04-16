#!/bin/bash

# kubectl get pods -o json --all-namespaces | jq -r '.items[] | .metadata.name + " \n Req. RAM: " + .spec.containers[].resources.requests.memory + " \n Lim. RAM: " + .spec.containers[].resources.limits.memory + " \n Req. CPU: " + .spec.containers[].resources.requests.cpu + " \n Lim. CPU: " + .spec.containers[].resources.limits.cpu + " \n Req. Eph. DISK: " + .spec.containers[].resources.requests["ephemeral-storage"] + " \n Lim. Eph. DISK: " + .spec.containers[].resources.limits["ephemeral-storage"] + "\n"' > resources.txt

RamConvertBytesToMbAndGb() {
  bytes=$1
  echo ${bytes} | awk '{$1=$1/(1024^2); print $1,"MB";}'
  echo ${bytes} | awk '{$1=$1/(1024^3); print $1,"GB";}'
}
CpuConvertToCore() {
  bytes=$1
  echo "${bytes} Cores"
}
convertStringToBytes() {
  size=$1
#  Ti, Gi, Mi, Ki
# https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory
  if [[ ${size} == *"Ti" ]]; then
    expr `echo "1024 ^ 4" | bc` \* $(echo ${size} | awk -F 'Ti' '{print $1}')
  elif [[ ${size} == *"Gi" ]]; then
    expr `echo "1024 ^ 3" | bc` \* $(echo ${size} | awk -F 'Gi' '{print $1}')
  elif [[ ${size} == *"Mi" ]]; then
    expr `echo "1024 ^ 2" | bc` \* $(echo ${size} | awk -F 'Mi' '{print $1}')
  elif [[ ${size} == *"Ki" ]]; then
    expr `echo "1024 ^ 1" | bc` \* $(echo ${size} | awk -F 'Ki' '{print $1}')

  elif [[ ${size} == *"T" ]]; then
    expr `echo "1000 ^ 4" | bc` \* $(echo ${size} | awk -F 'T' '{print $1}')
  elif [[ ${size} == *"G" ]]; then
    expr `echo "1000 ^ 3" | bc` \* $(echo ${size} | awk -F 'G' '{print $1}')
  elif [[ ${size} == *"M" ]]; then
    expr `echo "1000 ^ 2" | bc` \* $(echo ${size} | awk -F 'M' '{print $1}')
  elif [[ ${size} == *"K" ]]; then
    expr `echo "1000 ^ 1" | bc` \* $(echo ${size} | awk -F 'K' '{print $1}')

  elif [[ ${size} == *"m" ]]; then
    echo "scale=4; $(echo ${size} | awk -F 'm' '{print $1}') / 1000" | bc -l
  else
    echo ${size}
  fi

}
GetData() {
  kubectl get pods -o json --all-namespaces | jq -r '.items[] | select('${RESOURCE_PATH}' != null) | '${NAME}' + "\t" + '${RESOURCE_PATH} > ${FILE}
}
ReadData() {
  sum=0
#  echo $FILE
  while read -r line
    do
    dataSize=$(echo $line | awk '{print $2}')
    bytes=$(convertStringToBytes ${dataSize})
    sum=$(echo "${sum} + ${bytes}" | bc)
  done < ${FILE}
  if [[ "$(echo "${FILE}" | tr '[:upper:]' '[:lower:]')" == *ram* ]]; then
    printf "TOTAL:\t${sum}\tMb" >> ${FILE}
  else
    printf "TOTAL:\t${sum}\tCores" >> ${FILE}
  fi
  echo "TOTAL ${OUTPUT}"
  if [[ "$(echo "${FILE}" | tr '[:upper:]' '[:lower:]')" == *ram* ]]; then
    RamConvertBytesToMbAndGb ${sum}
  else
    CpuConvertToCore ${sum}
  fi
  echo

}

# Ram
  # Requests
      export OUTPUT="Ram in Requests"
      export RESOURCE_PATH=.spec.containers[].resources.requests.memory
      export NAME=.metadata.name
      export FILE=requests.ram.tsv
      GetData
      ReadData >&1 | tee System-Report.txt
  # Limits
      export OUTPUT="Ram in Limits"
      export RESOURCE_PATH=.spec.containers[].resources.limits.memory
      export NAME=.metadata.name
      export FILE=limits.ram.tsv
      GetData
      ReadData >&1 | tee -a System-Report.txt

# Cpu
  # Requests
      export OUTPUT="Cpu in Requests"
      export RESOURCE_PATH=.spec.containers[].resources.requests.cpu
      export NAME=.metadata.name
      export FILE=requests.cpu.tsv
      GetData
      ReadData >&1 | tee -a System-Report.txt
  # Limits
      export OUTPUT="Cpu in Limits"
      export RESOURCE_PATH=.spec.containers[].resources.limits.cpu
      export NAME=.metadata.name
      export FILE=limits.cpu.tsv
      GetData
      ReadData  >&1 | tee -a System-Report.txt
