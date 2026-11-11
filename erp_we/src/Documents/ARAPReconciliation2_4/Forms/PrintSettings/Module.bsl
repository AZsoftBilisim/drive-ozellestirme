
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseLoansDeposits = GetFunctionalOption("UseLoanAndDepositContracts");
	UseTheLease = False;
	UseTheLease = NonCurrentAssets.VNAManagementIsUsed();
	If UseLoansDeposits And Not UseTheLease Then
		Items.DetailingFinancialInstruments.Title = NStr("vi = 'cho vay, tiền gửi';
														|ru = 'по кредитам, депозитам';
														|en = 'on loans, deposits'; fa = 'on loans, deposits';
														|it = 'по кредитам, депозитам';
														|pl = 'wg pożyczek, lokat';
														|tr = 'krediler, mevduatlar'");
		
	ElsIf Not UseLoansDeposits And UseTheLease Then
		Items.DetailingFinancialInstruments.Title = NStr("vi = 'về thuê';
														|ru = 'по аренде';
														|en = 'on rental'; fa = 'on rental';
														|it = 'по аренде';
														|pl = 'z tytułu dzierżawy';
														|tr = 'kiralama altında'");
		
	ElsIf Not UseLoansDeposits And Not UseTheLease Then
		Items.DetailingFinancialInstruments.Visible = False;
		
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
								Documents.ARAPReconciliation2_4.UserSettingsObjectKey(),
								"PrintSettings");
		If PrintSettings = Undefined Then
			PrintSettings = DefaultPrintSettings();
		EndIf;
		
	EndIf;
	If Not PrintSettings.Property("MergeCustomersSuppliers") Then
		PrintSettings.Insert("MergeCustomersSuppliers", True);
	EndIf;
	
	FillPropertyValues(ThisObject, PrintSettings);
	If PrintSettings.MergeCustomersSuppliers Then
		DebtAsDebit = True;
	EndIf;
	Items.DebtAsDebit.Enabled = Not PrintSettings.MergeCustomersSuppliers;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormDetailsHandlers

&AtClient
Procedure DebtAsDebitOnChange(Item)

	If DebtAsDebit Then
		WithdrawInTheReglCurrency = False;
	EndIf;

EndProcedure

&AtClient
Procedure MergeCustomersSuppliersOnChange(Item)
	
	If MergeCustomersSuppliers Then
		DebtAsDebit = True;
		WithdrawInTheReglCurrency = False;
	EndIf;
	Items.DebtAsDebit.Enabled = Not MergeCustomersSuppliers;
	
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
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SaveSettingsAtServer(PrintSettings)

	Common.CommonSettingsStorageSave(
		Documents.ARAPReconciliation2_4.UserSettingsObjectKey(),
		"PrintSettings",
		PrintSettings);
	
EndProcedure

&AtServer
Function DefaultPrintSettings()
	
	Return Documents.ARAPReconciliation2_4.DefaultPrintSettings();
	
EndFunction

#EndRegion
