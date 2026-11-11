
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	BankAccountCashAccount = Parameters.BankAccountCashAccount;
	BankAccountCashAccountPresentation = String(BankAccountCashAccount);
	
	If Parameters.Sum < 0 Then
		Sum = -Parameters.Sum;
	Else
		Sum = Parameters.Sum;
	EndIf;
	
	FillPropertyValues(Object, Parameters.Object, "PlanFromDate, EndDate");
	
	Items.Sum.MaxValue = Sum;
	
	BankAccountsCashAccounts = DataProcessors.CashForecast.BankAccountsCashAccountsAvailableForPaymentObject(Parameters.RequestsToTransfer);
	If Not BankAccountsCashAccounts.Count() Then
		MessageText = NStr("vi = 'Không có cách nào để phân chia thanh toán đã chọn.';
							|ru = 'Нет возможности разбить выбранный платеж.';
							|en = 'Cannot split the selected payment.'; fa = 'Cannot split the selected payment.';
							|it = 'Non c''è possibilità di suddividere il pagamento';
							|pl = 'Nie ma możliwości rozbicia wybranej płatności.';
							|tr = 'Seçilen ödemenin bölünmesi mümkün değildir'");
		Common.MessageToUser(MessageText);
		Cancel = True;
	Else
		Items.BankAccountCashAccountPresentation.ChoiceList.LoadValues(BankAccountsCashAccounts);
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	AdditionalParameters = CallbackDescriptionOnClose.AdditionalParameters;
	AdditionalParameters.Insert("Sum", Sum);
	AdditionalParameters.Insert("Date", Date);
	AdditionalParameters.Insert("BankAccountCashAccount", BankAccountCashAccount);
	
EndProcedure

&AtClient
Procedure BankAccountCashAccountPresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	BankAccountCashAccount = ValueSelected;
	BankAccountCashAccountPresentation = String(ValueSelected);
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
