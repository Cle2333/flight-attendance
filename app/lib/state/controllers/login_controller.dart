import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_exception.dart';
import '../app_state.dart';

/// 登录/注册页的本地状态 —— 表单 controller、loading、错误提示、
/// 登录 vs 注册模式切换。原本散在 LoginScreen 的 _LoginScreenState 里,
/// 抽出来让 LoginScreen 变无状态 widget。
class LoginController extends GetxController {
  final AppState _state = Get.find<AppState>();

  // ── 模式 ──
  final RxBool isLogin = true.obs;

  // ── 加载 / 提示 ──
  final RxBool loading = false.obs;
  final RxnString message = RxnString();
  final Rx<MessageType> messageType = MessageType.error.obs;

  // ── 表单 ──
  late final TextEditingController accountCtrl;
  late final TextEditingController passwordCtrl;
  late final TextEditingController confirmCtrl;
  late final TextEditingController nicknameCtrl;

  @override
  void onInit() {
    super.onInit();
    accountCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    confirmCtrl = TextEditingController();
    nicknameCtrl = TextEditingController();
  }

  @override
  void onClose() {
    accountCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    nicknameCtrl.dispose();
    super.onClose();
  }

  // ── 模式切换 ──
  void toggleMode() {
    isLogin.value = !isLogin.value;
    message.value = null;
  }

  void setMessage(String? msg, [MessageType t = MessageType.error]) {
    message.value = msg;
    messageType.value = t;
  }

  // ── 提交 ──
  Future<void> submit() async {
    final account = accountCtrl.text.trim();
    final password = passwordCtrl.text;
    if (account.isEmpty || password.isEmpty) {
      setMessage('请填写完整信息');
      return;
    }
    loading.value = true;
    try {
      if (isLogin.value) {
        await _state.login(account, password);
        setMessage('登录成功', MessageType.success);
      } else {
        final nickname = nicknameCtrl.text.trim();
        if (nickname.isEmpty) {
          setMessage('请输入昵称');
          return;
        }
        if (password != confirmCtrl.text) {
          setMessage('两次输入的密码不一致');
          return;
        }
        if (password.length < 6) {
          setMessage('密码长度不能少于6位');
          return;
        }
        await _state.register(account, password, nickname);
        setMessage('注册成功', MessageType.success);
      }
    } on ApiException catch (e) {
      setMessage(e.message);
    } catch (e) {
      setMessage('操作失败: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> enterLocal() async {
    await _state.enterLocalMode();
  }
}

enum MessageType { error, success }