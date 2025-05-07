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
  DateTime selectedStartDate = DateTime.now().toLocal();
  DateTime selectedEndDate = DateTime.now().toLocal();
  final DateTime taiwanNow = DateTime.now().toLocal();
  String startDate = '';
  String endDate = '';
  num totalSales = 0;
  List<Map<String, dynamic>> productSales = [];
  List<Map<String, dynamic>> paymentMethodStats = [];

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  List<int> hourlySales = List.generate(24, (_) => 0);

  // 加載業績數據的方法
  Future<void> _fetchPerformanceData() async {
    setState(() {
      isLoading = true;
    });

    // 更新日期範圍
    startDate =
        '${selectedStartDate.year}-${selectedStartDate.month}-${selectedStartDate.day}';
    endDate =
        '${selectedEndDate.year}-${selectedEndDate.month}-${selectedEndDate.day}';
    final formatter = DateFormat('yyyy-MM-dd');

    startDate = formatter.format(selectedStartDate);
    endDate = formatter.format(selectedEndDate);

    final String startDateTime = '$startDate 00:00:00';
    final String endDateTime = '$endDate 23:59:59';

    print(
      'Fetching data for the date range: $startDateTime to $endDateTime',
    ); // 打印日期範圍

    // 從資料庫查詢數據
    List<Map<String, dynamic>> totalSalesResult = await DatabaseHelper()
        .getTotalSales(startDateTime, endDateTime);

    setState(() {
      totalSales =
          totalSalesResult.isNotEmpty &&
                  totalSalesResult[0]['total_sales'] != null
              ? (totalSalesResult[0]['total_sales'] as num)
              : 0.0;

      print('Total sales for selected date: \$${totalSales}');
    });

    productSales = await DatabaseHelper().getSalesByProduct(
      startDateTime,
      endDateTime,
    );
    paymentMethodStats = await DatabaseHelper().getSalesByPaymentMethod(
      startDateTime,
      endDateTime,
    );
    List<Map<String, dynamic>> hourlyData = await DatabaseHelper()
        .getHourlySales(startDateTime, endDateTime);
    hourlySales = hourlyData.map((data) => data['total_sales'] as int).toList();
    print(hourlyData);print(hourlySales);
    setState(() {
      isLoading = false;
    });
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
      lastDate: DateTime(taiwanNow.year, taiwanNow.month, taiwanNow.day),
    );

    // 確保選擇的日期範圍不為 null 且更新狀態
    if (picked != null && picked.start != null && picked.end != null) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                elevation: 5, // 按鈕陰影
                shadowColor: Colors.blue.withOpacity(0.3), // 陰影顏色
              ),
              child: Text(
                '選擇日期區間: ${DateFormat('yyyy-MM-dd').format(selectedStartDate)} 至 ${DateFormat('yyyy-MM-dd').format(selectedEndDate)}   總業績: \$${totalSales}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // const SizedBox(height: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              return Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          product['name'],
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
                                                        'x${product['total_quantity']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '\$${product['total_sales'] ?? 0}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
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

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      payment['payment_method']
                                                              ?.toString() ??
                                                          '未知付款方式',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                              const SizedBox(height: 4), // 行間距
                                            ],
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                      // 顯示每小時營業額的文字
                      const Text(
                        '每小時營業額',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 這裡顯示每小時的銷售數據
                     
                    ],
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
