def detect_type(text: str) -> str:
    text_lower = text.lower()

    erd_keywords = ["table", "database", "foreign key", "primary key",
                    "one to many", "many to many", "column", "row",
                    "entity", "relation", "stores", "references"]

    class_keywords = ["class", "inherit", "extends", "method", "function",
                      "object", "attribute", "interface", "polymorphism",
                      "instance", "property", "constructor"]

    mindmap_keywords = ["concept", "idea", "topic", "branch", "category",
                        "overview", "summary", "plan", "mind map", "outline"]

    usecase_keywords = ["actor", "use case", "user can", "admin can",
                        "system allows", "feature", "login", "register",
                        "manage", "perform", "access", "interact"]

    erd_score = sum(1 for kw in erd_keywords if kw in text_lower)
    class_score = sum(1 for kw in class_keywords if kw in text_lower)
    mindmap_score = sum(1 for kw in mindmap_keywords if kw in text_lower)
    usecase_score = sum(1 for kw in usecase_keywords if kw in text_lower)

    scores = {
        "erd": erd_score,
        "class": class_score,
        "mindmap": mindmap_score,
        "usecase": usecase_score
    }
    best = max(scores, key=scores.get)

    return best if scores[best] > 0 else "class"