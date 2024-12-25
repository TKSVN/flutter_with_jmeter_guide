import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:system_proxy/system_proxy.dart';
import 'package:http/http.dart' as http;

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
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

late final Dio dio;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, String>? proxy = await SystemProxy.getProxySettings();
  dio = Dio();

  if (proxy != null) {
    final httpOverrides = ProxiedHttpOverrides(proxy['host']!, proxy['port']!);
    HttpOverrides.global = httpOverrides;

    dio.httpClientAdapter = IOHttpClientAdapter()
      ..createHttpClient = () {
        return httpOverrides.createHttpClient(null);
      };
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _selectedHttpLib;
  String? _searchResponse;

  final _httpLibs = ['http', 'dio']
      .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ))
      .toList();

  FutureOr<void> _requestToPetStore() async {
    const url =
        'https://petstore.swagger.io/v2/pet/findByStatus?status=available';

    switch (_selectedHttpLib) {
      case 'http':
        {
          final response = await http.get(Uri.parse(url));
          setState(() {
            _searchResponse = response.statusCode.toString();
          });
          break;
        }
      case 'dio':
        {
          final response = await dio.get(url);
          setState(() {
            _searchResponse = response.statusCode.toString();
          });
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Select library:'),
                DropdownButton(
                    value: _selectedHttpLib,
                    items: _httpLibs,
                    onChanged: (value) => {
                      setState(() {
                        _selectedHttpLib = value;
                      })
                    }),
              ],
            ),
            const Text(
              'Result of search available pets',
            ),
            if (_searchResponse != null)
              Text('Response status is $_searchResponse'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestToPetStore,
        tooltip: 'Search available pets',
        child: const Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
