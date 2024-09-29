import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:passenger/serviceRequest/serviceHistoryFulldetailsALL.dart';
import 'package:passenger/serviceRequest/servicehistoryFulldetailsCompleted.dart';
import 'package:passenger/serviceRequest/servicehistryFulldetailsCancelled.dart';

class ServiceHistory extends StatefulWidget {
  @override
  _ServiceHistoryState createState() => _ServiceHistoryState();
}

class _ServiceHistoryState extends State<ServiceHistory> {
  int selectedIndex = 0; // Default tab index for ALL

  // Function to change the tab
  void onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'Service Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 1, 42, 123),
      ),
      body: Column(
        children: [
          // Tab bar with background color
          Container(
            height: 50,
            color: Color.fromARGB(255, 1, 42, 123),
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ALL Tab
                GestureDetector(
                  onTap: () => onTabSelected(0),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 0
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'ALL',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 0 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                // COMPLETED Tab
                GestureDetector(
                  onTap: () => onTabSelected(1),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 1
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 1 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                // CANCELLED Tab
                GestureDetector(
                  onTap: () => onTabSelected(2),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: selectedIndex == 2
                          ? Color.fromARGB(255, 1, 42, 123)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 2
                              ? Colors.white
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'CANCELLED',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedIndex == 2 ? Colors.white : Colors.grey,
                        fontWeight: selectedIndex == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content changes based on selected tab
          Expanded(
            child: selectedIndex == 0
                ? AllServicesPage()
                : selectedIndex == 1
                    ? CompletedServicesPage()
                    : CancelledServicesPage(),
          ),
        ],
      ),
    );
  }
}

class AllServicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error occurred: ${snapshot.error}'));
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(child: Text('No services found.'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              String status = service['status'] ?? 'Unknown';

              return _buildServiceTile(context, service, status); // Pass context here
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchServices() async {
    // Fetch completed services
    final completedServices = await FirebaseFirestore.instance
        .collection('Advance Booking History')
        .where('status', whereIn: ['Completed', 'No Appearance']).get();

    // Fetch cancelled services
    final cancelledServices = await FirebaseFirestore.instance
        .collection('Cancelled Service')
        .where('status', isEqualTo: 'Rejected and Cancelled')
        .get();

    // Combine both lists
    return [...completedServices.docs, ...cancelledServices.docs];
  }

  Widget _buildServiceTile(
      BuildContext context, DocumentSnapshot service, String status) {
    // Ensure 'postedAt' is a Timestamp
    Timestamp? timestamp = service['postedAt'] as Timestamp?;
    DateTime dateTime = timestamp?.toDate() ?? DateTime.now(); // Fallback to now if null

    // Check if there are dates available
    List<dynamic> dates = service['dates'] ?? [];
    if (dates.isNotEmpty) {
      // Get the latest date from the dates array
      DateTime latestDate = dates
          .map((dateEntry) => (dateEntry['date'] as Timestamp).toDate())
          .reduce((a, b) => a.isAfter(b) ? a : b);
      dateTime = latestDate; // Update to latest date
    }

    String formattedDate = DateFormat('MMMM d, y h:mm a').format(dateTime);

    // Safely retrieve other fields
    String from = service['from'] ?? 'Unknown';
    String to = service['to'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Color.fromARGB(21, 245, 245, 245), // Light background color
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: Text(
              'Trip on $formattedDate',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From $from to $to',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 4), // Small space between lines
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 12,
                    color: status == 'Completed' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            leading: Icon(Icons.event),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () {
              // Navigate to the ServiceDetailPage when the tile is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailPage(service: service),
                ),
              );
            },
          ),
        ),
        Divider(
          thickness: 2, // Adjust thickness
          color: Colors.grey[400], // Adjust color
          indent: 20, // Adjust the left padding of the divider
          endIndent: 20, // Adjust the right padding of the divider
        ),
      ],
    );
  }
}


class CompletedServicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(247, 245, 245, 245),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Advance Booking History')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error occurred'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.requireData;
                if (data.docs.isEmpty) {
                  return const Center(child: Text('No Completed Services'));
                }

                // Initialize a map to group services by completion date
                Map<String, List<DocumentSnapshot>> groupedServices = {};

                // Filter and group services by completed dates
                for (var service in data.docs) {
                  if (service.data() is Map<String, dynamic>) {
                    final serviceData = service.data() as Map<String, dynamic>;

                    if (serviceData.containsKey('dates') &&
                        serviceData['dates'] is List) {
                      List<dynamic> datesArray = serviceData['dates'];

                      for (var dateEntry in datesArray) {
                        if (dateEntry is Map<String, dynamic> &&
                            dateEntry['status'] == 'Completed') {
                          String completedTime = dateEntry['completed time'] ?? 'No time available';

                          // Parse the date string into DateTime
                          DateTime parsedDate;
                          try {
                            parsedDate = DateFormat("MMMM d, yyyy 'at' h:mm a").parse(completedTime);
                          } catch (e) {
                            print("Date parsing error: $e");
                            continue; // Skip this entry if parsing fails
                          }

                          String dateKey = DateFormat('MMM d, yyyy').format(parsedDate);

                          // Add the service to the appropriate group
                          if (!groupedServices.containsKey(dateKey)) {
                            groupedServices[dateKey] = [];
                          }
                          groupedServices[dateKey]!.add(service);
                          break; // Exit loop after finding a completed entry
                        }
                      }
                    }
                  }
                }

                // Check if any services were grouped
                if (groupedServices.isEmpty) {
                  return const Center(child: Text('No Completed Services'));
                }

                // Use ListView.builder to display the grouped services
                return ListView.builder(
                  itemCount: groupedServices.keys.length,
                  itemBuilder: (context, index) {
                    final dateKey = groupedServices.keys.elementAt(index);
                    final servicesForDate = groupedServices[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            dateKey,
                            style: TextStyle(
                              color:  Color.fromARGB(255, 1, 42, 123),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ...servicesForDate.map((service) {
                          return _buildListTile(service, context);
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 10,
            left: 15,
            bottom: 40,
            child: Text(
              'As of ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: TextStyle(
                color: Color.fromARGB(255, 1, 42, 123),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(DocumentSnapshot service, BuildContext context) {
    final serviceData = service.data() as Map<String, dynamic>;
    String completedTime = '';

    if (serviceData.containsKey('dates') && serviceData['dates'] is List) {
      List<dynamic> datesArray = serviceData['dates'];

      for (var dateEntry in datesArray) {
        if (dateEntry is Map<String, dynamic> && dateEntry['status'] == 'Completed') {
          completedTime = dateEntry['completed time'] ?? 'No time available';
          break; // Exit loop after finding completed time
        }
      }
    }

    return Container(
      color: Color.fromARGB(21, 245, 245, 245),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: Text(
              'Completed on $completedTime',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            subtitle: Text(
              'From ${serviceData["from"]} to ${serviceData["to"]}',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            leading: Icon(Icons.event),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceHistoryFullCompletedPage(service: service),
                ),
              );
            },
          ),
          Divider(
            thickness: 2,
            color: Colors.grey[400],
            indent: 20,
            endIndent: 20,
          ),
        ],
      ),
    );
  }
}
class CancelledServicesPage extends StatefulWidget {
  const CancelledServicesPage({super.key});

  @override
  _CancelledServicesPageState createState() => _CancelledServicesPageState();
}

class _CancelledServicesPageState extends State<CancelledServicesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(247, 245, 245, 245),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Cancelled Service')
                  .where('status', isEqualTo: 'Rejected and Cancelled')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error occurred'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.requireData;
                if (data.docs.isEmpty) {
                  return const Center(child: Text('No Cancelled Services'));
                }

                // Group cancelled services by cancellation date from the array
                Map<String, List<DocumentSnapshot>> groupedServices = {};
                
                for (var service in data.docs) {
                  List<dynamic> datesArray = service['dates'];
                  
                  for (var dateEntry in datesArray) {
                    if (dateEntry is Map<String, dynamic> && 
                        dateEntry['status'] == 'Cancelled') {
                      DateTime cancelledDate = dateEntry['date'].toDate();
                      String formattedDate = DateFormat('MMM d, yyyy').format(cancelledDate);

                      if (!groupedServices.containsKey(formattedDate)) {
                        groupedServices[formattedDate] = [];
                      }
                      groupedServices[formattedDate]!.add(service);
                    }
                  }
                }

                // Sort the grouped dates in descending order
                List<String> sortedDates = groupedServices.keys.toList()
                  ..sort((a, b) => DateFormat('MMM d, yyyy')
                      .parse(b)
                      .compareTo(DateFormat('MMM d, yyyy').parse(a)));

                // Use ListView.builder
                return ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final dateKey = sortedDates[index];
                    final servicesForDate = groupedServices[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            dateKey, // Displaying the grouped date
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 42, 123),
                            ),
                          ),
                        ),
                        ...servicesForDate.map((service) {
                          return Column(
                            children: [
                              _buildListTile(service, context), // Display the service ListTile
                              Divider(
                                height: 1,
                                thickness: 2,
                                color: Colors.grey[400],
                                indent: 20,
                                endIndent: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 10,
            left: 15,
            child: Text(
              'As of ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: TextStyle(
                color: Color.fromARGB(255, 1, 42, 123),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildListTile(DocumentSnapshot service, BuildContext context) {
  DateTime serviceDate = service['date'].toDate();

  // Assuming 'cancelled time' is stored in the 'dates' array of the service document
  String cancelledTime = '';
  List<dynamic> datesArray = service['dates'];

  for (var dateEntry in datesArray) {
    if (dateEntry['status'] == 'Cancelled') {
      cancelledTime = dateEntry['cancelled time'] ?? ''; // Get the cancelled time
      break; // Exit after finding the first cancelled entry
    }
  }

  return Container(
    color: Color.fromARGB(21, 245, 245, 245),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      title: Text(
        'Cancelled at $cancelledTime for Scheduled Service Request on ${DateFormat.yMMMd().format(serviceDate)}',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      subtitle: Text(
        'From ${service["from"]} to ${service["to"]}',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
      leading: Icon(Icons.cancel),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceHistoryFullCancelledPage(service: service),
          ),
        );
      },
    ),
  );
}

}
