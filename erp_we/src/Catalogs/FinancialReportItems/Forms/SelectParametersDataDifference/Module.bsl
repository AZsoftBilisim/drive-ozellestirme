

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ThereIsPeriod = Catalogs.FinancialReportItems.ElementExpandedByPeriod(Parameters);
	
	FillInPeriodSelectionLists(ThereIsPeriod);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If CheckFilling() Then
		Result = New Structure(
			"BeginOfPeriod, EndOfPeriod, Periodicity", 
			BeginOfPeriod, EndOfPeriod, Periodicity);
			
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInPeriodSelectionLists(ThereIsPeriod)
	
	PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
	
	Items.BeginOfPeriod.ChoiceList.Add(
		PeriodVariables.DataPeriodStart.Name,
		PeriodVariables.DataPeriodStart.Presentation);
	Items.EndOfPeriod.ChoiceList.Add(
		PeriodVariables.DataPeriodStart.Name,
		PeriodVariables.DataPeriodStart.Presentation);
	
	Items.BeginOfPeriod.ChoiceList.Add(
		PeriodVariables.DataPeriodEnd.Name,
		PeriodVariables.DataPeriodEnd.Presentation);
	Items.EndOfPeriod.ChoiceList.Add(
		PeriodVariables.DataPeriodEnd.Name,
		PeriodVariables.DataPeriodEnd.Presentation);
	
	Items.BeginOfPeriod.ChoiceList.Add(
		PeriodVariables.ActualDataLimit.Name,
		PeriodVariables.ActualDataLimit.Presentation);
	Items.EndOfPeriod.ChoiceList.Add(
		PeriodVariables.ActualDataLimit.Name,
		PeriodVariables.ActualDataLimit.Presentation);
	
	If ThereIsPeriod Then
		
		Items.BeginOfPeriod.ChoiceList.Add(
			PeriodVariables.PeriodOfGrouping.Name,
			PeriodVariables.PeriodOfGrouping.Presentation);
		Items.EndOfPeriod.ChoiceList.Add(
			PeriodVariables.PeriodOfGrouping.Name,
			PeriodVariables.PeriodOfGrouping.Presentation);
		
	EndIf;
	
EndProcedure

#EndRegion