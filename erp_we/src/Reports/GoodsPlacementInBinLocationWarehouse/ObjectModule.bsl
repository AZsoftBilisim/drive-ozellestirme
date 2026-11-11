#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	SetRequiredSettings(UserSettingsModified);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	If Not ValueIsFilled(UnitOfMeasureForWeight) Then
		NumberOfKgPerUnitOfWeight = 1;
	Else
		ResultingStructure = Common.ObjectAttributesValues(UnitOfMeasureForWeight, "Numerator, Denominator");
		
		NumberOfKgPerUnitOfWeight = ResultingStructure.Numerator / ResultingStructure.Denominator;
	EndIf;
	
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	If Not ValueIsFilled(UnitOfMeasureForVolume) Then
		NumberOfCubicMetersPerUnitOfVolume = 1;
	Else
		ResultingStructure = Common.ObjectAttributesValues(UnitOfMeasureForVolume, "Numerator, Denominator");
		
		NumberOfCubicMetersPerUnitOfVolume = ResultingStructure.Numerator / ResultingStructure.Denominator;
	EndIf;
	
	QueryText = DataCompositionSchema.DataSets.StorageBins.Query;
	
	QueryText = StrReplace(QueryText,
								"&NumberOfKgPerUnitOfWeight",
								Format(NumberOfKgPerUnitOfWeight, "NDS=.; NG=0"));
	QueryText = StrReplace(QueryText,
								"&NumberOfCubicMetersPerUnitOfVolume",
								Format(NumberOfCubicMetersPerUnitOfVolume, "NDS=.; NG=0"));
	
	DataCompositionSchema.DataSets.StorageBins.Query = QueryText;
	
	QueryText = DataCompositionSchema.DataSets.GoodsInStorageBins.Query;
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("GoodsInStorageBinsBalance.Package", "GoodsInStorageBinsBalance.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageVolume", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("GoodsInStorageBinsBalance.Package", "GoodsInStorageBinsBalance.Products"));
	
	DataCompositionSchema.DataSets.GoodsInStorageBins.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)

	Setting = DataCompositionClientServer.GetParameter(SettingsComposer, "DisplayOccupancyOfAcceptanceAndShipmentZones");
	ListOfDimensions = DataCompositionClientServer.GetGroupings(SettingsComposer);
	For Each Group In ListOfDimensions  Do
		If Group.Value.Name = "Zones receivings / shipments" Then
			Group.Value.Use = Setting.Value;
		EndIf;
	EndDo;
	
EndProcedure

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

#EndRegion

#EndIf