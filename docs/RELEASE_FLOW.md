# リリースフロー(develop / main ブランチ運用、2026-10-06導入)

`readygo-speak`・`readygo-speak-api`と同じ考え方で、このアプリも`develop`で開発し、`main`は
明示的な「リリース作業」のときだけ進める運用にする。アプリにはRenderのような自動デプロイ先が
無く、「リリース」はストア(Play Console / App Store Connect)への手動アップロードを指す。

## ブランチの役割

| ブランチ | 役割 |
|---|---|
| `develop` | 通常の開発。PRのマージ先 |
| `main` | ストアに提出した(または提出する)状態。`develop`から明示的にマージするときだけ進む |

`main`に何かが入るのは、ユーザー自身がストア提出に向けてリリース作業をしたときだけ。
普段の機能追加・修正はすべて`develop`で完結する。

## 日常の開発フロー

1. `develop`から作業ブランチを切ってPR → `develop`にマージ
2. 動作確認は`develop`の状態で行う。APIの変更も絡む場合は`readygo-speak-api`側も
   `develop`にマージしてdev環境(api-dev)に反映させ、このアプリを
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://api-dev.readygo-english.space
   ```
   でビルドして実機で確認する
   ([readygo-speak-api/docs/DEV_API_ENVIRONMENT.md](../../readygo-speak-api/docs/DEV_API_ENVIRONMENT.md))

## リリース作業(ストア提出に向けてmainを進める)

1. `develop`の状態でストアに出してよいと判断したら、`develop` → `main`のPRを作成・マージ
2. **API側に未リリースの変更が含まれる場合は、このタイミングでAPI側のリリース作業も行う**
   ([readygo-speak-api/docs/RELEASE_FLOW.md](../../readygo-speak-api/docs/RELEASE_FLOW.md))。
   アプリのリリースビルドは常に本番API(`api.readygo-english.space`)を向くため、
   アプリのビルドより前に本番側のデプロイを済ませておくこと
3. `pubspec.yaml`の`version`(現在`1.0.0+1`)を上げる
4. リリースビルドを作成:
   ```bash
   flutter build appbundle --release   # Android(Play Store提出用)
   flutter build ipa --release         # iOS(App Store Connect提出用)
   ```
   Android本番署名の設定は[android/RELEASE_SIGNING.md](../android/RELEASE_SIGNING.md)参照
5. Play Console / App Store Connectへアップロード(手動)
6. リリースコミットにタグを付ける(例: `git tag phrase-v1.0.0 && git push origin phrase-v1.0.0`)。
   必須ではないが、後から「ストアにいつ何を出したか」を追いやすくするため推奨

## 初回セットアップ(このフローを有効にするための一度だけの作業)

- [ ] `develop`ブランチをpush(ローカルには作成済み。`git push -u origin develop`)
- [ ] (推奨)GitHubのDefault branchを`develop`に変更(Settings → General → Default branch)
- [ ] (推奨)`main`にブランチ保護を設定(Settings → Branches → Add rule → `main`:
      "Require a pull request before merging")。直接pushを防ぎ、必ずPR経由でのみ更新されるようにする

## 関連

- バックエンド側のブランチ運用・リリース手順は
  [readygo-speak-api/docs/RELEASE_FLOW.md](../../readygo-speak-api/docs/RELEASE_FLOW.md)
- 外出先での実機テスト用dev環境は
  [readygo-speak-api/docs/DEV_API_ENVIRONMENT.md](../../readygo-speak-api/docs/DEV_API_ENVIRONMENT.md)
- readygo-speak側の同じ運用は
  [readygo-speak/docs/RELEASE_FLOW.md](../../readygo-speak/docs/RELEASE_FLOW.md)
