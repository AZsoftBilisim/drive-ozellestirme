&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	MessageText = NStr("ru = 'Непосредственное формирование отчета ""Настройка списка"" не предусмотрено.';
						|vi = 'Generation of the ""List setting"" report is not available.';
						|en = 'Generation of the ""List setting"" report is not available.'; fa = 'Generation of the ""List setting"" report is not available.';
						|it = 'Generation of the ""List setting"" report is not available.';
						|pl = 'Generation of the ""List setting"" report is not available.';
						|tr = '""Liste ayarı"" raporunun doğrudan oluşturulması öngörülmemiştir.'");
	Raise MessageText;
	
EndProcedure
