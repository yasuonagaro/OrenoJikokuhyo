# 俺の時刻表 (OrenoJikokuhyo)

これは、電車の時刻表を表示するためのiOSアプリケーションです。RapidAPI上のAPIを利用して時刻表データを取得します。

## 主な機能

-   指定した駅の時刻表を表示
-   （ここに他の機能を追加）

## 動作環境

-   Xcode 14.0 以上
-   Swift 5.0 以上
-   CocoaPods

## セットアップ手順

プロジェクトをビルド・実行するには、以下の手順に従ってAPIキーを設定する必要があります。

### 1. リポジトリのクローン

```bash
git clone <リポジトリのURL>
cd OrenoJikokuhyo
```

### 2. CocoaPodsの依存関係をインストール

ターミナルで以下のコマンドを実行し、必要なライブラリをインストールします。

```bash
pod install
```

### 3. APIキーの設定

本プロジェクトでは、APIキーを安全に管理するため、暗号化してコードに埋め込む方式を採用しています。

#### 3-1. `credentials.plist` の作成

プロジェクトのルートディレクトリにある `.credentials` フォルダ内に、`credentials.plist` という名前のファイルを手動で作成します。

作成した `credentials.plist` に、以下の内容をコピー＆ペーストし、`YOUR_RAPID_API_KEY` の部分をあなた自身のRapidAPIキーに書き換えてください。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>rapidAPIKey</key>
	<string>YOUR_RAPID_API_KEY</string>
</dict>
</plist>
```

#### 3-2. 設定スクリプトの実行

ターミナルで以下のコマンドを実行します。

```bash
./.credentials/configure.sh
```

このコマンドは、`credentials.plist` の内容を暗号化し、APIキーを安全に取得するための `OrenoJikokuhyo/Credentials.swift` ファイルを自動的に生成します。

**注意:** `credentials.plist` や `Credentials.swift` は `.gitignore` によってGitの管理対象から除外されています。APIキーを変更した場合は、再度このスクリプトを実行してください。

### 4. プロジェクトを開いてビルド

Xcodeで `OrenoJikokuhyo.xcworkspace` ファイルを開き、ビルド・実行してください。

```bash
open OrenoJikokuhyo.xcworkspace
```

## 使用している技術

-   Swift / UIKit
-   CocoaPods
    -   Google Mobile Ads SDK
    -   Google Maps
-   RapidAPI
