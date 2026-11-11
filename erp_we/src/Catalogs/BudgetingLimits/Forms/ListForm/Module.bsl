
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	FilterRules_ = Undefined;
	FilterByOwner = Undefined;
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	OwnerDefined = False;
	If Parameters.Property("Filter", FilterRules_) Then
		If FilterRules_.Property("Owner", FilterByOwner) Then
			If ValueIsFilled(FilterByOwner) Then
				OwnerDefined = True;
			EndIf;
		EndIf;
	EndIf;
	
	If Not OwnerDefined Then
		Raise NStr("vi = 'Bạn chỉ có thể xem danh sách các giới hạn dưới dạng mô hình ngân sách.';
					|ru = 'Просмотреть список лимитов можно только в форме модели бюджетирования';
					|en = 'You can view a limit list only in the budgeting model form'; fa = 'You can view a limit list only in the budgeting model form';
					|it = 'Visualizzare elenco dei limiti è possibile solo sotto forma di un modello di budgeting';
					|pl = 'Przejrzeć listę limitów można tylko w formularzu modelu budżetowania';
					|tr = 'Limit listesi sadece bütçeleme modeli formunda gösterilebilir'");
	EndIf;
	
	// Visibility settings at startup
	ManagingElements();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddByBudget(Command)
	
	BudgetingModel = Undefined;
	For Each Filter In List.Filter.Items Do
		If String(Filter.LeftValue) = "Owner" Then
			BudgetingModel = Filter.RightValue;
		EndIf;
	EndDo;
	
	FormParameters = New Structure("Owner", BudgetingModel);
	
	CallbackDescription = New CallbackDescription("CreatingItemsByBudgetType", ThisForm);
	OpenForm("Catalog.BudgetingLimits.Form.SelectBudgetProfileItems", FormParameters,,,,,
																			CallbackDescription,
																			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CreatingItemsByBudgetType(SelectionResult, AddlParameters) Export
	
	If SelectionResult = True Then
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpendingLimits(Command)
	
	OpenForm(NameOfReportFormLimitsBasedOnBudgetingData(), New Structure("GenerateOnOpen", True));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()
	
	Items.FormAddByBudget.Visible = AccessRight("Insert", Metadata.Catalogs.BudgetingLimits);
	
	LimitedTransactions = LimitsByBudgetingDataServer.UsedLimitedOFOperations();
	
	CommandExpenseLimits = Commands.Find("SpendingLimits");
	If LimitedTransactions.Count() = 1 And LimitedTransactions[0] = Enums.LimitedTransactions.FlowOfCash Then
		CommandExpenseLimits.Title = NStr("vi = 'Hạn mức chi tiền';
											|ru = 'Лимиты расхода ДС';
											|en = 'Cash flow limits'; fa = 'سقف‌های جریان وجوه نقد';
											|it = 'Limiti delle uscite monetarie';
											|pl = 'Limity wydatków środków pieniężnych';
											|tr = 'Nakit gider limitleri'");
	ElsIf LimitedTransactions.Count() = 1 And LimitedTransactions[0] = Enums.LimitedTransactions.Expenses Then
		CommandExpenseLimits.Title = NStr("vi = 'Hạn mức Ngân sách thu nhập và chi phí';
											|ru = 'Лимиты БДР';
											|en = 'IEB limits'; fa = 'IEB limits';
											|it = 'IEB limits';
											|pl = 'IEB limits';
											|tr = 'Gelir-Gider Bütçesi Limitleri'");
	Else
		CommandExpenseLimits.Title = NStr("vi = 'Hạn mức Ngân sách thu nhập, chi phí và chi tiền';
											|ru = 'Лимиты БДР и расхода ДС';
											|en = 'IEB and cash flow limits'; fa = 'IEB and cash flow limits';
											|it = 'IEB and cash flow limits';
											|pl = 'IEB and cash flow limits';
											|tr = 'Gelir-Gider Bütçesi ve Nakit Gider Limitleri'");
	EndIf;
	Items.GroupSwitchingToLimitControl2_5.Visible = GetFunctionalOption(
		"ControllingLimitsBasedOnBudgetingData2_4");
	
EndProcedure

&AtServerNoContext
Function NameOfReportFormLimitsBasedOnBudgetingData()
	
	If LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		FormName = "Report.LimitsByBudgetingData.Form";
	Else
		FormName = "Report.CashFlowLimitsForBudgetingData.Form";
	EndIf;
	
	Return FormName;
	
EndFunction

#EndRegion
