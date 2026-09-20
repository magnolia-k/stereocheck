# StereoCheck

macOS のメニューバーに常駐し、オーディオ出力デバイスの左右チャンネル設定を確認・修正するアプリ。

Audio MIDI Setup を開かなくても、スピーカーの L/R が正常か入れ替わっているかをひと目で確認でき、クリック一つで切り替えられる。

## 動作環境

- macOS 26 Tahoe 以降
- 対応するSwift Command Line ToolsまたはXcode

## インストール

### 1. Command Line Tools の確認

```bash
swift --version
```

インストールされていない場合:

```bash
xcode-select --install
```

### 2. リポジトリのクローン

```bash
git clone git@github.com:magnolia-k/stereocheck.git
cd stereocheck
```

### 3. ビルド＆起動

```bash
swift run -c release
```

開発中にデバッグビルドを使用する場合は `swift run` を実行する。

## ログイン時に自動起動する

リリースビルドしてバイナリをインストールし、LaunchAgent を登録する。

```bash
swift build -c release
sudo cp .build/release/StereoCheck /usr/local/bin/StereoCheck
cp tech.magnolia.stereocheck.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/tech.magnolia.stereocheck.plist
```

### 自動起動を解除する

```bash
launchctl bootout gui/$(id -u)/tech.magnolia.stereocheck
rm ~/Library/LaunchAgents/tech.magnolia.stereocheck.plist
```

## アンインストール

自動起動を解除したうえで、バイナリを削除する。

```bash
launchctl bootout gui/$(id -u)/tech.magnolia.stereocheck
rm ~/Library/LaunchAgents/tech.magnolia.stereocheck.plist
sudo rm /usr/local/bin/StereoCheck
```

## 使い方

起動するとメニューバーにステレオスピーカーアイコンが表示される。

- **アイコンが白/黒**: すべてのデバイスで L/R が正常
- **アイコンがオレンジ**: いずれかのデバイスで L/R が入れ替わっている

アイコンをクリックすると接続中の出力デバイス一覧が表示される。

- 現在の再生先デバイスは名前の横にスピーカーアイコン（🔊）が表示される
- デバイス名をクリックすると再生先を切り替えられる
- 各デバイスの左端のアイコン（✓ または ⚠）をクリックすると L/R チャンネルの割り当てを切り替えられる
- ステレオ設定を取得できないデバイスでは、L/R の切り替えは無効になる
- 設定変更に失敗した場合は、メニュー内にエラーが表示される

## 終了

メニューの「StereoCheck を終了」または ⌘Q。

## トラブルシューティング

Command Line Toolsの構成によって、存在しない検索パスに関するリンカー警告が表示される場合がある。ビルドが完了していれば、アプリの実行には影響しない。

警告を解消するにはCommand Line Toolsを更新・再インストールするか、完全版Xcodeのツールチェーンを使用する。非推奨の `--build-system native` は使用しない。
