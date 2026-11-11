#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.ThisNode Then
		AutoTitle = False;
		Title = NStr("vi = 'Nút này';
					|ru = 'Этот узел';
					|en = 'This node.'; fa = 'This node.';
					|it = 'Этот узел';
					|pl = 'This node.';
					|tr = 'Bu bir alt varlıktır'");
		Items.Description.Title = NStr("vi = 'Tên định danh';
										|ru = 'Идентификатор';
										|en = 'ID'; fa = 'شناسه';
										|it = 'Идентификатор';
										|pl = 'ID';
										|tr = 'Kimlik'");
		Items.ChangeId.Visible = True;
		
		If Not StringFunctionsClientServer.IsUUID(Object.Description) Then
			Object.Description = String(New UUID);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeId(Command)
	
	Object.Description = String(New UUID);
	Modified = True;
	
EndProcedure

#EndRegion