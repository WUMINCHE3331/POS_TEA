import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos_system/DatabaseHelper.dart';
import 'package:intl/intl.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  _PerformanceScreenState createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool isLoading = false;
DateTime selectedDate = DateTime.now().toUtc().add(const Duration(hours: 8));

  String startDate = '';
  String endDate = '';
  double totalSales = 0.0;
  List<Map<String, dynamic>> productSales = [];
  List<Map<String, dynamic>> paymentMethodStats = [];
  List<int> hourlySales = List.generate(24, (_) => 0);

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  // 加載業績數據的方法
  Future<void> _fetchPerformanceData() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2)); // 模擬加載延遲

      // 更新日期範圍
      startDate =
          '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
      endDate = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
    final formatter = DateFormat('yyyy-MM-dd');

    startDate = formatter.format(selectedDate);
    endDate = formatter.format(selectedDate);

    final String startDateTime = '$startDate 00:00:00';
    final String endDateTime = '$endDate 23:59:59';

    print('Fetching data for the date range: $startDateTime to $endDateTime'); // 打印日期範圍

    // 從資料庫查詢數據
    List<Map<String, dynamic>> totalSalesResult = await DatabaseHelper()
        .getTotalSales(startDateTime, endDateTime);

    // 確保 total_sales 不為 null，若為 null，則設定為 0.0
    double totalSales =
        totalSalesResult.isNotEmpty &&
                totalSalesResult[0]['total_sales'] != null
            ? (totalSalesResult[0]['total_sales'] as num).toDouble()
            : 0.0;

    print(
      'Total sales for selected date: \$${totalSales.toStringAsFixed(2)}',
    ); // 打印總業績

    productSales = await DatabaseHelper().getSalesByProduct(startDateTime, endDateTime);
    paymentMethodStats = await DatabaseHelper().getSalesByPaymentMethod(
      startDate,
      endDate,
    );

    // 確保 getHourlySales 返回的是 List<Map<String, dynamic>> 類型
    List<Map<String, dynamic>> hourlyData = await DatabaseHelper()
        .getHourlySales(startDateTime, endDateTime);

    // 提取每小時的銷售金額並轉換為 List<int>
    hourlySales = hourlyData.map((data) => data['total_sales'] as int).toList();

    print('Hourly sales data: $hourlySales'); // 打印每小時的銷售數據

    setState(() {
      isLoading = false;
    });
  }
Future<void> _selectDate(BuildContext context) async {
  // 確保使用的是台灣的當前時間 (UTC+8)
  final DateTime taiwanNow = DateTime.now().toUtc().add(const Duration(hours: 8));
  
  // 顯示日期選擇器，設置初始日期和限制日期範圍為今天
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: taiwanNow,  // 初始顯示的日期為台灣當前時間
    firstDate: DateTime(2020),
    lastDate: DateTime(taiwanNow.year, taiwanNow.month, taiwanNow.day),  // 限制日期範圍到今天
  );

  // 確保選擇的日期不為 null 且更新狀態
  if (picked != null && picked != selectedDate) {
    setState(() {
      selectedDate = picked;
      _fetchPerformanceData(); // 根據選擇的日期重新載入資料
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('業績查詢')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   '業績總覽',
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
            const SizedBox(height: 20),
            // 日期選擇器
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // 自定義按鈕顏色
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
 child: Text(
    '選擇日期: ${DateFormat('yyyy-MM-dd').format(selectedDate.toLocal())}',
    style: const TextStyle(fontSize: 16),
  ),
            ),
            const SizedBox(height: 20),
            // Loading indicator
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // 顯示總業績
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: const Text('總業績'),
                        subtitle: Text('\$${totalSales.toStringAsFixed(2)}'),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 顯示產品銷售統計和支付方式統計並排顯示
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 產品銷售統計
                        Expanded(
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '產品銷售統計',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...productSales.map((product) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: ListTile(
                                        title: Text(product['name']),
                                        subtitle: Text(
                                          '銷售次數: ${product['quantity']}  總金額: \$${product['total_sales']}',
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 16.0,
                                            ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 支付方式統計
                        Expanded(
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '支付方式統計',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...paymentMethodStats.map((payment) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: ListTile(
                                        title: Text(payment['method']),
                                        subtitle: Text(
                                          '使用次數: ${payment['count']}  總金額: \$${payment['total_sales']}',
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 16.0,
                                            ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 顯示每小時營業額
                    const Text(
                      '每小時營業額',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                hourlySales.length,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  hourlySales[index].toDouble(),
                                ),
                              ),
                              isCurved: true,
                              color: Colors.blue,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
