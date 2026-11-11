#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithClient" Then
			
			GenerateParametersStateOfSettlementsWithClient(Parameters.CommandParameter, ThisForm, Parameters);
			
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithClientOnDocuments" Then
			
			CommandParameter = Parameters.CommandParameter;
			
			SettingsStructure = ReportSettings(CommandParameter);
			ValuesOfFunctionalOptions = SettingsStructure.ValuesOfFunctionalOptions;
			
			ExtendedOrder = ValuesOfFunctionalOptions.UseAdvancedFeaturesOfSalesOrder;
			
			ThisIsOrder = TypeOf(CommandParameter[0]) = Type("DocumentRef.SalesOrder")
				Or TypeOf(CommandParameter[0]) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer");
			
			If ExtendedOrder And ThisIsOrder Then
				ExtendedOrder = Not Common.ObjectAttributeValue(CommandParameter[0], "ThisIsOrderAsInvoice");
			EndIf;
			
			VariantKey = ?(Not ExtendedOrder And ThisIsOrder,
				NameOfVariantKeyDependsOnFlag("CalculationStateForCalculationObjectSimplifiedContext", ValuesOfFunctionalOptions.BaseVersion),
				NameOfVariantKeyDependsOnFlag("StateOfCalculationsForObjectOfCalculationsContext", ValuesOfFunctionalOptions.BaseVersion));
			
			ThisForm.ParametersForm.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
			
			If SettingsStructure.Property("FiltersStructure") Then
				For Each KeyAndValue In SettingsStructure.FiltersStructure Do
					SetFixedSelection(KeyAndValue.Key, KeyAndValue.Value);
				EndDo;
			EndIf;
			
			Parameters.VariantKey = VariantKey;
			ThisForm.CurrentVariantKey = VariantKey;
			
		EndIf;
		
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;
	
	ARAPAccountingServer.ReplaceCustomerSettlementDocuments(ParametersForm);
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More details - See ReportsOverridable.BeforeLoadVariantAtServer 
// .
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
// 
// Parameters:
//  ThisForm                         - ClientApplicationForm - Report form
//  NewDCUserSettings - DataCompositionSettings - 
//                                        Custom settings to upload to The Settings Composer.
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCUserSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer);
	
	NewDCUserSettings = FormSettingsComposer.UserSettings;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	Calculations = DataCompositionSchema.DataSets["Calculations"]; // DataCompositionSchemaDataSetUnion -  
	Calculations.Items.SettlementBalances.Query = QueryTextSettlementBalances();
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);

	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	ARAPAccountingServer.DisplayWarningAboutEndOfOfflinePaymentSupport(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	If GetFunctionalOption("UseSimplifiedPaymentSchemeInSales") Then
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, "PrepaymentBeforeProvision");
	EndIf;

EndProcedure

Procedure ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UseSimplifiedPaymentSchemeInSales") Then
		DataCompositionServer.DisableSelectedFieldInUserSettings(FormSettingsComposer, "PrepaymentBeforeProvision");
	EndIf;
	
EndProcedure

Function QueryTextSettlementBalances()
	
	QueryTexts        = New Array;
	RequestTextsForOrders = New Array;
	
	QueryTexts.Add(
	"SELECT ALLOWED DISTINCT
	|	Segments.Partner AS Partner,
	|	TRUE AS FilterByPartnerSegmentIsUsed
	|INTO SelectionByPartnerSegment
	|	FROM
	|	InformationRegister.SegmentPartners AS Segments
	|{WHERE
	|	Segments.Segment.* AS PartnersSegment,
	|	Segments.Partner.* AS Partner}
	|	
	|INDEX BY
	|	Partner,
	|	FilterByPartnerSegmentIsUsed
	|");
	
	If AccessRight("Read", Metadata.Documents.SalesOrder) Then
		RequestTextsForOrders.Add(
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Status AS Status,
		|	DocumentData.Partner AS Partner,
		|	DocumentData.Terms AS Terms,
		|	DocumentData.Contract AS Contract,
		|	DocumentData.Terms.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Counterparty AS Counterparty,
		|	DocumentData.DocumentAmount AS DocumentAmount,
		|	DocumentData.AmountPrepaymentBeforeGoodsIssue AS AmountPrepaymentBeforeGoodsIssue,
		|	DocumentData.AmountOfPrepaymentBeforeShipment AS AmountOfPrepaymentBeforeShipment
		|FROM
		|	Document.SalesOrder AS DocumentData
		|");
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
		RequestTextsForOrders.Add(
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Status AS Status,
		|	DocumentData.Partner AS Partner,
		|	DocumentData.Terms AS Terms,
		|	DocumentData.Contract AS Contract,
		|	DocumentData.Terms.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Counterparty AS Counterparty,
		|	DocumentData.ReplacementAmount AS DocumentAmount,
		|	DocumentData.AmountPrepaymentBeforeGoodsIssue AS AmountPrepaymentBeforeGoodsIssue,
		|	DocumentData.AmountOfPrepaymentBeforeShipment AS AmountOfPrepaymentBeforeShipment
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
		|");
	EndIf;
	
	
	If AccessRight("Read", Metadata.Documents.MaterialProviderOrder2_5) Then
		RequestTextsForOrders.Add(
		"SELECT
		|	DocumentData.Ref                                 AS Ref,
		|	DocumentData.Status                                 AS Status,
		|	DocumentData.Partner                                AS Partner,
		|	VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
		|	DocumentData.Contract                                AS Contract,
		|	DocumentData.FinancialAccountingGroup                 AS FinancialAccountingGroup,
		|	DocumentData.Currency                                 AS Currency,
		|	DocumentData.Organization                            AS Organization,
		|	DocumentData.Counterparty                             AS Counterparty,
		|	DocumentData.DocumentAmount                         AS DocumentAmount,
		|	DocumentData.AmountPrepaymentBeforeGoodsIssue               AS AmountPrepaymentBeforeGoodsIssue,
		|	DocumentData.AmountOfPrepaymentBeforeShipment              AS AmountOfPrepaymentBeforeShipment
		|FROM
		|	Document.MaterialProviderOrder2_5 AS DocumentData
		|");
	EndIf;
	If AccessRight("Read", Metadata.Documents.CustomerInvoice) Then
		RequestTextsForOrders.Add(
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	CASE WHEN DocumentData.Status = VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment) THEN
		|		VALUE(Enum.SalesOrderStatuses.ToSupply)
		|	ELSE
		|		VALUE(Enum.SalesOrderStatuses.Closed)
		|	END AS Status,
		|	DocumentData.Partner AS Partner,
		|	DocumentData.Terms AS Terms,
		|	DocumentData.Contract AS Contract,
		|	DocumentData.Terms.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Counterparty AS Counterparty,
		|	DocumentData.AmountARAP AS DocumentAmount,
		|	0 AS AmountPrepaymentBeforeGoodsIssue,
		|	SUM(ISNULL(ScheduleStages.AmountARAP,0)) AS AmountOfPrepaymentBeforeShipment
		|FROM
		|	Document.CustomerInvoice AS DocumentData
		|		LEFT JOIN Document.CustomerInvoice.PaymentScheduleSteps AS ScheduleStages
		|		ON DocumentData.Ref = ScheduleStages.Ref
		|			AND ScheduleStages.PaymentOption IN (VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment),
		|													VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision))
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Terms.FinancialAccountingGroup
		|");
	EndIf;
	
	QueryText = StrConcat(RequestTextsForOrders, TMCommonUse.QuerySeparatorInJoin());
	QueryText = RequestSchemes.SetSelectionOfAllowedRecords(QueryText, True);
	QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, "ARAPObjects");
	QueryTexts.Add(QueryText);
	
	QueryTexts.Add(
	"SELECT ALLOWED
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccounting.ARAPObject AS SalesOrder,
	|	CASE
	|		WHEN CustomersARAPAccounting.ARAPObject.Object REFS Catalog.CounterpartyContracts
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SettlementsUnderContract,
	|	CustomersARAPAccounting.Currency AS Currency,
	|	DimensionByPartners.Partner AS Partner,
	|	DimensionByPartners.Organization AS Organization,
	|	DimensionByPartners.Counterparty AS Counterparty,
	|	DimensionByPartners.Contract AS Contract,
	|	CASE WHEN NOT CustomersARAPAccounting.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionByPartners.LineOfBusiness
	|		ELSE CustomersARAPAccounting.ARAPObject.LineOfBusiness
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN CustomersARAPAccounting.SumClosingBalance > 0
	|			THEN CustomersARAPAccounting.SumClosingBalance
	|		ELSE 0
	|	END AS CustomerAccountsReceivable,
	|	CASE
	|		WHEN CustomersARAPAccounting.SumClosingBalance < 0
	|			THEN -CustomersARAPAccounting.SumClosingBalance
	|		ELSE 0
	|	END AS AccountsPayableOfCompany,
	|	CustomersARAPAccounting.SumClosingBalance AS DebtBalance,
	|	CustomersARAPAccounting.BeingPaidClosingBalance AS BeingPaid,
	|	CASE
	|		WHEN CustomersARAPAccounting.AmountDueClosingBalance > 0
	|			THEN CustomersARAPAccounting.AmountDueClosingBalance
	|		ELSE 0
	|	END AS AmountDue,
	|	CASE
	|		WHEN CustomersARAPAccounting.AmountDueClosingBalance < 0
	|			AND (CustomersARAPAccounting.ARAPObject.Object REFS Document.ReturnOfGoodsFromCustomer
	|				OR CustomersARAPAccounting.ARAPObject.Object REFS Document.RequestForReturnOfGoodsFromCustomer)
	|			THEN -CustomersARAPAccounting.AmountDueClosingBalance
	|		ELSE 0
	|	END AS ForCashReturn,
	|	CASE
	|		WHEN CustomersARAPAccounting.ToShipClosingBalance < 0
	|			THEN -CustomersARAPAccounting.ToShipClosingBalance
	|		ELSE 0
	|	END AS ToShip,
	|	CASE
	|		WHEN CustomersARAPAccounting.BeingShippedClosingBalance > 0
	|			THEN CustomersARAPAccounting.BeingShippedClosingBalance
	|		ELSE 0
	|	END AS BeingShipped,
	|	CASE
	|		WHEN ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0) > 0
	|				AND CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance
	|					< ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue,0)
	|			THEN OrderDocument.AmountPrepaymentBeforeGoodsIssue - (CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance)
	|		ELSE 0
	|	END AS PrepaymentBeforeProvision,
	|	CASE
	|		WHEN ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0) > 0
	|				AND ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0) > 0
	|				AND CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance
	|					< ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|			THEN OrderDocument.AmountOfPrepaymentBeforeShipment
	|		WHEN ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0) > 0
	|				AND CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance
	|					< ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0) + ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|				AND CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance
	|					>= ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|			THEN OrderDocument.AmountOfPrepaymentBeforeShipment + OrderDocument.AmountPrepaymentBeforeGoodsIssue - (CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance)
	|		ELSE 0
	|	END AS PrepaymentBeforeShipment,
	|	CASE
	|		WHEN CustomersARAPAccounting.ARAPObject.Object <> UNDEFINED
	|				AND OrderDocument.Ref IS NULL 
	|				AND CustomersARAPAccounting.AmountDueClosingBalance > 0
	|			THEN CustomersARAPAccounting.AmountDueClosingBalance
	|		WHEN CustomersARAPAccounting.AmountDueReceipt - ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|				- ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0) > 0
	|			AND CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance <=
	|				ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0) + ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|			THEN CustomersARAPAccounting.AmountDueReceipt - ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|					- ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0)
	|		WHEN CustomersARAPAccounting.AmountDueReceipt - ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|				- ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0) > 0
	|			AND CustomersARAPAccounting.AmountDueReceipt - CustomersARAPAccounting.AmountDueClosingBalance
	|				> ISNULL(OrderDocument.AmountOfPrepaymentBeforeShipment, 0) + ISNULL(OrderDocument.AmountPrepaymentBeforeGoodsIssue, 0)
	|			THEN CustomersARAPAccounting.AmountDueClosingBalance
	|		ELSE 0
	|	END AS CreditPlanned
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(, ) AS CustomersARAPAccounting
	|		LEFT JOIN ARAPObjects AS OrderDocument
	|		ON CustomersARAPAccounting.ARAPObject.Object = OrderDocument.Ref
	|		{INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionByPartners.DimensionKey}
	|WHERE
	|	DimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|	AND (CustomersARAPAccounting.AmountDueClosingBalance <> 0 
	|			OR CustomersARAPAccounting.ToShipClosingBalance <> 0
	|			OR CustomersARAPAccounting.BeingShippedClosingBalance <> 0
	|			OR CustomersARAPAccounting.SumClosingBalance <> 0)
	|{WHERE
	|	(DimensionByPartners.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|");
	
	Return StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
EndFunction

Procedure GenerateParametersStateOfSettlementsWithClient(CommandParameter, ThisForm, Parameters)
	
	FormParameters = ThisForm.ParametersForm;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		ThisIsArray = True;
	Else
		ThisIsArray = False;
	EndIf;
	
	If ThisIsArray Then
		ThereAreSubordinatePartners = False;
		For Each CommandParameterElement In CommandParameter Do
			If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
				ThereAreSubordinatePartners = True;
				Break;
			EndIf;
		EndDo;
	Else
		ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameter);
	EndIf;
	
	ThisIsBasic = GetFunctionalOption("BaseVersion");
	
	VariantKey = ThisForm.CurrentVariantKey;
	
	If ThereAreSubordinatePartners Then
		FormParameters.PurposeUseKey = "Partners_Group";
		Parameters.PurposeUseKey = "Partners_Group";
		VariantKey = NameOfVariantKeyDependsOnFlag("StatusOfSettlementsWithClientsContext", ThisIsBasic);
	Else
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		If ThisIsArray And CommandParameter.Count() = 1 Then
			VariantKey = NameOfVariantKeyDependsOnFlag("StatusOfSettlementsWithClientContext", ThisIsBasic);
		Else
			VariantKey = NameOfVariantKeyDependsOnFlag("StatusOfSettlementsWithClientsContext", ThisIsBasic);
		EndIf;
	EndIf;
	Parameters.VariantKey = VariantKey;
	ThisForm.CurrentVariantKey = VariantKey;
	
	FilterValue = CommandParameter; 
	DCComparisonType = DataCompositionComparisonType.Equal;
	If ThisIsArray Then
		FilterValue = New ValueList;
		FilterValue.LoadValues(CommandParameter);
		If ThereAreSubordinatePartners Then
			DCComparisonType = DataCompositionComparisonType.InListByHierarchy;
		Else 
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
	ElsIf ThereAreSubordinatePartners Then
		DCComparisonType = DataCompositionComparisonType.InHierarchy;
	EndIf;
	CommonClientServer.SetFilterItem(
		SettingsComposer.FixedSettings.Filter,
		"Partner",
		FilterValue,
		DCComparisonType,,
		True);
	
EndProcedure

Function ReportSettings(CommandParameter)
	
	ValuesOfFunctionalOptions = New Structure;
	ValuesOfFunctionalOptions.Insert("UseAdvancedFeaturesOfSalesOrder", 
	                                     GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	ValuesOfFunctionalOptions.Insert("BaseVersion", GetFunctionalOption("BaseVersion"));
	
	Types = New Array;
	Types.Add(Type("DocumentRef.ReturnOfGoodsFromCustomer"));
	Types.Add(Type("DocumentRef.RedemptionOfGoodsByCustodian"));
	Types.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	Types.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));
	Types.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	Types.Add(Type("DocumentRef.SaleAdjustment"));
	Types.Add(Type("DocumentRef.CustomerInvoice"));
	Types.Add(Type("DocumentRef.ReturnablePackagingRedemptionByCustomer"));
	Types.Add(Type("DocumentRef.CustomerInvoiceServices"));
	Types.Add(Type("DocumentRef.SalesOrder"));
	Types.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("ValuesOfFunctionalOptions", ValuesOfFunctionalOptions);
	SettingsStructure.Insert("FiltersStructure",
	                           ARAPAccountingServer.StructureOfReportSelectionsSettlementsWithClients(CommandParameter,
	                                                                                        "StatusOfCustomersARAP",
	                                                                                         "StateOfSettlementsWithClientOnDocuments", 
	                                                                                         Types));
	Return SettingsStructure;
	
EndFunction

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "StatusOfCustomersARAP" Then
		Return "StatusOfSettlementsWithClientsIsBasic";
	ElsIf VariantKeyName = "StateOfCalculationsForObjectOfCalculationsContext" Then
		Return "StateOfCalculationsForObjectOfCalculationsContextBasic";
	ElsIf VariantKeyName = "StatusOfSettlementsWithClientContext" Then
		Return "StateOfSettlementsWithClientContextBasic";
	ElsIf VariantKeyName = "StatusOfSettlementsWithClientsContext" Then
		Return "StateOfSettlementsWithCustomersContextBasic";
	ElsIf VariantKeyName = "CalculationStateForCalculationObjectSimplifiedContext" Then
		Return "StateOfCalculationsForObjectOfCalculationsSimplifiedContextBasic";
	EndIf;
	
EndFunction

Procedure SetFixedSelection(FieldName, Value)
	
	FilterValue = Value;
	DCComparisonType = DataCompositionComparisonType.Equal;
	If TypeOf(Value) = Type("Array") Then
		FilterValue = New ValueList;
		FilterValue.LoadValues(Value);
		DCComparisonType = DataCompositionComparisonType.InList;
	EndIf;
	CommonClientServer.SetFilterItem(
		SettingsComposer.FixedSettings.Filter,
		FieldName,
		FilterValue,
		DCComparisonType,,
		True);
	
EndProcedure

#EndRegion

#EndIf