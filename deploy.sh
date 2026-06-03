gcloud run deploy trojan-cr \
  --source . \
  --platform managed \
  --region asia-southeast1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 256Mi \
  --timeout 3600