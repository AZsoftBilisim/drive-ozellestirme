#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.Title;
	For Each Item In Parameters.List Do
		List.Add(Item.Value, Item.Presentation, Item.Check, Item.Picture);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ReturnValue = New ValueList();
	
	ThereIsMark = False;
	For Each Item In List Do
		ThereIsMark = ThereIsMark Or Item.Check;
		ReturnValue.Add(Item.Value, Item.Presentation, Item.Check, Item.Picture);
	EndDo;
	
	If Not ThereIsMark Then
		ShowMessageBox(, NStr("vi = 'Cần đặt dấu ít nhất một phần tử';
								|ru = 'Необходимо установить пометку хотя бы у одного элемента';
								|en = 'At least one element must be checked'; fa = 'At least one element must be checked';
								|it = 'È necessario contrassegnare almeno un elemento';
								|pl = 'Należy ustawić zaznaczenie co najmniej dla jednego elementu';
								|tr = 'En az bir öğe için işaret ayarlanmalı'"));
	Else
		NotifyChoice(ReturnValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	For Each Item In List Do
		Item.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure RemoveAllMarks(Command)
	For Each Item In List Do
		Item.Check = False;
	EndDo;
EndProcedure

#EndRegion