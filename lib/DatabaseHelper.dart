import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';

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
            price INTEGER,
            category TEXT
          );
          ''');

        // 創建訂單表格
        await db.execute('''
            CREATE TABLE IF NOT EXISTS orders (
              order_id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_name TEXT,
              total_price INTEGER,
              received_cash INTEGER,
              change INTEGER,
              payment_method TEXT,
              pickup_method TEXT,
              order_status TEXT,
              order_creation_time TEXT,
              status TEXT,
              timestamp TEXT
            );
            ''');

        // // 創建訂單項目表格
        // await db.execute('''
        // CREATE TABLE IF NOT EXISTS order_items (
        //   order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        //   order_id INTEGER,
        //   menu_item_id INTEGER,
        //   quantity INTEGER,
        //   price INTEGER,
        //   FOREIGN KEY(order_id) REFERENCES orders(order_id),
        //   FOREIGN KEY(menu_item_id) REFERENCES menu(id)
        // );
        // ''');

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

        // // 創建訂單項目選項表
        // await db.execute('''
        // CREATE TABLE IF NOT EXISTS order_item_options (
        //   order_item_id INTEGER,
        //   option_id INTEGER,
        //   selected BOOLEAN DEFAULT false,
        //   FOREIGN KEY(order_item_id) REFERENCES order_items(order_item_id),
        //   FOREIGN KEY(option_id) REFERENCES options(option_id)
        // );
        // ''');

        // 插入預設資料
        await _insertDefaultData(db);
      },
    );
  }

//   Future<void> insertOrderWithItems(
//     Map<String, dynamic> orderDetails, List<Map<String, dynamic>> orderItems) async {
//   final db = await database;

//   try {
//     await db.transaction((txn) async {
//       // 插入訂單，並獲得訂單 ID
//       int orderId = await txn.insert('orders', orderDetails);
//       print('訂單 ID: $orderId');

//       // 迭代插入訂單項目
//       for (var order in orderItems) {
//         print('訂單項目 options: ${order['options']}');
//         // 如果 options 是空的，設置為空列表或某個預設值
//         if (order['options'] == null) {
//           order['options'] = [];
//         }
        
//         String optionsJson = json.encode(order['options']);
//         print('optionsJson: $optionsJson');

//         // 根據名稱找到對應的 menu_item_id
//         int menuItemId = await getMenuItemIdByName(order['name']);
//         print('菜單項目名稱: ${order['name']} 對應的 menu_item_id: $menuItemId');
        
//         if (menuItemId == -1) {
//           // 如果找不到對應的菜單項目，拋出異常，這將導致事務回滾
//           throw Exception('無法找到菜單項目: ${order['name']}');
//         }

//         // 移除不必要的欄位
//         order.remove('name');
//         order.remove('selected');

//         // 將訂單項目和其他欄位準備好
//         order['options'] = optionsJson;  // 將選項儲存為 JSON
//         order['menu_item_id'] = menuItemId;
//         order['order_id'] = orderId;  // 設置訂單 ID 關聯

//         // 插入訂單項目
//         await txn.insert('order_items', order);
//       }
//     });

//     print('✅ 訂單與訂單項目成功儲存');
//   } catch (e) {
//     print('❌ 在交易過程中發生錯誤: $e');
//     // 輸出更詳細的錯誤信息來幫助調試
//     print('錯誤詳細資料: ${e.toString()}');
//     throw e;  // 會觸發回滾
//   }
// }



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
