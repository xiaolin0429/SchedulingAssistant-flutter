import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/di/injection_container.dart';
import '../../../domain/services/user_profile_service.dart';
import '../../../data/models/user_profile.dart';

class UserProfileEditPage extends StatefulWidget {
  const UserProfileEditPage({super.key});

  @override
  State<UserProfileEditPage> createState() => _UserProfileEditPageState();
}

class _UserProfileEditPageState extends State<UserProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // 用户资料服务
  final _profileService = getIt<UserProfileService>();

  // 是否正在保存
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.loadUserProfile();
      setState(() {
        _nameController.text = profile.nickname ?? '';
        _bioController.text = profile.bio ?? '';
        _emailController.text = profile.email ?? '';
        _phoneController.text = profile.phone ?? '';

        // 如果有头像路径，加载头像
        if (profile.avatarPath != null && profile.avatarPath!.isNotEmpty) {
          _imageFile = File(profile.avatarPath!);
          if (!_imageFile!.existsSync()) {
            _imageFile = null;
          }
        }
      });
    } catch (e) {
      debugPrint('加载用户资料失败: $e');
      // 使用默认空值
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // 防止重复点击保存按钮
      if (_isSaving) return;

      setState(() {
        _isSaving = true;
      });

      try {
        // 创建用户资料对象
        final profile = UserProfile(
          nickname: _nameController.text,
          bio: _bioController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          avatarPath: _imageFile?.path,
        );

        // 保存到服务
        final success = await _profileService.saveUserProfile(profile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '个人信息已保存' : '保存失败，请重试'),
              backgroundColor: success ? null : Colors.red,
            ),
          );

          if (success) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        debugPrint('保存用户资料失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人信息'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 头像
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 昵称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  hintText: '请输入昵称',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入昵称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 个人简介
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '个人简介',
                  hintText: '请输入个人简介',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 邮箱
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  hintText: '请输入邮箱',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // 简单的邮箱格式验证
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return '请输入有效的邮箱地址';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 手机号
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // 简单的手机号格式验证（中国大陆）
                    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                      return '请输入有效的手机号';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
