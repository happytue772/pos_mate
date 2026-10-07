import 'package:flutter/material.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.add_box_outlined),
            title: Text('상품 등록'),
            subtitle: Text('새 상품을 등록합니다.'),
          ),
          ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('상품 관리'),
            subtitle: Text('상품을 수정하거나 삭제합니다.'),
          ),
          ListTile(
            leading: Icon(Icons.input_outlined),
            title: Text('입고 관리'),
            subtitle: Text('입고된 상품의 재고를 추가합니다.'),
          ),
          ListTile(
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('판매 내역'),
            subtitle: Text('완료된 판매 기록을 확인합니다.'),
          ),
          ListTile(
            leading: Icon(Icons.undo_outlined),
            title: Text('환불 관리'),
            subtitle: Text('판매 취소 및 환불을 처리합니다.'),
          ),
          ListTile(
            leading: Icon(Icons.manage_accounts_outlined),
            title: Text('직원 관리'),
            subtitle: Text('직원 계정과 권한을 관리합니다.'),
          ),
        ],
      ),
    );
  }
}
