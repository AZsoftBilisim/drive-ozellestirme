#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function prepares the data structure required for printing price tags and labels.
//
// Parameters:
//  SettingsStructure - Structure - data, configuration structure.
//
// Returns:
//  Structure - data required for printing labels and price tags.
//
Function PrepareDataStructure(SettingsStructure) Export
	
	ResultStructure1 = New Structure;
	ResultStructure1.Insert("TableOfProductCategories",                             Undefined);
	ResultStructure1.Insert("CorrespondenceOfDCSFieldsToColumnsOfProductCategoryTable", New Map);

#Region PreparingDataLayoutSchemeAndDCSSettingsComposer
	
	// scheme of the layout.
	DataCompositionSchema = DataProcessors.SelectProductCategoriesByFilter.GetTemplate(SettingsStructure.NameOfDataLayoutSchemaTemplate);
	
	// Preparing the data layout layout builder.
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	Composer.LoadSettings(DataCompositionSchema.DefaultSettings);
	Composer.Settings.Filter.Items.Clear();
	UseProductRange = GetFunctionalOption("UseProductRange");
	If UseProductRange Then
		DataCompositionClientServer.SetParameter(Composer.Settings, "ProductRangeAsOfDate", CurrentSessionDate());
	EndIf;
	
	If SettingsStructure.KeepRecordsOfQualityCertificates Then
		DataCompositionClientServer.SetParameter(Composer.Settings, "KeepRecordsOfQualityCertificates", True);
	EndIf;
	
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
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(Composer);
	
	// Layout layout of the data layout.
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Composer.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));

#EndRegion

#Region PreparingAuxiliaryDataForMatchingTemplateAndDCSFields
	
	For Each Field In DataCompositionTemplate.DataSets.DataSet.Fields Do
		ResultStructure1.CorrespondenceOfDCSFieldsToColumnsOfProductCategoryTable.Insert(Catalogs.LabelAndPriceTagTemplates.NameOfFieldInTemplate(Field.DataPath), Field.Name);
	EndDo;

#EndRegion

#Region RequestExecution
	
	Query = New Query(DataCompositionTemplate.DataSets.DataSet.Query);
	
	// Filling in parameters from the selection fields of the processing form settings linker.
	For Each Parameter In DataCompositionTemplate.ParameterValues Do
		Query.Parameters.Insert(Parameter.Name, Parameter.Value);
	EndDo;
	
	ResultStructure1.TableOfProductCategories = Query.Execute().Unload();
	
	Return ResultStructure1;

#EndRegion
EndFunction
#EndRegion

#EndIf