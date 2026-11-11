#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.ControlItemsPlacementParameters = DetermineLocationOfControls();

	Settings.Events.OnCreateAtServer             = True;
	Settings.Events.BeforeLoadVariantAtServer  = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm             - ClientApplicationForm - report form.
//   Cancel                - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandParameter;
		ThisForm.ParametersForm.Filter.Insert("Ref", Parameters.CommandParameter);
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
// Parameters:
//   ThisForm         - ClientApplicationForm - report form or report settings.
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	DataParameters = MainCircuitSettings.DataParameters.Items;
	
	DetailByPeriodParameter = DataParameters.Find("ShowDetailsOnPeriod"); 	
	ShowAssignmentParameter    = DataParameters.Find("ShowAssignment");
	
	GroupsToAdd     = New Array;
	FieldsToDelete__         = New Array;
	FieldsToAdd       = New Array;
	ResourcesWithoutGranularity = New Map;
	
	If DetailByPeriodParameter.Value > 0 Then
		GroupsToAdd.Add(
			New DataCompositionField(?(DetailByPeriodParameter.Value = 1, "DayPeriod", "MonthPeriod")));
	EndIf;	
	
	If ShowAssignmentParameter.Value Then
		FieldsToAdd.Add(New DataCompositionField("Purpose"));
	Else
		FieldsToDelete__.Add(New DataCompositionField("Purpose"));	
	EndIf;
	
	ResourcesWithoutGranularity.Insert(0, New Array);
	ResourcesWithoutGranularity.Insert(1, New Array);
	
	FieldArray = ResourcesWithoutGranularity.Get(0);// Array
	FieldArray.Add(New DataCompositionField("ForTransferToWarehouse"));
	
	FieldArray = ResourcesWithoutGranularity.Get(1);// Array
	FieldArray.Add(New DataCompositionField("ToReceive"));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("GroupsToAdd"     , GroupsToAdd);
	StructureOfActions.Insert("FieldsToDelete__"         , FieldsToDelete__);
	StructureOfActions.Insert("FieldsToAdd"       , FieldsToAdd);
	StructureOfActions.Insert("ResourcesWithoutGranularity" , ResourcesWithoutGranularity);
	
	SettingsStructure = MainCircuitSettings.Structure;
	StructureIndex   = SettingsStructure.Count() - 1;
	While StructureIndex > -1 Do
		
		SettingsItem = SettingsStructure[StructureIndex];
		
		If TypeOf(SettingsItem) = Type("DataCompositionGroup") Then
			AdjustDetail(SettingsStructure, SettingsItem, StructureOfActions, StructureIndex);  
		EndIf;
		
		StructureIndex = StructureIndex - 1;	
		
	EndDo;
	
	DataCompositionClientServer.SetParameter(
		MainCircuitSettings,
		"ScheduleStatus",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	SettingsComposer.LoadSettings(MainCircuitSettings);
	
	// Layout and output.
	SetPrivilegedMode(True);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfUnitFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified.
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	AuxiliaryParameters.Add("ShowDetailsOnPeriod");
	AuxiliaryParameters.Add("ShowAssignment");	
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

Function StructureOfUnitFieldHeaders()
	
	TheStructureOfTheHeaders = DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	For Each Item In TheStructureOfTheHeaders Do
		If TypeOf(Item.Value) = Type("String")
			And Not Find(Item.Value, NStr("vi = 'hàng hóa';
											|ru = 'товар';
											|en = 'product'; fa = 'product';
											|it = 'merce';
											|pl = 'product';
											|tr = 'ürün'"))=0 Then
			
			TheStructureOfTheHeaders.Insert(
				Item.Key,
				StrReplace(Item.Value, NStr("vi = 'hàng hóa';
											|ru = 'товар';
											|en = 'product'; fa = 'product';
											|it = 'merce';
											|pl = 'product';
											|tr = 'ürün'"), NStr("vi = 'nguyên vật liệu';
																	|ru = 'материал';
																	|en = 'material'; fa = 'material';
																	|it = 'materiale';
																	|pl = 'material';
																	|tr = 'malzeme'")));
			
		EndIf;
	EndDo;
	
	Return TheStructureOfTheHeaders;
	
EndFunction

Procedure AdjustDetail(SettingsStructure, SettingsItem, StructureOfActions, IndexOf)
	
	GroupFields = SettingsItem.GroupFields.Items;
	
	If GroupFields.Count() > 1 Then
		
		If SettingsItem.Structure.Count() > 0 Then
			SettingsItem.Structure.Clear();	
		EndIf;
		
		ProcessSelectedFields = False;
		FiltersCollection        = SettingsItem.Filter.Items;
		For Each CurrentFilter In FiltersCollection Do
			
			If CurrentFilter.LeftValue  = New DataCompositionField("MovementType")
			   And CurrentFilter.ComparisonType   = DataCompositionComparisonType.Equal
			   And CurrentFilter.RightValue = Enums.InventoryMovementTypes.Inpayment Then
				
				ProcessSelectedFields = True;
				Break;
				
			EndIf;   
			
		EndDo;	
		
		If ProcessSelectedFields Then
			
			DeleteReportFields(
				SettingsItem.Selection.Items, 
				"DataCompositionSelectedField", 
				StructureOfActions.FieldsToDelete__);
			
			DeleteReportFields(
				SettingsItem.GroupFields.Items, 
				"DataCompositionGroupField", 
				StructureOfActions.FieldsToDelete__, 
				StructureOfActions.FieldsToAdd);
			
			For Each FieldToAdd In StructureOfActions.FieldsToAdd Do
				
				GroupingField = SettingsItem.GroupFields.Items.Add(Type("DataCompositionGroupField"));
				GroupingField.Use = True;
				GroupingField.Field          = FieldToAdd;
				
				SelectionField_ = SettingsItem.Selection.Items.Insert(1, Type("DataCompositionSelectedField"));
				SelectionField_.Use = True;
				SelectionField_.Field          = FieldToAdd;
				
			EndDo;	
			
		EndIf;
		
		ArrayOfResourcesWithoutGranularity = StructureOfActions.ResourcesWithoutGranularity.Get(IndexOf);
		
		For Each DimensionToAdd In StructureOfActions.GroupsToAdd Do
			
			NewSettingItem = SettingsItem.Structure.Add(TypeOf(SettingsItem));
			
			DataCompositionClientServer.CopyElements(NewSettingItem.Filter, SettingsItem.Filter);
						
			GroupItem2 = NewSettingItem.GroupFields.Items.Add(Type("DataCompositionGroupField"));
			GroupItem2.Use = True;
			GroupItem2.Field 		 = DimensionToAdd;
			
			ArrayOfNumericFields = New Array;
			SelectionAvailableFields = SettingsItem.Selection.SelectionAvailableFields.Items;
			For Each AvailableField In SelectionAvailableFields Do
				TypesArray = AvailableField.Type.Types();
				If TypesArray.Count() = 1 And TypesArray[0] = Type("Number") Then
					ArrayOfNumericFields.Add(AvailableField.Field);
				EndIf;	
			EndDo;	
			
			ChoiceItem = NewSettingItem.Selection.Items.Add(Type("DataCompositionSelectedField"));
			ChoiceItem.Use = True;
			ChoiceItem.Field          = DimensionToAdd;
			
			If ArrayOfResourcesWithoutGranularity <> Undefined Then
			
				ConditionalAppearanceItem = NewSettingItem.ConditionalAppearance.Items.Add();
				ConditionalAppearanceItem.Use               = True;
				ConditionalAppearanceItem.UseInHeader      = DataCompositionConditionalAppearanceUse.DontUse;
				ConditionalAppearanceItem.UseInFieldsHeader = DataCompositionConditionalAppearanceUse.DontUse;
				
				ConditionalAppearanceItem.Appearance.SetParameterValue(
					New DataCompositionParameter("Text"), "");
				
			EndIf;	
			
			SelectedFields = SettingsItem.Selection.Items;
			For Each SelectedField In SelectedFields Do
				
				If ArrayOfNumericFields.Find(SelectedField.Field) <> Undefined Then
					
					ChoiceItem = NewSettingItem.Selection.Items.Add(Type("DataCompositionSelectedField"));
					ChoiceItem.Use = True;
					ChoiceItem.Field          = SelectedField.Field;
					
					If ArrayOfResourcesWithoutGranularity <> Undefined 
					   And ArrayOfResourcesWithoutGranularity.Find(SelectedField.Field) <> Undefined Then
			
						FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
						FormattedField.Use = True;
						FormattedField.Field          = SelectedField.Field;
			
					EndIf;	
					
				EndIf;
				
			EndDo;
			
			ElementOrder = NewSettingItem.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
			ElementOrder.Use = True;
			
			NewSettingItem.OutputParameters.SetParameterValue(
				New DataCompositionParameter("FilterOutput"), DataCompositionTextOutputType.DontOutput);
			
			SettingsItem = NewSettingItem;	
			
		EndDo;	
		
	EndIf;	
	
EndProcedure

Procedure DeleteReportFields(ReportFields, NameOfReportFieldType, FieldsToDelete__, FieldsToAdd = Undefined)
	
	IndexFieldOfReport = ReportFields.Count() - 1;
	While IndexFieldOfReport > - 1 Do
		
		ReportField = ReportFields.Get(IndexFieldOfReport);
		If TypeOf(ReportField) = Type(NameOfReportFieldType) Then
			
			If FieldsToDelete__.Find(ReportField.Field) <> Undefined Then
				
				ReportFields.Delete(ReportField);
				
			ElsIf FieldsToAdd <> Undefined Then
				
				IndexOfFieldBeingAdded = FieldsToAdd.Find(ReportField.Field);
				If IndexOfFieldBeingAdded <> Undefined Then
					FieldsToAdd.Delete(IndexOfFieldBeingAdded);
				EndIf;
				
			EndIf;	   
			
		EndIf;
		
		IndexFieldOfReport = IndexFieldOfReport - 1;	
		
	EndDo;
	
EndProcedure	

Function DetermineLocationOfControls()
	
	SettingsArray              = New Array;
	ControlItemSettings = New Structure;
	
	ControlItemSettings.Insert("Field"                     , "ShowDetailsOnPeriod");
	ControlItemSettings.Insert("HorizontalStretch" , False);
	ControlItemSettings.Insert("AutoMaxWidth"   , False);
	ControlItemSettings.Insert("Width"                   , 12);
	
	SettingsArray.Add(ControlItemSettings);
	
	ControlSettings_ = New Structure();
	ControlSettings_.Insert("DataParameters", SettingsArray);
	
	Return ControlSettings_;
	
EndFunction

#EndRegion

#EndIf