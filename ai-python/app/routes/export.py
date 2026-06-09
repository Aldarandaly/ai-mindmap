from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
import subprocess
import tempfile
import os

router = APIRouter()

class ExportRequest(BaseModel):
    diagram_code: str
    diagram_name: str = "diagram"

@router.post("/export/png")
async def export_png(body: ExportRequest):
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            input_file = os.path.join(tmpdir, "diagram.mmd")
            output_file = os.path.join(tmpdir, "diagram.png")
            config_file = os.path.join(tmpdir, "config.json")

            with open(input_file, 'w') as f:
                f.write(body.diagram_code)

            import json
            config = {
                "theme": "dark",
                "background": "#0D1B2A",
                "themeVariables": {
                    "primaryColor": "#6C63FF",
                    "primaryTextColor": "#ffffff",
                    "lineColor": "#00D4FF",
                    "secondaryColor": "#1A1828"
                }
            }
            with open(config_file, 'w') as f:
                json.dump(config, f)

            result = subprocess.run(
                [
                    '/usr/local/bin/mmdc',
                    '-i', input_file,
                    '-o', output_file,
                    '-c', config_file,
                    '-w', '2000',
                    '-s', '2',
                    '--quiet'
                ],
            capture_output=True,
            text=True,
            timeout=60
        )

            print(f"mmdc stdout: {result.stdout}")
            print(f"mmdc stderr: {result.stderr}")
            print(f"mmdc returncode: {result.returncode}")

            if result.returncode != 0:
                raise Exception(f"mmdc error: {result.stderr}")

            if not os.path.exists(output_file):
                raise Exception("Output file not created")

            with open(output_file, 'rb') as f:
                png_bytes = f.read()

        return Response(content=png_bytes, media_type="image/png")
    except Exception as e:
        print(f"❌ EXPORT ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))