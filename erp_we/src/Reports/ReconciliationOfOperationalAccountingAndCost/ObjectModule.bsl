#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	AddWarningAboutReportGenerationFeatures(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Procedure AddWarningAboutReportGenerationFeatures(ResultDocument)
	
	Period = BegOfMonth(DataCompositionClientServer.GetParameter(SettingsComposer, "Period").Value);
	
	If Not CalculationOfCostCached.CostCalculationIsPossible(Period) Then
		
		WarningText = 
			NStr("vi = 'Sử dụng báo cáo chỉ khi bật sử dụng kế toán giá vốn.';
				|ru = 'Отчет используется только при включенном учете себестоимости.';
				|en = 'The report is used only when the cost accounting is on.'; fa = 'The report is used only when the cost accounting is on.';
				|it = 'Il report viene utilizzato solo quando è abilitata la contabilità dei costi.';
				|pl = 'Raport jest używany tylko wtedy, gdy włączone jest księgowanie kosztów własnych.';
				|tr = 'Rapor yalnızca maliyet muhasebesi etkinleştirildiğinde kullanılır.'");
		
	ElsIf Not CalculationOfCostCached.BatchAccountingVersion22(Period) Then
		
		WarningText = 
			NStr("vi = 'Sử dụng báo cáo chỉ khi bật sử dụng kế toán theo lô, phiên bản 2.2.';
				|ru = 'Отчет используется только при включенном партионном учете версии 2.2.';
				|en = 'The report is used only with enabled lot accounting of version 2.2.'; fa = 'The report is used only with enabled lot accounting of version 2.2.';
				|it = 'Il report viene utilizzato solo quando è inclusa la contabilità parziale della versione 2.2';
				|pl = 'Raport jest używany tylko wtedy, gdy włączone jest ewidencja partii w wersji 2.2.';
				|tr = 'Rapor yalnızca lot muhasebesi sürüm 2.2 etkinleştirildiğinde kullanılır.'");
		
	Else
		
		// The report is formed without features.
		WarningText = "";
		
	EndIf;
	
	WarningTable_ = New SpreadsheetDocument;
	AreaWarning = WarningTable_.Area(1,1,1,1);
	
	AreaWarning.Text 	 = TrimAll(WarningText);
	AreaWarning.TextColor = StyleColors.NegativeTextColor;
	
	ResultDocument.InsertArea(
		AreaWarning,
		ResultDocument.Area(1,1,1,1),
		SpreadsheetDocumentShiftType.Vertical);
	
EndProcedure

#EndRegion

#EndIf
