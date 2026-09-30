import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/order_item.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import '../bottom_navigation.dart';
import 'order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderItem order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final bool isSmall = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.matteBlack,
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmall ? 24 : 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 450 : double.infinity),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmall ? 24 : 32),
                      decoration: BoxDecoration(
                        color: AppTheme.brushedPlatinum.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.glassBorder, width: 1.2),
                      ),
                      child: Icon(Icons.check_rounded, color: AppTheme.brushedPlatinum, size: isSmall ? 48 : 64),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    
                    SizedBox(height: isSmall ? 32 : 48),
                    
                    Text(
                      'ORDER\nCONFIRMED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 24 : 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.polishedSilver,
                        height: 1.2,
                        letterSpacing: 1,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    
                    SizedBox(height: isSmall ? 20 : 32),
                    
                    const Text(
                      'Your order has been placed successfully. You will receive an update once it is shipped.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.coolGrey, height: 1.6, fontSize: 13),
                    ).animate().fadeIn(delay: 500.ms),
                    
                    SizedBox(height: isSmall ? 40 : 64),
                    
                    GoldButton(
                      label: 'TRACK ORDER',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)));
                      },
                    ).animate().fadeIn(delay: 700.ms),
                    
                    const SizedBox(height: 20),
                    
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BottomNavigation()), (_) => false);
                      },
                      child: const Text('BACK TO SHOP', style: TextStyle(color: AppTheme.coolGrey, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
