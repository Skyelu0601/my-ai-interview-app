import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_state.dart';

class ExperienceScreen extends ConsumerWidget {
  const ExperienceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experienceLevels = <String>[
      '无经验',
      '0 - 3 年（初级）',
      '3 - 5 年（中级）',
      '5 - 10 年（高级）',
      '10 年以上（专家）',
    ];

    final selectedLevel = ref.watch(onboardingStateProvider).experienceLevel;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('您有多少年相关工作经验？', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('我们将根据您的经验调整面试问题的难度。', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ...experienceLevels.map((level) => RadioListTile<String>(
                title: Text(level),
                value: level,
                groupValue: selectedLevel,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(onboardingStateProvider.notifier).updateExperienceLevel(value);
                },
              )),
        ],
      ),
    );
  }
}

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
    _selectedIndustry = state.targetIndustry;
    _selectedRole = state.targetRole;
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
    ref.read(onboardingStateProvider.notifier).updateTargetIndustry(industry);
  }

  void _selectRole(String role, String industry) {
    // 允许从全局搜索直接点选岗位，同时确定行业
    setState(() {
      _selectedIndustry = industry;
      _selectedRole = role;
      _showAllOnFocus = false;
    });
    ref.read(onboardingStateProvider.notifier).updateTargetIndustry(industry);
    ref.read(onboardingStateProvider.notifier).updateTargetRole(role);
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
            .map((i) => ChoiceChip(
                  label: Text(i),
                  selected: _selectedIndustry == i,
                  onSelected: (_) => _selectIndustry(i),
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
            .map((r) => ChoiceChip(
                  label: Text(r),
                  selected: _selectedRole == r,
                  onSelected: (_) => _selectRole(r, _selectedIndustry!),
                ))
            .toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isIndustryPhase ? '您的目标行业是？' : '您的目标岗位是？', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          // 面包屑导航：仅在岗位选择阶段显示
          if (!isIndustryPhase && _selectedIndustry != null) ...[
            Row(
              children: [
                Text('已选行业：', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _resetIndustrySelection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedIndustry!,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('点击重新选择', style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isIndustryPhase ? '搜索行业...' : '搜索岗位...',
              prefixIcon: const Icon(Icons.search),
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
          const SizedBox(height: 12),
          Expanded(
            child: Builder(
              builder: (_) {
                if (query.isEmpty && !_showAllOnFocus) {
                  // 初始/无输入状态，显示热门
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isIndustryPhase) ...[
                          Text('热门行业', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          buildHotIndustries(),
                        ] else ...[
                          Text('热门岗位', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          buildHotRoles(),
                        ],
                      ],
                    ),
                  );
                }

                if (isIndustryPhase) {
                  // 行业阶段：同时显示匹配的行业和全局岗位
                  return ListView(
                    children: [
                      if (matchedIndustries.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('匹配的行业', style: theme.textTheme.titleMedium),
                        ),
                        ...matchedIndustries.map((i) => ListTile(
                              leading: const Icon(Icons.apartment_outlined),
                              title: Text(i),
                              onTap: () => _selectIndustry(i),
                            )),
                      ],
                      if (matchedRolesGlobal.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('匹配的岗位', style: theme.textTheme.titleMedium),
                        ),
                        ...matchedRolesGlobal.map((ri) => ListTile(
                              leading: const Icon(Icons.work_outline),
                              title: Text(ri.$1),
                              subtitle: Text(ri.$2),
                              onTap: () => _selectRole(ri.$1, ri.$2),
                            )),
                      ],
                      if (matchedIndustries.isEmpty && matchedRolesGlobal.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24.0),
                          child: Center(child: Text('无匹配结果')),
                        ),
                      if (_showAllOnFocus && query.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('全部行业', style: theme.textTheme.titleMedium),
                        ),
                        ..._allIndustries().map((i) => ListTile(
                              leading: const Icon(Icons.apartment_outlined),
                              title: Text(i),
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
                      return ListTile(
                        leading: const Icon(Icons.work_outline),
                        title: Text(r),
                        trailing: _selectedRole == r ? const Icon(Icons.check, color: Colors.green) : null,
                        onTap: () => _selectRole(r, _selectedIndustry!),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: list.length,
                  );
                }
              },
            ),
          ),
        ],
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
      final fileToStore = path != null ? File(path) : null;
      if (fileToStore == null) {
        setState(() {
          _isPicking = false;
          _error = '无法访问所选文件，请重试或更换位置';
        });
        return;
      }

      ref.read(onboardingStateProvider.notifier).updateResumeFile(fileToStore);
      setState(() {
        _isPicking = false;
        _error = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('简历已选择')),
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
    final file = ref.watch(onboardingStateProvider).resumeFile;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('上传您的简历', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('AI将分析您的简历，为您生成高度相关的面试问题。支持PDF、Word格式。', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isPicking ? null : _pickFile,
            child: Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: file == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.upload_file, size: 40),
                              SizedBox(height: 8),
                              Text('点击选择或拖拽文件到此'),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(file.path.split('/').last),
                              const SizedBox(height: 4),
                              FutureBuilder<int>(
                                future: file.length(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const SizedBox.shrink();
                                  return Text(_formatSize(snapshot.data!));
                                },
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _isPicking ? null : _pickFile,
                                child: const Text('重新选择'),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_isPicking)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class JobDescriptionScreen extends ConsumerWidget {
  const JobDescriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController(
      text: ref.watch(onboardingStateProvider).jobDescription,
    );

    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.96),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('希望问题更精准？(可选)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('粘贴您心仪岗位的招聘描述，AI将结合简历与JD，为您生成最佳问题。'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '请粘贴岗位招聘描述（JD）...',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => ref.read(onboardingStateProvider.notifier).updateJobDescription(val),
          ),
        ],
      ),
    );
  }
}


