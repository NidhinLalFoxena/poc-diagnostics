import 'package:diagnostics_test/widgets/app_sizes.dart';
import 'package:diagnostics_test/widgets/common_padding_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Constants for the screen
class LiveDataConstants {
  static const backgroundColor = Color(0xFF030303);
  static const iconColor = Color(0xFF7D7D7D);
  static const borderColor = Color(0xFF3A3A3A);
  static const titleColor = Color(0xFF828282);
  static const subtitleColor = Color(0xFFFFFFFF);
  static const conditionBackground = Color(0xFF161616);

  // Condition colors
  static const errorColor = Color(0xFFFF5252);
  static const moderateColor = Color(0xFFFFB617);
  static const goodColor = Color(0xFF8FFF93);

  // Text styles
  static const appBarTextStyle = TextStyle(
    color: Colors.white,
    fontFamily: 'Disket_Mono',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const titleTextStyle = TextStyle(
    color: titleColor,
    fontFamily: 'Disket_Mono',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
  );

  static const subtitleTextStyle = TextStyle(
    color: subtitleColor,
    fontFamily: 'Disket_Mono',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );

  static TextStyle conditionTextStyle(Color color) => TextStyle(
        color: color,
        fontFamily: 'Disket_Mono',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );
}

// Data model for live data items
class LiveDataItem {
  final String title;
  final String subTitle;
  final String iconPath;
  final String condition;
  final VoidCallback onTap;

  LiveDataItem({
    required this.title,
    required this.subTitle,
    required this.iconPath,
    required this.condition,
    required this.onTap,
  });
}

final List<LiveDataItem> liveDataItems = [
  LiveDataItem(
    title: 'BATTERY SOC',
    subTitle: '35%',
    iconPath: 'assets/battery.svg',
    condition: '',
    onTap: () {},
  ),
  LiveDataItem(
    title: 'ODOMETER',
    subTitle: '1200 KMS',
    iconPath: 'assets/swap_horiz.svg',
    condition: '',
    onTap: () {},
  ),
  LiveDataItem(
    title: 'MOTOR TEMP',
    subTitle: '65°C',
    iconPath: 'assets/heat_pump.svg',
    condition: 'CRITICAL',
    onTap: () {},
  ),
  LiveDataItem(
    title: 'MCU TEMP',
    subTitle: '45°C',
    iconPath: 'assets/mcu.svg',
    condition: 'GOOD',
    onTap: () {},
  ),
  LiveDataItem(
    title: 'PACK TEMP',
    subTitle: '45°C',
    iconPath: 'assets/packtemp.svg',
    condition: 'GOOD',
    onTap: () {},
  ),
  LiveDataItem(
    title: 'CELL TEMP',
    subTitle: '45°C',
    iconPath: 'assets/packtemp.svg',
    condition: 'MODERATE',
    onTap: () {},
  ),
  LiveDataItem(
    title: 'THROTTLE VALUE',
    subTitle: '5%',
    iconPath: 'assets/speed.svg',
    condition: '',
    onTap: () {},
  ),
  LiveDataItem(
    title: 'WHEEL SPEED',
    subTitle: '1200 RPM',
    iconPath: 'assets/toys_fan.svg',
    condition: 'ERROR',
    onTap: () {},
  ),
];

class LiveDataScreen extends StatelessWidget {
  const LiveDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: LiveDataConstants.backgroundColor,
        appBar: _buildAppBar(context),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: LiveDataConstants.backgroundColor,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: LiveDataConstants.iconColor,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Text(
        'LIVE DATA',
        style: LiveDataConstants.appBarTextStyle,
      ),
      actions: [
        Padding(
          padding: CommonPaddingWrapper.getPadding(right: TSizes.md),
          child: SvgPicture.asset('assets/autorenew.svg'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView.separated(
      itemCount: liveDataItems.length,
      itemBuilder: (context, index) {
        return LiveDataTile(item: liveDataItems[index]);
      },
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFF1F1F1F),
      ),
    );
  }

  void _refreshData() {}
}

class LiveDataTile extends StatelessWidget {
  final LiveDataItem item;

  const LiveDataTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: item.onTap,
      leading: _buildIcon(),
      title: _buildTitle(),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(),
      contentPadding: CommonPaddingWrapper.getPadding(
        left: TSizes.md,
        right: TSizes.md,
        top: TSizes.xs,
        bottom: TSizes.xs,
      ),
    );
  }

  Widget _buildIcon() {
    return SvgPicture.asset(
      item.iconPath,
      width: 24,
      height: 24,
      colorFilter: const ColorFilter.mode(
        Color(0xFF727272),
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      item.title,
      style: LiveDataConstants.titleTextStyle,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      item.subTitle,
      style: LiveDataConstants.subtitleTextStyle,
    );
  }

  Widget _buildTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.condition.isNotEmpty) _buildConditionChip(),
        const SizedBox(width: TSizes.m),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: LiveDataConstants.iconColor,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildConditionChip() {
    final conditionColor = _getConditionColor(item.condition);

    return Container(
      padding: CommonPaddingWrapper.getPadding(
        left: TSizes.sm,
        right: TSizes.sm,
        top: TSizes.xs,
        bottom: TSizes.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TSizes.xs),
        color: LiveDataConstants.conditionBackground,
      ),
      child: Text(
        item.condition,
        style: LiveDataConstants.conditionTextStyle(conditionColor),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toUpperCase()) {
      case 'ERROR':
      case 'CRITICAL':
        return LiveDataConstants.errorColor;
      case 'MODERATE':
        return LiveDataConstants.moderateColor;
      case 'GOOD':
        return LiveDataConstants.goodColor;
      default:
        return Colors.white;
    }
  }
}
