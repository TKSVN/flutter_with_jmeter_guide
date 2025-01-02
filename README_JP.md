<img src="https://tks.asia/wp-content/uploads/2022/01/logo-1024x337.png" alt="drawing" width="200"/>

---
他の言語:  
- [🇺🇸 English(US)](README.md)  
- [🇻🇳 Tiếng Việt](README_VN.md)

# FlutterアプリのテストシナリオをJMeterで記録する方法

## 問題

おそらく、JMeterでモバイルアプリのテストシナリオを記録する際に、インターネット上でよく見られる以下のガイドを参考にされたことがあるでしょう。 

https://medium.com/@viniciuscorrei/using-jmeter-to-record-test-scenarios-directly-from-mobile-applications-b5dc5bc48ef6  
https://blogs.perficient.com/2021/08/25/perform-load-test-on-mobile-app-using-apache-jmeter/  

しかし、それらのガイドの手順通りに実行しても、JMeterがモバイルアプリからサーバーに送信されるリクエストを記録できなかった経験をされた方もいる可能性があります。 

では、その原因は一体何なのでしょうか？ 

TKSベトナムで調査を進めた結果、この問題の答えを見つけることができました。詳細な説明は以下をご覧ください。

## 問題の解決方法

### 主な原因：Flutterはproxy-awareではないDartを使用しているため 

JMeterがモバイルアプリからサーバーに送信されるリクエストを記録できない主な原因は、Flutterがproxy-awareではないDartを使用しているためです。 

JMeterの仕組みでは、プロキシサーバーを作成し、その後モバイルアプリがそのプロキシサーバーを通じてインターネットに接続します。これにより、JMeterはモバイルアプリが送信するリクエストを記録できるようになります。 

しかし、Flutterアプリはデフォルトでシステム設定で構成されたプロキシサーバーを使用しないため、それらのガイドに従ってプロキシを設定してもFlutterアプリには効果がありません。 

### 解決策

簡単な解決策は、ガイドに従うだけでなく、Flutterアプリのためにプロキシサーバーの設定を明示的に指定することです。 

以下は、Flutterで一般的に使用されるサーバー接続ライブラリを使用する際のガイドです。 

#### http

1. 以下のライブラリを追加します。 

    ```bash
    flutter pub add http
    flutter pub add system_proxy
    ```

1. システムのプロキシを取得し、Flutterアプリに設定します。 

    ```dart
    class ProxiedHttpOverrides extends HttpOverrides {
        final String _port;
        final String _host;
        ProxiedHttpOverrides(this._host, this._port);

        @override
        HttpClient createHttpClient(SecurityContext? context) {
            return super.createHttpClient(context)
            // set proxy
            ..findProxy = (uri) {
                return 'PROXY $_host:$_port';
            }
            ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        }
    }


    void main() async {
        WidgetsFlutterBinding.ensureInitialized();

        Map<String, String>? proxy = await SystemProxy.getProxySettings();
        if (proxy != null) {
            HttpOverrides.global = ProxiedHttpOverrides(proxy['host']!, proxy['port']!);
        }

        runApp(MyApp());
    }
    ```

    **注意：** 以下のコードは、JMeterが生成した自己署名証明書を使用するために必須です。 

    ```dart
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    ```

1. モバイルアプリからAPIへのリクエストを実行します

    ```dart
    const url = 'https://petstore.swagger.io/v2/pet/findByStatus?status=available';
    await http.get(Uri.parse(url));
    ```

#### dio

1. 以下のライブラリを追加します。 

    ```bash
    flutter pub add dio
    flutter pub add system_proxy
    ```

1. システムのプロキシを取得し、Flutterアプリに設定します。 

    ```dart
    class ProxiedHttpOverrides extends HttpOverrides {
        final String _port;
        final String _host;
        ProxiedHttpOverrides(this._host, this._port);

        @override
        HttpClient createHttpClient(SecurityContext? context) {
            return super.createHttpClient(context)
            // set proxy
            ..findProxy = (uri) {
                return 'PROXY $_host:$_port';
            }
            ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        }
    }

    void main() async {
        WidgetsFlutterBinding.ensureInitialized();

        Map<String, String>? proxy = await SystemProxy.getProxySettings();
        if (proxy != null) {
            final httpOverrides = ProxiedHttpOverrides(proxy['host']!, proxy['port']!);

            dio.httpClientAdapter = IOHttpClientAdapter()
                ..createHttpClient = () {
                    return httpOverrides.createHttpClient(null);
                };
        }

        runApp(MyApp());
    }
    ```

    **注意：** 以下のコードは、JMeterが生成した自己署名証明書を使用するために必須です。 

    ```dart
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    ```

1. モバイルアプリからAPIへのリクエストを実行します。 

    ```dart
    const url = 'https://petstore.swagger.io/v2/pet/findByStatus?status=available';
    await dio.get(url);
    ```

### サンプルアプリ上の結果

1. JMeterサーバーでプロキシを設定する時

    ![Proxy setting](images/proxy_setting.png)

1. ライブラリを選択し、リクエストを実行する時

    ![Request from app](images/request_from_app.png)

1. リクエストがJMeterで記録されていることを確認できます。 

    ![JMeter](images/jmeter.png)
