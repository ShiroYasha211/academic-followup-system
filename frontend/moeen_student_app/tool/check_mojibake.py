from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    affected: list[tuple[Path, int]] = []

    for folder in (root / "lib", root / "test"):
        if not folder.exists():
            continue
        for path in folder.rglob("*"):
            if not path.is_file() or path.suffix not in {".dart", ".md"}:
                continue
            hits = 0
            for line in path.read_text(encoding="utf-8").splitlines():
                try:
                    repaired = line.encode("cp1256").decode("utf-8")
                except UnicodeError:
                    continue
                if repaired != line:
                    hits += 1
            if hits:
                affected.append((path.relative_to(root), hits))

    if not affected:
        print("No mojibake fragments found.")
        return 0

    print("Potential mojibake fragments found:")
    for path, hits in affected:
        print(f"- {path}: {hits}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
