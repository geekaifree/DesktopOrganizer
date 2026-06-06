import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const DesktopOrganizerApp());

class DesktopOrganizerApp extends StatelessWidget {
  const DesktopOrganizerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '桌面分区管理', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true, brightness: Brightness.dark),
    home: const OrganizerHomePage(),
  );
}

class DesktopZone {
  String id, name;
  int color;
  List<String> items;
  DesktopZone({required this.id, required this.name, this.color = 0xFF80DEEA, this.items = const []});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color, 'items': items};
  factory DesktopZone.fromJson(Map<String, dynamic> j) => DesktopZone(id: j['id'], name: j['name'], color: j['color'] ?? 0xFF80DEEA, items: List<String>.from(j['items'] ?? []));
}

class OrganizerHomePage extends StatefulWidget {
  const OrganizerHomePage({super.key});
  @override
  State<OrganizerHomePage> createState() => _OrganizerHomePageState();
}

class _OrganizerHomePageState extends State<OrganizerHomePage> {
  List<DesktopZone> _zones = [];
  final _zoneColors = [0xFF80DEEA, 0xFFA5D6A7, 0xFFFFF59D, 0xFFFFAB91, 0xFFCE93D8, 0xFF90CAF9, 0xFFEF9A9A, 0xFFB0BEC5];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('desktop_zones');
    if (d != null) { setState(() => _zones = (json.decode(d) as List).map((e) => DesktopZone.fromJson(e)).toList()); }
    else { _zones = [
      DesktopZone(id: '1', name: '工作', color: 0xFF80DEEA, items: ['项目报告.docx', '演示文稿.pptx', '数据表格.xlsx']),
      DesktopZone(id: '2', name: '常用', color: 0xFFA5D6A7, items: ['浏览器', '终端', '编辑器']),
      DesktopZone(id: '3', name: '临时', color: 0xFFFFF59D, items: ['下载文件.zip', '截图_001.png']),
    ]; _save(); }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('desktop_zones', json.encode(_zones.map((e) => e.toJson()).toList()));
  }

  void _addZone() {
    final nameC = TextEditingController();
    int color = _zoneColors[_zones.length % _zoneColors.length];
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('新建分区'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '分区名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _zoneColors.map((c) => GestureDetector(
          onTap: () => setS(() => color = c),
          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: color == c ? Colors.black : Colors.transparent, width: 2))),
        )).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { if (nameC.text.isNotEmpty) { setState(() => _zones.add(DesktopZone(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, color: color))); _save(); } Navigator.pop(ctx); }, child: const Text('创建')),
      ],
    )));
  }

  void _editZone(DesktopZone zone) {
    final nameC = TextEditingController(text: zone.name);
    int color = zone.color;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('编辑分区'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '分区名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _zoneColors.map((c) => GestureDetector(
          onTap: () => setS(() => color = c),
          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: color == c ? Colors.black : Colors.transparent, width: 2))),
        )).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { setState(() { zone.name = nameC.text; zone.color = color; }); _save(); Navigator.pop(ctx); }, child: const Text('保存')),
      ],
    )));
  }

  void _addItem(DesktopZone zone) {
    final itemC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('添加到「${zone.name}」'),
      content: TextField(controller: itemC, decoration: const InputDecoration(labelText: '文件/应用名称', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { if (itemC.text.isNotEmpty) { setState(() => zone.items = [...zone.items, itemC.text]); _save(); } Navigator.pop(ctx); }, child: const Text('添加')),
      ],
    ));
  }

  void _deleteZone(DesktopZone zone) { setState(() => _zones.removeWhere((z) => z.id == zone.id)); _save(); }
  void _removeItem(DesktopZone zone, int index) { setState(() { final items = List<String>.from(zone.items); items.removeAt(index); zone.items = items; }); _save(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🖥️ 桌面分区管理'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addZone, tooltip: '新建分区'),
      ]),
      body: _zones.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.dashboard, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text('点击 + 创建桌面分区', style: TextStyle(color: Colors.grey.shade500))])) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _zones.length, itemBuilder: (ctx, i) {
        final zone = _zones[i];
        return Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 48, decoration: BoxDecoration(color: Color(zone.color).withOpacity(0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), child: Row(children: [
            const SizedBox(width: 16),
            Expanded(child: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => _addItem(zone), tooltip: '添加'),
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editZone(zone), tooltip: '编辑'),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _deleteZone(zone), tooltip: '删除'),
          ])),
          if (zone.items.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('暂无文件，点击 + 添加', style: TextStyle(color: Colors.grey)))
          else ...zone.items.asMap().entries.map((entry) => ListTile(dense: true, leading: const Icon(Icons.insert_drive_file, size: 20), title: Text(entry.value), trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeItem(zone, entry.key)))),
          const SizedBox(height: 8),
        ]);
      }),
    );
  }
}
