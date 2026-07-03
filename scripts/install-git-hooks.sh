#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Instalar Git Hooks de TrueTally
# Configura core.hooksPath para usar los hooks versionados en scripts/git-hooks/
# =============================================================================

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
HOOKS_DIR="$REPO_ROOT/scripts/git-hooks"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "❌ No se encontró el directorio de hooks en $HOOKS_DIR"
  exit 1
fi

# Asegurar permisos de ejecución
chmod +x "$HOOKS_DIR"/*

# Configurar git para usar este directorio de hooks
git config core.hooksPath "$HOOKS_DIR"

echo "✅ Git hooks instalados correctamente en: $HOOKS_DIR"
echo ""
echo "Hooks activos:"
ls -1 "$HOOKS_DIR"
echo ""
echo "Para desinstalar: git config --unset core.hooksPath"
