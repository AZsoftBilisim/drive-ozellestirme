#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Applies the specified settings to the list
//
// Parameters:
//  ListData				- FormDataCollection - the source list to apply the settings to
//  AddressOfDataCompositionSchema	- String - the address of the storage where the data schema is located
//  CompositionSettings			- DataCompositionSettings - List Settings
//  DefaultOrder1			- String - a list of fields to arrange by if the user has not configured the order.
//
Procedure ApplySettingToList(ListData, AddressOfDataCompositionSchema, CompositionSettings, DefaultOrder1 = "") Export

	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
	
	// SKD loading
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(CompositionSettings);
	SettingsComposer.Refresh();
	
	// Disabling the output of total totals
	SettingsComposer.Settings.OutputParameters.SetParameterValue("HorizontalOverallPlacement", DataCompositionTotalPlacement.None);
	SettingsComposer.Settings.OutputParameters.SetParameterValue("VerticalOverallPlacement", DataCompositionTotalPlacement.None);
	
	SettingsUsed = SettingsComposer.GetSettings();
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(
											DataCompositionSchema, 
											SettingsUsed,,, 
											Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataSet = ListData.Unload().CopyColumns();
	DataSet.Columns.Add("_Id", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	For Each RowData In ListData Do
		NewRow = DataSet.Add();
		FillPropertyValues(NewRow, RowData);
		NewRow._Id = RowData.GetID();
	EndDo;
	
	DatasetsObjects = New Structure;
	DatasetsObjects.Insert("DataSet", DataSet);
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, DatasetsObjects);
	
	// Getting the result
	ResultTable2 = New ValueTable;
	DataCompositionResultValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(ResultTable2);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);

	ResultTable2.Indexes.Add("_Id");
	
	// You cannot use the loading of the value table, because the result table may not contain all columns.
	For Each RowData In ListData Do
		RowData.DoesnTMatchListSetting = (ResultTable2.Find(RowData.GetID(), "_Id") = Undefined);
	EndDo;
	
	SortFields = "";
	For Each OrderItem In SettingsUsed.Order.Items Do
		If Not OrderItem.Use Then
			Continue;
		EndIf;
		
		SortFields = SortFields 
							+ ?(SortFields = "", "", ", ")
							+ String(OrderItem.Field)
							+ ?(OrderItem.OrderType = DataCompositionSortDirection.Desc, " desc", "");
	EndDo;
	
	If SortFields <> "" Then
		ListData.Sort(SortFields);
	ElsIf DefaultOrder1 <> "" Then
		ListData.Sort(DefaultOrder1);
	EndIf; 
	
EndProcedure

// Initializes the settings Composer for the form table
// Parameters:
//  ListAttributes - Array of FormAttribute - Attributes of the form table.
//  ListSettings - DataCompositionSettingsComposer - The linker settings.
//  FormUniqueID - UUID - the ID of the form.
//  SettingUpFields - Structure - structure with fields:
//   * UnavailableFields - Array of String - names of fields in the form table that are not available for settings.
// Returns:
//  String - the address in the temporary storage.
Function InitializingSettings(ListAttributes, ListSettings, FormUniqueID, SettingUpFields = Undefined) Export

	FilterFields = Undefined;
	OrderFields_ = Undefined;
	UnavailableFields = Undefined;
	
	If SettingUpFields <> Undefined Then
		SettingUpFields.Property("FilterFields", FilterFields);
		SettingUpFields.Property("OrderFields_", OrderFields_);
		SettingUpFields.Property("UnavailableFields", UnavailableFields);
	EndIf;
	
	If UnavailableFields = Undefined Then
		UnavailableFields = New Array;
	EndIf;
	UnavailableFields.Add("DoesnTMatchListSetting");
	
	DataCompositionSchema = New DataCompositionSchema;
	
	DataSource = DataCompositionSchema.DataSources.Add(); 
	DataSource.Name = "DataSource";
	DataSource.ConnectionString = "";
	DataSource.DataSourceType = "Local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
	DataSet.Name = "DataSet";
	DataSet.ObjectName = "DataSet";
	DataSet.DataSource = "DataSource";

	For Each FormAttribute In ListAttributes Do
		
		If UnavailableFields.Find(FormAttribute.Name) <> Undefined Then
			Continue;
		EndIf;
		
		If FormAttribute.ValueType.ContainsType(Type("ValueTable"))
			Or FormAttribute.ValueType.ContainsType(Type("ValueList")) Then
			Continue;
		EndIf;
		
		SetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		SetField.DataPath = FormAttribute.Name;
		SetField.Title   = FormAttribute.Title;
		SetField.Field        = FormAttribute.Name;
		SetField.ValueType = New TypeDescription(FormAttribute.ValueType);
		
		If FilterFields <> Undefined And FilterFields.Find(FormAttribute.Name) = Undefined Then
			SetField.UseRestriction.Condition = True;
		EndIf; 
		If OrderFields_ <> Undefined And FilterFields.Find(FormAttribute.Name) = Undefined Then
			SetField.UseRestriction.Order = True;
		EndIf; 
		
	EndDo; 
	
	SetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	SetField.DataPath = "_Id";
	SetField.Title   = "Id";
	SetField.Field        = "_Id";
	SetField.ValueType = New TypeDescription("Number", New NumberQualifiers(10, 0));
	SetField.UseRestriction.Condition = True;
	SetField.UseRestriction.Order = True;
	
	DataCompositionSchema.DefaultSettings.Filter.UserSettingID = String(New UUID);
	DataCompositionSchema.DefaultSettings.Order.UserSettingID = String(New UUID);
	
	GroupingRecords = DataCompositionSchema.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
	SelectedField = GroupingRecords.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Use = True;
	SelectedField.Field = New DataCompositionField("_Id");
	
	SchemaURL = PutToTempStorage(DataCompositionSchema, FormUniqueID);
	
	ListSettings.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	ListSettings.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	Return SchemaURL;
	
EndFunction

// Saves settings.
// Parameters:
//  ObjectKey - String - the key of the object in the user settings store. 
//  SettingsKey - String - The settings key is in the user settings store.
//  ListSettings - DataCompositionSettingsComposer - The settings Composer where the settings will be uploaded.
Procedure DownloadSettingsFromStorage(ObjectKey, SettingsKey, ListSettings) Export

	SavedSettings = FormDataSettingsStorage.Load(ObjectKey, SettingsKey);

	ListSettings.LoadSettings(SavedSettings.Settings);
	ListSettings.LoadUserSettings(SavedSettings.UserSettings);
	
EndProcedure

// Saves settings.
// Parameters:
//  ObjectKey - String - the key of the object in the user settings store. 
//  SettingsKey - String - The settings key is in the user settings store.
//  ListSettings - DataCompositionSettingsComposer - saved settings.
Procedure SaveSettingsInStorage(ObjectKey, SettingsKey, ListSettings) Export

	SavedSettings = New Structure;
	SavedSettings.Insert("Settings", ListSettings.GetSettings());
	SavedSettings.Insert("UserSettings", ListSettings.UserSettings);
	FormDataSettingsStorage.Save(ObjectKey, SettingsKey, SavedSettings);
	
EndProcedure

#EndRegion

#EndIf