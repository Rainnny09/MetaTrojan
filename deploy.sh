#!/bin/bash

echo "=== Cloud Run Deploy ==="

read -p "Service name [trojan-cr]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-trojan-cr}

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
echo "Deploying $SERVICE_NAME sa $REGION with 1Gi mem + 1 CPU..."

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

URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')
DOMAIN=$(echo $URL | sed 's|https://||')

echo ""
echo "=== DONE ==="
echo "Service: $SERVICE_NAME"
echo "Region: $REGION"
echo "URL: $URL"
echo ""
echo "Trojan Link:"
echo "trojan://raen_xlx@firebase-settings.crashlytics.com:443?security=tls&type=ws&path=%2Fraen_xlx&sni=cares.paymaya.com&host=$DOMAIN#$SERVICE_NAME"
