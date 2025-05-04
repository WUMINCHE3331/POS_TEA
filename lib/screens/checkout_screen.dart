import 'package:flutter/material.dart';
import 'package:pos_system/DatabaseHelper.dart';
import 'dart:convert';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Map<String, dynamic>> menuItems = []; // 這裡改為 List，而不是 Future
  List<Map<String, dynamic>> options = []; // 這裡改為 List，而不是 Future
  List<Map<String, dynamic>> filteredMenuItems = [];
  @override
  void initState() {
    super.initState();
    // 讀取資料庫中的菜單項目
    // 讀取資料庫中的菜單項目
    // 初始化菜單資料並讀取資料庫中的菜單項目
    _loadMenuItems();
    _loadOptions();
  }

  // 異步加載菜單資料
  Future<void> _loadMenuItems() async {
    // 讀取資料庫中的菜單項目
    var menuData = await DatabaseHelper().getMenuItems();

    // 使用 setState 更新 UI，將資料設置為菜單項目
    setState(() {
      menuItems = menuData;

      // 根據預設的分類過濾菜單項目
      filteredMenuItems =
          menuItems
              .where((item) => item['category'] == selectedCategory)
              .toList();
    });
  }

  // 異步加載option資料
  Future<void> _loadOptions() async {
    // 讀取資料庫中的菜單項目
    var menuData = await DatabaseHelper().getOptions();

    // 使用 setState 更新 UI，將資料設置為菜單項目
    setState(() {
      options =
          menuData.map((item) {
            return {...item, 'selected': item['selected'] == 1 ? true : false};
          }).toList();

      print('我是加載: ${options.toString()}');
    });
  }

  num calculateTotalQuantity(List<Map<String, dynamic>> orderItems) {
    return orderItems.fold(0, (sum, item) => sum + item['quantity']);
  }

  // Future<void> addOrder(
  //   Map<String, dynamic> order,
  //   List<Map<String, dynamic>> orderItems,
  //   List<Map<String, dynamic>> selectedOptions,
  // ) async {
  //   final db = await DatabaseHelper().database;

  //   // 開始一個事務
  //   await db.transaction((txn) async {
  //     // 插入訂單資料到訂單表格
  //     int orderId = await txn.insert('orders', order);

  //     // 插入訂單項目
  //     for (var item in orderItems) {
  //       // 插入每一個訂單項目
  //       item['order_id'] = orderId; // 設置訂單ID
  //       await txn.insert('order_items', item);

  //       // 插入每個訂單項目的選項（如冰塊、糖度等）
  //       for (var option in selectedOptions) {
  //         if (option['order_item_id'] == item['order_item_id']) {
  //           // 插入每個選項
  //           await txn.insert('order_item_options', {
  //             'order_item_id': item['order_item_id'],
  //             'option_id': option['option_id'],
  //             'selected': option['selected'],
  //           });
  //         }
  //       }
  //     }
  //   });
  // }

  // 設置選中的訂單項目，並更新客製化UI
  void setSelectedOrderItem(Map<String, dynamic> item) {
    setState(() {
      selectedOrderItem = item; // 保存選中的訂單項目
      print('選中的訂單項目: $selectedOrderItem');
      // 更新UI（例如：選擇的糖度、冰塊等）
      updateCustomizationUI(selectedOrderItem);
    });
  }

  // 整筆取消方法
  void clearAllOrders() {
    setState(() {
      // 清空所有訂單項目
      orderItems.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清空所有訂單項目')),
    );  
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

  String paymentMethod = '現金'; // 預設付款方式
  String pickupMethod = '外帶'; // 預設取餐方式為外帶



  // 顯示結帳對話框
  _showCheckoutDialog(num totalAmount) {
      TextEditingController cashController = TextEditingController(text: '0'); // 現金輸入框控制器
      
  num receivedCash = 0; // 收到的現金
    num change = 0 - totalAmount;
  // 計算找零
  void calculateChange(num totalAmount) {
    int cash = int.tryParse(cashController.text) ?? 0;
    setState(() {
      receivedCash = cash;
      change = receivedCash - totalAmount;
    });
  }
      // 檢查 totalAmount 是否有值
  if (totalAmount == null || totalAmount <= 0) {
    // 如果沒有值，顯示 SnackBar 並返回
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('金額無效，請檢查訂單金額')),
    );
    return; // 直接返回，不顯示對話框
  }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // title: const Text('結帳'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顯示總金額
                  Text(
                    '總金額: \$$totalAmount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      // 輸入現金
                      TextField(
                        controller: cashController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '輸入收到的現金',
                          border: OutlineInputBorder(),
                          suffixIcon: SizedBox(), // 用空的 icon 佔位符避免外框變形
                        ),
                        onChanged: (value) {
                          int cashInput = int.tryParse(value) ?? 0;
                          setStateDialog(() {
                            receivedCash = cashInput;
                            change = receivedCash - totalAmount;
                          });
                        },
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.center, // 垂直居中
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setStateDialog(() {
                                cashController.clear(); // 清空 TextField
                                receivedCash = 0; // 重置收到的現金
                                change = 0; // 重置找零
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 顯示找零
                  Text(
                    '找零: \$${change.toInt()}',
                    style: TextStyle(
                      fontSize: 24,
                      color:
                          change < 0
                              ? Colors.red
                              : Colors.black, // 如果找零小於0，顯示紅色
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 取餐方式與付款方式選擇
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 取餐方式選擇
                      Row(
                        children: [
                          const Text('取餐: ', style: TextStyle(fontSize: 18)),
                          DropdownButton<String>(
                            value: pickupMethod,
                            items: const [
                              DropdownMenuItem(value: '外帶', child: Text('外帶')),
                              DropdownMenuItem(value: 'UB', child: Text('UB')),
                              DropdownMenuItem(value: 'FD', child: Text('FD')),
                              DropdownMenuItem(value: 'LA', child: Text('LA')),
                            ],
                            onChanged: (value) {
                              setStateDialog(() {
                                pickupMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      // 付款方式選擇
                      Row(
                        children: [
                          const Text('付款: ', style: TextStyle(fontSize: 18)),
                          DropdownButton<String>(
                            value: paymentMethod,
                            items: const [
                              DropdownMenuItem(value: '現金', child: Text('現金')),
                              DropdownMenuItem(
                                value: '信用卡',
                                child: Text('信用卡'),
                              ),
                              DropdownMenuItem(
                                value: '支付寶',
                                child: Text('支付寶'),
                              ),
                            ],
                            onChanged: (value) {
                              setStateDialog(() {
                                paymentMethod = value!; // 更新付款方式
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 快捷金額選擇
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setStateDialog(() {
                            receivedCash = 50;
                            change = receivedCash - totalAmount;
                            cashController.text = '50'; // 快捷金額為100
                          });
                        },
                        child: const Text('50'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setStateDialog(() {
                            receivedCash = 100;
                            change = receivedCash - totalAmount;
                            cashController.text = '100'; // 快捷金額為100
                          });
                        },
                        child: const Text('100'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setStateDialog(() {
                            receivedCash = 500;
                            change = receivedCash - totalAmount;
                            cashController.text = '500'; // 快捷金額為500
                          });
                        },
                        child: const Text('500'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setStateDialog(() {
                            receivedCash = 1000;
                            change = receivedCash - totalAmount;
                            cashController.text = '1000'; // 快捷金額為1000
                          });
                        },
                        child: const Text('1000'),
                      ),

                      const SizedBox(width: 10), // 剛好選項
                      ElevatedButton(
                        onPressed: () {
                          setStateDialog(() {
                            receivedCash = totalAmount; // 將收到的現金設為總金額
                            change = 0; // 找零為0
                            cashController.text =
                                totalAmount.toString(); // 快捷金額為總金額
                          });
                        },
                        child: const Text('剛好'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 56,
              ),
              onPressed: () async {
                if (receivedCash >= totalAmount) {
                  var orderDetails = {
                    'total_price': totalAmount,
                    'received_cash': receivedCash,
                    'change': change,
                    'payment_method': paymentMethod,
                    'pickup_method': pickupMethod,
                    'order_status': 'success',
                    'order_creation_time': DateTime.now().toString(),
                  };

                  print('送出的訂單物件: $orderDetails');

                  int orderId = await DatabaseHelper().insertOrder(
                    orderDetails,
                  );
                  print('成功儲存訂單 ID: $orderId');

                  for (var order in orderItems) {
                    var optionsJson = json.encode(
                      order['options'],
                    ); // options 是 HashMap，將它轉為 JSON 字串
                    int menuItemId = await DatabaseHelper().getMenuItemIdByName(
                      order['name'],
                    );
                    if (menuItemId != -1) {
                      order.remove('name'); // 👈 移除不存在於 DB 表的欄位
                      order.remove('selected'); // 👈 移除不存在於 DB 表的欄位
                      order['options'] = optionsJson;
                      order['menu_item_id'] = menuItemId;
                    } else {
                      print('無法找到菜單項目: ${order['name']}');
                    }
                  }

                  await DatabaseHelper().insertOrderItems(orderId, orderItems);

                  print('成功儲存訂單項目$orderItems');
                  setState(() {
                    orderItems.clear();
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '結帳完成！總金額：\$${totalAmount.toStringAsFixed(2)}',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('收到的現金不足，無法完成結帳')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 合併所有客製化選項，包括冰塊、糖度和環保杯
  // List<Map<String, dynamic>> options = [
  //   {'name': '正常冰', 'price': 0, 'type': 'ice', 'selected': false},
  //   {'name': '微冰', 'price': 0, 'type': 'ice', 'selected': false},
  //   {'name': '少冰', 'price': 0, 'type': 'ice', 'selected': false},
  //   {'name': '去冰', 'price': 0, 'type': 'ice', 'selected': false},
  //   {'name': '常溫', 'price': 0, 'type': 'ice', 'selected': false},
  //   {'name': '溫熱', 'price': 0, 'type': 'ice', 'selected': false},
  //   {'name': '熱', 'price': 0, 'type': 'ice', 'selected': false},
  //   {'name': '正常糖', 'price': 0, 'type': 'sugar', 'selected': false},
  //   {'name': '少糖', 'price': 1, 'type': 'sugar', 'selected': false},
  //   {'name': '微糖', 'price': 1, 'type': 'sugar', 'selected': false},
  //   {'name': '無糖', 'price': 0, 'type': 'sugar', 'selected': false},
  //   {'name': '環保杯', 'price': -5, 'type': 'eco_cup', 'selected': false}, // 環保杯選項
  //   {'name': '珍珠', 'price': 10, 'type': 'topping', 'selected': false},
  //   {'name': '椰果', 'price': 10, 'type': 'topping', 'selected': false},
  // ];
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

  // 單筆取消方法
  void cancelSelectedOrder() {
    final index = orderItems.indexWhere((item) => item['selected'] == true);

    if (index != -1) {
      // 如果有選中的項目，進行取消操作
      setState(() {
        // 清空與選中項目相關的所有客製化選項

        orderItems.removeAt(index); // 移除選中的訂單項目
        if (index > 0) {
          orderItems[index - 1]['selected'] = true; // 選擇上一個訂單項目
        }
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('已取消該項目')),
      // );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('沒有選中的項目可以取消')));
    }
  }

  void _quantityRevise() {
    final index = orderItems.indexWhere((item) => item['selected'] == true);

    if (index != -1) {
      int quantity = orderItems[index]['quantity'];
      // ✅ 定義 controller 並初始化
      final TextEditingController controller = TextEditingController(
        text: quantity.toString(),
      );

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 數量調整區域
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // 水平居中
                      crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
                      children: [
                        // 左箭頭，包裹在 Container 中加邊框
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.brown, // 設置背景顏色為咖啡色
                            shape: BoxShape.circle, // 圓形
                          ),
                          // padding: const EdgeInsets.all(8), // 設置內邊距
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_left,
                              size: 50, // 增大箭頭圖標
                              color: Colors.white, // 設置為棕色
                            ),
                            onPressed: () {
                              if (quantity > 1) {
                                setStateDialog(() {
                                  quantity--; // 減少數量
                                  controller.text =
                                      quantity.toString(); // 更新文本框
                                });
                              }
                            },
                          ),
                        ),

                        // 數量輸入框（底線樣式）
                        SizedBox(
                          width: 60, // 控制數字框的寬度
                          child: TextField(
                            controller: controller,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              border: UnderlineInputBorder(),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.brown,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              final val = int.tryParse(value);
                              if (val != null && val > 0) {
                                setStateDialog(() {
                                  quantity = val;
                                });
                              }
                            },
                          ),
                        ),

                        // 右箭頭，包裹在 Container 中加邊框
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.brown, // 設置背景顏色為咖啡色
                            shape: BoxShape.circle, // 圓形
                          ),
                          // padding: const EdgeInsets.all(8), // 設置內邊距
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_right,
                              size: 50, // 增大箭頭圖標
                              color: Colors.white, // 設置為棕色
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                quantity++; // 增加數量
                                controller.text = quantity.toString(); // 更新文本框
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              // 快速選擇數量 1
              IconButton(
                icon: const Icon(
                  Icons.looks_one, // 顯示數字 1
                  color: Colors.blue,
                  size: 30, // 設置按鈕大小
                ),
                onPressed: () {
                  setState(() {
                    quantity = 1; // 快速設置為 1
                    controller.text = '1'; // 更新文本框顯示
                  });
                },
              ),

              // 快速選擇數量 3
              IconButton(
                icon: const Icon(
                  Icons.looks_3, // 顯示數字 3
                  color: Colors.blue,
                  size: 30, // 設置按鈕大小
                ),
                onPressed: () {
                  setState(() {
                    quantity = 3; // 快速設置為 3
                    controller.text = '3'; // 更新文本框顯示
                  });
                },
              ),

              // 快速選擇數量 5
              IconButton(
                icon: const Icon(
                  Icons.looks_5, // 顯示數字 5
                  color: Colors.blue,
                  size: 30, // 設置按鈕大小
                ),
                onPressed: () {
                  setState(() {
                    quantity = 5; // 快速設置為 5
                    controller.text = '5'; // 更新文本框顯示
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.check_circle, // 更粗的勾勾圖標
                  color: Colors.green,
                  size: 56, // 增加大小
                ),
                onPressed: () {
                  final val = int.tryParse(controller.text);
                  if (val != null && val > 0) {
                    setState(() {
                      orderItems[index]['quantity'] = val;
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('請輸入有效的數量')));
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇一項商品')));
    }
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
                  decoration: const BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final categories = groupedMenu.keys.toList();
                      final int count = categories.length;

                      // 假設最多顯示 4 個按鈕寬度時剛好填滿容器
                      final int visibleCount = count < 6 ? count : 6;
                      final double buttonWidth =
                          (constraints.maxWidth - (visibleCount - 1) * 10) /
                          visibleCount;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              categories.map((category) {
                                return Container(
                                  width: buttonWidth,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedCategory = category;
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
                                              ? Colors.brown
                                              : Colors.grey[300],
                                      foregroundColor:
                                          selectedCategory == category
                                              ? Colors.white
                                              : Colors.black,
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
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    },
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
                                        childAspectRatio: 2.6, // 保持每個選項為正方形
                                      ),
                                  itemCount: options.length, // 項目數量
                                  itemBuilder: (context, index) {
                                    var option = options[index];

                                    return GestureDetector(
                                      onTap: () {
                                        var selectedOrder = orderItems
                                            .firstWhere(
                                              (item) =>
                                                  item['selected'] == true,
                                              orElse:
                                                  () =>
                                                      <
                                                        String,
                                                        dynamic
                                                      >{}, // 找不到時回傳 null
                                            );

                                        if (selectedOrder.isEmpty) {
                                          print('⚠️ 沒有選中的飲料項目，無法設定客製化');
                                          return;
                                        }
                                        setState(() {
                                          option['selected'] =
                                              !option['selected'];

                                          // 如果有選到，繼續處理 selectedOrder

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
                      onPressed:
                          () => _showCheckoutDialog(totalAmount), // 包裝成匿名函
                      child: const Text('結帳'),
                    ),
                    ElevatedButton(
                      onPressed: _quantityRevise,
                      child: const Text('數量更正'),
                    ),
                    // 取消按鈕
                    ElevatedButton(
                      onPressed: cancelSelectedOrder, // 調用取消方法
                      child: const Text('單筆取消'),
                    ),
                    ElevatedButton(
                      onPressed: clearAllOrders, // 呼叫整筆取消方法
                      child: const Text('整筆取消'),
                    ),

                    ElevatedButton(
                      onPressed: _placeOrder,
                      child: const Text('開啟錢櫃'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          calculateTotalQuantity(orderItems) > 0
                              ? Colors.green[100]
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // 讓兩個項目兩端對齊
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              '個數: ${calculateTotalQuantity(orderItems)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '總金額: \$$totalAmount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: orderItems.length,

                      itemBuilder: (context, index) {
                        var item = orderItems[index];
                        // 合併飲料的詳細選項：名稱、冰塊、糖度
                        String drinkDetails =
                            '${item['name']} ${item['eco_cup'] != null && item['eco_cup'] == '環保杯' ? '環保杯 (-5)' : ''}';

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
                                      if ((item['ice'] != null &&
                                              item['ice'].isNotEmpty) ||
                                          (item['sugar_level'] != null &&
                                              item['sugar_level'].isNotEmpty))
                                        Text(
                                          [
                                            if (item['sugar_level'] != null &&
                                                item['sugar_level'].isNotEmpty)
                                              item['sugar_level'],
                                            if (item['ice'] != null &&
                                                item['ice'].isNotEmpty)
                                              item['ice'],
                                          ].join('，'),
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),

                                      // Inside your widget or method
                                      Text(
                                        (() {
                                          final rawOptions = item['options'];
                                          List<dynamic> options = [];

                                          if (rawOptions is String) {
                                            try {
                                              options = jsonDecode(rawOptions);
                                            } catch (e) {
                                              print(
                                                '⚠️ JSON decode failed: $e',
                                              );
                                              options = [];
                                            }
                                          } else if (rawOptions is List) {
                                            options = rawOptions;
                                          }

                                          return options.isNotEmpty
                                              ? options
                                                  .map<String>(
                                                    (option) =>
                                                        '${option['name']} (+${option['price']})',
                                                  )
                                                  .join(', ')
                                              : '';
                                        })(),
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  // 顯示該飲料的價格
                                  Text(
                                    '\$${(item['price'] * item['quantity'])}',
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
                        '總金額: \$$totalAmount',
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
