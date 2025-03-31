# 실행 권한 부여: chmod +x pull_all.sh
# 실행: ./pull_all.sh

#!/bin/bash

# 현재 디렉토리와 1단계, 2단계 하위 디렉토리 처리 함수
process_git_repository() {
    local current_path=$1
    echo -e "\n📂 Processing directory: $current_path"

    # Git 저장소인지 확인
    if [ ! -d "$current_path/.git" ]; then
        echo "⚠️  Not a git repository, skipping..."
        return
    fi

    cd "$current_path" || return

    # 현재 상태 확인
    echo "📊 Checking repository status..."
    git status -s

    # stash 적용 (작업 중인 변경사항 있는 경우)
    if [[ -n $(git status -s) ]]; then
        echo "💾 Stashing changes..."
        git stash
    fi

    # 원격 브랜치 정보 업데이트
    echo "🔄 Fetching remote information..."
    git fetch --all --prune

    # 원격에서 삭제된 브랜치 정리
    echo "🧹 Pruning deleted remote branches..."
    git remote prune origin

    for branch in "main" "master" "develop"; do
        if git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
            echo "⬇️  Checking out and resetting $branch branch..."
            git checkout $branch
            git fetch origin $branch
            git reset --hard origin/$branch
            echo "✅ Reset $branch to origin/$branch"
        else
            echo "ℹ️  Branch $branch does not exist in this repository"
        fi
    done

    # stash 복원 (있는 경우)
    if git stash list | grep -q "stash@{0}"; then
        echo "♻️  Restoring stashed changes..."
        git stash pop
    fi

    # 불필요한 파일 정리
    echo "🧹 Cleaning unnecessary files..."
    git gc --prune=now

    echo "✅ Completed processing $(pwd)"
    echo "-------------------------"
}

# 시작 디렉토리 저장
start_dir=$PWD

# 현재 디렉토리 처리
process_git_repository "$start_dir"

# 1단계 하위 디렉토리 처리
for d in "$start_dir"/*/; do
    if [ -d "$d" ]; then
        process_git_repository "$d"

        # 2단계 하위 디렉토리 처리
        for subd in "$d"/*/; do
            if [ -d "$subd" ]; then
                process_git_repository "$subd"
            fi
        done
    fi
done

# 시작 디렉토리로 복귀
cd "$start_dir" || exit
