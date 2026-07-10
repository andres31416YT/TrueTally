Run ansible-playbook \
Using /home/runner/work/TrueTally/TrueTally/ansible/playbooks/ansible.cfg as config file

PLAY [Configurar infraestructura TrueTally] ************************************

TASK [Validar variables de ambiente] *******************************************
ok: [localhost] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [Obtener VPC ID desde AWS] ************************************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-vpcs --filters \"Name=tag:Name,Values=truetally-dev-vpc\" --query 'Vpcs[0].VpcId' --output text --region \"***\"\n", "delta": "0:00:05.939536", "end": "2026-07-10 20:56:39.452735", "msg": "", "rc": 0, "start": "2026-07-10 20:56:33.513199", "stderr": "", "stderr_lines": [], "stdout": "vpc-0b0cf50af4c9c73a4", "stdout_lines": ["vpc-0b0cf50af4c9c73a4"]}

TASK [Obtener subnets privadas (compute + database)] ***************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-subnets --filters \"Name=vpc-id,Values=vpc-0b0cf50af4c9c73a4\" \"Name=tag:Name,Values=truetally-dev-compute-*,truetally-dev-database-*\" --query 'Subnets[].SubnetId' --output json --region \"***\"\n", "delta": "0:00:00.988979", "end": "2026-07-10 20:56:40.684374", "msg": "", "rc": 0, "start": "2026-07-10 20:56:39.695395", "stderr": "", "stderr_lines": [], "stdout": "[\n    \"subnet-0dec35c145a58b4e1\",\n    \"subnet-06c4f99d194126a75\",\n    \"subnet-0d85a43d83f16a2be\",\n    \"subnet-06c6b3f47a2ce9ec9\"\n]", "stdout_lines": ["[", "    \"subnet-0dec35c145a58b4e1\",", "    \"subnet-06c4f99d194126a75\",", "    \"subnet-0d85a43d83f16a2be\",", "    \"subnet-06c6b3f47a2ce9ec9\"", "]"]}

TASK [Obtener subnets de blockchain] *******************************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-subnets --filters \"Name=vpc-id,Values=vpc-0b0cf50af4c9c73a4\" \"Name=tag:Name,Values=truetally-dev-blockchain-*\" --query 'Subnets[].SubnetId' --output json --region \"***\"\n", "delta": "0:00:00.924341", "end": "2026-07-10 20:56:41.850330", "msg": "", "rc": 0, "start": "2026-07-10 20:56:40.925989", "stderr": "", "stderr_lines": [], "stdout": "[\n    \"subnet-0384242bd7c68ddb8\",\n    \"subnet-03160e5aefb44161a\"\n]", "stdout_lines": ["[", "    \"subnet-0384242bd7c68ddb8\",", "    \"subnet-03160e5aefb44161a\"", "]"]}

TASK [Obtener security group de Lambda] ****************************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-security-groups --filters \"Name=vpc-id,Values=vpc-0b0cf50af4c9c73a4\" \"Name=group-name,Values=truetally-dev-lambda-sg\" --query 'SecurityGroups[0].GroupId' --output text --region \"***\"\n", "delta": "0:00:01.210322", "end": "2026-07-10 20:56:43.310449", "msg": "", "rc": 0, "start": "2026-07-10 20:56:42.100127", "stderr": "", "stderr_lines": [], "stdout": "sg-04a29d7136327cc9e", "stdout_lines": ["sg-04a29d7136327cc9e"]}

TASK [Obtener CloudFront Distribution ID] **************************************
changed: [localhost] => {"changed": true, "cmd": "aws cloudfront list-distributions --query \"DistributionList.Items[?length(Origins.Items[?contains(DomainName, 'truetally-dev-frontend-***.s3.amazonaws.com')]) > \\`0\\`].Id | [0]\" --output text --region \"***\"\n", "delta": "0:00:00.835185", "end": "2026-07-10 20:56:44.392371", "msg": "", "rc": 0, "start": "2026-07-10 20:56:43.557186", "stderr": "", "stderr_lines": [], "stdout": "E1EGDDKRRPMJ7T", "stdout_lines": ["E1EGDDKRRPMJ7T"]}

TASK [Establecer variables dinámicas] ******************************************
ok: [localhost] => {"ansible_facts": {"blockchain_subnet_ids": ["subnet-0384242bd7c68ddb8", "subnet-03160e5aefb44161a"], "cloudfront_distribution_id": "E1EGDDKRRPMJ7T", "lambda_security_group_id": "sg-04a29d7136327cc9e", "private_subnet_ids": ["subnet-0dec35c145a58b4e1", "subnet-06c4f99d194126a75", "subnet-0d85a43d83f16a2be", "subnet-06c6b3f47a2ce9ec9"], "vpc_id": "vpc-0b0cf50af4c9c73a4"}, "changed": false}

        "Loki URL (interno): http://localhost:3100",
        "Prometheus URL (interno): http://localhost:9090",
        "==============================================",
        "Para configurar data sources en Grafana:",
        "1. Accede a http://10.0.0.251:3000",
        "2. Ve a Configuration > Data Sources",
        "3. Agrega los data sources:",
        "   - Loki: http://localhost:3100",
        "   - Prometheus: http://localhost:9090",
        "   - CloudWatch: https://monitoring.***.amazonaws.com",
        "==============================================",
        "Archivo de provisioning generado en: /tmp/grafana-provisioning-datasources.yaml",
        "=============================================="
    ]
}

TASK [observability : Generar dashboard basico de infraestructura] *************
changed: [localhost] => {"changed": true, "checksum": "f529aa8f376278b6d8918da7371055a76cfe6a75", "dest": "/tmp/grafana-dashboard-infrastructure.json", "gid": 1001, "group": "runner", "md5sum": "28667b50acaf28061ad6cda3bbde7477", "mode": "0644", "owner": "runner", "size": 1117, "src": "/home/runner/.ansible/tmp/ansible-tmp-1783717133.645585-6452-51667356086675/.source.json", "state": "file", "uid": 1001}

TASK [observability : Mostrar informacion de dashboards] ***********************
ok: [localhost] => {
    "msg": [
        "Dashboard basico generado en: /tmp/grafana-dashboard-infrastructure.json",
        "Puedes importarlo en Grafana navegando a: Dashboards > Import"
    ]
}

PLAY RECAP *********************************************************************
localhost                  : ok=101  changed=84   unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   