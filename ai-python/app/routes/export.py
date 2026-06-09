from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
from playwright.async_api import async_playwright
import traceback

router = APIRouter()

class ExportRequest(BaseModel):
    diagram_code: str
    diagram_name: str = "diagram"

@router.post("/export/png")
async def export_png(body: ExportRequest):
    try:
        html = f"""<!DOCTYPE html><html><head>
<script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
<style>
* {{margin:0;padding:0;box-sizing:border-box;}}
body {{background:#0D1B2A;padding:40px;}}
.mermaid svg {{display:block;max-width:none !important;}}
</style>
</head><body>
<div id="diagram" class="mermaid">{body.diagram_code}</div>
<script>
mermaid.initialize({{startOnLoad:false,theme:'dark',securityLevel:'loose'}});
async function render() {{
    document.getElementById('diagram').textContent = `{body.diagram_code}`;
    await mermaid.run();
}}
render();
</script>
</body></html>"""

        async with async_playwright() as p:
            browser = await p.chromium.launch(args=['--no-sandbox', '--disable-setuid-sandbox'])
            page = await browser.new_page(viewport={{"width": 2400, "height": 6000}}, device_scale_factor=2)
            await page.set_content(html)
            await page.wait_for_selector('#diagram svg', timeout=15000)
            await page.wait_for_timeout(2000)

            real_size = await page.evaluate("""() => {
                const svg = document.querySelector('#diagram svg');
                if (!svg) return {width: 1200, height: 800};
                const bbox = svg.getBBox();
                return {
                    width: Math.ceil(bbox.width) + 80,
                    height: Math.ceil(bbox.height) + 80,
                };
            }""")

            w = max(int(real_size['width']), 800)
            h = max(int(real_size['height']), 400)

            await page.set_viewport_size({'width': w, 'height': h})
            await page.wait_for_timeout(500)

            screenshot = await page.screenshot(full_page=True, scale='device')
            await browser.close()

        return Response(content=screenshot, media_type="image/png")
    except Exception as e:
        print(f"❌ EXPORT ERROR: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))