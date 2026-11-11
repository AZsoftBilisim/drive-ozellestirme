///////////////////////////////////////////////////////////////////////////////
// The module contains methods of management reporting formation
///////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region CreatingSettingsForReportOptions

// The function fills in the passed parameters and returns the user settings of the option
// Steps for getting custom settings:
//		1. Getting custom settings for custom report options (settings saved/unsaved)
//		2. Getting custom settings for predefined report options (settings were saved)
//		3. Getting custom settings for predefined report options (settings were not saved, first run).
//
// Parameters:
//	PropertiesOfAnalysisVariant - Structure - Contains:
//		* Ref        - CatalogRef.AnalysisOptionsOfTargetValues - analysis option to apply settings to the report
//		* AnalysisPeriod - ValueStorage - contains a Packed standard Period describing the data sampling period
//		* AnalysisPeriod - StandardPeriod - or ready-made
//	ReportOptionProperties  - Structure - the version of the report whose settings will be set. Contains:
//		* VariantKey - String -
//		* ObjectKey  - String -
//
// Returns:
//	Structure - Contains:
//		* UserSettings - DataCompositionSettings -
//		* FixedSettings    - DataCompositionUserSettings -
//
Function GenerateReportVariantSettings(PropertiesOfAnalysisVariant, ReportOptionProperties) Export
	
	SettingsStructure = New Structure("UserSettings, FixedSettings");
	OptionSettings = Undefined;
	OptionDetails = ReportsVariantsStorage.GetDescription(ReportOptionProperties.ObjectKey, ReportOptionProperties.VariantKey);
		
	DCSReport = Common.ObjectManagerByFullName(ReportOptionProperties.ObjectKey).GetTemplate("MainDataCompositionSchema");
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCSReport);
	
	// We will pass the custom settings of the analysis option to the report
	FixedReportOptionSettings = SetSelectionCollectionToFixedSettings(ReportOptionProperties,
		PropertiesOfAnalysisVariant,
		OptionDetails);
	
	If FixedReportOptionSettings = Undefined Then
		FixedReportOptionSettings = DCSReport.SettingVariants[ReportOptionProperties.VariantKey].Settings;
	EndIf;
	
	// Let's set the parameters of the report variant
	ParametersToBeSpecified = CreateCollectionOfPeriodParameters(PropertiesOfAnalysisVariant.AnalysisPeriod);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(AvailableSettingsSource);
	If FixedReportOptionSettings <> Undefined Then
		SettingsComposer.LoadFixedSettings(FixedReportOptionSettings);
		AdjustSettingsByAvailableFields(SettingsComposer.FixedSettings);
		FixedReportOptionSettings = SettingsComposer.FixedSettings;
	EndIf;
	
	If AccessRight("SaveUserData", Metadata)
		And OptionDetails.AdditionalProperties.Custom Then
		OptionSettings = ReportsVariantsStorage.Load(ReportOptionProperties.ObjectKey,
			ReportOptionProperties.VariantKey,
			OptionDetails);
	EndIf;
	
	If OptionSettings <> Undefined Then
		SettingsComposer.LoadSettings(OptionSettings);
	EndIf;
	
	CustomOptionSettings = SettingsComposer.UserSettings;
	
	DataCompositionClientServer.SetCollectionOfParameters(CustomOptionSettings, ParametersToBeSpecified);
	
	SettingsStructure.Insert("FixedSettings", FixedReportOptionSettings);
	SettingsStructure.Insert("UserSettings", CustomOptionSettings);
	
	Return SettingsStructure;
	
EndFunction

// The procedure adjusts the composition of the selected fields, selection fields, order
// fields in accordance with the corresponding available fields
//
Procedure AdjustSettingsByAvailableFields(Settings)
	
	SettingCompliance = New Map;
	SettingCompliance.Insert("Selection", "SelectionAvailableFields");
	SettingCompliance.Insert("Filter", "FilterAvailableFields");
	SettingCompliance.Insert("Order", "OrderAvailableFields");
	
	For Each Setting In SettingCompliance Do
		
		SettingsItems = Settings[Setting.Key].Items;
		If SettingsItems.Count() > 0 Then
			N1 = 0;
			While N1 < SettingsItems.Count() Do
				SettingItem = SettingsItems[N1];
				If TypeOf(SettingItem) = Type("DataCompositionFilterItem")
					And Settings[Setting.Value].FindField(SettingsItems[N1].LeftValue) = Undefined Then
					SettingsItems.Delete(N1);
				ElsIf (TypeOf(SettingItem) = Type("DataCompositionOrderItem")
					Or TypeOf(SettingItem) = Type("DataCompositionSelectedField"))
					And Settings[Setting.Value].FindField(SettingItem.Field) = Undefined Then
					SettingsItems.Delete(N1);
				Else
					N1 = N1 + 1;
				EndIf;
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region GettingAnalysisVariantPropertiesAndObjectReferences

// The function returns properties of the analysis variant by the variant ID
// Parameters:
//	Id - String - string representation of the analysis variant ID
// Returns:
//	Structure - the structure of the properties of the target analysis variant:
//	 *Ref - CatalogRef.AnalysisOptionsOfTargetValues - 
//	 *AnalysisPeriod - StandardPeriod - 
//
Function GetPropertiesOfAnalysisVariantById(Id) Export
	
	AnalysisOption = GetReferenceToCatalogById("AnalysisOptionsOfTargetValues", Id);
	
	IndicatorStructure = New Structure("Ref, AnalysisPeriod", AnalysisOption, AnalysisOption.AnalysisPeriod.Get());
	
	Return IndicatorStructure;
	
EndFunction

// The function returns a reference to the reference identifier reference
// Parameters:
//	ObjectName    - String - directory name
//	Id - String - ID of the directory element
// Returns:
//	CatalogRef - a reference to the metadata object.
//
Function GetReferenceToCatalogById(ObjectName, Id) Export
		
	UniqueMetricIdentifier = New UUID(StrReplace(Id, "_", "-"));
	LinkYouAreLookingFor = Catalogs[ObjectName].GetRef(UniqueMetricIdentifier);
	
	Return LinkYouAreLookingFor;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region CreatingSettingsForReportOptions

Procedure CopySelectionElementsToMatches(ItemsCollection, ComplianceIncluded, MatchingNotIncluded, IncludeNested = False)
	
	For Each CollectionItem In ItemsCollection Do 
		If Not IsBlankString(CollectionItem.UserSettingID) Then
			If TypeOf(CollectionItem) = Type("DataCompositionFilterItem") Then
				ComplianceIncluded.Insert(CollectionItem.UserSettingID, CollectionItem);
			Else
				ComplianceIncluded.Insert(CollectionItem.UserSettingID, CollectionItem);
				
				If IncludeNested Then
					CopySelectionElementsToMatches(CollectionItem.Items,
						ComplianceIncluded,
						MatchingNotIncluded);
				EndIf;
			EndIf;
		Else
			MatchingNotIncluded.Insert(CollectionItem, CollectionItem);
		EndIf;
	EndDo;
	
EndProcedure

Function SetSelectionCollectionToFixedSettings(PropertiesReportOption, PropertiesOfAnalysisVariant, OptionDetails)
	
	OptionSettings = Undefined;
	
	// We will get the saved settings of the report variant
	If AccessRight("SaveUserData", Metadata) And OptionDetails.AdditionalProperties.Custom Then
		OptionSettings = ReportsVariantsStorage.Load(PropertiesReportOption.ObjectKey,
			PropertiesReportOption.VariantKey,
			OptionDetails);
	EndIf;

	If OptionSettings = Undefined Then
		DCSReport = Common.ObjectManagerByFullName(PropertiesReportOption.ObjectKey).GetTemplate("MainDataCompositionSchema");
		
		RequiredVersionOfReport = DCSReport.SettingVariants.Find(PropertiesReportOption.VariantKey);
		If Not RequiredVersionOfReport = Undefined Then
			OptionSettings = DCSReport.SettingVariants[PropertiesReportOption.VariantKey].Settings;
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.LoadSettings(OptionSettings);
	
	// We will get the settings of the analysis option
	TargetValue = Common.ObjectAttributeValue(PropertiesOfAnalysisVariant.Ref, "Owner");
	TargetData = Common.ObjectAttributesValues(TargetValue, "DataCompositionSchema, StorageOfDataCompositionSchema, StorageOfDataCompositionSettings");
	If ValueIsFilled(TargetData.DataCompositionSchema)
		Or TargetData.StorageOfDataCompositionSchema.Get() = Undefined Then
		SchemeAndSettings = Catalogs.StructureOfTargets.DescriptionAndLayoutDiagramOfTargetDataByTemplateName(
			TargetValue,
			TargetData.DataCompositionSchema);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
	Else
		DataCompositionSchema = TargetData.StorageOfDataCompositionSchema.Get();
	EndIf;
	
	DCSAddress = PutToTempStorage(DataCompositionSchema, New UUID());
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCSAddress);
	
	AnalysisVariantSettingsComposer = New DataCompositionSettingsComposer;
	AnalysisVariantSettingsComposer.Initialize(AvailableSettingsSource);
	
	Settings = TargetData.StorageOfDataCompositionSettings.Get();
	
	If Not Settings = Undefined Then
		AnalysisVariantSettingsComposer.LoadSettings(Settings);
	Else
		AnalysisVariantSettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	CustomSettingsForAnalysisOption = Common.ObjectAttributeValue(
		PropertiesOfAnalysisVariant.Ref, "StorageOfDataCompositionUserSettings").Get();
	
	If Not CustomSettingsForAnalysisOption = Undefined Then
		AnalysisVariantSettingsComposer.LoadUserSettings(CustomSettingsForAnalysisOption);
	Else 
		AnalysisVariantSettingsComposer.Refresh();
	EndIf;
	
	// We will get the selections that need to be sent to the report
	CustomFilters = AnalysisVariantSettingsComposer.UserSettings.Items;
	
	InstallableSelectionsIncludedInCustomSelections = New Map;
	InstallableSelectionsNotIncludedInCustomSelections = New Map;
	InstallableCustomSelections = New Map;
	
	For Each UserSelection_ In CustomFilters Do 
		If TypeOf(UserSelection_) = Type("DataCompositionFilterItem")
			Or TypeOf(UserSelection_) = Type("DataCompositionFilterItemGroup") Then
			
			InstallableCustomSelections.Insert(UserSelection_.UserSettingID, UserSelection_);
			
		EndIf;
		
	EndDo;
	
	SelectionOfAnalysisOption = AnalysisVariantSettingsComposer.Settings.Filter.Items;
	
	CopySelectionElementsToMatches(SelectionOfAnalysisOption,
		InstallableSelectionsIncludedInCustomSelections,
		InstallableSelectionsNotIncludedInCustomSelections);
	
	// Fill in the selections of fixed settings
	SelectionsOfFixedSettings = SettingsComposer.FixedSettings.Filter.Items;
	
	For Each EstablishedSelection In InstallableSelectionsNotIncludedInCustomSelections Do 
		If TypeOf(EstablishedSelection.Value) = Type("DataCompositionFilterItem") Then
			NewFilter = SelectionsOfFixedSettings.Add(Type("DataCompositionFilterItem"));
			FillPropertyValues(NewFilter, EstablishedSelection.Value);
		Else
			NewFilter = SelectionsOfFixedSettings.Add(Type("DataCompositionFilterItemGroup"));
			FillPropertyValues(NewFilter, EstablishedSelection.Value);
			DataCompositionClientServer.CopyElements(NewFilter, EstablishedSelection.Value);
		EndIf;
	EndDo;
	
	For Each EstablishedSelection In InstallableSelectionsIncludedInCustomSelections Do
		If TypeOf(EstablishedSelection.Value) = Type("DataCompositionFilterItem") Then
			NewFilter = SelectionsOfFixedSettings.Add(Type("DataCompositionFilterItem"));
			FillPropertyValues(NewFilter, EstablishedSelection.Value);
			FillPropertyValues(NewFilter, InstallableCustomSelections.Get(EstablishedSelection.Key),,
				"LeftValue, Presentation, Application, UserSettingPresentation");
		Else
			NewFilter = SelectionsOfFixedSettings.Add(Type("DataCompositionFilterItemGroup"));
			FillPropertyValues(NewFilter, EstablishedSelection.Value);
			FillPropertyValues(NewFilter, InstallableCustomSelections.Get(EstablishedSelection.Key),,
				"Presentation");
			DataCompositionClientServer.CopyElements(NewFilter, EstablishedSelection.Value);
		EndIf;
	EndDo;
	
	Return SettingsComposer.FixedSettings;
	
EndFunction

#EndRegion

#Region Other

// Returns a collection of parameters with the date or standard period type
// The currently used period parameters
// in report data layout schemes are added to the collection.
//  
//Parameters:
//	Period - StandardPeriod -
//
Function CreateCollectionOfPeriodParameters(Period)
	
	CollectionOfPeriodParameters = New Map;
	
	// Let's add standard periods
	CollectionOfPeriodParameters.Insert("Period", Period);
	CollectionOfPeriodParameters.Insert("ReportPeriod", Period);
	CollectionOfPeriodParameters.Insert("StandardPeriod", Period);
	
	// Add the start dates of the periods
	CollectionOfPeriodParameters.Insert("BeginOfPeriod", Period.StartDate);
	CollectionOfPeriodParameters.Insert("PeriodBeginning", Period.StartDate);
	CollectionOfPeriodParameters.Insert("StartDate", Period.StartDate);
	
	// Adding the end dates of the periods
	CollectionOfPeriodParameters.Insert("PeriodEnding", Period.EndDate);
	CollectionOfPeriodParameters.Insert("EndOfPeriod", Period.EndDate);
	CollectionOfPeriodParameters.Insert("PeriodEnd_", Period.EndDate);
	CollectionOfPeriodParameters.Insert("PeriodEnd", Period.EndDate);
	CollectionOfPeriodParameters.Insert("ReportDate", Period.EndDate);
	CollectionOfPeriodParameters.Insert("EndDate", Period.EndDate);
	CollectionOfPeriodParameters.Insert("OnDate", Period.EndDate);
	
	Return CollectionOfPeriodParameters;
	
EndFunction

#EndRegion

#EndRegion
