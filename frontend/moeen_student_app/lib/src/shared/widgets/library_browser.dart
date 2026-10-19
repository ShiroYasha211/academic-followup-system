import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'moeen_dialogs.dart';

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
    this.gradient,
    this.heroIcon,
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
  final Gradient? gradient;
  final IconData? heroIcon;
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
  bool _isGrid = false;
  int? _downloadingId;

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
  int? get _availableFiles {
    if (_children.any((item) => _id(item['items_count']) == null)) return null;
    return _children.fold<int>(
      _resourceTotal,
      (total, item) => total + (_id(item['items_count']) ?? 0),
    );
  }

  bool _can(String key) => _capabilities[key] == true;
  int? _id(Object? value) => int.tryParse(value?.toString() ?? '');

  Future<void> _handleDownload(LibraryJson item) async {
    final id = _id(item['id']);
    if (id != null) setState(() => _downloadingId = id);
    try {
      await widget.onDownload(item);
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

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
        color: AppColors.slate50,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: widget.accentColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _header()),
                  SliverToBoxAdapter(child: _searchBar()),
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
                    if (_children.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _sectionHeader(
                          'الأقسام والمجلدات',
                          _children.length,
                          showToggle: _resourceItems.isEmpty,
                        ),
                      ),
                      if (_isGrid)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.15,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _nodeGridTile(_children[index], index),
                              childCount: _children.length,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.separated(
                            itemCount: _children.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) =>
                                _nodeListTile(_children[index], index),
                          ),
                        ),
                    ],
                    if (_resourceItems.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _sectionHeader(
                          'الملفات التعليمية',
                          _resourceTotal,
                          showToggle: true,
                        ),
                      ),
                      if (_isGrid)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.82,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _resourceGridTile(_resourceItems[index]),
                              childCount: _resourceItems.length,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.separated(
                            itemCount: _resourceItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) =>
                                _resourceListTile(_resourceItems[index]),
                          ),
                        ),
                    ],
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
            if (_managementActions().isNotEmpty)
              PositionedDirectional(
                bottom: 24,
                start: 16,
                child: _buildFloatingActionMenu(),
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
    final gradient =
        widget.gradient ??
        LinearGradient(
          colors: [
            widget.accentColor,
            widget.accentColor.withValues(alpha: 0.82),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
    final icon = widget.heroIcon ?? Icons.account_tree_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 25),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                height: 1.35,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_data != null && _availableFiles != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _availableFiles == 0
                                ? 'لا توجد ملفات في هذا المسار حالياً'
                                : 'إجمالي الملفات المتاحة في هذا المسار: $_availableFiles',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.midnight.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.slate200),
        ),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _load(page: 1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.midnight,
            fontFamily: 'Cairo',
          ),
          decoration: InputDecoration(
            hintText: 'ابحث داخل هذا المستوى...',
            hintStyle: const TextStyle(
              color: AppColors.slate400,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: widget.accentColor,
              size: 21,
            ),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح البحث',
                    onPressed: () {
                      _search.clear();
                      _load(page: 1);
                    },
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.slate400,
                      size: 19,
                    ),
                  ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: widget.accentColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _breadcrumbBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _breadcrumbs.length + 1,
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 17,
            color: AppColors.slate400,
          ),
        ),
        itemBuilder: (_, index) {
          final home = index == 0;
          final item = home
              ? <String, dynamic>{'key': 'root', 'title': 'الرئيسية'}
              : _breadcrumbs[index - 1];
          final active = item['key']?.toString() == _node;
          final title = item['title']?.toString() ?? '';

          return InkWell(
            onTap: active
                ? null
                : () => _navigate(item['key']?.toString() ?? 'root'),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: active ? widget.accentColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? widget.accentColor : AppColors.slate200,
                  width: 1,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (home) ...[
                    Icon(
                      Icons.home_rounded,
                      size: 14,
                      color: active ? Colors.white : widget.accentColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                      color: active ? Colors.white : AppColors.slate700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
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

  Widget _buildFloatingActionMenu() {
    final actions = _managementActions();
    if (actions.isEmpty) return const SizedBox.shrink();

    if (actions.length == 1 && actions.contains('upload')) {
      return FloatingActionButton.extended(
        onPressed: _showUpload,
        backgroundColor: widget.accentColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(
          Icons.cloud_upload_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: const Text(
          'رفع ملف',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: _showManagementActionsSheet,
      backgroundColor: widget.accentColor,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 22),
      label: const Text(
        'إدارة القسم',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  void _showManagementActionsSheet() {
    final actions = _managementActions();
    showMoeenBottomSheet(
      context: context,
      title: 'خيارات إدارة القسم',
      icon: Icons.tune_rounded,
      color: widget.accentColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actions.contains('upload'))
              _managementSheetTile(
                icon: Icons.cloud_upload_rounded,
                title: 'رفع ملف جديد',
                subtitle: 'إضافة ملف تعليمي (PDF، عرض، ملخص) في هذا المسار',
                color: widget.accentColor,
                onTap: () {
                  Navigator.pop(context);
                  _showUpload();
                },
              ),
            if (actions.contains('create'))
              _managementSheetTile(
                icon: Icons.create_new_folder_rounded,
                title: 'إنشاء قسم جديد',
                subtitle: 'إضافة مجلد أو تصنيف فرعي داخل هذا المستوى',
                color: const Color(0xFF0F766E),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateNode();
                },
              ),
            if (actions.contains('edit'))
              _managementSheetTile(
                icon: Icons.edit_note_rounded,
                title: 'تعديل اسم القسم',
                subtitle: 'تغيير عنوان المجلد الحالي',
                color: const Color(0xFFD97706),
                onTap: () {
                  Navigator.pop(context);
                  _showEditNode();
                },
              ),
            if (actions.contains('delete'))
              _managementSheetTile(
                icon: Icons.delete_forever_rounded,
                title: 'حذف القسم الحالي',
                subtitle: 'حذف هذا المجلد وفروعه من المكتبة',
                color: AppColors.danger,
                danger: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _managementSheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: danger ? AppColors.danger.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: danger
              ? AppColors.danger.withValues(alpha: 0.2)
              : AppColors.slate200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
            color: danger ? AppColors.danger : AppColors.midnight,
            fontFamily: 'Cairo',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: danger
                ? AppColors.danger.withValues(alpha: 0.8)
                : AppColors.slate500,
            fontFamily: 'Cairo',
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: danger ? AppColors.danger : AppColors.slate400,
          size: 20,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count, {bool showToggle = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: widget.accentColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showToggle)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _viewModeButton(
                    icon: Icons.view_list_rounded,
                    selected: !_isGrid,
                    onTap: () => setState(() => _isGrid = false),
                    tooltip: 'عرض كقائمة',
                  ),
                  const SizedBox(width: 2),
                  _viewModeButton(
                    icon: Icons.grid_view_rounded,
                    selected: _isGrid,
                    onTap: () => setState(() => _isGrid = true),
                    tooltip: 'عرض كشبكة',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _viewModeButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? widget.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : AppColors.slate500,
          ),
        ),
      ),
    );
  }

  Widget _nodeListTile(LibraryJson item, int index) {
    final key = item['key']?.toString() ?? '';
    final type = item['type']?.toString();
    final itemsCount = _id(item['items_count']);
    final empty = itemsCount == 0;
    final badge = _nodeBadgeInfo(type, empty);
    final canReorder =
        _can('can_reorder_sections') &&
        widget.onReorder != null &&
        key.startsWith('custom:');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: empty
              ? AppColors.slate200
              : badge.color.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          minTileHeight: 70,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 6, 8, 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onTap: () => _navigate(key),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(badge.icon, color: badge.color, size: 24),
          ),
          title: Text(
            item['title']?.toString() ?? 'قسم',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              color: AppColors.midnight,
              fontFamily: 'Cairo',
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge.label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate600,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                if (itemsCount != null) const SizedBox(width: 6),
                if (itemsCount != null)
                  Text(
                    _itemsLabel(itemsCount),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: itemsCount > 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: itemsCount > 0
                          ? widget.accentColor
                          : AppColors.slate400,
                      fontFamily: 'Cairo',
                    ),
                  ),
              ],
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
              : Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.slate500,
                    size: 19,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _nodeGridTile(LibraryJson item, int index) {
    final key = item['key']?.toString() ?? '';
    final type = item['type']?.toString();
    final itemsCount = _id(item['items_count']);
    final empty = itemsCount == 0;
    final badge = _nodeBadgeInfo(type, empty);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: empty
              ? AppColors.slate200
              : badge.color.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(key),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(badge.icon, color: badge.color, size: 21),
                    ),
                    if (itemsCount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: itemsCount > 0
                              ? widget.accentColor.withValues(alpha: 0.1)
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _itemsLabel(itemsCount),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: itemsCount > 0
                                ? widget.accentColor
                                : AppColors.slate500,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']?.toString() ?? 'قسم',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: AppColors.midnight,
                        fontFamily: 'Cairo',
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate400,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<LibraryJson> get _resourceItems => _maps(_resources['data']);
  int get _lastPage => _id(_map(_resources['pagination'])['last_page']) ?? 1;

  Widget _resourceListTile(LibraryJson item) {
    final rawType = item['file_type']?.toString() ?? 'FILE';
    final badge = _fileBadgeInfo(rawType);
    final id = _id(item['id']);
    final isDownloading = _downloadingId != null && _downloadingId == id;
    final subjectName = _map(item['subject'])['name']?.toString();
    final uploaderName = _map(item['uploader'])['name']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          minTileHeight: 74,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 6, 10, 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: badge.gradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.28),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(badge.icon, color: Colors.white, size: 19),
                Text(
                  badge.label,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            item['title']?.toString() ?? 'ملف',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              color: AppColors.midnight,
              fontFamily: 'Cairo',
              height: 1.25,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (subjectName != null && subjectName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 11,
                          color: widget.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: widget.accentColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (uploaderName != null && uploaderName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 11,
                          color: AppColors.slate500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          uploaderName,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          trailing: isDownloading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'تحميل الملف',
                  onPressed: () => _handleDownload(item),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.accentColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.download_rounded,
                    color: widget.accentColor,
                    size: 20,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _resourceGridTile(LibraryJson item) {
    final rawType = item['file_type']?.toString() ?? 'FILE';
    final badge = _fileBadgeInfo(rawType);
    final id = _id(item['id']);
    final isDownloading = _downloadingId != null && _downloadingId == id;
    final subjectName = _map(item['subject'])['name']?.toString();
    final uploaderName = _map(item['uploader'])['name']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: badge.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: badge.color.withValues(alpha: 0.28),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(badge.icon, color: Colors.white, size: 18),
                        Text(
                          badge.label,
                          style: const TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (uploaderName != null && uploaderName.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          uploaderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item['title']?.toString() ?? 'ملف',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.midnight,
                  fontFamily: 'Cairo',
                  height: 1.25,
                ),
              ),
              if (subjectName != null && subjectName.isNotEmpty)
                Text(
                  subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: FilledButton.icon(
                  onPressed: isDownloading ? null : () => _handleDownload(item),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: isDownloading
                      ? const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 15),
                  label: Text(
                    isDownloading ? 'جاري التحميل...' : 'تحميل',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, Gradient gradient, IconData icon, String label})
  _fileBadgeInfo(String rawType) {
    final type = rawType.toUpperCase().trim();
    if (type == 'PDF') {
      return (
        color: const Color(0xFFE11D48),
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.picture_as_pdf_rounded,
        label: 'PDF',
      );
    }
    if (type == 'PPT' || type == 'PPTX') {
      return (
        color: const Color(0xFFEA580C),
        gradient: const LinearGradient(
          colors: [Color(0xFFFB923C), Color(0xFFC2410C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.slideshow_rounded,
        label: 'PPTX',
      );
    }
    if (type == 'DOC' || type == 'DOCX') {
      return (
        color: const Color(0xFF2563EB),
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.description_rounded,
        label: 'DOCX',
      );
    }
    if (type == 'XLS' || type == 'XLSX') {
      return (
        color: const Color(0xFF059669),
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.table_chart_rounded,
        label: 'XLSX',
      );
    }
    if (type == 'ZIP' || type == 'RAR' || type == '7Z') {
      return (
        color: const Color(0xFF7C3AED),
        gradient: const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.folder_zip_rounded,
        label: 'ZIP',
      );
    }
    return (
      color: AppColors.slate600,
      gradient: const LinearGradient(
        colors: [AppColors.slate500, AppColors.slate700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.insert_drive_file_rounded,
      label: type.length > 4
          ? type.substring(0, 4)
          : (type.isEmpty ? 'FILE' : type),
    );
  }

  ({Color color, IconData icon, String label}) _nodeBadgeInfo(
    String? type,
    bool empty,
  ) {
    if (empty) {
      return (
        color: AppColors.slate400,
        icon: Icons.folder_open_rounded,
        label: _nodeTypeLabel(type),
      );
    }
    return switch (type) {
      'major' => (
        color: const Color(0xFF7C3AED),
        icon: Icons.school_rounded,
        label: 'تخصص',
      ),
      'level' => (
        color: const Color(0xFF0284C7),
        icon: Icons.stairs_rounded,
        label: 'مستوى دراسي',
      ),
      'term' || 'semester' => (
        color: const Color(0xFFD97706),
        icon: Icons.calendar_month_rounded,
        label: 'فصل دراسي',
      ),
      'subject' => (
        color: widget.accentColor,
        icon: Icons.menu_book_rounded,
        label: 'مادة دراسية',
      ),
      'section' => (
        color: const Color(0xFF0F766E),
        icon: Icons.folder_copy_rounded,
        label: 'قسم محتوى',
      ),
      _ => (
        color: widget.accentColor,
        icon: Icons.folder_rounded,
        label: 'مجلد',
      ),
    };
  }

  Widget _loadingState() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
    child: Column(
      children: List.generate(
        5,
        (index) => Container(
          height: 74,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: AppColors.midnight.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: index.isEven ? 160 : 210,
                      decoration: BoxDecoration(
                        color: AppColors.slate200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 9,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(5),
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

  Widget _emptyState() {
    final canUpload = _managementActions().contains('upload');
    final canCreate = _managementActions().contains('create');

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 38,
                color: widget.accentColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'هذا القسم فارغ حالياً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'لا توجد مجلدات أو ملفات تعليمية متاحة في هذا المسار حالياً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.slate500,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (canUpload)
                  FilledButton.icon(
                    onPressed: _showUpload,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: const Text(
                      'رفع ملف هنا',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (canCreate)
                  FilledButton.icon(
                    onPressed: _showCreateNode,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                    label: const Text(
                      'إنشاء قسم جديد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _load,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.accentColor,
                    side: BorderSide(
                      color: widget.accentColor.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'تحديث',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
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

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 30,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'تعذر تحميل المحتوى',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error.toString().replaceAll('ApiException: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate500,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: widget.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showCreateNode() async {
    final title = await _textBottomSheet(
      title: 'إنشاء قسم جديد',
      hint: 'اسم القسم أو المجلد',
      icon: Icons.create_new_folder_rounded,
    );
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
    final title = await _textBottomSheet(
      title: 'تعديل اسم القسم',
      hint: 'اسم القسم',
      initial: _context['current_node_title']?.toString(),
      icon: Icons.edit_note_rounded,
    );
    if (title == null || nodeId == null || widget.onUpdateNode == null) return;
    await _run(() => widget.onUpdateNode!(nodeId, title), reload: true);
  }

  Future<void> _confirmDelete() async {
    final nodeId = _id(_context['current_node_id']);
    if (nodeId == null || widget.onDeleteNode == null) return;
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف القسم',
      message:
          'سيتم حذف هذا القسم وفروعه نهائياً من المكتبة. هل تريد المتابعة؟',
      confirmLabel: 'حذف القسم',
      cancelLabel: 'إلغاء',
      danger: true,
      icon: Icons.delete_forever_rounded,
    );
    if (confirmed && mounted) {
      final deleted = await _run(() => widget.onDeleteNode!(nodeId));
      if (deleted && mounted) _navigate(_parentNodeKey());
    }
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

    final accepted = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'رفع ملف تعليمي',
      icon: Icons.cloud_upload_rounded,
      color: widget.accentColor,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                  decoration: InputDecoration(
                    labelText: 'عنوان الملف *',
                    labelStyle: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 12.5,
                      fontFamily: 'Cairo',
                    ),
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: widget.accentColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: widget.accentColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                  decoration: InputDecoration(
                    labelText: 'وصف اختياري',
                    labelStyle: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 12.5,
                      fontFamily: 'Cairo',
                    ),
                    prefixIcon: const Icon(
                      Icons.notes_rounded,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: widget.accentColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                  decoration: InputDecoration(
                    labelText: 'نطاق الظهور',
                    labelStyle: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 12.5,
                      fontFamily: 'Cairo',
                    ),
                    prefixIcon: Icon(
                      Icons.visibility_rounded,
                      color: widget.accentColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: widget.accentColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'batch', child: Text('الدفعة فقط')),
                    DropdownMenuItem(
                      value: 'college',
                      child: Text('الكلية كاملة'),
                    ),
                    DropdownMenuItem(value: 'everyone', child: Text('الجميع')),
                  ],
                  onChanged: (value) =>
                      setLocal(() => visibility = value ?? 'batch'),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await FilePicker.platform.pickFiles(
                      withData: false,
                    );
                    if (picked != null && picked.files.isNotEmpty) {
                      setLocal(() {
                        file = picked.files.first;
                        if (title.text.trim().isEmpty) {
                          title.text = file!.name;
                        }
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: file != null
                          ? widget.accentColor.withValues(alpha: 0.08)
                          : AppColors.slate50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: file != null
                            ? widget.accentColor.withValues(alpha: 0.4)
                            : AppColors.slate200,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: file != null
                                ? widget.accentColor.withValues(alpha: 0.15)
                                : AppColors.slate200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            file != null
                                ? Icons.file_present_rounded
                                : Icons.attach_file_rounded,
                            color: file != null
                                ? widget.accentColor
                                : AppColors.slate600,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file?.name ?? 'اضغط لاختيار ملف من جهازك',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: file != null
                                      ? widget.accentColor
                                      : AppColors.slate600,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                file != null
                                    ? '${(file!.size / (1024 * 1024)).toStringAsFixed(2)} MB'
                                    : 'يدعم PDF، Word، عروض، والمستندات',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.slate400,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (file != null)
                          IconButton(
                            onPressed: () => setLocal(() => file = null),
                            icon: const Icon(
                              Icons.cancel_rounded,
                              color: AppColors.slate400,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (title.text.trim().isNotEmpty && file?.path != null) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'تأكيد الرفع',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Future<String?> _textBottomSheet({
    required String title,
    required String hint,
    String? initial,
    required IconData icon,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showMoeenBottomSheet<String>(
      context: context,
      title: title,
      icon: icon,
      color: widget.accentColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 150,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
                fontFamily: 'Cairo',
              ),
              decoration: InputDecoration(
                labelText: hint,
                labelStyle: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 12.5,
                  fontFamily: 'Cairo',
                ),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) Navigator.pop(context, text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: widget.accentColor,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
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
}
