
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ReadOnly = True;	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CommonClient.MessageToUser(NStr("vi = 'Đây là biểu ghi hệ thống, nên bị cấm truy cập.';
									|ru = 'Данный регистр является служебным, поэтому доступ к его данным запрещен.';
									|en = 'This is a service register, the access to its data is prohibited.'; fa = 'This is a service register, the access to its data is prohibited.';
									|it = 'Questo è un registro di servizio, pertanto l''accesso ai suoi dati è proibito.';
									|pl = 'Ten rejestr jest serwisowym, dlatego dostęp do jego danych jest zabroniony.';
									|tr = 'Bu kayıt özeldir, bu nedenle verilerine erişim yasaktır.'"));
EndProcedure

#EndRegion
