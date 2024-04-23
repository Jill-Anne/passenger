import 'package:flutter/material.dart';
import 'package:passenger/pages/booking_screen.dart';

class InfoDialog extends StatefulWidget
{
  String? title, description;

  InfoDialog({super.key, this.title, this.description,});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog>
{
  
  @override
  Widget build(BuildContext context)
  {
    print('InfoDialog is being built with title: ${widget.title}');
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
      ),
      backgroundColor: Colors.grey,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 12,),

                Text(
                  widget.title.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white60,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 27,),

                Text(
                  widget.description.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 32,),

                SizedBox(
                  width: 202,
                  child: ElevatedButton(
                    onPressed: ()
                    {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "OK",
                    ),
                  ),
                ),

                const SizedBox(height: 12,),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

  void showRideOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Schedule a Ride'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookingScreen()),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/ridenow.png",
                          height: 50,
                          width: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Ride Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookingScreen()),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/calendar.png",
                          height: 50,
                          width: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Advance Booking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  