# KubeScripts
A collection of kubectl scripts

## Commands Used

##### Sed replace multiple consecutive spaces with a single comma - used for csv gen
  
  Comma: `| sed 's/ \{1,\}/,/g'`
  
  Tab (MacOsX): `| sed -e 's/  */\'$'\t/g'`
  
  Thus the command for [pod-utilization.csv](./pod-utilization.csv) is
  ```bash
kubectl top pod --all-namespaces --containers | sed 's/ \{1,\}/,/g' | pbcopy
  ```

#### Scale a namespace to 0
Note - either change your default namespace or add `-n <some namespace>` to this command
```bash
kubectl get deploy -o go-template='{{range .items}}{{printf "%s\n" .metadata.name}}{{end}}' | xargs kubectl scale --replicas=0 deployment
```
