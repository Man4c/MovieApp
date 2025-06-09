import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Uncomment if using a provider for state
import 'package:flutter_video_app/services/api_service.dart'; // Uncomment when calling API
import 'package:flutter_stripe/flutter_stripe.dart';

class SubscriptionScreen extends StatefulWidget {
  static const String routeName = '/subscription'; // For navigation

  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedPlan; // To keep track of the selected plan
  bool _isLoading = false; // To show a loading indicator

  // Hardcoded plans for now
  final List<Map<String, dynamic>> _plans = [
    {'id': 'basic', 'name': 'Basic Plan', 'price': '\$5/month', 'description': 'Access to basic features.'},
    {'id': 'premium', 'name': 'Premium Plan', 'price': '\$10/month', 'description': 'Access to all premium features.'},
  ];

  void _handlePlanSelection(String planId) {
    setState(() {
      _selectedPlan = planId;
    });
    // In the next step, we'll call the backend here.
    print('Selected plan: $planId');
    // _initiatePayment(planId); // This will be implemented later
  }

  Future<void> _initiatePayment(String planId) async {
    setState(() { _isLoading = true; });
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide previous snackbars

    try {
      // Placeholder for userId - in a real app, get this from your AuthProvider
      const String userId = 'currentUserPlaceholderId';
      if (userId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final Map<String, dynamic> response = await ApiService.createPaymentIntent(userId, planId);
      final String? clientSecret = response['clientSecret'] as String?; // Make sure to cast and check for null

      if (clientSecret == null || clientSecret.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not retrieve payment details from server.')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your App Name', // Replace with your app name
          // customerId: response['customerId'], // Optional: if you have it from backend
          // customerEphemeralKeySecret: response['ephemeralKey'], // Optional: for saving cards
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // After payment sheet is presented and payment is attempted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment attempt completed. Checking status...')),
      );
      // NOTE: The actual success/failure is confirmed via webhooks on the backend.
      // The app gets an immediate client-side indication, but the source of truth is your backend.
      // You might want to navigate the user to a "pending" or "success" screen,
      // and then update based on backend confirmation.

    } on StripeException catch (e) {
      print('StripeException: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Error: ${e.message ?? e.toString()}')),
      );
    } catch (e) {
      print('Error during payment: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Subscription Plan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(plan['name'] as String),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan['price'] as String),
                        Text(plan['description'] as String),
                      ],
                    ),
                    trailing: _selectedPlan == plan['id']
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () => _handlePlanSelection(plan['id'] as String),
                  ),
                );
              },
            ),
      floatingActionButton: _selectedPlan != null
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : () { // Disable button when loading
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
