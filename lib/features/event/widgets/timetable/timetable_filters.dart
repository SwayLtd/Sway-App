/* import 'package:flutter/material.dart';

showModalBottomSheet(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setStateModal) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'FILTERS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Select Stages'),
                        const SizedBox(height: 10),
                        ReorderableListView(
                          shrinkWrap: true,
                          children: tempAllStages.map((stage) {
                            return ListTile(
                              key: ValueKey(stage),
                              leading: const Icon(Icons.menu),
                              title: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(stage),
                              ),
                              trailing: Checkbox(
                                value: tempSelectedStages.contains(stage),
                                onChanged: (bool? selected) {
                                  setStateModal(() {
                                    if (selected != null && selected) {
                                      tempSelectedStages.add(stage);
                                    } else {
                                      tempSelectedStages.remove(stage);
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                          onReorder: (int oldIndex, int newIndex) {
                            setStateModal(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final String stage =
                                  tempAllStages.removeAt(oldIndex);
                              tempAllStages.insert(newIndex, stage);
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Show Followed Artists Only'),
                            Switch(
                              value: tempShowFollowedArtistsOnly,
                              onChanged: (bool value) {
                                setStateModal(() {
                                  tempShowFollowedArtistsOnly = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Appliquez les filtres temporaires aux filtres actuels
                              setState(() {
                                selectedStages = List.from(tempSelectedStages);
                                showFollowedArtistsOnly =
                                    tempShowFollowedArtistsOnly;
                                allStages = List.from(tempAllStages);
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'APPLY',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );

*/
