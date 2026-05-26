import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GroupMembersScreen extends StatefulWidget {

  final int? groupId;
  final Map user;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.user,
  });

  @override
  State<GroupMembersScreen> createState() =>
      _GroupMembersScreenState();
}

class _GroupMembersScreenState
    extends State<GroupMembersScreen> {

  List<dynamic> members = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  void fetchMembers() async {

    try {

      final data =
          await ApiService.getGroupMembers(
              widget.groupId!
          );

      setState(() {
        members = data;
      });

    } catch(e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
              "Error cargando integrantes"
          ),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      setState(() => isLoading = false);

    }
  }

  @override
  Widget build(BuildContext context) {

    final currentUserId =
        widget.user['idUser'] ??
        widget.user['id_user'];

    return Scaffold(

      backgroundColor: Colors.grey.shade50,

      body: Column(

        children: [

          Container(

            width: double.infinity,

            padding: EdgeInsets.fromLTRB(
                20,
                50,
                20,
                25
            ),

            decoration: BoxDecoration(

              gradient: LinearGradient(

                colors: [
                  Color(0xFF5F2C82),
                  Color(0xFF49A09D),
                ],

                begin: Alignment.topCenter,

                end: Alignment.bottomCenter,
              ),

              borderRadius:
                  BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    GestureDetector(

                      onTap: () {
                        Navigator.pop(context);
                      },

                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(width: 15),

                    Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(

                          "Chat de grupo",

                          style: TextStyle(

                            color: Colors.white,

                            fontSize: 26,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(

                          "Integrantes",

                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          Expanded(

            child: isLoading

                ? Center(
                    child:
                        CircularProgressIndicator(
                      color: Color(0xFF5F2C82),
                    ),
                  )

                : ListView.builder(

                    padding:
                        EdgeInsets.symmetric(
                            horizontal: 20),

                    itemCount: members.length,

                    itemBuilder:
                        (context,index) {

                      final member =
                          members[index];

                      final bool isMe =
                          member['idUser'] ==
                          currentUserId;

                      final bool isDriver =
                          member['role'] ==
                          "Conductor";

                      return Container(

                        margin:
                            EdgeInsets.only(
                                bottom: 15),

                        padding:
                            EdgeInsets.all(16),

                        decoration:
                            BoxDecoration(

                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                                  18),

                          border: Border.all(
                            color:
                                Colors.grey.shade200,
                          ),

                          boxShadow: [

                            BoxShadow(
                              color:
                                  Colors.grey.shade100,
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: Offset(0,4),
                            )
                          ],
                        ),

                        child: Row(

                          children: [

                            CircleAvatar(

                              radius: 28,

                              backgroundColor:
                                  Color.fromRGBO(
                                      95,
                                      44,
                                      130,
                                      0.1
                                  ),

                              backgroundImage:
                                  member['profilePhoto'] != null

                                      ? NetworkImage(
                                          member['profilePhoto']
                                      )

                                      : null,

                              child:
                                  member['profilePhoto'] == null

                                      ? Icon(
                                          Icons.person,
                                          color: Color(
                                              0xFF5F2C82
                                          ),
                                        )

                                      : null,
                            ),

                            SizedBox(width: 15),

                            Expanded(

                              child: Column(

                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  Row(

                                    children: [

                                      Expanded(

                                        child: Text(

                                          member['fullName'],

                                          style: TextStyle(

                                            fontWeight:
                                                FontWeight.bold,

                                            fontSize: 16,

                                            color:
                                                Colors.black87,
                                          ),
                                        ),
                                      ),

                                      if(isMe)

                                        Container(

                                          padding:
                                              EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),

                                          decoration:
                                              BoxDecoration(

                                            color:
                                                Color(
                                                    0xFF5F2C82),

                                            borderRadius:
                                                BorderRadius.circular(
                                                    12),
                                          ),

                                          child: Text(

                                            "Tú",

                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  SizedBox(height: 8),

                                  Container(

                                    padding:
                                        EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),

                                    decoration:
                                        BoxDecoration(

                                      color: isDriver
                                          ? Colors.green
                                          : Colors.red,

                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                    ),

                                    child: Text(

                                      member['role'],

                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}