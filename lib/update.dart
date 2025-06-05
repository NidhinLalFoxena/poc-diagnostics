import 'package:diagnostics_test/firmware.dart';
import 'package:diagnostics_test/widgets/app_sizes.dart';
import 'package:diagnostics_test/widgets/common_padding_wrapper.dart';
import 'package:flutter/material.dart';

class UpdateModalSheet extends StatefulWidget {
  final String vehicleVin;

  const UpdateModalSheet({
    super.key,
    required this.vehicleVin,
  });

  @override
  State<UpdateModalSheet> createState() => _UpdateModalSheetState();
}

class _UpdateModalSheetState extends State<UpdateModalSheet> {
  static const _defaultComment = 'Select Comment';
  String _selectedComment = _defaultComment;
  bool get _isCommentSelected => _selectedComment != _defaultComment;

  final List<String> _comments = const [
    'Software mismatch',
    'Firmware bug',
    'Performance issue',
    'Others'
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      color: FirmwareConstants.backgroundColor,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: TSizes.md),
            _buildContent(),
            const Spacer(),
            _buildSendButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return CommonPaddingWrapper.all(
      padding: TSizes.md,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF7D7D7D),
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: TSizes.m),
          const Text(
            'UPDATE',
            style: FirmwareConstants.appBarTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CommonPaddingWrapper.all(
      padding: TSizes.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVinField(),
          const SizedBox(height: TSizes.xl),
          _buildCommentsDropdown(),
        ],
      ),
    );
  }

  Widget _buildVinField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VEHICLE VIN',
          style: _labelTextStyle,
        ),
        const SizedBox(height: TSizes.m1),
        Container(
          width: double.infinity,
          padding: CommonPaddingWrapper.getPadding(
            left: TSizes.l1,
            right: TSizes.l1,
            top: TSizes.l1,
            bottom: TSizes.l1,
          ),
          decoration: BoxDecoration(
            color: FirmwareConstants.containerColor,
            borderRadius: BorderRadius.circular(TSizes.xs),
          ),
          child: Text(
            widget.vehicleVin,
            style: _valueTextStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMENTS',
          style: _labelTextStyle,
        ),
        const SizedBox(height: TSizes.m1),
        Container(
          padding: CommonPaddingWrapper.getPadding(
            left: TSizes.l1,
            right: TSizes.l1,
            top: TSizes.sm,
            bottom: TSizes.sm,
          ),
          width: double.infinity,
          decoration: BoxDecoration(
            color: FirmwareConstants.containerColor,
            borderRadius: BorderRadius.circular(TSizes.xs),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedComment,
              dropdownColor: FirmwareConstants.containerColor,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF7D7D7D),
                size: 30,
              ),
              style: _valueTextStyle,
              onChanged: _handleCommentChange,
              items: _buildDropdownItems(),
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    return [_defaultComment, ..._comments].map((value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(
          value,
          style: _valueTextStyle,
        ),
      );
    }).toList();
  }

  void _handleCommentChange(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedComment = newValue;
      });
    }
  }

  Widget _buildSendButton(BuildContext context) {
    return CommonPaddingWrapper.all(
      padding: TSizes.md,
      child: SizedBox(
        width: double.infinity,
        height: FirmwareConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: _isCommentSelected ? () => _handleSend(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCommentSelected
                ? FirmwareConstants.buttonColor
                : FirmwareConstants.buttonColor.withOpacity(0.5),
            foregroundColor: FirmwareConstants.buttonTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TSizes.xs),
            ),
            elevation: 0,
          ),
          child: Text(
            "SEND",
            style: FirmwareConstants.buttonTextStyle,
          ),
        ),
      ),
    );
  }

  void _handleSend(BuildContext context) {
    Navigator.of(context).pop(_selectedComment);
  }

  // Text styles
  static const _labelTextStyle = TextStyle(
    color: Color(0xFF828282),
    fontFamily: 'Disket_Mono',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
  );

  static const _valueTextStyle = TextStyle(
    color: Color.fromRGBO(192, 192, 192, 0.7),
    fontFamily: 'Brutal_Type',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
