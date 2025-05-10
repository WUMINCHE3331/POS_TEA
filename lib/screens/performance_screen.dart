import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos_system/DatabaseHelper.dart';
import 'package:intl/intl.dart';
import 'app_drawer.dart'; // 匯入側邊欄元件

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  _PerformanceScreenState createState() => _PerformanceScreenState();
}

List<String> salesInfo = [];

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool isLoading = false;
  DateTime selectedStartDate = DateTime.now().toLocal();
  DateTime selectedEndDate = DateTime.now().toLocal();
  DateTime nowday = DateTime.now().toLocal();
  String startDate = '';
  String endDate = '';
  num totalSales = 0;
  num orderCountD = 0;
  num InvalidOrderCount = 0;
  num InvalidOrderMoney = 0;
  List<Map<String, dynamic>> productSales = [];
  List<Map<String, dynamic>> paymentMethodStats = [];
  List<Map<String, dynamic>> pickMethods = [];
  List<Map<String, dynamic>> totalSalesResult = [];
  int orderCount = 0;
  Map<String, dynamic> InValidOrder = {};
  List<Map<String, dynamic>> hourlyData = [];
  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
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
        startDateTime,
        endDateTime,
      );
      print('作廢單數跟金額${InValidOrder}');
      orderCount = await DatabaseHelper().getOrderCount(startDate, endDate);
      print('訂單總數${orderCount}');

      hourlyData = await DatabaseHelper().getHourlySales(
        startDateTime,
        endDateTime,
      );
      print('每小時業績${hourlyData}');

      totalSalesResult = await DatabaseHelper().getTotalSales(
        startDateTime,
        endDateTime,
      );
      print('總業績${totalSalesResult}');
      pickMethods = await DatabaseHelper().fetchPickupMethodCount(
        startDateTime,
        endDateTime,
      );
      productSales = await DatabaseHelper().getSalesByProduct(
        startDateTime,
        endDateTime,
      );
      print('我是產品peramount${productSales}');
      paymentMethodStats = await DatabaseHelper().getSalesByPaymentMethod(
        startDateTime,
        endDateTime,
      );
      print(pickMethods);
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
      appBar: AppBar(title: const Text('業績查詢')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 撐滿寬度
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '選擇日期: ${DateFormat('yyyy-MM-dd').format(selectedStartDate)} 至 ${DateFormat('yyyy-MM-dd').format(selectedEndDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8), // 間距
                  Text(
                    '總業績: \$${totalSales}  總筆數:${orderCount} 作廢筆數:${InvalidOrderCount} 作廢金額\$${InvalidOrderMoney}',
                    style: const TextStyle(fontSize: 16, letterSpacing: 0.5),
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
                    // 顯示總業績

                    // 顯示產品銷售統計和支付方式統計並排顯示
                    // 統計數據與圖表並排顯示
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左側：統計資訊（產品銷售 + 支付方式）
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 左側：產品銷售統計
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey,
                                        ), // 外框邊線
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ), // 圓角
                                      ),
                                      padding: const EdgeInsets.all(12), // 內距
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // const SizedBox(height: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: const Text(
                                                  '產品銷售統計',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 10),
                                              ...productSales.map((product) {
                                                return Column(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      decoration:
                                                          const BoxDecoration(
                                                            border: Border(
                                                              bottom: BorderSide(
                                                                color:
                                                                    Colors.grey,
                                                              ), // 加底線邊框
                                                            ),
                                                          ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              product['name'],
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          Text(
                                                            'x${product['total_quantity']}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            '\$${product['total_sales'] ?? 0}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 4,
                                                    ), // 行距
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                      ), // 外框邊線
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // 圓角
                                    ),
                                    padding: const EdgeInsets.all(12), // 內距
                                    child: Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: const Text(
                                              '業績/小時',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 10),
                                          ...hourlyData.map((hourlyData) {
                                            return Column(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Colors.grey,
                                                          ), // 加底線邊框
                                                        ),
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '${hourlyData['hour']} 時'
                                                                  ?.toString() ??
                                                              '未知業績小時',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        '\$${hourlyData['total_sales'] ?? 0}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ), // 行間距
                                              ],
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                      ), // 外框邊線
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // 圓角
                                    ),
                                    padding: const EdgeInsets.all(12), // 內距
                                    child: Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: const Text(
                                              '支付統計',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 10),
                                          ...paymentMethodStats.map((payment) {
                                            return Column(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Colors.grey,
                                                          ), // 加底線邊框
                                                        ),
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          payment['payment_method']
                                                                  ?.toString() ??
                                                              '未知付款方式',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        'x${payment['total_count'] ?? 0}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '\$${payment['total_sales'] ?? 0}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ), // 行間距
                                              ],
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                      ), // 外框邊線
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // 圓角
                                    ),
                                    padding: const EdgeInsets.all(12), // 內距
                                    child: Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: const Text(
                                              '外帶統計',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 10),
                                          ...pickMethods.map((pickmethods) {
                                            return Column(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Colors.grey,
                                                          ), // 加底線邊框
                                                        ),
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          pickmethods['pickup_method']
                                                                  ?.toString() ??
                                                              '未知付款方式',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        'x${pickmethods['method_count'] ?? 0}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '\$${pickmethods['total_amount'] ?? 0}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ), // 行間距
                                              ],
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
