# Start here

**The working game is not on this branch.** It is on the branch `feature/v3-heroes-bosses-meta`, in draft pull request #2: https://github.com/Vano3667/HPGTA-Game/pull/2

Read this file on that branch first: [HANDOFF.md](https://github.com/Vano3667/HPGTA-Game/blob/feature/v3-heroes-bosses-meta/HANDOFF.md). Begin with the sections `Start Here` and `Where the Work Stopped`.

What you need to know about `main`:

- The scripts on `main` do not parse (`scripts/game/art.gd:145`), so `main` does not build. Merging pull request #2 repairs it. Do not merge until the owner has approved the game on a phone.
- `HANDOFF.md` and `README.md` on `main` are out of date. Do not edit them here: both differ on the branch, an edit on `main` creates a merge conflict, and the pull request's CI stops running while a conflict exists.
- The owner uploads painted art to `main` under `assets/visual-kit/`. That is the only thing `main` is used for right now. The pull request's CI tests the branch merged with `main`, so new art is picked up without any merge by hand.

Added on 2026-11-27 as a pointer only. This commit changes no code.

---

**По-русски.** Рабочая игра лежит не здесь, а в ветке `feature/v3-heroes-bosses-meta` (черновой PR #2). Новому агенту нужно открыть `HANDOFF.md` в той ветке и начать с раздела `Where the Work Stopped`. В `main` кладутся только картинки в `assets/visual-kit/`.
