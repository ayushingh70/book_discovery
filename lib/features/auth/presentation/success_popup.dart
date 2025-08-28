import 'package:flutter/material.dart';

class SuccessPopup extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onDone;

  const SuccessPopup({
    super.key,
    this.title = "Success",
    this.message = "Congratulations, you have completed your registration!\nStart discovering your books.",
    this.buttonText = "Done",
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //  Circle icon
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF3D5CFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F39),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 17,
                color: Color(0xFF858597),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Done button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5CFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onDone,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}