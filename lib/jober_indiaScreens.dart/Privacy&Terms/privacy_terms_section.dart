import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Privacy&Terms/web_liknks.dart';
import 'package:url_launcher/url_launcher.dart';


class PrivacyTermsSection extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? errorText;

  const PrivacyTermsSection({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  Future<void> _openLink(
    BuildContext context,
    String url,
  ) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'This page is not available yet.',
          ),
        ),
      );

      return;
    }

    final Uri uri =
        Uri.parse(url);

    try {
      final bool opened =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open the webpage.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Unable to open URL: $e',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the webpage.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor:
                  const Color(0xFF16803C),
            ),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(
                  top: 12,
                  right: 8,
                ),
                child: Wrap(
                  children: [
                    const Text(
                      'I agree to the ',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Color(0xFF333333),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        _openLink(
                          context,
                          AppLinks
                              .privacyPolicy,
                        );
                      },
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF16803C),
                          decoration:
                              TextDecoration
                                  .underline,
                        ),
                      ),
                    ),

                    const Text(
                      ' and ',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Color(0xFF333333),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        _openLink(
                          context,
                          AppLinks
                              .termsConditions,
                        );
                      },
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF16803C),
                          decoration:
                              TextDecoration
                                  .underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (errorText != null &&
            errorText!.trim().isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              left: 12,
              top: 2,
            ),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}