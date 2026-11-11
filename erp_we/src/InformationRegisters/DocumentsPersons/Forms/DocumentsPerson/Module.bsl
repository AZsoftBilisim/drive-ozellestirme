
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Filter.Property("Person") Then
		
		FromThePersonalDataEditingForm = Parameters.FromThePersonalDataEditingForm;
		
		If ReadOnly Then
			SetViewOnlyMode(ThisObject);
		EndIf;
		
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If FromThePersonalDataEditingForm And Not BlockObjectInOwnerForm() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	If FromThePersonalDataEditingForm And Not BlockObjectInOwnerForm() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	If FromThePersonalDataEditingForm And Not BlockObjectInOwnerForm() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ListBeforeLoadUserSettingsAtServer(Item, Settings)
	Return;
EndProcedure

&AtServer
Procedure ListOnUpdateUserSettingSetAtServer(StandardProcessing)
	Return;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	For Each String In Rows Do
		String.Value.Data["Presentation"] = InformationRegisters.DocumentsPersons.RecordPresentation(String.Value.Data);
	EndDo;

EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetViewOnlyMode(Form)
	
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"List",
		"ReadOnly",
		True);
	
EndProcedure

&AtClient
Function BlockObjectInOwnerForm()
	Return True;
	
EndFunction

#EndRegion

