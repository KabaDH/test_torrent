import 'dart:async';
import 'dart:io';

import 'package:dtorrent_parser/dtorrent_parser.dart';
import 'package:dtorrent_task/dtorrent_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulHookWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final Uint8List torrent;
  late final Directory directory;
  TorrentTask? task;

  Future<Uint8List> loadTorrentFromAsset() async {
    ByteData byteData = await rootBundle.load('assets/some.torrent');

    Uint8List bytes = byteData.buffer.asUint8List();
    debugPrint('💡loadTorrentFromAsset :length: ${bytes.length}');
    torrent = bytes;
    return bytes;
  }

  Future<void> startDownloading(Uint8List torrent) async {
    if (task == null) {
      try {
        debugPrint('💡:1: START: ${torrent.length}');
        directory = await getTemporaryDirectory();

        var model = await Torrent.parse(torrent);
        task = TorrentTask.newTask(model, directory.path);
        task?.start();
        task?.onTaskComplete(() {
          debugPrint('💡TaskComplete ');
        });
        task?.onFileComplete((String filePath) {
          debugPrint('💡File downloaded to  $filePath');
        });
      } catch (e) {
        debugPrint('💡startDownloading :ERROR: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadTorrentFromAsset();
    update();
  }

  void update() {
    Timer(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        setState(() {});
        update();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (task != null) ...[
                Text('💡STATUS:: ${task?.progress}'),
                Text('💡connectedPeersNumber:: ${task?.connectedPeersNumber}'),
              ],
              Gap(15),
              ElevatedButton(
                  onPressed: () {
                    startDownloading(torrent);
                  },
                  child: const Text('Start download')),
              Gap(5),
              ElevatedButton(
                  onPressed: () {
                    debugPrint('💡STATUS:: ${task?.progress}');
                    debugPrint(
                        '💡connectedPeersNumber:: ${task?.connectedPeersNumber}');
                  },
                  child: const Text('Status')),
            ],
          ),
        ),
      ),
    );
  }
}
