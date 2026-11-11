#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.AccountingInFunctionalCurrency.ChoiceList.Clear();
	
	ValuePresentation = StrTemplate(
		NStr("vi = 'theo tiền tệ kế toán pháp quy của doanh nghiệp';
			|ru = 'в валюте регламентированного учета организаций';
			|en = 'in local accounting currency of companies'; fa = 'in local accounting currency of companies';
			|it = 'nella valuta della contabilità regolatoria dell''azienda';
			|pl = 'w walucie ewidencji reglamentowanej firmy';
			|tr = 'yerel muhasebe para birimi cinsinden'"));
	Items.AccountingInFunctionalCurrency.ChoiceList.Add(
		Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal, ValuePresentation);
	
	If Catalogs.FinancialAccountingChartsOfAccounts.AccountingInManCurrencyIsAvailable() Then
		ValuePresentation = StrTemplate(
			NStr("vi = 'theo tiền tệ kế toán quản trị';
				|ru = 'в валюте управленческого учета';
				|en = 'in management accounting currency'; fa = 'in management accounting currency';
				|it = 'nella valuta della contabilità gestionale';
				|pl = 'w walucie ewidencji administracyjnej';
				|tr = 'yönetim muhasebesinin para birimi cinsinden'"));
		Items.AccountingInFunctionalCurrency.ChoiceList.Add(
			Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_, ValuePresentation);
	EndIf;
	
	InternationalChartOfAccounts_ = Catalogs.FinancialAccountingChartsOfAccounts.International.GetObject(); 
		
	FillPropertyValues(ThisForm, InternationalChartOfAccounts_);
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject,,,
		InternationalChartOfAccounts_);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Not Exit Then
		Cancel = True;
		ResponseHandler1 = New CallbackDescription("FormClosingCompletion", ThisObject);
		ShowQueryBox(ResponseHandler1, NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
											|ru = 'Данные были изменены. Сохранить изменения?';
											|en = 'The data was changed. Do you want to save the changes?'; fa = 'The data was changed. Do you want to save the changes?';
											|it = 'I dati sono stati modificati. Salvare le modifiche?';
											|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
											|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"), QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure FormClosingCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		If SaveData() Then
			Modified = False;
			Notify("Write_FinancialAccountingChartsOfAccounts");
			Close();
		EndIf;
	ElsIf Result = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteClose(Command)
	
	If SaveData() Then
		Modified = False;
		Notify("Write_FinancialAccountingChartsOfAccounts");
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	OpenForm("Catalog.FinancialAccountingChartsOfAccounts.Form.AttributeUnlocking",,,,,,
		New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
	EndIf;
	
EndProcedure

// End StandardSubsystems.ObjectAttributesLock

#EndRegion

#Region Private

&AtServer
Function SaveData()
	
	If Not CheckFilling() Then
		Return False;
	EndIf;

	ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.International.GetObject();
	FillPropertyValues(ChartOfAccounts, ThisForm, , "ThisObject");
	ChartOfAccounts.Write();
	
	Return True;
	
EndFunction

#EndRegion
