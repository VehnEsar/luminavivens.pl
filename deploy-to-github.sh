#!/bin/bash

# =============================================================================
# SKRYPT DEPLOYMENTU LUMINA VIVENS NA GITHUB PAGES
# =============================================================================
# Instrukcja użycia:
# 1. Upewnij się, że masz konto na GitHub (https://github.com/signup)
# 2. Utwórz token dostępu: GitHub → Settings → Developer settings → 
#    Personal access tokens → Tokens (classic) → Generate new token
#    Zaznacz uprawnienia: repo, workflow
# 3. Uruchom skrypt: bash deploy-to-github.sh
# =============================================================================

set -e  # Zatrzymaj przy błędzie

echo "=========================================="
echo "  LUMINA VIVENS - DEPLOYMENT NA GITHUB"
echo "=========================================="
echo ""

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Sprawdź czy git jest zainstalowany
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git nie jest zainstalowany!${NC}"
    echo "Zainstaluj git: https://git-scm.com/downloads"
    exit 1
fi

echo -e "${GREEN}✓ Git znaleziony${NC}"

# Pobierz dane od użytkownika
echo ""
echo -e "${BLUE}Podaj nazwę użytkownika GitHub:${NC}"
read -r GITHUB_USERNAME

echo -e "${BLUE}Podaj nazwę repozytorium (np. luminavivens):${NC}"
read -r REPO_NAME

echo -e "${BLUE}Podaj token dostępu GitHub:${NC}"
echo "(Utwórz token: GitHub → Settings → Developer settings → Personal access tokens)"
read -rs GITHUB_TOKEN
echo ""

# Sprawdź czy dane są podane
if [ -z "$GITHUB_USERNAME" ] || [ -z "$REPO_NAME" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Wszystkie pola są wymagane!${NC}"
    exit 1
fi

# Konfiguracja
echo ""
echo -e "${YELLOW}📝 Konfiguracja...${NC}"
git config --global user.email "deploy@luminavivens.com" 2>/dev/null || true
git config --global user.name "Lumina Vivens Deploy" 2>/dev/null || true

# Sprawdź czy repozytorium już istnieje
echo -e "${YELLOW}🔍 Sprawdzanie repozytorium na GitHub...${NC}"
REPO_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME")

if [ "$REPO_CHECK" = "404" ]; then
    echo -e "${YELLOW}📁 Tworzenie nowego repozytorium...${NC}"
    
    CREATE_RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"name\":\"$REPO_NAME\",\"private\":false,\"auto_init\":false}" \
        "https://api.github.com/user/repos")
    
    if echo "$CREATE_RESPONSE" | grep -q "\"id\":"; then
        echo -e "${GREEN}✓ Repozytorium utworzone pomyślnie!${NC}"
    else
        echo -e "${RED}❌ Błąd tworzenia repozytorium:${NC}"
        echo "$CREATE_RESPONSE"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Repozytorium już istnieje${NC}"
fi

# Inicjalizacja git lokalnie
echo ""
echo -e "${YELLOW}🔧 Inicjalizacja lokalnego repozytorium...${NC}"

if [ -d ".git" ]; then
    echo -e "${YELLOW}  Repozytorium git już istnieje, resetuję...${NC}"
    rm -rf .git
fi

git init
git branch -M main

# Dodaj zdalne repozytorium
echo -e "${YELLOW}🔗 Łączenie z GitHub...${NC}"
git remote remove origin 2>/dev/null || true
git remote add origin "https://$GITHUB_TOKEN@github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Dodaj pliki .gitignore
echo -e "${YELLOW}📝 Tworzenie .gitignore...${NC}"
cat > .gitignore << 'EOF'
# Dependencies
node_modules
.pnp
.pnp.js

# Build outputs (nie ignorujemy dist dla GitHub Pages!)
# dist

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE
.vscode
.idea
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF

# Dodaj wszystkie pliki
echo -e "${YELLOW}📦 Dodawanie plików...${NC}"
git add .

# Commit
echo -e "${YELLOW}💾 Tworzenie commitu...${NC}"
git commit -m "Initial commit: Lumina Vivens website

- React + TypeScript + Vite + Tailwind CSS
- GSAP animations with ScrollTrigger
- Custom fonts: Cinzel + Playfair Display
- 6 spiritual gateway sections
- Responsive design
- Smooth scrolling with Lenis" || {
    echo -e "${YELLOW}  ℹ️ Brak zmian do zacommitowania lub commit już istnieje${NC}"
}

# Push
echo ""
echo -e "${YELLOW}🚀 Wysyłanie na GitHub...${NC}"
git push -u origin main --force

echo ""
echo -e "${GREEN}✅ KOD WYSŁANY NA GITHUB!${NC}"
echo ""
echo -e "${BLUE}📍 Repozytorium:${NC} https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo ""

# Włącz GitHub Pages przez API
echo -e "${YELLOW}⚙️  Włączanie GitHub Pages...${NC}"

ENABLE_PAGES=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d '{
        "source": {
            "branch": "main",
            "path": "/"
        }
    }' \
    "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME/pages")

if echo "$ENABLE_PAGES" | grep -q "\"html_url\":" || echo "$ENABLE_PAGES" | grep -q "already enabled"; then
    echo -e "${GREEN}✓ GitHub Pages włączone!${NC}"
else
    echo -e "${YELLOW}⚠️  GitHub Pages prawdopodobnie już włączone lub wymaga ręcznej konfiguracji${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  🎉 GOTOWE!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}🌐 Twoja strona będzie dostępna za 2-5 minut pod adresem:${NC}"
echo -e "${GREEN}   https://$GITHUB_USERNAME.github.io/$REPO_NAME${NC}"
echo ""
echo -e "${YELLOW}📋 Następne kroki (jeśli strona nie działa):${NC}"
echo "   1. Wejdź na: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "   2. Kliknij Settings → Pages (w menu po lewej)"
echo "   3. Upewnij się, że Source jest ustawione na 'Deploy from a branch'"
echo "   4. Branch: main, Folder: / (root)"
echo ""
echo -e "${YELLOW}🔄 Aktualizacja strony w przyszłości:${NC}"
echo "   Po wprowadzeniu zmian w kodzie, uruchom:"
echo -e "   ${GREEN}git add . && git commit -m 'Update' && git push${NC}"
echo ""
