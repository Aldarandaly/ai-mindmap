def get_dfd_prompt(text: str) -> str:
    return f"""
You are an expert software architect. Create a professional Mermaid.js Data Flow Diagram (DFD Level 1).
Output ONLY valid Mermaid code. No explanation. No markdown. No code blocks.

STRICT SYNTAX RULES:
- Start with: flowchart TD
- External entities: E1[Entity Name]
- Processes: P1([Process Name])
- Data stores: DS1[(Data Store Name)]
- Data flows: A -->|data name| B
- All arrows MUST have data labels

CORRECT EXAMPLE:
flowchart TD
    Student[Student]
    Teacher[Teacher]
    Admin[Admin]

    P1([1.0 Register Student])
    P2([2.0 Manage Courses])
    P3([3.0 Submit Assignment])
    P4([4.0 Grade Assignment])
    P5([5.0 Generate Report])

    DS1[(Student Records)]
    DS2[(Course Database)]
    DS3[(Assignment Store)]

    Student -->|registration form| P1
    P1 -->|student data| DS1
    DS1 -->|student info| P1
    P1 -->|confirmation| Student

    Teacher -->|course details| P2
    P2 -->|course data| DS2
    DS2 -->|course list| P2
    P2 -->|course schedule| Teacher

    Student -->|assignment file| P3
    P3 -->|stored assignment| DS3
    Teacher -->|grade & feedback| P4
    DS3 -->|assignment data| P4
    P4 -->|graded result| DS3
    P4 -->|grade notification| Student

    Admin -->|report request| P5
    DS1 -->|student records| P5
    DS2 -->|course data| P5
    DS3 -->|assignment data| P5
    P5 -->|report| Admin

RULES:
- Number all processes (1.0, 2.0, etc.)
- External entities as rectangles
- Processes as rounded rectangles
- Data stores as cylinders
- ALL arrows must have data flow labels
- Show both input and output flows
- Max 5 processes, 3 data stores, 4 entities

Text:
{text}
"""