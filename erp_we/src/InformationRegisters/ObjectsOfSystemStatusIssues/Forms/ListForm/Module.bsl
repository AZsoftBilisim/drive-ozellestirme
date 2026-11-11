
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Filter.Property("Object") And ValueIsFilled(Parameters.Filter.Object) Then
		
		Items.Object.Visible = False;
		AutoTitle = False;
		Title = NStr("vi = 'Các vấn đề được xác định trong đối tượng';
					|ru = 'Проблемы, выявленные в объекте';
					|en = 'Issues detected in the object'; fa = 'Issues detected in the object';
					|it = 'Problemi, rilevati nell''oggetto';
					|pl = 'Problemy, zidentyfikowane w obiekcie';
					|tr = 'Nesnede tespit edilen sorunlar'");
		
	EndIf;	
		
EndProcedure

#EndRegion
