[all]
${hosts_control}
${hosts_work}

[kube_control_plane]
${list_master}

[etcd]
${list_master}

[kube_node]
${list_work}

[k8s_cluster:children]
kube_control_plane
kube_node