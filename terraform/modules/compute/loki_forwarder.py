import base64
import gzip
import json
import os
import urllib.request

LOKI_URL = os.environ.get(
    "LOKI_URL", "http://loki.dev.truetally.internal:3100/loki/api/v1/push"
)


def lambda_handler(event, context):
    raw = event.get("awslogs", {}).get("data")
    if not raw:
        return {"status": "skipped", "reason": "no awslogs data"}

    try:
        payload = json.loads(gzip.decompress(base64.b64decode(raw)))
    except Exception as e:
        print("LOKI_FORWARDER_ERROR decode_failed error=%s" % e)
        return {"status": "error", "reason": "decode_failed", "error": str(e)}

    log_group = payload.get("logGroup", "unknown")
    function = log_group.split("/")[-1] or log_group

    if log_group.startswith("/aws/lambda/"):
        job = "lambda"
    elif "blockchain" in log_group:
        job = "blockchain"
    else:
        job = "app"

    values = []
    skipped = 0
    for entry in payload.get("logEvents", []):
        message = entry.get("message", "")
        if not message.strip():
            skipped += 1
            continue
        ts_ns = str(int(entry["timestamp"]) * 1_000_000)
        values.append([ts_ns, message])

    if not values:
        return {"status": "ok", "count": 0, "skipped_empty": skipped}

    body = {
        "streams": [
            {
                "stream": {
                    "job": job,
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
            return {
                "status": response.status,
                "count": len(values),
                "skipped_empty": skipped,
                "log_group": log_group,
                "job": job,
            }
    except Exception as err:
        print(
            "LOKI_FORWARDER_ERROR url=%s error=%s log_group=%s job=%s count=%d"
            % (LOKI_URL, err, log_group, job, len(values))
        )
        return {
            "status": "error",
            "count": len(values),
            "skipped_empty": skipped,
            "log_group": log_group,
            "job": job,
            "error": str(err),
        }
