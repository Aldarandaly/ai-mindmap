def get_dfd_prompt(text: str) -> str:
    return f"""
Analyze the text below following these steps to create a perfect Mermaid.js DATA FLOW DIAGRAM (DFD):

STEP 1: Identify all external entities (sources and destinations of data).
STEP 2: Identify all processes that transform data.
STEP 3: Identify all data stores (databases, files).
STEP 4: Determine the data flows between entities, processes, and stores.
STEP 5: Output ONLY the final Mermaid code.

Rules for Output:
- Start with 'flowchart TD'.
- External entities as rectangles: Entity[Entity Name]
- Processes as rounded rectangles: Process([Process Name])
- Data stores as cylinders: Store[(Store Name)]
- Data flows as arrows with labels: A -->|data name| B
- No explanations or extra text.

Text to Analyze:
{text}
"""