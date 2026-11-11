
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AllowEditingOptionsForGeneratingTransactions = True;
	AllowEditingOfTheViewCurrency = True;
	AllowEditingAccountingInTheFunctionalCurrency = True;
	
	MethodOfAccountingForImproperValuesIsAvailable = FinancialAccountingOfGeneralPurpose.SettingUpTransactionsForAccountingObjectsOrLocalAccounting();
	
	If MethodOfAccountingForImproperValuesIsAvailable Then
		AllowEditingAccountingForInappropriateControlledValues = True;
		Items.AllowEditingAccountingForInappropriateControlledValues.Enabled = True;
	Else
		Items.AllowEditingAccountingForInappropriateControlledValues.Enabled = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	If AllowEditingOptionsForGeneratingTransactions Then
		Result.Add("OptionForGeneratingTransactions");
	EndIf;
	If AllowEditingAccountingForInappropriateControlledValues Then
		Result.Add("MethodOfNotOwnedControlledValuesAccounting");
	EndIf;
	If AllowEditingOfTheViewCurrency Then
		Result.Add("PresentationCurrency");
	EndIf;
	If AllowEditingAccountingInTheFunctionalCurrency Then
		Result.Add("AccountingInFunctionalCurrency");
	EndIf;

	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
