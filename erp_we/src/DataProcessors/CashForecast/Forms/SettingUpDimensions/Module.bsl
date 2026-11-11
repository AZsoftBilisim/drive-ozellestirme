#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReportDimensions = Parameters.ReportDimensions.Copy();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	
	ClearMessages();
	
	LevelCurrency = ReportDimensions.FindByValue("Currency");
	BankAccountCashAccountLevel = ReportDimensions.FindByValue("BankAccountCashAccount");
	
	If ReportDimensions.IndexOf(LevelCurrency) <> 0 Then
		MessageText = NStr("vi = 'Tiền tệ phải là loại tiền đầu tiên.';
							|ru = 'Валюта должна быть первой.';
							|en = 'The currency must be the first one.'; fa = 'The currency must be the first one.';
							|it = 'The currency must be the first one.';
							|pl = 'The currency must be the first one.';
							|tr = 'Para birimi ilk olmalıdır.'");
		CommonClient.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
	If ReportDimensions.IndexOf(BankAccountCashAccountLevel) <> ReportDimensions.Count() - 1 Then
		MessageText = NStr("vi = 'Tài khoản ngân hàng / Quỹ tiền mặt phải là mục cuối cùng.';
							|ru = 'Банковский счет / Касса должны быть последней.';
							|en = 'The bank / cash account must be the last one.'; fa = 'The bank / cash account must be the last one.';
							|it = 'The bank / cash account must be the last one.';
							|pl = 'The bank / cash account must be the last one.';
							|tr = 'Banka hesabı / Kasa hesabı sonda olmalıdır.'");
		CommonClient.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveChanges(Command)
	
	Close(ReportDimensions);
	
EndProcedure

#EndRegion