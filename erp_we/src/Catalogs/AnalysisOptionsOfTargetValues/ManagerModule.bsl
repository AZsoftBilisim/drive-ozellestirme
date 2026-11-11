#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the default appearance settings for analysis options.
// 
// Parameters:
// 	ComponentWiseComparisonStructure - Boolean - LongDesc
// Returns:
// 	Structure - LongDesc:
// * Include_2Zero - Boolean -
// * ValueScaleMode - EnumRef.ChartValueScaleMode -
// * ChartSmoothingMode - Boolean -
// * ChartBorder - Boolean -
// * DisplayChartCaptions - Boolean -
// * ShowLegend - Boolean -
// * DisplayAMarkerOfForecastPoints - Boolean -
// * HighlightMaximumValueForComponentWiseComparison - Boolean -
// * GradientForComponentWiseComparison - Boolean -
// * OnlyColorOfMainBatch - Boolean -
// * DecorationSettingStorage - ValueStorage -
Function DefaultDesignSettings(ComponentWiseComparisonStructure = False) Export
	
	// Let's form the color settings
	ColorSettings_ = New Structure;
	
	SetOfColors = New Map;
	SetOfColors.Insert("Value", WebColors.SteelBlue);
	SetOfColors.Insert("Prediction", WebColors.MediumVioletRed);
	SetOfColors.Insert("TargetValue_", WebColors.ForestGreen);
	SetOfColors.Insert("PositiveVariance", WebColors.RoyalBlue);
	SetOfColors.Insert("NegativeVariance", WebColors.Crimson);
	SetOfColors.Insert("AcceptableDeviationZone", New Color(255, 195, 0));
	
	ColorSettings_.Insert("Colors", SetOfColors);
	
	DecorationSettingStorage = New ValueStorage(ColorSettings_);
	
	// Let's form the settings of the output parameters
	DecorationSettingStructure = New Structure;
	DecorationSettingStructure.Insert("DecorationSettingStorage", DecorationSettingStorage);
	DecorationSettingStructure.Insert("OnlyColorOfMainBatch", True);
	DecorationSettingStructure.Insert("GradientForComponentWiseComparison", True);
	DecorationSettingStructure.Insert("HighlightMaximumValueForComponentWiseComparison", False);
	DecorationSettingStructure.Insert("DisplayAMarkerOfForecastPoints", False);
	DecorationSettingStructure.Insert("ShowLegend", True);
	DecorationSettingStructure.Insert("DisplayChartCaptions", True);
	DecorationSettingStructure.Insert("ChartBorder", False);
	DecorationSettingStructure.Insert("ChartSmoothingMode", True);
	DecorationSettingStructure.Insert("ValueScaleMode", Enums.ChartValueScaleMode.Auto);
	DecorationSettingStructure.Insert("Include_2Zero", True);
	
	Return DecorationSettingStructure;
	
EndFunction

// Puts the data layout schema
// , data layout settings, and user settings in temporary storage and returns their addresses.
//
// Parameters:
//	AnalysisOption - Structure - Attributes of the analysis variant for which addresses are returned.
//
// Returns:
//	Structure - structure containing addresses:
//	 *DataCompositionSchema - String - the address of the temporary storage that contains the layout scheme.
//	 *DataCompositionSettings - String - the address of the temporary storage that contains the layout scheme settings.
//	 *UserSettings - String - temporary storage address containing user settings.
//
Function AddressesOfDataLayoutSchemeAndUserSettings(AnalysisOption) Export
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings, UserSettings");
	
	TargetValue = AnalysisOption.Owner;
	TargetData = Common.ObjectAttributesValues(TargetValue,
		"DataCompositionSchema, StorageOfDataCompositionSchema, StorageOfDataCompositionSettings");
	
	// We get the data layout scheme
	If ValueIsFilled(TargetData.DataCompositionSchema) Or TargetData.StorageOfDataCompositionSchema.Get() = Undefined Then
		SchemeAndSettings = Catalogs.StructureOfTargets.DescriptionAndLayoutDiagramOfTargetDataByTemplateName(TargetValue, TargetData.DataCompositionSchema);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
	Else
		DataCompositionSchema = TargetData.StorageOfDataCompositionSchema.Get();
	EndIf;
	
	Addresses.DataCompositionSchema = PutToTempStorage(DataCompositionSchema, New UUID());
	
	Settings = TargetData.StorageOfDataCompositionSettings.Get();
	
	If ValueIsFilled(Settings) Then
		Addresses.DataCompositionSettings = PutToTempStorage(Settings, New UUID());
	EndIf;
	
	UserSettings = AnalysisOption.StorageOfDataCompositionUserSettings.Get();
	
	If ValueIsFilled(UserSettings) Then
		Addresses.UserSettings = PutToTempStorage(UserSettings, New UUID());
	EndIf;
	
	Return Addresses;
	
EndFunction

// Returns the demo data specified in the analysis option
//
// Parameters:
//	AnalysisOption - Structure - Attributes of the analysis variant for which addresses are returned.
//
// Returns:
//	ValueTable - table of demo data of the analysis option.
//
Function DemonstrationDataOfAnalysisOption(AnalysisOption) Export 
	DemonstrationData = New ValueTable;
	
	ValueAnalysisName = String(AnalysisOption.AnalysisValue.Get());
	AnalysisValueAdditionalName = String(AnalysisOption.AnalysisValueAdditional.Get());
	ObjectOfAnalysisName = String(AnalysisOption.AnalysisObject.Get());
	
	DemoDataStorageValue = AnalysisOption.DemoDataStorage.Get();
	If DemoDataStorageValue <> Undefined Then
		DemoDataStorage = DemoDataStorageValue.Data; // ValueStorage
		DemonstrationData = DemoDataStorage.Get(); // ValueTable -
		
		TableColumn2 = DemonstrationData.Columns.IndicatorValue; // ValueTableColumn - 
		TableColumn2.Name = ValueAnalysisName;
		
		If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
			Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
			If AnalysisOption.ComponentWiseComparisonMode = 0 Then
				TableColumn2 = DemonstrationData.Columns.AnalysisObject; // ValueTableColumn -
				TableColumn2.Name = ObjectOfAnalysisName;
			Else
				TableColumn2 = DemonstrationData.Columns.TheValueOfTheIndexForMore; // ValueTableColumn -
				TableColumn2.Name = AnalysisValueAdditionalName;
			EndIf;
		EndIf;
		If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure Then
			If AnalysisOption.ComponentWiseComparisonMode = 0 Then
				LastDate = DemonstrationData[0].Period;
				DemonstrationData.FillValues(Undefined, "Period");
				
				SummaryOfTable = DemonstrationData.Total(ValueAnalysisName);
				NewRow = DemonstrationData.Add();
				NewRow.Period = LastDate;
				NewRow[ValueAnalysisName] = SummaryOfTable;
			EndIf;
		EndIf;
	EndIf;

	Return DemonstrationData;
EndFunction
// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	OpeningExistingObject = Parameters.Property("Key") And ValueIsFilled(Parameters.Key);
	CreatingObjectNotFromList = Not OpeningExistingObject
			And Not (Parameters.Property("FillingValues") 
				And Parameters.FillingValues.Property("Owner")
				Or Parameters.Property("CopyingValue"));
	
	If FormType = "ObjectForm" And CreatingObjectNotFromList Then
		
		StandardProcessing = False;
		SelectedForm = Metadata.Catalogs.AnalysisOptionsOfTargetValues.Forms.WarningForm;
	EndIf;
EndProcedure
	
#EndRegion 
