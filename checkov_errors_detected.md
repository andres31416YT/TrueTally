Run bridgecrewio/checkov-action@master
  with:
    directory: terraform
    soft_fail: true
    output_file_path: checkov_results.xml
    output_format: junitxml
    skip_check: CKV2_AWS_62,CKV_AWS_129,CKV_AWS_16,CKV_AWS_42,CKV_AWS_33
    log_level: WARNING
    container_user: 0
  env:
    TF_INPUT: 0
    AWS_REGION: us-east-1
    TF_VAR_redis_auth_token: ***
    TF_VAR_aws_account_id: ***
    TF_VAR_lambda_zip_path: /home/runner/work/TrueTally/TrueTally/terraform/artifacts
/usr/bin/docker run --name ghcriobridgecrewiocheckov331_73bc49 --label fe1400 --workdir /github/workspace --rm -e "TF_INPUT" -e "AWS_REGION" -e "TF_VAR_redis_auth_token" -e "TF_VAR_aws_account_id" -e "TF_VAR_lambda_zip_path" -e "INPUT_DIRECTORY" -e "INPUT_SOFT_FAIL" -e "INPUT_OUTPUT_FILE_PATH" -e "INPUT_OUTPUT_FORMAT" -e "INPUT_SKIP_CHECK" -e "INPUT_FILE" -e "INPUT_CHECK" -e "INPUT_COMPACT" -e "INPUT_QUIET" -e "INPUT_API-KEY" -e "INPUT_OUTPUT_BC_IDS" -e "INPUT_USE_ENFORCEMENT_RULES" -e "INPUT_SKIP_RESULTS_UPLOAD" -e "INPUT_FRAMEWORK" -e "INPUT_SKIP_FRAMEWORK" -e "INPUT_EXTERNAL_CHECKS_DIRS" -e "INPUT_EXTERNAL_CHECKS_REPOS" -e "INPUT_DOWNLOAD_EXTERNAL_MODULES" -e "INPUT_ENABLE_SECRETS_SCAN_ALL_FILES" -e "INPUT_LOG_LEVEL" -e "INPUT_CONFIG_FILE" -e "INPUT_BASELINE" -e "INPUT_SOFT_FAIL_ON" -e "INPUT_HARD_FAIL_ON" -e "INPUT_CONTAINER_USER" -e "INPUT_DOCKER_IMAGE" -e "INPUT_DOCKERFILE_PATH" -e "INPUT_VAR_FILE" -e "INPUT_GITHUB_PAT" -e "INPUT_TFC_TOKEN" -e "INPUT_TF_REGISTRY_TOKEN" -e "INPUT_CKV_VALIDATE_SECRETS" -e "INPUT_VCS_BASE_URL" -e "INPUT_VCS_USERNAME" -e "INPUT_VCS_TOKEN" -e "INPUT_BITBUCKET_TOKEN" -e "INPUT_BITBUCKET_APP_PASSWORD" -e "INPUT_BITBUCKET_USERNAME" -e "INPUT_REPO_ROOT_FOR_PLAN_ENRICHMENT" -e "INPUT_DEEP_ANALYSIS" -e "INPUT_POLICY_METADATA_FILTER" -e "INPUT_POLICY_METADATA_FILTER_EXCEPTION" -e "INPUT_SKIP_PATH" -e "INPUT_SKIP_CVE_PACKAGE" -e "INPUT_SKIP_DOWNLOAD" -e "INPUT_PRISMA-API-URL" -e "API_KEY_VARIABLE" -e "GITHUB_PAT" -e "TFC_TOKEN" -e "TF_REGISTRY_TOKEN" -e "VCS_USERNAME" -e "VCS_BASE_URL" -e "VCS_TOKEN" -e "BITBUCKET_TOKEN" -e "BITBUCKET_USERNAME" -e "BITBUCKET_APP_PASSWORD" -e "PRISMA_API_URL" -e "CKV_VALIDATE_SECRETS" -e "HOME" -e "GITHUB_JOB" -e "GITHUB_REF" -e "GITHUB_SHA" -e "GITHUB_REPOSITORY" -e "GITHUB_REPOSITORY_OWNER" -e "GITHUB_REPOSITORY_OWNER_ID" -e "GITHUB_RUN_ID" -e "GITHUB_RUN_NUMBER" -e "GITHUB_RETENTION_DAYS" -e "GITHUB_RUN_ATTEMPT" -e "GITHUB_ACTOR_ID" -e "GITHUB_ACTOR" -e "GITHUB_WORKFLOW" -e "GITHUB_HEAD_REF" -e "GITHUB_BASE_REF" -e "GITHUB_EVENT_NAME" -e "GITHUB_SERVER_URL" -e "GITHUB_API_URL" -e "GITHUB_GRAPHQL_URL" -e "GITHUB_REF_NAME" -e "GITHUB_REF_PROTECTED" -e "GITHUB_REF_TYPE" -e "GITHUB_WORKFLOW_REF" -e "GITHUB_WORKFLOW_SHA" -e "GITHUB_REPOSITORY_ID" -e "GITHUB_TRIGGERING_ACTOR" -e "GITHUB_WORKSPACE" -e "GITHUB_ACTION" -e "GITHUB_EVENT_PATH" -e "GITHUB_ACTION_REPOSITORY" -e "GITHUB_ACTION_REF" -e "GITHUB_PATH" -e "GITHUB_ENV" -e "GITHUB_STEP_SUMMARY" -e "GITHUB_STATE" -e "GITHUB_OUTPUT" -e "RUNNER_OS" -e "RUNNER_ARCH" -e "RUNNER_NAME" -e "RUNNER_ENVIRONMENT" -e "RUNNER_TOOL_CACHE" -e "RUNNER_TEMP" -e "RUNNER_WORKSPACE" -e "ACTIONS_RUNTIME_URL" -e "ACTIONS_RUNTIME_TOKEN" -e "ACTIONS_CACHE_URL" -e "ACTIONS_ID_TOKEN_REQUEST_URL" -e "ACTIONS_ID_TOKEN_REQUEST_TOKEN" -e "ACTIONS_RESULTS_URL" -e "ACTIONS_ORCHESTRATION_ID" -e GITHUB_ACTIONS=true -e CI=true -v "/var/run/docker.sock":"/var/run/docker.sock" -v "/home/runner/work/_temp":"/github/runner_temp" -v "/home/runner/work/_temp/_github_home":"/github/home" -v "/home/runner/work/_temp/_github_workflow":"/github/workflow" -v "/home/runner/work/_temp/_runner_file_commands":"/github/file_commands" -v "/home/runner/work/TrueTally/TrueTally":"/github/workspace" ghcr.io/bridgecrewio/checkov:3.3.1  "" "terraform" "" "CKV2_AWS_62,CKV_AWS_129,CKV_AWS_16,CKV_AWS_42,CKV_AWS_33" "" "" "true" "" "" "" "" "" "" "" "junitxml" "checkov_results.xml" "" "" "WARNING" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "--user 0"
running checkov on directory: terraform
BC_FROM_BRANCH=develop
BC_TO_BRANCH=
BC_PR_ID=develop
BC_PR_URL=https://github.com/andres31416YT/TrueTally/pull/develop
BC_COMMIT_HASH=5e2c874f14b0b3440453596a9a5b1052bf8dece3
BC_COMMIT_URL=https://github.com/andres31416YT/TrueTally/commit/5e2c874f14b0b3440453596a9a5b1052bf8dece3
BC_AUTHOR_NAME=andres31416YT
BC_AUTHOR_URL=https://github.com/andres31416YT
BC_RUN_ID=90
BC_RUN_URL=https://github.com/andres31416YT/TrueTally/actions/runs/27572497239
BC_REPOSITORY_URL=https://github.com/andres31416YT/TrueTally
checkov -d terraform --output-file-path checkov_results.xml --soft-fail --skip-check CKV2_AWS_62 --skip-check CKV_AWS_129 --skip-check CKV_AWS_16 --skip-check CKV_AWS_42 --skip-check CKV_AWS_33 --output junitxml
<?xml version="1.0" ?>
<testsuites disabled="0" errors="0" failures="68" tests="172" time="0.0">
	<testsuite disabled="0" errors="0" failures="68" name="terraform scan" skipped="0" tests="172" time="0">
		<properties>
			<property name="directory" value="['terraform']"/>
			<property name="add_check" value="False"/>
			<property name="list" value="False"/>
			<property name="output" value="['junitxml']"/>
			<property name="output_file_path" value="checkov_results.xml"/>
			<property name="output_bc_ids" value="False"/>
			<property name="include_all_checkov_policies" value="True"/>
			<property name="quiet" value="False"/>
			<property name="compact" value="False"/>
			<property name="framework" value="['all']"/>
			<property name="skip_framework" value="[]"/>
			<property name="skip_check" value="['CKV2_AWS_62', 'CKV_AWS_129', 'CKV_AWS_16', 'CKV_AWS_42', 'CKV_AWS_33']"/>
			<property name="run_all_external_checks" value="False"/>
			<property name="soft_fail" value="True"/>
			<property name="prisma_api_url" value=""/>
			<property name="skip_results_upload" value="False"/>
			<property name="repo_id" value="cli_repo/terraform"/>
			<property name="branch" value="master"/>
			<property name="skip_download" value="False"/>
			<property name="use_enforcement_rules" value="False"/>
			<property name="external_modules_download_path" value=".external_modules"/>
			<property name="evaluate_variables" value="True"/>
			<property name="no_cert_verify" value="False"/>
			<property name="create_baseline" value="False"/>
			<property name="output_baseline_as_skipped" value="False"/>
			<property name="secrets_scan_file_type" value="[]"/>
			<property name="enable_secret_scan_all_files" value="False"/>
			<property name="block_list_secret_scan" value="[]"/>
			<property name="summary_position" value="top"/>
			<property name="skip_resources_without_violations" value="False"/>
			<property name="deep_analysis" value="False"/>
			<property name="no_fail_on_crash" value="False"/>
			<property name="mask" value="defaultdict(&lt;class 'set'&gt;, {})"/>
			<property name="scan_secrets_history" value="False"/>
			<property name="secrets_history_timeout" value="12h"/>
			<property name="custom_tool_name" value="Checkov"/>
		</properties>
		<testcase name="[NONE][CKV_AWS_41] Ensure no hard coded AWS access key and secret key exists in provider" classname="/environments/dev/providers.tf.aws.default" file="/environments/dev/providers.tf"/>
		<testcase name="[NONE][CKV_AWS_41] Ensure no hard coded AWS access key and secret key exists in provider" classname="/environments/prod/providers.tf.aws.default" file="/environments/prod/providers.tf"/>
		<testcase name="[NONE][CKV_AWS_393] Ensure AWS GitHub Actions OIDC authorization policies only allow safe claims and claim order on IAM role" classname="/modules/compute/main.tf.module.compute.aws_iam_role.lambda" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_61] Ensure AWS IAM policy does not allow assume role permission across all services" classname="/modules/compute/main.tf.module.compute.aws_iam_role.lambda" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_274] Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy" classname="/modules/compute/main.tf.module.compute.aws_iam_role.lambda" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_60] Ensure IAM role allows only specific services or principals to assume it" classname="/modules/compute/main.tf.module.compute.aws_iam_role.lambda" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_274] Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy_attachment.lambda_basic" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_274] Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy_attachment.lambda_vpc" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_286] Ensure IAM policies does not allow privilege escalation" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_62] Ensure IAM policies that allow full &quot;*-*&quot; administrative privileges are not created" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_289] Ensure IAM policies does not allow permissions management / resource exposure without constraints" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_63] Ensure no IAM policies documents allow &quot;*&quot; as a statement's actions" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_287] Ensure IAM policies does not allow credentials exposure" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_45] Ensure no hard-coded secrets exist in lambda environment" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_363] Ensure Lambda Runtime is not deprecated" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_117] Ensure that AWS Lambda function is configured inside a VPC" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_45] Ensure no hard-coded secrets exist in lambda environment" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_363] Ensure Lambda Runtime is not deprecated" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_117] Ensure that AWS Lambda function is configured inside a VPC" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_45] Ensure no hard-coded secrets exist in lambda environment" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_363] Ensure Lambda Runtime is not deprecated" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_117] Ensure that AWS Lambda function is configured inside a VPC" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_223] Ensure ECS Cluster enables logging of ECS Exec" classname="/modules/compute/main.tf.module.compute.aws_ecs_cluster.blockchain" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_393] Ensure AWS GitHub Actions OIDC authorization policies only allow safe claims and claim order on IAM role" classname="/modules/compute/main.tf.module.compute.aws_iam_role.ecs_task" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_61] Ensure AWS IAM policy does not allow assume role permission across all services" classname="/modules/compute/main.tf.module.compute.aws_iam_role.ecs_task" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_274] Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy" classname="/modules/compute/main.tf.module.compute.aws_iam_role.ecs_task" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_60] Ensure IAM role allows only specific services or principals to assume it" classname="/modules/compute/main.tf.module.compute.aws_iam_role.ecs_task" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_274] Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy_attachment.ecs_task_ecr" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_97] Ensure Encryption in transit is enabled for EFS volumes in ECS Task definitions" classname="/modules/compute/main.tf.module.compute.aws_ecs_task_definition.blockchain" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_335] Ensure ECS task definitions should not share the host's process namespace" classname="/modules/compute/main.tf.module.compute.aws_ecs_task_definition.blockchain" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_249] Ensure that the Execution Role ARN and the Task Role ARN are different in ECS Task definitions" classname="/modules/compute/main.tf.module.compute.aws_ecs_task_definition.blockchain" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_334] Ensure ECS containers should run as non-privileged" classname="/modules/compute/main.tf.module.compute.aws_ecs_task_definition.blockchain" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_184] Ensure resource is encrypted by KMS using a customer managed Key (CMK)" classname="/modules/compute/main.tf.module.compute.aws_efs_file_system.blockchain" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_333] Ensure ECS services do not have public IP addresses assigned to them automatically" classname="/modules/compute/main.tf.module.compute.aws_ecs_service.blockchain" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_382] Ensure no security groups allow egress from 0.0.0.0:0 to port -1" classname="/modules/database/main.tf.module.database.aws_security_group.elasticache" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_277] Ensure no security groups allow ingress from 0.0.0.0:0 to port -1" classname="/modules/database/main.tf.module.database.aws_security_group.elasticache" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_25] Ensure no security groups allow ingress from 0.0.0.0:0 to port 3389" classname="/modules/database/main.tf.module.database.aws_security_group.elasticache" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_24] Ensure no security groups allow ingress from 0.0.0.0:0 to port 22" classname="/modules/database/main.tf.module.database.aws_security_group.elasticache" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_260] Ensure no security groups allow ingress from 0.0.0.0:0 to port 80" classname="/modules/database/main.tf.module.database.aws_security_group.elasticache" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_354] Ensure RDS Performance Insights are encrypted using KMS CMKs" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_211] Ensure RDS uses a modern CaCert" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_133] Ensure that RDS instances has backup policy" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_250] Ensure that RDS PostgreSQL instances use a non vulnerable version with the log_fdw extension (https://aws.amazon.com/security/security-bulletins/AWS-2022-004/)" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_388] Ensure AWS Aurora PostgreSQL is not exposed to local file read vulnerability" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_17] Ensure all data stored in RDS is not publicly accessible" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_93] Ensure S3 bucket policy does not lockout all but root user. (Prevent lockouts needing root account fixes)" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_54] Ensure S3 bucket has block public policy enabled" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket_public_access_block.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_53] Ensure S3 bucket has block public ACLS enabled" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket_public_access_block.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_55] Ensure S3 bucket has ignore public ACLs enabled" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket_public_access_block.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_56] Ensure S3 bucket has 'restrict_public_buckets' enabled" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket_public_access_block.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_70] Ensure S3 bucket does not allow an action with any Principal" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket_policy.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_93] Ensure S3 bucket policy does not lockout all but root user. (Prevent lockouts needing root account fixes)" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket_policy.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_216] Ensure CloudFront distribution is enabled" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_34] Ensure CloudFront distribution ViewerProtocolPolicy is set to HTTPS" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_305] Ensure CloudFront distribution has a default root object configured" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_168] Ensure SQS queue policy is not public by only allowing specific services or principals to access it" classname="/modules/messaging/main.tf.module.messaging.aws_sqs_queue.vote_queue" file="/modules/messaging/main.tf"/>
		<testcase name="[NONE][CKV_AWS_168] Ensure SQS queue policy is not public by only allowing specific services or principals to access it" classname="/modules/messaging/main.tf.module.messaging.aws_sqs_queue.dlq" file="/modules/messaging/main.tf"/>
		<testcase name="[NONE][CKV_AWS_66] Ensure that CloudWatch Log Group specifies retention days" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_acceso" file="/modules/monitoring/main.tf"/>
		<testcase name="[NONE][CKV_AWS_66] Ensure that CloudWatch Log Group specifies retention days" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_despachador" file="/modules/monitoring/main.tf"/>
		<testcase name="[NONE][CKV_AWS_66] Ensure that CloudWatch Log Group specifies retention days" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_procesador" file="/modules/monitoring/main.tf"/>
		<testcase name="[NONE][CKV_AWS_66] Ensure that CloudWatch Log Group specifies retention days" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.ecs_blockchain" file="/modules/monitoring/main.tf"/>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.compute[&quot;us-east-1a&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.database[&quot;us-east-1a&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.blockchain[&quot;us-east-1a&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_277] Ensure no security groups allow ingress from 0.0.0.0:0 to port -1" classname="/modules/networking/main.tf.module.networking.aws_security_group.lambda" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_25] Ensure no security groups allow ingress from 0.0.0.0:0 to port 3389" classname="/modules/networking/main.tf.module.networking.aws_security_group.lambda" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_24] Ensure no security groups allow ingress from 0.0.0.0:0 to port 22" classname="/modules/networking/main.tf.module.networking.aws_security_group.lambda" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_260] Ensure no security groups allow ingress from 0.0.0.0:0 to port 80" classname="/modules/networking/main.tf.module.networking.aws_security_group.lambda" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_277] Ensure no security groups allow ingress from 0.0.0.0:0 to port -1" classname="/modules/networking/main.tf.module.networking.aws_security_group.database" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_25] Ensure no security groups allow ingress from 0.0.0.0:0 to port 3389" classname="/modules/networking/main.tf.module.networking.aws_security_group.database" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_24] Ensure no security groups allow ingress from 0.0.0.0:0 to port 22" classname="/modules/networking/main.tf.module.networking.aws_security_group.database" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_260] Ensure no security groups allow ingress from 0.0.0.0:0 to port 80" classname="/modules/networking/main.tf.module.networking.aws_security_group.database" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.compute[&quot;us-east-1b&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.database[&quot;us-east-1b&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.blockchain[&quot;us-east-1b&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_227] Ensure KMS key is enabled" classname="/modules/security/main.tf.module.security.aws_kms_key.main" file="/modules/security/main.tf"/>
		<testcase name="[NONE][CKV_AWS_7] Ensure rotation for customer created CMKs is enabled" classname="/modules/security/main.tf.module.security.aws_kms_key.main" file="/modules/security/main.tf"/>
		<testcase name="[NONE][CKV_AWS_149] Ensure that Secrets Manager secret is encrypted using KMS CMK" classname="/modules/security/main.tf.module.security.aws_secretsmanager_secret.db_credentials" file="/modules/security/main.tf"/>
		<testcase name="[NONE][CKV_AWS_149] Ensure that Secrets Manager secret is encrypted using KMS CMK" classname="/modules/security/main.tf.module.security.aws_secretsmanager_secret.redis_auth_token" file="/modules/security/main.tf"/>
		<testcase name="[NONE][CKV_AWS_41] Ensure no hard coded AWS access key and secret key exists in provider" classname="/providers.tf.aws.default" file="/providers.tf"/>
		<testcase name="[NONE][CKV2_AWS_5] Ensure that Security Groups are attached to another resource" classname="/modules/database/main.tf.module.database.aws_security_group.elasticache" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_73] Ensure AWS SQS uses CMK not AWS default keys for encryption" classname="/modules/messaging/main.tf.module.messaging.aws_sqs_queue.vote_queue" file="/modules/messaging/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_73] Ensure AWS SQS uses CMK not AWS default keys for encryption" classname="/modules/messaging/main.tf.module.messaging.aws_sqs_queue.dlq" file="/modules/messaging/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_64] Ensure KMS key Policy is defined" classname="/modules/security/main.tf.module.security.aws_kms_key.main" file="/modules/security/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_56] Ensure AWS Managed IAMFullAccess IAM policy is not used." classname="/modules/compute/main.tf.module.compute.aws_iam_role.lambda" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_56] Ensure AWS Managed IAMFullAccess IAM policy is not used." classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy_attachment.lambda_basic" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_56] Ensure AWS Managed IAMFullAccess IAM policy is not used." classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy_attachment.lambda_vpc" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_56] Ensure AWS Managed IAMFullAccess IAM policy is not used." classname="/modules/compute/main.tf.module.compute.aws_iam_role.ecs_task" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_56] Ensure AWS Managed IAMFullAccess IAM policy is not used." classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy_attachment.ecs_task_ecr" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_69] Ensure AWS RDS database instance configured with encryption in transit" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf"/>
		<testcase name="[NONE][CKV_AWS_20] S3 Bucket has an ACL defined which allows public READ access." classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_72] Ensure AWS CloudFront origin protocol policy enforces HTTPS-only" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_46] Ensure AWS CloudFront Distribution with S3 have Origin Access set to enabled" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_40] Ensure AWS IAM policy does not allow full IAM privileges" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_75] Ensure no open CORS policy" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_75] Ensure no open CORS policy" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_75] Ensure no open CORS policy" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf"/>
		<testcase name="[NONE][CKV_AWS_57] S3 Bucket has an ACL defined which allows public WRITE access." classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_54] Ensure AWS CloudFront distribution is using secure SSL protocols for HTTPS communication" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_6] Ensure that S3 bucket has a Public Access block" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_21] Ensure all data stored in the S3 bucket have versioning enabled" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV_AWS_19] Ensure all data stored in the S3 bucket is securely encrypted at rest" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_19] Ensure that all EIP addresses allocated to a VPC are attached to EC2 instances" classname="/modules/networking/main.tf.module.networking.aws_eip.nat[&quot;us-east-1a&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV2_AWS_19] Ensure that all EIP addresses allocated to a VPC are attached to EC2 instances" classname="/modules/networking/main.tf.module.networking.aws_eip.nat[&quot;us-east-1b&quot;]" file="/modules/networking/main.tf"/>
		<testcase name="[NONE][CKV_AWS_290] Ensure IAM policies does not allow write access without constraints" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure IAM policies does not allow write access without constraints">
Resource: module.compute.aws_iam_role_policy.lambda_ssm
File: /modules/compute/main.tf: 54-76
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-iam-policies/bc-aws-290

		54 | resource &quot;aws_iam_role_policy&quot; &quot;lambda_ssm&quot; {
		55 |   name = &quot;${local.name_prefix}-lambda-ssm&quot;
		56 |   role = aws_iam_role.lambda.id
		57 | 
		58 |   policy = jsonencode({
		59 |     Version = &quot;2012-10-17&quot;
		60 |     Statement = [
		61 |       {
		62 |         Effect = &quot;Allow&quot;
		63 |         Action = [
		64 |           &quot;ssm:DescribeInstanceInformation&quot;,
		65 |           &quot;ssm:StartSession&quot;,
		66 |           &quot;ssm:SendCommand&quot;,
		67 |           &quot;secretsmanager:GetSecretValue&quot;,
		68 |           &quot;sqs:ReceiveMessage&quot;,
		69 |           &quot;sqs:DeleteMessage&quot;,
		70 |           &quot;sqs:GetQueueAttributes&quot;
		71 |         ]
		72 |         Resource = &quot;*&quot;
		73 |       }
		74 |     ]
		75 |   })
		76 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_355] Ensure no IAM policies documents allow &quot;*&quot; as a statement's resource for restrictable actions" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure no IAM policies documents allow &quot;*&quot; as a statement's resource for restrictable actions">
Resource: module.compute.aws_iam_role_policy.lambda_ssm
File: /modules/compute/main.tf: 54-76
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-iam-policies/bc-aws-355

		54 | resource &quot;aws_iam_role_policy&quot; &quot;lambda_ssm&quot; {
		55 |   name = &quot;${local.name_prefix}-lambda-ssm&quot;
		56 |   role = aws_iam_role.lambda.id
		57 | 
		58 |   policy = jsonencode({
		59 |     Version = &quot;2012-10-17&quot;
		60 |     Statement = [
		61 |       {
		62 |         Effect = &quot;Allow&quot;
		63 |         Action = [
		64 |           &quot;ssm:DescribeInstanceInformation&quot;,
		65 |           &quot;ssm:StartSession&quot;,
		66 |           &quot;ssm:SendCommand&quot;,
		67 |           &quot;secretsmanager:GetSecretValue&quot;,
		68 |           &quot;sqs:ReceiveMessage&quot;,
		69 |           &quot;sqs:DeleteMessage&quot;,
		70 |           &quot;sqs:GetQueueAttributes&quot;
		71 |         ]
		72 |         Resource = &quot;*&quot;
		73 |       }
		74 |     ]
		75 |   })
		76 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_288] Ensure IAM policies does not allow data exfiltration" classname="/modules/compute/main.tf.module.compute.aws_iam_role_policy.lambda_ssm" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure IAM policies does not allow data exfiltration">
Resource: module.compute.aws_iam_role_policy.lambda_ssm
File: /modules/compute/main.tf: 54-76
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-iam-policies/bc-aws-288

		54 | resource &quot;aws_iam_role_policy&quot; &quot;lambda_ssm&quot; {
		55 |   name = &quot;${local.name_prefix}-lambda-ssm&quot;
		56 |   role = aws_iam_role.lambda.id
		57 | 
		58 |   policy = jsonencode({
		59 |     Version = &quot;2012-10-17&quot;
		60 |     Statement = [
		61 |       {
		62 |         Effect = &quot;Allow&quot;
		63 |         Action = [
		64 |           &quot;ssm:DescribeInstanceInformation&quot;,
		65 |           &quot;ssm:StartSession&quot;,
		66 |           &quot;ssm:SendCommand&quot;,
		67 |           &quot;secretsmanager:GetSecretValue&quot;,
		68 |           &quot;sqs:ReceiveMessage&quot;,
		69 |           &quot;sqs:DeleteMessage&quot;,
		70 |           &quot;sqs:GetQueueAttributes&quot;
		71 |         ]
		72 |         Resource = &quot;*&quot;
		73 |       }
		74 |     ]
		75 |   })
		76 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_116] Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)">
Resource: module.compute.aws_lambda_function.acceso
File: /modules/compute/main.tf: 79-96
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-for-a-dead-letter-queue-dlq

		79 | resource &quot;aws_lambda_function&quot; &quot;acceso&quot; {
		80 |   function_name = &quot;${local.name_prefix}-acceso&quot;
		81 |   filename      = &quot;${var.lambda_zip_path}/lambda-acceso.zip&quot;
		82 |   role          = aws_iam_role.lambda.arn
		83 |   handler       = &quot;bootstrap&quot;
		84 |   runtime       = &quot;provided.al2&quot;
		85 | 
		86 |   vpc_config {
		87 |     subnet_ids         = var.private_subnet_ids
		88 |     security_group_ids = [var.lambda_security_group_id]
		89 |   }
		90 | 
		91 |   environment {
		92 |     variables = {
		93 |       DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
		94 |     }
		95 |   }
		96 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_50] X-Ray tracing is enabled for Lambda" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf">
			<failure type="failure" message="X-Ray tracing is enabled for Lambda">
Resource: module.compute.aws_lambda_function.acceso
File: /modules/compute/main.tf: 79-96
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-serverless-policies/bc-aws-serverless-4

		79 | resource &quot;aws_lambda_function&quot; &quot;acceso&quot; {
		80 |   function_name = &quot;${local.name_prefix}-acceso&quot;
		81 |   filename      = &quot;${var.lambda_zip_path}/lambda-acceso.zip&quot;
		82 |   role          = aws_iam_role.lambda.arn
		83 |   handler       = &quot;bootstrap&quot;
		84 |   runtime       = &quot;provided.al2&quot;
		85 | 
		86 |   vpc_config {
		87 |     subnet_ids         = var.private_subnet_ids
		88 |     security_group_ids = [var.lambda_security_group_id]
		89 |   }
		90 | 
		91 |   environment {
		92 |     variables = {
		93 |       DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
		94 |     }
		95 |   }
		96 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_173] Check encryption settings for Lambda environmental variable" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf">
			<failure type="failure" message="Check encryption settings for Lambda environmental variable">
Resource: module.compute.aws_lambda_function.acceso
File: /modules/compute/main.tf: 79-96
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-serverless-policies/bc-aws-serverless-5

		79 | resource &quot;aws_lambda_function&quot; &quot;acceso&quot; {
		80 |   function_name = &quot;${local.name_prefix}-acceso&quot;
		81 |   filename      = &quot;${var.lambda_zip_path}/lambda-acceso.zip&quot;
		82 |   role          = aws_iam_role.lambda.arn
		83 |   handler       = &quot;bootstrap&quot;
		84 |   runtime       = &quot;provided.al2&quot;
		85 | 
		86 |   vpc_config {
		87 |     subnet_ids         = var.private_subnet_ids
		88 |     security_group_ids = [var.lambda_security_group_id]
		89 |   }
		90 | 
		91 |   environment {
		92 |     variables = {
		93 |       DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
		94 |     }
		95 |   }
		96 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_272] Ensure AWS Lambda function is configured to validate code-signing" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure AWS Lambda function is configured to validate code-signing">
Resource: module.compute.aws_lambda_function.acceso
File: /modules/compute/main.tf: 79-96
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-272

		79 | resource &quot;aws_lambda_function&quot; &quot;acceso&quot; {
		80 |   function_name = &quot;${local.name_prefix}-acceso&quot;
		81 |   filename      = &quot;${var.lambda_zip_path}/lambda-acceso.zip&quot;
		82 |   role          = aws_iam_role.lambda.arn
		83 |   handler       = &quot;bootstrap&quot;
		84 |   runtime       = &quot;provided.al2&quot;
		85 | 
		86 |   vpc_config {
		87 |     subnet_ids         = var.private_subnet_ids
		88 |     security_group_ids = [var.lambda_security_group_id]
		89 |   }
		90 | 
		91 |   environment {
		92 |     variables = {
		93 |       DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
		94 |     }
		95 |   }
		96 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_115] Ensure that AWS Lambda function is configured for function-level concurrent execution limit" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.acceso" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure that AWS Lambda function is configured for function-level concurrent execution limit">
Resource: module.compute.aws_lambda_function.acceso
File: /modules/compute/main.tf: 79-96
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-for-function-level-concurrent-execution-limit

		79 | resource &quot;aws_lambda_function&quot; &quot;acceso&quot; {
		80 |   function_name = &quot;${local.name_prefix}-acceso&quot;
		81 |   filename      = &quot;${var.lambda_zip_path}/lambda-acceso.zip&quot;
		82 |   role          = aws_iam_role.lambda.arn
		83 |   handler       = &quot;bootstrap&quot;
		84 |   runtime       = &quot;provided.al2&quot;
		85 | 
		86 |   vpc_config {
		87 |     subnet_ids         = var.private_subnet_ids
		88 |     security_group_ids = [var.lambda_security_group_id]
		89 |   }
		90 | 
		91 |   environment {
		92 |     variables = {
		93 |       DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
		94 |     }
		95 |   }
		96 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_116] Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)">
Resource: module.compute.aws_lambda_function.despachador
File: /modules/compute/main.tf: 98-115
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-for-a-dead-letter-queue-dlq

		98  | resource &quot;aws_lambda_function&quot; &quot;despachador&quot; {
		99  |   function_name = &quot;${local.name_prefix}-despachador&quot;
		100 |   filename      = &quot;${var.lambda_zip_path}/lambda-despachador.zip&quot;
		101 |   role          = aws_iam_role.lambda.arn
		102 |   handler       = &quot;bootstrap&quot;
		103 |   runtime       = &quot;provided.al2&quot;
		104 | 
		105 |   vpc_config {
		106 |     subnet_ids         = var.private_subnet_ids
		107 |     security_group_ids = [var.lambda_security_group_id]
		108 |   }
		109 | 
		110 |   environment {
		111 |     variables = {
		112 |       VOTE_QUEUE_URL = var.vote_queue_url
		113 |     }
		114 |   }
		115 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_50] X-Ray tracing is enabled for Lambda" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf">
			<failure type="failure" message="X-Ray tracing is enabled for Lambda">
Resource: module.compute.aws_lambda_function.despachador
File: /modules/compute/main.tf: 98-115
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-serverless-policies/bc-aws-serverless-4

		98  | resource &quot;aws_lambda_function&quot; &quot;despachador&quot; {
		99  |   function_name = &quot;${local.name_prefix}-despachador&quot;
		100 |   filename      = &quot;${var.lambda_zip_path}/lambda-despachador.zip&quot;
		101 |   role          = aws_iam_role.lambda.arn
		102 |   handler       = &quot;bootstrap&quot;
		103 |   runtime       = &quot;provided.al2&quot;
		104 | 
		105 |   vpc_config {
		106 |     subnet_ids         = var.private_subnet_ids
		107 |     security_group_ids = [var.lambda_security_group_id]
		108 |   }
		109 | 
		110 |   environment {
		111 |     variables = {
		112 |       VOTE_QUEUE_URL = var.vote_queue_url
		113 |     }
		114 |   }
		115 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_173] Check encryption settings for Lambda environmental variable" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf">
			<failure type="failure" message="Check encryption settings for Lambda environmental variable">
Resource: module.compute.aws_lambda_function.despachador
File: /modules/compute/main.tf: 98-115
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-serverless-policies/bc-aws-serverless-5

		98  | resource &quot;aws_lambda_function&quot; &quot;despachador&quot; {
		99  |   function_name = &quot;${local.name_prefix}-despachador&quot;
		100 |   filename      = &quot;${var.lambda_zip_path}/lambda-despachador.zip&quot;
		101 |   role          = aws_iam_role.lambda.arn
		102 |   handler       = &quot;bootstrap&quot;
		103 |   runtime       = &quot;provided.al2&quot;
		104 | 
		105 |   vpc_config {
		106 |     subnet_ids         = var.private_subnet_ids
		107 |     security_group_ids = [var.lambda_security_group_id]
		108 |   }
		109 | 
		110 |   environment {
		111 |     variables = {
		112 |       VOTE_QUEUE_URL = var.vote_queue_url
		113 |     }
		114 |   }
		115 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_272] Ensure AWS Lambda function is configured to validate code-signing" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure AWS Lambda function is configured to validate code-signing">
Resource: module.compute.aws_lambda_function.despachador
File: /modules/compute/main.tf: 98-115
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-272

		98  | resource &quot;aws_lambda_function&quot; &quot;despachador&quot; {
		99  |   function_name = &quot;${local.name_prefix}-despachador&quot;
		100 |   filename      = &quot;${var.lambda_zip_path}/lambda-despachador.zip&quot;
		101 |   role          = aws_iam_role.lambda.arn
		102 |   handler       = &quot;bootstrap&quot;
		103 |   runtime       = &quot;provided.al2&quot;
		104 | 
		105 |   vpc_config {
		106 |     subnet_ids         = var.private_subnet_ids
		107 |     security_group_ids = [var.lambda_security_group_id]
		108 |   }
		109 | 
		110 |   environment {
		111 |     variables = {
		112 |       VOTE_QUEUE_URL = var.vote_queue_url
		113 |     }
		114 |   }
		115 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_115] Ensure that AWS Lambda function is configured for function-level concurrent execution limit" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.despachador" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure that AWS Lambda function is configured for function-level concurrent execution limit">
Resource: module.compute.aws_lambda_function.despachador
File: /modules/compute/main.tf: 98-115
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-for-function-level-concurrent-execution-limit

		98  | resource &quot;aws_lambda_function&quot; &quot;despachador&quot; {
		99  |   function_name = &quot;${local.name_prefix}-despachador&quot;
		100 |   filename      = &quot;${var.lambda_zip_path}/lambda-despachador.zip&quot;
		101 |   role          = aws_iam_role.lambda.arn
		102 |   handler       = &quot;bootstrap&quot;
		103 |   runtime       = &quot;provided.al2&quot;
		104 | 
		105 |   vpc_config {
		106 |     subnet_ids         = var.private_subnet_ids
		107 |     security_group_ids = [var.lambda_security_group_id]
		108 |   }
		109 | 
		110 |   environment {
		111 |     variables = {
		112 |       VOTE_QUEUE_URL = var.vote_queue_url
		113 |     }
		114 |   }
		115 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_116] Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)">
Resource: module.compute.aws_lambda_function.procesador
File: /modules/compute/main.tf: 117-135
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-for-a-dead-letter-queue-dlq

		117 | resource &quot;aws_lambda_function&quot; &quot;procesador&quot; {
		118 |   function_name = &quot;${local.name_prefix}-procesador&quot;
		119 |   filename      = &quot;${var.lambda_zip_path}/lambda-procesador.zip&quot;
		120 |   role          = aws_iam_role.lambda.arn
		121 |   handler       = &quot;bootstrap&quot;
		122 |   runtime       = &quot;provided.al2&quot;
		123 | 
		124 |   vpc_config {
		125 |     subnet_ids         = var.private_subnet_ids
		126 |     security_group_ids = [var.lambda_security_group_id]
		127 |   }
		128 | 
		129 |   environment {
		130 |     variables = {
		131 |       NODE_URL_AZ1 = var.lambda_node_url_az1
		132 |       NODE_URL_AZ2 = var.lambda_node_url_az2
		133 |     }
		134 |   }
		135 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_50] X-Ray tracing is enabled for Lambda" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf">
			<failure type="failure" message="X-Ray tracing is enabled for Lambda">
Resource: module.compute.aws_lambda_function.procesador
File: /modules/compute/main.tf: 117-135
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-serverless-policies/bc-aws-serverless-4

		117 | resource &quot;aws_lambda_function&quot; &quot;procesador&quot; {
		118 |   function_name = &quot;${local.name_prefix}-procesador&quot;
		119 |   filename      = &quot;${var.lambda_zip_path}/lambda-procesador.zip&quot;
		120 |   role          = aws_iam_role.lambda.arn
		121 |   handler       = &quot;bootstrap&quot;
		122 |   runtime       = &quot;provided.al2&quot;
		123 | 
		124 |   vpc_config {
		125 |     subnet_ids         = var.private_subnet_ids
		126 |     security_group_ids = [var.lambda_security_group_id]
		127 |   }
		128 | 
		129 |   environment {
		130 |     variables = {
		131 |       NODE_URL_AZ1 = var.lambda_node_url_az1
		132 |       NODE_URL_AZ2 = var.lambda_node_url_az2
		133 |     }
		134 |   }
		135 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_173] Check encryption settings for Lambda environmental variable" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf">
			<failure type="failure" message="Check encryption settings for Lambda environmental variable">
Resource: module.compute.aws_lambda_function.procesador
File: /modules/compute/main.tf: 117-135
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-serverless-policies/bc-aws-serverless-5

		117 | resource &quot;aws_lambda_function&quot; &quot;procesador&quot; {
		118 |   function_name = &quot;${local.name_prefix}-procesador&quot;
		119 |   filename      = &quot;${var.lambda_zip_path}/lambda-procesador.zip&quot;
		120 |   role          = aws_iam_role.lambda.arn
		121 |   handler       = &quot;bootstrap&quot;
		122 |   runtime       = &quot;provided.al2&quot;
		123 | 
		124 |   vpc_config {
		125 |     subnet_ids         = var.private_subnet_ids
		126 |     security_group_ids = [var.lambda_security_group_id]
		127 |   }
		128 | 
		129 |   environment {
		130 |     variables = {
		131 |       NODE_URL_AZ1 = var.lambda_node_url_az1
		132 |       NODE_URL_AZ2 = var.lambda_node_url_az2
		133 |     }
		134 |   }
		135 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_272] Ensure AWS Lambda function is configured to validate code-signing" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure AWS Lambda function is configured to validate code-signing">
Resource: module.compute.aws_lambda_function.procesador
File: /modules/compute/main.tf: 117-135
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-272

		117 | resource &quot;aws_lambda_function&quot; &quot;procesador&quot; {
		118 |   function_name = &quot;${local.name_prefix}-procesador&quot;
		119 |   filename      = &quot;${var.lambda_zip_path}/lambda-procesador.zip&quot;
		120 |   role          = aws_iam_role.lambda.arn
		121 |   handler       = &quot;bootstrap&quot;
		122 |   runtime       = &quot;provided.al2&quot;
		123 | 
		124 |   vpc_config {
		125 |     subnet_ids         = var.private_subnet_ids
		126 |     security_group_ids = [var.lambda_security_group_id]
		127 |   }
		128 | 
		129 |   environment {
		130 |     variables = {
		131 |       NODE_URL_AZ1 = var.lambda_node_url_az1
		132 |       NODE_URL_AZ2 = var.lambda_node_url_az2
		133 |     }
		134 |   }
		135 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_115] Ensure that AWS Lambda function is configured for function-level concurrent execution limit" classname="/modules/compute/main.tf.module.compute.aws_lambda_function.procesador" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure that AWS Lambda function is configured for function-level concurrent execution limit">
Resource: module.compute.aws_lambda_function.procesador
File: /modules/compute/main.tf: 117-135
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-for-function-level-concurrent-execution-limit

		117 | resource &quot;aws_lambda_function&quot; &quot;procesador&quot; {
		118 |   function_name = &quot;${local.name_prefix}-procesador&quot;
		119 |   filename      = &quot;${var.lambda_zip_path}/lambda-procesador.zip&quot;
		120 |   role          = aws_iam_role.lambda.arn
		121 |   handler       = &quot;bootstrap&quot;
		122 |   runtime       = &quot;provided.al2&quot;
		123 | 
		124 |   vpc_config {
		125 |     subnet_ids         = var.private_subnet_ids
		126 |     security_group_ids = [var.lambda_security_group_id]
		127 |   }
		128 | 
		129 |   environment {
		130 |     variables = {
		131 |       NODE_URL_AZ1 = var.lambda_node_url_az1
		132 |       NODE_URL_AZ2 = var.lambda_node_url_az2
		133 |     }
		134 |   }
		135 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_65] Ensure container insights are enabled on ECS cluster" classname="/modules/compute/main.tf.module.compute.aws_ecs_cluster.blockchain" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure container insights are enabled on ECS cluster">
Resource: module.compute.aws_ecs_cluster.blockchain
File: /modules/compute/main.tf: 138-140
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-logging-11

		138 | resource &quot;aws_ecs_cluster&quot; &quot;blockchain&quot; {
		139 |   name = &quot;${local.name_prefix}-blockchain-cluster&quot;
		140 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_336] Ensure ECS containers are limited to read-only access to root filesystems" classname="/modules/compute/main.tf.module.compute.aws_ecs_task_definition.blockchain" file="/modules/compute/main.tf">
			<failure type="failure" message="Ensure ECS containers are limited to read-only access to root filesystems">
Resource: module.compute.aws_ecs_task_definition.blockchain
File: /modules/compute/main.tf: 164-181
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-336

		164 | resource &quot;aws_ecs_task_definition&quot; &quot;blockchain&quot; {
		165 |   family                   = &quot;${local.name_prefix}-blockchain&quot;
		166 |   network_mode             = &quot;awsvpc&quot;
		167 |   requires_compatibilities = [&quot;FARGATE&quot;]
		168 |   cpu                      = &quot;512&quot;
		169 |   memory                   = &quot;1024&quot;
		170 |   execution_role_arn       = aws_iam_role.ecs_task.arn
		171 | 
		172 |   container_definitions = jsonencode([{
		173 |     name      = &quot;blockchain-node&quot;
		174 |     image     = &quot;${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-blockchain:latest&quot;
		175 |     essential = true
		176 |     portMappings = [{
		177 |       containerPort = 9944
		178 |       hostPort      = 9944
		179 |     }]
		180 |   }])
		181 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_23] Ensure every security group and rule has a description" classname="/modules/database/main.tf.module.database.aws_security_group.elasticache" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure every security group and rule has a description">
Resource: module.database.aws_security_group.elasticache
File: /modules/database/main.tf: 52-67
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/networking-31

		52 | resource &quot;aws_security_group&quot; &quot;elasticache&quot; {
		53 |   name_prefix = &quot;${local.name_prefix}-elasticache-&quot;
		54 |   description = &quot;Allow Redis access from Lambda&quot;
		55 |   vpc_id      = var.vpc_id
		56 | 
		57 |   ingress {
		58 |     from_port       = 6379
		59 |     to_port         = 6379
		60 |     protocol        = &quot;tcp&quot;
		61 |     security_groups = [var.lambda_security_group_id]
		62 |   }
		63 | 
		64 |   tags = {
		65 |     Name = &quot;${local.name_prefix}-elasticache-sg&quot;
		66 |   }
		67 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_31] Ensure all data stored in the ElastiCache Replication Group is securely encrypted at transit and has auth token" classname="/modules/database/main.tf.module.database.aws_elasticache_replication_group.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure all data stored in the ElastiCache Replication Group is securely encrypted at transit and has auth token">
Resource: module.database.aws_elasticache_replication_group.main
File: /modules/database/main.tf: 69-85
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/general-11

		69 | resource &quot;aws_elasticache_replication_group&quot; &quot;main&quot; {
		70 |   replication_group_id       = &quot;${local.name_prefix}-redis&quot;
		71 |   description                = &quot;Redis cache&quot;
		72 |   engine                     = &quot;redis&quot;
		73 |   engine_version             = &quot;7.1&quot;
		74 |   node_type                  = &quot;cache.t3.micro&quot;
		75 |   port                       = 6379
		76 |   num_cache_clusters         = 1
		77 |   automatic_failover_enabled = false
		78 |   multi_az_enabled           = false
		79 |   subnet_group_name          = aws_elasticache_subnet_group.main.name
		80 |   security_group_ids         = [aws_security_group.elasticache.id]
		81 | 
		82 |   tags = {
		83 |     Name = &quot;${local.name_prefix}-redis&quot;
		84 |   }
		85 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_30] Ensure all data stored in the ElastiCache Replication Group is securely encrypted at transit" classname="/modules/database/main.tf.module.database.aws_elasticache_replication_group.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure all data stored in the ElastiCache Replication Group is securely encrypted at transit">
Resource: module.database.aws_elasticache_replication_group.main
File: /modules/database/main.tf: 69-85
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/general-10

		69 | resource &quot;aws_elasticache_replication_group&quot; &quot;main&quot; {
		70 |   replication_group_id       = &quot;${local.name_prefix}-redis&quot;
		71 |   description                = &quot;Redis cache&quot;
		72 |   engine                     = &quot;redis&quot;
		73 |   engine_version             = &quot;7.1&quot;
		74 |   node_type                  = &quot;cache.t3.micro&quot;
		75 |   port                       = 6379
		76 |   num_cache_clusters         = 1
		77 |   automatic_failover_enabled = false
		78 |   multi_az_enabled           = false
		79 |   subnet_group_name          = aws_elasticache_subnet_group.main.name
		80 |   security_group_ids         = [aws_security_group.elasticache.id]
		81 | 
		82 |   tags = {
		83 |     Name = &quot;${local.name_prefix}-redis&quot;
		84 |   }
		85 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_29] Ensure all data stored in the ElastiCache Replication Group is securely encrypted at rest" classname="/modules/database/main.tf.module.database.aws_elasticache_replication_group.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure all data stored in the ElastiCache Replication Group is securely encrypted at rest">
Resource: module.database.aws_elasticache_replication_group.main
File: /modules/database/main.tf: 69-85
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/general-9

		69 | resource &quot;aws_elasticache_replication_group&quot; &quot;main&quot; {
		70 |   replication_group_id       = &quot;${local.name_prefix}-redis&quot;
		71 |   description                = &quot;Redis cache&quot;
		72 |   engine                     = &quot;redis&quot;
		73 |   engine_version             = &quot;7.1&quot;
		74 |   node_type                  = &quot;cache.t3.micro&quot;
		75 |   port                       = 6379
		76 |   num_cache_clusters         = 1
		77 |   automatic_failover_enabled = false
		78 |   multi_az_enabled           = false
		79 |   subnet_group_name          = aws_elasticache_subnet_group.main.name
		80 |   security_group_ids         = [aws_security_group.elasticache.id]
		81 | 
		82 |   tags = {
		83 |     Name = &quot;${local.name_prefix}-redis&quot;
		84 |   }
		85 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_191] Ensure ElastiCache replication group is encrypted by KMS using a customer managed Key (CMK)" classname="/modules/database/main.tf.module.database.aws_elasticache_replication_group.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure ElastiCache replication group is encrypted by KMS using a customer managed Key (CMK)">
Resource: module.database.aws_elasticache_replication_group.main
File: /modules/database/main.tf: 69-85
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-general-111

		69 | resource &quot;aws_elasticache_replication_group&quot; &quot;main&quot; {
		70 |   replication_group_id       = &quot;${local.name_prefix}-redis&quot;
		71 |   description                = &quot;Redis cache&quot;
		72 |   engine                     = &quot;redis&quot;
		73 |   engine_version             = &quot;7.1&quot;
		74 |   node_type                  = &quot;cache.t3.micro&quot;
		75 |   port                       = 6379
		76 |   num_cache_clusters         = 1
		77 |   automatic_failover_enabled = false
		78 |   multi_az_enabled           = false
		79 |   subnet_group_name          = aws_elasticache_subnet_group.main.name
		80 |   security_group_ids         = [aws_security_group.elasticache.id]
		81 | 
		82 |   tags = {
		83 |     Name = &quot;${local.name_prefix}-redis&quot;
		84 |   }
		85 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_118] Ensure that enhanced monitoring is enabled for Amazon RDS instances" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure that enhanced monitoring is enabled for Amazon RDS instances">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/ensure-that-enhanced-monitoring-is-enabled-for-amazon-rds-instances

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_157] Ensure that RDS instances have Multi-AZ enabled" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure that RDS instances have Multi-AZ enabled">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/general-73

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_293] Ensure that AWS database instances have deletion protection enabled" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure that AWS database instances have deletion protection enabled">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-293

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_226] Ensure DB instance gets all minor upgrades automatically" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure DB instance gets all minor upgrades automatically">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-aws-db-instance-gets-all-minor-upgrades-automatically

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_161] Ensure RDS database has IAM authentication enabled" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure RDS database has IAM authentication enabled">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-iam-policies/ensure-rds-database-has-iam-authentication-enabled

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_353] Ensure that RDS instances have performance insights enabled" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure that RDS instances have performance insights enabled">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-353

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_68] CloudFront Distribution should have WAF enabled" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="CloudFront Distribution should have WAF enabled">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-general-27

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_310] Ensure CloudFront distributions should have origin failover configured" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure CloudFront distributions should have origin failover configured">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-310

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_86] Ensure CloudFront distribution has Access Logging enabled" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure CloudFront distribution has Access Logging enabled">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/logging-20

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_174] Verify CloudFront Distribution Viewer Certificate is using TLS v1.2 or higher" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Verify CloudFront Distribution Viewer Certificate is using TLS v1.2 or higher">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/bc-aws-networking-63

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_374] Ensure AWS CloudFront web distribution has geo restriction enabled" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure AWS CloudFront web distribution has geo restriction enabled">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/bc-aws-374

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_27] Ensure all data stored in the SQS queue is encrypted" classname="/modules/messaging/main.tf.module.messaging.aws_sqs_queue.vote_queue" file="/modules/messaging/main.tf">
			<failure type="failure" message="Ensure all data stored in the SQS queue is encrypted">
Resource: module.messaging.aws_sqs_queue.vote_queue
File: /modules/messaging/main.tf: 9-18
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/general-16-encrypt-sqs-queue

		9  | resource &quot;aws_sqs_queue&quot; &quot;vote_queue&quot; {
		10 |   name                       = &quot;${local.name_prefix}-vote-queue&quot;
		11 |   visibility_timeout_seconds = 30
		12 |   message_retention_seconds  = 1209600
		13 | 
		14 |   redrive_policy = jsonencode({
		15 |     deadLetterTargetArn = aws_sqs_queue.dlq.arn
		16 |     maxReceiveCount     = 3
		17 |   })
		18 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_27] Ensure all data stored in the SQS queue is encrypted" classname="/modules/messaging/main.tf.module.messaging.aws_sqs_queue.dlq" file="/modules/messaging/main.tf">
			<failure type="failure" message="Ensure all data stored in the SQS queue is encrypted">
Resource: module.messaging.aws_sqs_queue.dlq
File: /modules/messaging/main.tf: 20-22
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/general-16-encrypt-sqs-queue

		20 | resource &quot;aws_sqs_queue&quot; &quot;dlq&quot; {
		21 |   name = &quot;${local.name_prefix}-vote-dlq&quot;
		22 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_158] Ensure that CloudWatch Log Group is encrypted by KMS" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_acceso" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure that CloudWatch Log Group is encrypted by KMS">
Resource: module.monitoring.aws_cloudwatch_log_group.lambda_acceso
File: /modules/monitoring/main.tf: 9-16
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-cloudwatch-log-group-is-encrypted-by-kms

		9  | resource &quot;aws_cloudwatch_log_group&quot; &quot;lambda_acceso&quot; {
		10 |   name              = &quot;/aws/lambda/${local.name_prefix}-acceso&quot;
		11 |   retention_in_days = 7
		12 | 
		13 |   tags = {
		14 |     Environment = var.env
		15 |   }
		16 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_338] Ensure CloudWatch log groups retains logs for at least 1 year" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_acceso" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure CloudWatch log groups retains logs for at least 1 year">
Resource: module.monitoring.aws_cloudwatch_log_group.lambda_acceso
File: /modules/monitoring/main.tf: 9-16
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-338

		9  | resource &quot;aws_cloudwatch_log_group&quot; &quot;lambda_acceso&quot; {
		10 |   name              = &quot;/aws/lambda/${local.name_prefix}-acceso&quot;
		11 |   retention_in_days = 7
		12 | 
		13 |   tags = {
		14 |     Environment = var.env
		15 |   }
		16 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_158] Ensure that CloudWatch Log Group is encrypted by KMS" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_despachador" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure that CloudWatch Log Group is encrypted by KMS">
Resource: module.monitoring.aws_cloudwatch_log_group.lambda_despachador
File: /modules/monitoring/main.tf: 18-25
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-cloudwatch-log-group-is-encrypted-by-kms

		18 | resource &quot;aws_cloudwatch_log_group&quot; &quot;lambda_despachador&quot; {
		19 |   name              = &quot;/aws/lambda/${local.name_prefix}-despachador&quot;
		20 |   retention_in_days = 7
		21 | 
		22 |   tags = {
		23 |     Environment = var.env
		24 |   }
		25 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_338] Ensure CloudWatch log groups retains logs for at least 1 year" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_despachador" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure CloudWatch log groups retains logs for at least 1 year">
Resource: module.monitoring.aws_cloudwatch_log_group.lambda_despachador
File: /modules/monitoring/main.tf: 18-25
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-338

		18 | resource &quot;aws_cloudwatch_log_group&quot; &quot;lambda_despachador&quot; {
		19 |   name              = &quot;/aws/lambda/${local.name_prefix}-despachador&quot;
		20 |   retention_in_days = 7
		21 | 
		22 |   tags = {
		23 |     Environment = var.env
		24 |   }
		25 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_158] Ensure that CloudWatch Log Group is encrypted by KMS" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_procesador" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure that CloudWatch Log Group is encrypted by KMS">
Resource: module.monitoring.aws_cloudwatch_log_group.lambda_procesador
File: /modules/monitoring/main.tf: 27-34
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-cloudwatch-log-group-is-encrypted-by-kms

		27 | resource &quot;aws_cloudwatch_log_group&quot; &quot;lambda_procesador&quot; {
		28 |   name              = &quot;/aws/lambda/${local.name_prefix}-procesador&quot;
		29 |   retention_in_days = 7
		30 | 
		31 |   tags = {
		32 |     Environment = var.env
		33 |   }
		34 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_338] Ensure CloudWatch log groups retains logs for at least 1 year" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.lambda_procesador" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure CloudWatch log groups retains logs for at least 1 year">
Resource: module.monitoring.aws_cloudwatch_log_group.lambda_procesador
File: /modules/monitoring/main.tf: 27-34
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-338

		27 | resource &quot;aws_cloudwatch_log_group&quot; &quot;lambda_procesador&quot; {
		28 |   name              = &quot;/aws/lambda/${local.name_prefix}-procesador&quot;
		29 |   retention_in_days = 7
		30 | 
		31 |   tags = {
		32 |     Environment = var.env
		33 |   }
		34 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_158] Ensure that CloudWatch Log Group is encrypted by KMS" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.ecs_blockchain" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure that CloudWatch Log Group is encrypted by KMS">
Resource: module.monitoring.aws_cloudwatch_log_group.ecs_blockchain
File: /modules/monitoring/main.tf: 36-43
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-cloudwatch-log-group-is-encrypted-by-kms

		36 | resource &quot;aws_cloudwatch_log_group&quot; &quot;ecs_blockchain&quot; {
		37 |   name              = &quot;/ecs/${local.name_prefix}-blockchain&quot;
		38 |   retention_in_days = 7
		39 | 
		40 |   tags = {
		41 |     Environment = var.env
		42 |   }
		43 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_338] Ensure CloudWatch log groups retains logs for at least 1 year" classname="/modules/monitoring/main.tf.module.monitoring.aws_cloudwatch_log_group.ecs_blockchain" file="/modules/monitoring/main.tf">
			<failure type="failure" message="Ensure CloudWatch log groups retains logs for at least 1 year">
Resource: module.monitoring.aws_cloudwatch_log_group.ecs_blockchain
File: /modules/monitoring/main.tf: 36-43
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-338

		36 | resource &quot;aws_cloudwatch_log_group&quot; &quot;ecs_blockchain&quot; {
		37 |   name              = &quot;/ecs/${local.name_prefix}-blockchain&quot;
		38 |   retention_in_days = 7
		39 | 
		40 |   tags = {
		41 |     Environment = var.env
		42 |   }
		43 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.public[&quot;us-east-1a&quot;]" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure VPC subnets do not assign public IP by default">
Resource: module.networking.aws_subnet.public[&quot;us-east-1a&quot;]
File: /modules/networking/main.tf: 35-42
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/ensure-vpc-subnets-do-not-assign-public-ip-by-default

		35 | resource &quot;aws_subnet&quot; &quot;public&quot; {
		36 |   for_each                = toset(var.azs)
		37 |   vpc_id                  = aws_vpc.main.id
		38 |   cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2)
		39 |   availability_zone       = each.key
		40 |   map_public_ip_on_launch = true
		41 |   tags                    = { Name = &quot;${local.name_prefix}-public-${each.key}&quot; }
		42 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_382] Ensure no security groups allow egress from 0.0.0.0:0 to port -1" classname="/modules/networking/main.tf.module.networking.aws_security_group.lambda" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure no security groups allow egress from 0.0.0.0:0 to port -1">
Resource: module.networking.aws_security_group.lambda
File: /modules/networking/main.tf: 68-79
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/bc-aws-382

		68 | resource &quot;aws_security_group&quot; &quot;lambda&quot; {
		69 |   name        = &quot;${local.name_prefix}-lambda-sg&quot;
		70 |   description = &quot;Security group for Lambda&quot;
		71 |   vpc_id      = aws_vpc.main.id
		72 |   egress {
		73 |     from_port   = 0
		74 |     to_port     = 0
		75 |     protocol    = &quot;-1&quot;
		76 |     cidr_blocks = [&quot;0.0.0.0/0&quot;]
		77 |   }
		78 |   tags = { Name = &quot;${local.name_prefix}-lambda-sg&quot; }
		79 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_23] Ensure every security group and rule has a description" classname="/modules/networking/main.tf.module.networking.aws_security_group.lambda" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure every security group and rule has a description">
Resource: module.networking.aws_security_group.lambda
File: /modules/networking/main.tf: 68-79
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/networking-31

		68 | resource &quot;aws_security_group&quot; &quot;lambda&quot; {
		69 |   name        = &quot;${local.name_prefix}-lambda-sg&quot;
		70 |   description = &quot;Security group for Lambda&quot;
		71 |   vpc_id      = aws_vpc.main.id
		72 |   egress {
		73 |     from_port   = 0
		74 |     to_port     = 0
		75 |     protocol    = &quot;-1&quot;
		76 |     cidr_blocks = [&quot;0.0.0.0/0&quot;]
		77 |   }
		78 |   tags = { Name = &quot;${local.name_prefix}-lambda-sg&quot; }
		79 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_382] Ensure no security groups allow egress from 0.0.0.0:0 to port -1" classname="/modules/networking/main.tf.module.networking.aws_security_group.database" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure no security groups allow egress from 0.0.0.0:0 to port -1">
Resource: module.networking.aws_security_group.database
File: /modules/networking/main.tf: 81-98
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/bc-aws-382

		81 | resource &quot;aws_security_group&quot; &quot;database&quot; {
		82 |   name        = &quot;${local.name_prefix}-database-sg&quot;
		83 |   description = &quot;Security group for Aurora&quot;
		84 |   vpc_id      = aws_vpc.main.id
		85 |   ingress {
		86 |     from_port       = 5432
		87 |     to_port         = 5432
		88 |     protocol        = &quot;tcp&quot;
		89 |     security_groups = [aws_security_group.lambda.id]
		90 |   }
		91 |   egress {
		92 |     from_port   = 0
		93 |     to_port     = 0
		94 |     protocol    = &quot;-1&quot;
		95 |     cidr_blocks = [&quot;0.0.0.0/0&quot;]
		96 |   }
		97 |   tags = { Name = &quot;${local.name_prefix}-database-sg&quot; }
		98 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_23] Ensure every security group and rule has a description" classname="/modules/networking/main.tf.module.networking.aws_security_group.database" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure every security group and rule has a description">
Resource: module.networking.aws_security_group.database
File: /modules/networking/main.tf: 81-98
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/networking-31

		81 | resource &quot;aws_security_group&quot; &quot;database&quot; {
		82 |   name        = &quot;${local.name_prefix}-database-sg&quot;
		83 |   description = &quot;Security group for Aurora&quot;
		84 |   vpc_id      = aws_vpc.main.id
		85 |   ingress {
		86 |     from_port       = 5432
		87 |     to_port         = 5432
		88 |     protocol        = &quot;tcp&quot;
		89 |     security_groups = [aws_security_group.lambda.id]
		90 |   }
		91 |   egress {
		92 |     from_port   = 0
		93 |     to_port     = 0
		94 |     protocol    = &quot;-1&quot;
		95 |     cidr_blocks = [&quot;0.0.0.0/0&quot;]
		96 |   }
		97 |   tags = { Name = &quot;${local.name_prefix}-database-sg&quot; }
		98 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_130] Ensure VPC subnets do not assign public IP by default" classname="/modules/networking/main.tf.module.networking.aws_subnet.public[&quot;us-east-1b&quot;]" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure VPC subnets do not assign public IP by default">
Resource: module.networking.aws_subnet.public[&quot;us-east-1b&quot;]
File: /modules/networking/main.tf: 35-42
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/ensure-vpc-subnets-do-not-assign-public-ip-by-default

		35 | resource &quot;aws_subnet&quot; &quot;public&quot; {
		36 |   for_each                = toset(var.azs)
		37 |   vpc_id                  = aws_vpc.main.id
		38 |   cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(var.azs, each.key) * 2)
		39 |   availability_zone       = each.key
		40 |   map_public_ip_on_launch = true
		41 |   tags                    = { Name = &quot;${local.name_prefix}-public-${each.key}&quot; }
		42 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_12] Ensure the default security group of every VPC restricts all traffic" classname="/modules/networking/main.tf.module.networking.aws_vpc.main" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure the default security group of every VPC restricts all traffic">
Resource: module.networking.aws_vpc.main
File: /modules/networking/main.tf: 10-15
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/networking-4

		10 | resource &quot;aws_vpc&quot; &quot;main&quot; {
		11 |   cidr_block           = var.vpc_cidr
		12 |   enable_dns_support   = true
		13 |   enable_dns_hostnames = true
		14 |   tags                 = { Name = &quot;${local.name_prefix}-vpc&quot; }
		15 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_5] Ensure that Security Groups are attached to another resource" classname="/modules/networking/main.tf.module.networking.aws_security_group.lambda" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure that Security Groups are attached to another resource">
Resource: module.networking.aws_security_group.lambda
File: /modules/networking/main.tf: 68-79
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/ensure-that-security-groups-are-attached-to-ec2-instances-or-elastic-network-interfaces-enis

		68 | resource &quot;aws_security_group&quot; &quot;lambda&quot; {
		69 |   name        = &quot;${local.name_prefix}-lambda-sg&quot;
		70 |   description = &quot;Security group for Lambda&quot;
		71 |   vpc_id      = aws_vpc.main.id
		72 |   egress {
		73 |     from_port   = 0
		74 |     to_port     = 0
		75 |     protocol    = &quot;-1&quot;
		76 |     cidr_blocks = [&quot;0.0.0.0/0&quot;]
		77 |   }
		78 |   tags = { Name = &quot;${local.name_prefix}-lambda-sg&quot; }
		79 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_5] Ensure that Security Groups are attached to another resource" classname="/modules/networking/main.tf.module.networking.aws_security_group.database" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure that Security Groups are attached to another resource">
Resource: module.networking.aws_security_group.database
File: /modules/networking/main.tf: 81-98
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/ensure-that-security-groups-are-attached-to-ec2-instances-or-elastic-network-interfaces-enis

		81 | resource &quot;aws_security_group&quot; &quot;database&quot; {
		82 |   name        = &quot;${local.name_prefix}-database-sg&quot;
		83 |   description = &quot;Security group for Aurora&quot;
		84 |   vpc_id      = aws_vpc.main.id
		85 |   ingress {
		86 |     from_port       = 5432
		87 |     to_port         = 5432
		88 |     protocol        = &quot;tcp&quot;
		89 |     security_groups = [aws_security_group.lambda.id]
		90 |   }
		91 |   egress {
		92 |     from_port   = 0
		93 |     to_port     = 0
		94 |     protocol    = &quot;-1&quot;
		95 |     cidr_blocks = [&quot;0.0.0.0/0&quot;]
		96 |   }
		97 |   tags = { Name = &quot;${local.name_prefix}-database-sg&quot; }
		98 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_42] Ensure AWS CloudFront distribution uses custom SSL certificate" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure AWS CloudFront distribution uses custom SSL certificate">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/ensure-aws-cloudfront-distribution-uses-custom-ssl-certificate

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_144] Ensure that S3 bucket has cross-region replication enabled" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure that S3 bucket has cross-region replication enabled">
Resource: module.frontend.aws_s3_bucket.frontend
File: /modules/frontend/main.tf: 12-14
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-s3-bucket-has-cross-region-replication-enabled

		12 | resource &quot;aws_s3_bucket&quot; &quot;frontend&quot; {
		13 |   bucket = &quot;${local.name_prefix}-frontend&quot;
		14 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_47] Ensure AWS CloudFront attached WAFv2 WebACL is configured with AMR for Log4j Vulnerability" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure AWS CloudFront attached WAFv2 WebACL is configured with AMR for Log4j Vulnerability">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-general-47

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_60] Ensure RDS instance with copy tags to snapshots is enabled" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure RDS instance with copy tags to snapshots is enabled">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-2-60

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_18] Ensure the S3 bucket has access logging enabled" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure the S3 bucket has access logging enabled">
Resource: module.frontend.aws_s3_bucket.frontend
File: /modules/frontend/main.tf: 12-14
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/s3-policies/s3-13-enable-logging

		12 | resource &quot;aws_s3_bucket&quot; &quot;frontend&quot; {
		13 |   bucket = &quot;${local.name_prefix}-frontend&quot;
		14 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_61] Ensure that an S3 bucket has a lifecycle configuration" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure that an S3 bucket has a lifecycle configuration">
Resource: module.frontend.aws_s3_bucket.frontend
File: /modules/frontend/main.tf: 12-14
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-2-61

		12 | resource &quot;aws_s3_bucket&quot; &quot;frontend&quot; {
		13 |   bucket = &quot;${local.name_prefix}-frontend&quot;
		14 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_11] Ensure VPC flow logging is enabled in all VPCs" classname="/modules/networking/main.tf.module.networking.aws_vpc.main" file="/modules/networking/main.tf">
			<failure type="failure" message="Ensure VPC flow logging is enabled in all VPCs">
Resource: module.networking.aws_vpc.main
File: /modules/networking/main.tf: 10-15
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/logging-9-enable-vpc-flow-logging

		10 | resource &quot;aws_vpc&quot; &quot;main&quot; {
		11 |   cidr_block           = var.vpc_cidr
		12 |   enable_dns_support   = true
		13 |   enable_dns_hostnames = true
		14 |   tags                 = { Name = &quot;${local.name_prefix}-vpc&quot; }
		15 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_57] Ensure Secrets Manager secrets should have automatic rotation enabled" classname="/modules/security/main.tf.module.security.aws_secretsmanager_secret.db_credentials" file="/modules/security/main.tf">
			<failure type="failure" message="Ensure Secrets Manager secrets should have automatic rotation enabled">
Resource: module.security.aws_secretsmanager_secret.db_credentials
File: /modules/security/main.tf: 57-65
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-2-57

		57 | resource &quot;aws_secretsmanager_secret&quot; &quot;db_credentials&quot; {
		58 |   name        = &quot;${local.name_prefix}/db/credentials&quot;
		59 |   description = &quot;DB credentials&quot;
		60 |   kms_key_id  = aws_kms_key.main.arn
		61 | 
		62 |   lifecycle {
		63 |     ignore_changes = all
		64 |   }
		65 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_57] Ensure Secrets Manager secrets should have automatic rotation enabled" classname="/modules/security/main.tf.module.security.aws_secretsmanager_secret.redis_auth_token" file="/modules/security/main.tf">
			<failure type="failure" message="Ensure Secrets Manager secrets should have automatic rotation enabled">
Resource: module.security.aws_secretsmanager_secret.redis_auth_token
File: /modules/security/main.tf: 77-85
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/bc-aws-2-57

		77 | resource &quot;aws_secretsmanager_secret&quot; &quot;redis_auth_token&quot; {
		78 |   name        = &quot;${local.name_prefix}/redis/auth-token&quot;
		79 |   description = &quot;Redis auth token&quot;
		80 |   kms_key_id  = aws_kms_key.main.arn
		81 | 
		82 |   lifecycle {
		83 |     ignore_changes = all
		84 |   }
		85 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_32] Ensure CloudFront distribution has a response headers policy attached" classname="/modules/frontend/main.tf.module.frontend.aws_cloudfront_distribution.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure CloudFront distribution has a response headers policy attached">
Resource: module.frontend.aws_cloudfront_distribution.frontend
File: /modules/frontend/main.tf: 77-119
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/bc-aws-networking-65

		77  | resource &quot;aws_cloudfront_distribution&quot; &quot;frontend&quot; {
		78  |   enabled             = true
		79  |   is_ipv6_enabled     = true
		80  |   comment             = &quot;Frontend for ${local.name_prefix}&quot;
		81  |   default_root_object = &quot;index.html&quot;
		82  | 
		83  |   default_cache_behavior {
		84  |     allowed_methods  = [&quot;GET&quot;, &quot;HEAD&quot;, &quot;OPTIONS&quot;]
		85  |     cached_methods   = [&quot;GET&quot;, &quot;HEAD&quot;]
		86  |     target_origin_id = &quot;s3-origin&quot;
		87  | 
		88  |     forwarded_values {
		89  |       query_string = false
		90  |       cookies {
		91  |         forward = &quot;none&quot;
		92  |       }
		93  |     }
		94  | 
		95  |     viewer_protocol_policy = &quot;redirect-to-https&quot;
		96  |     min_ttl                = 0
		97  |     default_ttl            = 3600
		98  |     max_ttl                = 86400
		99  |   }
		100 | 
		101 |   restrictions {
		102 |     geo_restriction {
		103 |       restriction_type = &quot;none&quot;
		104 |     }
		105 |   }
		106 | 
		107 |   viewer_certificate {
		108 |     cloudfront_default_certificate = true
		109 |   }
		110 | 
		111 |   origin {
		112 |     domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
		113 |     origin_id   = &quot;s3-origin&quot;
		114 | 
		115 |     s3_origin_config {
		116 |       origin_access_identity = &quot;origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.frontend.id}&quot;
		117 |     }
		118 |   }
		119 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV_AWS_145] Ensure that S3 buckets are encrypted with KMS by default" classname="/modules/frontend/main.tf.module.frontend.aws_s3_bucket.frontend" file="/modules/frontend/main.tf">
			<failure type="failure" message="Ensure that S3 buckets are encrypted with KMS by default">
Resource: module.frontend.aws_s3_bucket.frontend
File: /modules/frontend/main.tf: 12-14
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-s3-buckets-are-encrypted-with-kms-by-default

		12 | resource &quot;aws_s3_bucket&quot; &quot;frontend&quot; {
		13 |   bucket = &quot;${local.name_prefix}-frontend&quot;
		14 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_30] Ensure Postgres RDS as aws_db_instance has Query Logging enabled" classname="/modules/database/main.tf.module.database.aws_db_instance.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure Postgres RDS as aws_db_instance has Query Logging enabled">
Resource: module.database.aws_db_instance.main
File: /modules/database/main.tf: 100-121
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-postgres-rds-has-query-logging-enabled

		100 | resource &quot;aws_db_instance&quot; &quot;main&quot; {
		101 |   identifier             = &quot;${local.name_prefix}-postgres&quot;
		102 |   engine                 = &quot;postgres&quot;
		103 |   engine_version         = &quot;15.7&quot;
		104 |   instance_class         = &quot;db.t3.micro&quot;
		105 |   allocated_storage      = 20
		106 |   db_name                = &quot;truetally&quot;
		107 |   username               = var.db_username
		108 |   password               = var.db_password
		109 |   db_subnet_group_name   = aws_db_subnet_group.main.name
		110 |   vpc_security_group_ids = [var.lambda_security_group_id]
		111 |   storage_encrypted      = true
		112 |   kms_key_id             = var.kms_key_arn
		113 |   skip_final_snapshot    = true
		114 |   publicly_accessible    = false
		115 | 
		116 |   enabled_cloudwatch_logs_exports = [&quot;postgresql&quot;, &quot;upgrade&quot;]
		117 | 
		118 |   tags = {
		119 |     Name = &quot;${local.name_prefix}-postgres&quot;
		120 |   }
		121 | }
</failure>
		</testcase>
		<testcase name="[NONE][CKV2_AWS_50] Ensure AWS ElastiCache Redis cluster with Multi-AZ Automatic Failover feature set to enabled" classname="/modules/database/main.tf.module.database.aws_elasticache_replication_group.main" file="/modules/database/main.tf">
			<failure type="failure" message="Ensure AWS ElastiCache Redis cluster with Multi-AZ Automatic Failover feature set to enabled">
Resource: module.database.aws_elasticache_replication_group.main
File: /modules/database/main.tf: 69-85
Guideline: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-aws-elasticache-redis-cluster-with-multi-az-automatic-failover-feature-set-to-enabled

		69 | resource &quot;aws_elasticache_replication_group&quot; &quot;main&quot; {
		70 |   replication_group_id       = &quot;${local.name_prefix}-redis&quot;
		71 |   description                = &quot;Redis cache&quot;
		72 |   engine                     = &quot;redis&quot;
		73 |   engine_version             = &quot;7.1&quot;
		74 |   node_type                  = &quot;cache.t3.micro&quot;
		75 |   port                       = 6379
		76 |   num_cache_clusters         = 1
		77 |   automatic_failover_enabled = false
		78 |   multi_az_enabled           = false
		79 |   subnet_group_name          = aws_elasticache_subnet_group.main.name
		80 |   security_group_ids         = [aws_security_group.elasticache.id]
		81 | 
		82 |   tags = {
		83 |     Name = &quot;${local.name_prefix}-redis&quot;
		84 |   }
		85 | }
</failure>
		</testcase>
	</testsuite>
</testsuites>