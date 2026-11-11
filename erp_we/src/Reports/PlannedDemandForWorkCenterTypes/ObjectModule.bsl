#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	// Additional command
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.Filter.Insert("ProductionPlan", Parameters.CommandParameter);
		
		Scenario = Parameters.CommandParameter.Scenario;
		If Not Scenario.UseForMaterialsPlanning Then
			
			MessageText = NStr("vi = 'Kịch bản ""%Scenario%"" không bao gồm việc tính toán nhu cầu dự tính!';
								|ru = 'В сценарии ""%Scenario%"" не включен расчет плановых потребностей!';
								|en = 'The scenario ""%Scenario%"" does not have the planned demands calculation enabled!'; fa = 'The scenario ""%Scenario%"" does not have the planned demands calculation enabled!';
								|it = 'Nello scenario ""%Scenario%"" non è incluso il calcolo di fabbisogni pianificati!';
								|pl = 'Do scenariusza ""%Scenario%"" nie dodano obliczenia planowanych zapotrzebowań!';
								|tr = '""%Scenario%"" senaryosuna planlanan gereksinimlerin hesaplanması dahil değildir!'");
			MessageText = StrReplace(MessageText, "%Scenario%", Scenario);
			Common.MessageToUser(MessageText, , , , Cancel);
			
		EndIf;
		
	EndIf;
	
	If Parameters.Property("Details")
		And Parameters.Details <> Undefined Then
		
		ReplaceOption = False;
		
		If Parameters.Details.UsedSettings.Structure.Count() > 0 Then
			
			ProductProductsField = New DataCompositionField("ProductsItems");
			FieldCharacteristicOfProduction = New DataCompositionField("ItemVariant");
			
			GroupFields = Parameters.Details.UsedSettings.Structure[0].GroupFields; // DataCompositionGroupFields - 
			
			For Each Group In GroupFields.Items Do
			
				If Group.Field = ProductProductsField 
					Or Group.Field = FieldCharacteristicOfProduction Then
					
					ReplaceOption = True;
					Break;
				
				EndIf; 
			
			EndDo; 
		
		EndIf; 
		
		ThisIsContextualReport = False;
		
		// filling in the decryption parameters
		If IsTempStorageURL(Parameters.Details.Data) Then
		
			DetailsData = GetFromTempStorage(Parameters.Details.Data);
			
			If Not DetailsData.Settings.AdditionalProperties.Property("CurrentVariantKey")
				Or Not (DetailsData.Settings.AdditionalProperties.CurrentVariantKey = "PlannedNeedForTypesOfRCTs"
				Or DetailsData.Settings.AdditionalProperties.CurrentVariantKey = "Main") Then
			
				Return;
			
			EndIf; 
			ThisIsContextualReport = DetailsData.Settings.AdditionalProperties.CurrentVariantKey = "PlannedNeedForTypesOfRCTs";
		EndIf; 
		
		If Not ReplaceOption Then
			Return;
		EndIf; 
		
		If Parameters.Property("VariantKey") Then
			Parameters.VariantKey = ?(ThisIsContextualReport, "DecodingContext", "Details");
		EndIf; 
		If Parameters.Property("PurposeUseKey") Then
			Parameters.PurposeUseKey = ?(ThisIsContextualReport, "DecodingContext", "Details");
		EndIf;
		
		ThisForm.CurrentVariantKey = ?(ThisIsContextualReport, "DecodingContext", "Details");
		
		ThisForm.DetailsMode = False;
		ThisForm.ReportSettings.EditOptionsAllowed = False;
		ThisForm.ReportSettings.OptionRef = ReportsOptions.ReportVariant(ThisForm.ReportSettings.ReportRef, ThisForm.CurrentVariantKey);
		
	EndIf;
	

EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	If FormSettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey") 
		And ((FormSettingsComposer.Settings.AdditionalProperties.CurrentVariantKey = "PlannedNeedForTypesOfRCTs"
		And ThisForm.CurrentVariantKey = "DecodingContext")
		Or (FormSettingsComposer.Settings.AdditionalProperties.CurrentVariantKey = "Main"
		And ThisForm.CurrentVariantKey = "Details")) Then
		
		Scenario = Undefined;
		FormSettingsComposer.Settings.AdditionalProperties.Property("Scenario", Scenario);
		
		ReportObject = Reports.PlannedDemandForWorkCenterTypes.Create();
		Variant = ReportObject.DataCompositionSchema.SettingVariants.Find(ThisForm.CurrentVariantKey);
		
		DataCompositionClientServer.FillInElements(Variant.Settings.DataParameters,	FormSettingsComposer.Settings.DataParameters);
		DataCompositionClientServer.CopyElements(Variant.Settings.Filter,			FormSettingsComposer.Settings.Filter, False);
		
		FormSettingsComposer.LoadSettings(Variant.Settings);
		
		If Scenario <> Undefined Then
		
			DataCompositionClientServer.SetParameter(
				FormSettingsComposer, 
				"Scenario", 
				Scenario);
		
		EndIf; 
		
	EndIf; 
	
	FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	
	If ThisForm.ParametersForm.Filter.Property("ProductionPlan") Then
		
		FormSettingsComposer.Settings.AdditionalProperties.Insert(
			"Scenario", 
			Common.ObjectAttributeValue(ThisForm.ParametersForm.Filter.ProductionPlan, "Scenario"));
		
		DataCompositionClientServer.SetParameter(
			FormSettingsComposer, 
			"Scenario", 
			FormSettingsComposer.Settings.AdditionalProperties.Scenario);
		
		
	EndIf; 
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, StandardProcessing)
	
	CurrentVariantKey = SettingsComposer.Settings.AdditionalProperties.CurrentVariantKey;
	Scenario = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Scenario");
	
	If CurrentVariantKey = "Main"
	   And Scenario <> Undefined
	   And ValueIsFilled(Scenario.Value) Then
		
		// Checking the structure of the report settings for the presence of charts in it and their use
		If SettingsComposer.Settings.Structure.Count() > 2
		   And Type(SettingsComposer.Settings.Structure.Get("1")) = Type("DataCompositionChart")
		   And SettingsComposer.Settings.Structure.Get("1").Name = "Chart required_2 availability"
		   And SettingsComposer.Settings.Structure.Get("1").Use = True
		   And Type(SettingsComposer.Settings.Structure.Get("2")) = Type("DataCompositionGroup")
		   And SettingsComposer.Settings.Structure.Get("2").Name = "Group diagrams required_3 capacity_1"
		   And SettingsComposer.Settings.Structure.Get("2").Use = True
		   And Type(SettingsComposer.Settings.Structure.Get("2").Structure.Get("0")) = Type("DataCompositionChart")
		   And SettingsComposer.Settings.Structure.Get("2").Structure.Get("0").Name = "Charts required_3 capacity_1"
		   And SettingsComposer.Settings.Structure.Get("2").Structure.Get("0").Use = True Then
			
			// The required capacity diagram is grouped by the data layout field of the Work Center view
			DiagramOfRequiredAvailability = SettingsComposer.Settings.Structure.Get("1");
			GroupingDiagramsOfRequiredCapacities = SettingsComposer.Settings.Structure.Get("2");
			DiagramsOfRequiredCapacities = GroupingDiagramsOfRequiredCapacities.Structure.Get("0");
			
			TDChartType = DiagramOfRequiredAvailability.OutputParameters.Items.Find("ChartType");
			CompositionOfTDChartCaptions = TDChartType.NestedParameterValues.Find("ChartType.LabelType");
			PlacementOfLegendOfTDChart = TDChartType.NestedParameterValues.Find("ChartType.LegendPlacement");
			TDChartLine = TDChartType.NestedParameterValues.Find("ChartType.ValuesReferenceLines"); 
			EdgingTDChart = TDChartType.NestedParameterValues.Find("ChartType.Outline");
			ChartHeaderTD = DiagramOfRequiredAvailability.OutputParameters.Items.Find("Title");
			
			TypeOfTMDiagrams = DiagramsOfRequiredCapacities.OutputParameters.Items.Find("ChartType");
			CompositionOfTMChartCaptions = TypeOfTMDiagrams.NestedParameterValues.Find("ChartType.LabelType");
			PlacementOfTMChartLegends = TypeOfTMDiagrams.NestedParameterValues.Find("ChartType.LegendPlacement");
			TMChartLine = TypeOfTMDiagrams.NestedParameterValues.Find("ChartType.ValuesReferenceLines");
			EdgingTMDiagrams = TypeOfTMDiagrams.NestedParameterValues.Find("ChartType.Outline");
			UsingNonNumericTMChartValues = TypeOfTMDiagrams.NestedParameterValues.Find("ChartType.NonnumericValueUse");
			TitleOfTMDiagrams = GroupingDiagramsOfRequiredCapacities.OutputParameters.Items.Find("Title");
			
			MaximumPower = DiagramsOfRequiredCapacities.Selection.SelectionAvailableFields.Items.Find("MaximumPower");
			
			CompositionOfTDChartCaptions.Use = True;
			CompositionOfTDChartCaptions.Value = ChartLabelType.Value;
			PlacementOfLegendOfTDChart.Use = True;
			PlacementOfLegendOfTDChart.Value = DataCompositionChartLegendPlacement.Top;
			TDChartLine.Use = True;
			EdgingTDChart.Use = True;
			EdgingTDChart.Value = True;
			ChartHeaderTD.Use = True;
			ChartHeaderTD.Value = NStr("vi = 'Biểu đồ khả năng tiếp cận cần thiết của các dạng NLSX';
										|ru = 'Диаграмма требуемой доступности видов РЦ';
										|en = 'Required work center type availability'; fa = 'Required work center type availability';
										|it = 'Diagramma della disponibilità richiesta dei tipi di centri di lavoro';
										|pl = 'Diagram wymaganej dostępności rodzajów CP';
										|tr = 'İM türlerinin gerekli erişim grafiği'");
			
			CompositionOfTMChartCaptions.Use = True;
			CompositionOfTMChartCaptions.Value = ChartLabelType.Value;
			PlacementOfTMChartLegends.Use = True;
			PlacementOfTMChartLegends.Value = DataCompositionChartLegendPlacement.Top;
			TMChartLine.Use = True;
			EdgingTMDiagrams.Use = True;
			EdgingTMDiagrams.Value = True;
			UsingNonNumericTMChartValues.Use = True;
			UsingNonNumericTMChartValues.Value = NonnumericChartValueUse.Skip;
			TitleOfTMDiagrams.Use = True;
			TitleOfTMDiagrams.Value = NStr("vi = 'Biểu đồ phân tích công suất cho các dạng NLSX';
											|ru = 'Диаграммы анализа мощностей видов РЦ';
											|en = 'Capacity analysis of work center types'; fa = 'Capacity analysis of work center types';
											|it = 'Diagramma dell''analisi della capacità del tipi di centri di lavoro';
											|pl = 'Diagramy analizy mocy rodzajów CP';
											|tr = 'İM türlerinin kapasite boyut grafikleri'");
			
			ChartLine = TDChartLine.Value; // ChartReferenceLines - 
			AddingInformationLineToTDDiagram = ChartLine.Add();
			AddingInformationLineToTDDiagram.Value = 100;
			AddingInformationLineToTDDiagram.ToolTip = NStr("vi = '100% có sẵn';
															|ru = '100% введённой доступности';
															|en = '100% of entered availability'; fa = '100% of entered availability';
															|it = '100% di disponibilità inserita';
															|pl = '100% wprowadzonej dostępności';
															|tr = '100% girilmiş uygunluk'");
			AddingInformationLineToTDDiagram.SemitransparencyPercent = 50;
			AddingInformationLineToTDDiagram.Color = New Color(0, 150, 150);
			
			ChartLine = TMChartLine.Value; // ChartReferenceLines -
			AddingInformationLineToTMDiagrams = ChartLine.Add();
			AddingInformationLineToTMDiagrams.Value = MaximumPower.Field;
			AddingInformationLineToTMDiagrams.ToolTip = NStr("vi = 'Công suất tối đa';
															|ru = 'Максимальная мощность';
															|en = 'Maximum capacity'; fa = 'حداکثر ظرفیت';
															|it = 'Максимальная мощность';
															|pl = 'Maximum capacity';
															|tr = 'Azami güç'");
			AddingInformationLineToTMDiagrams.SemitransparencyPercent = 50;
			AddingInformationLineToTMDiagrams.Color = New Color(0, 150, 150);
		EndIf;
		
		Planning.PlannedNeedForTypesOfRCInLayoutOfResult(SettingsComposer, ResultDocument, StandardProcessing);
		
	ElsIf CurrentVariantKey = "Main" Then
		If SettingsComposer.Settings.Structure.Count() > 2
		   And Type(SettingsComposer.Settings.Structure.Get("1")) = Type("DataCompositionChart")
		   And SettingsComposer.Settings.Structure.Get("1").Name = "Chart required_2 availability"
		   And SettingsComposer.Settings.Structure.Get("1").Use = True
		   And Type(SettingsComposer.Settings.Structure.Get("2")) = Type("DataCompositionGroup")
		   And SettingsComposer.Settings.Structure.Get("2").Name = "Group diagrams required_3 capacity_1"
		   And SettingsComposer.Settings.Structure.Get("2").Use = True
		   And Type(SettingsComposer.Settings.Structure.Get("2").Structure.Get("0")) = Type("DataCompositionChart")
		   And SettingsComposer.Settings.Structure.Get("2").Structure.Get("0").Name = "Charts required_3 capacity_1"
		   And SettingsComposer.Settings.Structure.Get("2").Structure.Get("0").Use = True Then
			
			SettingsComposer.Settings.Structure.Get("1").Use = False;
			SettingsComposer.Settings.Structure.Get("2").Use = False;
			SettingsComposer.Settings.Structure.Get("2").Structure.Get("0").Use = False;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf