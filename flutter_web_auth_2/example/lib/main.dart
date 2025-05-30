import 'dart:async';
import 'dart:io' show HttpServer;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

const _html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Grant Access to Flutter</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin: 0; padding: 0; }

    main {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol;
    }

    #icon {
      font-size: 96pt;
    }

    #text {
      padding: 2em;
      max-width: 260px;
      text-align: center;
    }

    #button a {
      display: inline-block;
      padding: 6px 12px;
      color: white;
      border: 1px solid rgba(27,31,35,.2);
      border-radius: 3px;
      background-image: linear-gradient(-180deg, #34d058 0%, #22863a 90%);
      text-decoration: none;
      font-size: 14px;
      font-weight: 600;
    }

    #button a:active {
      background-color: #279f43;
      background-image: none;
    }
  </style>
</head>
<body>
  <main>
    <div id="icon">&#x1F3C7;</div>
    <div id="text">Press the button below to sign in using your localhost account.</div>
    <div id="button"><a href="CALLBACK_URL_HERE">Sign in</a></div>
  </main>
</body>
</html>
''';

void main(List<String> args) {
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      startServer();
    }
  }

  Future<void> startServer() async {
    final server = await HttpServer.bind('127.0.0.1', 43823);

    server.listen((req) async {
      setState(() {
        _status = 'Received request!';
      });

      req.response.headers.add('Content-Type', 'text/html');

      req.response.write(
        _html.replaceFirst(
          'CALLBACK_URL_HERE',
          'foobar://success?code=1337',
        ),
      );

      await req.response.close();
    });
  }

  Future<void> authenticate() async {
    setState(() {
      _status = '';
    });

    // Normally, you don't need to specify a custom URL on web. However, in
    // this example, we just go the auth page directly since we cannot start
    // the socket server...
    final url = kIsWeb ? '${Uri.base}auth.html' : 'http://127.0.0.1:43823/';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'foobar',
        options: const FlutterWebAuth2Options(
          timeout: 5, // example: 5 seconds timeout
          //Set Android Browser priority
          // customTabsPackageOrder: ['com.android.chrome'],
        ),
      );
      setState(() {
        _status = 'Got result: $result';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Got error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Web Auth 2 example'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Status: $_status\n'),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () async {
                    await authenticate();
                  },
                  child: const Text('Authenticate'),
                ),
              ],
            ),
          ),
        ),
      );
}
