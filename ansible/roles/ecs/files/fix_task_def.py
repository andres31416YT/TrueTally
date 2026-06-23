import json
import subprocess
import sys

task_def_name = sys.argv[1]
region = sys.argv[2]
new_image = sys.argv[3]

result = subprocess.run([
    'aws', 'ecs', 'describe-task-definition',
    '--task-definition', task_def_name,
    '--region', region,
    '--query', 'taskDefinition',
    '--output', 'json'
], capture_output=True, text=True)

if not result.stdout.strip():
    print("STDOUT is empty", file=sys.stderr)
    print("STDERR:", result.stderr, file=sys.stderr)
    sys.exit(1)

task_def = json.loads(result.stdout)

for container in task_def.get('containerDefinitions', []):
    container['image'] = new_image

for key in ['taskDefinitionArn', 'revision', 'status', 'registeredAt', 'registeredBy', 'requiresAttributes', 'compatibilities', 'requiresCompatibilities']:
    task_def.pop(key, None)

with open('/tmp/task_def.json', 'w') as f:
    json.dump(task_def, f)

reg = subprocess.run([
    'aws', 'ecs', 'register-task-definition',
    '--cli-input-json', 'file:///tmp/task_def.json',
    '--region', region
], capture_output=True, text=True)

print(reg.stdout)
if reg.returncode != 0:
    print(reg.stderr, file=sys.stderr)
    sys.exit(1)
