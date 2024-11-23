* `.zshenv` is always sourced. `$PATH`, `$EDITOR`, and `$PAGER` are often set in `.zshenv`. `$ZDOTDIR` can specify alternate location for the rest of your zsh configuration.
* `.zprofile` is for login shells. It is sourced before `.zshrc`.
* `.zshrc` is for interactive shells.
* `.zlogin` is for login shells

```
.zshenv → [.zprofile if login] → [.zshrc if interactive] → [.zlogin if login] → [.zlogout sometimes]
```

<https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout>
