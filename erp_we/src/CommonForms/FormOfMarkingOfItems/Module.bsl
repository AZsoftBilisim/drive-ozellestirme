
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("ValueList", List);
	Parameters.Property("Address", Address);
	
	If IsTempStorageURL(Address) Then
		UsedSubsystems = GetFromTempStorage(Address);
		
		FormGroupOfCreateButtons();
	EndIf;
	
	If Parameters.Property("FormCaption") Then
		AutoTitle = False;
		Title = Parameters.FormCaption; 
	EndIf;
	
	If Parameters.Property("TitleOKButton") Then
		Items.FormOK.Title = Parameters.TitleOKButton;
	EndIf;
	
	If Parameters.Property("TitleCancelButton") Then
		Items.FormCancel.Title = Parameters.TitleCancelButton;
	EndIf;	
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure OK(Command)
	
	NotifyChoice(List);
	
EndProcedure

&AtClient
Procedure TypeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FormGroupOfCreateButtons()
	
	For Each TopLevelSubsystem In UsedSubsystems Do
		SubsystemName = TopLevelSubsystem.Value[0];
		TopLevel = Metadata.FindByFullName(SubsystemName);
		
		If Commands.Find(TopLevel.Name) = Undefined Then
			NewFormCommand = Commands.Add(TopLevel.Name);
			NewFormCommand.Title = TopLevel.Synonym;
			NewFormCommand.Action = "Attachable_Notice";
			
			CommandOnForm = Items.Insert("Form" + TopLevel.Name, Type("FormButton"), Items.FormGroupSelection,);
			CommandOnForm.CommandName = TopLevel.Name;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_Notice(Command) 
	
	MarkOnServer(Command.Name);
	
EndProcedure

&AtServer
Procedure MarkOnServer(NameOfCommand)
	
	SubordinateSubsystemsNames = UsedSubsystems[NameOfCommand];
	
	For Each CurRow In List Do
		
		For Each SubsystemName In SubordinateSubsystemsNames Do
			SubordinateSubsystem = Metadata.FindByFullName(SubsystemName);
			
			If SubordinateSubsystem.Content.Contains(Metadata.FindByType(CurRow.Value)) Then
				CurRow.Check = True;
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion
