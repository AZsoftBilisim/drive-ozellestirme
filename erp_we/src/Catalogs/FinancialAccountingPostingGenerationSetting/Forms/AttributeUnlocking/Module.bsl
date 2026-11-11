
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SettingUpFormationOfTransactionsIsUsed = 
		Catalogs.FinancialAccountingPostingGenerationSetting.SettingUpFormationOfTransactionsIsUsed(Parameters.PostingGenerationSetting);
	
	If SettingUpFormationOfTransactionsIsUsed Then
		Items.DescriptionNoEditingAllowed.Visible = True;
		AllowEditingOfAllocationOfLongTermAssetsLiabilities = False;
		AllowEditingRevenueTransactionSettingsWithoutVAT = False;
		AllowEditingClosingOfIncomeAndExpenseAccounts = False;
	Else
		Items.DescriptionNoEditingAllowed.Visible = False;
		AllowEditingOfAllocationOfLongTermAssetsLiabilities = True;
		AllowEditingRevenueTransactionSettingsWithoutVAT = True;
		AllowEditingClosingOfIncomeAndExpenseAccounts = True;
	EndIf;
	
	MethodOfCancelingTransactionsIsAvailable = 
		FinancialAccountingOfGeneralPurpose.SettingUpTransactionsForAccountingObjectsOrLocalAccounting();
	
	If MethodOfCancelingTransactionsIsAvailable Then
		Items.AllowEditingTransactionCancellationMethod.Enabled = True;
		AllowEditingTransactionCancellationMethod = Not SettingUpFormationOfTransactionsIsUsed;
	Else
		Items.AllowEditingTransactionCancellationMethod.Enabled = False;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	If AllowEditingTransactionCancellationMethod Then
		Result.Add("MethodOfCancelingTransactions");
	EndIf;
	If AllowEditingOfAllocationOfLongTermAssetsLiabilities Then
		Result.Add("DivisionIntoShortTermLongTermAssetsAndLiabilities");
	EndIf;
	If AllowEditingRevenueTransactionSettingsWithoutVAT Then
		Result.Add("RevenueTransactionsExcludingVAT");
	EndIf;
	If AllowEditingClosingOfIncomeAndExpenseAccounts Then
		Result.Add("ClosingOfIncomeAndExpenseAccounts");
	EndIf;

	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
