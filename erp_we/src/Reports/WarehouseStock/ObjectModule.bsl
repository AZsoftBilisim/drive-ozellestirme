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
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - The Form of the report. Contains including:
//   	* Parameters - Structure - The parameter structure contains, among other things:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure:
//   				**** CommandName - String
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then
			
			If Parameters.CommandDetails.AdditionalParameters.CommandName = "MovementOfGoods" Then
				ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
			ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "GoodsBeingShipped" Then
				DocumentWarehouse = Common.ObjectAttributeValue(Parameters.CommandParameter, "Warehouse");
				
				ThisForm.ParametersForm.Filter.Insert("Warehouse",       DocumentWarehouse);
				ThisForm.ParametersForm.Filter.Insert("Recorder", Parameters.CommandParameter);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary									- parameters of the context in which the report is used.
//	SchemaKey							- String										- ID of the current configuration Builder schema.
//	VariantKey						- String, Undefined							- name of the predefined or unique ID of the custom
//																							version of the report.
//																							Undefined when calling for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings, Undefined		- report variant settings that will be loaded
//																							into the settings Builder after it is initialized.
//																							Undefined when the option settings do not need to be loaded (already loaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings, Undefined - custom settings that will be loaded into
//																							the settings Builder after it is initialized.
//																							Undefined when user settings do not need to be loaded
//																							(already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	SchemaKey		= VariantKey;
	FieldHeaders	= ParameterizableFieldHeaders();
	
	DataCompositionServer.SetHeadersOfSelectedFields(NewDCSettings.Selection.Items, FieldHeaders);
	DataCompositionServer.SetDimensionFieldHeaders(NewDCSettings.Structure, FieldHeaders);
	
	If TypeOf(NewDCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return;
	EndIf;
	
	SettingID = NewDCSettings.Selection.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		
		If FoundSettingElement <> Undefined Then 
			DataCompositionServer.SetHeadersOfSelectedFields(FoundSettingElement.Items, FieldHeaders);
		EndIf;
	EndIf;
	
	SettingID = NewDCSettings.Structure.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		
		If FoundSettingElement <> Undefined Then 
			DataCompositionServer.SetDimensionFieldHeaders(FoundSettingElement.Items, FieldHeaders);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	SelectionIsUsedForRecalculatingGoods = DataCompositionClientServer.GetParameter(
											SettingsComposer.Settings,
											"SelectionIsUsedForRecalculatingGoods");
	
	If SelectionIsUsedForRecalculatingGoods = Undefined Then
		Return;
	EndIf;
	
	SelectionIsUsedForRecalculatingGoods.Value      = False;
	SelectionIsUsedForRecalculatingGoods.Use = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(MainCircuitSettings.Filter,
																			"InventoryRecount");
	
	SelectionIsUsedForRecalculatingGoods = False;
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then
			SelectionIsUsedForRecalculatingGoods = True;
			Break;
		EndIf;
	EndDo;
	
	ThisParameterIsUsedForRecalculatingProducts = DataCompositionClientServer.GetParameter(
													SettingsComposer.Settings,
													"SelectionIsUsedForRecalculatingGoods");
	ThisParameterIsUsedForRecalculatingProducts.Value = True;
	ThisParameterIsUsedForRecalculatingProducts.Use = SelectionIsUsedForRecalculatingGoods;
	
	QueryText = DataCompositionSchema.DataSets.DataSet.Query;
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
									"GoodsInWarehousesBalancesAndTurnover.Products.UnitOfMeasure",
									"GoodsInWarehousesBalancesAndTurnover.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
									"GoodsInWarehousesBalancesAndTurnover.Products.UnitOfMeasure",
									"GoodsInWarehousesBalancesAndTurnover.Products"));
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfDynamicHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema,
																SettingsComposer,
																ResultDocument,
																AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Function StructureOfDynamicHeaders()
	DynamicHeaders = New Structure;
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "GroupingProducts");
	AvailableSetting = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, Parameter);
	If AvailableSetting <> Undefined Then
		PresentationOfParameterValue = AvailableSetting.AvailableValues[Parameter.Value-1];
		DynamicHeaders.Insert("GroupingProducts", PresentationOfParameterValue);
	EndIf;
	
	Return DynamicHeaders;
EndFunction

#EndRegion

#EndIf