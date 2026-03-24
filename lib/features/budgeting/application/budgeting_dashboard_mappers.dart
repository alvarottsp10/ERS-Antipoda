import '../domain/budgeting_models.dart';
import 'budgeting_dashboard_view_models.dart';

class BudgetingDashboardMappers {
  const BudgetingDashboardMappers._();

  static BudgetingNewOrderItem mapNewOrder(BudgetingOrderSummary order) {
    final baseRef = order.latestVersionRef.trim().isNotEmpty
        ? order.latestVersionRef.trim()
        : order.orderRef.trim();
    final customerName = order.customerName.trim();
    final displayLabel = customerName.isEmpty
        ? baseRef
        : '$baseRef - $customerName';

    return BudgetingNewOrderItem(
      orderId: order.orderId,
      orderRef: baseRef,
      versionLabel: order.versionLabel,
      displayLabel: displayLabel,
      customerName: order.customerName,
      createdAt: order.createdAt,
      createdAtLabel: _formatDateTime(order.createdAt),
      entryDate: order.sentToBudgetingAt ?? order.requestedAt ?? order.createdAt,
      entryDateLabel: _formatDate(
        order.sentToBudgetingAt ?? order.requestedAt ?? order.createdAt,
      ),
      expectedDeliveryDate: order.expectedDeliveryDate,
      expectedDeliveryDateLabel: _formatDate(order.expectedDeliveryDate),
    );
  }

  static BudgetingMyBudgetItem mapMyBudget(BudgetingOrderSummary order) {
    final baseRef = order.latestVersionRef.trim().isNotEmpty
        ? order.latestVersionRef.trim()
        : order.orderRef.trim();
    final primaryAssignment = order.activeAssignments.isEmpty
        ? null
        : order.activeAssignments.first;

    return BudgetingMyBudgetItem(
      orderId: order.orderId,
      latestVersionId: order.latestVersionId,
      orderRef: baseRef,
      versionLabel: order.versionLabel,
      displayLabel: _buildDisplayLabel(baseRef, order.customerName),
      customerName: order.customerName,
      budgetingPhaseId: order.budgetingPhaseId,
      budgetingPhaseName: order.budgetingPhaseName,
      primaryTypologyName: primaryAssignment?.budgetTypologyName ?? '',
      primaryProductTypeName: primaryAssignment?.productTypeName ?? '',
      isSpecial: order.activeAssignments.any((assignment) => assignment.isSpecial),
      totalWorkedHours: order.activeAssignments.fold(
        0,
        (sum, assignment) => sum + assignment.workedHours,
      ),
      activeProposalId: order.activeProposalId,
      activeProposalSellTotal: order.activeProposalSellTotal,
      activeProposalCostTotal: order.activeProposalCostTotal,
      activeProposalCostMaterialTotal: order.activeProposalCostMaterialTotal,
      activeProposalCostLaborTotal: order.activeProposalCostLaborTotal,
      activeProposalCostProjectTotal: order.activeProposalCostProjectTotal,
      activeProposalMarginPct: order.activeProposalMarginPct,
      activeProposalSentAt: order.activeProposalSentAt,
      activeProposalFeedbackAt: order.activeProposalFeedbackAt,
      activeProposalValidUntil: order.activeProposalValidUntil,
      activeProposalItems: order.activeProposalItems,
      assignments:
          order.activeAssignments.map(_mapAssignment).toList(growable: false),
    );
  }

  static BudgetingActiveBudgetItem mapActiveBudget(BudgetingOrderSummary order) {
    final baseRef = order.latestVersionRef.trim().isNotEmpty
        ? order.latestVersionRef.trim()
        : order.orderRef.trim();
    final primaryAssignment = order.activeAssignments.isEmpty
        ? null
        : order.activeAssignments.first;

    return BudgetingActiveBudgetItem(
      orderId: order.orderId,
      latestVersionId: order.latestVersionId,
      orderRef: baseRef,
      versionLabel: order.versionLabel,
      displayLabel: _buildDisplayLabel(baseRef, order.customerName),
      customerName: order.customerName,
      budgetingPhaseId: order.budgetingPhaseId,
      budgetingPhaseName: order.budgetingPhaseName,
      primaryTypologyName: primaryAssignment?.budgetTypologyName ?? '',
      primaryProductTypeName: primaryAssignment?.productTypeName ?? '',
      isSpecial: order.activeAssignments.any((assignment) => assignment.isSpecial),
      totalWorkedHours: order.activeAssignments.fold(
        0,
        (sum, assignment) => sum + assignment.workedHours,
      ),
      activeProposalId: order.activeProposalId,
      activeProposalSellTotal: order.activeProposalSellTotal,
      activeProposalCostTotal: order.activeProposalCostTotal,
      activeProposalCostMaterialTotal: order.activeProposalCostMaterialTotal,
      activeProposalCostLaborTotal: order.activeProposalCostLaborTotal,
      activeProposalCostProjectTotal: order.activeProposalCostProjectTotal,
      activeProposalMarginPct: order.activeProposalMarginPct,
      activeProposalSentAt: order.activeProposalSentAt,
      activeProposalFeedbackAt: order.activeProposalFeedbackAt,
      activeProposalValidUntil: order.activeProposalValidUntil,
      activeProposalItems: order.activeProposalItems,
      assignments:
          order.activeAssignments.map(_mapAssignment).toList(growable: false),
    );
  }

  static BudgetingAssignmentItem _mapAssignment(
    BudgetingAssignmentSummary assignment,
  ) {
    return BudgetingAssignmentItem(
      id: assignment.id,
      assigneeUserId: assignment.assigneeUserId,
      assigneeName: assignment.assigneeName,
      assignmentRole: assignment.assignmentRole,
      roleLabel: assignment.assignmentRole == 'lead' ? 'Lead' : 'Support',
      typologyName: assignment.budgetTypologyName,
      productTypeName: assignment.productTypeName,
      workedHours: assignment.workedHours,
      isSpecial: assignment.isSpecial,
    );
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  static String _buildDisplayLabel(String baseRef, String customerName) {
    final trimmedCustomer = customerName.trim();
    if (trimmedCustomer.isEmpty) {
      return baseRef;
    }
    return '$baseRef - $trimmedCustomer';
  }
}
