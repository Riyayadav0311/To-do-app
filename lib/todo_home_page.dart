import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'package:lottie/lottie.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final _taskBox = Hive.box<Task>('tasks');
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deleteOldTasks();
  }

  void _deleteOldTasks() {
    final now = DateTime.now();
    for (var task in _taskBox.values.toList()) {
      if (now.difference(task.createdDate).inDays >= 1) {
        task.delete();
      }
    }
  }

  void _addTask(String title) {
    if (title.isEmpty) return;
    _taskBox.add(Task(title: title, createdDate: DateTime.now()));
    _controller.clear();
  }

  void _toggleTask(Task task) {
    setState(() {
      task.isDone = !task.isDone;
      task.save();
      if (task.isDone) {
        _showCongratsPopup(); // Show animation when completed
      }
    });
  }

  void _showCongratsPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/animation/congrats.json', height: 150),
            const SizedBox(height: 10),
            const Text(
              'Wow! You did it! 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
     if(context.mounted){
      Navigator.of(context).pop();
      }
    }); 
  }

  void _deleteTask(Task task) {
    task.delete();
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        "📝 Add your tasks for today!",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Tasks")),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _taskBox.listenable(),
              builder: (context, Box<Task> box, _) {
                if (box.values.isEmpty) {
                  return const Center(child: Text("No tasks yet!"));
                }
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final task = box.getAt(index)!;
                    return ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: task.isDone,
                        onChanged: (_) => _toggleTask(task),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black),
                        onPressed: () => _deleteTask(task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
       
        backgroundColor: const Color(0xFFE3F2FD),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Task"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "Enter task title"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addTask(_controller.text);
              Navigator.of(context).pop();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
