import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_task/models/task.dart';
import 'package:pocket_task/widgets/progress_indicator.dart';

enum TaskFilter { all, active, done }

class PocketTasksScreen extends StatefulWidget {
  const PocketTasksScreen({super.key});

  @override
  State<PocketTasksScreen> createState() => _PocketTasksScreenState();
}

class _PocketTasksScreenState extends State<PocketTasksScreen> {
  final List<Task> _tasks = [
    Task(title: "Buy groceries", isDone: true),
    Task(title: "Walk the dog"),
    Task(title: "Call Nitish"),
  ];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = "";
  Timer? _debounce;
  String? _errorText;

  static const String storageKey = "pocket_tasks_v1";

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _searchQuery = _searchController.text;
        });
      });
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(storageKey);
    if (jsonString != null) {
      final decoded = jsonDecode(jsonString) as List;
      setState(() {
        _tasks.clear();
        _tasks.addAll(decoded.map((e) => Task.fromJson(e)));
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(storageKey, jsonString);
  }

  void _addTask() {
    if (_taskController.text.trim().isEmpty) {
      setState(() {
        _errorText = "Task title cannot be empty";
      });
      return;
    }
    setState(() {
      _tasks.add(Task(title: _taskController.text.trim()));
      _taskController.clear();
      _errorText = null;
    });
    _saveTasks();
  }

  void _toggleTask(Task task) {
    final index = _tasks.indexOf(task);
    setState(() {
      task.isDone = !task.isDone;
    });
    _saveTasks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(task.isDone ? "Task marked done" : "Task marked active"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() {
              _tasks[index].isDone = !task.isDone;
            });
            _saveTasks();
          },
        ),
      ),
    );
  }

  void _deleteTask(Task task) {
    final index = _tasks.indexOf(task);
    setState(() {
      _tasks.remove(task);
    });
    _saveTasks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Task deleted"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() {
              _tasks.insert(index, task);
            });
            _saveTasks();
          },
        ),
      ),
    );
  }

  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      switch (_filter) {
        case TaskFilter.active:
          return matchesSearch && !task.isDone;
        case TaskFilter.done:
          return matchesSearch && task.isDone;
        case TaskFilter.all:
          return matchesSearch;
      }
    }).toList();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CustomProgressIndicator(
                    completed: _tasks.where((t) => t.isDone).length,
                    total: _tasks.length,
                  ),
                  SizedBox(width: 30),
                  const Text(
                    "PocketTasks",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // Add Task Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: "Add Task",
                        errorText: _errorText,
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_taskController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid Task')),
                        );
                        return;
                      }
                      _addTask(); 
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task Added')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                    child: const Text(
                      "Add",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Box
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search Task",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("All"),
                    selected: _filter == TaskFilter.all,
                    onSelected: (_) => setState(() => _filter = TaskFilter.all),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Active"),
                    selected: _filter == TaskFilter.active,
                    onSelected:
                        (_) => setState(() => _filter = TaskFilter.active),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Done"),
                    selected: _filter == TaskFilter.done,
                    onSelected:
                        (_) => setState(() => _filter = TaskFilter.done),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Task List
              Expanded(
                child:
                    _filteredTasks.isEmpty
                        ? const Center(
                          child: Text(
                            "No tasks found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return Dismissible(
                              key: ValueKey(task.id),
                              background: Container(
                                color: Colors.redAccent,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteTask(task),
                              child: ListTile(
                                leading: IconButton(
                                  icon: Icon(
                                    task.isDone
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        task.isDone
                                            ? Colors.greenAccent
                                            : Colors.white54,
                                  ),
                                  onPressed: () => _toggleTask(task),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    decoration:
                                        task.isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
