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
			|tr = 'iş yerinin yerel muhasebe para birimi cinsinden'"));
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
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_FinancialAccountingChartsOfAccounts", WriteParameters, Object.Ref);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command) 
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);	
EndProcedure

// End StandardSubsystems.ObjectAttributesLock

#EndRegion
