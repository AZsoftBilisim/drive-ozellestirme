#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf; 
	
	If Not ValueIsFilled(DemandForMaterials) Then
		DemandForMaterials = PredefinedValue("Enum.MaterialCalculationMethods.PossibleConsumption");
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If (CreatePurchasePlanByAmount Or CreateSalesPlanByAmount) 
		And Not GetFunctionalOption("UseMultipleCurrencies")
		And Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
		If Not ValueIsFilled(Currency) Then
			Raise NStr("vi = 'Không thể điền trường ""Tiền tệ"". Hãy thiết lập tiền tệ của kế toán quản trị!';
						|ru = 'Не удалось заполнить поле ""Валюта"". Установите валюту управленческого учета!';
						|en = 'Failed to fill in field ""Currency"". Set management accounting currency.'; fa = 'Failed to fill in field ""Currency"". Set management accounting currency.';
						|it = 'Non è stato possibile compilare il campo ""Valuta"". Impostare la valuta della contabilità gestionale!';
						|pl = 'Wypełnianie pola ""Валюта"" nie powiodło się. Ustaw walutę ewidencji zarządczej!';
						|tr = '""Para birimi"" alanı doldurulamadı. Yönetim muhasebesi para birimini ayarlayın!'");
		EndIf;
	EndIf;
	
	If Periodicity = Enums.Periodicity.Year
		Or Periodicity = Enums.Periodicity.TenDays Then
	
		ShowNumberOfPeriod = False;
	EndIf;
	If Not RecordedInBudgeting Then
		BudgetingScenario = Undefined;
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(DemandForMaterials) Then
		DemandForMaterials = PredefinedValue("Enum.MaterialCalculationMethods.PossibleConsumption");
	EndIf;
	
	If Not (CreatePurchasePlanByAmount Or CreateSalesPlanByAmount) Then
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	If Not UseForMaterialsPlanning Then
		NotCheckedAttributeArray.Add("DemandForMaterials");
	EndIf;
	
	If GetFunctionalOption("TradeManagement") Then
		NotCheckedAttributeArray.Add("RecordedInBudgeting");
		NotCheckedAttributeArray.Add("BudgetingScenario");
	EndIf;
	If Not RecordedInBudgeting Then
		NotCheckedAttributeArray.Add("BudgetingScenario");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If (CreatePurchasePlanByAmount Or CreateSalesPlanByAmount)  
		And Not GetFunctionalOption("UseMultipleCurrencies")
		And Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
		If Not ValueIsFilled(Currency) Then
			Raise NStr("vi = 'Không thể điền trường ""Tiền tệ"". Hãy thiết lập tiền tệ của kế toán quản trị!';
						|ru = 'Не удалось заполнить поле ""Валюта"". Установите валюту управленческого учета!';
						|en = 'Failed to fill in field ""Currency"". Set management accounting currency.'; fa = 'Failed to fill in field ""Currency"". Set management accounting currency.';
						|it = 'Non è stato possibile compilare il campo ""Valuta"". Impostare la valuta della contabilità gestionale!';
						|pl = 'Wypełnianie pola ""Валюта"" nie powiodło się. Ustaw walutę ewidencji zarządczej!';
						|tr = '""Para birimi"" alanı doldurulamadı. Yönetim muhasebesi para birimini ayarlayın!'");
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
