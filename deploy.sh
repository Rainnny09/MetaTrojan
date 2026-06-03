#!/bin/bash

echo "=== Cloud Run Deploy ==="

read -p "Service name [trojan-cr]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-trojan-cr}

echo "Regions: 1=SG asia-southeast1 | 2=Iowa us-central1"
read -p "Pili region [2]: " REGION_CHOICE
REGION_CHOICE=${REGION_CHOICE:-2}

if [ "$REGION_CHOICE" = "1" ]; then
  REGION="asia-southeast1"
else
  REGION="us-central1"
fi

read -p "Project ID: " PROJECT_ID

gcloud config set project $PROJECT_ID

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
echo "trojan://PALITAN_PASSWORD@$DOMAIN:443?security=tls&type=ws&path=%2Fchat&sni=$DOMAIN#$SERVICE_NAME"
```

**Run mo:**
```bash
chmod +x deploy.sh
./deploy.sh
