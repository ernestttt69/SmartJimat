// import 'package:flutter/material.dart';
//
// import '../services/supabase_service.dart';
// import '../utils/translation_helper.dart';
// import 'ai_chat_screen.dart';
// import 'search_results_screen.dart';
// import 'shopping_list_screen.dart';
// import 'subcategory_screen.dart';
//
// class CustomerHomeScreen extends StatefulWidget {
//   const CustomerHomeScreen({super.key});
//
//   @override
//   State<CustomerHomeScreen> createState() =>
//       _CustomerHomeState();
// }
//
// class _CustomerHomeState
//     extends State<CustomerHomeScreen> {
//   final SupabaseService supabaseService =
//   SupabaseService();
//
//   final TextEditingController searchController =
//   TextEditingController();
//
//   bool isLoading = true;
//
//   List<String> itemGroups = [];
//
//   @override
//   void initState() {
//     super.initState();
//     loadGroups();
//   }
//
//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> loadGroups() async {
//     try {
//       final groups =
//       await supabaseService.getItemGroups();
//
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         itemGroups = groups;
//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         isLoading = false;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content:
//           Text('Failed to load categories: $e'),
//         ),
//       );
//     }
//   }
//
//   void searchProduct() {
//     final keyword =
//     searchController.text.trim();
//
//     if (keyword.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content:
//           Text('Please enter a product name'),
//         ),
//       );
//       return;
//     }
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             SearchResultsScreen(
//               keyword: keyword,
//             ),
//       ),
//     );
//   }
//
//   IconData getGroupIcon(String group) {
//     final value = group.toLowerCase();
//
//     if (value.contains('segar')) {
//       return Icons.eco;
//     }
//
//     if (value.contains('minuman')) {
//       return Icons.local_drink;
//     }
//
//     if (value.contains('kering')) {
//       return Icons.rice_bowl;
//     }
//
//     if (value.contains('makanan')) {
//       return Icons.restaurant;
//     }
//
//     if (value.contains('runcit')) {
//       return Icons.local_grocery_store;
//     }
//
//     if (value.contains('keperluan')) {
//       return Icons.shopping_bag_outlined;
//     }
//
//     return Icons.shopping_basket;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//       const Color(0xFFF6F7F8),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: Row(
//           children: [
//             Image.asset(
//               'assets/images/smart_jimat_icon.jpeg',
//               width: 65,
//               height: 65,
//               fit: BoxFit.contain,
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'SmartJimat',
//               style: TextStyle(
//                 fontWeight:
//                 FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'SmartJimat AI',
//             icon: const Icon(
//               Icons.smart_toy_outlined,
//               color: Color(0xFF38BB62),
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                   const AiChatScreen(),
//                 ),
//               );
//             },
//           ),
//           IconButton(
//             tooltip: 'Shopping List',
//             icon: const Icon(
//               Icons.shopping_cart_outlined,
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                   const ShoppingListScreen(),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: loadGroups,
//         child: ListView(
//           padding:
//           const EdgeInsets.all(20),
//           children: [
//             const Text(
//               'Find cheaper groceries',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight:
//                 FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 6),
//             const Text(
//               'Search or browse grocery categories to start saving.',
//               style: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 24),
//             TextField(
//               controller:
//               searchController,
//               textInputAction:
//               TextInputAction.search,
//               onSubmitted: (_) =>
//                   searchProduct(),
//               decoration: InputDecoration(
//                 hintText:
//                 'Search product name...',
//                 prefixIcon:
//                 const Icon(
//                   Icons.search,
//                 ),
//                 suffixIcon:
//                 IconButton(
//                   tooltip: 'Search',
//                   icon: const Icon(
//                     Icons.arrow_forward,
//                   ),
//                   onPressed:
//                   searchProduct,
//                 ),
//                 filled: true,
//                 fillColor:
//                 Colors.white,
//                 contentPadding:
//                 const EdgeInsets
//                     .symmetric(
//                   horizontal: 18,
//                   vertical: 18,
//                 ),
//                 border:
//                 OutlineInputBorder(
//                   borderRadius:
//                   BorderRadius.circular(
//                     16,
//                   ),
//                   borderSide:
//                   BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 32),
//             const Text(
//               'Shop by Category',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight:
//                 FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 6),
//             const Text(
//               'Choose a grocery category',
//               style: TextStyle(
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 16),
//             if (isLoading)
//               const Padding(
//                 padding:
//                 EdgeInsets.all(40),
//                 child: Center(
//                   child:
//                   CircularProgressIndicator(),
//                 ),
//               )
//             else if (itemGroups.isEmpty)
//               const Padding(
//                 padding:
//                 EdgeInsets.all(40),
//                 child: Center(
//                   child: Text(
//                     'No categories found',
//                   ),
//                 ),
//               )
//             else
//               GridView.builder(
//                 shrinkWrap: true,
//                 physics:
//                 const NeverScrollableScrollPhysics(),
//                 itemCount:
//                 itemGroups.length,
//                 gridDelegate:
//                 const SliverGridDelegateWithMaxCrossAxisExtent(
//                   maxCrossAxisExtent:
//                   280,
//                   crossAxisSpacing: 14,
//                   mainAxisSpacing: 14,
//                   childAspectRatio:
//                   1.10,
//                 ),
//                 itemBuilder:
//                     (context, index) {
//                   final originalGroup =
//                   itemGroups[index];
//
//                   final englishGroup =
//                   TranslationHelper
//                       .translate(
//                     originalGroup,
//                   );
//
//                   return InkWell(
//                     borderRadius:
//                     BorderRadius.circular(
//                       18,
//                     ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (context) =>
//                               SubcategoryScreen(
//                                 itemGroup:
//                                 originalGroup,
//                               ),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       padding:
//                       const EdgeInsets
//                           .all(18),
//                       decoration:
//                       BoxDecoration(
//                         color:
//                         Colors.white,
//                         borderRadius:
//                         BorderRadius
//                             .circular(
//                           18,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors
//                                 .black
//                                 .withValues(
//                               alpha: 0.04,
//                             ),
//                             blurRadius: 8,
//                             offset:
//                             const Offset(
//                               0,
//                               3,
//                             ),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisAlignment:
//                         MainAxisAlignment
//                             .center,
//                         children: [
//                           Container(
//                             width: 58,
//                             height: 58,
//                             decoration:
//                             BoxDecoration(
//                               color:
//                               const Color(
//                                 0xFFE7F8EC,
//                               ),
//                               borderRadius:
//                               BorderRadius
//                                   .circular(
//                                 16,
//                               ),
//                             ),
//                             child: Icon(
//                               getGroupIcon(
//                                 originalGroup,
//                               ),
//                               color:
//                               const Color(
//                                 0xFF38BB62,
//                               ),
//                               size: 30,
//                             ),
//                           ),
//                           const SizedBox(
//                             height: 12,
//                           ),
//                           Text(
//                             englishGroup,
//                             textAlign:
//                             TextAlign
//                                 .center,
//                             maxLines: 2,
//                             overflow:
//                             TextOverflow
//                                 .ellipsis,
//                             style:
//                             const TextStyle(
//                               fontSize: 15,
//                               fontWeight:
//                               FontWeight
//                                   .w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }