from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
from playwright.async_api import async_playwright

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
body {{background:#0D1B2A;display:flex;justify-content:center;align-items:flex-start;padding:40px;min-height:100vh;}}
.mermaid {{width:100%;}}
.mermaid svg {{width:100% !important;height:auto !important;max-width:none !important;}}
</style>
</head><body>
<div class="mermaid" id="diagram">{body.diagram_code}</div>
<script>
mermaid.initialize({{
    startOnLoad: false,
    theme: 'dark',
    securityLevel: 'loose',
    er: {{diagramPadding: 30}},
    flowchart: {{padding: 30}},
    sequence: {{diagramMarginX: 30, diagramMarginY: 30}},
}});
async function render() {{
    const el = document.getElementById('diagram');
    el.textContent = `{body.diagram_code}`;
    await mermaid.run();
}}
render();
</script>
</body></html>"""

        async with async_playwright() as p:
            browser = await p.chromium.launch(args=['--no-sandbox'])
            page = await browser.new_page(viewport={{"width": 2000, "height": 1200}}, device_scale_factor=2)
            await page.set_content(html)
            await page.wait_for_timeout(4000)

            await page.wait_for_selector('.mermaid svg', timeout=10000)
 
            svg_box = await page.evaluate("""() => {
                const svg = document.querySelector('.mermaid svg');
                if (!svg) return null;
                const rect = svg.getBoundingClientRect();
                return {x: rect.x, y: rect.y, width: rect.width, height: rect.height};
            }""")

            if svg_box and svg_box['width'] > 0:
                padding = 40
                screenshot = await page.screenshot(
                    clip={{
                        'x': max(0, svg_box['x'] - padding),
                        'y': max(0, svg_box['y'] - padding),
                        'width': svg_box['width'] + padding * 2,
                        'height': svg_box['height'] + padding * 2,
                    }},
                    scale='device'
                )
            else:
                screenshot = await page.screenshot(full_page=True, scale='device')

            await browser.close()

        return Response(content=screenshot, media_type="image/png")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))