
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Settings = Common.CommonSettingsStorageLoad(
		FormKey(),
		Undefined);
	If TypeOf(Settings) = Type("Structure") Then
		FillPropertyValues(ThisObject, Settings);
		If Not ReserveMaterials And ReplaceMaterialsWithAnalogs Then
			ReplaceMaterialsWithAnalogs = False;
		EndIf;
	EndIf;
	
	If Not ProductionManagementCached.TheProductionScheduleIsUsed() Then
		Items.CalculateTheSchedule.Visible = False;
		CalculateTheSchedule = False;
	EndIf;
	
	UseAlternativeMaterials = GetFunctionalOption("UseAlternativeMaterials");
	Items.ReplaceMaterialsWithAnalogs.Visible = UseAlternativeMaterials;
	Items.IndentDecoration4.Visible = UseAlternativeMaterials;
	Items.ReplacePFNaAnalogues.Visible = UseAlternativeMaterials;
	Items.IndentDecoration3.Visible = UseAlternativeMaterials;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReserveMaterialsOnChange(Item)
	
	If Not ReserveMaterials Then
		ReplaceMaterialsWithAnalogs = False;
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ReserveMaterials");
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure ReplaceMaterialsWithAnalogsOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure CalculateTheScheduleOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "CalculateTheSchedule");
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure PassStagesForExecutionOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure ReservePFOnChange(Item)
	
	If Not ReservePF Then
		ReplacePFNaAnalogues = False;
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ReservePF");
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure ReplacePFNaAnaloguesOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure Generate(Command)
	
	Close(StageGenerationSettings());
	
EndProcedure

&AtClient
Procedure ShowNeeds(Command)
	
	Filter = New Structure;
	If Parameters.References.Count() = 1 Then
		Filter.Insert("ReferenceOrder", Parameters.References[0]);
	Else
		Filter.Insert("ReferenceOrder", Parameters.References);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.DemandsForCreationOfProductionStages.Form", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveFormSettingsClient()
	
	Settings = New Structure;
	Settings.Insert("ReserveMaterials",               ReserveMaterials);
	Settings.Insert("ReservePF",                      ReservePF);
	Settings.Insert("ReplaceMaterialsWithAnalogs",           ReplaceMaterialsWithAnalogs);
	Settings.Insert("ReplacePFNaAnalogues",                  ReplacePFNaAnalogues);
	Settings.Insert("CalculateTheSchedule",                     CalculateTheSchedule);
	Settings.Insert("PassStagesForExecution",             PassStagesForExecution);
	
	SaveFormSettingsServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettingsServer(Settings)
	
	Common.CommonSettingsStorageSave(FormKey(), Undefined, Settings);
	
EndProcedure

&AtClientAtServerNoContext
Function FormKey()
	
	Return "Document.ProductionStage2_2.Form.DocumentGenerationParameters";
	
EndFunction

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Form.UseAlternativeMaterials Then
		
		If AttributesStructure1.Property("ReserveMaterials")
			Or Initialize Then
		
			Items.ReplaceMaterialsWithAnalogs.Enabled = Form.ReserveMaterials;
		
		EndIf;
		
		If AttributesStructure1.Property("ReservePF")
			Or Initialize Then
		
			Items.ReplacePFNaAnalogues.Enabled = Form.ReservePF;
		
		EndIf;
	
	EndIf;
	
EndProcedure

&AtServer
Function StageGenerationSettings()
	
	ExcludeProperties = ?(UseAlternativeMaterials, "", "ReplaceMaterialsWithAnalogs, ReplacePFNaAnalogues");
	
	Result = Documents.ProductionStage2_2.StageGenerationSettings();
	FillPropertyValues(Result, ThisObject,, ExcludeProperties);
	Result.References = Parameters.References;
	
	Return Result;
	
EndFunction

#EndRegion
