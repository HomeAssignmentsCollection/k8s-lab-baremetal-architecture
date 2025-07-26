# Ansible Inventory Template
# Шаблон инвентаря Ansible

[control_plane]
%{ for ip in control_plane_ips ~}
${node_prefix}-master-${index(control_plane_ips, ip) + 1} ansible_host=${ip}
%{ endfor ~}

[workers]
%{ for ip in worker_ips ~}
${node_prefix}-worker-${index(worker_ips, ip) + 1} ansible_host=${ip}
%{ endfor ~}

[load_balancer]
${node_prefix}-lb ansible_host=${load_balancer_ip}

[k8s_cluster:children]
control_plane
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3 