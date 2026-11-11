
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If Not ValueIsFilled(Record.Author)
	 Or ValueIsFilled(Parameters.CopyingValue) Then
		Record.Author = Users.CurrentUser();
	EndIf;
	
	If Parameters.Property("Person") Then
		Record.Person1 = Parameters.Person;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Record.Person1 = Record.Person2 Then
		CommonClientServer.MessageToUser(
		NStr("vi = 'Cá nhân được chỉ ra trong liên kết không được trùng nhau.';
			|ru = 'Физические лица, указанные в связи не должны совпадать.';
			|en = 'Please specify different persons.'; fa = 'Please specify different persons.';
			|it = 'Le persone fisiche indicate nel collegamento non devono coincidere.';
			|pl = 'Osoby fizyczne, wymienieni w połączeniu nie powinny być takie same.';
			|tr = 'Bağlantıda listelenen gerçek kişiler eşleşmemelidir.'"),
		,
		"Person1",, Cancel);
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion
