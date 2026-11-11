#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	UserSettingsModified = False;
	SetRequiredSettings(UserSettingsModified);
	
	DataSetAssociation = DataCompositionSchema.DataSets.Union;
	ProcessDataSetQueryTexts(DataSetAssociation);
	
	ReportSettings = SettingsComposer.GetSettings();
	ResultOfParameterProcessing = ProcessReportParameters(ReportSettings);
	
	// performing data layout
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,,
		DetailsData,
		True,,
		AuxiliaryTemporaryTables(ResultOfParameterProcessing.ParameterDocumentSelectionOption,
			ResultOfParameterProcessing.BeginOfPeriod,
			ResultOfParameterProcessing.EndOfPeriod));
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema,
		SettingsComposer,
		ResultDocument,
		AuxiliaryReportParameters());
	
	If UserSettingsModified Then
		
		SettingsComposer.UserSettings.AdditionalProperties.Insert(
			"UserSettingsModified",
			True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
// 	Form - ClientApplicationForm - Report form
// 	VariantKey - String - The name of a predefined or unique identifier of a custom version of the report
// 	Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.AfterLoadSettingsInLinker = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
// 	Context - Arbitrary - Parameters of the context in which the report is used
// 	SchemaKey - String - ID of the current Configuration Composer schema
// 	VariantKey - String - The name of a predefined or unique identifier of a custom version of the report
// 	NewDCSettings - DataCompositionSettings - Report Variant Settings
// 	NewDCUserSettings - DataCompositionUserSettings - custom setting
//
Procedure BeforeImportSettingsToComposer(Context,
	SchemaKey,
	VariantKey,
	NewDCSettings,
	NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	SchemaKey = VariantKey;
	FieldHeaders = ParameterizableFieldHeaders();
	
	DataCompositionServer.SetHeadersOfSelectedFields(NewDCSettings.Selection.Items, FieldHeaders);
	
	If TypeOf(NewDCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return;
	EndIf;
	
	SettingID = NewDCSettings.Selection.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		If FoundSettingElement <> Undefined Then 
			DataCompositionServer.SetHeadersOfSelectedFields(FoundSettingElement.Items, FieldHeaders);
		EndIf;
		
	EndIf;
	
EndProcedure

// Called after loading new settings. Used to change the layout scheme.
//
// Parameters:
// 	AdditionalParameters - Structure
//
Procedure AfterLoadSettingsInLinker(AdditionalParameters) Export
	
	SetLimitsOnFunctionalOptions();
	
	// setting available values for data parameters
	For Each AvailableParameter In SettingsComposer.Settings.DataParameters.AvailableParameters.Items Do
		
		If AvailableParameter.Parameter = New DataCompositionParameter("FilterState") Then
			
			ChoiceList = Enums.SalesOrderStates.ListOfAvailableStatesOfOrders();
			ChoiceList.Insert(0, "All", NStr("vi = 'Tất cả';
											|ru = 'Все';
											|en = 'All'; fa = 'همه';
											|it = 'All';
											|pl = 'All';
											|tr = 'Tümü'"));
			
			AvailableParameter.AvailableValues = ChoiceList;
			AvailableParameter.AvailableValues.AvailableValues = Undefined;
			
		ElsIf AvailableParameter.Parameter = New DataCompositionParameter("FilterDueDate_2") Then
			
			ListOfOptionsForDueDate = New ValueList;
			ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(ListOfOptionsForDueDate);
			ListOfOptionsForDueDate.Insert(0, "All", NStr("vi = 'Tất cả';
															|ru = 'Все';
															|en = 'All'; fa = 'همه';
															|it = 'All';
															|pl = 'All';
															|tr = 'Tümü'"));
			
			SearchForInteractiveElement = ListOfOptionsForDueDate.FindByValue("ExpiresOnDate");
			If SearchForInteractiveElement <> Undefined Then
				ListOfOptionsForDueDate.Delete(SearchForInteractiveElement);
			EndIf;
			
			AvailableParameter.AvailableValues = ListOfOptionsForDueDate;
			AvailableParameter.AvailableValues.AvailableValues = Undefined;
			
		EndIf;
		
	EndDo;
	
	// setting the available values for selection elements
	For Each FilterElement In SettingsComposer.Settings.FilterAvailableFields.Items Do
		
		If FilterElement.Field = New DataCompositionField("TypeOfOrder_") Then
			
			FilterElement.AvailableValues = ListOfAvailableTypesOfOrders();
			FilterElement.AvailableValues.AvailableValues = Undefined;
			
			FilterElement.AvailableCompareTypes.Clear();
			FilterElement.AvailableCompareTypes.Add(DataCompositionComparisonType.Equal);
			FilterElement.AvailableCompareTypes.Add(DataCompositionComparisonType.NotEqual);
			
		ElsIf FilterElement.Field = New DataCompositionField("ShipmentStatus")
			Or FilterElement.Field = New DataCompositionField("StateOfRegistration")
			Or FilterElement.Field = New DataCompositionField("StateOfTransferOfOwnership")
			Or FilterElement.Field = New DataCompositionField("AcceptanceState")
			Or FilterElement.Field = New DataCompositionField("StateOfReturnsProcessing") Then
			
			FilterElement.AvailableValues = ListOfAvailableStatesOfGoodsByOrder(FilterElement.Field);
			FilterElement.AvailableValues.AvailableValues = Undefined;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	FixedPeriodSetting_ = FixedParameterSetting("RequestPeriod");
	If FixedPeriodSetting_.Use = True Then
		
		UsesPeriodSetting = CustomParameterSetting("RequestPeriod");
		UsesPeriodSetting.Use = True;
		UsesPeriodSettingValue = UsesPeriodSetting.Value; // StandardPeriod
		FixedPeriodSettingValue_ = FixedPeriodSetting_.Value; // StandardPeriod
		UsesPeriodSettingValue.StartDate = FixedPeriodSettingValue_.StartDate;
		UsesPeriodSettingValue.EndDate = FixedPeriodSettingValue_.EndDate;
		
		FixedPeriodSetting_.Use = False;
		
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	DataCompositionSchema.Templates[0].Template[0].Cells[0].Items[0].Value = TitleTextWarning();
	
EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;
	
EndFunction

Function FixedParameterSetting(ParameterName)
	
	DataParameter = SettingsComposer.FixedSettings.DataParameters.Items.Find(ParameterName);
	Return DataParameter;
	
EndFunction

Function CustomParameterSetting(ParameterName)
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		
		CustomSettingParameter = SettingsComposer.UserSettings.Items.Find(
			DataParameter.UserSettingID);
		
		If CustomSettingParameter <> Undefined Then
			Return CustomSettingParameter;
		Else
			Return DataParameter;
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

// Returns the list of order types available for selection.
//
// Returns:
// 	ValueList of Type
//
Function ListOfAvailableTypesOfOrders()
	
	Result = New ValueList;
	Result.Add(Type("DocumentRef.SourceDocument"));
	
	If GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers") Then
		Result.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	EndIf;
	
	If GetFunctionalOption("UseCreditNotes") Then
		Result.Add(Type("DocumentRef.SaleAdjustment"));
	EndIf;
	
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
		Result.Add(Type("DocumentRef.GoodsShipmentToCustomer"));
	EndIf;
	
	
	If GetFunctionalOption("UseMaterialProviderOrder2_5") Then
		Result.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	EndIf;
	If GetFunctionalOption("UseSalesOrders") Then
		Result.Add(Type("DocumentRef.SalesOrder"));
	EndIf;
	
	
	If GetFunctionalOption("UseSubcontractOrders2_5") Then
		Result.Add(Type("DocumentRef.SubcontractOrder2_5"));
	EndIf;
	Result.SortByValue();
	
	Return Result;
	
EndFunction

// Returns a list of States of goods available for selection by order.
//
// Parameters:
// 	LayoutField - DataCompositionField - field for setting the available selection values
//
// Returns:
// 	ValueList of EnumRef.StateOfRegisteringDocumentsByReference
//
Function ListOfAvailableStatesOfGoodsByOrder(LayoutField)
	
	Result = New ValueList;
	
	If LayoutField = New DataCompositionField("ShipmentStatus") Then
		
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PendingCreation,
			NStr("vi = 'Chưa giao hàng';
				|ru = 'Не отгружено';
				|en = 'Not shipped'; fa = 'ارسال‌نشده';
				|it = 'Not shipped';
				|pl = 'Not shipped';
				|tr = 'Sevk edilmedi'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PartiallyRegistered,
			NStr("vi = 'Đã giao một phần';
				|ru = 'Отгружено частично';
				|en = 'Partially shipped'; fa = 'Partially shipped';
				|it = 'Partially shipped';
				|pl = 'Partially shipped';
				|tr = 'Kısmen sevk edildi'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.Decorated,
			NStr("vi = 'Đã giao';
				|ru = 'Отгружено';
				|en = 'Shipped'; fa = 'ارسال‌شده';
				|it = 'Shipped';
				|pl = 'Shipped';
				|tr = 'Sevk edildi'"));
		
	ElsIf LayoutField = New DataCompositionField("AcceptanceState") Then
		
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PendingCreation,
			NStr("vi = 'Chưa tiếp nhận';
				|ru = 'Не принято';
				|en = 'Not received'; fa = 'دریافت نشده';
				|it = 'Non accettato';
				|pl = 'Nie przyjęto';
				|tr = 'Kabul edilmedi'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PartiallyRegistered,
			NStr("vi = 'Đã tiếp nhận một phần';
				|ru = 'Принято частично';
				|en = 'Partially accepted'; fa = 'Partially accepted';
				|it = 'Partially accepted';
				|pl = 'Partially accepted';
				|tr = 'Kısmen kabul edildi'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.Decorated,
			NStr("vi = 'Đã tiếp nhận';
				|ru = 'Принято';
				|en = 'Accepted'; fa = 'پذیرفته‌شده';
				|it = 'Accepted';
				|pl = 'Accepted';
				|tr = 'Kabul edildi'"));
		
	ElsIf LayoutField = New DataCompositionField("StateOfTransferOfOwnership") Then
		
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PendingCreation,
			NStr("vi = 'Chưa thực hiện';
				|ru = 'Не выполнен';
				|en = 'Not fulfilled'; fa = 'اجرا نشده';
				|it = 'Not fulfilled';
				|pl = 'Not fulfilled';
				|tr = 'Tamamlanmadı'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PartiallyRegistered,
			NStr("vi = 'Đã thực hiện một phần';
				|ru = 'Выполнен частично';
				|en = 'Partially completed'; fa = 'تکمیل جزئی';
				|it = 'Partially completed';
				|pl = 'Partially completed';
				|tr = 'Kısmen tamamlandı'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.Decorated,
			NStr("vi = 'Đã thực hiện';
				|ru = 'Выполнен';
				|en = 'Completed'; fa = 'تکمیل‌شده';
				|it = 'Completed';
				|pl = 'Completed';
				|tr = 'Tamamlandı'"));
		
	ElsIf LayoutField = New DataCompositionField("StateOfRegistration")
		Or LayoutField = New DataCompositionField("StateOfReturnsProcessing") Then
		
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PendingCreation,
			NStr("vi = 'Chưa lập chứng từ';
				|ru = 'Не оформлено';
				|en = 'Not registered'; fa = 'ثبت‌نشده';
				|it = 'Not registered';
				|pl = 'Not registered';
				|tr = 'Oluşturulmadı'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.PartiallyRegistered,
			NStr("vi = 'Đã lập một phần chứng từ';
				|ru = 'Оформлено частично';
				|en = 'Partially registered'; fa = 'ثبت‌شده به‌صورت جزئی';
				|it = 'Partially registered';
				|pl = 'Partially registered';
				|tr = 'Kısmen oluşturuldu'"));
		Result.Add(Enums.StateOfRegisteringDocumentsByReference.Decorated,
			NStr("vi = 'Đã lập chứng từ';
				|ru = 'Оформлено';
				|en = 'Registered'; fa = 'ثبت‌شده';
				|it = 'Registered';
				|pl = 'Registered';
				|tr = 'Oluşturuldu'"));
		
	EndIf;
	
	Return Result;
	
EndFunction

// Adds a selection based on the date of the event.
//
// Parameters:
// 	ReportSettings - DataCompositionSettings
// 	EventDate - Date
//
Procedure AddSelectionByEventDate(ReportSettings, EventDate)
	
	GroupSelectionByEventDate = DataCompositionClientServer.AddSelectionGroup(ReportSettings.Filter.Items,
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		GroupSelectionByEventDate,
		"EventDate",
		DataCompositionComparisonType.LessOrEqual,
		EventDate);
		
	CommonClientServer.AddCompositionItem(
		GroupSelectionByEventDate,
		"EventDate",
		DataCompositionComparisonType.NotEqual,
		Date(1, 1, 1));
	
EndProcedure

// Returns the text of a warning about the relevance of report indicators with hyperlinks to objects.
//
// Returns:
// 	FormattedString
//
Function TitleTextWarning()
	
	CostLines_ = New Array;
	CostLines_.Add(NStr("vi = 'Các chỉ số giá vốn trong báo cáo có thể chưa được cập nhật,';
						|ru = 'Показатели себестоимости в отчете могут быть неактуальными,';
						|en = 'The cost indicators in the report may be irrelevant'; fa = 'The cost indicators in the report may be irrelevant';
						|it = 'The cost indicators in the report may be irrelevant';
						|pl = 'The cost indicators in the report may be irrelevant';
						|tr = 'Rapordaki maliyet göstergeleri güncel olmayabilir,'"));
	CostLines_.Add(NStr("vi = 'nếu dữ liệu nằm trong các kỳ chưa kết chuyển.';
						|ru = 'если выводимые данные находятся в незакрытых периодах.';
						|en = 'if the output data is in unclosed periods.'; fa = 'if the output data is in unclosed periods.';
						|it = 'if the output data is in unclosed periods.';
						|pl = 'if the output data is in unclosed periods.';
						|tr = 'çıkış verisi kapalı olmayan periyotlarda olması durumunda.'"));
	CostLines_.Add(NStr("vi = 'Để kiểm soát việc kết chuyển cuối kỳ, hãy sử dụng chỗ làm việc';
						|ru = 'Для контроля закрытия периодов воспользуйтесь рабочим местом';
						|en = 'Use the workplace to control period-end closing.'; fa = 'Use the workplace to control period-end closing.';
						|it = 'Use the workplace to control period-end closing.';
						|pl = 'Use the workplace to control period-end closing.';
						|tr = 'Dönem kapanışlarını kontrol etmek için iş yerlerini kullanın'"));
	CostLines_.Add(Metadata.Subsystems.FinancialResultAndControlling.Synonym
		+ " - "
		+ Metadata.Subsystems.FinancialResultAndControlling.Subsystems.MonthEndTransactions.Synonym
		+ " - ");
	
	TextCostPrice = StrConcat(CostLines_, Chars.LF);
	
	FormattedCostLine = New FormattedString(
		New FormattedString(" ", Chars.LF),
		New FormattedString(PictureLib.Warning),
		New FormattedString("  "),
		New FormattedString(TextCostPrice),
		New FormattedString(Metadata.DataProcessors.MonthEndClosingOperations.Synonym,,,,
			?(AccessRight("Use", Metadata.DataProcessors.MonthEndClosingOperations),
				GetURL(DataProcessors.MonthEndClosingOperations.Create()),
				Undefined)),
		New FormattedString(Chars.LF + " "));
	
	Return FormattedCostLine;
	
EndFunction

// Sets a restriction on the use of the data layout field.
//
// Parameters:
// 	FieldName - String
// 	Restrict - Boolean
//
Procedure SetFieldUsageLimit(FieldName, Restrict = True)
	
	For Each Current_Set In DataCompositionSchema.DataSets Do
		
		CurrentField = Current_Set.Fields.Find(FieldName);
		If CurrentField <> Undefined Then
			
			CurrentField.UseRestriction.Group = Restrict;
			CurrentField.UseRestriction.Field = Restrict;
			CurrentField.UseRestriction.Order = Restrict;
			CurrentField.UseRestriction.Condition = Restrict;
			
			CurrentField.AttributeUseRestriction.Group = Restrict;
			CurrentField.AttributeUseRestriction.Field = Restrict;
			CurrentField.AttributeUseRestriction.Order = Restrict;
			CurrentField.AttributeUseRestriction.Condition = Restrict;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets restrictions on the use of fields depending on the values of functional options.
//
Procedure SetLimitsOnFunctionalOptions()
	
	If GetFunctionalOption("TradeManagement") Then
		SetFieldUsageLimit("ExciseTaxAmount");
	EndIf;
	
	If Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle") Then
		
		SetFieldUsageLimit("InTransitNumberOfTurnover");
		SetFieldUsageLimit("EnRouteAmountOfTurnover");
		SetFieldUsageLimit("InWayOfWeight");
		SetFieldUsageLimit("EnRouteVolume");
		
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagementSystem")
		Or Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue") Then
		
		SetFieldUsageLimit("ItRemainsToCollect");
		SetFieldUsageLimit("AssemblyInProgress");
		SetFieldUsageLimit("Assembled");
		SetFieldUsageLimit("ToBeShippedFromWarehouse");
		SetFieldUsageLimit("ShippedFromWarehouse");
		SetFieldUsageLimit("ItRemainsToShipFromWarehouse");
		
		SetFieldUsageLimit("ItRemainsToCollectWeight");
		SetFieldUsageLimit("WeightIsCollected");
		SetFieldUsageLimit("CollectedWeight");
		SetFieldUsageLimit("ToBeShippedFromWarehouseWeight");
		SetFieldUsageLimit("ShippedFromWarehouseWeight");
		SetFieldUsageLimit("ItRemainsToShipWeightFromWarehouse");
		
		SetFieldUsageLimit("ItRemainsToCollectVolume");
		SetFieldUsageLimit("AssemblyInProgressVolume");
		SetFieldUsageLimit("AssembledVolume");
		SetFieldUsageLimit("ToBeShippedFromWarehouseVolume");
		SetFieldUsageLimit("ShippedFromWarehouseVolume");
		SetFieldUsageLimit("ItRemainsToShipVolumeFromWarehouse");
		
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagementSystem")
		Or Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt") Then
		
		SetFieldUsageLimit("GoodsReceiptNotesToRegister");
		SetFieldUsageLimit("IssuedOrders");
		SetFieldUsageLimit("ItRemainsToIssueOrders");
		
		SetFieldUsageLimit("ToExecuteOrdersWeight");
		SetFieldUsageLimit("IssuedOrdersWeight");
		SetFieldUsageLimit("ItRemainsToIssueOrdersWeight");
		
		SetFieldUsageLimit("ToExecuteOrdersVolume");
		SetFieldUsageLimit("IssuedOrdersVolume");
		SetFieldUsageLimit("ItRemainsToIssueOrdersVolume");
		
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		SetFieldUsageLimit("Organization");
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		SetFieldUsageLimit("Warehouse");
	EndIf;
	
EndProcedure

// Returns the temporary table manager with auxiliary tables for generating the report.
//
// Parameters:
// 	FilterOption - Boolean
// 	BeginOfPeriod - Date
// 	EndOfPeriod - Date
//
// Returns:
// 	TempTablesManager
//
Function AuxiliaryTemporaryTables(FilterOption, BeginOfPeriod, EndOfPeriod)
	
	Result = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = Result;
	Query.SetParameter("FilterOption", FilterOption);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	RegisterTable.ReferenceOrder AS ReferenceOrder
	|INTO SelectionOfOrdersByPeriod
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS RegisterTable
	|WHERE
	|	CASE
	|		WHEN &FilterOption
	|			THEN Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		ELSE RegisterTable.ReferenceOrder IN
	|			(SELECT
	|				RegisterTable.Ref
	|			FROM
	|				InformationRegister.DocumentsRegistry AS RegisterTable
	|			WHERE
	|				RegisterTable.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|	END
	|
	|INDEX BY
	|	ReferenceOrder";
	
	Query.Execute();
	
	Return Result;
	
EndFunction

// Performs string substitutions in the query text of the dataset.
//
// Parameters:
// 	DataSet - DataCompositionSchemaDataSetQuery
//
Procedure PerformSubstitutionsOfExpressionsWeightVolume(DataSet)
	
	DataSet.Query = StrReplace(DataSet.Query,
		"&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"CatalogProducts.UnitOfMeasure",
			"CatalogProducts.Ref"));
	
	DataSet.Query = StrReplace(DataSet.Query,
		"&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"CatalogProducts.UnitOfMeasure",
			"CatalogProducts.Ref"));
	
EndProcedure

// Performs text processing of data set queries.
//
// Parameters:
// 	DataSetAssociation - DataCompositionSchemaDataSetUnion
//
Procedure ProcessDataSetQueryTexts(DataSetAssociation)
	
	PerformSubstitutionsOfExpressionsWeightVolume(DataSetAssociation.Items.ShipmentAndReturnReferences);
	PerformSubstitutionsOfExpressionsWeightVolume(DataSetAssociation.Items.GoodsForIssue);
	PerformSubstitutionsOfExpressionsWeightVolume(DataSetAssociation.Items.GoodsToReceive);
	PerformSubstitutionsOfExpressionsWeightVolume(DataSetAssociation.Items.ReasonsForCancellation);
	
EndProcedure

// Processes report parameters when composing the result.
//
// Parameters:
// 	ReportSettings - DataCompositionSettings
//
// Returns:
// 	Structure:
// 		* ParameterDocumentSelectionOption - Boolean
// 		* BeginOfPeriod - Date
// 		* EndOfPeriod - Date
//
Function ProcessReportParameters(ReportSettings)
	
	Result = New Structure;
	Result.Insert("ParameterDocumentSelectionOption", False);
	Result.Insert("BeginOfPeriod", Date(1, 1, 1));
	Result.Insert("EndOfPeriod", Date(1, 1, 1));
	
	// setting the data actuality parameter
	DateOfRelevanceParameter = DataCompositionClientServer.GetParameter(ReportSettings, "UpdateDate");
	DateOfRelevanceParameter.Value = BegOfDay(CurrentSessionDate());
	DateOfRelevanceParameter.Use = True;
	
	PeriodOfOrdersParameter = DataCompositionClientServer.GetParameter(
		ReportSettings,
		"RequestPeriod").Value; // StandardPeriod
	
	Result.BeginOfPeriod = BegOfDay(PeriodOfOrdersParameter.StartDate);
	Result.EndOfPeriod = EndOfDay(PeriodOfOrdersParameter.EndDate);
	
	// processing of the variantboradocument parameter
	Result.ParameterDocumentSelectionOption = DataCompositionClientServer.GetParameter(
		ReportSettings,
		"DocumentSelectionOption").Value; // Boolean
	
	If Result.ParameterDocumentSelectionOption Then
		
		DataCompositionClientServer.SetParameter(ReportSettings,
			"BeginOfPeriod",
			Result.BeginOfPeriod);
		
		DataCompositionClientServer.SetParameter(ReportSettings,
			"EndOfPeriod",
			Result.EndOfPeriod);
		
	EndIf;
	
	// processing of the selection parameter
	FilterDueDate_2 = DataCompositionClientServer.GetParameter(ReportSettings, "FilterDueDate_2");
	If FilterDueDate_2.Value = "All" Then
		
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "EventDate");
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "Overdue");
		
	ElsIf FilterDueDate_2.Value = "NotOverdue" Then
		
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "EventDate");
		DataCompositionClientServer.AddFilter(ReportSettings,
			"Overdue",
			False,
			DataCompositionComparisonType.Equal);
		
	ElsIf FilterDueDate_2.Value = "Overdue" Then
		
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "EventDate");
		DataCompositionClientServer.AddFilter(ReportSettings,
			"Overdue",
			True,
			DataCompositionComparisonType.Equal);
		
	ElsIf FilterDueDate_2.Value = "Today" Then
		
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "Overdue");
		AddSelectionByEventDate(ReportSettings, GeneralPurposeTMServerCall.SessionDate());
		
	ElsIf FilterDueDate_2.Value = "Tomorrow" Then
		
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "Overdue");
		AddSelectionByEventDate(ReportSettings, GeneralPurposeTMServerCall.SessionDate() + 86400);
		
	ElsIf FilterDueDate_2.Value = "TheDayAfterTomorrow" Then
		
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "Overdue");
		AddSelectionByEventDate(ReportSettings, GeneralPurposeTMServerCall.SessionDate() + 86400 * 2);
		
	ElsIf FilterDueDate_2.Value = "InAWeek" Then
		
		DataCompositionClientServer.DeleteSelection(ReportSettings.Filter, "Overdue");
		AddSelectionByEventDate(ReportSettings, GeneralPurposeTMServerCall.SessionDate() + 86400 * 7);
		
	EndIf;
	
	// processing of the Selection state parameter
	FilterState = DataCompositionClientServer.GetParameter(ReportSettings, "FilterState");
	If TypeOf(FilterState.Value) = Type("EnumRef.SalesOrderStates") Then
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"State",
			FilterState.Value,
			DataCompositionComparisonType.Equal);
		
	ElsIf FilterState.Value = "All" Then
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"State",
			Undefined,
			DataCompositionComparisonType.Equal,
			False);
		
	ElsIf FilterState.Value = "AllOpened" Then
		
		StatesList = New ValueList();
		StatesList.Add(Enums.SalesOrderStates.Closed);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"State",
			StatesList,
			DataCompositionComparisonType.NotInList);
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"DeletionMark",
			False,
			DataCompositionComparisonType.Equal);
		
	ElsIf FilterState.Value = "AllPaymentPending" Then
		
		StatesList = New ValueList();
		StatesList.Add(Enums.SalesOrderStates.PendingAdvanceBeforeSupply);
		StatesList.Add(Enums.SalesOrderStates.PendingPrepaymentBeforeShipment);
		StatesList.Add(Enums.SalesOrderStates.PendingPaymentAfterShipment);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingAdvanceOrReturnBeforeSupply);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPrepaymentOrReturnBeforeShipment);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPaymentOrReturnAfterShipment);
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"State",
			StatesList,
			DataCompositionComparisonType.InList);
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"DeletionMark",
			False,
			DataCompositionComparisonType.Equal);
		
	ElsIf FilterState.Value = "AllExecutionPending" Then
		
		StatesList = New ValueList();
		StatesList.Add(Enums.SalesOrderStates.PendingApproval);
		StatesList.Add(Enums.SalesOrderStates.ReadyForSupply);
		StatesList.Add(Enums.SalesOrderStates.PendingSupply);
		StatesList.Add(Enums.SalesOrderStates.ReadyToShip);
		StatesList.Add(Enums.SalesOrderStates.DuringShipment);
		StatesList.Add(Enums.SalesOrderStates.TransferOfTitleToGoodsIsExpected);
		StatesList.Add(Enums.SalesOrderStates.ReadyForClosure);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingApproval);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForSupply_);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingSupply);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForShipment);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.DuringShipment);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForSupply_);
		StatesList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForReturn);
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"State",
			StatesList,
			DataCompositionComparisonType.InList);
		
		DataCompositionClientServer.AddFilter(ReportSettings,
			"DeletionMark",
			False,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf