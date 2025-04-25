#!/bin/bash

# # 1. 스크립트 파일의 권한 변경하기
chmod +x delete-node-modules.sh
# ------------------------------------------------
# 권한 변경이 제대로 되었는지 확인하기
ls -la delete-node-modules.sh
# ------------------------------------------------
# 2. 스크립트 실행하기 (현재 디렉토리에서 검색)
#./delete-node-modules.sh
# ------------------------------------------------
# 또는 특정 디렉토리에서 검색 시작하기
# ./delete-node-modules.sh /path/to/your/directory


# 시작 디렉토리 설정 (현재 디렉토리를 기본값으로 사용)
START_DIR="${1:-.}"

echo "시작 디렉토리: $START_DIR"
echo "모든 node_modules 폴더를 찾는 중..."

# node_modules 폴더 찾기
FOUND_DIRS=$(find "$START_DIR" -type d -name "node_modules" -not -path "*/\.*")

# 찾은 디렉토리 수 계산
COUNT=$(echo "$FOUND_DIRS" | grep -c "node_modules")

if [ $COUNT -eq 0 ]; then
  echo "node_modules 폴더를 찾지 못했습니다."
  exit 0
fi

echo "총 $COUNT 개의 node_modules 폴더를 찾았습니다:"
echo "$FOUND_DIRS" | sed 's/^/- /'

# 삭제 확인
read -p "이 폴더들을 모두 삭제하시겠습니까? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "작업을 취소했습니다."
  exit 0
fi

# 삭제 진행
echo "node_modules 폴더를 삭제하는 중..."
echo "$FOUND_DIRS" | xargs rm -rf

echo "삭제 완료!"
echo "총 $COUNT 개의 node_modules 폴더를 삭제했습니다."

