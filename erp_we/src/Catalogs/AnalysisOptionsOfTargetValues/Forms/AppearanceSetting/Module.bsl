
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	RestoreServerDesignSettings(Parameters.DecorationSettingStructure);
	
	SetVisibilityAccessibilityOfFormElements(ThisForm);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GradientForComponentWiseComparisonOnChange(Item)
	If Not GradientForComponentWiseComparison Then
		HighlightMaximumValueForComponentWiseComparison = False;
		
	EndIf;
	
	SetVisibilityAccessibilityOfFormElements(ThisForm);
EndProcedure

&AtClient
Procedure OnlyColorOfMainBatchOnChange(Item)
	If Not OnlyColorOfMainBatch Then
		GradientForComponentWiseComparison = False;
		HighlightMaximumValueForComponentWiseComparison = False;
		
	EndIf;
	
	SetVisibilityAccessibilityOfFormElements(ThisForm);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	ClosingResult  = New Structure("DecorationSettingStorage, 
		|OnlyColorOfMainBatch,
		|GradientForComponentWiseComparison,
		|HighlightMaximumValueForComponentWiseComparison,
		|DisplayValuePointMarkers,
		|DisplayAMarkerOfForecastPoints,
		|ShowLegend,
		|DisplayChartCaptions,
		|ChartBorder,
		|ChartSmoothingMode,
		|ValueScaleMode,
		|Include_2Zero");
		
	ClosingResult.Insert("DecorationSettingStorage", 
		DecorationSettingStorageServer());
	ClosingResult.Insert("OnlyColorOfMainBatch", 
		OnlyColorOfMainBatch);
	ClosingResult.Insert("GradientForComponentWiseComparison", 
		GradientForComponentWiseComparison); // The name of the form's props is different from the name of the property
	ClosingResult.Insert("HighlightMaximumValueForComponentWiseComparison", 
		HighlightMaximumValueForComponentWiseComparison); // The name of the form's props is different from the name of the property
	ClosingResult.Insert("DisplayValuePointMarkers", 
		DisplayValuePointMarkers);
	ClosingResult.Insert("DisplayAMarkerOfForecastPoints", 
		DisplayAMarkerOfForecastPoints);
	ClosingResult.Insert("ShowLegend", 
		ShowLegend);
	ClosingResult.Insert("DisplayChartCaptions", 
		DisplayChartCaptions);
	ClosingResult.Insert("ChartBorder", 
		ChartBorder);
	ClosingResult.Insert("ChartSmoothingMode", 
		ChartSmoothingMode);
	ClosingResult.Insert("ValueScaleMode", 
		ValueScaleMode);
	ClosingResult.Insert("Include_2Zero", 
		Include_2Zero);
	
	Close(ClosingResult);
EndProcedure

&AtClient
Procedure SetStandardDesignSettings(Command)
	RestoreServerDesignSettings();
	
	SetVisibilityAccessibilityOfFormElements(ThisForm);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClientAtServerNoContext 
Function SetVisibilityAccessibilityOfFormElements(Form)
	Form.Items.ColorGroupForComponentByComponentComparison.Visible = Form.TheDesignOfAComponentByComponentComparisonIsAvailable;
	
	GradientAvailability = Form.TheDesignOfAComponentByComponentComparisonIsAvailable And Form.OnlyColorOfMainBatch;
	Form.Items.GradientForComponentWiseComparison.Enabled = GradientAvailability;
	
	AvailabilityOfMaximumValueAllocation = Form.TheDesignOfAComponentByComponentComparisonIsAvailable And Form.GradientForComponentWiseComparison;
	Form.Items.HighlightMaximumValueForComponentWiseComparison.Enabled = AvailabilityOfMaximumValueAllocation;
	
	Form.Items.DisplayValuePointMarkers.Visible = Form.DisplayPointMarkersAvailable;
	Form.Items.DisplayAMarkerOfForecastPoints.Visible = Form.DisplayAMarkerOfForecastPointsAvailable;
	
	Form.Items.DisplayChartCaptions.Visible = Form.DisplayChartCaptionsAvailable;
	Form.Items.ChartBorder.Visible = Form.ChartBorderIsAvailable;
	Form.Items.ChartSmoothingMode.Visible = Form.ChartSmoothingModeAvailable;
	
	Form.Items.Include_2Zero.Enabled = (Form.ValueScaleMode = PredefinedValue("Enum.ChartValueScaleMode.Auto"));
EndFunction

#EndRegion

#Region Other

&AtServer 
Procedure RestoreServerDesignSettings(DecorationSettingStructure = Undefined)
	If Not DecorationSettingStructure = Undefined Then
		DecorationSettingStorage = DecorationSettingStructure.DecorationSettingStorage; // ValueStorage
		
		If Not DecorationSettingStorage = Undefined 
			And Not DecorationSettingStorage.Get() = Undefined Then
			
			StructureOfColorSettings = DecorationSettingStorage.Get();
		Else
			DecorationSettingStructure = Catalogs.AnalysisOptionsOfTargetValues.DefaultDesignSettings();
			
			StructureOfColorSettings = DecorationSettingStructure.DecorationSettingStorage.Get();
		EndIf;	
	Else
		DecorationSettingStructure = Catalogs.AnalysisOptionsOfTargetValues.DefaultDesignSettings();
		
		StructureOfColorSettings = DecorationSettingStructure.DecorationSettingStorage.Get();
	EndIf;
	
	FillPropertyValues(ThisForm, DecorationSettingStructure);
	
	Colors = StructureOfColorSettings.Colors;
	
	MainSeriesColor = Colors["Value"];
	ForecastColor = Colors["Prediction"];
	TargetValueColor = Colors["TargetValue_"];
	ColorPositiveDeviation = Colors["PositiveVariance"];
	ColorNegativeDeviation = Colors["NegativeVariance"];
	ColorOfTheToleranceZone = Colors["AcceptableDeviationZone"];
EndProcedure

&AtServer 
Function DecorationSettingStorageServer()
	DecorationSettingStructure = New Structure;
	
	SetOfColors = New Map;
	SetOfColors.Insert("Value", MainSeriesColor);
	SetOfColors.Insert("Prediction", ForecastColor);
	SetOfColors.Insert("TargetValue_", TargetValueColor);
	SetOfColors.Insert("PositiveVariance", ColorPositiveDeviation);
	SetOfColors.Insert("NegativeVariance", ColorNegativeDeviation);
	SetOfColors.Insert("AcceptableDeviationZone", ColorOfTheToleranceZone);
	
	DecorationSettingStructure.Insert("Colors", SetOfColors);
	
	Return New ValueStorage(DecorationSettingStructure);
EndFunction

&AtClient
Procedure TheRegimeOfTheScaleOfValuesMinimumOnChange(Item)
	ValueScaleModeWhenChanging(Item);
EndProcedure

&AtClient
Procedure AutoValueScaleModeOnChange(Item)
	ValueScaleModeWhenChanging(Item);
EndProcedure

&AtClient 
Procedure ValueScaleModeWhenChanging(Item)
	If ValueScaleMode <> PredefinedValue("Enum.ChartValueScaleMode.Auto") Then
		Include_2Zero = False;
	EndIf;
	
	SetVisibilityAccessibilityOfFormElements(ThisForm);
EndProcedure

#EndRegion

#EndRegion
