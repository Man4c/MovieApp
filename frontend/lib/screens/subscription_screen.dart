import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_video_app/providers/auth_provider.dart';
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

// <-- FIX: Data model for type safety
class Plan {
  final String id;
  final String stripePriceId;
  final String name;
  final String price;
  final String description;

  const Plan({
    required this.id,
    required this.stripePriceId,
    required this.name,
    required this.price,
    required this.description,
  });
}

class SubscriptionScreen extends StatefulWidget {
  static const String routeName = '/subscription';

  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Plan? _selectedPlan; // <-- FIX: Use the Plan object for state
  bool _isLoading = false;

  // <-- FIX: Use the Plan model. Replace with your actual Stripe Price IDs!
  final List<Plan> _plans = [
    Plan(
      id: 'basic',
      stripePriceId:
          'price_1RYDjQFJqSjpkwgi7LpWIYfj', // Your Basic Plan Price ID from Stripe
      name: 'Basic Plan',
      price: '\$5/month',
      description: 'Access to basic features.',
    ),
    Plan(
      id: 'premium',
      stripePriceId:
          'price_1RYDgNFJqSjpkwgim7nwsQ4F', // Your Premium Plan Price ID from Stripe
      name: 'Premium Plan',
      price: '\$10/month',
      description: 'Access to all premium features.',
    ),
  ];

  void _handlePlanSelection(Plan plan) {
    setState(() {
      _selectedPlan = plan;
    });
    print('Selected plan: ${plan.name}');
  }

  Future<void> _initiatePayment(Plan plan) async {
    setState(() {
      _isLoading = true;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      // Get the current user from your AuthProvider
      final currentUser = await ApiService.getMe();
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final userId = currentUser.id;

      // Create subscription and get payment intent
      final Map<String, dynamic> response =
          await ApiService.createPaymentIntent(userId, plan.stripePriceId);

      final String? clientSecret = response['clientSecret'] as String?;
      final String? subscriptionId = response['subscriptionId'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Could not retrieve payment details from server.',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Movie App',
          customerId: response['customerId'] as String?,
          customerEphemeralKeySecret: response['ephemeralKey'] as String?,
        ),
      ); // Present payment sheet and wait for result
      await Stripe.instance.presentPaymentSheet();

      // Confirm subscription after successful payment
      if (subscriptionId != null) {
        await ApiService.confirmSubscription(subscriptionId);
      }

      // Refresh user data to get updated subscription status
      await Provider.of<AuthProvider>(context, listen: false).refreshUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful! Your ${plan.name} is now active.'),
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate back or to home screen after successful subscription
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on StripeException catch (e) {
      print('StripeException: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Error: ${e.error.message ?? 'An unknown error occurred'}',
          ),
        ),
      );
    } catch (e) {
      print('Error during payment: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Subscription Plan')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final Plan plan = _plans[index]; // <-- FIX: Strongly typed
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      // <-- FIX: Clean and type-safe property access
                      title: Text(plan.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.price),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(plan.description),
                          ),
                        ],
                      ),
                      trailing:
                          _selectedPlan?.id == plan.id
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                              : const Icon(Icons.radio_button_unchecked),
                      onTap: () => _handlePlanSelection(plan),
                    ),
                  );
                },
              ),
      floatingActionButton:
          _selectedPlan != null
              ? FloatingActionButton.extended(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          if (_selectedPlan != null) {
                            _initiatePayment(_selectedPlan!);
                          }
                        },
                label: const Text('Proceed to Payment'),
                icon: const Icon(Icons.payment),
              )
              : null,
    );
  }
}
