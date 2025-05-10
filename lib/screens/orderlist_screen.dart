import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/DatabaseHelper.dart';
import 'dart:convert';
import 'dart:math';
import 'app_drawer.dart'; // 匯入側邊欄元件

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool isLoading = false;
  int? expandedOrderId; // 移到這裡
  DateTime selectedStartDate = DateTime.now().toLocal();
  DateTime selectedEndDate = DateTime.now().toLocal();
  DateTime nowday = DateTime.now().toLocal();
  String startDate = '';
  String endDate = '';
  num totalSales = 0;
  num orderCountD = 0;
  num InvalidOrderCount = 0;
  num InvalidOrderMoney = 0;

  List<Map<String, dynamic>> totalSalesResult = [];
  int orderCount = 0;
  Map<String, dynamic> InValidOrder = {};
  List<Map<String, dynamic>> hourlyData = [];
  List<Map<String, dynamic>> orderlist = [];

  int offset = 0;
  int limit = 10;
  int currentPage = 1; // 當前頁數
  int totalPages = 1; // 總頁數
  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  String formattedTime(String orderCreationTime) {
    // 解析成 DateTime 物件
    DateTime dateTime = DateTime.parse(orderCreationTime);

    // 格式化只取時間部分（例如：11:11:47）
    String formattedTime = DateFormat('HH:mm:ss').format(dateTime);

    return formattedTime;
  }

  // 分頁功能
  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
        offset = (currentPage - 1) * limit;
        _fetchPerformanceData(); // 重新獲取資料
      });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        offset = (currentPage - 1) * limit;
        _fetchPerformanceData(); // 重新獲取資料
      });
    }
  }

  // 當用戶更改每頁顯示的數量時
  void _onPageSizeChanged(int? newLimit) {
    setState(() {
      limit = newLimit ?? 10;
      print('新的頁數$newLimit');
      currentPage = 1; // 每次改變頁面大小時，都設為第一頁
      offset = 0; // 重新設置偏移量為 0
      _fetchPerformanceData(); // 重新獲取資料
    });
  }

  Future<void> _fetchPerformanceData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final formatter = DateFormat('yyyy-MM-dd');
      startDate = formatter.format(selectedStartDate);
      endDate = formatter.format(selectedEndDate);

      final String startDateTime = '$startDate 00:00:00';
      final String endDateTime = '$endDate 23:59:59';

      print('Fetching data for the date range: $startDateTime to $endDateTime');
      InValidOrder = await DatabaseHelper().getInvalidOrderTotalAmount(
        startDate,
        endDate,
      );
      print('作廢單數跟金額$InValidOrder');

      orderlist = await DatabaseHelper().getOrderWithItems(
        startDate: startDateTime,
        endDate: endDateTime,
        offset: offset,
        limit: limit,
      );
      print('實際的訂單長度${orderlist.length}');
      // 計算總頁數，至少為 1
      totalPages = max(1, (orderCount / limit).ceil());
      print('訂單列表$orderlist');

      orderCount = await DatabaseHelper().getOrderCount(startDate, endDate);
      print('訂單總數$orderCount');

      hourlyData = await DatabaseHelper().getHourlySales(
        startDateTime,
        endDateTime,
      );

      totalSalesResult = await DatabaseHelper().getTotalSales(
        startDateTime,
        endDateTime,
      );
      print('總業績$totalSalesResult');
    } finally {
      setState(() {
        isLoading = false;
        totalSales =
            totalSalesResult.isNotEmpty &&
                    totalSalesResult[0]['total_sales'] != null
                ? (totalSalesResult[0]['total_sales'] as num)
                : 0;
        orderCount = orderCount;

        InvalidOrderCount =
            InValidOrder.isNotEmpty && InValidOrder['count'] != null
                ? (InValidOrder['count'] as num)
                : 0;

        InvalidOrderCount =
            InValidOrder.isNotEmpty && InValidOrder['total'] != null
                ? (InValidOrder['total'] as num)
                : 0;
        // InValidOrder ;
      });
    }
  }

  // 日期區間選擇方法
  Future<void> _selectDateRange(BuildContext context) async {
    // 顯示日期區間選擇器
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: selectedStartDate,
        end: selectedEndDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(nowday.year, nowday.month, nowday.day),
    );

    // 確保選擇的日期範圍不為 null 且更新狀態
    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        _fetchPerformanceData(); // 根據選擇的日期範圍重新載入資料
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('訂單列表查詢')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // 日期區間選擇按鈕
            ElevatedButton(
              onPressed: () => _selectDateRange(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.brown), // 設定邊框顏色
                  borderRadius: BorderRadius.circular(12), // 圓角設置
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ), // 按鈕內邊距
                elevation: 3, // 按鈕陰影
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // 撐滿寬度

                children: [
                  Text(
                    '選擇日期: ${DateFormat('yyyy-MM-dd').format(selectedStartDate)} 至 ${DateFormat('yyyy-MM-dd').format(selectedEndDate)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8), // 間距
                  Text(
                    '總業績: \$$totalSales  總筆數:$orderCount 作廢筆數:$InvalidOrderCount 作廢金額\$$InvalidOrderMoney',
                    style: const TextStyle(fontSize: 20, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Loading indicator
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Center(
                                          child: Text(
                                            '訂單列表',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 10),
                                        ...orderlist.map((order) {
                                          final isExpanded =
                                              expandedOrderId ==
                                              order['order_id'];
                                          final items =
                                              order['items'] as List<dynamic>;
                                          // String time = formattedTime(
                                          //   order['order_creation_time'],
                                          // ); // 將 JSON 字符串解析為 Dart List

                                          return Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    expandedOrderId =
                                                        isExpanded
                                                            ? null
                                                            : order['order_id'];
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          order['order_no'],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 20,
                                                              ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(
                                                            width: 80, // 金額欄位寬度
                                                            child: Text(
                                                              '\$${order['total_price']}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                80, // 付款方式欄位寬度
                                                            child: Text(
                                                              order['payment_method'],
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                80, // 取餐方式欄位寬度
                                                            child: Text(
                                                              order['pickup_method'],
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                80, // 訂單狀態欄位寬度
                                                            child: Text(
                                                              '${order['order_status']}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  if (isExpanded) ...[
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '實收 \$${order['received_cash']}',
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              '找零 \$${order['change']}',
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Text(
                                                          order['order_creation_time'],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                        ),
                                                      ],
                                                    ),

                                                    // const SizedBox(height: 10),
                                                    ...items.map((item) {
                                                      List<dynamic>
                                                      optionsList =
                                                          item['options'] !=
                                                                  null
                                                              ? jsonDecode(
                                                                item['options'],
                                                              )
                                                              : [];
                                                      String optionNames = '';
                                                      if (optionsList
                                                          .isNotEmpty) {
                                                        List<String> names =
                                                            optionsList
                                                                .map(
                                                                  (option) =>
                                                                      option['name']
                                                                          as String,
                                                                )
                                                                .toList();
                                                        optionNames = names
                                                            .join(' ');
                                                      }

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 4.0,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                '${item['menu_name']} x${item['quantity']}${optionNames.isNotEmpty ? ' $optionNames' : ''} ${item['sugar_level']}${item['ice']}',
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                              ),
                                                            ),
                                                            Text(
                                                              '\$${item['price']}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Stack(
                      children: [
                        // 中間絕對置中的分頁控制
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: _previousPage,
                              ),
                              Text('第 $currentPage 頁 / $totalPages 頁'),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: _nextPage,
                              ),
                            ],
                          ),
                        ),

                        // 右側的下拉選單固定靠右
                        Positioned(
                          right: 0,
                          child: DropdownButton<int>(
                            value: limit,
                            items: const [
                              DropdownMenuItem(
                                value: 10,
                                child: Text('10 筆/頁'),
                              ),
                              DropdownMenuItem(
                                value: 20,
                                child: Text('20 筆/頁'),
                              ),
                              DropdownMenuItem(
                                value: 50,
                                child: Text('50 筆/頁'),
                              ),
                            ],
                            onChanged: _onPageSizeChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
