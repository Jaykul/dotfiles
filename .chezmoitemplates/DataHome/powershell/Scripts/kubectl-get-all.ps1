[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    $Namespace
)

foreach($resource in kubectl api-resources --verbs=list --namespaced -o name) {
    kubectl get $resource --show-kind --ignore-not-found --namespace $Namespace
}