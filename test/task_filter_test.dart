import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_task/models/task.dart';

enum TaskFilter { all, active, done }

List<Task> filterTasks(List<Task> tasks, String query, TaskFilter filter) {
  return tasks.where((task) {
    final matchesSearch = task.title.toLowerCase().contains(query.toLowerCase());
    switch (filter) {
      case TaskFilter.active:
        return matchesSearch && !task.isDone;
      case TaskFilter.done:
        return matchesSearch && task.isDone;
      case TaskFilter.all:
        return matchesSearch;
    }
  }).toList();
}

void main() {
  final tasks = [
    Task(title: "Buy milk", isDone: false),
    Task(title: "Walk dog", isDone: true),
    Task(title: "Call mom", isDone: false),
  ];

  test("Filter: All shows all matching tasks", () {
    final result = filterTasks(tasks, "", TaskFilter.all);
    expect(result.length, 3);
  });

  test("Filter: Active shows only active tasks", () {
    final result = filterTasks(tasks, "", TaskFilter.active);
    expect(result.every((t) => !t.isDone), true);
  });

  test("Filter: Done shows only completed tasks", () {
    final result = filterTasks(tasks, "", TaskFilter.done);
    expect(result.every((t) => t.isDone), true);
  });

  test("Search filters by title", () {
    final result = filterTasks(tasks, "milk", TaskFilter.all);
    expect(result.length, 1);
    expect(result.first.title, "Buy milk");
  });
}
