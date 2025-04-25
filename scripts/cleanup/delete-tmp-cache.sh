# 실행 권한을 부여
# chmod +x delete-tmp-cache.sh
# --------------------------------------------------
# 현재 디렉토리에서 검색
# ./delete-tmp-cache.sh
# 특정 디렉토리에서 검색
# ./delete-tmp-cache.sh /path/to/directory
# -------------------------------------------------

#!/bin/bash

# 시작 디렉토리 설정 (현재 디렉토리를 기본값으로 사용)
START_DIR="${1:-.}"

echo "시작 디렉토리: $START_DIR"
echo "모든 tmp/cache 폴더를 찾는 중..."

# tmp/cache 패턴의 폴더 찾기
FOUND_DIRS=$(find "$START_DIR" -type d -path "*/tmp/cache" -not -path "*/\.*")

# 찾은 디렉토리 수 계산
COUNT=$(echo "$FOUND_DIRS" | grep -c "tmp/cache" || echo 0)

if [ $COUNT -eq 0 ]; then
  echo "tmp/cache 폴더를 찾지 못했습니다."
  exit 0
fi

echo "총 $COUNT 개의 tmp/cache 폴더를 찾았습니다:"
echo "$FOUND_DIRS" | sed 's/^/- /'

# 용량 정보 표시
echo "각 폴더의 용량 정보:"
for DIR in $FOUND_DIRS; do
  SIZE=$(du -sh "$DIR" | cut -f1)
  echo "- $DIR: $SIZE"
done

# 전체 용량 계산
TOTAL_SIZE=$(du -sh $(echo "$FOUND_DIRS") 2>/dev/null | awk '{sum+=$1} END {print sum}')
echo "모든 tmp/cache 폴더의 총 용량: 약 $TOTAL_SIZE"

# 삭제 확인
read -p "이 폴더들의 내용을 모두 삭제하시겠습니까? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "작업을 취소했습니다."
  exit 0
fi

# 삭제 방식 선택
echo "삭제 방식을 선택하세요:"
echo "1) 폴더 내용만 삭제 (폴더 구조는 유지)"
echo "2) 폴더 자체를 삭제"
read -p "선택 (1 또는 2): " DELETE_OPTION

# 삭제 진행
echo "삭제를 시작합니다..."
success_count=0

for DIR in $FOUND_DIRS; do
  echo "처리 중: $DIR"
  
  if [ "$DELETE_OPTION" = "1" ]; then
    # 폴더 내용만 삭제
    rm -rf "$DIR"/* "$DIR"/.[!.]* 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "  완료: 폴더 내용을 삭제했습니다."
      ((success_count++))
    else
      echo "  경고: 일부 파일을 삭제하지 못했습니다. 권한을 확인하세요."
    fi
  else
    # 폴더 자체를 삭제
    rm -rf "$DIR"
    if [ $? -eq 0 ]; then
      echo "  완료: 폴더를 삭제했습니다."
      ((success_count++))
    else
      echo "  경고: 폴더를 삭제하지 못했습니다. 권한을 확인하세요."
    fi
  fi
done

echo "작업 완료!"
echo "총 $COUNT 개의 tmp/cache 폴더 중 $success_count 개를 성공적으로 처리했습니다."


