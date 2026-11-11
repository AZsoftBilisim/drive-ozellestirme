#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// receives the total amounts of the Cur payment schedule under the Contract of the loan, deposit, loan.
//
// Parameters:
//  Contract - CatalogRef.LoanAndDepositContracts, CatalogRef.OptionsOfLoansAndDepositsSchedules - Contract of a loan, deposit, loan; or a variant of the schedule of the Contract
//
// Returns:
//  Structure - The key is the name of the total, the value is the total amount of the graph.
//
Function GraphResults(Contract) Export
	
	GraphResults = New Structure("DateOfFirstTranche, LastPayment, TrancheAmount, PayAmount,
		|InterestAmount, FeeAmount, InterestAccruals, CommissionAccruals");
	
	ScheduleOption = Undefined;
	If TypeOf(Contract) = Type("CatalogRef.LoanAndDepositContracts") Then
		ScheduleOption = CurVersionOfGraph(Contract);
	ElsIf TypeOf(Contract) = Type("CatalogRef.OptionsOfLoansAndDepositsSchedules") Then
		ScheduleOption = Contract;
	EndIf;
		
	If Not ValueIsFilled(ScheduleOption) Then
		Return GraphResults;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	ScheduleData.Period AS DateOfFirstTranche
	|FROM
	|	InformationRegister.ScheduleOfTrancheForLoansAndDeposits AS ScheduleData
	|WHERE
	|	ScheduleData.ScheduleOption = &ScheduleOption
	|ORDER BY
	|	ScheduleData.Period
	|;
	|
	|SELECT TOP 1
	|	ScheduleData.AmountTotal AS TrancheAmount
	|FROM
	|	InformationRegister.ScheduleOfTrancheForLoansAndDeposits AS ScheduleData
	|WHERE
	|	ScheduleData.ScheduleOption = &ScheduleOption
	|ORDER BY
	|	ScheduleData.Period DESC
	|;
	|
	|SELECT TOP 1
	|	ScheduleData.Period AS LastPayment,
	|	ScheduleData.AmountTotal AS PayAmount,
	|	ScheduleData.InterestTotal AS InterestAmount,
	|	ScheduleData.FeeTotal AS FeeAmount
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS ScheduleData
	|WHERE
	|	ScheduleData.ScheduleOption = &ScheduleOption
	|ORDER BY
	|	ScheduleData.Period DESC
	|;
	|
	|SELECT TOP 1
	|	ScheduleData.InterestTotal AS InterestAccruals,
	|	ScheduleData.FeeTotal AS CommissionAccruals
	|FROM
	|	InformationRegister.ScheduleOfAccrualsForLoansAndDeposits AS ScheduleData
	|WHERE
	|	ScheduleData.ScheduleOption = &ScheduleOption
	|ORDER BY
	|	ScheduleData.Period DESC
	|";
	
	Query.SetParameter("ScheduleOption", ScheduleOption);
	
	Results = Query.ExecuteBatch();
	
	For Each Result In Results Do
		Selection = Result.Select();
		If Selection.Next() Then
			FillPropertyValues(GraphResults, Selection);
		EndIf;
	EndDo;
	
	Return GraphResults;
	
EndFunction

// updates the terms of the loan Contract, deposit, loan according to the payment schedule.
//
// Parameters:
//    Contract - CatalogObject.LoanAndDepositContracts - loan, Deposit, or loan agreement.
//    AttributeName - CatalogObject.LoanAndDepositContracts - loan, Deposit, or loan agreement.
//
Procedure RecalculateTerms(Contract, AttributeName = "LastPayment") Export
	
	If (AttributeName = "DateOfFirstTranche" Or AttributeName = "LastPayment")
		And ValueIsFilled(Contract.DateOfFirstTranche)
		And ValueIsFilled(Contract.LastPayment) Then
		
		Contract.TermMonths = TMCommonUse.DateDiff(
			Contract.DateOfFirstTranche, Contract.LastPayment, Enums.Periodicity.Month);
		Contract.TermDays = TMCommonUse.DateDiff(
			Contract.DateOfFirstTranche, Contract.LastPayment, Enums.Periodicity.Day);
		
	ElsIf AttributeName = "TermMonths" And ValueIsFilled(Contract.DateOfFirstTranche) Then
		
		Contract.LastPayment = AddMonth(Contract.DateOfFirstTranche, Contract.TermMonths);
		Contract.TermDays = TMCommonUse.DateDiff(
			Contract.DateOfFirstTranche, Contract.LastPayment, Enums.Periodicity.Day);
		
	ElsIf AttributeName = "TermDays"  And ValueIsFilled(Contract.DateOfFirstTranche) Then
		
		Contract.LastPayment = Contract.DateOfFirstTranche + Contract.TermDays * 60*60*24;
		Contract.TermMonths = TMCommonUse.DateDiff(
			Contract.DateOfFirstTranche, Contract.LastPayment, Enums.Periodicity.Month);
		
	ElsIf AttributeName = "TermMonths" And ValueIsFilled(Contract.LastPayment) Then
		
		Contract.DateOfFirstTranche = AddMonth(Contract.LastPayment, -Contract.TermMonths);
		Contract.TermDays = TMCommonUse.DateDiff(
			Contract.DateOfFirstTranche,Contract.LastPayment, Enums.Periodicity.Day);
		
	ElsIf AttributeName = "TermDays" And ValueIsFilled(Contract.LastPayment) Then
		
		Contract.DateOfFirstTranche = Contract.LastPayment - Contract.TermDays * 60*60*24;
		Contract.TermMonths = TMCommonUse.DateDiff(
			Contract.DateOfFirstTranche, Contract.LastPayment, Enums.Periodicity.Month);
		
	Else
		Contract.TermMonths = 0;
		Contract.TermDays = 0;
	EndIf;
	
EndProcedure

// for a loan Contract, a deposit, a loan receives a Cur payment schedule.
//
// Parameters:
//  Contract - CatalogObject.LoanAndDepositContracts - loan, Deposit, or loan agreement.
//
// Returns:
//  CatalogRef.OptionsOfLoansAndDepositsSchedules - The graph variant used
Function CurVersionOfGraph(Contract) Export
	
	Result = Undefined;
	
	If Not ValueIsFilled(Contract) Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	CatalogData.Ref
	|FROM
	|	Catalog.OptionsOfLoansAndDepositsSchedules AS CatalogData
	|WHERE
	|	CatalogData.Owner = &Contract
	|	AND NOT CatalogData.DeletionMark
	|	AND CatalogData.Used
	|";
	
	Query.SetParameter("Contract", Contract);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
	EndIf;
	
	Return Result;
	
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Reports.VarianceAnalysisOfFinancialInstruments.AddReportCommand(ReportsCommands, "PlanFactualAnalysisLoansDepositsContext");
	If GetFunctionalOption("TradeManagement") Then
		Reports.VarianceAnalysisOfFinancialInstrumentsTM.AddReportCommand(ReportsCommands, "PlanFactualAnalysisLoansDepositsContext");
	EndIf;
	
	ReportCommand = Reports.CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

