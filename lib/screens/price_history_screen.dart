import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceHistoryScreen
    extends StatefulWidget {
  final int premiseCode;
  final String premiseName;
  final int itemCode;
  final String itemName;
  final String unit;

  const PriceHistoryScreen({
    super.key,
    required this.premiseCode,
    required this.premiseName,
    required this.itemCode,
    required this.itemName,
    required this.unit,
  });

  @override
  State<PriceHistoryScreen> createState() =>
      _PriceHistoryScreenState();
}

class _PriceHistoryScreenState
    extends State<PriceHistoryScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  bool isLoading = true;

  List<Map<String, dynamic>> history = [];

  double? latestPrice;
  double? lowestPrice;
  double? highestPrice;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final result = await supabase
          .from('pricecatcher')
          .select(
        'date, price',
      )
          .eq(
        'premise_code',
        widget.premiseCode,
      )
          .eq(
        'item_code',
        widget.itemCode,
      )
          .not(
        'price',
        'is',
        null,
      )
          .order(
        'date',
        ascending: false,
      );

      final rows =
      List<Map<String, dynamic>>.from(
        result,
      );

      final validRows = rows.where(
            (row) {
          return double.tryParse(
            row['price'].toString(),
          ) !=
              null;
        },
      ).toList();

      double? lowest;
      double? highest;

      for (final row in validRows) {
        final price = double.parse(
          row['price'].toString(),
        );

        if (lowest == null ||
            price < lowest) {
          lowest = price;
        }

        if (highest == null ||
            price > highest) {
          highest = price;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        history = validRows;

        latestPrice =
        validRows.isNotEmpty
            ? double.parse(
          validRows.first['price']
              .toString(),
        )
            : null;

        lowestPrice = lowest;
        highestPrice = highest;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load price history: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Price History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: loadHistory,
        child: ListView(
          padding:
          const EdgeInsets.all(20),
          children: [
            buildProductHeader(),
            const SizedBox(height: 20),
            buildPriceSummary(),
            const SizedBox(height: 28),
            const Text(
              'Price History',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${history.length} price records',
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              buildEmptyState()
            else
              ...history.map(
                buildHistoryCard,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildProductHeader() {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration:
                BoxDecoration(
                  color: const Color(
                    0xFFE7F8EC,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.shopping_basket,
                  color: Color(
                    0xFF38BB62,
                  ),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName,
                      style:
                      const TextStyle(
                        fontSize: 19,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    if (widget
                        .unit.isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        widget.unit,
                        style:
                        const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.store_outlined,
                size: 19,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.premiseName,
                  style:
                  const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPriceSummary() {
    return Row(
      children: [
        Expanded(
          child: buildSummaryCard(
            'Latest',
            latestPrice,
            Icons.sell_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildSummaryCard(
            'Lowest',
            lowestPrice,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildSummaryCard(
            'Highest',
            highestPrice,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget buildSummaryCard(
      String title,
      double? price,
      IconData icon,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
            const Color(0xFF38BB62),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            price == null
                ? '-'
                : 'RM ${price.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHistoryCard(
      Map<String, dynamic> row,
      ) {
    final date =
        row['date']?.toString() ?? '';

    final price = double.tryParse(
      row['price'].toString(),
    ) ??
        0;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
              const Color(0xFFE7F8EC),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(
                0xFF38BB62,
              ),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              date,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),
          Text(
            'RM ${price.toStringAsFixed(2)}',
            style:
            const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xFF38BB62),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      padding:
      const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history,
            size: 55,
            color: Colors.grey,
          ),
          SizedBox(height: 14),
          Text(
            'No price history',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}