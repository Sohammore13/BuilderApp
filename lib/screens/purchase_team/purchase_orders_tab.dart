import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/firestore_service.dart';

class PurchaseOrdersTab extends StatefulWidget {
  final String siteId;
  const PurchaseOrdersTab({super.key, required this.siteId});

  @override
  State<PurchaseOrdersTab> createState() => _PurchaseOrdersTabState();
}

class _PurchaseOrdersTabState extends State<PurchaseOrdersTab> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;
  bool _showForm = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _firestoreService.submitPurchaseOrder(
        siteId: widget.siteId,
        itemName: _itemController.text.trim(),
        quantity: int.parse(_qtyController.text.trim()),
        estimatedCost: double.parse(_costController.text.trim()),
        notes: _notesController.text.trim(),
        submittedBy: _uid,
      );

      _itemController.clear();
      _qtyController.clear();
      _costController.clear();
      _notesController.clear();
      setState(() => _showForm = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase order submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle form button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: InkWell(
            onTap: () => setState(() => _showForm = !_showForm),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showForm ? Icons.close : Icons.add_circle_outline,
                    size: 20,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showForm ? 'Cancel' : 'Submit New Order',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Collapsible form
        if (_showForm)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  BuilderTextField(
                    controller: _itemController,
                    label: 'Item Name',
                    hint: 'e.g. Steel Reinforcement Bars',
                    prefixIcon: Icons.inventory_2_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: BuilderTextField(
                          controller: _qtyController,
                          label: 'Quantity',
                          hint: 'e.g. 100',
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (int.tryParse(v.trim()) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BuilderTextField(
                          controller: _costController,
                          label: 'Est. Cost (₹)',
                          hint: 'e.g. 50000',
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (double.tryParse(v.trim()) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BuilderTextField(
                    controller: _notesController,
                    label: 'Notes (optional)',
                    hint: 'Any additional details',
                    prefixIcon: Icons.notes,
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Submit Order',
                    icon: Icons.send,
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),

        // My orders list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.streamMyPurchaseOrders(
              siteId: widget.siteId,
              uid: _uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.onSurfaceMuted),
                      const SizedBox(height: 12),
                      Text('No orders submitted yet',
                          style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? 'pending';
                  final itemName = data['itemName'] as String? ?? '';
                  final quantity = data['quantity'] ?? 0;
                  final cost = data['estimatedCost'] ?? 0;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  Color statusColor;
                  switch (status) {
                    case 'approved':
                      statusColor = AppColors.success;
                      break;
                    case 'rejected':
                      statusColor = AppColors.error;
                      break;
                    default:
                      statusColor = AppColors.warning;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  itemName,
                                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoChip(Icons.inventory_2_outlined, 'Qty: $quantity'),
                              const SizedBox(width: 10),
                              _infoChip(Icons.currency_rupee, '₹$cost'),
                              const Spacer(),
                              if (createdAt != null)
                                Text(
                                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  style: AppTextStyles.caption,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
