#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;

	SetRequiredSettings(UserSettingsModified);
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		#Region UpdatingSettlements
		SetPrivilegedMode(True);
		FilterFields = ARAPAllocationServerCall.DefaultSelectionFields();
		FilterFields.Insert("Period", "ReportPeriod");
		AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
		JobName = ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob();
		ARAPAllocationServerCall.RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties, JobName);
		SetPrivilegedMode(False);
		#EndRegion
	EndIf;
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		#Region CheckingSettlements
		InformationRegisters.JobsForAllocatingCustomersARAP.DisplayRelevanceOfCalculation(ResultDocument, AuxProperties);
		#EndRegion
	EndIf;
	OutputProcessor.Output(CompositionProcessor);
	
	AuxiliaryParameters = New Array;
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryParameters);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	ShowSalesParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ShowSales_");
	If ShowSalesParameter <> Undefined 
		And ShowSalesParameter.Value = Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ShowSales_", 1);
		UserSettingsModified = True;
	EndIf;
	
	ListOfTypesOfSettlementDocuments = New ValueList;
	ListOfTypesOfSettlementDocuments.Add(Type("DocumentRef.CustomerInvoiceServices"));
	ListOfTypesOfSettlementDocuments.Add(Type("DocumentRef.RedemptionOfGoodsByCustodian"));
	ListOfTypesOfSettlementDocuments.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));
	ListOfTypesOfSettlementDocuments.Add(Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany"));
	ListOfTypesOfSettlementDocuments.Add(Type("DocumentRef.CustomerInvoice"));
	ListOfTypesOfSettlementDocuments.Add(Type("DocumentRef.CustomerInvoiceIntercompany"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "APARDocumentTypes", ListOfTypesOfSettlementDocuments);
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

#EndRegion

#EndIf
