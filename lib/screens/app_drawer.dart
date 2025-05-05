// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.brown),
            child: Text('功能選單', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('業績查詢'),
            onTap: () {
              Navigator.pop(context); // 關閉 Drawer
              // 可在此跳轉至業績查詢頁面
              Navigator.pushNamed(context, '/performance');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('登出'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 登出邏輯
            },
          ),
        ],
      ),
    );
  }
}
