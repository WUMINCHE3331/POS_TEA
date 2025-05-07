import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart'; // 用於日期格式化

class DatabaseHelper {
  static Database? _database;
  String getStartOfDay(DateTime date) {
    // 返回日期的開始時間（00:00:00）
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 00:00:00';
  }

  String getEndOfDay(DateTime date) {
    // 返回日期的結束時間（23:59:59）
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 23:59:59';
  }

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
            price INTEGER,
            category TEXT
          );
          ''');

        // 創建訂單表格
        await db.execute('''
            CREATE TABLE IF NOT EXISTS orders (
              order_id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_no TEXT,
              total_price INTEGER,
              received_cash INTEGER,
              change INTEGER,
              payment_method TEXT,
              pickup_method TEXT,
              order_status TEXT,
              order_creation_time TEXT,
              modify_time TEXT
            );
            ''');

        // 創建訂單項目表格
        await db.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
          order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER,
          menu_item_id INTEGER,
          quantity INTEGER,
          price INTEGER,
          options TEXT,          -- 儲存為 JSON 格式的選項
          ice TEXT,              -- 冰塊設定
          sugar_level TEXT,      -- 糖度設定
          eco_cup TEXT,          -- 是否選擇環保杯
          FOREIGN KEY(order_id) REFERENCES orders(order_id),
          FOREIGN KEY(menu_item_id) REFERENCES menu(id)
        );
      ''');

        // 創建選項表格
        await db.execute('''
          CREATE TABLE IF NOT EXISTS options (
            option_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price INTEGER,
            type TEXT,
            selected BOOLEAN DEFAULT false
          );
          ''');

        // 創建單號
        await db.execute('''
            CREATE TABLE IF NOT EXISTS order_numbers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            last_order_no INTEGER NOT NULL
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

  // 獲取最新的 order_number（last_order_no）
  Future<String> getLatestOrderNumber() async {
    final db = await database;

    // 查詢 order_numbers 表格，根據日期取得最新的一筆資料
    List<Map<String, dynamic>> result = await db.query(
      'order_numbers', // 資料表名稱
      columns: ['last_order_no'], // 查詢 last_order_no
      orderBy: 'date DESC', // 根據日期降冪排序
      limit: 1, // 只取最新的紀錄
    );

    if (result.isNotEmpty) {
      int orderNumber = result[0]['last_order_no'] as int;
      // 將 orderNumber 補滿四位數，若不足四位數則補零
      return orderNumber.toString().padLeft(4, '0');
    } else {
      return '0000'; // 如果沒有資料，則返回 0 或其他適當的初始值
    }
  }

  // 獲取當天的單號並更新
  Future<String> generateOrderNumber() async {
    final db = await database;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 查詢今天的單號紀錄
    var result = await db.query(
      'order_numbers',
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );

    int lastOrderNo = 0;

    if (result.isNotEmpty) {
      // 如果今天有紀錄，則從資料庫中取得最後的單號
      lastOrderNo = result.first['last_order_no'] as int;
    }

    // 更新單號，累加
    lastOrderNo += 1;

    // 儲存或更新單號
    if (result.isEmpty) {
      // 如果今天沒有紀錄，插入新的紀錄
      await db.insert('order_numbers', {
        'date': today,
        'last_order_no': lastOrderNo,
      });
    } else {
      // 如果今天已有紀錄，更新單號
      await db.update(
        'order_numbers',
        {'last_order_no': lastOrderNo},
        where: 'date = ?',
        whereArgs: [today],
      );
    }

    // 格式化單號為 4 位數
    return lastOrderNo.toString().padLeft(4, '0');
  }

  // 插入菜單項目
  Future<void> insertMenuItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('menu', item);
  }

  Future<List<Map<String, dynamic>>> getDailySales(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT   order_creation_time , SUM(total_price) AS total_sales
    FROM orders
    WHERE order_date BETWEEN ? AND ?
    GROUP BY   order_creation_time 
    ORDER BY   order_creation_time 
  ''',
      [startDate, endDate],
    );
  }

  // 獲取所有菜單項目
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final db = await database;
    return await db.query('menu');
  }

  // 獲取所有
  Future<List<Map<String, dynamic>>> getOptions() async {
    final db = await database;
    return await db.query('options');
  }

  // 根據菜單名稱查找對應的 menu_item_id
  Future<int> getMenuItemIdByName(String menuItemName) async {
    final db = await database;

    // 查詢菜單表格，根據菜單名稱過濾
    var result = await db.query(
      'menu',
      where: 'name = ?',
      whereArgs: [menuItemName],
      limit: 1, // 只需要一條資料
    );

    if (result.isNotEmpty) {
      // 返回對應菜單項目的 ID
      return result.first['id'] as int;
    }

    // 如果找不到對應的菜單項目，則返回 -1 或適當的錯誤值
    return -1;
  }

  Future<int> insertOrderWithItems(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> orderItems,
  ) async {
    final db = await database;

    return await db.transaction((txn) async {
      // 插入訂單
      int orderId = await txn.insert('orders', order);

      // 插入每個訂單項目
      for (var item in orderItems) {
        item['order_id'] = orderId;
        await txn.insert('order_items', item);
      }

      return orderId; // 返回訂單 ID
    });
  }

  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;

    // 插入訂單，並獲得生成的 order_id
    int orderId = await db.insert('orders', order);

    return orderId; // 返回插入的 order_id
  }

  Future<void> insertOrderItems(
    int orderId,
    List<Map<String, dynamic>> orderItems,
  ) async {
    final db = await database;

    // 為每個訂單項目插入
    for (var item in orderItems) {
      // 將 order_id 加入每個訂單項目
      item['order_id'] = orderId;

      // 插入訂單項目
      await db.insert('order_items', item);
    }
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
      {'status': status, 'timestamp': DateTime.now().toIso8601String()},
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

  Future<List<Map<String, dynamic>>> getTotalSales(
    String startDate, // 例如 '2025-05-05'
    String endDate, // 例如 '2025-05-05'
  ) async {
    final db = await database;

    print("查詢區間：$startDate ~ $endDate");
    return await db.rawQuery(
      '''
    SELECT SUM(total_price) AS total_sales
    FROM orders
    WHERE order_creation_time BETWEEN ? AND ?
    ''',
      [startDate, endDate],
    );
  }

  // 查詢每個商品的銷售數量與金額：
  Future<List<Map<String, dynamic>>> getSalesByProduct(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT oi.menu_item_id, mi.name, SUM(oi.quantity) AS total_quantity, SUM(oi.price * oi.quantity) AS total_sales
    FROM order_items oi
    JOIN menu mi ON oi.menu_item_id = mi.id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.  order_creation_time  BETWEEN ? AND ?
    GROUP BY oi.menu_item_id
  ''',
      [startDate, endDate],
    );
  }

  // 查詢每種支付方式的統計
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod(
    String startDate,
    String endDate,
  ) async {
   
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT payment_method, SUM(total_price) AS total_sales, COUNT(*) AS total_count
    FROM orders
    WHERE order_creation_time BETWEEN ? AND ?
    GROUP BY payment_method
  ''',
      [startDate, endDate],
    );
  }

  Future<List<Map<String, dynamic>>> getHourlySales(
    String startDate,
    String endDate,
  ) async {
    final db = await database;

    print("查詢區間：$startDate ~ $endDate");
    // 執行 SQL 查詢，查詢每小時的銷售額
    return await db.rawQuery(
      '''
    SELECT strftime('%H', order_creation_time) AS hour, SUM(total_price) AS total_sales
    FROM orders
    WHERE order_creation_time BETWEEN ? AND ?
    GROUP BY hour
    ORDER BY hour
  ''',
      [startDate, endDate],
    );
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
  {'name': '拿鐵1', 'category': '飲品', 'price': 120},
  {'name': '摩卡1', 'category': '飲品', 'price': 130},
  {'name': '卡布奇諾1', 'category': '飲品', 'price': 125},
  {'name': '冰茶1', 'category': '飲品', 'price': 80},
  {'name': '巧克力蛋糕1', 'category': '甜點', 'price': 100},
  {'name': '藍莓松餅1', 'category': '甜點', 'price': 95},
  {'name': '蘋果派1', 'category': '甜點', 'price': 90},
  {'name': '雞肉沙拉1', 'category': '飲品', 'price': 150},
  {'name': '鮮榨橙汁1', 'category': '飲品', 'price': 90},
  {'name': '蔬菜沙拉1', 'category': '飲品', 'price': 120},
  {'name': '雞胸肉沙拉1', 'category': '飲品', 'price': 140},
  {'name': '鮮榨葡萄柚汁1', 'category': '飲品', 'price': 85},
  {'name': '煙燻三文魚沙拉1', 'category': '飲品1', 'price': 180},
  {'name': '雞肉沙拉1', 'category': '飲品2', 'price': 150},
  {'name': '鮮榨橙汁1', 'category': '飲品3', 'price': 90},
  {'name': '蔬菜沙拉1', 'category': '飲品4', 'price': 120},
  {'name': '雞胸肉沙拉1', 'category': '飲品5', 'price': 140},
  {'name': '鮮榨葡萄柚汁1', 'category': '飲品6', 'price': 85},
  {'name': '煙燻三文魚沙拉1', 'category': '飲品7', 'price': 180},
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
