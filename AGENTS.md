# AGENTS.md

- 製品概要、利用方法、ビルド手順は `README.md` を参照する。
- 仕様とアーキテクチャは `doc/spec.md` を参照する。
- 実装変更後は `swift build -c release` を実行し、可能なら `swift test` も実行する。
- Core Audio APIの戻り値を確認し、取得・変更の失敗を正常状態として扱わない。
- ユーザーの既存変更には触れず、タスクに関係するファイルだけを変更する。
