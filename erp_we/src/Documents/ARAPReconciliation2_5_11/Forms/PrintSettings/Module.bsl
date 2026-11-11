
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Print") Then
		Items.Save.Title = NStr("vi = 'In';
								|ru = 'Печать';
								|en = 'Print'; fa = 'چاپ';
								|it = 'Печать';
								|pl = 'Print';
								|tr = 'Yazdır'");
	EndIf;
	
	If Parameters.Property("PrintSettings") Then
		PrintSettings = Parameters.PrintSettings;
		
	Else
		PrintSettings = Common.CommonSettingsStorageLoad(
								Documents.ARAPReconciliation2_5_11.UserSettingsObjectKey(),
								"PrintSettings");
		If PrintSettings = Undefined Then
			PrintSettings = DefaultPrintSettings();
		EndIf;
		
	EndIf;
	If Not PrintSettings.Property("MergeCustomersSuppliers") Then
		PrintSettings.Insert("MergeCustomersSuppliers", True);
	EndIf;
	
	If Parameters.Property("PrintObjects") Then
		Query = New Query;
		Query.Text = 
		"SELECT TOP 1
		|	ARAPReconciliation.ModeOfARAPTotalsReconciliation AS TotalReconciliationMode
		|FROM
		|	Document.ARAPReconciliation2_5_11 AS ARAPReconciliation
		|WHERE
		|	ARAPReconciliation.Ref IN(&ReconciliationDocuments)
		|;
		|
		|SELECT TOP 1
		|	SummaryRecords.Contract AS Contract
		|FROM
		|	Document.ARAPReconciliation2_5_11.SummaryRecords AS SummaryRecords
		|WHERE
		|	SummaryRecords.Ref IN(&ReconciliationDocuments)
		|	AND VALUETYPE(SummaryRecords.Contract) IN (
		|		TYPE(Catalog.LeaseContract),
		|		TYPE(Catalog.LoanAndDepositContracts))";
		Query.SetParameter("ReconciliationDocuments", Parameters.PrintObjects);
		QueryResult = Query.ExecuteBatch();
		LastIndex = QueryResult.UBound();
		ReconciliationDocuments = QueryResult[LastIndex-1].Select();
		ReconciliationDocuments.Next();
		ContractReconciliationMode = ReconciliationDocuments.TotalReconciliationMode = Enums.ModeOfARAPTotalsReconciliation.ByContracts;
		ThereAreContractsForLoansDepositsLoansLeases = QueryResult[LastIndex].Select().Next();
		
		Items.DebitAsDebt.ReadOnly = ThereAreContractsForLoansDepositsLoansLeases;
		If ContractReconciliationMode Then
			ChoiceList = Items.MutualSettlementsDetails.ChoiceList;
			ChoiceList.Delete(ChoiceList.Count()-1);
		EndIf;
	ElsIf Parameters.Property("ReconciliationSettings") Then
		Items.DebitAsDebt.ReadOnly = Parameters.ReconciliationSettings.ThereAreContractsForLoansDepositsLoansLeases;
		ContractReconciliationMode = Parameters.ReconciliationSettings.TotalReconciliationMode = Enums.ModeOfARAPTotalsReconciliation.ByContracts;
		If ContractReconciliationMode Then
			ChoiceList = Items.MutualSettlementsDetails.ChoiceList;
			ChoiceList.Delete(ChoiceList.Count()-1);
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, PrintSettings);
	If PrintSettings.MergeCustomersSuppliers Then
		DebitAsDebt = False;
	EndIf;
	Items.DebitAsDebt.Enabled = Not PrintSettings.MergeCustomersSuppliers;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	If ContractReconciliationMode And MutualSettlementsDetails = 2 Then
		MutualSettlementsDetails = 1;
	EndIf;
	
EndProcedure
#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MergeCustomersSuppliersOnChange(Item)
	
	If MergeCustomersSuppliers Then
		DebitAsDebt = False;
	EndIf;
	Items.DebitAsDebt.Enabled = Not MergeCustomersSuppliers;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)

	PrintSettings = DefaultPrintSettings();
	FillPropertyValues(PrintSettings, ThisObject);
	SaveSettingsAtServer(PrintSettings); 
	Close(PrintSettings);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SaveSettingsAtServer(PrintSettings)

	Common.CommonSettingsStorageSave(
		Documents.ARAPReconciliation2_5_11.UserSettingsObjectKey(),
		"PrintSettings",
		PrintSettings);
	
EndProcedure

&AtServer
Function DefaultPrintSettings()
	
	Return Documents.ARAPReconciliation2_5_11.DefaultPrintSettings();
	
EndFunction

#EndRegion
