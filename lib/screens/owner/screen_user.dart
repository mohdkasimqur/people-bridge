import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Ambulance/ambulance_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/CorierService/corrier_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Recovery/screen_recovery_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/IndividualSellers/individual_sellers_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Tea_Shops/screen_tea_shop_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/companies/company_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/foodDelivery/food_delivery_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/freelancers/freelancer_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/otherBusiness/other_business_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/rentals/screen_rentals_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/broker/screen_broker_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/selfEmployi/self_employee_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/spareparts/spare_parts_login.dart';
import 'package:jober_india/l10n/app_localizations.dart';
import 'package:jober_india/screens/owner/screen_houseowner.dart';
import 'package:jober_india/screens/owner/screen_student.dart';
import 'package:jober_india/jober_indiaScreens.dart/Clinic/screen_clinic_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Doctors/screen_doctor_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Groceries/screen_grocery_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/Laboratory/screen_laboratory_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/medical%20shop/screen_mediclshp_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/TaxiCommercial/screen_taxicomrcial_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/garage/screen_garage_login.dart';
import 'package:jober_india/jober_indiaScreens.dart/workers/screen_worker_login.dart';

import '../../jober_indiaScreens.dart/FishFruit Delivery/fish_delivery_login.dart';

class ScreenChooseRole extends StatelessWidget {
  const ScreenChooseRole({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        
      ),

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               Text(AppLocalizations.of(context)!.chooseYourRole,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: Color(0xFF202124),
      ),
    ),

    const SizedBox(height: 8),

     Text(AppLocalizations.of(context)!.registerandconnectwithpeoplenearyou,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF777777),
        height: 1.4,
      ),
    ),

              const SizedBox(height: 35),     
Transform.translate(
  offset: const Offset(-20, 0),
  child: sectionLabel(AppLocalizations.of(context)!.healthCareEmergency
    ),
),

const SizedBox(height: 15),
              // =========================
              // DOCTOR
              // =========================

              _buildRoleCard(
                title: AppLocalizations.of(context)!.doctor,
                subtitle: AppLocalizations.of(context)!.consultationmadeeasier,
                icon: Icons.medical_services_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenDoctorLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // AMBULANCE
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.ambulance,
                subtitle:AppLocalizations.of(context)!.savelifeatrightTime,
                icon: Icons.emergency,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AmbulanceLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // CLINIC
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.clinic,
                subtitle: AppLocalizations.of(context)!.findhealthcareandclinicservices,
                icon: Icons.local_hospital_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenClinicLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // MEDICAL SHOP
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.medicalShop,
                subtitle: AppLocalizations.of(context)!.goforDeliveryRiderstoserveFaster,
                icon: Icons.medical_services_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenMedicalShpLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
               // =========================
              // LABORATORY
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.laboratory,
                subtitle: AppLocalizations.of(context)!.waterclinicaletc,
                icon: Icons.biotech_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenLabLogin(),
                    ),
                  );
                },
              ),
const SizedBox(height: 15),

Transform.translate(
  offset: const Offset(-20, 0),
  child: sectionLabel(AppLocalizations.of(context)!.exploreyourNeeds
    ),
),

const SizedBox(height: 15),
              // =========================
              // STUDENT
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.student,
                subtitle: AppLocalizations.of(context)!.teaTaxisShopsMore,
                icon: Icons.school_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScreenStudent(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // HOUSE OWNER
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.houseOwner,
                subtitle: AppLocalizations.of(context)!.doctorsWorkersTaxisservices,
                icon: Icons.home_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenHouseOwner(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
               // =========================
              // COMPANIES
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.companies,
                subtitle: AppLocalizations.of(context)!.connecthiregrow,
                icon: Icons.factory,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CompanyLoginPage(),
                    ),
                  );
                },
              ),
const SizedBox(height: 15),

Transform.translate(
  offset: const Offset(-20, 0),
  child: sectionLabel(AppLocalizations.of(context)!.oppertunityHub
  ),
),

const SizedBox(height: 15),
              // =========================
              // WORKER
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.worker,
                subtitle: AppLocalizations.of(context)!.yourFutureStartsHere,
                icon: Icons.engineering_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenWorker(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // FREELANCERS
              // =========================
              _buildRoleCard(
                title:AppLocalizations.of(context)!.freelancers,
                subtitle: AppLocalizations.of(context)!.connectdiscoverExplore,
                icon: Icons.work_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenFreelancerLogin(),
                    ),
                  );
                },
              ),
               const SizedBox(height: 4),
              // =========================
              // SELF EMPLOYEE
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.selfEmployed,
                subtitle: AppLocalizations.of(context)!.yourskillsnewopportunities,
                icon: Icons.person_outline_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenSelfEmployeesLogin(),
                    ),
                  );
                },
              ),
const SizedBox(height: 15),

Transform.translate(
  offset: const Offset(-20, 0),
  child: sectionLabel(AppLocalizations.of(context)!.deliveriesRestareas
    ),
),

const SizedBox(height: 15),
              // =========================
              // COURIER SERVICE
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.courierService,
                subtitle: AppLocalizations.of(context)!.noMatterWhereyouare,
                icon: Icons.local_shipping,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenCourierLogin(),
                    ),
                  );
                },
              ),
               const SizedBox(height: 4),
              // =========================
              // TEA SHOPS
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.hotelTeaShops,
                subtitle:  AppLocalizations.of(context)!.deliveryServemoreeasily,
                icon: Icons.restaurant,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenTeaShopLogin(),
                    ),
                  );
                },
              ),
             const SizedBox(height: 4),
             // =========================
             // FOOD DELIVERY
            //  =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.foodDelivery,
                subtitle: AppLocalizations.of(context)!.anywhereNoMatter,
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenFoodDeliveryLogin(),
                    ),
                  );
                },
              ),
               const SizedBox(height: 4),
             // =========================
             // FISH DELIVERY
             //  =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.fishDelivery,
                subtitle: AppLocalizations.of(context)!.anywhereNoMatter,
                icon: Icons.delivery_dining,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenFishDeliveryLogin(),
                    ),
                  );
                },
              ),
const SizedBox(height: 15),

Transform.translate(
  offset: const Offset(-20, 0),
  child: sectionLabel(AppLocalizations.of(context)!.automotiveServices
    ),
),

const SizedBox(height: 15),
               // =========================
              // TAXI / COMMERCIAL
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)! .taxiorotherusesvehicles,
                subtitle: AppLocalizations.of(context)! .startyourJorneyhere,
                icon: Icons.local_taxi_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScreenTaxicomrcialLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // GARAGE / WORKSHOP
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.garageWorkshop,
                subtitle: AppLocalizations.of(context)! .expandyourCustomer,
                icon: Icons.car_repair_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenGarageLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
               // =========================
              // RECOVERY
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.recovery,
                subtitle: AppLocalizations.of(context)!.breakdownisnotaMatter,
                icon: Icons.support_agent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenRecoveryLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
                // =========================
              // SPARE PARTS
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.spareParts,
                subtitle: AppLocalizations.of(context)! .fastResponsemoreBusiness,
                icon: Icons.build_circle_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AutoSparePartsLoginPage(),
                    ),
                  );
                },
              ),
const SizedBox(height: 15),

Transform.translate(
  offset: const Offset(-20, 0),
  child: sectionLabel(AppLocalizations.of(context)!.connectingpoints
    ),
),

const SizedBox(height: 15),
               // =========================
              // BROKERS
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.brokers,
                subtitle: AppLocalizations.of(context)!.landCarsotherservicesInside,
                icon: Icons.handshake_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenBrokerLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // RENTALS
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.rentals,
                subtitle: AppLocalizations.of(context)!.carsbikesFlatsShopsmore,
                icon: Icons.key_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const RentalLoginScreen(),
                    ),
                  );
                },
              ),

const SizedBox(height: 15),

Transform.translate(
  offset: const Offset(-20, 0),
  child: sectionLabel(AppLocalizations.of(context)!.businessHub ),
),

const SizedBox(height: 15),
              // =========================
              // INDIVIDUAL SELLERS
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.individualSellers,
                subtitle: AppLocalizations.of(context)!.growyourbusinessyourWay,
                icon: Icons.storefront_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenSelfBusinessLogin(),
                    ),
                  );
                },
              ),
               const SizedBox(height: 4),
               // =========================
              // GROCERY STORE 
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.groceryStores,
                subtitle: AppLocalizations.of(context)!.dailyessentialsinsingleTouch,
                icon: Icons.shopping_cart_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenGroceryLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // =========================
              // OTHER BUSINESS
              // =========================
              _buildRoleCard(
                title: AppLocalizations.of(context)!.otherBusiness,
                subtitle: AppLocalizations.of(context)!.connectFastGrowFast,
                icon: Icons.business_center_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScreenOtherBusinessLogin(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

Widget sectionLabel(String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
  // ============================================================
  // STANDARD ROLE CARD
  // ============================================================

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),

        child: Container(
          width: double.infinity,
          height: 115,

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(24),

            border: Border.all(
              color: const Color(0xFFE8E8E8),
              width: 1,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 26,
            ),

            child: Row(
              children: [

                // =====================
                // ICON
                // =====================

                Icon(
                  icon,
                  size: 40,
                  color: Colors.red,
                ),

                const SizedBox(width: 28),

                // =====================
                // TITLE + SUBTITLE
                // =====================

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202124),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,

                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // =====================
                // RIGHT ARROW
                // =====================

                const Icon(
                  Icons.chevron_right,
                  size: 33,
                  color: Color(0xFF777777),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}