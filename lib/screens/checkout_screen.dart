import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Map<String, dynamic>> filteredMenuItems = [];
  @override
  void initState() {
    super.initState();
    // 初始化 filteredMenuItems，根據預設的分類過濾菜單項目
    filteredMenuItems =
        menuItems
            .where((item) => item['category'] == selectedCategory)
            .toList();
  }

  List<Map<String, dynamic>> menuItems = [
    {'name': '拿鐵232', 'category': '飲品', 'price': 5},
    {'name': '摩卡', 'category': '飲品', 'price': 6},
    {'name': '卡布奇諾', 'category': '飲品', 'price': 5},
    {'name': '冰茶', 'category': '飲品', 'price': 3},
    {'name': '巧克力蛋糕', 'category': '甜點', 'price': 4},
    {'name': '藍莓松餅', 'category': '甜點', 'price': 4},
    {'name': '蘋果派', 'category': '甜點', 'price': 3},
    {'name': '雞肉沙拉', 'category': '沙拉', 'price': 6},
    {'name': '鮮榨果汁', 'category': '飲品', 'price': 4},
    {'name': '蔬菜沙拉', 'category': '沙拉1', 'price': 5},
    {'name': '雞肉沙拉', 'category': '沙拉2', 'price': 6},
    {'name': '鮮榨果汁', 'category': '飲品3', 'price': 4},
    {'name': '蔬菜沙拉', 'category': '沙拉4', 'price': 5},
    {'name': '雞肉沙拉', 'category': '沙拉5', 'price': 6},
    {'name': '鮮榨果汁', 'category': '飲品6', 'price': 4},
    {'name': '蔬菜沙拉', 'category': '沙拉7', 'price': 5},
    {'name': '雞肉沙拉', 'category': '沙拉2', 'price': 6},
    {'name': '鮮榨果汁', 'category': '飲品3', 'price': 4},
    {'name': '蔬菜沙拉', 'category': '沙拉4', 'price': 5},
    {'name': '雞肉沙拉', 'category': '沙拉5', 'price': 6},
    {'name': '鮮榨果汁', 'category': '飲品6', 'price': 4},
    {'name': '蔬菜沙拉', 'category': '沙拉7', 'price': 5},
    {'name': '雞肉沙拉', 'category': '沙拉2', 'price': 6},
    {'name': '鮮榨果汁', 'category': '飲品3', 'price': 4},
    {'name': '蔬菜沙拉', 'category': '沙拉4', 'price': 5},
    {'name': '雞肉沙拉', 'category': '沙拉5', 'price': 6},
    {'name': '鮮榨果汁', 'category': '飲品6', 'price': 4},
    {'name': '蔬菜沙拉', 'category': '沙拉7', 'price': 5},
  ];

  // 設置選中的訂單項目，並更新客製化UI
  void setSelectedOrderItem(Map<String, dynamic> item) {
    setState(() {
      selectedOrderItem = item; // 保存選中的訂單項目
      print('選中的訂單項目: $selectedOrderItem');
      // 更新UI（例如：選擇的糖度、冰塊等）
      updateCustomizationUI(selectedOrderItem);
    });
  }

  void updateCustomizationUI(Map<String, dynamic>? selectedItem) {
    if (selectedItem == null) return;

    // 清除所有選項的選中狀態
    for (var option in options) {
      option['selected'] = false;
    }

    // 定義各類型的欄位對應名稱
    Map<String, String> typeToField = {
      'sugar': 'sugar_level',
      'ice': 'ice',
      'eco_cup': 'eco_cup',
    };

    // 根據欄位內容更新選項
    for (var type in typeToField.keys) {
      String? value = selectedItem[typeToField[type]];
      if (value != null && value.isNotEmpty) {
        for (var option in options) {
          if (option['type'] == type && option['name'] == value) {
            option['selected'] = true;
            break;
          }
        }
      }
    }

    // 更新配料（例如椰果、珍珠等）
    if (selectedItem.containsKey('options')) {
      for (var selectedOpt in selectedItem['options']) {
        var matched = options.firstWhere(
          (opt) => opt['name'] == selectedOpt['name'],
          orElse: () => {},
        );
        if (matched.isNotEmpty) {
          matched['selected'] = true;
        }
      }
    }
  }

  // 合併所有客製化選項，包括冰塊、糖度和環保杯
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
    {'name': '環保杯', 'price': -5, 'type': 'eco_cup', 'selected': false}, // 環保杯選項
    {'name': '珍珠', 'price': 10, 'type': 'topping', 'selected': false},
    {'name': '椰果', 'price': 10, 'type': 'topping', 'selected': false},
  ];
  Map<String, dynamic>? selectedOrderItem;
  List<Map<String, dynamic>> orderItems = [];
  int currentItemIndex = -1; // 用於追蹤當前選擇的飲料
  // 計算總金額
  num get totalAmount {
    num total = 0;
    for (var item in orderItems) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  bool isOptionSelected(
    Map<String, dynamic> option,
    Map<String, dynamic> selectedOrder,
  ) {
    String type = option['type'];

    if (type == 'ice') {
      return selectedOrder['ice'] == option['name'];
    } else if (type == 'sugar') {
      return selectedOrder['sugar_level'] == option['name'];
    } else if (type == 'eco_cup') {
      return selectedOrder['eco_cup'] == '環保杯';
    } else if (type == 'topping') {
      return selectedOrder['options'].any(
        (opt) => opt['name'] == option['name'],
      );
    }

    return false;
  }

  // 添加飲料到訂單
  void _addToOrder(String name, int price) {
    setState(() {
      // 在添加新訂單之前，先清除所有訂單的選中狀態
      for (var item in orderItems) {
        item['selected'] = false; // 取消所有訂單項目的選中狀態
      }

      // 添加新訂單項目到 orderItems
      orderItems.add({
        'name': name,
        'quantity': 1,
        'price': price,
        'options': [], // 存儲客製選項的列表
        'ice': '', // 預設為空
        'sugar_level': '', // 預設為空
        'eco_cup': '', // 預設為空
        'selected': true, // 默認為選中狀態
      });

      // 更新當前選擇的飲料索引
      currentItemIndex = orderItems.length - 1; // 更新為新增的訂單項目索引

      // 打印新增訂單項目後的訂單列表
      print('新增訂單項目: {name: $name, price: $price }');
      print('當前訂單列表: $orderItems');
    });
  }

  // 存儲選中的訂單和選擇的客製化選項
  Map<String, dynamic>? selectedOrder;
  List<String> selectedOptions = []; // 儲存選擇的客製化選項

  String selectedCategory = '飲品';
  // 處理結帳
  void _placeOrder() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('訂單完成'),
            content: Text('總金額: \$${totalAmount.toStringAsFixed(2)}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('確定'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 將菜單按類別分組
    Map<String, List<Map<String, dynamic>>> groupedMenu = {};
    for (var item in menuItems) {
      if (groupedMenu.containsKey(item['category'])) {
        groupedMenu[item['category']]?.add(item);
      } else {
        groupedMenu[item['category']] = [item];
      }
    }

    return Scaffold(
      // appBar: AppBar(title: const Text('POS 結帳系統')),
      body: Row(
        children: [
          // 左側菜單區域
          Container(
            width: 900,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50], // 背景顏色
              borderRadius: BorderRadius.circular(20), // 設置圓角邊框
            ),
            margin: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顯示收銀、日期、時間和單號
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown, // 咖啡色底
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20), // 左上角圓角
                      topRight: Radius.circular(20), // 右上角圓角
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        '收銀: 0000',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ), // 白色字體
                      ),
                      Text(
                        '日期: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ), // 白色字體
                      ),
                      Text(
                        '時間: ${DateTime.now().toLocal().toString().split(' ')[1].split('.')[0]}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ), // 白色字體
                      ),
                      Text(
                        '單號: 123456789',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ), // 白色字體
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 10),
                // 顯示菜單區域：橫向滑動顯示
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent, // 咖啡色底
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20), // 左上角圓角
                      bottomRight: Radius.circular(20), // 右上角圓角
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // 水平滑動
                    child: Row(
                      children:
                          groupedMenu.keys.map((category) {
                            return Container(
                              margin: const EdgeInsets.only(right: 15),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedCategory = category; // 更新選中的分類
                                    print(category);
                                    filteredMenuItems =
                                        menuItems
                                            .where(
                                              (item) =>
                                                  item['category'] ==
                                                  selectedCategory,
                                            )
                                            .toList();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      selectedCategory == category
                                          ? Colors
                                              .brown // 如果是選中的分類，顯示咖啡色背景
                                          : Colors.grey[300], // 否則顯示灰色背景
                                  foregroundColor:
                                      selectedCategory == category
                                          ? Colors
                                              .white // 如果是選中的分類，顯示白色文字
                                          : Colors.black, // 否則顯示黑色文字
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),

                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 500), // 設置最大高度
                    // margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // 顯示菜單項目區域
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4, // 每行顯示4個項目
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.5,
                                ),
                            itemCount: filteredMenuItems.length,
                            itemBuilder: (context, index) {
                              var item = filteredMenuItems[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    _addToOrder(item['name'], item['price']);
                                    setSelectedOrderItem(item);
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 10),
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        '\$${item['price']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          height: 200, // 設置客製化區塊的高度為200
                          width: double.infinity, // 設置寬度為100%
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 0),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4, // 每行顯示4個選項
                                        crossAxisSpacing: 10, // 交叉間距
                                        mainAxisSpacing: 10, // 主軸間距
                                        childAspectRatio: 3, // 保持每個選項為正方形
                                      ),
                                  itemCount: options.length, // 項目數量
                                  itemBuilder: (context, index) {
                                    var option = options[index];

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          option['selected'] =
                                              !option['selected'];

                                          var selectedOrder = orderItems
                                              .firstWhere(
                                                (item) =>
                                                    item['selected'] == true,
                                              );

                                          if (selectedOrder == null) {
                                            print('⚠️ 沒有選中的飲料項目，無法設定客製化');
                                            return;
                                          }

                                          String type = option['type'];

                                          if (type != 'topping') {
                                            for (var opt in options.where(
                                              (opt) => opt['type'] == type,
                                            )) {
                                              if (opt != option) {
                                                opt['selected'] = false;
                                              }
                                            }
                                          }

                                          if (option['selected']) {
                                            if (type == 'ice') {
                                              selectedOrder['ice'] =
                                                  option['name'];
                                            } else if (type == 'sugar') {
                                              selectedOrder['sugar_level'] =
                                                  option['name'];
                                            } else if (type == 'eco_cup') {
                                              selectedOrder['eco_cup'] = '環保杯';
                                              selectedOrder['price'] -= 5;
                                            } else if (type == 'topping') {
                                              if (!selectedOrder['options'].any(
                                                (o) =>
                                                    o['name'] == option['name'],
                                              )) {
                                                selectedOrder['options'].add(
                                                  option,
                                                );
                                                selectedOrder['price'] +=
                                                    option['price'];
                                              }
                                            }
                                          } else {
                                            if (type == 'ice') {
                                              selectedOrder['ice'] = '';
                                            } else if (type == 'sugar') {
                                              selectedOrder['sugar_level'] = '';
                                            } else if (type == 'eco_cup') {
                                              selectedOrder['eco_cup'] = '';
                                              selectedOrder['price'] += 5;
                                            } else if (type == 'topping') {
                                              selectedOrder['options']
                                                  .removeWhere(
                                                    (o) =>
                                                        o['name'] ==
                                                        option['name'],
                                                  );
                                              selectedOrder['price'] -=
                                                  option['price'];
                                            }
                                          }

                                          // 印出目前的訂單狀態
                                          print(
                                            '🎯 目前作用在飲料: ${selectedOrder['name']}',
                                          );
                                          print(
                                            '🧊 冰量: ${selectedOrder['ice']}',
                                          );
                                          print(
                                            '🍬 甜度: ${selectedOrder['sugar_level']}',
                                          );
                                          print(
                                            '🛍️ 是否環保杯: ${selectedOrder['eco_cup']}',
                                          );
                                          print(
                                            '➕ 加料: ${selectedOrder['options'].map((e) => e['name'])}',
                                          );
                                          print(
                                            '💰 總價: ${selectedOrder['price']}',
                                          );
                                        });
                                      },

                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        elevation: 3, // 卡片陰影
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ), // 圓角方框
                                        ),
                                        color:
                                            option['selected']
                                                ? Colors.green[100] // 已選擇顯示為綠色
                                                : Colors.white, // 未選擇顯示為白色

                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 10),
                                            Icon(
                                              option['selected']
                                                  ? Icons
                                                      .check_circle // 已選擇顯示打勾
                                                  : Icons.circle, // 未選擇顯示圓圈
                                              color:
                                                  option['selected']
                                                      ? Colors
                                                          .green[800] // 已選擇顯示為綠色
                                                      : Colors.grey, // 未選擇顯示為灰色
                                            ),
                                            Text(
                                              option['name'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    Colors.black, // 文字顏色設置為黑色
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // const Divider(),

                // 顯示結帳按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _placeOrder,
                      child: const Text('確認結帳'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '訂單列表',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        var item = orderItems[index];
                        // 合併飲料的詳細選項：名稱、冰塊、糖度
                        String drinkDetails =
                            '${item['name']} ${item['ice'] ?? ''} ${item['sugar_level'] ?? ''} ${item['eco_cup'] ?? ''} ${item['topping'] ?? ''}';

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              // 清除其他訂單項目的選中狀態
                              for (var orderItem in orderItems) {
                                orderItem['selected'] = false; // 取消所有選項的選中狀態
                              }

                              // 設置當前點擊的項目為選中
                              item['selected'] = true;
                              setSelectedOrderItem(item);
                            });
                          },

                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color:
                                (item['selected'] ?? false)
                                    ? Colors.green[100]
                                    : Colors.white, // 如果為 null，預設為 false
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 顯示飲料名稱、冰塊和糖度的詳細信息
                                      Text(
                                        '$drinkDetails x${item['quantity']}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      // 顯示該飲料的選項，若無選項則顯示「無選項」
                                      if (item['options'] != null &&
                                          item['options'].isNotEmpty)
                                        ...item['options'].map<Widget>((
                                          option,
                                        ) {
                                          return Text(
                                            '${option['name']} (+${option['price']})',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          );
                                        }).toList()
                                      else
                                        const Text(
                                          '',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                    ],
                                  ),
                                  // 顯示該飲料的價格
                                  Text(
                                    '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '總金額: \$${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _placeOrder,
                        child: const Text('確認結帳'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
