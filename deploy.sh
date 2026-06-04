#!/bin/bash

echo "=== Cloud Run Deploy ==="

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
        ;;
    2)
        DURATION_TEXT="5h"
        VALID_SECONDS=18000
        ;;
    3)
        DURATION_TEXT="10h"
        VALID_SECONDS=36000
        ;;
    *)
        echo "Invalid option. Defaulting to 5 minutes testing."
        DURATION_TEXT="5m"
        VALID_SECONDS=300
        ;;
esac

# Calculate precise expiration timestamp
EXPIRY_TIMESTAMP=$((NOW + VALID_SECONDS))
EXPIRY_DATE=$(date -d "@$EXPIRY_TIMESTAMP" +"%Y-%m-%d %H:%M:%S")

# Generate a unique path/password identifier containing the expiration string
# Example: raen_xlx_5m_1717523554
UNIQUE_TOKEN="raen_xlx_${DURATION_TEXT}_${EXPIRY_TIMESTAMP}"

# Create a temporary config file injecting our unique dynamic token
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

# Set region directly to Singapore
REGION="asia-southeast1"

# Automatically fetch the active project ID from gcloud config
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "Error: No active project found in gcloud config."
  echo "Please run 'gcloud auth login' and 'gcloud config set project YOUR_PROJECT_ID' first."
  exit 1
fi

echo "Using active Project ID: $PROJECT_ID"
echo "Deploying $SERVICE_NAME to $REGION ($DURATION_TEXT limit, 1Gi mem + 1 CPU)..."

# Label the Cloud Run instance with its expiry timestamp so you know when to delete it
gcloud run deploy $SERVICE_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --cpu 1 \
  --max-instances 1 \
  --timeout 3600 \
  --update-labels="expires-at=${EXPIRY_TIMESTAMP}"

URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')
DOMAIN=$(echo $URL | sed 's|https://||')

echo ""
echo "=== DONE ==="
echo "Service: $SERVICE_NAME"
echo "Region: $REGION"
echo "URL: $URL"
echo "Created At: $(date +"%Y-%m-%d %H:%M:%S")"
echo "Expires At: $EXPIRY_DATE"
echo ""
echo "Trojan Link:"
echo "trojan://${UNIQUE_TOKEN}@firebase-settings.crashlytics.com:443?security=tls&type=ws&path=%2F${UNIQUE_TOKEN}&sni=cares.paymaya.com&host=$DOMAIN#$SERVICE_NAME"
