from langchain.prompts import PromptTemplate
from langchain.llms import OpenAI

def text_to_json_node(state):
    # StackTableItem, TableItemContent의 JSON 스키마 정의
    schema = '''
    StackTableItem: {
      "boardId": string,
      "id": string,
      "angle": double,
      "size": {"width": double, "height": double},
      "offset": {"dx": double, "dy": double},
      "padding": double,
      "status": int,  // StackItemStatus enum index
      "lockZOrder": bool,
      "dock": bool,
      "permission": string,
      "content": TableItemContent
    }
    TableItemContent: {
      "columnGap": double,
      "rowGap": double,
      "gapColor": string,
      "areas": string,
      "columnSizes": string,
      "rowSizes": string,
      "reqApis": string,
      "resApis": string
    }
    '''
    # 예제 JSON
    examples = '''
    예시1: 인사관리 테이블 위젯
    {
      "boardId": "board-001",
      "id": "item-123",
      "angle": 0.0,
      "size": {"width": 400.0, "height": 300.0},
      "offset": {"dx": 100.0, "dy": 200.0},
      "padding": 8.0,
      "status": 1,
      "lockZOrder": false,
      "dock": false,
      "permission": "admin",
      "content": {
        "columnGap": 8.0,
        "rowGap": 4.0,
        "gapColor": "#EEEEEE",
        "areas": "header body footer",
        "columnSizes": "100,200,100",
        "rowSizes": "40,200,60",
        "reqApis": "/api/hr/list",
        "resApis": "/api/hr/response"
      }
    }
    '''
    prompt = PromptTemplate(
        template="""
아래는 Flutter 위젯 StackTableItem, TableItemContent의 JSON 스키마와 예제입니다.\n
{schema}\n
예제:\n{examples}\n
---\n
아래 사용자 요청에 맞는 StackTableItem JSON을 생성하세요.\n
사용자 요청: {query}\n
생성할 JSON:
""",
        input_variables=["query"]
    )
    llm = OpenAI()
    # state에 schema, examples를 추가
    state["schema"] = schema
    state["examples"] = examples
    json_str = llm(prompt.format(query=state["query"], schema=schema, examples=examples))
    state["generated_json"] = json_str
    return state 