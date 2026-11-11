
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Cấm tạo trực tác.';
				|ru = 'Интерактивное создание запрещено.';
				|en = 'Interactive creation is not allowed.'; fa = 'Interactive creation is not allowed.';
				|it = 'La creazione interattiva è vietata.';
				|pl = 'Tworzenie interaktywne jest zabronione.';
				|tr = 'İnteraktif oluşturma yasaktır.'"));
		Cancel = True;
		Return;
	EndIf;

	InitialStartFlag = Object.Started;
	ReadOnly = Object.Completed;
	Items.StateGroup.Visible = Object.Completed;
	If Object.Completed Then
		UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
		EndDateAsString = ?(UseDateAndTimeInTaskDeadlines, 
			Format(Object.CompletedOn, "DLF=DT"), Format(Object.CompletedOn, "DLF=D"));
		StateText = StrTemplate(NStr("vi = 'Vụ việc - %1 %2';
									|ru = 'Сделка - %1 %2';
									|en = 'Sales opportunity - %1 %2'; fa = 'Sales opportunity - %1 %2';
									|it = 'Сделка - %1 %2';
									|pl = 'Sales opportunity - %1 %2';
									|tr = 'Satış fırsatı; %1 %2'"),
		                           Common.ObjectAttributeValue(Object.SubjectOf, "Status"), 
		                           EndDateAsString);
		Items.TextDecoration.Title = StateText;
	EndIf;

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion
