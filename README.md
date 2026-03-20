# StreoCheck

macOS のメニューバーに常駐し、オーディオ出力デバイスの左右チャンネル設定を確認・修正するアプリ。

Audio MIDI Setup を開かなくても、スピーカーの L/R が正常か入れ替わっているかをひと目で確認でき、クリック一つで切り替えられる。

## 動作環境

- macOS 26 Tahoe 以降
- Swift Command Line Tools（Xcode 不要）

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
git clone git@github.com:magnolia-k/streocheck.git
cd streocheck
```

### 3. ビルド＆起動

```bash
swift run
```

## ログイン時に自動起動する

リリースビルドしてバイナリをインストールし、LaunchAgent を登録する。

```bash
swift build -c release
sudo cp .build/release/StreoCheck /usr/local/bin/StreoCheck
cp tech.magnolia.streocheck.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/tech.magnolia.streocheck.plist
```

### 自動起動を解除する

```bash
launchctl unload ~/Library/LaunchAgents/tech.magnolia.streocheck.plist
rm ~/Library/LaunchAgents/tech.magnolia.streocheck.plist
```

## 使い方

起動するとメニューバーにステレオスピーカーアイコンが表示される。

- **アイコンが白/黒**: すべてのデバイスで L/R が正常
- **アイコンがオレンジ**: いずれかのデバイスで L/R が入れ替わっている

アイコンをクリックすると接続中の出力デバイス一覧が表示される。各デバイスの左端のアイコン（✓ または ⚠）をクリックすると L/R チャンネルの割り当てを切り替えられる。

## 終了

メニューの「StreoCheck を終了」または ⌘Q。
