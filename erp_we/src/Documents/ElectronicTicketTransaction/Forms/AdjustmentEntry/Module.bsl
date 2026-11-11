
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("AttributesValues") Then
		FillPropertyValues(ThisObject, Parameters.AttributesValues);
	EndIf;
	
	Parameters.Property("AttributesOfAdjustingEntries", AttributesOfAdjustingEntries);
	
	FormItemsManagement();
	
	If ValueIsFilled(Date) Then
		
		DataToCheck = PeriodClosingDates.DataToCheckTemplate();
		NewRow = DataToCheck.Add();
		NewRow.Date   = Date;
		NewRow.Object = Organization;
		NewRow.Section = "FinancialOutline";
		
		If PeriodClosingDates.PeriodEndClosingFound(DataToCheck) Then
			ReadOnly = True;
		EndIf;
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ParametersForSelectingArticlesAndAnalyticsInInputForm(OperationType);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ElectronicTicketTransaction.AccountSettingsInAdjustmentEntryForm(OperationType);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If PenaltyAmount = 0 Then
		AttributesNotToCheck.Add("ExpenseItem");
		AttributesNotToCheck.Add("DimensionOfExpenses");
		AttributesNotToCheck.Add("AssetsLiabilitiesDimension");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ParametersForSelectingArticlesAndAnalyticsInInputForm(OperationType);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PenaltyAmountOnChange(Item)
	
	FormItemsManagement();
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemStartListChoice(Item, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure AssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If CheckFilling() Then
		Result = New Structure(AttributesOfAdjustingEntries);
		FillPropertyValues(Result, ThisObject);
		RecordFormSInvoiceSettings();
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
&AtServer
Procedure RecordFormSInvoiceSettings()
	GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
EndProcedure
&AtServer
Procedure FormItemsManagement()
	
	Title                   = NStr("vi = 'Nhập tiền phạt';
									|ru = 'Ввод штрафа';
									|en = 'Enter fine'; fa = 'Enter fine';
									|it = 'Ввод штрафа';
									|pl = 'Enter fine';
									|tr = 'Ceza girişi'");
	ExpenseAnalystAvailability = (PenaltyAmount <> 0);
	Items.ExpenseItem.AutoMarkIncomplete = ExpenseAnalystAvailability;
	Items.DimensionOfExpenses.Enabled            = ExpenseAnalystAvailability;
	Items.AssetsLiabilitiesDimension.Enabled     = ExpenseAnalystAvailability;
	
EndProcedure

#EndRegion
