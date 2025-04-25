#!/bin/bash

# 권한 부여
# chmod +x delete-vendor-bundle.sh
#
# 현재 디렉토리에서 검색 시작
# ./delete-vendor-bundle.sh
#
# 특정 디렉토리에서 검색 시작
# ./delete-vendor-bundle.sh /path/to/directory


# 시작 디렉토리 설정 (현재 디렉토리를 기본값으로 사용)
START_DIR="${1:-.}"

echo "시작 디렉토리: $START_DIR"
echo "모든 vendor/bundle 폴더를 찾는 중..."

# vendor/bundle 패턴의 폴더 찾기
FOUND_DIRS=$(find "$START_DIR" -type d -path "*/vendor/bundle" -not -path "*/\.*")

# 찾은 디렉토리 수 계산
COUNT=$(echo "$FOUND_DIRS" | grep -c "vendor/bundle" || echo 0)

if [ $COUNT -eq 0 ]; then
  echo "vendor/bundle 폴더를 찾지 못했습니다."
  exit 0
fi

echo "총 $COUNT 개의 vendor/bundle 폴더를 찾았습니다:"
echo "$FOUND_DIRS" | sed 's/^/- /'

# 용량 정보 표시 (옵션)
echo "각 폴더의 용량 정보:"
for DIR in $FOUND_DIRS; do
  SIZE=$(du -sh "$DIR" | cut -f1)
  echo "- $DIR: $SIZE"
done

# 삭제 확인
read -p "이 폴더들을 모두 삭제하시겠습니까? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "작업을 취소했습니다."
  exit 0
fi

# 삭제 진행
echo "vendor/bundle 폴더를 삭제하는 중..."
for DIR in $FOUND_DIRS; do
  echo "삭제 중: $DIR"
  rm -rf "$DIR"
  echo "완료: $DIR"
done

echo "삭제 완료!"
echo "총 $COUNT 개의 vendor/bundle 폴더를 삭제했습니다."

