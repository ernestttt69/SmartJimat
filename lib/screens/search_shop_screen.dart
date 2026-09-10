import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'shop_details_screen.dart';

class SearchShopScreen extends StatefulWidget {
  const SearchShopScreen({super.key});

  @override
  State<SearchShopScreen> createState() => _SearchShopScreenState();
}

class _SearchShopScreenState extends State<SearchShopScreen> {
  final TextEditingController searchController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = false;
  bool hasSearched = false;

  List<Map<String, dynamic>> shops = [];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchShops() async {
    final keyword = searchController.text.trim();

    if (keyword.isEmpty) {
      setState(() {
        shops = [];
        hasSearched = false;
      });

      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      final result = await supabase
          .from('lookup_premise')
          .select(
        'premise_code, premise, address, premise_type, state',
      )
          .ilike(
        'premise',
        '%$keyword%',
      )
          .order('premise')
          .limit(50);

      if (!mounted) {
        return;
      }

      setState(() {
        shops = List<Map<String, dynamic>>.from(
          result,
        );

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
            'Failed to search shops: $e',
          ),
        ),
      );
    }
  }

  void clearSearch() {
    searchController.clear();

    setState(() {
      shops = [];
      hasSearched = false;
    });
  }

  void openShop(
      Map<String, dynamic> shop,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailsScreen(
          premiseCode: int.parse(
            shop['premise_code'].toString(),
          ),
          premiseName: shop['premise']?.toString() ?? '',
          address: shop['address']?.toString() ?? '',
          premiseType: shop['premise_type']?.toString() ?? '',
          state: shop['state']?.toString() ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text(
          'Search Shop',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          bottom: 24,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find grocery shops',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search for grocery stores by shop name.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    setState(() {});
                  },
                  onSubmitted: (_) => searchShops(),
                  decoration: InputDecoration(
                    hintText: 'Search shop name...',
                    prefixIcon: const Icon(
                      Icons.search,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: clearSearch,
                      icon: const Icon(
                        Icons.close,
                      ),
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : searchShops,
                    icon: const Icon(
                      Icons.search,
                    ),
                    label: const Text(
                      'Search Shop',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF38BB62,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          buildContent(),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 80,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!hasSearched) {
      return Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            30,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              20,
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 64,
                color: Color(
                  0xFF38BB62,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Search for shops',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter a shop name above to find grocery stores.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (shops.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 80,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No shops found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try another shop name.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24,
      ),
      itemCount: shops.length,
      separatorBuilder: (_, __) => const SizedBox(
        height: 12,
      ),
      itemBuilder: (context, index) {
        final shop = shops[index];

        final premise = shop['premise']?.toString() ?? '';

        final address = shop['address']?.toString() ?? '';

        final premiseType = shop['premise_type']?.toString() ?? '';

        final state = shop['state']?.toString() ?? '';

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            18,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(
              18,
            ),
            onTap: () => openShop(
              shop,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                18,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE7F8EC,
                      ),
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Color(
                        0xFF38BB62,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          premise,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (premiseType.isNotEmpty) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            premiseType,
                            style: const TextStyle(
                              color: Color(
                                0xFF38BB62,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (address.isNotEmpty) ...[
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            address,
                            style: const TextStyle(
                              color: Colors.grey,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (state.isNotEmpty) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            state,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}