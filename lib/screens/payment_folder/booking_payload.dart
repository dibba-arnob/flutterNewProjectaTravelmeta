import 'package:flutter/material.dart';

class BookingPayload {
  final String serviceType;
  final double baseAmount;
  final String currency;
  final Map<String, dynamic> details;
  final DateTime? startsAt;

  // Checkout display
  final String title;
  final String subtitle;
  final String quantitySummary;

  // Confirmation display
  final String checkInLabel;
  final String checkInValue;
  final String guestsLabel;
  final String guestsValue;

  // Service card styling
  final IconData serviceIcon;
  final String serviceLabel;
  final Color accentColor;

  const BookingPayload({
    required this.serviceType,
    required this.baseAmount,
    required this.currency,
    required this.details,
    this.startsAt,
    required this.title,
    required this.subtitle,
    required this.quantitySummary,
    required this.checkInLabel,
    required this.checkInValue,
    required this.guestsLabel,
    required this.guestsValue,
    required this.serviceIcon,
    required this.serviceLabel,
    required this.accentColor,
  });
}
