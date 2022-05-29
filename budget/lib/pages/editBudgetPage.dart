import 'dart:developer';

import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/pageFramework.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

class EditBudgetPage extends StatefulWidget {
  EditBudgetPage({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  _EditBudgetPageState createState() => _EditBudgetPageState();
}

class _EditBudgetPageState extends State<EditBudgetPage> {
  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: widget.title,
      navbar: false,
      floatingActionButton: AnimatedScaleDelayed(
        child: FAB(
          tooltip: "Add Budget",
          openPage: AddBudgetPage(
            title: "Add Budget",
          ),
        ),
      ),
      slivers: [
        StreamBuilder<List<Budget>>(
          stream: database.watchAllBudgets(),
          builder: (context, snapshot) {
            if (snapshot.hasData && (snapshot.data ?? []).length > 0) {
              return SliverReorderableList(
                itemBuilder: (context, index) {
                  return BudgetRowEntry(
                    budget: snapshot.data![index],
                    index: index,
                    key: ValueKey(index),
                  );
                },
                itemCount: snapshot.data!.length,
                onReorder: (_intPrevious, _intNew) async {
                  Budget oldBudget = snapshot.data![_intPrevious];

                  print(oldBudget.name);
                  print(oldBudget.order);

                  if (_intNew > _intPrevious) {
                    await database.moveBudget(
                        oldBudget.budgetPk, _intNew - 1, oldBudget.order);
                  } else {
                    await database.moveBudget(
                        oldBudget.budgetPk, _intNew, oldBudget.order);
                  }
                },
              );
            }
            return SliverToBoxAdapter(
              child: Container(),
            );
          },
        ),
      ],
    );
  }
}

class BudgetRowEntry extends StatelessWidget {
  const BudgetRowEntry({required this.index, required this.budget, Key? key})
      : super(key: key);
  final int index;
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    DateTimeRange budgetRange = getBudgetDate(budget, DateTime.now());
    Color backgroundColor = dynamicPastel(context,
        HexColor(budget.colour, Theme.of(context).colorScheme.lightDarkAccent),
        amountLight: 0.55, amountDark: 0.35);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: backgroundColor,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  left: 25,
                  right: 10,
                  top: 15,
                  bottom: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text: budget.name + " - " + budget.order.toString(),
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                    Container(height: 2),
                    Row(
                      children: [
                        TextFont(
                          text: convertToMoney(budget.amount),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        TextFont(
                          text: " / ",
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        budget.reoccurrence!.index != 0
                            ? TextFont(
                                text: budget.periodLength.toString() + " ",
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )
                            : SizedBox(),
                        TextFont(
                          text: budget.periodLength == 1
                              ? nameRecurrence[budget.reoccurrence!.index]
                              : namesRecurrence[budget.reoccurrence!.index],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ],
                    ),
                    TextFont(
                      text: getWordedDateShort(budgetRange.start) +
                          " - " +
                          getWordedDateShort(budgetRange.end),
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ),
            Tappable(
              color: backgroundColor,
              borderRadius: 0,
              child: Container(
                  height: double.infinity,
                  width: 40,
                  child: Icon(Icons.delete_rounded)),
              onTap: () {
                openPopup(context,
                    description: "Delete " + budget.name + "?",
                    icon: Icons.delete_rounded,
                    onCancel: () {
                      Navigator.pop(context);
                    },
                    onCancelLabel: "Cancel",
                    onSubmit: () {
                      database.deleteBudget(budget.budgetPk);
                      Navigator.pop(context);
                      openSnackbar(context, "Deleted " + budget.name);
                    },
                    onSubmitLabel: "Delete");
              },
            ),
            OpenContainerNavigation(
              closedColor: backgroundColor,
              borderRadius: 0,
              button: (openContainer) {
                return Tappable(
                  color: backgroundColor,
                  borderRadius: 0,
                  child: Container(
                      width: 40,
                      height: double.infinity,
                      child: Icon(Icons.edit_rounded)),
                  onTap: () {
                    openContainer();
                  },
                );
              },
              openPage: AddBudgetPage(
                title: "Edit " + budget.name + " Budget",
                budget: budget,
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Tappable(
                color: Colors.transparent,
                borderRadius: 0,
                child: Container(
                    margin: EdgeInsets.only(right: 10),
                    width: 40,
                    height: double.infinity,
                    child: Icon(Icons.drag_handle_rounded)),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
