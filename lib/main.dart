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
  late final Torrent torrent;
  late final Directory directory;
  TorrentTask? task;

  File? downloadedFile;

  Future<void> loadTorrentFromAsset() async {
    directory = await getTemporaryDirectory();

    ByteData byteData = await rootBundle.load('assets/akula.torrent');

    Uint8List bytes = byteData.buffer.asUint8List();
    torrent = await Torrent.parse(bytes);
    debugPrint('💡Torrent name ${torrent.name} ');
    debugPrint('💡Torrent announces ${torrent.announces} ');
    debugPrint('💡Torrent filePath ${torrent.filePath} ');
    debugPrint('💡Torrent info ${torrent.info} ');
    debugPrint('💡Torrent urlList ${torrent.urlList} ');
    debugPrint('💡Torrent files.first.path ${torrent.files.first.path} ');
  }

  Future<void> startDownloading() async {
    if (task == null) {
      try {
        debugPrint('💡_MainAppState.startDownloading :torrent: $torrent');
        task = TorrentTask.newTask(torrent, directory.path);
        debugPrint('💡Torrent task?.metaInfo.files ${task?.metaInfo.files} ');

        task?.start();
        final ev = task?.createListener();
        ev?.listen((event) {
          debugPrint('💡Got event :: $event');
        });
      } catch (e) {
        debugPrint('💡startDownloading :ERROR: $e');
      }
    }
  }

  Future<void> checkFile() async {
    if (task != null) {
      if (task!.metaInfo.files.isNotEmpty) {
        downloadedFile =
            File('${directory.path}/${task!.metaInfo.files.first.name}');
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
              if (task != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${task?.metaInfo.length}'),
                      Text('Downloaded: ${task?.downloaded}'),
                      Text('Progress:: ${task?.progress.toStringAsFixed(2)}'),
                      Text(
                          'connectedPeersNumber:: ${task?.connectedPeersNumber}'),
                      Text(
                          'averageDownloadSpeed:: ${task?.currentDownloadSpeed.toStringAsFixed(2)}'),
                      Text(
                          'averageUploadSpeed:: ${task?.uploadSpeed.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              const Gap(15),
              ElevatedButton(
                  onPressed: () {
                    startDownloading();
                  },
                  child: const Text('Start download')),
              const Gap(15),
              ElevatedButton(
                  onPressed: () {
                    checkFile();
                  },
                  child: const Text('check file')),
              if (downloadedFile != null) ...[
                Text('Downloaded file :path: ${downloadedFile?.path}'),
                FutureBuilder(
                    future: downloadedFile?.length(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return Text('Downloaded file :size: ${snapshot.data}');
                      } else if (snapshot.hasError) {
                        return const Icon(Icons.error_outline);
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
                ElevatedButton(
                    onPressed: () {
                      task?.stop();
                    },
                    child: const Text('Task Stop')),
                ElevatedButton(
                    onPressed: () {
                      task?.start();
                    },
                    child: const Text('Task Start')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
