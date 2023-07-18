// ignore_for_file: implementation_imports, prefer_const_constructors, use_build_context_synchronously

import 'dart:collection';
import 'dart:io';

import 'package:dipswitch/l10n/generated/localizations.dart';
import 'package:dipswitch/widgets/checkbox_item.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'package:flutter/src/material/dialog.dart' as dialog;
// ignore: library_prefixes
import 'package:flutter/src/material/text_button.dart' as textButton;
import 'package:flutter/src/widgets/single_child_scroll_view.dart'
    // ignore: library_prefixes
    as singleChildScrollView;

class TaskKillerPage extends StatefulWidget {
  const TaskKillerPage({Key? key}) : super(key: key);

  @override
  State<TaskKillerPage> createState() => _TaskKillerPageState();
}

class _TaskKillerPageState extends State<TaskKillerPage> {
  final List<ProcessItem> _systemProcess = [];
  final List<ProcessItem> _userProcess = [];
  bool _isfetching = false;
  String currentUser = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isfetching) {
      _isfetching = true;
      setState(() {
        getProcesses();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future getCurrentUser() async {
    final results = await Process.run('whoami', []);
    final processes = results.stdout.split('\n');
    return processes[0];
  }

  void getProcesses() async {
    _systemProcess.clear();
    _userProcess.clear();
    final String currentUser = await getCurrentUser();
    final results = await runExecutableArguments('tasklist', ['/v', '/fo:csv']);
    final processes = results.stdout.split('\n');
    List<String> processList = processes.sublist(3, processes.length - 1);
    processList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final List<String> unmappedSystemProcess = [];
    final List<String> unmappedUserProcess = [];
    for (var process in processList) {
      var processDetails = process.split(RegExp(','));
      if (processDetails.length > 2) {
        var processName = '';
        var user = '';

        var windowTitle = 'N/A';
        windowTitle =
            processDetails[processDetails.length - 1].replaceAll('"', '');
        processName = processDetails[0].replaceAll('"', '');
        user = processDetails[processDetails.length - 3].replaceAll('"', '');

        if (windowTitle.compareTo("N/A") == 1) {
          windowTitle = FGCOSLocalizations.of(context)
              .taskKillerBackgroundService
              .toString();
        }

        if (currentUser.trim() == user.toLowerCase().trim()) {
          unmappedUserProcess.add("$windowTitle - $processName");
        } else {
          unmappedSystemProcess.add("$user - $windowTitle - $processName");
        }
      }
    }

    final cleanListUser =
        LinkedHashSet<String>.from(unmappedUserProcess).toList();
    cleanListUser.sort((b, a) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (var process in cleanListUser) {
      if (mounted) {
        setState(() {
          _userProcess.add(ProcessItem(isChecked: false, processName: process));
        });
      }
    }

    final cleanSystemList =
        LinkedHashSet<String>.from(unmappedSystemProcess).toList();
    cleanSystemList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (var process in cleanSystemList) {
      if (mounted) {
        setState(() {
          _systemProcess
              .add(ProcessItem(isChecked: false, processName: process));
        });
      }
    }

    _isfetching = false;
  }

  void killProcess(String processName) async {
    const command = 'powershell.exe';
    final args = [
      '-ExecutionPolicy',
      'Unrestricted',
      '-Command',
      // ignore: prefer_interpolation_to_compose_strings
      'Get-WmiObject Win32_Process -Filter "name = \'' +
          processName +
          '\'" | ForEach-Object { \$_.Terminate() }'
    ];
    await runExecutableArguments(command, args);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(FGCOSLocalizations.of(context).taskKillerTitle),
        ),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 190,
          child: singleChildScrollView.SingleChildScrollView(
              child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 5, top: 5),
                  child:
                      Text(FGCOSLocalizations.of(context).taskKillerUserTasks),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _userProcess.length,
                itemBuilder: (context, index) {
                  return Material(
                    child: CheckboxListTile(
                      title: Text(_userProcess[index].processName),
                      value: _userProcess[index].isChecked,
                      onChanged: (newValue) {
                        setState(() {
                          _userProcess[index].isChecked = newValue!;
                        });
                      },
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 5, top: 15),
                  child: Text(
                    FGCOSLocalizations.of(context)
                        .taskKillerSystemTasksLabel
                        .toString(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _systemProcess.length,
                itemBuilder: (context, index) {
                  return Material(
                    child: CheckboxListTile(
                      title: Text(_systemProcess[index].processName),
                      value: _systemProcess[index].isChecked,
                      onChanged: (newValue) {
                        setState(() {
                          _systemProcess[index].isChecked = newValue!;
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          )),
        ),
        SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  getProcesses();
                });
              },
              icon: Icon(
                Icons.refresh,
                size: 20,
              ),
              label: Text('Refresh')),
          SizedBox(width: 5),
          ElevatedButton.icon(
              onPressed: () {
                dialog.showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    var systemSelected =
                        _systemProcess.any((element) => element.isChecked);
                    var userSelected =
                        _userProcess.any((element) => element.isChecked);

                    if (!systemSelected && !userSelected) {
                      return dialog.AlertDialog(
                          title: Text(FGCOSLocalizations.of(context)
                              .taskKillerKillButton),
                          content: Text(FGCOSLocalizations.of(context)
                              .taskKillerCheckatLeastOne),
                          actions: [
                            textButton.TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child:
                                  Text(FGCOSLocalizations.of(context).okButton),
                            ),
                          ]);
                    } else {
                      return dialog.AlertDialog(
                          title: Text(FGCOSLocalizations.of(context)
                              .taskKillerKillButton),
                          content: Text(FGCOSLocalizations.of(context)
                              .taskKillerWarningMessage),
                          actions: [
                            textButton.TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                  FGCOSLocalizations.of(context).cancelString),
                            ),
                            textButton.TextButton(
                              onPressed: () {
                                for (var process in _systemProcess) {
                                  if (process.isChecked) {
                                    killProcess(
                                        process.processName.split(' - ')[2]);
                                  }
                                }
                                for (var process in _userProcess) {
                                  if (process.isChecked) {
                                    killProcess(
                                        process.processName.split(' - ')[1]);
                                  }
                                }
                                Navigator.of(context).pop();
                                Future.delayed(Duration(seconds: 2), () {
                                  setState(() {
                                    getProcesses();
                                  });
                                });
                              },
                              child: Text(FGCOSLocalizations.of(context)
                                  .taskKillerConfirmToKill),
                            ),
                          ]);
                    }
                  },
                );
              },
              icon: Icon(
                Icons.dangerous,
                size: 20,
              ),
              label: Text(FGCOSLocalizations.of(context).taskKillerKillButton)),
        ])
      ],
    );
  }
}
