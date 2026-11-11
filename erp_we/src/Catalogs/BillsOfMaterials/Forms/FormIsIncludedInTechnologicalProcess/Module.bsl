
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.ConnectToStage.ReadOnly = Not Parameters.AttributeAvailability
		Or Not Parameters.CanBeConnectedToStage;
	
	Items.MaterialsAndServices.ReadOnly = Not Parameters.Property("MaterialsAndServices");
		
	Items.LaborCosts.ReadOnly = Not Parameters.Property("LaborCosts");
		
	If Parameters.CanBeConnectedToStage
		And Parameters.Property("StageName", StageName) Then
		Items.ConnectToStage.Title =
			Items.ConnectToStage.Title + StrTemplate(" ""%1""", StageName);
	EndIf;
	
	Renumber = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	If CheckFilling() Then
		
		Result = SettingsConstructor();
		FillPropertyValues(Result, ThisObject);
		Result.RelatedResources = MaterialsAndServices Or LaborCosts;
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	SetUncheckElements(True);
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	SetUncheckElements(False);
EndProcedure

#EndRegion

#Region Private

&AtClient
Function SettingsConstructor(OnlySwitches = False)
	
	Result = New Structure;
	
	Result.Insert("Renumber");
	Result.Insert("ConnectToStage");
	Result.Insert("MaterialsAndServices");
	Result.Insert("LaborCosts");
	
	If Not OnlySwitches Then
		Result.Insert("NameOfProcessTechnology");
		Result.Insert("RelatedResources");
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure SetUncheckElements(Mark)
	
	For Each KeyAndValue In SettingsConstructor(True) Do
		If Not Items[KeyAndValue.Key].ReadOnly Then
			ThisObject[KeyAndValue.Key] = Mark;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion