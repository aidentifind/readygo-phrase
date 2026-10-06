# Play Store向け本番署名(アップロード鍵)の設定

`android/app/build.gradle.kts` は `android/key.properties` があればそれを使って
リリースビルドに署名し、無ければこれまで通りdebug鍵でビルドする(`flutter run --release`
が引き続き動くように)。`key.properties` 自体は `.gitignore` 済みなのでコミットされない。
readygo-speakと同じ仕組み。

## 手順

1. まだ鍵が無ければ、**リポジトリの外**(例: `~/keys/`)で生成する:
   ```
   keytool -genkey -v -keystore ~/keys/readygo-phrase-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   対話式でパスワードと名前などを聞かれる。パスワードはパスワードマネージャー等、
   安全な場所に必ず控えておくこと。**この鍵を紛失すると同じアプリとしてPlay Storeを
   更新できなくなる**(Play App Signingに登録済みなら、アップロード鍵の紛失はGoogleに
   申請すれば再発行できる)。

2. `android/` 直下に `key.properties` というファイルを作り、以下の内容を実際の値に
   置き換えて保存する(このファイル名はコミットしないこと):
   ```properties
   storePassword=<keytoolで設定したストアパスワード>
   keyPassword=<keytoolで設定した鍵パスワード>
   keyAlias=upload
   storeFile=/Users/<あなたのユーザー名>/keys/readygo-phrase-upload.jks
   ```

3. `flutter build appbundle --release` でPlay Store提出用の`.aab`が本番鍵で
   署名されてビルドされる。

## Play App Signingについて

Google Play Consoleでアプリを新規作成する際、この手順で作った鍵は「アップロード鍵」
として登録し、配布用の実際の署名鍵はGoogleが管理する **Play App Signing** を使うことを
推奨(Googleのデフォルト・現在の標準フロー)。アップロード鍵を紛失・漏洩してもPlay
Console経由でリセットできるため、本番配布鍵そのものを紛失するより被害が小さい。
