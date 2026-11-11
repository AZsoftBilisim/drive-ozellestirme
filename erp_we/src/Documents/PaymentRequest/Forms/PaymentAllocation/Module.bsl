
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ScheduleOfPayments,
		"PaymentObject",
		Parameters.DocumentBasis,
		DataCompositionComparisonType.InList,,
		True);
	
	If Parameters.PaymentMethod = "BankAccountPayment" Then
		TypeOfPaymentLocation = Type("CatalogRef.CashAccounts");
		Title = NStr("vi = 'Chọn tài khoản ngân hàng';
					|ru = 'Выберите банковский счет';
					|en = 'Select a bank account'; fa = 'Select a bank account';
					|it = 'Selezionare il conto bancario';
					|pl = 'Wybierz rachunek bankowy';
					|tr = 'Lütfen, banka hesabı seçin.'")
	ElsIf Parameters.PaymentMethod = "CashAccountPayment_" Then
		TypeOfPaymentLocation = Type("CatalogRef.CompaniesBankAccounts");
		Title = NStr("vi = 'Hãy chọn quầy thu ngân';
					|ru = 'Выберите кассу';
					|en = 'Select a cash account'; fa = 'Select a cash account';
					|it = 'Selezionare la cassa';
					|pl = 'Wybierz kasę';
					|tr = 'Lütfen, kasa seçin'")
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ScheduleOfPayments,
		"TypeOfPaymentLocation",
		TypeOfPaymentLocation,
		DataCompositionComparisonType.NotEqual,,
		True);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ScheduleOfPaymentsValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.ScheduleOfPayments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure("BankAccountCashAccount, Sum",
		CurrentData.BankAccountCashAccount, CurrentData.Sum);
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion