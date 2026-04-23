def basic_validate_mermaid(code: str) -> bool:
    if not code:
        return False

    valid_starts = ["classDiagram", "erDiagram", "mindmap", "flowchart", "graph"]

    if not any(code.strip().startswith(start) for start in valid_starts):
        return False

    if len(code.splitlines()) < 2:
        return False

    return True


def advanced_validate_mermaid(code: str, diagram_type: str) -> bool:
    if diagram_type == "class":
        return "classDiagram" in code and ("--" in code or "<|" in code)

    if diagram_type == "erd":
        return "erDiagram" in code and ("||" in code or "}|" in code)

    if diagram_type == "mindmap":
        return "mindmap" in code and len(code.splitlines()) > 2

    return True