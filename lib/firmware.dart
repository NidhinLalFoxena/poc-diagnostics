import 'dart:ui';

import 'package:diagnostics_test/update.dart';
import 'package:diagnostics_test/widgets/app_sizes.dart';
import 'package:diagnostics_test/widgets/common_padding_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// Constants for the screen
class FirmwareConstants {
  static const backgroundColor = Color(0xFF030303);
  static const iconColor = Color(0xFF7D7D7D);
  static const containerColor = Color.fromRGBO(23, 23, 23, 0.57);
  static const titleColor = Color(0xFF666666);
  static const valueColor = Color(0xFFFFFFFF);
  static const buttonColor = Color(0xFFFFFFFF);
  static const buttonTextColor = Colors.black;

  static const double blurSigmaX = 9.2;
  static const double blurSigmaY = 9.2;
  static const double buttonHeight = 50.0;

  // Text styles
  static const appBarTextStyle = TextStyle(
    color: Colors.white,
    fontFamily: 'Disket_Mono',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const itemTitleStyle = TextStyle(
    color: titleColor,
    fontFamily: 'Brutal_Type',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.3125,
  );

  static const itemValueStyle = TextStyle(
    color: valueColor,
    fontFamily: 'Brutal_Type',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const buttonTextStyle = TextStyle(
    color: buttonTextColor,
    fontFamily: 'Brutal_Type',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 18 / 14,
    letterSpacing: 0.07,
  );
}

// Data model for firmware items
class FirmwareItem {
  final String title;
  final String value;

  FirmwareItem({
    required this.title,
    required this.value,
  });
}

final List<FirmwareItem> firmwareItems = [
  FirmwareItem(title: 'VCU', value: '20.86'),
  FirmwareItem(title: 'BMS', value: '19.43'),
  FirmwareItem(title: 'MCU', value: '6a06'),
  FirmwareItem(title: 'DCP', value: '2.1'),
  FirmwareItem(title: 'Display', value: '2.1'),
  FirmwareItem(title: 'ec25', value: '4.0'),
];

class FirmWareScreen extends StatelessWidget {
  const FirmWareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: CommonPaddingWrapper.all(
          padding: TSizes.md,
          child: Column(
            children: [
              Expanded(
                child: _buildFirmwareList(),
              ),
              const SizedBox(height: TSizes.md),
              const UpdateButton(),
            ],
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: FirmwareConstants.backgroundColor,
    centerTitle: false,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: FirmwareConstants.iconColor,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    titleSpacing: 0,
    title: Text(
      'FIRMWARE',
      style: FirmwareConstants.appBarTextStyle,
    ),
    actions: [
      IconButton(
        icon: SvgPicture.asset(
          'assets/overview.svg',
          colorFilter: ColorFilter.mode(
            FirmwareConstants.iconColor,
            BlendMode.srcIn,
          ),
        ),
        onPressed: _showOverview,
      ),
    ],
  );
}

Widget _buildFirmwareList() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(TSizes.xs),
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: FirmwareConstants.blurSigmaX,
        sigmaY: FirmwareConstants.blurSigmaY,
      ),
      child: Container(
        padding: CommonPaddingWrapper.getPadding(all: TSizes.md),
        decoration: BoxDecoration(
          color: FirmwareConstants.containerColor,
          borderRadius: BorderRadius.circular(TSizes.xs),
        ),
        child: ListView.separated(
          itemCount: firmwareItems.length,
          itemBuilder: (context, index) =>
              _buildFirmwareItem(firmwareItems[index]),
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: Colors.transparent,
          ),
        ),
      ),
    ),
  );
}

Widget _buildFirmwareItem(FirmwareItem item) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      item.title,
      style: FirmwareConstants.itemTitleStyle,
    ),
    trailing: Text(
      item.value,
      style: FirmwareConstants.itemValueStyle,
    ),
  );
}

void _showOverview() {}

class UpdateButton extends StatelessWidget {
  const UpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FirmwareConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: () => _handleUpdate(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: FirmwareConstants.buttonColor,
          foregroundColor: FirmwareConstants.buttonTextColor,
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(FirmwareConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.xs),
          ),
          elevation: 0,
        ),
        child: Center(
          child: Text(
            "Update",
            style: FirmwareConstants.buttonTextStyle,
          ),
        ),
      ),
    );
  }
}

void _handleUpdate(BuildContext context) {
  showCupertinoModalBottomSheet(
    context: context,
    builder: (context) => const UpdateModalSheet(
      vehicleVin: '1234567890',
    ),
    expand: true,
    topRadius: const Radius.circular(20),
    backgroundColor: Colors.transparent,
  );
}
