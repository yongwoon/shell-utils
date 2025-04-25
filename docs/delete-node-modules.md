# delete-node-modules.sh

Node.js 프로젝트의 `node_modules` 폴더를 찾아 삭제하는 스크립트입니다.

## 위치

```bash
scripts/cleanup/delete-node-modules.sh
```

## 동작 순서

```bash
1. 시작 디렉토리 설정 (인자 또는 현재 디렉토리)
2. node_modules 폴더 검색
3. 찾은 폴더 목록 및 개수 표시
4. 사용자에게 삭제 확인 요청
5. 확인 시 모든 폴더 삭제
```

## 주요 기능

- 디스크 공간 확보를 위한 불필요한 `node_modules` 폴더 정리
- 특정 디렉토리부터 시작하여 모든 하위 디렉토리 검색
- 목록 확인 후 사용자의 확인을 받고 삭제 진행

## 사용 방법

```bash
# 권한 부여
chmod +x scripts/cleanup/delete-node-modules.sh

# 현재 디렉토리에서 검색 시작
./scripts/cleanup/delete-node-modules.sh

# 특정 디렉토리에서 검색 시작
./scripts/cleanup/delete-node-modules.sh /path/to/directory
```
