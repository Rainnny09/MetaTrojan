#!/bin/bash

# --- Color Definitions ---
COLOR_RESET="\033[0m"
COLOR_HEADER="\033[1;36m"  # Bold Cyan
COLOR_SUCCESS="\033[1;32m" # Bold Green
COLOR_ERROR="\033[1;31m"   # Bold Red
COLOR_INFO="\033[0;34m"    # Blue
COLOR_LABEL="\033[1;33m"   # Bold Yellow

echo -e "${COLOR_HEADER}=====================================${COLOR_RESET}"
echo -e "${COLOR_HEADER}         CLOUD RUN DEPLOY            ${COLOR_RESET}"
echo -e "${COLOR_HEADER}=====================================${COLOR_RESET}"
echo ""

read -p "Service name [trojan-sts]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-trojan-sts}

# Set region directly to Singapore
REGION="asia-southeast1"

# Automatically fetch the active project ID from gcloud config
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo -e "\n${COLOR_ERROR}Error: No active project found in gcloud config.${COLOR_RESET}"
  echo "Please run 'gcloud auth login' and 'gcloud config set project YOUR_PROJECT_ID' first."
  exit 1
fi

echo -e "\n${COLOR_INFO}[->] Active Project ID:${COLOR_RESET} $PROJECT_ID"
echo -e "${COLOR_INFO}[->] Deploying Configuration:${COLOR_RESET} $SERVICE_NAME to $REGION (1Gi Mem / 1 CPU)"
echo ""

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
echo -e "${COLOR_SUCCESS}=====================================${COLOR_RESET}"
echo -e "${COLOR_SUCCESS}          DEPLOYMENT DONE            ${COLOR_RESET}"
echo -e "${COLOR_SUCCESS}=====================================${COLOR_RESET}"
echo ""
echo -e "${COLOR_LABEL}Service:${COLOR_RESET} $SERVICE_NAME"
echo -e "${COLOR_LABEL}Region:${COLOR_RESET}  $REGION"
echo -e "${COLOR_LABEL}URL:${COLOR_RESET}     $URL"
echo ""
echo -e "${COLOR_SUCCESS}Trojan Link:${COLOR_RESET}"
echo "trojan://raen_xlx@firebase-settings.crashlytics.com:443?security=tls&type=ws&path=%2Fraen_xlx&sni=cares.paymaya.com&host=$DOMAIN#$SERVICE_NAME"
echo ""
