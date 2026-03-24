class AppAccessState {
  const AppAccessState({
    required this.userId,
    required this.fullName,
    required this.initialsValue,
    required this.roleIds,
    required this.roleCodes,
  });

  final String? userId;
  final String? fullName;
  final String? initialsValue;
  final Set<int> roleIds;
  final Set<String> roleCodes;

  static const _adminRoleIds = {1};
  static const _crmManagerRoleIds = {9};
  static const _commercialRoleIds = {2};
  static const _budgetManagerRoleIds = {6};
  static const _budgeterRoleIds = {3};

  static const _adminCodes = {'ADMIN'};
  static const _crmManagerCodes = {
    'COM_MANAGER',
    'COMERCIAL_MANAGER',
    'CRM_MANAGER',
    'GESTOR_COMERCIAL',
  };
  static const _commercialCodes = {'COMERCIAL'};
  static const _budgetManagerCodes = {'ORC_MANAGER'};
  static const _budgeterCodes = {'ORCAMENTISTA'};

  bool get isAuthenticated => userId != null && userId!.trim().isNotEmpty;

  bool get isAdmin =>
      roleIds.any(_adminRoleIds.contains) || roleCodes.any(_adminCodes.contains);

  bool get isCrmManager =>
      roleIds.any(_crmManagerRoleIds.contains) ||
      roleCodes.any(_crmManagerCodes.contains);

  bool get isCommercial =>
      roleIds.any(_commercialRoleIds.contains) ||
      roleCodes.any(_commercialCodes.contains);

  bool get isBudgetManager =>
      roleIds.any(_budgetManagerRoleIds.contains) ||
      roleCodes.any(_budgetManagerCodes.contains);

  bool get isBudgeter =>
      roleIds.any(_budgeterRoleIds.contains) ||
      roleCodes.any(_budgeterCodes.contains);

  bool get canAccessCrmManagement => isAdmin || isCrmManager;
  bool get canAccessBudgetManagement => isAdmin || isBudgetManager;

  bool get canAssignCustomerCommercial => isAdmin || isCrmManager;

  bool get shouldAutoAssignCustomerToCurrentUser =>
      isCommercial && !canAssignCustomerCommercial;

  String? get roleLabel {
    if (isAdmin) {
      return 'Admin';
    }
    if (isCrmManager) {
      return 'Responsavel Comercial';
    }
    if (isBudgetManager) {
      return 'Responsavel Orcamentacao';
    }
    if (isBudgeter) {
      return 'Orcamentista';
    }
    if (isCommercial) {
      return 'Comercial';
    }
    return null;
  }

  String? get initials {
    final explicitInitials = initialsValue?.trim() ?? '';
    if (explicitInitials.isNotEmpty) {
      return explicitInitials.toUpperCase();
    }

    final value = fullName?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return null;
    }

    if (parts.length == 1) {
      final first = parts.first;
      if (first.isEmpty) {
        return null;
      }
      return first.substring(0, 1).toUpperCase();
    }

    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
  }
}
