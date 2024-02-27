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

  File? downloadedFile;

  Future<Uint8List> loadTorrentFromAsset() async {
    ByteData byteData = await rootBundle.load('assets/akula.torrent');

    Uint8List bytes = byteData.buffer.asUint8List();
    debugPrint('💡loadTorrentFromAsset :length: ${bytes.length}');
    torrent = bytes;
    return bytes;
  }

  Future<void> startDownloading(Uint8List torrent) async {
    if (task == null) {
      try {
        directory = await getTemporaryDirectory();

        final model = await Torrent.parse(torrent);
        debugPrint('💡Torrent name ${model.name} ');
        debugPrint('💡Torrent announces ${model.announces} ');
        debugPrint('💡Torrent filePath ${model.filePath} ');
        debugPrint('💡Torrent info ${model.info} ');
        debugPrint('💡Torrent urlList ${model.urlList} ');
        debugPrint('💡Torrent files.first.path ${model.files.first.path} ');

        task = TorrentTask.newTask(model, directory.path);
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
              if (task != null) ...[
                Text('💡STATUS:: ${task?.progress}'),
                Text('💡connectedPeersNumber:: ${task?.connectedPeersNumber}'),
              ],
              const Gap(15),
              ElevatedButton(
                  onPressed: () {
                    startDownloading(torrent);
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
                    })
              ],
            ],
          ),
        ),
      ),
    );
  }
}
