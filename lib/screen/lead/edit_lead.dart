import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/lead_model.dart';
import 'add_lead.dart';
import 'edit_lead_viewmodel.dart';

enum EditLeadOpenMode { details, edit, addEvent, events }

class EditLeadScreen extends StatefulWidget {
  final String leadName;
  final LeadModel? initialLead;
  final EditLeadOpenMode openMode;

  const EditLeadScreen({
    super.key,
    required this.leadName,
    this.initialLead,
    this.openMode = EditLeadOpenMode.details,
  });

  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen> {
  late final EditLeadViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _fields = LeadFormControllers();
  bool _editing = false;
  bool _dirty = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _editing = widget.openMode == EditLeadOpenMode.edit;
    _viewModel = EditLeadViewModel(
      leadName: widget.leadName,
      initialLead: widget.initialLead,
    )..addListener(_changed);
    _viewModel.initialise().then((_) {
      if (!mounted) return;
      _seedFields();
      if (widget.openMode == EditLeadOpenMode.addEvent) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showEventForm());
      } else if (widget.openMode == EditLeadOpenMode.events) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEvents());
      }
    });
  }

  void _changed() {
    if (!mounted) return;
    _seedFields();
    setState(() {});
  }

  void _seedFields() {
    final lead = _viewModel.lead;
    if (lead != null && !_seeded) {
      _fields.fill(lead);
      for (final controller in _fields.all) {
        controller.addListener(_markDirty);
      }
      _seeded = true;
    }
  }

  void _markDirty() {
    if (_editing) _dirty = true;
  }

  @override
  void dispose() {
    _viewModel.removeListener(_changed);
    _viewModel.dispose();
    _fields.dispose();
    super.dispose();
  }

  Future<bool> _canPop() async {
    if (!_editing || !_dirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your lead changes are not saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate() || _viewModel.saving) return;

    final message = await _viewModel.updateLead(
      _fields.toLead(
        name: widget.leadName.trim(),
        company: _viewModel.lead?.company ?? '',
      ),
    );

    if (!mounted) return;

    if (message != null) {
      _dirty = false;
      _editing = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      setState(() {});
    } else if (_viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.error!)),
      );
    }
  }

  Future<void> _launch(String value, String scheme) async {
    final uri = Uri(scheme: scheme, path: value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open this action.')));
    }
  }

  void _scrollToEvents() {
    final target = _eventsKey.currentContext;
    if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 450));
  }

  final _eventsKey = GlobalKey();

  Future<void> _showEventForm([LeadEventModel? event]) async {
    final value = await showModalBottomSheet<LeadEventModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EventFormSheet(
        event: event,
        leadName: widget.leadName,
        categories: _viewModel.masterData.eventCategories,
      ),
    );
    if (value == null) return;
    final message = await _viewModel.saveEvent(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? _viewModel.eventsError ?? 'Unable to save event.')),
    );
  }

  Future<void> _deleteEvent(LeadEventModel event) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Delete “${event.subject}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    final message = await _viewModel.deleteEvent(event.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? _viewModel.eventsError ?? 'Unable to delete event.')));
  }

  @override
  Widget build(BuildContext context) {
    final lead = _viewModel.lead;
    return WillPopScope(
      onWillPop: _canPop,
      child: Scaffold(
        backgroundColor: leadBackground,
        appBar: AppBar(
          title: Text(_editing ? 'Edit Lead' : 'Lead Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: leadInk,
          elevation: 0,
          actions: [
            if (lead != null && !_editing)
              IconButton(onPressed: () => setState(() => _editing = true), tooltip: 'Edit', icon: const Icon(Icons.edit_outlined)),
          ],
        ),
        body: _viewModel.loading && lead == null
            ? const Center(child: CircularProgressIndicator(color: leadBlue))
            : lead == null
            ? _ErrorBody(message: _viewModel.error ?? 'Lead not found.', retry: _viewModel.refresh)
            : RefreshIndicator(
          onRefresh: _viewModel.refresh,
          child: _editing ? _editBody(lead) : _detailBody(lead),
        ),
        bottomNavigationBar: _editing && lead != null
            ? SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: leadBorder))),
            child: Row(children: [
              Expanded(child: OutlinedButton(onPressed: _viewModel.saving ? null : () { _fields.fill(_viewModel.lead!); setState(() { _editing = false; _dirty = false; }); }, child: const Text('Cancel'))),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _viewModel.saving ? null : _saveLead,
                  style: FilledButton.styleFrom(backgroundColor: leadBlue, minimumSize: const Size.fromHeight(46), textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  child: Text(_viewModel.saving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ]),
          ),
        )
            : null,
      ),
    );
  }

  Widget _editBody(LeadModel lead) => Form(
    key: _formKey,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 82),
      children: [
        LeadFormFields(controllers: _fields, masterData: _viewModel.masterData, onChanged: () => _dirty = true),
        if (_viewModel.error != null) LeadInlineError(message: _viewModel.error!),
      ],
    ),
  );

  Widget _detailBody(LeadModel lead) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    children: [
      _LeadHeader(
        lead: lead,
        call: lead.primaryPhone.isEmpty ? null : () => _launch(lead.primaryPhone, 'tel'),
        email: lead.emailId.isEmpty ? null : () => _launch(lead.emailId, 'mailto'),
        addEvent: _showEventForm,
      ),
      const SizedBox(height: 10),
      _InfoCard(title: 'Contact', rows: [
        _InfoRow(Icons.smartphone_rounded, 'Mobile', lead.mobileNo),
        _InfoRow(Icons.phone_outlined, 'Phone', lead.phone),
        _InfoRow(Icons.email_outlined, 'Email', lead.emailId),
        _InfoRow(Icons.business_outlined, 'Company name', lead.companyName),
      ]),
      const SizedBox(height: 9),
      _InfoCard(title: 'Lead information', rows: [
        _InfoRow(Icons.flag_outlined, 'Status', lead.status),
        _InfoRow(Icons.campaign_outlined, 'Source', lead.source),
        _InfoRow(Icons.location_city_outlined, 'City / State', lead.location),
        _InfoRow(Icons.public_rounded, 'Territory', lead.territory),
        _InfoRow(Icons.notes_rounded, 'Description', lead.description),
      ]),
      const SizedBox(height: 12),
      Row(key: _eventsKey, children: [
        const Expanded(child: Text('Events', style: TextStyle(color: leadInk, fontSize: 14, fontWeight: FontWeight.w800))),
        TextButton.icon(onPressed: _viewModel.eventBusy ? null : _showEventForm, icon: const Icon(Icons.add_rounded, size: 17), label: const Text('Add Event', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
      if (_viewModel.eventsError != null) ...[
        LeadInlineError(message: _viewModel.eventsError!),
        const SizedBox(height: 8),
      ],
      if (_viewModel.events.isEmpty)
        const _EmptyEvents()
      else
        ..._viewModel.events.map((event) => _EventCard(event: event, edit: () => _showEventForm(event), delete: () => _deleteEvent(event))),
    ],
  );
}

class _LeadHeader extends StatelessWidget {
  final LeadModel lead; final VoidCallback? call; final VoidCallback? email; final VoidCallback addEvent;
  const _LeadHeader({required this.lead, this.call, this.email, required this.addEvent});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [leadNavy, leadBlue]), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x30123FA0), blurRadius: 14, offset: Offset(0, 6))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(radius: 23, backgroundColor: Colors.white24, child: Text(lead.leadName.isEmpty ? '?' : lead.leadName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(lead.leadName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), if (lead.companyName.isNotEmpty) Text(lead.companyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11))]))]),
      const SizedBox(height: 13),
      Row(children: [if (call != null) Expanded(child: _HeaderButton(Icons.call_outlined, 'Call', call!)), if (call != null && email != null) const SizedBox(width: 8), if (email != null) Expanded(child: _HeaderButton(Icons.email_outlined, 'Email', email!)), if (call != null || email != null) const SizedBox(width: 8), Expanded(child: _HeaderButton(Icons.event_available_outlined, 'Event', addEvent))]),
    ]),
  );
}

class _HeaderButton extends StatelessWidget { final IconData icon; final String label; final VoidCallback onTap; const _HeaderButton(this.icon, this.label, this.onTap); @override Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 15), label: Text(label), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.symmetric(vertical: 8), textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))); }

class _InfoRow { final IconData icon; final String label; final String value; const _InfoRow(this.icon, this.label, this.value); }

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.value.isNotEmpty).toList();

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: leadBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: leadInk,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          ...visible.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: Icon + Label
                  Expanded(
                    flex: 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          r.icon,
                          size: 17,
                          color: leadBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.label,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: leadMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // RIGHT COLUMN: Value (LEFT ALIGNED)
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        r.value,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: leadInk,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final LeadEventModel event; final VoidCallback edit; final VoidCallback delete; const _EventCard({required this.event, required this.edit, required this.delete});
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: leadBorder)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.event_outlined, color: leadBlue, size: 18)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.subject, style: const TextStyle(color: leadInk, fontSize: 12.5, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(_formatEvent(event), style: const TextStyle(fontSize: 10.5, color: leadMuted)), if (event.description.isNotEmpty) ...[const SizedBox(height: 4), Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: leadInk, fontSize: 11))]])), PopupMenuButton<String>(iconSize: 20, onSelected: (v) => v == 'edit' ? edit() : delete(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit Event')), PopupMenuItem(value: 'delete', child: Text('Delete Event'))]) ]));
}

String _formatEvent(LeadEventModel event) {
  final start = event.startsOn;
  if (start == null) return 'No date';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(start.day)}/${two(start.month)}/${start.year}';
}

class _EmptyEvents extends StatelessWidget { const _EmptyEvents(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: leadBorder)), child: const Column(children: [Icon(Icons.event_busy_outlined, color: Color(0xFF98A2B3), size: 32), SizedBox(height: 7), Text('No events for this lead', style: TextStyle(color: leadInk, fontSize: 12.5, fontWeight: FontWeight.w700)), SizedBox(height: 3), Text('Add a follow-up, call or meeting.', style: TextStyle(fontSize: 10.5, color: leadMuted))])); }
class _ErrorBody extends StatelessWidget { final String message; final VoidCallback retry; const _ErrorBody({required this.message, required this.retry}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 43, color: Color(0xFF98A2B3)), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: leadMuted, fontSize: 12)), const SizedBox(height: 14), FilledButton(onPressed: retry, style: FilledButton.styleFrom(backgroundColor: leadBlue), child: const Text('Try again'))]))); }

class _EventFormSheet extends StatefulWidget {
  final LeadEventModel? event;
  final String leadName;
  final List<String> categories;

  const _EventFormSheet({
    this.event,
    required this.leadName,
    required this.categories,
  });

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}
class _EventFormSheetState extends State<_EventFormSheet> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _subject;
  late String _selectedCategory;

  List<String> get _availableCategories {
    final categories = widget.categories
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    // Always keep Event available and selected by default.
    if (!categories.contains('Event')) {
      categories.insert(0, 'Event');
    }

    return categories;
  }
  DateTime? _date;

  @override
  void initState() {
    super.initState();

    final e = widget.event;

    _subject = TextEditingController(
      text: e?.subject ?? '',
    );

    _selectedCategory = e?.category.trim().isNotEmpty == true
        ? e!.category.trim()
        : 'Event';

    final existingDate = e?.startsOn;

    _date = existingDate == null
        ? DateTime.now()
        : DateTime(
      existingDate.year,
      existingDate.month,
      existingDate.day,
    );
  }

  @override
  void dispose() {
    _subject.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() {
        _date = DateTime(selected.year, selected.month, selected.day);
      });
    }
  }

  Future<void> _pickCategory() async {
    final categories = widget.categories
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No event categories received from ERPNext.',
          ),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        selected: _selectedCategory,      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an event date.')),
      );
      return;
    }

    final date = DateTime(_date!.year, _date!.month, _date!.day);

    Navigator.pop(
      context,
      LeadEventModel(
        name: widget.event?.name ?? '',
        leadId: widget.leadName,
        subject: _subject.text.trim(),
        startsOn: date,
        category: _selectedCategory.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      10,
      16,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _key,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.event == null ? 'Add Event' : 'Edit Event',
                    style: const TextStyle(
                      color: leadInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _availableCategories.contains(_selectedCategory)
                  ? _selectedCategory
                  : 'Event',
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: leadBlue,
              ),
              decoration: InputDecoration(
                labelText: 'Category *',
                hintText: 'Select event category',
                prefixIcon: const Icon(
                  Icons.category_outlined,
                  color: leadBlue,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: leadBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: leadBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: leadBlue,
                    width: 1.5,
                  ),
                ),
              ),
              items: _availableCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: leadInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a category';
                }

                return null;
              },
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Event date *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _date == null ? 'Select date' : _formatDate(_date!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: leadInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _subject,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Summary *',
                hintText: 'Enter event summary',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(
                    Icons.subject_rounded,
                    color: leadBlue,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: leadBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: leadBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: leadBlue,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Summary is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: leadBlue,
                minimumSize: const Size.fromHeight(47),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.event == null ? 'Add Event' : 'Save Event',
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final List<String> categories;
  final String selected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selected,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.categories
        .where((item) => item.toLowerCase().contains(query))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Category',
            style: TextStyle(
              color: leadInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search category',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: filtered.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No categories available.'),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final category = filtered[index];
                return ListTile(
                  title: Text(category),
                  trailing: category == widget.selected
                      ? const Icon(Icons.check, color: leadBlue)
                      : null,
                  onTap: () => Navigator.pop(context, category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
