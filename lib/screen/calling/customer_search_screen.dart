import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/customer_call_model.dart';
import 'customer_call_viewmodel.dart';

const _blue = Color(0xFF1B5FE0);
const _navy = Color(0xFF123FA0);
const _background = Color(0xFFF4F6FA);
const _ink = Color(0xFF182230);
const _muted = Color(0xFF667085);
const _border = Color(0xFFEAECF0);

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({
    super.key,
    required this.viewModel,
    this.selectionMode = false,
  });

  final CustomerCallViewModel viewModel;
  final bool selectionMode;

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  CustomerCallViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewModel.customers.isEmpty) {
        _viewModel.loadCustomers();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 260) {
      _viewModel.loadMoreCustomers();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _ink,
          title: Text(
            widget.selectionMode ? 'Select Customer' : 'Customers',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh customer numbers',
              onPressed: _viewModel.lookupRefreshing
                  ? null
                  : _refreshCustomersAndLookup,
              icon: _viewModel.lookupRefreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _blue,
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _SearchField(
            controller: _searchController,
            onChanged: _viewModel.searchCustomers,
            onClear: _clearSearch,
          ),
        ),
        if (_viewModel.operationError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _InlineMessage(
              message: _viewModel.operationError!,
              isError: true,
              onClose: _viewModel.clearOperationFeedback,
            ),
          ),
        Expanded(child: _results()),
      ],
    );
  }

  Widget _results() {
    if (_viewModel.customerSearching && _viewModel.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    if (_viewModel.customers.isEmpty) {
      return _EmptyState(
        searching: _searchController.text.trim().isNotEmpty,
        onRetry: () => _viewModel.loadCustomers(),
      );
    }

    return RefreshIndicator(
      color: _blue,
      onRefresh: _refreshCustomersAndLookup,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: _viewModel.customers.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Company customers',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${_viewModel.customers.length} loaded',
                    style: const TextStyle(color: _muted, fontSize: 10.5),
                  ),
                ],
              ),
            );
          }

          if (index == _viewModel.customers.length + 1) {
            return _LoadMore(
              loading: _viewModel.customerLoadingMore,
              hasMore: _viewModel.customerHasMore,
              onTap: _viewModel.loadMoreCustomers,
            );
          }

          final customer = _viewModel.customers[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _CustomerCard(
              customer: customer,
              selectionMode: widget.selectionMode,
              onTap: () => _openCustomer(customer),
              onPhone: customer.phoneNumbers.isEmpty
                  ? null
                  : () => _dial(customer.phoneNumbers.first),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshCustomersAndLookup() async {
    await Future.wait([
      _viewModel.refreshPhoneLookup(),
      _viewModel.loadCustomers(),
    ]);
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.clearCustomerSearch();
    _viewModel.loadCustomers();
  }

  Future<void> _openCustomer(CustomerCallCustomerModel customer) async {
    if (widget.selectionMode) {
      Navigator.of(context).pop(customer);
      return;
    }

    _viewModel.clearCustomerDetails();
    _viewModel.loadCustomerDetails(customer.name);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => _CustomerDetailsSheet(
          fallback: customer,
          details: _viewModel.customerDetails,
          loading: _viewModel.customerDetailsLoading,
          error: _viewModel.operationError,
          onRetry: () => _viewModel.loadCustomerDetails(customer.name),
          onDial: _dial,
        ),
      ),
    );
  }

  Future<void> _dial(String number) async {
    final clean = number.trim();
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the Phone app.')),
      );
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: _ink, fontSize: 12.5),
        decoration: InputDecoration(
          hintText: 'Search customer or company',
          hintStyle: const TextStyle(color: _muted, fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          filled: true,
          fillColor: _background,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.selectionMode,
    required this.onTap,
    this.onPhone,
  });

  final CustomerCallCustomerModel customer;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onPhone;

  @override
  Widget build(BuildContext context) {
    final title = customer.customerName.isEmpty
        ? customer.name
        : customer.customerName;
    final subtitle = [customer.customerType, customer.territory]
        .where((value) => value.isNotEmpty)
        .join(' • ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              _CustomerAvatar(name: title, image: customer.image),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.isEmpty ? customer.name : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: _blue),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            customer.phoneNumbers.isEmpty
                                ? 'No registered number'
                                : customer.phoneNumbers.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: customer.phoneNumbers.isEmpty
                                  ? _muted
                                  : _navy,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (customer.phoneCount > 1)
                          _SmallBadge(label: '+${customer.phoneCount - 1}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!selectionMode && onPhone != null)
                IconButton.filledTonal(
                  tooltip: 'Call customer',
                  onPressed: onPhone,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF1FF),
                    foregroundColor: _blue,
                  ),
                  icon: const Icon(Icons.call_rounded, size: 19),
                )
              else
                Icon(
                  selectionMode
                      ? Icons.check_circle_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: selectionMode ? _blue : const Color(0xFF98A2B3),
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerDetailsSheet extends StatelessWidget {
  const _CustomerDetailsSheet({
    required this.fallback,
    required this.details,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onDial,
  });

  final CustomerCallCustomerModel fallback;
  final CustomerDetailsModel? details;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<String> onDial;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 10, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Customer Details',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (loading && details == null) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (details == null) {
      return _SheetError(
        message: error ?? 'Unable to load customer details.',
        onRetry: onRetry,
      );
    }

    final customer = details!.customer;
    final name = customer.customerName.isEmpty
        ? fallback.customerName
        : customer.customerName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_navy, _blue]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              _CustomerAvatar(name: name, light: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [customer.customerType, customer.territory]
                          .where((value) => value.isNotEmpty)
                          .join(' • '),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _SectionTitle(title: 'Registered phone numbers'),
        const SizedBox(height: 7),
        if (details!.phones.isEmpty)
          const _NoPhones()
        else
          ...details!.phones.map(
            (phone) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _PhoneRow(phone: phone, onDial: onDial),
            ),
          ),
      ],
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone, required this.onDial});
  final CustomerPhoneMatchModel phone;
  final ValueChanged<String> onDial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.phone_outlined, color: _blue, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phone.phoneNumber,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone.contactName?.isNotEmpty == true
                      ? '${phone.contactName} • ${phone.label}'
                      : phone.label,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call',
            onPressed: () => onDial(phone.phoneNumber),
            color: _blue,
            icon: const Icon(Icons.call_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({
    required this.name,
    this.image,
    this.light = false,
  });

  final String name;
  final String? image;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 23,
      backgroundColor: light ? Colors.white24 : const Color(0xFFEAF1FF),
      foregroundImage: image?.isNotEmpty == true ? NetworkImage(image!) : null,
      child: Text(
        initial,
        style: TextStyle(
          color: light ? Colors.white : _navy,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({
    required this.loading,
    required this.hasMore,
    required this.onTap,
  });

  final bool loading;
  final bool hasMore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
          ),
        ),
      );
    }
    if (!hasMore) return const SizedBox(height: 8);
    return Center(
      child: TextButton(onPressed: onTap, child: const Text('Load more')),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.isError,
    required this.onClose,
  });

  final String message;
  final bool isError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB42318) : const Color(0xFF067647);
    final background =
        isError ? const Color(0xFFFFECEC) : const Color(0xFFECFDF3);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 10.5)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching, required this.onRetry});
  final bool searching;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.business_outlined, size: 54, color: Color(0xFF98A2B3)),
        const SizedBox(height: 14),
        Text(
          searching ? 'No customers found' : 'No customers available',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          searching
              ? 'Try another customer name.'
              : 'Only customers linked to your company appear here.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _NoPhones extends StatelessWidget {
  const _NoPhones();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'No phone number is registered for this customer or its contacts.',
        style: TextStyle(color: _muted, fontSize: 10.5),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _navy,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD0D5DD),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
