import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';

import 'onboarding_state.dart';

class IndustryRoleScreen extends ConsumerStatefulWidget {
  const IndustryRoleScreen({super.key});

  @override
  ConsumerState<IndustryRoleScreen> createState() => _IndustryRoleScreenState();
}

class _IndustryRoleScreenState extends ConsumerState<IndustryRoleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedIndustry;
  String? _selectedRole;
  bool _showAllOnFocus = false;

  // 完整行业-岗位映射
  static const Map<String, List<String>> industryRoleMap = {
    '互联网/AI': ['后端开发', '前端开发', '全栈开发', '移动开发', '算法工程师', '数据科学家', 'AI工程师', '机器学习', '深度学习', '自然语言处理', '计算机视觉', '产品经理', '运营', '数据分析', '运维工程师', '测试工程师', '技术总监'],
    '生产制造': ['生产工程师', '工艺工程师', '质量检验', '生产计划', '设备管理', '车间主任', '技术员', '操作工', '包装工', '装配工'],
    '设计': ['UI设计师', 'UX设计师', '平面设计师', '视觉设计师', '交互设计师', '产品设计师', '工业设计师', '服装设计师', '室内设计师', '建筑设计'],
    '物流/仓储/司机': ['物流专员', '仓储管理', '配送司机', '货运司机', '快递员', '调度员', '供应链管理', '仓库管理员', '分拣员'],
    '采购/贸易': ['采购专员', '采购经理', '外贸专员', '跟单员', '贸易经理', '供应链专员', '采购工程师', '供应商管理'],
    '房地产/建筑': ['房地产经纪人', '项目经理', '建筑师', '结构工程师', '土木工程师', '造价工程师', '监理工程师', '施工员', '安全员', '置业顾问'],
    '医疗健康': ['医生', '护士', '药剂师', '医学检验', '影像技师', '康复治疗师', '中医师', '牙医', '医疗管理', '医药代表'],
    '咨询/翻译/法律': ['咨询顾问', '管理咨询', '财务咨询', '翻译', '口译员', '律师', '法务专员', '法律顾问', '专利代理'],
    '高级管理': ['CEO', '总经理', '副总经理', '部门总监', '区域经理', '分公司经理', '合伙人', '总裁', '董事长'],
    '市场/公关/广告': ['市场专员', '品牌经理', '市场总监', '公关专员', '活动策划', '广告设计', '媒介采购', '数字营销', 'SEO专员'],
    '客服/运营': ['客服专员', '客服经理', '用户运营', '内容运营', '社区运营', '电商运营', '游戏运营', '新媒体运营', '数据运营'],
    '金融': ['投资分析师', '风险管理', '客户经理', '信贷专员', '财务顾问', '证券分析师', '基金经理', '保险精算', '银行柜员'],
    '销售': ['销售代表', '销售经理', '大客户经理', '渠道销售', '电话销售', '网络销售', '商务拓展', '销售工程师'],
    '产品': ['产品经理', '产品助理', '产品总监', '产品运营', '游戏策划', '产品设计师', '需求分析'],
    '电子/电气/通信': ['电子工程师', '电气工程师', '通信工程师', '硬件工程师', '嵌入式开发', '射频工程师', '测试工程师', 'PCB设计'],
    '酒店/旅游': ['酒店管理', '前台接待', '客房服务', '旅游顾问', '导游', '景区管理', '会展策划', '餐饮管理'],
    '教育培训': ['教师', '讲师', '培训师', '教育顾问', '课程开发', '学术研究', '教务管理', '家教', '幼师'],
    '人力/行政/法务': ['HR专员', '招聘经理', '薪酬福利', '培训发展', '行政助理', '办公室管理', '法务经理', '合规专员'],
    '直播/影视/传媒': ['主播', '编导', '摄影师', '剪辑师', '艺人经纪', '场务', '编剧', '策划', '媒体编辑'],
    '餐饮': ['厨师', '餐饮服务', '店长', '厨师长', '面点师', '西餐师', '调酒师', '餐饮管理'],
    '零售/生活服务': ['店员', '店长', '收银员', '导购', '美容师', '美发师', '健身教练', '护理员', '保洁'],
    '财务/审计/税务': ['会计师', '财务经理', '出纳', '审计师', '税务专员', '成本会计', '财务分析', '资金管理'],
    '汽车': ['汽车维修', '汽车销售', '汽车设计', '二手车评估', '汽车工程师', '4S店管理', '汽车美容'],
    '能源/环保/农业': ['能源工程师', '环保工程师', '农业技术员', '林业工程师', '水利工程师', '环境监测', '新能源开发'],
    '项目管理': ['项目经理', '项目助理', '项目协调', '项目总监', 'Scrum Master', '项目专员', '项目工程师'],
    '其他': ['其他岗位']
  };

  static const List<String> hotIndustries = [
    '互联网/AI', '金融', '教育培训', '医疗健康', '产品', '客服/运营', '销售'
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingStateProvider);
    // 检查是否在设置流程中（有临时状态）
    final isInSettingsFlow = state.tempTargetIndustry != null || state.tempTargetRole != null;
    _selectedIndustry = isInSettingsFlow ? state.tempTargetIndustry : state.targetIndustry;
    _selectedRole = isInSettingsFlow ? state.tempTargetRole : state.targetRole;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _allIndustries() => industryRoleMap.keys.toList();

  List<(String role, String industry)> _allRolesWithIndustry() {
    final List<(String, String)> list = [];
    industryRoleMap.forEach((industry, roles) {
      for (final r in roles) {
        list.add((r, industry));
      }
    });
    return list;
  }

  void _selectIndustry(String industry) {
    setState(() {
      _selectedIndustry = industry;
      _selectedRole = null;
      _searchController.clear();
      _showAllOnFocus = false;
    });
    
    final state = ref.read(onboardingStateProvider);
    final isInSettingsFlow = state.tempTargetIndustry != null || state.tempTargetRole != null;
    
    if (isInSettingsFlow) {
      ref.read(onboardingStateProvider.notifier).updateTempTargetIndustry(industry);
    } else {
      ref.read(onboardingStateProvider.notifier).updateTargetIndustry(industry);
    }
  }

  void _selectRole(String role, String industry) {
    // 允许从全局搜索直接点选岗位，同时确定行业
    setState(() {
      _selectedIndustry = industry;
      _selectedRole = role;
      _showAllOnFocus = false;
    });
    
    final state = ref.read(onboardingStateProvider);
    final isInSettingsFlow = state.tempTargetIndustry != null || state.tempTargetRole != null;
    
    if (isInSettingsFlow) {
      ref.read(onboardingStateProvider.notifier).updateTempTargetIndustry(industry);
      ref.read(onboardingStateProvider.notifier).updateTempTargetRole(role);
    } else {
      ref.read(onboardingStateProvider.notifier).updateTargetIndustry(industry);
      ref.read(onboardingStateProvider.notifier).updateTargetRole(role);
    }
  }

  void _resetIndustrySelection() {
    setState(() {
      _selectedIndustry = null;
      _selectedRole = null;
      _searchController.clear();
      _showAllOnFocus = false;
    });
    ref.read(onboardingStateProvider.notifier).resetIndustrySelection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchController.text.trim();
    final isIndustryPhase = _selectedIndustry == null;

    // 搜索逻辑
    final List<String> matchedIndustries = _allIndustries()
        .where((i) => query.isEmpty ? (_showAllOnFocus || false) : i.contains(query))
        .toList();

    final List<(String role, String industry)> matchedRolesGlobal = _allRolesWithIndustry()
        .where((ri) => query.isEmpty ? (_showAllOnFocus && isIndustryPhase) : ri.$1.contains(query) || ri.$2.contains(query))
        .toList();

    final List<String> rolesInSelectedIndustry = _selectedIndustry == null
        ? <String>[]
        : industryRoleMap[_selectedIndustry!]!;
    final List<String> matchedRolesInIndustry = rolesInSelectedIndustry
        .where((r) => query.isEmpty ? (_showAllOnFocus || false) : r.contains(query))
        .toList();

    Widget buildHotIndustries() {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: hotIndustries
            .map((i) => GestureDetector(
                  onTap: () => _selectIndustry(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedIndustry == i 
                          ? const Color(0xFF1976D2) 
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedIndustry == i 
                            ? const Color(0xFF1976D2) 
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      i,
                      style: TextStyle(
                        color: _selectedIndustry == i 
                            ? Colors.white 
                            : const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    }

    Widget buildHotRoles() {
      final roles = rolesInSelectedIndustry.take(12).toList();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: roles
            .map((r) => GestureDetector(
                  onTap: () => _selectRole(r, _selectedIndustry!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedRole == r 
                          ? const Color(0xFF1976D2) 
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedRole == r 
                            ? const Color(0xFF1976D2) 
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      r,
                      style: TextStyle(
                        color: _selectedRole == r 
                            ? Colors.white 
                            : const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    }

    Widget _buildSectionHeader(String title) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      );
    }

    Widget _buildListItem({
      required IconData icon,
      required String title,
      String? subtitle,
      bool isSelected = false,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1976D2) 
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected 
                  ? const Color(0xFF1976D2) 
                  : const Color(0xFF1A1A1A),
            ),
          ),
          subtitle: subtitle != null 
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: isSelected 
              ? const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1976D2),
                )
              : null,
          onTap: onTap,
        ),
      );
    }

    Widget _buildEmptyState() {
      return Container(
        padding: const EdgeInsets.all(40),
      child: Column(
        children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: const Color(0xFF999999),
            ),
            const SizedBox(height: 16),
            Text(
              '无匹配结果',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF666666),
              ),
            ),
          const SizedBox(height: 8),
            Text(
              '请尝试其他关键词',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const SizedBox(height: 8),
              
              // 标题区域
              Container(
                padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                  color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isIndustryPhase ? Icons.apartment_outlined : Icons.work_outline,
                            color: const Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIndustryPhase ? '选择目标行业' : '选择目标岗位',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isIndustryPhase 
                                    ? '请选择您希望从事的行业领域'
                                    : '请选择您希望从事的具体岗位',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // 面包屑导航：仅在岗位选择阶段显示
                    if (!isIndustryPhase && _selectedIndustry != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1976D2).withOpacity(0.3),
                          ),
                    ),
                    child: Row(
                      children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF1976D2),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                        Text(
                              '已选行业：',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1976D2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedIndustry!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF1976D2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _resetIndustrySelection,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                          Icons.edit,
                                  size: 14,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 搜索框
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isIndustryPhase ? '搜索行业...' : '搜索岗位...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF999999),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF1976D2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
            ),
            onTap: () {
              setState(() {
                _showAllOnFocus = true; // 点击后显示完整列表
              });
            },
            onChanged: (_) {
              setState(() {
                _showAllOnFocus = false; // 输入时按关键字过滤
              });
            },
          ),
              ),
              
              const SizedBox(height: 20),
              
              // 内容区域
          Expanded(
            child: Builder(
              builder: (_) {
                if (query.isEmpty && !_showAllOnFocus) {
                  // 初始/无输入状态，显示热门
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isIndustryPhase ? '热门行业' : '热门岗位',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (isIndustryPhase) buildHotIndustries() else buildHotRoles(),
                                ],
                              ),
                            ),
                      ],
                    ),
                  );
                }

                if (isIndustryPhase) {
                  // 行业阶段：同时显示匹配的行业和全局岗位
                  return ListView(
                    children: [
                      if (matchedIndustries.isNotEmpty) ...[
                            _buildSectionHeader('匹配的行业'),
                            ...matchedIndustries.map((i) => _buildListItem(
                              icon: Icons.apartment_outlined,
                              title: i,
                              onTap: () => _selectIndustry(i),
                            )),
                      ],
                      if (matchedRolesGlobal.isNotEmpty) ...[
                            _buildSectionHeader('匹配的岗位'),
                            ...matchedRolesGlobal.map((ri) => _buildListItem(
                              icon: Icons.work_outline,
                              title: ri.$1,
                              subtitle: ri.$2,
                              onTap: () => _selectRole(ri.$1, ri.$2),
                            )),
                      ],
                      if (matchedIndustries.isEmpty && matchedRolesGlobal.isEmpty)
                            _buildEmptyState(),
                      if (_showAllOnFocus && query.isEmpty) ...[
                            _buildSectionHeader('全部行业'),
                            ..._allIndustries().map((i) => _buildListItem(
                              icon: Icons.apartment_outlined,
                              title: i,
                              onTap: () => _selectIndustry(i),
                            )),
                      ],
                    ],
                  );
                } else {
                  // 岗位阶段：显示选中行业下匹配岗位或全部岗位
                  final list = matchedRolesInIndustry.isNotEmpty || query.isNotEmpty || _showAllOnFocus
                      ? matchedRolesInIndustry.isEmpty && (query.isEmpty && _showAllOnFocus)
                          ? rolesInSelectedIndustry
                          : matchedRolesInIndustry
                      : rolesInSelectedIndustry;

                  return ListView.separated(
                    itemBuilder: (_, idx) {
                      final r = list[idx];
                          return _buildListItem(
                            icon: Icons.work_outline,
                            title: r,
                            isSelected: _selectedRole == r,
                        onTap: () => _selectRole(r, _selectedIndustry!),
                      );
                    },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: list.length,
                  );
                }
              },
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class UploadResumeScreen extends ConsumerStatefulWidget {
  const UploadResumeScreen({super.key});

  @override
  ConsumerState<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends ConsumerState<UploadResumeScreen> {
  static const List<String> _allowedExtensions = ['pdf', 'doc', 'docx'];
  static const int _maxSizeBytes = 10 * 1024 * 1024; // 10 MB

  bool _isPicking = false;
  String? _error;

  String _formatSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }


  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );
      if (result == null) {
        setState(() => _isPicking = false);
        return; // user canceled
      }

      final picked = result.files.single;
      final path = picked.path; // may be null on some platforms
      final name = picked.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      if (!_allowedExtensions.contains(ext)) {
        setState(() {
          _isPicking = false;
          _error = '仅支持文件类型: ${_allowedExtensions.join(', ')}';
        });
        return;
      }

      // Prefer picker-reported size to avoid sandbox read issues on macOS.
      int? size = picked.size;
      if (size == null && path != null) {
        try {
          size = await File(path).length();
        } catch (_) {}
      }
      size ??= 0;

      if (size <= 0) {
        setState(() {
          _isPicking = false;
          _error = '文件大小为 0，无法上传';
        });
        return;
      }

      if (size > _maxSizeBytes) {
        setState(() {
          _isPicking = false;
          _error = '文件过大（${_formatSize(size!)}），最大支持 ${_formatSize(_maxSizeBytes)}';
        });
        return;
      }
      // 解析文件内容
      String? resumeText;
      if (ext == 'pdf') {
        try {
          Uint8List bytes;
          if (kIsWeb) {
            // 在Web环境中，file_picker返回的PlatformFile已经包含bytes
            bytes = picked.bytes!;
          } else {
            // 在移动/桌面环境中，使用File读取
            final file = File(path!);
            bytes = await file.readAsBytes();
          }
          final document = PdfDocument(inputBytes: bytes);
          resumeText = PdfTextExtractor(document).extractText();
          document.dispose();
          print('PDF解析成功，文本长度: ${resumeText.length}');
        } catch (e) {
          print('PDF解析失败: $e');
          // PDF解析失败不影响文件上传，只是没有文本内容
        }
      } else if (ext == 'docx') {
        try {
          // 在Web环境中，file_picker返回的PlatformFile已经包含bytes
          if (kIsWeb) {
            final bytes = picked.bytes;
            if (bytes != null) {
              resumeText = await docxToText(bytes);
              print('Word文档解析成功，文本长度: ${resumeText.length}');
            }
          } else {
            // 在移动/桌面环境中，使用File读取
            final file = File(path!);
            final bytes = await file.readAsBytes();
            resumeText = await docxToText(bytes);
            print('Word文档解析成功，文本长度: ${resumeText.length}');
          }
        } catch (e) {
          print('Word文档解析失败: $e');
          // Word解析失败不影响文件上传，只是没有文本内容
        }
      } else if (ext == 'doc') {
        // .doc格式比较复杂，暂时不支持
        print('.doc格式暂不支持，请使用.docx或PDF格式');
      }

      // 存储文件信息
      final state = ref.read(onboardingStateProvider);
      final isInSettingsFlow = state.tempTargetIndustry != null || state.tempTargetRole != null;
      
      if (path != null) {
        final fileToStore = File(path);
        if (isInSettingsFlow) {
          ref.read(onboardingStateProvider.notifier).updateTempResumeFile(fileToStore);
        } else {
          ref.read(onboardingStateProvider.notifier).updateResumeFile(fileToStore);
        }
      }
      if (resumeText != null && resumeText.isNotEmpty) {
        if (isInSettingsFlow) {
          ref.read(onboardingStateProvider.notifier).updateTempResumeText(resumeText);
        } else {
          ref.read(onboardingStateProvider.notifier).updateResumeText(resumeText);
        }
      }
      
      setState(() {
        _isPicking = false;
        _error = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resumeText != null ? '简历已选择并解析' : '简历已选择')),
        );
      }
    } catch (e) {
      setState(() {
        _isPicking = false;
        _error = '选择文件时出错: $e';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingStateProvider);
    final isInSettingsFlow = state.tempTargetIndustry != null || state.tempTargetRole != null;
    final file = isInSettingsFlow ? state.tempResumeFile : state.resumeFile;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              const SizedBox(height: 8),
              
              // 标题区域
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
              children: [
                Container(
                          width: 40,
                          height: 40,
                  decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '上传简历',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AI将分析您的简历，为您生成高度相关的面试问题',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 支持格式说明
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF1976D2),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '支持格式：PDF、Word(.docx)，文件大小不超过10MB',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1976D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 上传区域
              Expanded(
                child: GestureDetector(
                  onTap: _isPicking ? null : _pickFile,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: file != null 
                            ? const Color(0xFF1976D2) 
                            : const Color(0xFFE0E0E0),
                        width: file != null ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: file == null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1976D2).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 40,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '点击选择简历文件',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '支持PDF、Word格式，最大10MB',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline,
                                        size: 40,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '简历已上传',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4CAF50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      file.path.split('/').last,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<int>(
                                      future: file.length(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) return const SizedBox.shrink();
                                        return Text(
                                          _formatSize(snapshot.data!),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFF999999),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _isPicking ? null : _pickFile,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('重新选择'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF1976D2),
                                        side: const BorderSide(color: Color(0xFF1976D2)),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        if (_isPicking)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '正在处理文件...',
                                      style: TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
          if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class JobDescriptionScreen extends ConsumerWidget {
  const JobDescriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingStateProvider);
    final isInSettingsFlow = state.tempTargetIndustry != null || state.tempTargetRole != null;
    final jobDescription = isInSettingsFlow ? state.tempJobDescription : state.jobDescription;
    final TextEditingController controller = TextEditingController(
      text: jobDescription,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              const SizedBox(height: 8),
              
              // 标题区域
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '岗位描述（可选）',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '粘贴您心仪岗位的招聘描述，AI将结合简历与JD，为您生成最佳问题',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 提示信息
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1976D2).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF1976D2),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '提供岗位描述可以让AI生成更精准的面试问题',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1976D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 输入区域
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '岗位招聘描述',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
          const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
            controller: controller,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: '请粘贴岗位招聘描述（JD）...\n\n例如：\n• 负责产品功能设计和优化\n• 协调各部门资源，推进项目进度\n• 分析用户需求，制定产品策略\n• 3年以上产品经理经验\n• 熟悉互联网产品开发流程',
                            hintStyle: TextStyle(
                              color: const Color(0xFF999999),
                              height: 1.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (val) {
              final state = ref.read(onboardingStateProvider);
              final isInSettingsFlow = state.tempTargetIndustry != null || state.tempTargetRole != null;
              if (isInSettingsFlow) {
                ref.read(onboardingStateProvider.notifier).updateTempJobDescription(val);
              } else {
                ref.read(onboardingStateProvider.notifier).updateJobDescription(val);
              }
            },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: const Color(0xFF999999),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '您也可以跳过此步骤，直接开始面试练习',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


