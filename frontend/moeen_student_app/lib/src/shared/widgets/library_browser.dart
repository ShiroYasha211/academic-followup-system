import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

typedef LibraryJson = Map<String, dynamic>;
typedef LibraryLoadCallback =
    Future<LibraryJson> Function(String node, String? search, int page);
typedef LibraryResourceCallback = Future<void> Function(LibraryJson resource);
typedef LibraryCreateNodeCallback =
    Future<void> Function(int spaceId, int? parentId, String title);
typedef LibraryUpdateNodeCallback =
    Future<void> Function(int nodeId, String title);
typedef LibraryDeleteNodeCallback = Future<void> Function(int nodeId);
typedef LibraryReorderCallback =
    Future<void> Function(int spaceId, List<LibraryJson> items);
typedef LibraryUploadCallback =
    Future<void> Function(
      int nodeId,
      String title,
      String description,
      String visibility,
      PlatformFile file,
    );

class LibraryBrowser extends StatefulWidget {
  const LibraryBrowser({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.load,
    required this.onDownload,
    this.onCreateNode,
    this.onUpdateNode,
    this.onDeleteNode,
    this.onReorder,
    this.onUpload,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final LibraryLoadCallback load;
  final LibraryResourceCallback onDownload;
  final LibraryCreateNodeCallback? onCreateNode;
  final LibraryUpdateNodeCallback? onUpdateNode;
  final LibraryDeleteNodeCallback? onDeleteNode;
  final LibraryReorderCallback? onReorder;
  final LibraryUploadCallback? onUpload;

  @override
  State<LibraryBrowser> createState() => _LibraryBrowserState();
}

class _LibraryBrowserState extends State<LibraryBrowser> {
  final _search = TextEditingController();
  LibraryJson? _data;
  Object? _error;
  String _node = 'root';
  int _page = 1;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({String? node, int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (node != null) _node = node;
      _page = page;
    });
    try {
      final result = await widget.load(
        _node,
        _search.text.trim().isEmpty ? null : _search.text.trim(),
        _page,
      );
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  LibraryJson get _context => _map(_data?['context']);
  LibraryJson get _capabilities => _map(_data?['capabilities']);
  List<LibraryJson> get _children => _maps(_data?['children']);
  List<LibraryJson> get _breadcrumbs => _maps(_data?['breadcrumbs']);
  LibraryJson get _resources => _map(_data?['resources']);
  int get _resourceTotal =>
      _id(_map(_resources['pagination'])['total']) ?? _resourceItems.length;
  int get _availableFiles => _children.fold<int>(
    _resourceTotal,
    (total, item) => total + (_id(item['items_count']) ?? 0),
  );

  bool _can(String key) => _capabilities[key] == true;
  int? _id(Object? value) => int.tryParse(value?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _node == 'root',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _node != 'root') {
          _navigate(_parentNodeKey());
        }
      },
      child: ColoredBox(
        color: const Color(0xFFF6F8FB),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: widget.accentColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _header()),
                  if (_breadcrumbs.isNotEmpty)
                    SliverToBoxAdapter(child: _breadcrumbBar()),
                  if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _errorState(),
                    )
                  else if (_loading && _data == null)
                    SliverToBoxAdapter(child: _loadingState())
                  else ...[
                    if (_managementActions().isNotEmpty)
                      SliverToBoxAdapter(child: _managementBar()),
                    if (_children.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _sectionLabel('الأقسام', _children.length),
                      ),
                    SliverList.separated(
                      itemCount: _children.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          _nodeTile(_children[index], index),
                    ),
                    if (_resourceItems.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _sectionLabel('الملفات', _resourceTotal),
                      ),
                    SliverList.separated(
                      itemCount: _resourceItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          _resourceTile(_resourceItems[index]),
                    ),
                    if (_children.isEmpty &&
                        _resourceItems.isEmpty &&
                        !_loading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptyState(),
                      ),
                    if (_lastPage > 1) SliverToBoxAdapter(child: _pagination()),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ],
              ),
            ),
            if (_loading && _data != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(color: widget.accentColor),
              ),
            if (_working)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x22000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECF2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: .18),
                  ),
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  color: widget.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_data != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 17,
                  color: widget.accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _availableFiles == 0
                      ? 'لا توجد ملفات في هذا المسار حالياً'
                      : 'إجمالي الملفات المتاحة في هذا المسار: $_availableFiles',
                  style: TextStyle(
                    color: _availableFiles == 0
                        ? const Color(0xFF7A8699)
                        : const Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _load(page: 1),
            decoration: InputDecoration(
              hintText: 'ابحث داخل هذا المستوى...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        _search.clear();
                        _load(page: 1);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.accentColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breadcrumbBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: _breadcrumbs.length + 1,
        separatorBuilder: (_, _) => const Icon(
          Icons.chevron_left_rounded,
          size: 18,
          color: Color(0xFF98A2B3),
        ),
        itemBuilder: (_, index) {
          final home = index == 0;
          final item = home
              ? <String, dynamic>{'key': 'root', 'title': 'البداية'}
              : _breadcrumbs[index - 1];
          final active = item['key']?.toString() == _node;
          return TextButton.icon(
            onPressed: active
                ? null
                : () => _navigate(item['key']?.toString() ?? 'root'),
            icon: home
                ? const Icon(Icons.home_rounded, size: 17)
                : const SizedBox.shrink(),
            label: Text(item['title']?.toString() ?? ''),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              foregroundColor: active
                  ? const Color(0xFF344054)
                  : widget.accentColor,
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigate(String node) {
    _search.clear();
    _load(node: node, page: 1);
  }

  List<String> _managementActions() {
    final actions = <String>[];
    if (_can('can_create_sections') &&
        widget.onCreateNode != null &&
        _id(_context['library_space_id']) != null) {
      actions.add('create');
    }
    if (_can('can_upload') &&
        widget.onUpload != null &&
        _id(_context['current_node_id']) != null) {
      actions.add('upload');
    }
    if (_can('can_update_sections') &&
        widget.onUpdateNode != null &&
        _id(_context['current_node_id']) != null) {
      actions.add('edit');
    }
    if (_can('can_delete_sections') &&
        widget.onDeleteNode != null &&
        _id(_context['current_node_id']) != null &&
        _context['current_node_is_system'] != true) {
      actions.add('delete');
    }
    return actions;
  }

  Widget _managementBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_managementActions().contains('create'))
            _actionButton(
              Icons.create_new_folder_rounded,
              'قسم جديد',
              _showCreateNode,
            ),
          if (_managementActions().contains('upload'))
            _actionButton(Icons.upload_file_rounded, 'رفع ملف', _showUpload),
          if (_managementActions().contains('edit'))
            _actionButton(Icons.edit_rounded, 'تعديل القسم', _showEditNode),
          if (_managementActions().contains('delete'))
            _actionButton(
              Icons.delete_outline_rounded,
              'حذف القسم',
              _confirmDelete,
              danger: true,
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback action, {
    bool danger = false,
  }) {
    return OutlinedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? const Color(0xFFB42318) : widget.accentColor,
        side: BorderSide(
          color: danger
              ? const Color(0xFFFECACA)
              : widget.accentColor.withValues(alpha: .35),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _sectionLabel(String title, int count) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF273247),
            ),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF7A8699),
          ),
        ),
      ],
    ),
  );

  Widget _nodeTile(LibraryJson item, int index) {
    final key = item['key']?.toString() ?? '';
    final type = item['type']?.toString();
    final itemsCount = _id(item['items_count']) ?? 0;
    final empty = item['is_empty'] == true || itemsCount == 0;
    final canReorder =
        _can('can_reorder_sections') &&
        widget.onReorder != null &&
        key.startsWith('custom:');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: empty ? const Color(0xFFFBFCFE) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: empty
                ? const Color(0xFFE7EBF0)
                : widget.accentColor.withValues(alpha: .2),
          ),
        ),
        child: ListTile(
          minTileHeight: 74,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 5, 8, 5),
          onTap: () => _navigate(key),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: empty
                  ? const Color(0xFFF0F2F5)
                  : widget.accentColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              _nodeIcon(type),
              color: empty ? const Color(0xFF98A2B3) : widget.accentColor,
              size: 21,
            ),
          ),
          title: Text(
            item['title']?.toString() ?? 'قسم',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: empty ? const Color(0xFF5E6A7D) : const Color(0xFF202A3B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_nodeTypeLabel(type)}  •  ${_itemsLabel(itemsCount)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: itemsCount > 0 ? FontWeight.w700 : FontWeight.w500,
                color: itemsCount > 0
                    ? widget.accentColor
                    : const Color(0xFF98A2B3),
              ),
            ),
          ),
          trailing: canReorder
              ? PopupMenuButton<String>(
                  tooltip: 'ترتيب القسم',
                  onSelected: (direction) => _reorder(index, direction),
                  itemBuilder: (_) => [
                    if (index > 0)
                      const PopupMenuItem(
                        value: 'up',
                        child: Text('تحريك لأعلى'),
                      ),
                    if (index < _children.length - 1)
                      const PopupMenuItem(
                        value: 'down',
                        child: Text('تحريك لأسفل'),
                      ),
                  ],
                )
              : const Icon(Icons.chevron_left_rounded),
        ),
      ),
    );
  }

  List<LibraryJson> get _resourceItems => _maps(_resources['data']);
  int get _lastPage => _id(_map(_resources['pagination'])['last_page']) ?? 1;

  Widget _resourceTile(LibraryJson item) {
    final type = item['file_type']?.toString().toUpperCase() ?? 'FILE';
    final fileColor = _fileTypeColor(type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE1E6ED)),
        ),
        child: ListTile(
          minTileHeight: 74,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 5, 4, 5),
          leading: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fileColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              type.length > 4 ? type.substring(0, 4) : type,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: fileColor,
              ),
            ),
          ),
          title: Text(
            item['title']?.toString() ?? 'ملف',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF202A3B),
            ),
          ),
          subtitle: Text(
            _resourceMeta(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF667085)),
          ),
          trailing: IconButton(
            tooltip: 'تحميل الملف',
            onPressed: () => _run(() => widget.onDownload(item)),
            icon: Icon(Icons.download_rounded, color: widget.accentColor),
          ),
        ),
      ),
    );
  }

  String _resourceMeta(LibraryJson item) {
    final parts = <String>[
      if (_map(item['subject'])['name'] != null)
        _map(item['subject'])['name'].toString(),
      if (_map(item['uploader'])['name'] != null)
        _map(item['uploader'])['name'].toString(),
    ];
    return parts.isEmpty ? 'مورد تعليمي' : parts.join(' · ');
  }

  Widget _loadingState() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 96),
    child: Column(
      children: List.generate(
        6,
        (index) => Container(
          height: 74,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7EBF0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF1F5),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: index.isEven ? .62 : .78,
                      child: Container(
                        height: 11,
                        color: const Color(0xFFE8ECF1),
                      ),
                    ),
                    const SizedBox(height: 9),
                    FractionallySizedBox(
                      widthFactor: .38,
                      child: Container(
                        height: 8,
                        color: const Color(0xFFF0F2F5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _pagination() {
    final pagination = _map(_resources['pagination']);
    final current = _id(pagination['current_page']) ?? 1;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: current > 1 ? () => _load(page: current - 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'الصفحة السابقة',
          ),
          Text(
            '$current / $_lastPage',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: current < _lastPage
                ? () => _load(page: current + 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'الصفحة التالية',
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 96),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEAEEF3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 31,
              color: Color(0xFF7A8699),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'هذا القسم فارغ حالياً',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF273247),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ستظهر الملفات هنا عند إضافتها إلى هذا المسار.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Color(0xFF7A8699),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تحديث'),
          ),
        ],
      ),
    ),
  );

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFFB42318),
          ),
          const SizedBox(height: 10),
          Text(_error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );

  Future<void> _showCreateNode() async {
    final title = await _textDialog('قسم جديد', 'اسم القسم');
    final spaceId = _id(_context['library_space_id']);
    if (title == null || spaceId == null || widget.onCreateNode == null) return;
    await _run(
      () => widget.onCreateNode!(
        spaceId,
        _id(_context['current_node_id']),
        title,
      ),
      reload: true,
    );
  }

  Future<void> _showEditNode() async {
    final nodeId = _id(_context['current_node_id']);
    final title = await _textDialog(
      'تعديل القسم',
      'اسم القسم',
      initial: _context['current_node_title']?.toString(),
    );
    if (title == null || nodeId == null || widget.onUpdateNode == null) return;
    await _run(() => widget.onUpdateNode!(nodeId, title), reload: true);
  }

  Future<void> _confirmDelete() async {
    final nodeId = _id(_context['current_node_id']);
    if (nodeId == null || widget.onDeleteNode == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القسم'),
        content: const Text(
          'سيختفي القسم وفروعه من المكتبة. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _run(() => widget.onDeleteNode!(nodeId));
    if (deleted && mounted) _navigate(_parentNodeKey());
  }

  String _parentNodeKey() {
    if (_breadcrumbs.length < 2) return 'root';
    return _breadcrumbs[_breadcrumbs.length - 2]['key']?.toString() ?? 'root';
  }

  Future<void> _showUpload() async {
    final nodeId = _id(_context['current_node_id']);
    if (nodeId == null || widget.onUpload == null) return;
    final title = TextEditingController();
    final description = TextEditingController();
    PlatformFile? file;
    String visibility = 'batch';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('رفع ملف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'عنوان الملف'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'وصف اختياري'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: const InputDecoration(labelText: 'الظهور'),
                  items: const [
                    DropdownMenuItem(value: 'batch', child: Text('الدفعة')),
                    DropdownMenuItem(value: 'college', child: Text('الكلية')),
                    DropdownMenuItem(value: 'everyone', child: Text('الجميع')),
                  ],
                  onChanged: (value) =>
                      setLocal(() => visibility = value ?? 'batch'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FilePicker.platform.pickFiles(
                      withData: false,
                    );
                    if (picked != null && picked.files.isNotEmpty) {
                      setLocal(() => file = picked.files.first);
                    }
                  },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(
                    file?.name ?? 'اختيار الملف',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                title.text.trim().isNotEmpty && file?.path != null,
              ),
              child: const Text('رفع'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && file != null) {
      await _run(
        () => widget.onUpload!(
          nodeId,
          title.text.trim(),
          description.text.trim(),
          visibility,
          file!,
        ),
        reload: true,
      );
    }
    title.dispose();
    description.dispose();
  }

  Future<String?> _textDialog(
    String title,
    String label, {
    String? initial,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 150,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _reorder(int index, String direction) async {
    final target = direction == 'up' ? index - 1 : index + 1;
    final spaceId = _id(_context['library_space_id']);
    if (target < 0 ||
        target >= _children.length ||
        spaceId == null ||
        widget.onReorder == null) {
      return;
    }
    final ordered = [..._children];
    final item = ordered.removeAt(index);
    ordered.insert(target, item);
    final payload = <LibraryJson>[];
    for (var i = 0; i < ordered.length; i++) {
      final id = _id(ordered[i]['key']?.toString().split(':').last);
      if (id != null) {
        payload.add({'id': id, 'sort_order': i});
      }
    }
    await _run(() => widget.onReorder!(spaceId, payload), reload: true);
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    bool reload = false,
  }) async {
    setState(() => _working = true);
    try {
      await operation();
      if (reload) {
        await _load(page: _page);
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: const Color(0xFFB42318),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  static LibraryJson _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static List<LibraryJson> _maps(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <LibraryJson>[];

  String _itemsLabel(int count) {
    if (count == 0) return 'فارغ حالياً';
    if (count == 1) return 'ملف واحد';
    if (count == 2) return 'ملفان';
    if (count <= 10) return '$count ملفات';
    return '$count ملفاً';
  }

  String _nodeTypeLabel(String? type) => switch (type) {
    'major' => 'تخصص',
    'level' => 'مستوى دراسي',
    'term' => 'ترم دراسي',
    'semester' => 'فصل دراسي',
    'subject' => 'مادة دراسية',
    'section' => 'قسم محتوى',
    _ => 'مجلد',
  };

  Color _fileTypeColor(String type) {
    final normalized = type.toLowerCase();
    if (normalized == 'pdf') return const Color(0xFFC2414B);
    if (normalized == 'ppt' || normalized == 'pptx') {
      return const Color(0xFFC7662E);
    }
    if (normalized == 'doc' || normalized == 'docx') {
      return const Color(0xFF3568B5);
    }
    if (normalized == 'xls' || normalized == 'xlsx') {
      return const Color(0xFF2E7D5B);
    }
    if (normalized == 'zip' || normalized == 'rar') {
      return const Color(0xFF7655A6);
    }
    return const Color(0xFF526071);
  }

  IconData _nodeIcon(String? type) => switch (type) {
    'major' => Icons.school_rounded,
    'level' => Icons.stairs_rounded,
    'term' || 'semester' => Icons.calendar_month_rounded,
    'subject' => Icons.menu_book_rounded,
    _ => Icons.folder_rounded,
  };
}
