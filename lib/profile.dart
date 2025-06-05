// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:diagnostics_test/firmware.dart';
import 'package:diagnostics_test/livedata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:diagnostics_test/widgets/app_sizes.dart';
import 'package:diagnostics_test/widgets/common_padding_wrapper.dart';

// Constants for the screen
class ProfileScreenConstants {
  static const double blurSigmaX = 9.2;
  static const double blurSigmaY = 9.2;
  static const double profileImageSize = 55.0;
  static const double connectionButtonHeight = 50.0;
  static const double connectionIndicatorSize = 15.0;
  static const double gridChildAspectRatio = 1.3;
  static const int gridItemCount = 4;
}

// Custom text styles for the profile screen
extension ProfileTextStyles on TextTheme {
  TextStyle get profileVehicleNumber => const TextStyle(
        color: Colors.white,
        fontFamily: 'Brutal_Type',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: -0.1,
      );

  TextStyle get profileVehicleModel => const TextStyle(
        color: Color(0xFF828282),
        fontFamily: 'Brutal_Type',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 24 / 13,
        letterSpacing: -0.1,
      );

  TextStyle get profileLabel => const TextStyle(
        color: Color(0xFF666666),
        fontFamily: 'Brutal_Type',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 21 / 12,
      );

  TextStyle get profileValue => const TextStyle(
        color: Color(0xFFA4A4A4),
        fontFamily: 'Brutal_Type',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 14,
      );

  TextStyle get menuItemTitle => const TextStyle(
        color: Colors.white,
        fontFamily: 'Brutal_Type',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
        letterSpacing: 0.07,
      );

  TextStyle get connectionStatus => const TextStyle(
        color: Colors.white,
        fontFamily: 'Brutal_Type',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
        letterSpacing: 0.07,
      );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final totalSpacing = TSizes.md;
    final itemWidth = (screenWidth - totalSpacing) / 2;
    final containerHeight =
        itemWidth / ProfileScreenConstants.gridChildAspectRatio;

    return SafeArea(
      child: Scaffold(
        body: CommonPaddingWrapper.all(
          padding: TSizes.lg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const ProfileCard(),
                      const SizedBox(height: TSizes.md),
                      _buildGridMenu(theme, context),
                      const SizedBox(height: TSizes.md),
                      Reports(containerHeight: containerHeight),
                      const SizedBox(height: TSizes.md),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const ConnectionButton(),
      ),
    );
  }

  Widget _buildGridMenu(ThemeData theme, BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': 'assets/live_deta.svg',
        'title': 'Live Data',
        'onTap': () {
          // push to LiveDataScreen
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LiveDataScreen()));
        },
      },
      {
        'icon': 'assets/firmware.svg',
        'title': 'Firmware',
        'onTap': () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FirmWareScreen(),
              ));
        },
      },
      {
        'icon': 'assets/diagnose.svg',
        'title': 'Diagnose',
        'onTap': () {
          // Handle History tap
          print('History tapped');
        },
      },
      {
        'icon': 'assets/service_history.svg',
        'title': 'Service History',
        'onTap': () {
          // Handle Help tap
          print('Help tapped');
        },
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: TSizes.md,
      mainAxisSpacing: TSizes.md,
      childAspectRatio: ProfileScreenConstants.gridChildAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        ProfileScreenConstants.gridItemCount,
        (index) {
          final item = menuItems[index];
          return DataBox(
            icon: item['icon']!,
            title: item['title']!,
            onTap: item['onTap']!,
          );
        },
      ),
    );
  }
}

class ConnectionButton extends StatelessWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CommonPaddingWrapper.all(
      child: SizedBox(
        height: ProfileScreenConstants.connectionButtonHeight,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF262525),
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromHeight(
              ProfileScreenConstants.connectionButtonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TSizes.xs),
            ),
            elevation: 0,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fiber_manual_record,
                  size: ProfileScreenConstants.connectionIndicatorSize,
                  color: Color(0xFF8FFF93),
                ),
                const SizedBox(width: TSizes.sm),
                Text(
                  "Connection Active",
                  style: theme.textTheme.connectionStatus,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(TSizes.xs),
      onTap: () {},
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TSizes.xs),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: ProfileScreenConstants.blurSigmaX,
              sigmaY: ProfileScreenConstants.blurSigmaY,
            ),
            child: Container(
              padding: CommonPaddingWrapper.getPadding(all: TSizes.md),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(23, 23, 23, 0.57),
                borderRadius: BorderRadius.circular(TSizes.xs),
              ),
              child: Column(
                children: [
                  _buildProfileHeader(theme),
                  const SizedBox(height: TSizes.md),
                  _buildVehicleInfo(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileInfo(theme),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF828282),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: ProfileScreenConstants.profileImageSize,
          height: ProfileScreenConstants.profileImageSize,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/bike.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            color: const Color(0xFF232323),
            border: Border.all(
              color: const Color(0xFF232323),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(TSizes.xs),
          ),
        ),
        const SizedBox(width: TSizes.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KA51GD2446',
              style: theme.textTheme.profileVehicleNumber,
            ),
            Text(
              'F77 Mach 2',
              style: theme.textTheme.profileVehicleModel,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleInfo(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoColumn(
          theme,
          label: 'VIN',
          value: 'P7111B129SM00870',
        ),
        _buildInfoColumn(
          theme,
          label: 'IMEI',
          value: '866308064310543',
        ),
      ],
    );
  }

  Widget _buildInfoColumn(ThemeData theme,
      {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.profileLabel,
        ),
        Text(
          value,
          style: theme.textTheme.profileValue,
        ),
      ],
    );
  }
}

class Reports extends StatelessWidget {
  const Reports({
    super.key,
    required this.containerHeight,
  });

  final double containerHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BlurredMenuContainer(
      height: containerHeight,
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/bar_chart.svg',
            semanticsLabel: 'Reports Chart',
          ),
          Text(
            'Reports',
            style: theme.textTheme.menuItemTitle,
          ),
        ],
      ),
    );
  }
}

class DataBox extends StatelessWidget {
  const DataBox({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final String icon;
  final String title;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BlurredMenuContainer(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            icon,
            semanticsLabel: '$title Icon',
          ),
          Text(
            title,
            style: theme.textTheme.menuItemTitle,
          ),
        ],
      ),
    );
  }
}

class _BlurredMenuContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double? height;

  const _BlurredMenuContainer({
    required this.child,
    required this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(TSizes.xs),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TSizes.xs),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ProfileScreenConstants.blurSigmaX,
            sigmaY: ProfileScreenConstants.blurSigmaY,
          ),
          child: Container(
            padding: CommonPaddingWrapper.getPadding(all: TSizes.md),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(23, 23, 23, 0.57),
              borderRadius: BorderRadius.circular(TSizes.xs),
            ),
            height: height,
            width: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}
