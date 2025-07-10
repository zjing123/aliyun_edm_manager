import 'package:flutter/material.dart';

/// 通用表单验证工具类
class FormValidator {
  /// 检查必填字段是否都已填写
  static bool areRequiredFieldsFilled(List<String?> fields) {
    return fields.every((field) => field != null && field.isNotEmpty);
  }

  /// 检查必填字段是否都已填写（支持多种类型）
  static bool areRequiredFieldsFilledGeneric(List<dynamic> fields) {
    return fields.every((field) {
      if (field == null) return false;
      if (field is String) return field.isNotEmpty;
      if (field is int) return field > 0;
      if (field is double) return field > 0;
      if (field is bool) return field;
      return true;
    });
  }

  /// 检查表单是否有效（包含Form验证）
  static bool isFormValid(GlobalKey<FormState> formKey, List<dynamic> requiredFields) {
    return areRequiredFieldsFilledGeneric(requiredFields) && 
           (formKey.currentState?.validate() ?? false);
  }

  /// 检查表单是否有效（不包含Form验证，仅检查字段）
  static bool isFormValidWithoutValidation(List<dynamic> requiredFields) {
    return areRequiredFieldsFilledGeneric(requiredFields);
  }

  /// 创建条件按钮的onPressed回调
  static VoidCallback? createConditionalCallback({
    required bool condition,
    required VoidCallback callback,
  }) {
    return condition ? callback : null;
  }

  /// 创建带加载状态的按钮回调
  static VoidCallback? createLoadingCallback({
    required bool isLoading,
    required VoidCallback callback,
  }) {
    return createConditionalCallback(
      condition: !isLoading,
      callback: callback,
    );
  }

  /// 创建带表单验证的按钮回调
  static VoidCallback? createFormValidCallback({
    required GlobalKey<FormState> formKey,
    required List<dynamic> requiredFields,
    required VoidCallback callback,
  }) {
    return createConditionalCallback(
      condition: isFormValid(formKey, requiredFields),
      callback: callback,
    );
  }

  /// 创建带表单验证和加载状态的按钮回调
  static VoidCallback? createFormValidLoadingCallback({
    required GlobalKey<FormState> formKey,
    required List<dynamic> requiredFields,
    required bool isLoading,
    required VoidCallback callback,
  }) {
    return createConditionalCallback(
      condition: isFormValid(formKey, requiredFields) && !isLoading,
      callback: callback,
    );
  }
}

/// 表单验证混入类，提供常用的验证方法
mixin FormValidationMixin {
  /// 检查必填字段是否都已填写
  bool areRequiredFieldsFilled(List<String?> fields) {
    return FormValidator.areRequiredFieldsFilled(fields);
  }

  /// 检查必填字段是否都已填写（支持多种类型）
  bool areRequiredFieldsFilledGeneric(List<dynamic> fields) {
    return FormValidator.areRequiredFieldsFilledGeneric(fields);
  }

  /// 检查表单是否有效（包含Form验证）
  bool isFormValid(GlobalKey<FormState> formKey, List<dynamic> requiredFields) {
    return FormValidator.isFormValid(formKey, requiredFields);
  }

  /// 检查表单是否有效（不包含Form验证，仅检查字段）
  bool isFormValidWithoutValidation(List<dynamic> requiredFields) {
    return FormValidator.isFormValidWithoutValidation(requiredFields);
  }

  /// 创建条件按钮的onPressed回调
  VoidCallback? createConditionalCallback({
    required bool condition,
    required VoidCallback callback,
  }) {
    return FormValidator.createConditionalCallback(
      condition: condition,
      callback: callback,
    );
  }

  /// 创建带加载状态的按钮回调
  VoidCallback? createLoadingCallback({
    required bool isLoading,
    required VoidCallback callback,
  }) {
    return FormValidator.createLoadingCallback(
      isLoading: isLoading,
      callback: callback,
    );
  }

  /// 创建带表单验证的按钮回调
  VoidCallback? createFormValidCallback({
    required GlobalKey<FormState> formKey,
    required List<dynamic> requiredFields,
    required VoidCallback callback,
  }) {
    return FormValidator.createFormValidCallback(
      formKey: formKey,
      requiredFields: requiredFields,
      callback: callback,
    );
  }

  /// 创建带表单验证和加载状态的按钮回调
  VoidCallback? createFormValidLoadingCallback({
    required GlobalKey<FormState> formKey,
    required List<dynamic> requiredFields,
    required bool isLoading,
    required VoidCallback callback,
  }) {
    return FormValidator.createFormValidLoadingCallback(
      formKey: formKey,
      requiredFields: requiredFields,
      isLoading: isLoading,
      callback: callback,
    );
  }
} 