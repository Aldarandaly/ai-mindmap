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

    activity_keywords = ["flow", "process", "step", "activity", "action",
                         "decision", "workflow", "procedure", "sequence of",
                         "start", "end", "if", "then", "else", "loop"]

    sequence_keywords = ["request", "response", "call", "send", "receive",
                         "message", "interaction", "communication", "api",
                         "service", "client", "server", "protocol"]

    context_keywords = ["system", "external", "boundary", "context",
                        "input", "output", "data flow", "interface",
                        "environment", "subsystem", "component"]

    state_keywords = ["state", "status", "transition", "pending", "processing",
                      "done", "failed", "active", "inactive", "cancelled",
                      "expired", "completed", "idle", "running"]

    dfd_keywords = ["data flow", "data store", "process", "external entity",
                    "dataflow", "dfd", "level 0", "level 1", "transform",
                    "data movement", "data source", "data sink"]

    gantt_keywords = ["schedule", "timeline", "milestone", "deadline", "sprint",
                      "phase", "task duration", "start date", "end date",
                      "project plan", "gantt", "week", "month", "days"]

    scores = {
        "erd":      sum(1 for kw in erd_keywords      if kw in text_lower),
        "class":    sum(1 for kw in class_keywords    if kw in text_lower),
        "mindmap":  sum(1 for kw in mindmap_keywords  if kw in text_lower),
        "usecase":  sum(1 for kw in usecase_keywords  if kw in text_lower),
        "activity": sum(1 for kw in activity_keywords if kw in text_lower),
        "sequence": sum(1 for kw in sequence_keywords if kw in text_lower),
        "context":  sum(1 for kw in context_keywords  if kw in text_lower),
        "state":    sum(1 for kw in state_keywords    if kw in text_lower),
        "dfd":      sum(1 for kw in dfd_keywords      if kw in text_lower),
        "gantt":    sum(1 for kw in gantt_keywords    if kw in text_lower),
    }

    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else "class"