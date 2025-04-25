# delete-tmp-cache.sh

임시 캐시 디렉토리(`tmp/cache` 패턴)를 찾아 삭제하는 스크립트입니다.

## 위치

```bash
scripts/cleanup/delete-tmp-cache.sh
```

## 동작 순서

```bash
1. 시작 디렉토리 설정 (인자 또는 현재 디렉토리)
2. tmp/cache 패턴의 폴더 검색
3. 찾은 폴더 목록 및 용량 정보 표시
4. 사용자에게 삭제 확인 요청
5. 삭제 방식 선택 (폴더 내용만 삭제 또는 폴더 자체 삭제)
6. 선택된 방식으로 삭제 진행
```

## 주요 기능

- 임시 캐시 파일로 인한 디스크 공간 낭비 방지
- 삭제 방식 선택 가능 (내용물만 삭제 또는 폴더 자체 삭제)
- 삭제 전 용량 정보 표시로 효과 예측 가능
- 여러 개발 환경의 캐시 디렉토리 일괄 처리

## 사용 방법

```bash
# 권한 부여
chmod +x scripts/cleanup/delete-tmp-cache.sh

# 현재 디렉토리에서 검색 시작
./scripts/cleanup/delete-tmp-cache.sh

# 특정 디렉토리에서 검색 시작
./scripts/cleanup/delete-tmp-cache.sh /path/to/directory
```
