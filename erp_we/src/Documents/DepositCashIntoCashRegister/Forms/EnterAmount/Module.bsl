
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	CashRegister = Parameters.CashRegister;
	
	CashRegisterData = Common.ObjectAttributesValues(CashRegister, "Owner, CashCurrency");
	Organization = CashRegisterData.Owner;
	Currency      = CashRegisterData.CashCurrency;
	
	AmountToBeReceived = Catalogs.CashRegisters.AmountToBeReceived(CashRegister);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReceiveToCashRegister(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(DepositAmount) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Số tiền ký gửi không được nhập';
				|ru = 'Не введена сумма внесения';
				|en = 'Enter deposit amount'; fa = 'Enter deposit amount';
				|it = 'L''importo di versamento non è immesso';
				|pl = 'Nie wprowadzono wartości wpłaconej';
				|tr = 'Depozito tutarı girilmemiş'"),,,
			"DepositAmount");
		Return;
	EndIf;
	
	If AmountToBeReceived < DepositAmount Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Số tiền nhập vượt quá số tiền có thể tiếp nhận.';
				|ru = 'Сумма внесения денежных средств превышает возможную сумму поступления.';
				|en = 'Cash amount exceeds the possible amount to deposit.'; fa = 'Cash amount exceeds the possible amount to deposit.';
				|it = 'L''importo del versamento supera l''eventuale ammontare d''introito.';
				|pl = 'Wartość wprowadzenia środków pieniężnych przekracza możliwą wartość wpaty.';
				|tr = 'Nakit depozito tutarı olası makbuz tutarını aşmaktadır.'"),,,
			"DepositAmount");
		Return;
	EndIf;
	
	AcceptToCashierOnClient();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure AcceptToCashierOnClient()
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("DepositAmount",          DepositAmount);
	ReturnStructure.Insert("CashRegister",               CashRegister);
	ReturnStructure.Insert("Organization",            Organization);
	ReturnStructure.Insert("Currency",                 Currency);
	ReturnStructure.Insert("CashAccount",                  Undefined);
	ReturnStructure.Insert("CashAccountReceiptNote", Undefined);
	
	Close(ReturnStructure);
	
EndProcedure

#EndRegion

#EndRegion
