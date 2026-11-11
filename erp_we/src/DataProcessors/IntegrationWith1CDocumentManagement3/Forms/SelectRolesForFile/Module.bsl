#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("FilesOwner", FilesOwner);
	
	For Each File In Parameters.ListOfFiles Do
		FillPropertyValues(ListOfFiles.Add(), File);
	EndDo;
	
	Parameters.Property("AvailableRoles", AvailableRoles);
	Parameters.Property("SelectedRole", SelectedRole);
	Parameters.Property("IdOfOwnerSForm", IdOfOwnerSForm);
	
	If ValueIsFilled(SelectedRole) Then
		RowIndex = Undefined;
		For Each Page1 In AvailableRoles Do
			If Page1.Value = SelectedRole Then
				RowIndex = Page1.GetID();
			EndIf;
		EndDo;
		
		If ValueIsFilled(RowIndex) Then
			Items.AvailableRoles.CurrentRow = RowIndex;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAvailableRoles

&AtClient
Procedure AvailableRolesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	DoneExecute();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	DoneExecute();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DoneExecute()
	
	SelectedRole = Items.AvailableRoles.CurrentData.Value;
	
	TotalFiles = ListOfFiles.Count();
	For Number = 1 To TotalFiles Do
		FileIndex = TotalFiles - Number;
		If ListOfFiles[FileIndex].FileRoleID = SelectedRole Then
			ListOfFiles.Delete(FileIndex);
		EndIf;
	EndDo;
	
	If ListOfFiles.Count() > 0 Then
		IntegrationWith1CDocumentManagement3Client.ReplaceRoleOfFiles(
			ListOfFiles,
			SelectedRole,
			FilesOwner,
			IdOfOwnerSForm);
	EndIf;
	
	Close();
	
EndProcedure

#EndRegion