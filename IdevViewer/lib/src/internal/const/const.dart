const String FORMULA = ('''
## 작성 예시
  이름: 총점
    > 띄어 쓰기 가능

  입력>필드: f1,f2,f3,f4,f5
    > 반드시, 필드명과 동일(대.소문자 구분함)

  출력>연산식:
    > 함수명은 대.소문자 구분 없음
    > 필드명은 필드명과 동일(대.소문자 구분함)
    > 띄어 쓰기, 줄바꿈 가능
    > 괄호 사용 대신 연산 함수로 변경 작성
    > f1 + f2 - f3 * f4 / f5
    > f1^2 + ADD(f1, MUL(f1, f2))
    > SQRT(f4) + f5^2 + ADD(f1, f2)
    > AVG(f2, f3, f4, f5) / 5 + POWER(f1, f2)
    > MUL(f1, DIVI(f1, f2)) - DIVI(f1, f2)

## 산술 연산자
| 연산자 | 설명 | 예시 |
| --- | --- | --- |
| + | 더하기 | f2 + f3 |
| - | 빼기 | f5 - f2 |
| \* | 곱하기 | f4 * f5 |
| /| 나누기 | f1 / f2 |
| ^| 멱승 | f2 ^ 3|

## 연산 함수
| 함수 | 설명 | 예시 |
| --- | --- | --- |
| ADD | 더하기 | ADD(f2, f3) |
| SUB | 빼기| SUB(f5, f2) |
| MUL | 곱하기 | MUL(f4, f5) |
| DIVI | 나누기 | DIVI(f1, f2) |
| POWER | 멱승 | POWER(f2, f3) |
| AVG | 평균 | AVG(f2, f3, f4) |
| SQRT | 루트 | SQRT(f4) |
| CEIL | ~보다 작거나 같은 최대 정수 | CEIL(f1) |
| FLOOR | ~보다 크거나 같은 최소 정수 | FLOOR(f1) |
| ROUND | 반올림 | ROUND(f4) |
| ABS | 절대값 | ABS(f5) |
| EXP | e멱승 | EXP(f2) |
| LOG | e로그 | LOG(f1) |
| SIN | Sine | SIN(f1) |
| ASIN | Arcsine | ASIN(f1) |
| COS | Cosine | COS(f1) |
| ACOS | Arccosine | ACOS(f1) |
| TAN | Tangent | TAN(f1) |
| ATAN | Arctangent | ATAN(f1) |

## 비교 연산자
| 연산자 | 설명 | 예시 |
| --- | --- | --- |
| == | 같다 | f2 == f3 |
| != | 같지 않다 | f5 != f2 |
| <| ~보다 작다 | f4 < f5|
| >| ~보다 크다 | f1 > f2|
| <= | 작거나 같다 | f2 <= f3 |
| >= | 크거나 같다 | f5 >= f2 |

또는 아래와 같이 사용 가능:
| 함수 | 설명 | 예시 |
| --- | --- | --- |
| EQ | 같다| EQ(f2, f3) |
| NE | 같지 않다 | NE(f2, f3) |
| LT | ~보다 작다 | LT(f2, f3) |
| GT | ~보다 크다 | GT(f2, f3) |
| GTE | 작거나 같다 | LTE(f2, f3) |
| LTE | 크거나 같다 | GTE(f2, f3) |
''');