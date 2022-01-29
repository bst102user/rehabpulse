import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:ffi/ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'RehabPulse Doctor APP'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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
  final navigatorKey = GlobalKey<NavigatorState>();
  final _controller = WebviewController();
  final _textController = TextEditingController();
  bool _isWebviewSuspended = false;

  @override
  void initState() {
    super.initState();

    initPlatformState();
    // var helloLib = ffi.DynamicLibrary.open('myAssets/hello.dll');
  }

  Future<void> initPlatformState() async {
    // Optionally initialize the webview environment using
    // a custom user data directory
    // and/or a custom browser executable directory
    // and/or custom chromium command line flags
    //await WebviewController.initializeEnvironment(
    //    additionalArguments: '--show-fps-counter');

    await _controller.initialize();
    _controller.url.listen((url) {
      _textController.text = url;
    });

    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    await _controller.loadUrl('https://rehabpulseclaim.com/');

    if (!mounted) return;

    setState(() {});
  }

  Widget compositeView() {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Loading....',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Column(
        children: [
          // Card(
          //   elevation: 0,
          //   child: TextField(
          //     decoration: InputDecoration(
          //         hintText: 'URL',
          //         contentPadding: EdgeInsets.all(10.0),
          //         suffixIcon: IconButton(
          //           icon: Icon(Icons.refresh),
          //           onPressed: () {
          //             _controller.reload();
          //           },
          //         )),
          //     textAlignVertical: TextAlignVertical.center,
          //     controller: _textController,
          //     onSubmitted: (val) {
          //       _controller.loadUrl(val);
          //     },
          //   ),
          // ),
          Expanded(
              child: Card(
                  color: Colors.transparent,
                  elevation: 0,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: Stack(
                    children: [
                      Webview(
                        _controller,
                        permissionRequested: _onPermissionRequested,
                      ),
                      StreamBuilder<LoadingState>(
                          stream: _controller.loadingState,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data == LoadingState.loading) {
                              return LinearProgressIndicator();
                            } else {
                              return SizedBox();
                            }
                          }),
                    ],
                  ))),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        // floatingActionButton: FloatingActionButton(
        //   tooltip: _isWebviewSuspended ? 'Resume webview' : 'Suspend webview',
        //   onPressed: () async {
        //     if (_isWebviewSuspended) {
        //       await _controller.resume();
        //     } else {
        //       await _controller.suspend();
        //     }
        //     setState(() {
        //       _isWebviewSuspended = !_isWebviewSuspended;
        //     });
        //   },
        //   child: Icon(_isWebviewSuspended ? Icons.play_arrow : Icons.pause),
        // ),
        appBar: AppBar(
            title: Text('RehabPulse Doctor APP')/*StreamBuilder<String>(
              stream: _controller.title,
              builder: (context, snapshot) {
                return Text(snapshot.hasData
                    ? snapshot.data!
                    : 'RehabPulse Doctor APP');
              },
            )*/),
        body: Center(
          child: compositeView(),
        ),
      ),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }
}