# Raspberry Pi Pico 2 W - Docker ビルド環境

このDockerfileは、Raspberry Pi Pico 2 W用のクロスコンパイル環境を提供します。

## セットアップ

### 1. Docker Imageのビルド

```bash
# Dockerfileが存在するディレクトリで実行
docker build -t pico2w-builder:latest .
```

または docker-compose を使用:

```bash
docker-compose build
```

## ビルド方法

### 方法1: docker-compose を使用（推奨）

```bash
docker-compose run pico-build build-pico.sh
```

### 方法2: docker コマンド直接実行

```bash
docker run --rm -v $(pwd):/workspace pico2w-builder:latest build-pico.sh
```

### 方法3: インタラクティブシェル

```bash
docker run --rm -it -v $(pwd):/workspace pico2w-builder:latest /bin/bash
```

インタラクティブシェル内で:

```bash
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
```

## ビルド結果

コンパイルが成功すると、以下の処理が自動的に実行されます：

- `.uf2` ファイルがトップディレクトリに移動される
- `build` フォルダが削除される
- トップディレクトリに `.uf2` ファイルが生成されます

### 生成されるファイル

- `picow_sdcard_play.uf2` - Picoにフラッシュ可能なファイル（トップディレクトリ）

## 環境変数

Docker内で以下の環境変数が設定されています：

- `PICO_SDK_PATH=/opt/pico-sdk` - Pico SDK のパス
- `PICO_TOOLCHAIN_PATH=/opt/arm-toolchain` - ツールチェーンのパス

## クリーンビルド

```bash
# ビルドスクリプトを実行（自動的にbuildフォルダは削除されます）
docker run --rm -v $(pwd):/workspace pico2w-builder:latest build-pico.sh
```

または、既存の成果物をクリアしてからビルド：

```bash
docker run --rm -v $(pwd):/workspace pico2w-builder:latest /bin/bash -c "rm -f *.uf2 && build-pico.sh"
```

## トラブルシューティング

### メモリリンカーエラーが発生した場合

プロジェクトの設定に関連するメモリレイアウトのエラーが発生する場合があります。この場合は、プロジェクトの`CMakeLists.txt`の設定を確認してください。Docker image自体は正常に動作しています。

### コンテナの再構築が必要な場合

```bash
docker-compose build --no-cache
```

### 古いimageの削除

```bash
docker rmi pico2w-builder:latest
```

## Docker Imageの検証

ビルド後、以下のコマンドでDocker imageが正常に動作していることを確認できます：

```bash
# ARM GCC Toolchainの確認
docker run --rm pico2w-builder:latest arm-none-eabi-gcc --version

# Pico SDKの確認
docker run --rm pico2w-builder:latest ls -la /opt/pico-sdk

# CMakeの確認
docker run --rm pico2w-builder:latest cmake --version
```

## 対応バージョン

- Pico SDK: 2.0.0
- ARM GCC Toolchain: 10.3.1
- CMake: 3.22+
- Ubuntu: 22.04

## Image情報

- **サイズ**: ~3.6GB
- **ベースイメージ**: ubuntu:22.04
- **含まれるツール**:
  - build-essential
  - CMake 3.22+
  - ARM GCC Toolchain
  - Pico SDK 2.0.0
  - Git
  - Python3

## マウントパス

Dockerコンテナ内でのビルド時、プロジェクトディレクトリは `/workspace` にマウントされます。

## ビルドプロセスの詳細

### ビルドスクリプトの処理フロー

1. `/workspace/build` ディレクトリを作成
2. CMakeでプロジェクトを設定
3. `make` でコンパイル
4. **自動処理**:
   - `*.uf2` ファイルをスキャン
   - 見つかったすべての `.uf2` ファイルを `/workspace` （トップディレクトリ）に移動
   - `build` ディレクトリを削除
5. 完了メッセージを表示

### 利点

- ビルド完了後、自動的にuf2ファイルはトップディレクトリに配置
- `build` フォルダはビルド完了後に自動削除されるため、ディスク容量を節約
- ローカルマシン上に `.uf2` ファイルが直接反映される
- 複数の `.uf2` ファイルが生成される場合、すべて移動される

