import 'package:diagnostics_test/profile.dart';
import 'package:diagnostics_test/widgets/app_sizes.dart';
import 'package:diagnostics_test/widgets/common_padding_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// 1:08
// Constants for styles and colors
class AppColors {
  static const primaryBackground = Color(0xFF161616);
  static const secondaryText = Color(0xFF727272);
  static const dividerColor = Color(0xFF3A3A3A);
  static const accentIcon = Color(0xFF92A8B0);
  static const white = Colors.white;
  static const black = Colors.black;
  static const buttonBackground = Color(0xFFFFFFFF);
}

class AppTextStyles {
  static const diskettMono = TextStyle(
    color: AppColors.white,
    fontFamily: 'Disket_Mono',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
  );

  static const brutalType = TextStyle(
    color: AppColors.white,
    fontFamily: 'Brutal_Type',
    fontSize: 16,
  );

  static const brutalTypeSecondary = TextStyle(
    color: AppColors.secondaryText,
    fontFamily: 'Brutal_Type',
    fontSize: 16,
  );

  static const buttonText = TextStyle(
    color: AppColors.black,
    fontFamily: 'Brutal_Type',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 18 / 14,
    letterSpacing: 0.07,
  );
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  ConnectionState _connectionState = ConnectionState.idle;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    // Initially pause the animation
    _lottieController.stop();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            _buildLogo(),
            const SizedBox(height: 20),
            _buildTitle(),
            const Spacer(),
            _buildBottomContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SvgPicture.asset('assets/logo.svg');
  }

  Widget _buildTitle() {
    return Text(
      'DIAGNOSTIC',
      style: AppTextStyles.diskettMono.copyWith(
        height: 18 / 14,
        letterSpacing: 15.82,
      ),
    );
  }

  Widget _buildBottomContent(BuildContext context) {
    return CommonPaddingWrapper.all(
      child: Column(
        children: [
          SizedBox(
            child: Lottie.asset(
              'assets/bikelottie.json',
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration
                  ..stop();
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionText(),
          const SizedBox(height: 12),
          _buildConnectButton(context),
        ],
      ),
    );
  }

  Widget _buildInstructionText() {
    String text;
    switch (_connectionState) {
      case ConnectionState.connecting:
        text = 'Connection in progress...';
      case ConnectionState.connected:
        text = 'Handshake successful';
      default:
        text = 'Connect OBD 2 and initiate the connection';
    }

    return Text(
      text,
      style: AppTextStyles.brutalTypeSecondary.copyWith(
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w400,
        height: 18 / 14,
        letterSpacing: 0.07,
        color: _connectionState == ConnectionState.connected
            ? Color(0xFF8FFF93)
            : null,
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _connectionState == ConnectionState.idle
            ? () => _showConnectBottomSheet(context)
            : () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBackground,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.xs),
          ),
          elevation: 0,
        ),
        child: _buildButtonChild(),
      ),
    );
  }

  Widget _buildButtonChild() {
    switch (_connectionState) {
      case ConnectionState.connecting:
        return Lottie.asset(
          'assets/app_button_loader.json',
        );
      case ConnectionState.connected:
        return const Icon(
          Icons.check_rounded,
          size: 30,
          color: Colors.black,
        );
      default:
        return Text(
          "Connect",
          style: AppTextStyles.buttonText,
        );
    }
  }

  void _showConnectBottomSheet(BuildContext context) {
    showBarModalBottomSheet(
      topControl: Container(
        height: 4,
        width: 50,
        color: Color(0xFF363636),
      ),
      context: context,
      backgroundColor: AppColors.primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => _buildBottomSheetContent(context),
    ).then(
      (_) {
        // When bottom sheet is closed
        if (_connectionState == ConnectionState.idle) {
          // User didn't select any device
          return;
        }

        // Start connection process
        setState(() => _connectionState = ConnectionState.connecting);
        _lottieController.repeat();

        // Simulate connection process
        Future.delayed(
          const Duration(seconds: 4),
          () {
            setState(() => _connectionState = ConnectionState.connected);
            _lottieController.stop();

            // Navigate to profile after success
            Future.delayed(
              const Duration(seconds: 1),
              () {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetContent(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBottomSheetHeader(),
          _buildObdDeviceList(),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader() {
    return CommonPaddingWrapper.only(
      top: TSizes.lg,
      bottom: TSizes.md,
      left: TSizes.md,
      right: TSizes.md,
      child: Row(
        spacing: TSizes.md,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select OBD', style: AppTextStyles.diskettMono),
                const SizedBox(height: 8),
                Text(
                  'Not seeing your connector? Make sure the OBD2 is connected to the vehicle and try again',
                  style: AppTextStyles.brutalTypeSecondary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SvgPicture.asset('assets/autorenew.svg')
        ],
      ),
    );
  }

  Widget _buildObdDeviceList() {
    return Expanded(
      child: ListView.separated(
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFF1F1F1F),
        ),
        padding: EdgeInsets.zero,
        itemCount: 10,
        itemBuilder: (context, index) => ObdListItem(
          deviceName: 'OBD-1234',
          onTap: () {
            // Set state to indicate user selected a device
            setState(() => _connectionState = ConnectionState.connecting);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

enum ConnectionState {
  idle,
  connecting,
  connected,
}

// Extracted widget for OBD list item
class ObdListItem extends StatelessWidget {
  final String deviceName;
  final VoidCallback onTap;

  const ObdListItem({
    super.key,
    required this.deviceName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: CommonPaddingWrapper.getPadding(
        left: TSizes.md,
        right: TSizes.md,
        top: TSizes.m1,
        bottom: TSizes.m1,
      ),
      onTap: onTap,
      leading: SvgPicture.asset('assets/two_wheeler.svg'),
      title: Text(
        deviceName,
        style: AppTextStyles.brutalType.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.normal,
        ),
      ),
      trailing: Text(
        'Tap to connect',
        style: AppTextStyles.brutalType.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.normal,
          color: Color(0xFF828282),
        ),
      ),
    );
  }
}
