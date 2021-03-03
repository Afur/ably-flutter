import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'config/test_factory.dart';
import 'driver_data_handler.dart';
import 'factory/error_handler.dart';
import 'factory/reporter.dart';

enum _TestStatus { success, error, progress }

/// Decodes messages from the driver, invokes the test and returns the result.
class TestDispatcher extends StatefulWidget {
  final ErrorHandler errorHandler;
  final Map<String, TestFactory> testFactory;
  final DispatcherController controller;

  const TestDispatcher({
    Key key,
    this.testFactory,
    this.errorHandler,
    this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TestDispatcherState();
}

class _TestDispatcherState extends State<TestDispatcher> {
  /// The last message received from the driver.
  Reporter _reporter;

  Map<String, String> _testResults;

  /// stores whether a test is success/failed/pending
  /// {'restPublish': true} => basic test passed,
  /// {'restPublish': false} => failed
  /// {} i.e., missing 'restPublish' key => test is still pending
  final _testStatuses = <String, _TestStatus>{};

  @override
  void initState() {
    super.initState();
    widget.controller.setDispatcher(this);
    _testResults = <String, String>{
      for (final key in testFactory.keys) key: '',
    };
  }

  Future<TestControlMessage> handleDriverMessage(
    TestControlMessage message,
  ) {
    final reporter = Reporter(message, widget.controller);

    Future.delayed(Duration.zero, () async {
      // check if a test is running and throw error
      if (_reporter != null) {
        reporter.reportTestError(
          'New test started while the previous one is still running.',
        );
      }

      if (widget.testFactory.containsKey(reporter.testName)) {
        // check if a test exists with that name
        _reporter = reporter;
        if (widget.testFactory.containsKey(_reporter.testName)) {
          setState(() {
            _testStatuses[_reporter.testName] = _TestStatus.progress;
          });
          final testFunction = widget.testFactory[_reporter.testName];
          await testFunction(
            reporter: _reporter,
            payload: _reporter.message.payload,
          ).then(
            (response) {
              _reporter?.reportTestCompletion(response);
            },
          ).catchError(widget.errorHandler.onException);
        }
      } else {
        // report error otherwise
        reporter.reportTestCompletion({
          TestControlMessage.errorKey:
              'Test ${reporter.testName} is not implemented'
        });
      }
      setState(() {});
    });

    return reporter.response.future;
  }

  void unhandledTestExceptionAndFlutterErrorHandler(
    Map<String, String> errorMessage,
  ) =>
      _reporter
          .reportTestCompletion({TestControlMessage.errorKey: errorMessage});

  Color _getColor(String testName) {
    switch (_testStatuses[testName]) {
      case _TestStatus.success:
        return Colors.green;
      case _TestStatus.error:
        return Colors.red;
      case _TestStatus.progress:
        return Colors.blue;
    }
    return Colors.grey;
  }

  Widget _getAction(String testName) {
    final playIcon = IconButton(
      icon: const Icon(Icons.play_arrow),
      onPressed: _reporter == null
          ? () {
              handleDriverMessage(TestControlMessage(testName)).then((_) {
                setState(() {});
              });
              setState(() {});
            }
          : null,
    );
    switch (_testStatuses[testName]) {
      case _TestStatus.success:
        return playIcon;
      case _TestStatus.error:
        return playIcon;
      case _TestStatus.progress:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(),
        );
    }
    return playIcon;
  }

  Widget _getStatus(String testName) {
    switch (_testStatuses[testName]) {
      case _TestStatus.success:
        return const Icon(Icons.check);
      case _TestStatus.error:
        return const Icon(Icons.warning_amber_rounded);
      case _TestStatus.progress:
        return Container();
    }
    return Container();
  }

  Widget getTestRow(BuildContext context, String testName) => Row(
        children: [
          Expanded(
            child: Text(
              testName,
              style: TextStyle(color: _getColor(testName)),
            ),
          ),
          _getAction(testName),
          _getStatus(testName),
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  contentPadding: const EdgeInsets.all(4),
                  insetPadding: const EdgeInsets.symmetric(vertical: 24),
                  content: SingleChildScrollView(
                    child: Text(
                      _testResults[testName] ?? 'No result yet',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => MaterialApp(
          home: Scaffold(
        appBar: AppBar(
          title: const Text('Test dispatcher'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(child: Text(_reporter?.testName ?? '-')),
            Expanded(
              child: ListView.builder(
                itemCount: _testResults.keys.length,
                itemBuilder: (context, idx) {
                  final testName = _testResults.keys.toList()[idx];
                  return ListTile(subtitle: getTestRow(context, testName));
                },
              ),
            ),
          ],
        ),
      ));

  void renderResponse(TestControlMessage message) {
    final testName = message.testName;
    _testResults[testName] = message.toPrettyJson();
    setState(() {
      _reporter = null;
      _testStatuses[testName] =
          message.payload.containsKey(TestControlMessage.errorKey)
              ? _TestStatus.error
              : _TestStatus.success;
    });
  }
}

class DispatcherController {
  _TestDispatcherState _dispatcher;

  // ignore: use_setters_to_change_properties
  void setDispatcher(_TestDispatcherState dispatcher) {
    _dispatcher = dispatcher;
    // more stuff
  }

  Future<String> driveHandler(String encodedMessage) async {
    final response = await _dispatcher.handleDriverMessage(
      TestControlMessage.fromJson(json.decode(encodedMessage) as Map),
    );
    return json.encode(response);
  }

  void errorHandler(Map<String, String> errorMessage) {
    _dispatcher.unhandledTestExceptionAndFlutterErrorHandler(errorMessage);
  }

  void setResponse(TestControlMessage message) {
    _dispatcher.renderResponse(message);
  }
}
