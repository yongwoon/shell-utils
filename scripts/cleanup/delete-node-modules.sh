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

# 삭제 대상 폴더 목록
TARGET_DIRS=("node_modules" ".next" ".astro" "dist" ".pnpm-store")

# 시작 디렉토리 설정 (현재 디렉토리를 기본값으로 사용)
START_DIR="${1:-.}"

echo "시작 디렉토리: $START_DIR"
echo "삭제 대상 폴더: ${TARGET_DIRS[*]}"
echo ""
echo "폴더를 찾는 중..."

# 모든 대상 폴더 찾기
FOUND_DIRS=""
for TARGET in "${TARGET_DIRS[@]}"; do
  DIRS=$(find "$START_DIR" -type d -name "$TARGET" -not -path "*/\.*/$TARGET" 2>/dev/null)
  if [ -n "$DIRS" ]; then
    FOUND_DIRS="$FOUND_DIRS$DIRS"$'\n'
  fi
done

# 빈 줄 제거
FOUND_DIRS=$(echo "$FOUND_DIRS" | sed '/^$/d')

# 찾은 디렉토리 수 계산
if [ -z "$FOUND_DIRS" ]; then
  echo "삭제할 폴더를 찾지 못했습니다."
  exit 0
fi

COUNT=$(echo "$FOUND_DIRS" | wc -l | tr -d ' ')

echo ""
echo "총 $COUNT 개의 폴더를 찾았습니다:"
echo "$FOUND_DIRS" | sed 's/^/- /'

# 삭제 확인
echo ""
read -p "이 폴더들을 모두 삭제하시겠습니까? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "작업을 취소했습니다."
  exit 0
fi

# 삭제 진행
echo ""
echo "폴더를 삭제하는 중..."
echo "$FOUND_DIRS" | xargs rm -rf

echo "삭제 완료!"
echo "총 $COUNT 개의 폴더를 삭제했습니다."

