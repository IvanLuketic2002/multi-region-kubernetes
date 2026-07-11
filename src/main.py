from fastapi import FastAPI
import httpx
import os

app = FastAPI(title="Multi-Region Global Platform")

@app.get("/")
async def read_root():
    # Pitamo AWS meta-data servis u kom se regionu nalazi ovaj server
    region = "Unknown Region"
    try:
        async with httpx.AsyncClient(timeout=1.0) as client:
            token_response = await client.put(
                "http://169.254.169.254/latest/api/token", 
                headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"}
            )
            if token_response.status_code == 200:
                token = token_response.text
                region_response = await client.get(
                    "http://169.254.169.254/latest/meta-data/placement/region",
                    headers={"X-aws-ec2-metadata-token": token}
                )
                if region_response.status_code == 200:
                    region = region_response.text
    except Exception:
        region = os.getenv("AWS_REGION", "Local/Docker Development")

    return {
        "status": "online",
        "message": "Dobrodošli na našu visoko-dostupnu multi-region platformu!",
        "aws_region": region,
        "environment": "production"
    }
