import 'package:flutter/material.dart';

import '../services/ai_chat_service.dart';
import '../services/shopping_cart_service.dart';
import 'shopping_list_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() =>
      _AiChatScreenState();
}

class _AiChatScreenState
    extends State<AiChatScreen> {
  final TextEditingController
  messageController =
  TextEditingController();

  final ScrollController
  scrollController =
  ScrollController();

  final AiChatService aiService =
  AiChatService();

  final ShoppingCartService cart =
      ShoppingCartService.instance;

  final List<Map<String, String>>
  messages = [
    {
      'role': 'bot',
      'message':
      'Hi! I am SmartJimat AI. Tell me what you want to buy or what you want to cook.',
    },
  ];

  bool isSending = false;

  @override
  void initState() {
    super.initState();
    cart.addListener(refreshCart);
  }

  @override
  void dispose() {
    cart.removeListener(refreshCart);
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void refreshCart() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> sendMessage() async {
    final message =
    messageController.text.trim();

    if (message.isEmpty ||
        isSending) {
      return;
    }

    setState(() {
      messages.add({
        'role': 'user',
        'message': message,
      });

      isSending = true;
    });

    messageController.clear();

    scrollToBottom();

    try {
      final response =
      await aiService.sendMessage(
        message,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        messages.add({
          'role': 'bot',
          'message': response,
        });

        isSending = false;
      });

      scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        messages.add({
          'role': 'bot',
          'message':
          'Sorry, I could not process your request.\n$e',
        });

        isSending = false;
      });

      scrollToBottom();
    }
  }

  void scrollToBottom() {
    Future.delayed(
      const Duration(
        milliseconds: 150,
      ),
          () {
        if (!scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController
              .position
              .maxScrollExtent,
          duration:
          const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor:
              Color(0xFFE7F8EC),
              child: Icon(
                Icons.smart_toy_outlined,
                color:
                Color(0xFF38BB62),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'SmartJimat AI',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip:
                'Shopping List',
                icon: const Icon(
                  Icons
                      .shopping_cart_outlined,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ShoppingListScreen(),
                    ),
                  );
                },
              ),
              if (cart.totalQuantity > 0)
                Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    constraints:
                    const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 5,
                    ),
                    alignment:
                    Alignment.center,
                    decoration:
                    const BoxDecoration(
                      color: Colors.red,
                      shape:
                      BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.totalQuantity}',
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller:
              scrollController,
              padding:
              const EdgeInsets.all(
                16,
              ),
              itemCount:
              messages.length +
                  (isSending ? 1 : 0),
              itemBuilder:
                  (context, index) {
                if (index ==
                    messages.length &&
                    isSending) {
                  return Align(
                    alignment:
                    Alignment
                        .centerLeft,
                    child: Container(
                      margin:
                      const EdgeInsets
                          .only(
                        bottom: 12,
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius
                            .circular(
                          18,
                        ),
                      ),
                      child:
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }

                final message =
                messages[index];

                final isUser =
                    message['role'] ==
                        'user';

                return Align(
                  alignment: isUser
                      ? Alignment
                      .centerRight
                      : Alignment
                      .centerLeft,
                  child: Container(
                    constraints:
                    const BoxConstraints(
                      maxWidth: 310,
                    ),
                    margin:
                    const EdgeInsets
                        .only(
                      bottom: 12,
                    ),
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration:
                    BoxDecoration(
                      color: isUser
                          ? const Color(
                        0xFF38BB62,
                      )
                          : Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child: Text(
                      message[
                      'message'] ??
                          '',
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser
                            ? Colors.white
                            : Colors
                            .black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding:
            const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      messageController,
                      enabled:
                      !isSending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                      TextInputAction
                          .send,
                      onSubmitted: (_) {
                        sendMessage();
                      },
                      decoration:
                      InputDecoration(
                        hintText:
                        'Ask SmartJimat AI...',
                        filled: true,
                        fillColor:
                        const Color(
                          0xFFF6F7F8,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            24,
                          ),
                          borderSide:
                          BorderSide
                              .none,
                        ),
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  IconButton.filled(
                    onPressed: isSending
                        ? null
                        : sendMessage,
                    icon: const Icon(
                      Icons.send,
                    ),
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