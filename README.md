# StereoCheck

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
git clone git@github.com:magnolia-k/stereocheck.git
cd stereocheck
```

### 3. ビルド＆起動

```bash
swift run
```

## ログイン時に自動起動する

リリースビルドしてバイナリをインストールし、LaunchAgent を登録する。

```bash
swift build -c release
sudo cp .build/release/StereoCheck /usr/local/bin/StereoCheck
cp tech.magnolia.stereocheck.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/tech.magnolia.stereocheck.plist
```

### 自動起動を解除する

```bash
launchctl unload ~/Library/LaunchAgents/tech.magnolia.stereocheck.plist
rm ~/Library/LaunchAgents/tech.magnolia.stereocheck.plist
```

## アンインストール

自動起動を解除したうえで、バイナリを削除する。

```bash
launchctl unload ~/Library/LaunchAgents/tech.magnolia.stereocheck.plist
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

## 終了

メニューの「StereoCheck を終了」または ⌘Q。
