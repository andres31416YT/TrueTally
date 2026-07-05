# Git Hooks - TrueTally

Hooks de Git automatizados para validar código antes de commit y push.

## Hooks disponibles

### pre-commit (rápido)
Se ejecuta antes de crear un commit. **Bloquea el commit** si falla.
- Detección de secrets硬codeados
- TypeScript type check (`tsc --noEmit`)
- Ansible syntax check
- Terraform fmt + validate (solo advertencia)
- Rust compile check (`cargo check --workspace`, solo advertencia)

### pre-push (completo)
Se ejecuta antes de hacer push. **Bloquea el push** si falla.
- Frontend build (`npm run build`)
- Rust unit tests (`cargo test --workspace`)
- Ansible lint (si `ansible-lint` está instalado)

## Instalación

Los hooks se activan automáticamente si clonas el repo (ya está configurado `core.hooksPath`).

Para activarlos manualmente en un clone existente:

```bash
bash scripts/install-git-hooks.sh
```

## Desinstalación

```bash
git config --unset core.hooksPath
```

## Notas

- Los hooks son **no interactivos** (no piden input al usuario).
- Si necesitás saltarte un hook temporalmente: `git commit --no-verify` o `git push --no-verify`.
- El hook de Rust en `pre-commit` es **advertencia** porque hay errores de compilación preexistentes en el workspace. El hook de `pre-push` corre `cargo test` y sí bloquea si falla.

### Configuración de AWS para Ansible

Si tu usuario de AWS se llama distinto a `NON_AWS`, configura la variable antes de correr Ansible:

```bash
export ANSIBLE_AWS_PROFILE=tu_perfil
```

Si tenés un perfil por defecto en `~/.aws/config` y `AWS_PROFILE` ya está seteado, no necesitás hacer nada.
