class PlanModel {
  final String id;
  final String name;
  final int monthlyPrice;
  final int annualPrice;
  final int diagramsPerMonth;
  final int chatMessagesPerMonth;
  final List<String> features;
  final bool isPopular;

  const PlanModel({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.diagramsPerMonth,
    required this.chatMessagesPerMonth,
    required this.features,
    this.isPopular = false,
  });
}

final List<PlanModel> kPlans = [
  PlanModel(
    id: 'free',
    name: 'Free',
    monthlyPrice: 0,
    annualPrice: 0,
    diagramsPerMonth: 10,
    chatMessagesPerMonth: 20,
    features: [
      '10 diagrams / month',
      '20 chat messages / month',
      '3 diagram types only',
      'Generate mode only',
      'No export',
    ],
  ),
  PlanModel(
    id: 'pro',
    name: 'Pro',
    monthlyPrice: 99,
    annualPrice: 799,
    diagramsPerMonth: 100,
    chatMessagesPerMonth: 200,
    isPopular: true,
    features: [
      '100 diagrams / month',
      '200 chat messages / month',
      'All 10 diagram types',
      'All 3 generation modes',
      'Export PNG & SVG',
      '30 days history',
    ],
  ),
  PlanModel(
    id: 'enterprise',
    name: 'Enterprise',
    monthlyPrice: 299,
    annualPrice: 2499,
    diagramsPerMonth: -1,
    chatMessagesPerMonth: -1,
    features: [
      'Unlimited diagrams',
      'Unlimited chat messages',
      'All 10 diagram types',
      'All 3 generation modes',
      'Export PNG, SVG & PDF',
      'Unlimited history',
    ],
  ),
];