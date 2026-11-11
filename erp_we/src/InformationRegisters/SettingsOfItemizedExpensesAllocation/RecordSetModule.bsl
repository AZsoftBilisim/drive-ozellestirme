#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	For Each Record In ThisObject Do
		If Not ValueIsFilled(Record.Organization) And Not ValueIsFilled(Record.Department) Then
			ErrorText = NStr("vi = 'Trong tùy chỉnh, cần chỉ ra doanh nghiệp và bộ phận';
							|ru = 'В настройке должна быть указана организация или подразделение';
							|en = 'Specify a company or a business unit in the setting'; fa = 'Specify a company or a business unit in the setting';
							|it = 'В настройке должна быть указана организация или подразделение';
							|pl = 'Specify a company or a business unit in the setting';
							|tr = 'Ayarlarda iş yeri veya departman belirtilmelidir'");
			Common.MessageToUser(ErrorText,, "Organization", "Record", Cancel);
		EndIf;
	EndDo;

EndProcedure


#EndRegion

#EndIf