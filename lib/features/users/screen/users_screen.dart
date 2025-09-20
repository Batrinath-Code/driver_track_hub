// features/users/screens/users_screen.dart
import 'package:driver_tracker_app/features/users/controller/users_controller.dart';
import 'package:driver_tracker_app/features/users/screen/add_edit_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_tracker_app/data/models/user_model.dart' as local;

class UsersScreen extends StatelessWidget {
  final UsersController usersController = Get.put(UsersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Users')),
      body: Obx(() {
        if (usersController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else {
          return ListView.builder(
            itemCount: usersController.users.length,
            itemBuilder: (context, index) {
              local.User user = usersController.users[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name.substring(0, 1).toUpperCase()),
                    // You can load profileImage if available
                  ),
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${user.email}'),
                      Text('Role: ${user.role}'),
                      Text('Status: ${user.status}'),
                      if (user.phoneNumber != null)
                        Text('Phone: ${user.phoneNumber}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (String result) {
                      switch (result) {
                        case 'edit':
                          Get.to(() => AddEditUserScreen(userToEdit: user));
                          break;
                        case 'delete':
                          usersController.deleteUser(user.uid);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddEditUserScreen());
        },
        tooltip: 'Add User',
        child: Icon(Icons.add),
      ),
    );
  }
}
