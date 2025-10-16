#!/bin/bash

# IDev Viewer NPM 배포 자동화 스크립트
# 사용법: ./scripts/npm-deploy.sh

set -e

echo "🚀 IDev Viewer NPM 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# NPM 패키지 배포
print_step "NPM 패키지 배포 시작..."
cd idev-viewer-js

# 현재 버전 확인
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo "현재 버전: $CURRENT_VERSION"

read -p "배포를 진행하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if npm publish --access public; then
        print_success "NPM 패키지 배포 완료!"
        echo "📦 패키지 URL: https://www.npmjs.com/package/idev-viewer"
    else
        print_error "NPM 패키지 배포 실패"
        exit 1
    fi
else
    print_warning "배포가 취소되었습니다"
fi
cd .. # 원래 디렉토리로 돌아가기

# 완료 메시지
print_success "✨ 모든 작업이 완료되었습니다!"
