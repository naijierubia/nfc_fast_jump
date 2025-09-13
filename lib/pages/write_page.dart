import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WritePage extends StatelessWidget {
  const WritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.edit,
            size: 100,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 20),
          const Text(
            'NFC 写入功能',
            style: TextStyle(fontSize: 24),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '在此页面可以向NFC标签写入信息',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                // 导航到网易云音乐写入页面
                context.push('/netease-music');
              },
              child: const Text('网易云音乐'),
            ),
          ),
        ],
      ),
    );
  }
}
