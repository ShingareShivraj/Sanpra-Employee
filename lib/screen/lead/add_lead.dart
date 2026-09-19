import 'package:flutter/material.dart';

import '../../model/lead_model.dart';
import 'add_lead_viewmodel.dart';

const Color leadBlue = Color(0xFF1B5FE0);
const Color leadNavy = Color(0xFF123FA0);
const Color leadBackground = Color(0xFFF4F6FA);
const Color leadInk = Color(0xFF182230);
const Color leadMuted = Color(0xFF667085);
const Color leadBorder = Color(0xFFEAECF0);

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = LeadFormControllers();
  late final AddLeadViewModel _viewModel;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AddLeadViewModel()..addListener(_changed);
    _viewModel.initialise();
    for (final controller in _fields.all) {
      controller.addListener(_markDirty);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _markDirty() => _dirty = true;

  @override
  void dispose() {
    _viewModel.removeListener(_changed);
    _viewModel.dispose();
    _fields.dispose();
    super.dispose();
  }

  Future<bool> _canPop() async {
    if (!_dirty || _viewModel.saving) return !_viewModel.saving;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('The lead has not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _viewModel.saving) return;
    final result = await _viewModel.createLead(_fields.toLead());
    if (!mounted) return;
    if (result != null) {
      _dirty = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pop(context, true);
    } else if (_viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _canPop,
      child: Scaffold(
        backgroundColor: leadBackground,
        appBar: AppBar(
          title: const Text(
            'Add Lead',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: leadInk,
          elevation: 0,
        ),
        body: _viewModel.loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 86),
              children: [
                const _FormIntro(),
                const SizedBox(height: 10),
                LeadFormFields(
                  controllers: _fields,
                  masterData: _viewModel.masterData,
                  onChanged: () => _dirty = true,
                ),
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 12),
                  LeadInlineError(message: _viewModel.error!),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: leadBorder)),
            ),
            child: FilledButton.icon(
              onPressed: _viewModel.loading || _viewModel.saving ? null : _save,
              icon: _viewModel.saving
                  ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.person_add_alt_1_rounded, size: 19),
              label: Text(_viewModel.saving ? 'Creating...' : 'Create Lead'),
              style: FilledButton.styleFrom(
                backgroundColor: leadBlue,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: leadBorder),
    ),
    child: const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFEAF1FF), borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Padding(padding: EdgeInsets.all(8), child: Icon(Icons.person_add_alt_1_rounded, color: leadBlue, size: 19)),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Add contact details and basic lead information. Lead status can be updated later.',
            style: TextStyle(color: leadMuted, fontSize: 11, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class LeadFormControllers {
  final leadName = TextEditingController();
  final mobileNo = TextEditingController();
  final companyName = TextEditingController();
  final email = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final description = TextEditingController();
  String source = '';
  String status = '';
  String territory = '';

  List<TextEditingController> get all => [
    leadName,
    mobileNo,
    companyName,
    email,
    city,
    state,
    description,
  ];

  void fill(LeadModel lead) {
    leadName.text = lead.leadName;
    mobileNo.text = lead.mobileNo;
    companyName.text = lead.companyName;
    email.text = lead.emailId;
    city.text = lead.city;
    state.text = lead.state;
    description.text = lead.description;
    source = lead.source;
    status = lead.status;
    territory = lead.territory;
  }

  LeadModel toLead({String name = '', String company = ''}) => LeadModel(
    name: name,
    leadName: leadName.text.trim(),
    mobileNo: mobileNo.text.trim(),
    companyName: companyName.text.trim(),
    emailId: email.text.trim(),
    source: source,
    status: status,
    city: city.text.trim(),
    state: state.text.trim(),
    territory: territory,
    description: description.text.trim(),
    company: company,
  );

  void dispose() {
    for (final controller in all) {
      controller.dispose();
    }
  }
}

class LeadFormFields extends StatefulWidget {
  final LeadFormControllers controllers;
  final LeadMasterDataModel masterData;
  final VoidCallback onChanged;

  const LeadFormFields({
    super.key,
    required this.controllers,
    required this.masterData,
    required this.onChanged,
  });

  @override
  State<LeadFormFields> createState() => _LeadFormFieldsState();
}

class _LeadFormFieldsState extends State<LeadFormFields> {
  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: leadMuted, fontSize: 12),
    prefixIcon: Icon(icon, size: 18, color: leadMuted),
    prefixIconConstraints: const BoxConstraints(minWidth: 42),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: leadBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: leadBlue, width: 1.2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controllers;
    return Column(
      children: [
        _field(c.leadName, 'Lead name *', Icons.person_outline_rounded,
            validator: (v) => v!.trim().isEmpty ? 'Lead name is required.' : null),
        _field(c.companyName, 'Company name', Icons.business_outlined),
        _field(c.mobileNo, 'Mobile', Icons.smartphone_rounded, keyboard: TextInputType.phone),
        _field(
          c.email,
          'Email',
          Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
          validator: (value) {
            final text = value!.trim();
            if (text.isEmpty) return null;
            return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
                ? null
                : 'Enter a valid email address.';
          },
        ),
        _dropdown('Source', Icons.campaign_outlined, widget.masterData.sources,
            c.source, (v) => c.source = v),
        Row(children: [
          Expanded(child: _field(c.city, 'City', Icons.location_city_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _stateField(c.state)),
        ]),
        _dropdown('Territory', Icons.public_rounded,
            widget.masterData.territories, c.territory, (v) => c.territory = v),
        _field(c.description, 'Description', Icons.notes_rounded,
            maxLines: 3, keyboard: TextInputType.multiline),
      ],
    );
  }

  Widget _field(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType? keyboard,
        int maxLines = 1,
        String? Function(String?)? validator,
      }) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: _decoration(label, icon),
      style: const TextStyle(color: leadInk, fontSize: 12.5),
      validator: validator,
    ),
  );

  Widget _dropdown(String label, IconData icon, List<String> values,
      String current, ValueChanged<String> changed) {
    final items = <String>{
      ...values.where((v) => v.trim().isNotEmpty),
      if (current.trim().isNotEmpty) current,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await _selectValue(label, icon, items, current);
          if (result != null) {
            changed(result);
            widget.onChanged();
            setState(() {});
          }
        },
        child: InputDecorator(
          decoration: _decoration(label, icon).copyWith(
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: leadMuted, size: 21),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                current.isEmpty ? 'Select $label' : current,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: current.isEmpty ? leadMuted : leadInk,
                    fontSize: 12.5,
                    fontWeight: current.isEmpty ? FontWeight.w400 : FontWeight.w600),
              ),
            ),
            if (current.isNotEmpty)
              GestureDetector(
                onTap: () { changed(''); widget.onChanged(); setState(() {}); },
                child: const Icon(Icons.close_rounded, size: 17, color: leadMuted),
              ),
          ]),
        ),
      ),
    );
  }

  static const List<String> _states = [
    'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa',
    'Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala',
    'Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland',
    'Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura',
    'Uttar Pradesh','Uttarakhand','West Bengal','Andaman and Nicobar Islands',
    'Chandigarh','Delhi','Jammu and Kashmir','Ladakh','Lakshadweep','Puducherry',
  ];

  Widget _stateField(TextEditingController controller) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final result = await _selectValue('State', Icons.map_outlined, _states,
          controller.text.trim());
      if (result != null) { controller.text = result; widget.onChanged(); setState(() {}); }
    },
    child: IgnorePointer(child: _field(controller, 'State', Icons.map_outlined)),
  );

  Future<String?> _selectValue(String title, IconData icon, List<String> values,
      String selected) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(title: title, icon: icon, values: values,
          selected: selected),
    );
  }
}


class _SearchSheet extends StatefulWidget {
  final String title; final IconData icon; final List<String> values; final String selected;
  const _SearchSheet({required this.title, required this.icon, required this.values, required this.selected});
  @override State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final search = TextEditingController();
  String query = '';
  @override void dispose() { search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final results = widget.values.where((v) => v.toLowerCase().contains(query.toLowerCase().trim())).toList();
    return SafeArea(child: Container(
      height: MediaQuery.of(context).size.height * .78,
      decoration: const BoxDecoration(color: leadBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 42, height: 4, decoration: BoxDecoration(color: Color(0xFFD0D5DD), borderRadius: BorderRadius.circular(20))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 18, 12, 14), child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(12)), child: Icon(widget.icon, color: leadBlue)),
          const SizedBox(width: 12), Expanded(child: Text('Select ${widget.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: leadInk))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
          controller: search, autofocus: true, onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(hintText: 'Search ${widget.title.toLowerCase()}...', prefixIcon: const Icon(Icons.search_rounded, color: leadBlue), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: leadBorder)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: leadBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: leadBlue))),
        )),
        const SizedBox(height: 12),
        Expanded(child: results.isEmpty ? const Center(child: Text('No matching options found', style: TextStyle(color: leadMuted))) : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 7),
          itemBuilder: (_, i) { final value = results[i]; final chosen = value == widget.selected; return Material(color: Colors.white, borderRadius: BorderRadius.circular(13), child: InkWell(borderRadius: BorderRadius.circular(13), onTap: () => Navigator.pop(context, value), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: chosen ? leadBlue : leadBorder)), child: Row(children: [Expanded(child: Text(value, style: TextStyle(color: leadInk, fontSize: 12.5, fontWeight: chosen ? FontWeight.w700 : FontWeight.w500))), Icon(chosen ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: chosen ? leadBlue : const Color(0xFFD0D5DD))])))); },
        )),
      ]),
    ));
  }
}

class LeadInlineError extends StatelessWidget {
  final String message;
  const LeadInlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECEC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB42318), fontSize: 11))),
    ]),
  );
}
