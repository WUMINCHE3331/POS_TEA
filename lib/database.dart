import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // 初始化資料庫
  Future<Database> get database async {
    if (_database != null) return _database!;
    print("初始化資料庫...");
    _database = await initDatabase();
    print("資料庫連線成功！");  
    return _database!;
  }

  // 初始化資料庫並創建表格
  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_system.db');
    print("資料庫路徑: $path");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print("正在創建表格...");

        // 創建菜單表格
        await db.execute('''
        CREATE TABLE IF NOT EXISTS menu (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          price REAL,
          category TEXT
        );
        ''');

        // 創建訂單表格
        await db.execute('''
        CREATE TABLE IF NOT EXISTS orders (
          order_id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_name TEXT,
          total_price REAL,
          received_cash REAL,
          change REAL,
          payment_method TEXT,
          pickup_method TEXT,
          order_status TEXT,
          order_creation_time TEXT,
          status TEXT,
          timestamp TEXT
        );
        ''');

        // 創建訂單項目表格
        await db.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
          order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER,
          menu_item_id INTEGER,
          quantity INTEGER,
          price REAL,
          FOREIGN KEY(order_id) REFERENCES orders(order_id),
          FOREIGN KEY(menu_item_id) REFERENCES menu(id)
        );
        ''');

        // 創建選項表格
        await db.execute('''
        CREATE TABLE IF NOT EXISTS options (
          option_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          price REAL,
          type TEXT,
          selected BOOLEAN DEFAULT FALSE
        );
        ''');

        // 創建訂單項目選項表
        await db.execute('''
        CREATE TABLE IF NOT EXISTS order_item_options (
          order_item_id INTEGER,
          option_id INTEGER,
          selected BOOLEAN DEFAULT FALSE,
          FOREIGN KEY(order_item_id) REFERENCES order_items(order_item_id),
          FOREIGN KEY(option_id) REFERENCES options(option_id)
        );
        ''');

        // 插入預設資料
        await _insertDefaultData(db);
      },
    );
  }

  // 插入預設資料（只在資料庫為空時執行）
  Future<void> _insertDefaultData(Database db) async {
    try {
      // 檢查菜單表格是否有資料
      var menuResult = await db.query('menu');
      if (menuResult.isEmpty) {
        for (var item in menuItems) {
          await db.insert('menu', item);
        }
        print('菜單資料插入成功！');
      } else {
        print('菜單表格已經存在資料！');
      }

      // 檢查選項表格是否有資料
      var optionsResult = await db.query('options');
      if (optionsResult.isEmpty) {
        for (var option in options) {
          await db.insert('options', option);
        }
        print('選項資料插入成功！');
      } else {
        print('選項表格已經存在資料！');
      }
    } catch (e) {
      print("插入預設資料失敗: $e");
    }
  }

  // ======= 操作函式區 =======

  // 插入菜單項目
  Future<void> insertMenuItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('menu', item);
  }

  // 獲取所有菜單項目
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final db = await database;
    return await db.query('menu');
  }

  // 插入訂單
  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('orders', order);
  }

  // 插入訂單項目
  Future<int> insertOrderItem(Map<String, dynamic> orderItem) async {
    final db = await database;
    return await db.insert('order_items', orderItem);
  }

  // 插入選項
  Future<void> insertOption(Map<String, dynamic> option) async {
    final db = await database;
    await db.insert('options', option);
  }

  // 插入訂單項目選項
  Future<void> insertOrderItemOption(Map<String, dynamic> itemOption) async {
    final db = await database;
    await db.insert('order_item_options', itemOption);
  }

  // 更新訂單狀態
  Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // 獲取所有訂單
  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.query('orders');
  }

  // 驗證使用者登入
  Future<bool> login(String userId, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'user_id = ? AND password = ?',
      whereArgs: [userId, password],
    );
    return result.isNotEmpty;
  }
}

List<Map<String, dynamic>> menuItems = [
  {'name': '拿鐵', 'category': '飲品', 'price': 120},
  {'name': '摩卡', 'category': '飲品', 'price': 130},
  {'name': '卡布奇諾', 'category': '飲品', 'price': 125},
  {'name': '冰茶', 'category': '飲品', 'price': 80},
  {'name': '巧克力蛋糕', 'category': '甜點', 'price': 100},
  {'name': '藍莓松餅', 'category': '甜點', 'price': 95},
  {'name': '蘋果派', 'category': '甜點', 'price': 90},
  {'name': '雞肉沙拉', 'category': '沙拉', 'price': 150},
  {'name': '鮮榨橙汁', 'category': '飲品', 'price': 90},
  {'name': '蔬菜沙拉', 'category': '沙拉', 'price': 120},
  {'name': '雞胸肉沙拉', 'category': '沙拉', 'price': 140},
  {'name': '鮮榨葡萄柚汁', 'category': '飲品', 'price': 85},
  {'name': '煙燻三文魚沙拉', 'category': '沙拉', 'price': 180},
  {'name': '卡士達蛋糕', 'category': '甜點', 'price': 110},
  {'name': '藍莓果昔', 'category': '飲品', 'price': 95},
  {'name': '綜合水果沙拉', 'category': '沙拉', 'price': 130},
  {'name': '冰拿鐵', 'category': '飲品', 'price': 130},
  {'name': '抹茶蛋糕', 'category': '甜點', 'price': 105},
  {'name': '鮮果冰沙', 'category': '飲品', 'price': 110},
  {'name': '紅豆抹茶冰淇淋', 'category': '甜點', 'price': 85},
  {'name': '起司蛋糕', 'category': '甜點', 'price': 95},
  {'name': '檸檬茶', 'category': '飲品', 'price': 75},
  {'name': '焦糖布丁', 'category': '甜點', 'price': 100},
  {'name': '美式咖啡', 'category': '飲品', 'price': 100},
  {'name': '牛油果沙拉', 'category': '沙拉', 'price': 160},
  {'name': '草莓慕斯', 'category': '甜點', 'price': 105},
  {'name': '綠茶冰沙', 'category': '飲品', 'price': 95},
  {'name': '香草冰淇淋', 'category': '甜點', 'price': 80},
  {'name': '海鮮沙拉', 'category': '沙拉', 'price': 200},
  {'name': '瑪奇朵', 'category': '飲品', 'price': 135},
  {'name': '鮮榨蘋果汁', 'category': '飲品', 'price': 85},
];

List<Map<String, dynamic>> options = [
  {'name': '正常冰', 'price': 0, 'type': 'ice', 'selected': false},
  {'name': '微冰', 'price': 0, 'type': 'ice', 'selected': false},
  {'name': '少冰', 'price': 0, 'type': 'ice', 'selected': false},
  {'name': '去冰', 'price': 0, 'type': 'ice', 'selected': false},
  {'name': '常溫', 'price': 0, 'type': 'ice', 'selected': false},
  {'name': '溫熱', 'price': 0, 'type': 'ice', 'selected': false},
  {'name': '熱', 'price': 0, 'type': 'ice', 'selected': false},
  {'name': '正常糖', 'price': 0, 'type': 'sugar', 'selected': false},
  {'name': '少糖', 'price': 1, 'type': 'sugar', 'selected': false},
  {'name': '微糖', 'price': 1, 'type': 'sugar', 'selected': false},
  {'name': '無糖', 'price': 0, 'type': 'sugar', 'selected': false},
  {'name': '環保杯', 'price': -5, 'type': 'eco_cup', 'selected': false},
  {'name': '珍珠', 'price': 10, 'type': 'topping', 'selected': false},
  {'name': '椰果', 'price': 10, 'type': 'topping', 'selected': false},
];
