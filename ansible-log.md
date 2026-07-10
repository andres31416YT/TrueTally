Run ansible-playbook \
  ansible-playbook \
    -i ansible/inventory/hosts.ini \
    ansible/playbooks/site.yml \
    -v \
    --extra-vars "truetally_env=dev ansible_python_interpreter=/usr/bin/python3"
  shell: /usr/bin/bash -e {0}
  env:
    AWS_DEFAULT_REGION: ***
    AWS_REGION: ***
    AWS_ACCESS_KEY_ID: ***
    AWS_SECRET_ACCESS_KEY: ***
    AWS_SESSION_TOKEN: ***
    ANSIBLE_HOST_KEY_CHECKING: false
    ANSIBLE_ROLES_PATH: ansible/roles
    ANSIBLE_CONFIG: ansible/playbooks/ansible.cfg
    AWS_ACCOUNT_ID: ***
    SUDOADMIN_EMAIL: ***
    SUDOADMIN_PASSWORD: ***
    ADMIN_EMAIL: ***
    ADMIN_PASSWORD: ***
Using /home/runner/work/TrueTally/TrueTally/ansible/playbooks/ansible.cfg as config file

PLAY [Configurar infraestructura TrueTally] ************************************

TASK [Validar variables de ambiente] *******************************************
ok: [localhost] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [Obtener VPC ID desde AWS] ************************************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-vpcs --filters \"Name=tag:Name,Values=truetally-dev-vpc\" --query 'Vpcs[0].VpcId' --output text --region \"***\"\n", "delta": "0:00:01.559850", "end": "2026-07-10 20:38:55.965576", "msg": "", "rc": 0, "start": "2026-07-10 20:38:54.405726", "stderr": "", "stderr_lines": [], "stdout": "vpc-0b0cf50af4c9c73a4", "stdout_lines": ["vpc-0b0cf50af4c9c73a4"]}

TASK [Obtener subnets privadas (compute + database)] ***************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-subnets --filters \"Name=vpc-id,Values=vpc-0b0cf50af4c9c73a4\" \"Name=tag:Name,Values=truetally-dev-compute-*,truetally-dev-database-*\" --query 'Subnets[].SubnetId' --output json --region \"***\"\n", "delta": "0:00:00.911375", "end": "2026-07-10 20:38:57.118064", "msg": "", "rc": 0, "start": "2026-07-10 20:38:56.206689", "stderr": "", "stderr_lines": [], "stdout": "[\n    \"subnet-0dec35c145a58b4e1\",\n    \"subnet-06c4f99d194126a75\",\n    \"subnet-0d85a43d83f16a2be\",\n    \"subnet-06c6b3f47a2ce9ec9\"\n]", "stdout_lines": ["[", "    \"subnet-0dec35c145a58b4e1\",", "    \"subnet-06c4f99d194126a75\",", "    \"subnet-0d85a43d83f16a2be\",", "    \"subnet-06c6b3f47a2ce9ec9\"", "]"]}

TASK [Obtener subnets de blockchain] *******************************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-subnets --filters \"Name=vpc-id,Values=vpc-0b0cf50af4c9c73a4\" \"Name=tag:Name,Values=truetally-dev-blockchain-*\" --query 'Subnets[].SubnetId' --output json --region \"***\"\n", "delta": "0:00:00.880901", "end": "2026-07-10 20:38:58.239876", "msg": "", "rc": 0, "start": "2026-07-10 20:38:57.358975", "stderr": "", "stderr_lines": [], "stdout": "[\n    \"subnet-0384242bd7c68ddb8\",\n    \"subnet-03160e5aefb44161a\"\n]", "stdout_lines": ["[", "    \"subnet-0384242bd7c68ddb8\",", "    \"subnet-03160e5aefb44161a\"", "]"]}

TASK [Obtener security group de Lambda] ****************************************
changed: [localhost] => {"changed": true, "cmd": "aws ec2 describe-security-groups --filters \"Name=vpc-id,Values=vpc-0b0cf50af4c9c73a4\" \"Name=group-name,Values=truetally-dev-lambda-sg\" --query 'SecurityGroups[0].GroupId' --output text --region \"***\"\n", "delta": "0:00:00.960165", "end": "2026-07-10 20:38:59.440230", "msg": "", "rc": 0, "start": "2026-07-10 20:38:58.480065", "stderr": "", "stderr_lines": [], "stdout": "sg-04a29d7136327cc9e", "stdout_lines": ["sg-04a29d7136327cc9e"]}

TASK [Obtener CloudFront Distribution ID] **************************************
changed: [localhost] => {"changed": true, "cmd": "aws cloudfront list-distributions --query \"DistributionList.Items[?length(Origins.Items[?contains(DomainName, 'truetally-dev-frontend-***.s3.amazonaws.com')]) > \\`0\\`].Id | [0]\" --output text --region \"***\"\n", "delta": "0:00:00.838319", "end": "2026-07-10 20:39:00.524227", "msg": "", "rc": 0, "start": "2026-07-10 20:38:59.685908", "stderr": "", "stderr_lines": [], "stdout": "E1EGDDKRRPMJ7T", "stdout_lines": ["E1EGDDKRRPMJ7T"]}

TASK [Establecer variables dinámicas] ******************************************
ok: [localhost] => {"ansible_facts": {"blockchain_subnet_ids": ["subnet-0384242bd7c68ddb8", "subnet-03160e5aefb44161a"], "cloudfront_distribution_id": "E1EGDDKRRPMJ7T", "lambda_security_group_id": "sg-04a29d7136327cc9e", "private_subnet_ids": ["subnet-0dec35c145a58b4e1", "subnet-06c4f99d194126a75", "subnet-0d85a43d83f16a2be", "subnet-06c6b3f47a2ce9ec9"], "vpc_id": "vpc-0b0cf50af4c9c73a4"}, "changed": false}

TASK [api_gateway : Configurar CORS en API Gateway] ****************************
changed: [localhost] => {"changed": true, "cmd": "CURRENT=$(aws apigatewayv2 get-api --api-id \"ev4hb6gfud\" --query 'Api.CorsConfiguration.AllowOrigins | [0]' --output text --region \"***\" 2>/dev/null || echo \"None\")\nif [ \"$CURRENT\" = \"None\" ] || [ -z \"$CURRENT\" ]; then\n  aws apigatewayv2 update-api    --api-id \"ev4hb6gfud\"    --cors-configuration '{\n      \"AllowOrigins\": [\"*\"],\n      \"AllowMethods\": [\"GET\",\"POST\",\"OPTIONS\"],\n      \"AllowHeaders\": [\"Content-Type\",\"Authorization\",\"X-User-Email\",\"X-User-Role\",\"X-Amz-Date\",\"X-Api-Key\",\"X-Amz-Security-Token\"],\n      \"MaxAge\": 86400\n    }'    --region \"***\"\nfi\n", "delta": "0:00:01.710820", "end": "2026-07-10 20:39:43.342533", "msg": "", "rc": 0, "start": "2026-07-10 20:39:41.631713", "stderr": "", "stderr_lines": [], "stdout": "{\n    \"ApiEndpoint\": \"https://ev4hb6gfud.execute-api.***.amazonaws.com\",\n    \"ApiId\": \"ev4hb6gfud\",\n    \"ApiKeySelectionExpression\": \"$request.header.x-api-key\",\n    \"CorsConfiguration\": {\n        \"AllowHeaders\": [\n            \"content-type\",\n            \"authorization\",\n            \"x-user-email\",\n            \"x-user-role\",\n            \"x-amz-date\",\n            \"x-api-key\",\n            \"x-amz-security-token\"\n        ],\n        \"AllowMethods\": [\n            \"GET\",\n            \"POST\",\n            \"OPTIONS\"\n        ],\n        \"AllowOrigins\": [\n            \"*\"\n        ],\n        \"MaxAge\": 86400\n    },\n    \"CreatedDate\": \"2026-06-29T01:36:23+00:00\",\n    \"DisableExecuteApiEndpoint\": false,\n    \"IpAddressType\": \"ipv4\",\n    \"Name\": \"truetally-dev-api\",\n    \"ProtocolType\": \"HTTP\",\n    \"RouteSelectionExpression\": \"$request.method $request.path\",\n    \"Tags\": {}\n}", "stdout_lines": ["{", "    \"ApiEndpoint\": \"https://ev4hb6gfud.execute-api.***.amazonaws.com\",", "    \"ApiId\": \"ev4hb6gfud\",", "    \"ApiKeySelectionExpression\": \"$request.header.x-api-key\",", "    \"CorsConfiguration\": {", "        \"AllowHeaders\": [", "            \"content-type\",", "            \"authorization\",", "            \"x-user-email\",", "            \"x-user-role\",", "            \"x-amz-date\",", "            \"x-api-key\",", "            \"x-amz-security-token\"", "        ],", "        \"AllowMethods\": [", "            \"GET\",", "            \"POST\",", "            \"OPTIONS\"", "        ],", "        \"AllowOrigins\": [", "            \"*\"", "        ],", "        \"MaxAge\": 86400", "    },", "    \"CreatedDate\": \"2026-06-29T01:36:23+00:00\",", "    \"DisableExecuteApiEndpoint\": false,", "    \"IpAddressType\": \"ipv4\",", "    \"Name\": \"truetally-dev-api\",", "    \"ProtocolType\": \"HTTP\",", "    \"RouteSelectionExpression\": \"$request.method $request.path\",", "    \"Tags\": {}", "}"]}

TASK [api_gateway : Obtener URL del API Gateway] *******************************
ok: [localhost] => {"ansible_facts": {"api_gateway_url": "https://ev4hb6gfud.execute-api.***.amazonaws.com"}, "changed": false}

TASK [api_gateway : Mostrar URL del API Gateway] *******************************
ok: [localhost] => {
    "msg": "API Gateway URL: https://ev4hb6gfud.execute-api.***.amazonaws.com"
}

TASK [lambda : Validar variables de BD provenientes del rol database] **********
Error: : Task failed: The filter plugin 'ansible.builtin.length' failed: object of type '_AnsibleTaggedInt' has no len()

Task failed.
Origin: /home/runner/work/TrueTally/TrueTally/ansible/roles/lambda/tasks/main.yml:13:3

11 # =============================================================================
12
13 - name: Validar variables de BD provenientes del rol database
     ^ column 3

<<< caused by >>>

The filter plugin 'ansible.builtin.length' failed: object of type '_AnsibleTaggedInt' has no len()
Origin: /home/runner/work/TrueTally/TrueTally/ansible/roles/lambda/tasks/main.yml:20:9

18       - db_password is defined and db_password | length > 0
19       - db_endpoint is defined and db_endpoint | length > 0
20       - db_port is defined and db_port | length > 0
           ^ column 9

fatal: [localhost]: FAILED! => {"changed": false, "msg": "Task failed: The filter plugin 'ansible.builtin.length' failed: object of type '_AnsibleTaggedInt' has no len()"}

PLAY RECAP *********************************************************************
localhost                  : ok=41   changed=32   unreachable=0    failed=1    skipped=1    rescued=0    ignored=0   

Error: Process completed with exit code 2.