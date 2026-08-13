import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

class AppConfigState {
  final bool isLoading;
  final bool heroSliderEnabled;
  final bool quickActionsEnabled;
  final bool walletCardEnabled;
  final bool nearbyStationsEnabled;
  final bool promoBannerEnabled;
  final bool searchSectionEnabled;

  final double minWalletBalance;
  final double defaultChargingRate;

  final bool maintenanceEnabled;
  final String maintenanceMessage;

  final String supportPhone;
  final String supportEmail;
  final String supportHours;

  final List<Map<String, String>> faqs;
  final List<Map<String, String>> offers;

  AppConfigState({
    this.isLoading = false,
    this.heroSliderEnabled = true,
    this.quickActionsEnabled = true,
    this.walletCardEnabled = true,
    this.nearbyStationsEnabled = true,
    this.promoBannerEnabled = true,
    this.searchSectionEnabled = true,
    this.minWalletBalance = 50.0,
    this.defaultChargingRate = 15.0,
    this.maintenanceEnabled = false,
    this.maintenanceMessage = 'EcoMargin is under maintenance.',
    this.supportPhone = '1800-123-4567',
    this.supportEmail = 'support@ecomargin.com',
    this.supportHours = '24/7 Helpline',
    this.faqs = const [],
    this.offers = const [],
  });

  AppConfigState copyWith({
    bool? isLoading,
    bool? heroSliderEnabled,
    bool? quickActionsEnabled,
    bool? walletCardEnabled,
    bool? nearbyStationsEnabled,
    bool? promoBannerEnabled,
    bool? searchSectionEnabled,
    double? minWalletBalance,
    double? defaultChargingRate,
    bool? maintenanceEnabled,
    String? maintenanceMessage,
    String? supportPhone,
    String? supportEmail,
    String? supportHours,
    List<Map<String, String>>? faqs,
    List<Map<String, String>>? offers,
  }) {
    return AppConfigState(
      isLoading: isLoading ?? this.isLoading,
      heroSliderEnabled: heroSliderEnabled ?? this.heroSliderEnabled,
      quickActionsEnabled: quickActionsEnabled ?? this.quickActionsEnabled,
      walletCardEnabled: walletCardEnabled ?? this.walletCardEnabled,
      nearbyStationsEnabled: nearbyStationsEnabled ?? this.nearbyStationsEnabled,
      promoBannerEnabled: promoBannerEnabled ?? this.promoBannerEnabled,
      searchSectionEnabled: searchSectionEnabled ?? this.searchSectionEnabled,
      minWalletBalance: minWalletBalance ?? this.minWalletBalance,
      defaultChargingRate: defaultChargingRate ?? this.defaultChargingRate,
      maintenanceEnabled: maintenanceEnabled ?? this.maintenanceEnabled,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      supportPhone: supportPhone ?? this.supportPhone,
      supportEmail: supportEmail ?? this.supportEmail,
      supportHours: supportHours ?? this.supportHours,
      faqs: faqs ?? this.faqs,
      offers: offers ?? this.offers,
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfigState> {
  final Ref ref;

  AppConfigNotifier(this.ref) : super(AppConfigState()) {
    fetchAppConfig();
  }

  Future<void> fetchAppConfig() async {
    try {
      state = state.copyWith(isLoading: true);
      final apiClient = ref.read(apiClientProvider);

      final response = await apiClient.dio.get('/app/config');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data
            : Map<String, dynamic>.from(response.data);

        bool hero = true;
        bool quick = true;
        bool wallet = true;
        bool nearby = true;
        bool promo = true;
        bool search = true;

        if (data['home_sections'] != null) {
          try {
            final Map<String, dynamic> hs = data['home_sections'] is String
                ? jsonDecode(data['home_sections'])
                : data['home_sections'];
            hero = hs['hero_slider'] ?? true;
            quick = hs['quick_actions'] ?? true;
            wallet = hs['wallet_card'] ?? true;
            nearby = hs['nearby_stations'] ?? true;
            promo = hs['promo_banner'] ?? true;
            search = hs['search_section'] ?? true;
          } catch (_) {}
        }

        double minBal = 50.0;
        if (data['min_wallet_balance_to_start'] != null) {
          minBal = double.tryParse(data['min_wallet_balance_to_start'].toString()) ?? 50.0;
        }

        double rate = 15.0;
        if (data['default_charging_rate_per_kwh'] != null) {
          rate = double.tryParse(data['default_charging_rate_per_kwh'].toString()) ?? 15.0;
        }

        bool isMaint = false;
        String maintMsg = 'EcoMargin is under maintenance.';
        if (data['app_maintenance'] != null) {
          try {
            final Map<String, dynamic> maint = data['app_maintenance'] is String
                ? jsonDecode(data['app_maintenance'])
                : data['app_maintenance'];
            isMaint = maint['enabled'] ?? false;
            maintMsg = maint['message'] ?? maintMsg;
          } catch (_) {}
        }

        String phone = '1800-123-4567';
        String email = 'support@ecomargin.com';
        String hours = '24/7 Helpline';
        if (data['support_info'] != null) {
          try {
            final Map<String, dynamic> supp = data['support_info'] is String
                ? jsonDecode(data['support_info'])
                : data['support_info'];
            phone = supp['phone'] ?? phone;
            email = supp['email'] ?? email;
            hours = supp['hours'] ?? hours;
          } catch (_) {}
        }

        List<Map<String, String>> parsedFaqs = [];
        if (data['faqs'] != null) {
          try {
            final List raw = data['faqs'] is String ? jsonDecode(data['faqs']) : data['faqs'];
            parsedFaqs = raw.map((item) {
              return {
                'q': item['q']?.toString() ?? '',
                'a': item['a']?.toString() ?? '',
              };
            }).toList();
          } catch (_) {}
        }

        List<Map<String, String>> parsedOffers = [];
        if (data['offers_banners'] != null) {
          try {
            final List raw = data['offers_banners'] is String ? jsonDecode(data['offers_banners']) : data['offers_banners'];
            parsedOffers = raw.map((item) {
              return {
                'code': item['code']?.toString() ?? '',
                'title': item['title']?.toString() ?? '',
                'desc': item['desc']?.toString() ?? '',
                'expiry': item['expiry']?.toString() ?? '',
              };
            }).toList();
          } catch (_) {}
        }

        state = AppConfigState(
          isLoading: false,
          heroSliderEnabled: hero,
          quickActionsEnabled: quick,
          walletCardEnabled: wallet,
          nearbyStationsEnabled: nearby,
          promoBannerEnabled: promo,
          searchSectionEnabled: search,
          minWalletBalance: minBal,
          defaultChargingRate: rate,
          maintenanceEnabled: isMaint,
          maintenanceMessage: maintMsg,
          supportPhone: phone,
          supportEmail: email,
          supportHours: hours,
          faqs: parsedFaqs,
          offers: parsedOffers,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfigState>((ref) {
  return AppConfigNotifier(ref);
});
