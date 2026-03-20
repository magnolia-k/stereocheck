# StreoCheck 仕様書

## 概要

macOS のメニューバーに常駐し、オーディオ出力デバイスの L/R チャンネル割り当て状況を表示・変更するアプリケーション。Audio MIDI Setup を開かずに、スピーカーの左右チャンネルが正常か入れ替わっているかを確認・修正できる。

## 動作環境

- macOS 26 Tahoe 以降
- Swift 6.2 以降（Xcode 不要、Command Line Tools のみで動作）

## 機能

### メニューバーアイコン

- 常に `hifispeaker.2.fill`（ステレオスピーカー）アイコンを表示
- すべてのデバイスが正常: デフォルト色（白/黒）
- 1台以上でチャンネルが入れ替わっている: オレンジ色

### ポップオーバー（アイコンクリックで表示）

#### デバイス一覧

接続中のオーディオ出力デバイスを列挙し、各デバイスについて以下を表示する。

| 要素 | 内容 |
|------|------|
| 状態アイコン | ✓（緑）= 正常、⚠（オレンジ）= 入れ替わり |
| デバイス名 | Core Audio から取得したデバイス名 |
| チャンネル情報 | `L←Ch1  R←Ch2` の形式で物理チャンネル番号を表示 |

#### チャンネル入れ替え操作

- 状態アイコンをクリックすると L/R チャンネルの割り当てを入れ替える
- 正常 → 入れ替え、入れ替え → 正常 をトグル
- 変更は即座に反映され、UI も即時更新される

#### フッター

- 「StreoCheck を終了」ボタン（⌘Q）のみ配置

### 自動更新

以下の2段構えで状態を監視する。

1. **Core Audio プロパティリスナー**: デバイスの接続・切断を即時検知
2. **ポーリング**: 5秒ごとにチャンネル設定の変化を確認（リスナーで検知できないケースの補完）

## チャンネル状態の判定

Core Audio の `kAudioDevicePropertyPreferredChannelsForStereo` プロパティを使用。

- 返り値: `[leftChannelNumber, rightChannelNumber]`
- 正常: left < right（例: Ch1=L, Ch2=R）
- 入れ替わり: left > right（例: Ch2=L, Ch1=R）

プロパティが取得できないデバイスは正常とみなす。

## ビルド・実行

```bash
swift build        # ビルド
swift run          # ビルド＆起動
pkill StreoCheck   # 終了
```

## 自動起動（LaunchAgent）

ログイン時に自動起動させる場合は LaunchAgent を使用する。

```bash
# リリースビルドしてバイナリを配置
swift build -c release
sudo cp .build/release/StreoCheck /usr/local/bin/StreoCheck

# LaunchAgent を登録
cp tech.magnolia.streocheck.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/tech.magnolia.streocheck.plist
```

バイナリのパスは `tech.magnolia.streocheck.plist` の `ProgramArguments` に記載（`/usr/local/bin/StreoCheck`）。

## ファイル構成

```
Sources/StreoCheck/
├── StreoCheckApp.swift   # @main エントリポイント、MenuBarExtra 定義
├── AudioMonitor.swift    # Core Audio 監視・チャンネル操作ロジック
└── MenuView.swift        # ポップオーバー UI
```
