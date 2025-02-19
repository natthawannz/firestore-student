import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Database',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  void showAddStudentDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController studentIdController = TextEditingController();
    TextEditingController branchController = TextEditingController();
    TextEditingController yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เพิ่มข้อมูลนักศึกษา'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'ชื่อ')),
              TextField(controller: studentIdController, decoration: const InputDecoration(labelText: 'รหัสนักศึกษา')),
              TextField(controller: branchController, decoration: const InputDecoration(labelText: 'สาขา')),
              TextField(controller: yearController, decoration: const InputDecoration(labelText: 'ชั้นปี'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    studentIdController.text.isNotEmpty &&
                    branchController.text.isNotEmpty &&
                    yearController.text.isNotEmpty) {
                  FirebaseFirestore.instance.collection('students').add({
                    'name': nameController.text.trim(),
                    'student-id': studentIdController.text.trim(),
                    'branch': branchController.text.trim(),
                    'year': yearController.text.trim(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Database')),
      body: const FirestoreData(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddStudentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FirestoreData extends StatelessWidget {
  const FirestoreData({super.key});

  void editStudent(BuildContext context, String id, Map<String, dynamic> studentData) {
    TextEditingController nameController = TextEditingController(text: studentData['name']);
    TextEditingController studentIdController = TextEditingController(text: studentData['student-id']);
    TextEditingController branchController = TextEditingController(text: studentData['branch']);
    TextEditingController yearController = TextEditingController(text: studentData['year']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูลนักศึกษา'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'ชื่อ')),
              TextField(controller: studentIdController, decoration: const InputDecoration(labelText: 'รหัสนักศึกษา')),
              TextField(controller: branchController, decoration: const InputDecoration(labelText: 'สาขา')),
              TextField(controller: yearController, decoration: const InputDecoration(labelText: 'ชั้นปี')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('students').doc(id).update({
                  'name': nameController.text.trim(),
                  'student-id': studentIdController.text.trim(),
                  'branch': branchController.text.trim(),
                  'year': yearController.text.trim(),
                });
                Navigator.pop(context);
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  void deleteStudent(String id) {
    FirebaseFirestore.instance.collection('students').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('โหลดข้อมูลผิดพลาด'));
        }

        final data = snapshot.data?.docs ?? [];

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final student = data[index].data();
            final studentId = data[index].id;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('${student['name']} (ชั้นปี ${student['year']})'),
                subtitle: Text('รหัส: ${student['student-id']} | สาขา: ${student['branch']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => editStudent(context, studentId, student),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteStudent(studentId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
