#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	BudgetProfile = DataCompositionClientServer.GetParameter(SettingsComposer, "BudgetProfile").Value;
	If Not ValueIsFilled(BudgetProfile) Then
		Raise NStr("vi = 'Báo cáo được dùng để sử dụng từ dạng ngân sách.';
					|ru = 'Отчет предназначен для использования из вида бюджета.';
					|en = 'You can use the report from the budget profile.'; fa = 'You can use the report from the budget profile.';
					|it = 'Отчет предназначен для использования из вида бюджета.';
					|pl = 'You can use the report from the budget profile.';
					|tr = 'Raporun bütçe profili olarak kullanılması amaçlandı'");
	EndIf;
	
	GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
	
	StructureOfBudgetColumns = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(BudgetProfile);
	StructureOfReportDescription = BudgetReportingCacheCalculationServer.DescriptionOfReport(BudgetProfile,
	                                                                             StructureOfBudgetColumns,
	                                                                             GenerationMode);
	TableOfElements = BudgetReportingCacheCalculationServer.TableOfOperandsRequiringCalculationOfCellData(StructureOfReportDescription);
	TableOfElements = TableOfElements.Unload();
	TableOfElements.Columns.Add("NoIssues");
	TableOfElements.FillValues(False, "NoIssues");
	If Not TableOfElements.Count() Then
		TableOfElements.Add().NoIssues = True;
	EndIf;
	
	ExternalSets = New Structure("TableOfElements", TableOfElements);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, , True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
EndProcedure

#EndRegion

#EndIf
