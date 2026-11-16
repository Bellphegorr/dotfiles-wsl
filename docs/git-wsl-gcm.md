# Git no WSL (Git Credential Manager)

> Guia detalhado; o índice do repositório está no [README](../README.md).

No WSL, o Git usa o **Git Credential Manager (GCM) do Windows** via interop.
As credenciais ficam no Windows Credential Manager, não em `~/.git-credentials`.

## Configuração

```bash
bash config/git/configure-gcm.sh --check  # verifica sem alterar
bash config/git/configure-gcm.sh          # aplica
```

O script detecta o WSL, localiza o `git-credential-manager.exe` (ou usa
`GCM_PATH`) e configura `credential.helper` e
`credential.https://github.com.provider`. Ele não altera `user.name`,
`user.email` nem credenciais salvas.

```bash
# GCM em outro caminho
GCM_PATH="/mnt/c/caminho/git-credential-manager.exe" bash config/git/configure-gcm.sh
```

## Como funciona

O `~/.gitconfig` fica com o helper apontando para o `.exe` do Windows. O WSL
executa esse binário via interop e o GCM guarda a credencial no **Windows
Credential Manager** (entrada `git:https://github.com`).

Para verificar:

```bash
git config --show-origin --get-all credential.helper
printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed 's/^password=.*/password=<oculto>/'
```

## Token embutido na URL

Se o remote tiver `https://ghp_xxxxxxxx@github.com/usuario/repo.git`, o Git usa
esse token **antes** do GCM. Se ele estiver expirado, o push falha com
`Invalid username or token`. Foi o que aconteceu neste repositório. Remova da
URL e reautentique:

```bash
git remote set-url origin https://github.com/usuario/repo.git
printf 'protocol=https\nhost=github.com\n\n' | git credential reject
git push
```

> **Segurança:** não deixe tokens em URLs ou arquivos versionados. Se um token
> foi exposto, revogue em https://github.com/settings/tokens.

## Limitações

- Só funciona no WSL com Git for Windows/GCM instalado; em Linux nativo use
  `libsecret`, `store` ou SSH.
- O GCM precisa de terminal interativo para abrir o login; em CI use token ou SSH.
