import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // 初始化資料庫
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  // 初始化資料庫並創建表格
  initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_system.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      // 創建菜單表格
      await db.execute('''
      CREATE TABLE menu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        image_url TEXT,
        category TEXT
      );
      ''');

      // 創建訂單表格
      await db.execute('''
      CREATE TABLE orders (
        order_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        total_price REAL,
        status TEXT,
        timestamp TEXT
      );
      ''');

      // 創建訂單項目表格
      await db.execute('''
      CREATE TABLE order_items (
        order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        menu_item_id INTEGER,
        quantity INTEGER,
        ice TEXT,
        sugar_level TEXT,
        temperature TEXT,
        price REAL,
        FOREIGN KEY(order_id) REFERENCES orders(order_id),
        FOREIGN KEY(menu_item_id) REFERENCES menu(id)
      );
      ''');
    });
  }

  // 插入菜單項目
  Future<void> insertMenuItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('menu', item);
  }

  // 獲取菜單項目
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final db = await database;
    return await db.query('menu');
  }

  // 插入訂單
  Future<void> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    await db.insert('orders', order);
  }

  // 插入訂單項目
  Future<void> insertOrderItem(Map<String, dynamic> orderItem) async {
    final db = await database;
    await db.insert('order_items', orderItem);
  }

  // 更新訂單狀態
  Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': status, 'timestamp': DateTime.now().toIso8601String()},
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // 獲取訂單資訊
  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.query('orders');
  }
}
