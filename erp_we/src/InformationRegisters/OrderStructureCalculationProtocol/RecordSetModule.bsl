
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RegistrationPeriod= CurrentUniversalDate();
	RegistrationDay = Int((RegistrationPeriod - '20000101000000') / 86400);
	
	For Each Record In ThisObject Do
		
		HasErrors = ThereAreErrorsFillingInProtocolRecord(Record, Cancel);
		
		If HasErrors Then
			Continue;
		EndIf;
		
		Record.RegistrationPeriod = RegistrationPeriod;
		Record.RegistrationDay = RegistrationDay;

	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ThereAreErrorsFillingInProtocolRecord(Record, Cancel)
	
	HasErrors = False;
	
	If Not ValueIsFilled(Record.ProductionOrder)
		And Not Record.ErrorType = Enums.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError Then
		HasErrors = True;
		ErrorText = NStr("vi = 'Trường ""Đơn hàng sản xuất"" bắt buộc điền.';
						|ru = 'Поле ""Заказ на производство"" обязательно к заполнению.';
						|en = 'Fill the ""Production order"" field.'; fa = 'Fill the ""Production order"" field.';
						|it = 'Il campo ""Ordine di produzione"" deve essere compilato.';
						|pl = 'Pole ""Zlecenie produkcyjne"" jest wymagane do wypełnienia.';
						|tr = '""Üretim Emri"" alanının doldurulması zorunludur.'");
		Common.MessageToUser(ErrorText,,,,Cancel)
	EndIf;
	
	Return HasErrors;
	
EndFunction

#EndRegion

#EndIf