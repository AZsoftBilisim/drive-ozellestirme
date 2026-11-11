
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

#EndRegion

// Defines the composition of documents and business operations that are available for display in the workplace.
//
// Parameters:
//  FilterBusinessTransactions		 - ValueList - list of values of the enum type Link.Economic operations
//  FilterDocumentTypes				 - ValueList - list of values of the reference Link type.IDs of metadata objectsreferences
//  PurposeUseKey		 - String - key of the workplace for which the function is called.
// 
// Returns:
//   See TMCommonUse.NewTableBusinessOperationsAndDocuments 
//
Function InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey) Export
	
	BusinessTransactionsAndDocuments = BusinessTransactionsAndDocuments();
	
	If PurposeUseKey = "DocumentsBetweenCompaniesAll" Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments,
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	
	Return TableOfValuesAvailable;
	
EndFunction

#Region CreatingHyperlinkInProcurementDocumentLog

// Returns the text of the request that is used to get data on the reports issued
// on commissions between organizations.
//
// Parameters:
//	QueryOptions - Structure - request parameters.
//
// Returns:
//	String - the text of the request, which is used to obtain data on the reports issued
//		on commissions between organizations.
//
Function RequestTextCommissionReportsIssued(QueryOptions = Undefined) Export
	
	ThisIsHyperlinkCalculation = ValueIsFilled(QueryOptions) And QueryOptions.Property("ThisIsHyperlinkCalculation")
		And QueryOptions.ThisIsHyperlinkCalculation;
	
	QueryText = 
	"SELECT ALLOWED
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.GoodsOwner AS Consignor,
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.Organization AS Consignee,
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.CCDNumber AS CCDNumber,
	|	SUM(GoodsToBeRegisteredInReportsToConsignorTurnovers.CountTurnover) AS CountTurnover,
	|	SUM(GoodsToBeRegisteredInReportsToConsignorTurnovers.QuantityConsumedTurnover) AS QuantityConsumedTurnover
	|INTO VTKRegistrationTurnover
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Turnovers(
	|			&InitialBorder,
	|			&ConBorder,
	|			,
	|			InventoryOwnerAttribute.GoodsOwner REFS Catalog.Companies
	|				AND (InventoryOwnerAttribute.GoodsOwner = &Consignor
	|					OR NOT &SelectionByCommitteeIsEstablished)
	|				AND (InventoryOwnerAttribute.Organization = &Consignee
	|					OR NOT &SelectionByCommissionAgentIsEstablished)) AS GoodsToBeRegisteredInReportsToConsignorTurnovers
	|
	|GROUP BY
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.CCDNumber,
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.GoodsOwner,
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.Organization,
	|	GoodsToBeRegisteredInReportsToConsignorTurnovers.ItemsLocationAttributes
	|
	|INDEX BY
	|	Consignor,
	|	Consignee,
	|	ItemsLocationAttributes,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	ReportPreparationServices.ItemsLocationAttributes.StorageLocation	AS Consignor,
	|	ReportPreparationServices.Organization								AS Consignee,
	|	ReportPreparationServices.ItemsLocationAttributes					AS ItemsLocationAttributes
	|INTO TTServicesForRegistrationTurnover
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Turnovers(
	|			&InitialBorder,
	|			&ConBorder,
	|			,
	|			ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Organization)
	|			AND (ItemsLocationAttributes.StorageLocation = &Consignor
	|				OR NOT &SelectionByCommitteeIsEstablished)
	|			AND (Organization = &Consignee
	|				OR NOT &SelectionByCommissionAgentIsEstablished)) AS ReportPreparationServices
	|
	|INDEX BY
	|	Consignor,
	|	Consignee,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsTransferredToCommissionAgentBalance.Organization AS Consignor,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.StorageLocation AS Consignee,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Products AS Products,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Series AS Series,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Purpose AS Purpose,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|	GoodsTransferredToCommissionAgentBalance.CCDNumber AS CCDNumber,
	|	SUM(GoodsTransferredToCommissionAgentBalance.CountBalance) AS CountBalance
	|INTO TTTransferredBalances
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(
	|			&ConBorder,
	|			ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Organization)
	|				AND (Organization = &Consignor
	|					OR NOT &SelectionByCommitteeIsEstablished)
	|				AND (ItemsLocationAttributes.Organization = &Consignee
	|					OR NOT &SelectionByCommissionAgentIsEstablished)) AS GoodsTransferredToCommissionAgentBalance
	|
	|GROUP BY
	|	GoodsTransferredToCommissionAgentBalance.Organization,
	|	GoodsTransferredToCommissionAgentBalance.CCDNumber,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.ProductCostElement,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Purpose,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.StorageLocation,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Products,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Characteristic,
	|	GoodsTransferredToCommissionAgentBalance.ItemsLocationAttributes.Series
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose
	|	,ProductCostElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransmittedBalance.Consignor AS Consignor,
	|	TransmittedBalance.Consignee AS Consignee,
	|	InventoryLocationAttributeKeys.DimensionKey AS ItemsLocationAttributes,
	|	TransmittedBalance.CCDNumber AS CCDNumber,
	|	SUM(TransmittedBalance.CountBalance) AS CountBalance
	|INTO TTTransferredBalancesToAnalystsForClearance
	|FROM
	|	TTTransferredBalances AS TransmittedBalance
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS InventoryLocationAttributeKeys
	|		ON TransmittedBalance.Products = InventoryLocationAttributeKeys.Products
	|			AND TransmittedBalance.Characteristic = InventoryLocationAttributeKeys.Characteristic
	|			AND TransmittedBalance.Series = InventoryLocationAttributeKeys.Series
	|			AND TransmittedBalance.Purpose = InventoryLocationAttributeKeys.Purpose
	|			AND TransmittedBalance.Consignor = InventoryLocationAttributeKeys.StorageLocation
	|			AND TransmittedBalance.ProductCostElement = InventoryLocationAttributeKeys.ProductCostElement
	|
	|GROUP BY
	|	TransmittedBalance.CCDNumber,
	|	TransmittedBalance.Consignor,
	|	TransmittedBalance.Consignee,
	|	InventoryLocationAttributeKeys.DimensionKey
	|
	|INDEX BY
	|	Consignor,
	|	Consignee,
	|	ItemsLocationAttributes,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	ReportPreparationServices.ItemsLocationAttributes.StorageLocation	AS Consignor,
	|	ReportPreparationServices.Organization								AS Consignee,
	|	ReportPreparationServices.ItemsLocationAttributes					AS ItemsLocationAttributes
	|INTO TTServicesForRegistrationBalance
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(
	|			&ConBorder,
	|			ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Organization)
	|			AND (ItemsLocationAttributes.StorageLocation = &Consignor
	|				OR NOT &SelectionByCommitteeIsEstablished)
	|			AND (Organization = &Consignee
	|				OR NOT &SelectionByCommissionAgentIsEstablished)) AS ReportPreparationServices
	|
	|INDEX BY
	|	Consignor,
	|	Consignee,
	|	ItemsLocationAttributes";
	
	QueryTextTTSelectionsForRegistration =
	"SELECT TOP 1
	|	ToDesignOfTurnover.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	ToDesignOfTurnover.CCDNumber	AS CCDNumber,
	|	InventoryKinds.Ref			AS InventoryOwnerAttribute,
	|	TRUE						AS ThisIsAProduct
	|INTO TTSelectionsForRegistration
	|FROM
	|	VTKRegistrationTurnover AS ToDesignOfTurnover
	|		LEFT JOIN TTTransferredBalancesToAnalystsForClearance AS SubmittedByAnalystsForRegistration
	|		ON ToDesignOfTurnover.Consignor = SubmittedByAnalystsForRegistration.Consignor
	|			AND ToDesignOfTurnover.Consignee = SubmittedByAnalystsForRegistration.Consignee
	|			AND ToDesignOfTurnover.ItemsLocationAttributes = SubmittedByAnalystsForRegistration.ItemsLocationAttributes
	|			AND ToDesignOfTurnover.CCDNumber = SubmittedByAnalystsForRegistration.CCDNumber
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON ToDesignOfTurnover.Consignor = InventoryKinds.GoodsOwner
	|			AND ToDesignOfTurnover.Consignee = InventoryKinds.Organization
	|WHERE
	|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (ISNULL(SubmittedByAnalystsForRegistration.CountBalance, 0) > 0
	|				AND ToDesignOfTurnover.CountTurnover > 0
	|				AND &SelectBySale
	|			OR ISNULL(SubmittedByAnalystsForRegistration.CountBalance, 0) > 0
	|				AND ToDesignOfTurnover.QuantityConsumedTurnover > 0
	|				AND &SelectByDebit
	|			OR ToDesignOfTurnover.CountTurnover < 0
	|				AND &SelectBySale
	|			OR ToDesignOfTurnover.QuantityConsumedTurnover < 0
	|				AND &SelectByDebit)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	ServicesForRegistrationTurnover.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	UNDEFINED	AS CCDNumber,
	|	UNDEFINED	AS InventoryOwnerAttribute,
	|	FALSE			AS ThisIsAProduct
	|FROM
	|	TTServicesForRegistrationTurnover AS ServicesForRegistrationTurnover
	|		INNER JOIN TTServicesForRegistrationBalance AS BalanceProcessingServices
	|		ON ServicesForRegistrationTurnover.Consignor = BalanceProcessingServices.Consignor
	|			AND ServicesForRegistrationTurnover.Consignee = BalanceProcessingServices.Consignee
	|			AND ServicesForRegistrationTurnover.ItemsLocationAttributes = BalanceProcessingServices.ItemsLocationAttributes";
	
	If ThisIsHyperlinkCalculation Then
		QueryTextTTSelectionsForRegistration = StrReplace(QueryTextTTSelectionsForRegistration, "INTO TTSelectionsForRegistration", "");
	Else	
		QueryTextTTSelectionsForRegistration = StrReplace(QueryTextTTSelectionsForRegistration, "TOP 1", "");
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator() + QueryTextTTSelectionsForRegistration;
	
	If Not ThisIsHyperlinkCalculation Then 
		QueryText = QueryText + Common.QueryBatchSeparator() +
		"SELECT
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.Currency AS Currency,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.Organization AS Consignee,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.GoodsOwner AS Consignor,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.Contract AS Contract,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.PriceKind AS PriceKind,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.InventoryOwnerAttribute.VATTaxation AS VATTaxation,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.CCDNumber AS CCDNumber,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.CountTurnover AS CountTurnover,
		|	GoodsToBeRegisteredInReportsToConsignorTurnovers.QuantityConsumedTurnover AS QuantityConsumedTurnover
		|INTO VTKDesignTurnoverDetail
		|FROM
		|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Turnovers(
		|			&InitialBorder,
		|			&ConBorder,
		|			,
		|			(ItemsLocationAttributes, CCDNumber, InventoryOwnerAttribute) IN
		|				(SELECT
		|					TTSelectionsForRegistration.ItemsLocationAttributes,
		|					TTSelectionsForRegistration.CCDNumber,
		|					TTSelectionsForRegistration.InventoryOwnerAttribute
		|				FROM
		|					TTSelectionsForRegistration
		|				WHERE
		|					TTSelectionsForRegistration.ThisIsAProduct)) AS GoodsToBeRegisteredInReportsToConsignorTurnovers
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ToDesignOfTurnover.Currency AS Currency,
		|	ToDesignOfTurnover.Consignee AS Consignee,
		|	ToDesignOfTurnover.Consignor AS Consignor,
		|	ToDesignOfTurnover.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	ToDesignOfTurnover.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	ToDesignOfTurnover.Contract AS Contract,
		|	ToDesignOfTurnover.PriceKind AS PriceKind,
		|	ToDesignOfTurnover.CCDNumber AS CCDNumber,
		|	ToDesignOfTurnover.VATTaxation AS VATTaxation,
		|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
		|	&TextSalesReport AS DocumentType,
		|	ToDesignOfTurnover.CountTurnover AS CountBalance,
		|	0 AS QuantityConsumed
		|INTO GoodsForRegistration
		|FROM
		|	VTKDesignTurnoverDetail AS ToDesignOfTurnover
		|WHERE
		|	ToDesignOfTurnover.CountTurnover <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	ToDesignOfTurnover.Currency,
		|	ToDesignOfTurnover.Consignee,
		|	ToDesignOfTurnover.Consignor,
		|	ToDesignOfTurnover.ItemsLocationAttributes,
		|	ToDesignOfTurnover.InventoryOwnerAttribute,
		|	ToDesignOfTurnover.Contract,
		|	ToDesignOfTurnover.PriceKind,
		|	ToDesignOfTurnover.CCDNumber,
		|	ToDesignOfTurnover.VATTaxation,
		|	VALUE(Enum.BusinessTransactions.CommissionWriteOffReportIntercompany),
		|	&TextReportOnDebiting,
		|	0,
		|	ToDesignOfTurnover.QuantityConsumedTurnover
		|FROM
		|	VTKDesignTurnoverDetail AS ToDesignOfTurnover
		|WHERE
		|	ToDesignOfTurnover.QuantityConsumedTurnover <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	ServicesForRegistrationBalance.Currency,
		|	ServicesForRegistrationBalance.Organization,
		|	ServicesForRegistrationBalance.ItemsLocationAttributes.StorageLocation,
		|	ServicesForRegistrationBalance.ItemsLocationAttributes,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef),
		|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany),
		|	&TextSalesReport,
		|	ServicesForRegistrationBalance.CountBalance,
		|	0
		|FROM
		|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(
		|			&ConBorder,
		|			ItemsLocationAttributes IN
		|				(SELECT
		|					TTSelectionsForRegistration.ItemsLocationAttributes
		|				FROM
		|					TTSelectionsForRegistration
		|				WHERE
		|					NOT TTSelectionsForRegistration.ThisIsAProduct)) AS ServicesForRegistrationBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsForRegistration.Currency AS Currency,
		|	GoodsForRegistration.Consignee AS Consignee,
		|	GoodsForRegistration.Consignor AS Consignor,
		|	GoodsForRegistration.BusinessOperation AS BusinessOperation,
		|	GoodsForRegistration.DocumentType AS DocumentType,
		|	GoodsForRegistration.Contract AS Contract,
		|	GoodsForRegistration.PriceKind AS PriceKind,
		|	CASE
		|		WHEN GoodsForRegistration.VATTaxation <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN GoodsForRegistration.VATTaxation
		|		ELSE ISNULL(AccountingPolicies.DefaultVATTaxation, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|	END AS VATTaxation
		|FROM
		|	GoodsForRegistration AS GoodsForRegistration
		|		LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPolicies
		|		ON GoodsForRegistration.Consignor = AccountingPolicies.Organization";
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the text of the hyperlink for the transition from the document log to the workplace for processing Commission reports.
//
// Parameters:
//	Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//	FormattedString, Undefined - the text of the hyperlink of the transition to the workplace of registration of reports on the commission.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	BusinessTransactionsAndDocuments = Parameters.BusinessTransactionsAndDocuments;
	
	Filter = New Structure("Filter, PurposeUseKey", True, "CommissionReportIntercompany");
	BusinessOperationsReports = BusinessTransactionsAndDocuments.FindRows(Filter);
	
	If BusinessOperationsReports.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Filter = New Structure("Filter, FullDocumentName", True, "Document.CommissionReportIntercompany");
	SelectBySale = BusinessTransactionsAndDocuments.FindRows(Filter).Count() > 0;
	
	Filter = New Structure("Filter, FullDocumentName", True, "Document.CommissionWriteOffReportIntercompany");
	SelectByDebit = BusinessTransactionsAndDocuments.FindRows(Filter).Count() > 0;
	
	QueryText = RequestTextCommissionReportsIssued(Parameters);
	
	If Not ValueIsFilled(QueryText) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	HyperlinkText    = NStr("vi = 'Bảng kê hàng bán ký gửi';
							|ru = 'Отчеты по комиссии';
							|en = 'Commission reports'; fa = 'گزارش‌های حق‌العمل';
							|it = 'Report sulla commissione';
							|pl = 'Raporty o komisji';
							|tr = 'Komisyon raporları'");
	TextSalesReport = NStr("vi = 'Báo cáo bán hàng';
							|ru = 'Отчет о продажах';
							|en = 'Consignment sale'; fa = 'فروش امانی';
							|it = 'Report sulle vendite';
							|pl = 'Raport o sprzedaży';
							|tr = 'Satış raporu'");
	TextReportOnDebiting = NStr("vi = 'Báo cáo ghi giảm';
								|ru = 'Отчет о списании';
								|en = 'Stock adjustment'; fa = 'Stock adjustment';
								|it = 'Report sullo storno';
								|pl = 'Raport o rozchodzie';
								|tr = 'Gider yazma raporu'");
	
	Query.SetParameter("Consignor", Parameters.Organization);
	Query.SetParameter("SelectionByCommitteeIsEstablished", ValueIsFilled(Parameters.Organization));
	Query.SetParameter("Consignee", Undefined);
	Query.SetParameter("SelectionByCommissionAgentIsEstablished", False);
	Query.SetParameter("InitialBorder", Undefined);
	Query.SetParameter("ConBorder", Undefined);
	Query.SetParameter("TextSalesReport", TextSalesReport);
	Query.SetParameter("TextReportOnDebiting", TextReportOnDebiting);
	Query.SetParameter("SelectBySale", SelectBySale);
	Query.SetParameter("SelectByDebit", SelectByDebit);
	
	If Not Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText, , , ,
			"DataProcessor.LogOfIntercompanyDocuments.Form.RegisterCommissionReports");
	Else
		Return New FormattedString(HyperlinkText, , StyleColors.EmptyTableField, ,
			"DataProcessor.LogOfIntercompanyDocuments.Form.RegisterCommissionReports");
	EndIf;
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	BusinessTransactionsAndDocuments = BusinessTransactionsAndDocuments();
	FoundRows = BusinessTransactionsAndDocuments.FindRows(
		New Structure("PurposeUseKey", Parameters.PurposeUseKey));
	
	If FoundRows.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	//All lines with the same key must have the same workplace header 
	StringByUseDestinationKey = FoundRows[0];
	
	Return New FormattedString(StringByUseDestinationKey.WorkplaceTitle, , , ,
				"DataProcessor.LogOfIntercompanyDocuments.Form.ListForm");
EndFunction

#EndRegion

Function BusinessTransactionsAndDocuments()
	
	Var String, ReturnOfGoodsBetweenOrganizationsLine, LineReportOnCommissionBetweenOrganizations, LineReportOnCommissionBetweenOrganizationsOnWriteOffs, LineTransferOfGoodsBetweenOrganizations, BusinessTransactionsAndDocuments;
	
	BusinessTransactionsAndDocuments = TMCommonUse.NewTableBusinessOperationsAndDocuments();
	
	// IntercompanyGoodsReturn
	
	ReturnOfGoodsBetweenOrganizationsLine = BusinessTransactionsAndDocuments.Add();
	
	String = ReturnOfGoodsBetweenOrganizationsLine;
	String.PurposeUseKey = "IntercompanyGoodsReturn";
	String.BusinessOperation       = Enums.BusinessTransactions.IntercompanyGoodsReturn;
	String.AddButtonCreate       = True;
	String.DocumentType                = Type("DocumentRef.IntercompanyGoodsReturn");
	String.FullDocumentName          = "Document.IntercompanyGoodsReturn";
	String.WorkplaceTitle      = NStr("vi = 'Chứng từ giữa các doanh nghiệp (trả về)';
										|ru = 'Документы между организациями (возвраты)';
										|en = 'Documents between companies (returns)'; fa = 'Documents between companies (returns)';
										|it = 'Documenti tra le società (i resi)';
										|pl = 'Dokumenty między firmami (zwroty)';
										|tr = 'İş yerleri arasındaki belgeler (iadeler)'");
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String, ReturnOfGoodsBetweenOrganizationsLine);
	String.BusinessOperation       = Enums.BusinessTransactions.IntercompanyCommissionReturn;
	
	// CommissionReportIntercompany
	
	LineReportOnCommissionBetweenOrganizations = BusinessTransactionsAndDocuments.Add();
	
	String = LineReportOnCommissionBetweenOrganizations;
	String.PurposeUseKey = "CommissionReportIntercompany";
	String.BusinessOperation       = Enums.BusinessTransactions.CommissionReportIntercompany;
	String.AddButtonCreate       = True;
	String.DocumentType                = Type("DocumentRef.CommissionReportIntercompany");
	String.FullDocumentName          = "Document.CommissionReportIntercompany";
	String.WorkplaceTitle      = NStr("vi = 'Chứng từ giữa các doanh nghiệp (báo cáo hoa hồng)';
										|ru = 'Документы между организациями (отчеты по комиссии)';
										|en = 'Intercompany documents (consignment issue notifications)'; fa = 'Intercompany documents (consignment issue notifications)';
										|it = 'Documenti tra le società (report sulle commissioni)';
										|pl = 'Dokumenty między firmami (raporty prowizji)';
										|tr = 'İş yerleri arasındaki belgeler (komisyon raporları)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfIntercompanyDocuments";
	
	// CommissionWriteOffReportIntercompany
	
	LineReportOnCommissionBetweenOrganizationsOnWriteOffs = BusinessTransactionsAndDocuments.Add();
	
	String = LineReportOnCommissionBetweenOrganizationsOnWriteOffs;
	String.PurposeUseKey = "CommissionReportIntercompany";
	String.BusinessOperation       = Enums.BusinessTransactions.CommissionWriteOffReportIntercompany;
	String.AddButtonCreate       = True;
	String.DocumentType                = Type("DocumentRef.CommissionWriteOffReportIntercompany");
	String.FullDocumentName          = "Document.CommissionWriteOffReportIntercompany";
	String.WorkplaceTitle      = NStr("vi = 'Chứng từ giữa các doanh nghiệp (báo cáo ghi giảm về hoa hồng)';
										|ru = 'Документы между организациями (отчеты по комиссии о списании)';
										|en = 'Intercompany documents (write-off commission reports)'; fa = 'Intercompany documents (write-off commission reports)';
										|it = 'Documenti tra le società (report sulle commissioni per storno)';
										|pl = 'Dokumenty między firmami (raporty prowizji o rozchodach)';
										|tr = 'İş yerleri arasındaki belgeler (komisyon iptal raporları)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfIntercompanyDocuments";
	
	// CustomerInvoiceIntercompany
	
	LineTransferOfGoodsBetweenOrganizations = BusinessTransactionsAndDocuments.Add();
	
	String = LineTransferOfGoodsBetweenOrganizations;
	String.PurposeUseKey = "CustomerInvoiceIntercompany";
	String.BusinessOperation       = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	String.AddButtonCreate       = True;
	String.DocumentType                = Type("DocumentRef.CustomerInvoiceIntercompany");
	String.FullDocumentName          = "Document.CustomerInvoiceIntercompany";
	String.WorkplaceTitle      = NStr("vi = 'Chứng từ giữa các doanh nghiệp (chuyển giao)';
										|ru = 'Документы между организациями (передачи)';
										|en = 'Documents between companies (transfers)'; fa = 'Documents between companies (transfers)';
										|it = 'Documenti tra le società (trasferimenti)';
										|pl = 'Dokumenty między firmami (transmisji)';
										|tr = 'İş yerleri arasındaki belgeler (transfer)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.CustomerInvoiceIntercompany";
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String, LineTransferOfGoodsBetweenOrganizations);
	String.BusinessOperation       = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany;
	
	// ConsumptionReportSubcontractingServicesDeliveredIntercompany
	
	String = BusinessTransactionsAndDocuments.Add();
	String.PurposeUseKey = "ConsumptionReportSubcontractingServicesDeliveredIntercompany";
	String.BusinessOperation       = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany;
	String.AddButtonCreate       = True;
	String.DocumentType                = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany");
	String.FullDocumentName          = "Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany";
	String.WorkplaceTitle      = NStr("vi = 'Chứng từ giữa các doanh nghiệp (bảng kê cho bên đặt gia công)';
										|ru = 'Документы между организациями (отчеты давальцу)';
										|en = 'Intercompany documents (Consumption reports — subcontracting services delivered)'; fa = 'Intercompany documents (Consumption reports — subcontracting services delivered)';
										|it = 'Документы между организациями (отчеты давальцу)';
										|pl = 'Intercompany documents (Consumption reports — subcontracting services delivered)';
										|tr = 'İş yerleri arası belgeler (Tüketim raporu-Verilen fason hizmetleri)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany";
	
	Return BusinessTransactionsAndDocuments;

EndFunction

#EndRegion

#Region Private

Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export
	
	ToRegister = TMCommonUse.CreateHyperlinkToDesign(Parameters[0], Parameters[1]);
	PutToTempStorage(ToRegister, StorageAddress);
	
EndProcedure

Procedure OnDefineCommandsAttachedToObject(Commands) Export
	
EndProcedure

Function ResultOfBackgroundTasks()
	                                       
	Result = New Structure();
	Result.Insert("ExcessReserves");
	Result.Insert("ToRegisterForAPeriod");
	Result.Insert("ThereAreGoodsForRegistrationOfTransfersBeforeRedemption");
	
	Return Result;
	
EndFunction

Function ThereAreGoodsForRegistrationOfTransfersBeforeRedemption(Parameters)
	
	If Parameters.Property("IssueRansoms")
		And Parameters.IssueRansoms Then
		
		Query = New Query;
		QueryText =
		"SELECT TOP 1
		|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStock.Organization AS Organization,
		|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	CompanySafeStock.CCDNumber AS CCDNumber,
		|	SUM(CompanySafeStock.Count) AS Count
		|FROM
		|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
		|WHERE
		|	CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND CompanySafeStock.Organization <> CompanySafeStock.CorCompany
		|	AND CompanySafeStock.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
		|	AND &StorageLocation
		|	AND &GoodsOwner
		|	AND &OrganizationOfReserve
		|
		|GROUP BY
		|	CompanySafeStock.ItemsLocationAttributes,
		|	CompanySafeStock.CCDNumber,
		|	CompanySafeStock.Organization,
		|	CompanySafeStock.InventoryOwnerAttribute
		|
		|HAVING
		|	SUM(CompanySafeStock.Count) > 0";
		
		If ValueIsFilled(Parameters.Recipient) Then
			QueryText = StrReplace(QueryText, "&OrganizationOfReserve", "CompanySafeStock.Organization = &Organization");
			
			Query.SetParameter("Organization", Parameters.Recipient);
		Else
			QueryText = StrReplace(QueryText, "&OrganizationOfReserve", "TRUE");
		EndIf;
		
		If ValueIsFilled(Parameters.Sender) Then
			QueryText = StrReplace(QueryText, "&GoodsOwner", "CompanySafeStock.InventoryOwnerAttribute.GoodsOwner = &GoodsOwner");
			
			Query.SetParameter("GoodsOwner", Parameters.Sender);
		Else
			QueryText = StrReplace(QueryText, "&GoodsOwner", "TRUE");
		EndIf;
		
		If ValueIsFilled(Parameters.StorageLocation) Then
			QueryText = StrReplace(QueryText, "&StorageLocation", "CompanySafeStock.ItemsLocationAttributes.StorageLocation = &StorageLocation");
			
			Query.SetParameter("StorageLocation", Parameters.StorageLocation);
		Else
			QueryText = StrReplace(QueryText, "&StorageLocation", "TRUE");
		EndIf;
		
		Query.Text = QueryText;
		
		ThereAreGoodsForRegistrationOfTransfersBeforeRedemption = Not Query.Execute().IsEmpty();
		
	Else
		ThereAreGoodsForRegistrationOfTransfersBeforeRedemption = False;
	EndIf;

	Return ThereAreGoodsForRegistrationOfTransfersBeforeRedemption;
	
EndFunction

// Distribute reserves by periods.
// 
// Parameters:
//  Parameters - Structure - Parameters
//  TempStorageAddress - UUID, String - Temporary storage address
Procedure AllocateReservesByPeriod(Parameters, TempStorageAddress) Export

	Result = AccumulationRegisters.CompanySafeStock.AllocateReservesByPeriod();
		
	If Result <> "Error" Then
		RequirementsForRegistrationForPeriod(Parameters, TempStorageAddress);
	Else
		Result = ResultOfBackgroundTasks();
		Result.ExcessReserves                            = "Error";
		Result.ToRegisterForAPeriod                      = Undefined;
		Result.ThereAreGoodsForRegistrationOfTransfersBeforeRedemption = False;
		PutToTempStorage(Result, TempStorageAddress);
	EndIf;	
	
EndProcedure

// Parameters:
// 	Parameters - Structure - Where:
// * StorageLocation - CatalogRef.CounterpartyContracts, CatalogRef.BusinessStructure, CatalogRef.Warehouses - 
// * Recipient - CatalogRef.Companies
// * Sender - CatalogRef.Companies, CatalogRef.Partners - 
// * Period - StandardPeriod
// * IssueRansoms - Boolean
// * MakeTransfers - Boolean
//  TempStorageAddress - UUID, String - Temporary storage address
Procedure RequirementsForRegistrationForPeriod(Parameters, TempStorageAddress) Export
	
	Result = ResultOfBackgroundTasks();
	
	If Parameters.Property("MakeTransfers") Then
		
		Query = New Query;
		Query.SetParameter("MakeTransfers", Parameters.MakeTransfers); 
		Query.SetParameter("IssueRansoms", Parameters.IssueRansoms); 
		
		BeginOfPeriod = BegOfMonth(Parameters.Period.StartDate);
		EndOfPeriod  = ?(ValueIsFilled(Parameters.Period.EndDate), EndOfMonth(Parameters.Period.EndDate), Parameters.Period.EndDate);
		
		Query.SetParameter("BeginOfPeriod",                 BeginOfPeriod);
		Query.SetParameter("EndOfPeriod",                  EndOfPeriod);
		Query.SetParameter("Sender",                   Parameters.Sender);
		Query.SetParameter("Recipient",                    Parameters.Recipient);
		Query.SetParameter("StorageLocation",                 Parameters.StorageLocation);
		Query.SetParameter("TypesOfRedemptionStocks",             Parameters.TypesOfRedemptionStocks);
		Query.Text = InventoriesServer.TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query, "SelectionByHeader");
		
		ToRegisterForAPeriod = Query.Execute().Unload();
		Result.ToRegisterForAPeriod                      = ToRegisterForAPeriod;
	EndIf;
	
	Result.ExcessReserves                            = AccumulationRegisters.CompanySafeStock.ThereAreExtraReserves(True);
	Result.ThereAreGoodsForRegistrationOfTransfersBeforeRedemption = ThereAreGoodsForRegistrationOfTransfersBeforeRedemption(Parameters);
	
	PutToTempStorage(Result, TempStorageAddress); 
	
EndProcedure

#EndRegion

#EndIf
