import 'package:process_run/process_run.dart';

void getProcesses() async {
  final results = await runExecutableArguments('tasklist', []);
  final processes = results.stdout.split('\n');
  List<String> processList = processes.sublist(2, processes.length - 1);
  print(processList);
}

class ProcessItem {
  bool isChecked = false;
  String processName = '';
  ProcessItem({required this.isChecked, required this.processName});
}
