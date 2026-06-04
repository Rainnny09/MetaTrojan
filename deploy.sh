#!/bin/bash

echo "=== Cloud Run Deploy with Auto-Delete ==="

read -p "Service name [trojan-cr]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-trojan-cr}

# Time Limit Menu
echo ""
echo "Select configuration duration limit:"
echo "1) 5 Minutes (Testing)"
echo "2) 5 Hours"
echo "3) 10 Hours"
read -p "Choose an option [1-3]: " TIME_OPTION

NOW=$(date +%s)
case $TIME_OPTION in
    1)
        DURATION_TEXT="5m"
        VALID_SECONDS=300
        TASK_DELAY="5m"
        ;;
    2)
        DURATION_TEXT="5h"
        VALID_SECONDS=18000
        TASK_DELAY="5h"
        ;;
    3)
        DURATION_TEXT="10h"
        VALID_SECONDS=36000
        TASK_DELAY="10h"
        ;;
    *)
        echo "Invalid option. Defaulting to 5 minutes testing."
        DURATION_TEXT="5m"
        VALID_SECONDS=300
        TASK_DELAY="5m"
        ;;
esac

EXPIRY_TIMESTAMP=$((NOW + VALID_SECONDS))
EXPIRY_DATE=$(date -d "@$EXPIRY_TIMESTAMP" +"%Y-%m-%d %H:%M:%S")

# Fixed token (no timestamp/duration suffix)
UNIQUE_TOKEN="raen_xlx"

# Create the temporary config file
cat <<EOF > config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 8080,
      "listen": "0.0.0.0",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${UNIQUE_TOKEN}"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/${UNIQUE_TOKEN}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

REGION="asia-southeast1"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "Error: No active project found in gcloud config."
  exit 1
fi

# Create Cloud Tasks queue if needed
QUEUE_NAME="ttl-cleanup-queue"
gcloud tasks queues create $QUEUE_NAME --location=$REGION 2>/dev/null || true

echo "Deploying $SERVICE_NAME to $REGION ($DURATION_TEXT limit)..."

# Deploy to Cloud Run
gcloud run deploy $SERVICE_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --cpu 1 \
  --max-instances 1 \
  --timeout 3600

URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format='value(status.url)')

DOMAIN=$(echo "$URL" | sed 's|https://||')

# Schedule auto-delete
echo "Scheduling automatic service deletion in $DURATION_TEXT..."

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')

SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud tasks create-http-task \
  --queue=$QUEUE_NAME \
  --location=$REGION \
  --url="https://${REGION}-run.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/services/${SERVICE_NAME}" \
  --method="DELETE" \
  --schedule-time="+${TASK_DELAY}" \
  --oauth-service-account-email=$SERVICE_ACCOUNT

echo ""
echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "Service: $SERVICE_NAME"
echo "Expires At: $EXPIRY_DATE"
echo "Google Cloud Tasks will completely wipe this service when the timer hits zero."
echo ""
echo "Trojan Link:"
echo "trojan://${UNIQUE_TOKEN}@firebase-settings.crashlytics.com:443?security=tls&type=ws&path=%2F${UNIQUE_TOKEN}&sni=cares.paymaya.com&host=${DOMAIN}#${SERVICE_NAME}"
