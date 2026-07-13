import base64
import gzip
import json
import os
import urllib.request

LOKI_URL = os.environ.get(
    "LOKI_URL", "http://loki.dev.truetally.internal:3100/loki/api/v1/push"
)


def lambda_handler(event, context):
    """Forward CloudWatch Logs subscription events to Loki.

    Each invocation receives one CloudWatch Logs batch. We transform the
    log events into the Loki push format and POST them to the Loki HTTP
    push API. Labeled with job=lambda and the originating function name so
    the logs are queryable in Grafana with {job="lambda"}.
    """
    raw = event.get("awslogs", {}).get("data")
    if not raw:
        return {"status": "skipped", "reason": "no awslogs data"}

    payload = json.loads(gzip.decompress(base64.b64decode(raw)))

    log_group = payload.get("logGroup", "unknown")
    # /aws/lambda/truetally-dev-acceso -> truetally-dev-acceso
    function = log_group.split("/")[-1] or log_group

    values = []
    for entry in payload.get("logEvents", []):
        # Loki requires nanosecond-precision timestamps.
        ts_ns = str(int(entry["timestamp"]) * 1_000_000)
        values.append([ts_ns, entry.get("message", "")])

    if not values:
        return {"status": "ok", "count": 0}

    body = {
        "streams": [
            {
                "stream": {
                    "job": "lambda",
                    "function": function,
                    "log_group": log_group,
                },
                "values": values,
            }
        ]
    }

    data = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(
        LOKI_URL,
        data=data,
        method="POST",
        headers={"Content-Type": "application/json"},
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return {"status": response.status, "count": len(values)}
    except Exception as err:  # best-effort: logs remain in CloudWatch
        print("LOKI_FORWARDER_ERROR url=%s error=%s" % (LOKI_URL, err))
        return {"status": "error", "count": len(values)}
