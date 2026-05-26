import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../const.dart';
import '../../../providers/appstate.dart';
import '../../widgets/section.dart';
import 'settings.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textStyle = Theme.of(context).textTheme.headlineSmall;

    return Section(
      title: 'Profile',
      onEscapeKey: () => state.setCurrentView(const SettingsView()),
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Avatar', style: textStyle),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(Const.avatarOptions.length, (i) {
              final option = Const.avatarOptions[i];
              final selected = state.avatarIndex == i;
              return GestureDetector(
                onTap: () => state.setAvatarIndex(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected ? Colors.amber : Colors.black12,
                          width: selected ? 4 : 2,
                        ),
                        color: selected ? Colors.amber.withValues(alpha: 0.1) : Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(option.icon, size: 72, color: option.color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
