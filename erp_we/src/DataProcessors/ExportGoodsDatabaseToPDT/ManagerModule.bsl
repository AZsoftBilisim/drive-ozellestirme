#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then


// The function returns an empty configuration structure
// 
// Parameters: 
//  None
// 
// Returns: 
//  Structure - the structure of the settings.
Function SettingsStructure() Export
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("RequiredFields",               New Array);
	SettingsStructure.Insert("SettingsComposer",            Undefined);
	SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate", Undefined);
	
	Return SettingsStructure;
	
EndFunction

Function SetValueOfDCSParameter(SettingsComposer, ParameterName, ParameterValue, UseNotFilled = True)
	
	ParameterIsSet = False;
	
	DataCompositionParameter = New DataCompositionParameter(ParameterName);
	DataCompositionParameterValue = SettingsComposer.Settings.DataParameters.FindParameterValue(DataCompositionParameter);
	If DataCompositionParameterValue <> Undefined Then
		
		DataCompositionParameterValue.Value = ParameterValue;
		DataCompositionParameterValue.Use = ?(UseNotFilled, True, ValueIsFilled(DataCompositionParameterValue.Value));
		
		ParameterIsSet = True;
		
	EndIf;
	
	Return ParameterIsSet;
	
EndFunction

// This function prepares the data structure required for printing price tags and labels.
//
// Returns:
//  Structure - data required for printing labels and price tags.
//
Function PrepareDataStructure(SettingsStructure) Export
	
	////////////////////////////////////////////////////////////////////////////////
	// PREPARATION OF THE DATA LAYOUT SCHEME AND THE SCD SETTINGS BUILDER
	
	// scheme of the layout.
	DataCompositionSchema = DataProcessors.ExportGoodsDatabaseToPDT.GetTemplate(SettingsStructure.NameOfDataLayoutSchemaTemplate);
	
	// Preparing the data layout layout builder.
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	Composer.LoadSettings(DataCompositionSchema.DefaultSettings);
	Composer.Settings.Filter.Items.Clear();
	
	// Selection of the settings linker.
	If SettingsStructure.SettingsComposer <> Undefined Then
		DataCompositionClientServer.CopyElements(Composer.Settings.Filter, SettingsStructure.SettingsComposer.Settings.Filter);
	EndIf;
	
	// Selected fields of the settings builder.
	For Each RequiredField In SettingsStructure.RequiredFields Do
		DCSField = DataCompositionServer.FindDCSFieldByFullName(Composer.Settings.Selection.SelectionAvailableFields.Items, RequiredField);
		If DCSField <> Undefined Then
			SelectedField = Composer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
			SelectedField.Field = DCSField.Field;
		EndIf;
	EndDo;
	
	For Each DataParameter In SettingsStructure.DataParameters Do
		SetValueOfDCSParameter(Composer, DataParameter.Key, DataParameter.Value);
	EndDo;
	
	QueryText = DataCompositionSchema.DataSets.DataSet.Query;
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products"));
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"SourceDataLastRequest.Package",
		"SourceDataLastRequest.Products"));
	DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	
	// Layout layout of the data layout.
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Composer.Settings,,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	////////////////////////////////////////////////////////////////////////////////
	// REQUEST EXECUTION
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	
	Table = New ValueTable();
	OutputProcessor.SetObject(Table);
	ReportData = OutputProcessor.Output(CompositionProcessor);
	
	Return Table;
	
EndFunction

#EndIf