#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Report.AnalysisOfVariancesInGoodsCost.ObjectModule.OnComposeResult");
	
	StandardProcessing = False;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	SetReportParameters(ReportSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ResultDocument.TableHeight);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Procedure for configuring report parameters.
//
// Parameters:
//	ReportSettings - Structure - report settings
//	NewDCSettings - DataCompositionSettings - customize the layout data
//	NewDCUserSettings - DataCompositionUserSettings - custom setting 
//
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	
	ParameterDataCost = DataCompositionSchema.Parameters.Find("CostData");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOption.VariantKey = "AnalysisOfDeviationsInCostOfGoodsByEnterprise" Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		EnterpriseParameter.Value = True;
		
	Else
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(4, NStr("vi = 'Theo tiền tệ kế toán tài chính';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = False;
		
	EndIf;
	
	ParameterDataCost.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
	 Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	CostDataParameterValue = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("CostData"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(CostDataParameterValue.UserSettingID);
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

Function GetPredefinedOption(Val Variant)
	
	OptionsKeys = New Array;
	OptionsKeys.Add("AnalysisOfDeviationsInCostOfGoodsByOrganizations");
	OptionsKeys.Add("AnalysisOfDeviationsInCostOfGoodsByEnterprise");
	
	// If the option is not specified, then we will take the first one from the default list
	If Variant = Undefined Then
		Return New Structure("VariantKey", OptionsKeys[0]);
	EndIf;
	
	While OptionsKeys.Find(Variant.VariantKey) = Undefined
		And ValueIsFilled(Variant.Parent) Do
		Variant = Variant.Parent;
	EndDo;
	
	Return Variant;
	
EndFunction

// Set report parameters.
// 
// Parameters:
//  ReportSettings - Structure - the report settings.
Procedure SetReportParameters(ReportSettings)
	
	// A general list for selection of operations.
	// The farm is gradually filling up. of operations for the specified categories.
	BusinessOfOperationsByCategory = New Array();
	
	// Purchases.
	BusinessProcurementOperations = New Array();
	BusinessProcurementOperations.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessProcurementOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	BusinessProcurementOperations.Add(Enums.BusinessTransactions.ReverseOfReceipt);
	BusinessProcurementOperations.Add(Enums.BusinessTransactions.DebitNoteForPreviousPeriod);
	BusinessProcurementOperations.Add(Enums.BusinessTransactions.OBEntryGoodsCostVariances);
	BusinessProcurementOperations.Add(Enums.BusinessTransactions.GoodsRecordingAsReceived);
	
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.ReverseOfReceipt);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.DebitNoteForPreviousPeriod);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.OBEntryGoodsCostVariances);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.GoodsRecordingAsReceived);
	
	ReportSettings.DataParameters.SetParameterValue("BusinessProcurementOperations", BusinessProcurementOperations);
	
	// Additional expenses.
	BusinessOperationsOfOperationsAdditionalExpensesAmount = New Array();
	BusinessOperationsOfOperationsAdditionalExpensesAmount.Add(Enums.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification);
	BusinessOperationsOfOperationsAdditionalExpensesAmount.Add(Enums.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification);
	BusinessOperationsOfOperationsAdditionalExpensesAmount.Add(Enums.BusinessTransactions.ImportFromEAEU);
	BusinessOperationsOfOperationsAdditionalExpensesAmount.Add(Enums.BusinessTransactions.ExpenseAllocationToCost);
	
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.ImportFromEAEU);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.ExpenseAllocationToCost);
	
	ReportSettings.DataParameters.SetParameterValue("BusinessOperationsOfOperationsAdditionalExpensesAmount", BusinessOperationsOfOperationsAdditionalExpensesAmount);
	
	// Product release.
	BusinessOfOperationRelease = New Array();
	BusinessOfOperationRelease.Add(Enums.BusinessTransactions.TransferOfProductsFromProduction);
	
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.TransferOfProductsFromProduction);
	
	ReportSettings.DataParameters.SetParameterValue("BusinessOfOperationRelease", BusinessOfOperationRelease);
	
	// Transfer of deviations in the cost of goods.
	BusinessOfOperationsOfTransferOfDeviations = New Array();
	BusinessOfOperationsOfTransferOfDeviations.Add(Enums.BusinessTransactions.TransferOfVariancesInGoodsCost);
	
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.TransferOfVariancesInGoodsCost);
	
	ReportSettings.DataParameters.SetParameterValue("BusinessOfOperationsOfTransferOfDeviations", BusinessOfOperationsOfTransferOfDeviations);
	
	// Sales.
	BusinessSalesOfOperations = New Array();
	BusinessSalesOfOperations.Add(Enums.BusinessTransactions.SaleToCustomer);
	BusinessSalesOfOperations.Add(Enums.BusinessTransactions.ReverseOfSale);
	
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.SaleToCustomer);
	BusinessOfOperationsByCategory.Add(Enums.BusinessTransactions.ReverseOfSale);
	
	ReportSettings.DataParameters.SetParameterValue("BusinessSalesOfOperations", BusinessSalesOfOperations);
	ReportSettings.DataParameters.SetParameterValue("BusinessOfOperationsByCategory", BusinessOfOperationsByCategory);
	
EndProcedure

#EndRegion

#EndIf