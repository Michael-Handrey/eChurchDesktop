import 'package:echurch_desktop/domain/models/member/member.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:echurch_desktop/ui/members/member_quick_search_viewmodel.dart';
import 'package:echurch_desktop/ui/members/members_viewmodel.dart';
import 'package:echurch_desktop/ui/members/widgets/member_details_dialog.dart';
import 'package:echurch_desktop/ui/members/widgets/member_status_chip.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Campo de busca da barra superior: os resultados aparecem numa lista logo abaixo, enquanto se
/// digita; clicar (ou Enter, no primeiro) abre a ficha do membro sem sair da tela atual.
/// Ctrl+K vai direto para o campo; Esc fecha a lista.
class MemberQuickSearchWidget extends StatefulWidget {
  const MemberQuickSearchWidget({super.key});

  static const maxWidth = 460.0;

  @override
  State<MemberQuickSearchWidget> createState() => _MemberQuickSearchWidgetState();
}

class _MemberQuickSearchWidgetState extends State<MemberQuickSearchWidget> {
  final _controller = TextEditingController();
  final _focus = FocusNode(debugLabel: 'busca-rapida');
  final _overlay = OverlayPortalController();
  final _link = LayerLink();

  /// O campo e a lista contam como uma área só: clicar na lista não tira o foco do campo.
  final _tapGroup = Object();
  var _width = MemberQuickSearchWidget.maxWidth;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final keyboard = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.keyK && keyboard.isControlPressed) {
      _focus.requestFocus();
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && _focus.hasFocus) {
      _focus.unfocus();
      return true;
    }
    return false;
  }

  void _onFocus() => _focus.hasFocus ? _overlay.show() : _overlay.hide();

  void _open(MemberQuickSearchViewModel viewModel, MemberRow member) {
    _focus.unfocus();
    _controller.clear();
    viewModel.clear();
    MemberDetailsDialog.show(context, details: viewModel.details, full: viewModel.canManage, member: member);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MemberQuickSearchViewModel>();

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: MemberQuickSearchWidget.maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            return CompositedTransformTarget(
              link: _link,
              child: OverlayPortal(
                controller: _overlay,
                // O painel fica no Overlay do app (fora dos providers da tela): recebe o ViewModel direto.
                overlayChildBuilder: (_) => CompositedTransformFollower(
                  link: _link,
                  targetAnchor: Alignment.bottomLeft,
                  offset: const Offset(0, 6),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TapRegion(
                      groupId: _tapGroup,
                      child: SizedBox(
                        width: _width,
                        child: _ResultsPanel(viewModel: viewModel, onOpen: (member) => _open(viewModel, member)),
                      ),
                    ),
                  ),
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.searchBarBackground,
                    border: Border.all(color: AppColors.searchBarBorder, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    key: const ValueKey('busca-rapida'),
                    controller: _controller,
                    focusNode: _focus,
                    groupId: _tapGroup,
                    onChanged: viewModel.setQuery,
                    onSubmitted: (_) {
                      if (viewModel.results.firstOrNull case final first?) _open(viewModel, first);
                    },
                    style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 13.5),
                    cursorColor: AppColors.textOnPrimary,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: viewModel.hint,
                      hintStyle: const TextStyle(color: AppColors.textOnPrimaryMuted, fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textOnPrimaryMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lista suspensa: buscando, erro, nenhum resultado ou até 8 membros (e quantos mais existem).
class const _ResultsPanel({required final MemberQuickSearchViewModel viewModel, required final ValueChanged<MemberRow> onOpen}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.isActive) return const SizedBox.shrink();

        Widget message(String text, {Widget? leading}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 10,
            children: [
              ?leading,
              Expanded(
                child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
        );

        final results = viewModel.results;
        return Material(
          color: AppColors.surface,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (results.isEmpty)
                if (viewModel.loading)
                  message(
                    'Buscando…',
                    leading: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  )
                else if (viewModel.hasError)
                  message('Não foi possível buscar agora. Tente de novo em instantes.', leading: const Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.textMuted))
                else
                  message('Nenhum membro encontrado.')
              else ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(
                    'MEMBROS',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                  ),
                ),
                for (final member in results) _ResultTile(member: member, onTap: () => onOpen(member)),
                if (viewModel.total > results.length)
                  Container(
                    color: AppColors.surfaceSubtle,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Mostrando ${results.length} de ${viewModel.total}. Digite mais para refinar.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class const _ResultTile({required final MemberRow member, required final VoidCallback onTap}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inactive = member.status == MemberStatus.inactive;
    final details = [?member.churchName, ?member.phone, ?MembersViewModel.birthdayLabel(member.birthDay, member.birthMonth)].join('  ·  ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.membersBg,
              child: Icon(Icons.person, size: 18, color: AppColors.membersIcon),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, color: inactive ? AppColors.textSecondary : AppColors.textPrimary),
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            MemberStatusChip(status: member.status, reason: member.deactivationReason),
          ],
        ),
      ),
    );
  }
}
