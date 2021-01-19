Clear-Host
kubectl get pvc -n helm
kubectl get pv -n helm
kubectl get sc -n helm
kubectl get po -n helm
$podName=$(kubectl get po -n helm -o=jsonpath="{.items[0].metadata.name}")
Write-Host "Looking for /shared on $podName"
kubectl exec -i -n "helm" "$podName" -- /bin/bash -c "echo 'Drive:';ls / | grep shared"