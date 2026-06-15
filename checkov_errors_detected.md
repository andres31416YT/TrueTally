Run bridgecrewio/checkov-action@master
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