import 'package:echurch_desktop/core/command.dart';
import 'package:echurch_desktop/core/result.dart';
import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/core/share/error_messages.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:echurch_desktop/ui/members/widgets/member_status_chip.dart';
import 'package:material_ui/material_ui.dart';

/// Detalhes do membro, buscados na API ao abrir. Quem só consulta recebe a versão reduzida
/// (contato, cargo, ministérios e aniversário); Secretaria/Administrador, o cadastro completo
/// e o histórico da desativação ([full]). Usado pela tela de Membros e pela busca rápida da barra
/// superior: cada uma passa o seu comando de carregar.
class const MemberDetailsDialog({super.key, required final Command1<MemberDetails, int> details, required final bool full, required final MemberRow member}) extends StatefulWidget {
  static Future<void> show(BuildContext context, {required Command1<MemberDetails, int> details, required bool full, required MemberRow member}) => showDialog<void>(
    context: context,
    builder: (_) => MemberDetailsDialog(details: details, full: full, member: member),
  );

  @override
  State<MemberDetailsDialog> createState() => _MemberDetailsDialogState();
}

class _MemberDetailsDialogState extends State<MemberDetailsDialog> {
  @override
  void initState() {
    super.initState();
    widget.details.execute(widget.member.id);
  }

  @override
  Widget build(BuildContext context) {
    final command = widget.details;
    return ListenableBuilder(
      listenable: command,
      builder: (context, _) => AlertDialog(
        icon: const Icon(Icons.person, color: AppColors.membersIcon),
        title: Text(widget.member.name),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 520, maxWidth: 600),
          child: switch (command.result) {
            Ok<MemberDetails>(:final value) => _Details(member: value, full: widget.full),
            Error<MemberDetails>(:final error) => Padding(
              padding: const .symmetric(vertical: 24),
              child: Column(
                mainAxisSize: .min,
                spacing: 12,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.textMuted),
                  Text(
                    ErrorMessages.of(error),
                    textAlign: .center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  FilledButton.tonal(onPressed: () => command.execute(widget.member.id), child: const Text('Tentar de novo')),
                ],
              ),
            ),
            null => const Padding(
              padding: .symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          },
        ),
        actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
      ),
    );
  }
}

class const _Details({required final MemberDetails member, required final bool full}) extends StatelessWidget {
  static String? _date(DateTime? value) => value == null ? null : MembersViewModel.formatDate(value);

  @override
  Widget build(BuildContext context) {
    final birthday = member.birthDate != null ? _date(member.birthDate) : MembersViewModel.birthdayLabel(member.birthDay, member.birthMonth);
    final sections = <(String, List<(String, String?)>)>[
      (
        'Igreja',
        [
          ('Igreja', member.churchName),
          ('Cargo', member.ecclesiasticalRoleName),
          ('Ministérios', member.ministryNames.isEmpty ? null : member.ministryNames.join(', ')),
          if (full) ...[('Batismo', _date(member.baptismDate)), ('Aceitou Jesus', _date(member.acceptedJesusDate))],
        ],
      ),
      (
        'Contato',
        [
          ('Telefone', member.phone),
          ('Outro telefone', member.secondaryPhone),
          ('E-mail', member.email),
          if (full) ('Endereço', member.address),
        ],
      ),
      (
        'Pessoal',
        [
          (member.birthDate != null ? 'Nascimento' : 'Aniversário', birthday),
          if (full) ...[
            ('Sexo', member.gender),
            ('Estado civil', member.maritalStatus),
            ('Cônjuge', member.spouseName),
            ('Pai', member.fatherName),
            ('Mãe', member.motherName),
            ('CPF', member.cpf),
            ('RG', member.rg),
          ],
        ],
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        spacing: 16,
        children: [
          MemberStatusChip(status: member.status),
          if (member.status == MemberStatus.inactive && member.deactivationReason != null) _Deactivation(member: member),
          // Todos os campos sempre, na mesma ordem (vazio = "—"): a ficha de um membro fica igual à do outro.
          for (final (title, fields) in sections) _Section(title: title, fields: fields),
          if (full && member.notes != null) _Section(title: 'Observações', fields: [('', member.notes)]),
          if (!full)
            const Text(
              'Documentos, endereço e demais dados do cadastro ficam com a Secretaria.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
        ],
      ),
    );
  }
}

/// Motivo e descrição da desativação, com quem e quando (só para quem gerencia: a versão reduzida não traz).
class const _Deactivation({required final MemberDetails member}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final when = [
      if (member.deactivatedAt case final at?) 'em ${MembersViewModel.formatDate(at)}',
      if (member.deactivatedByName case final name?) 'por $name',
    ].join(' ');
    return Container(
      width: double.infinity,
      padding: const .all(12),
      decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 4,
        children: [
          Text('Desativado: ${member.deactivationReason!.label}', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (member.deactivationDescription case final description?) Text(description),
          if (when.isNotEmpty) Text(when, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class const _Section({required final String title, required final List<(String, String?)> fields}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 6,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
        for (final (label, value) in fields)
          label.isEmpty
              ? SelectableText(value ?? '', style: const TextStyle(height: 1.4))
              : Row(
                  crossAxisAlignment: .start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: value == null ? const Text('—', style: TextStyle(color: AppColors.textMuted)) : SelectableText(value),
                    ),
                  ],
                ),
      ],
    );
  }
}
