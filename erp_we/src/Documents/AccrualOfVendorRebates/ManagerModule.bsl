//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Rebates");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef.AccrualOfVendorRebates, DocumentObject.AccrualOfVendorRebates - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	ValueList of String - a list of values containing query texts and their names.
//						Returned if the 'Get Request texts' property of the Dopparameters parameter
//						is set to True.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AccrualOfVendorRebates") Then
		
		DocumentObject = Document;
		DocumentRef = Document.Ref;
		
	Else
		
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
		
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList; // ValueList of String
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		QueryTextTableVendorRebates(QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.WriteOffVendorRebates.AddGenerateCommand(GenerationCommands, Parameters);
	Documents.VendorBonusCertificate.AddGenerateCommand(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command to create a document "Accrual of retro supplier bonuses".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
//
Function AddGenerateCommand(GenerationCommands, Parameters) Export
	
	Result = Undefined;
	
	If AccessRight("Insert", Metadata.Documents.AccrualOfVendorRebates) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AccrualOfVendorRebates.FullName();
		CreateBasedOnCommand.Presentation = 
			TMCommonUse.ObjectPresentation(Metadata.Documents.AccrualOfVendorRebates);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Result = CreateBasedOnCommand;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.CalculateVendorRebates.AddCommandToCalculateSuppliersRebates(ReportsCommands);
	If ReportCommand <> Undefined Then
		
		ReportCommand.Presentation = NStr("vi = 'Diễn giải tính thưởng lũy kế';
											|ru = 'Расшифровка расчета ретро-бонусов';
											|en = 'Drill down rebates'; fa = 'Drill down rebates';
											|it = 'Расшифровка расчета ретро-бонусов';
											|pl = 'Drill down rebates';
											|tr = 'Retro bonusların hesap detaylandırması'");
		ReportCommand.WriteMode = "Write";
		
	EndIf;
	
EndProcedure

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array; // Array of String
	
	NotAttributesToEdit.Add("*");
		
	Return NotAttributesToEdit;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	If GetFunctionalOption("DisplayFullNamesOfVendorRebates") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

// Parameters:
//  Data - Structure - Document data:
//  * Ref - DocumentRef.AccrualOfVendorRebates
//  * Number - String -
//  * Date - Date
//  Presentation - String - Presentation
//  StandardProcessing - Boolean - Standard treatment
//
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Not GetFunctionalOption("DisplayFullNamesOfVendorRebates") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Data.Ref <> Undefined Then
		
		Presentation = RebatesServerCall.DocumentTitle(
			Data.Ref,
			Data.Number,
			Data.Date);
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

#Region ConditionalAppearance

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//  Items - FormAllItems
//
Procedure SetConditionalAppearanceListValidityPeriod(ConditionalAppearance, Items) Export
	
	TextNotUsed = NStr("vi = '<không sử dụng>';
						|ru = '<не используется>';
						|en = '<not used>'; fa = '<استفاده نمی‌شود>';
						|it = '<не используется>';
						|pl = '<nie używa się>';
						|tr = '<kullanılmıyor>'");
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BeginOfPeriod.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEnding.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BonusType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VendorRebateTypes.Balance;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
EndProcedure

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//  Items - FormAllItems
//
Procedure SetConditionalAppearanceOfCounterpartyList(ConditionalAppearance, Items) Export
	
	TextIsMultiple = NStr("vi = '<nhiều>';
							|ru = '<несколько>';
							|en = '<several>'; fa = '<several>';
							|it = '<несколько>';
							|pl = '<several>';
							|tr = '<birkaç>'");
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BonusType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VendorRebateTypes.Purchases;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", TextIsMultiple);
	
EndProcedure

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//  Items - FormAllItems
//
Procedure SetConditionalAppearanceOfPartnerList(ConditionalAppearance, Items) Export
	
	TextIsMultiple = NStr("vi = '<nhiều>';
							|ru = '<несколько>';
							|en = '<several>'; fa = '<several>';
							|it = '<несколько>';
							|pl = '<several>';
							|tr = '<birkaç>'");
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Partner.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BonusType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VendorRebateTypes.Purchases;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", TextIsMultiple);
	
EndProcedure

#EndRegion

#Region Other

// Parameters:
//  DocumentAccruals - DocumentRef.AccrualOfVendorRebates
// 
// Returns:
//  Structure - Data of the Accrual Document:
// * Header - QueryResultSelection:
//   ** Organization - CatalogRef.Companies
//   ** Counterparty- CatalogRef.Counterparties
//   ** Partner- CatalogRef.Partners
//   ** Contract - CatalogRef.CounterpartyContracts
//   ** FinancialAccountingGroup - CatalogRef.FinancialAccountingGroupsOfARAP
//   ** LineOfBusiness - CatalogRef.LinesOfBusiness
//   ** Currency - CatalogRef.Currencies
//   ** BonusType - EnumRef.VendorRebateTypes
// * RowsData - QueryResultSelection:
//   ** Partner - CatalogRef.Partners
//   ** Contract - CatalogRef.CounterpartyContracts
//   ** Sum - DefinedType.MonetaryAmountNonNegative
//   ** TermDocument - DocumentRef.ConditionsOfVendorRebates
//   ** BeginOfPeriod - Date
//   ** PeriodEnding - Date
// * Counterparties - QueryResultSelection:
//   ** Counterparty - CatalogRef.Counterparties
//
Function DataOfAccrualDocument(DocumentAccruals) Export
	
	QueryText =
	"SELECT
	|	Accruals.Partner AS Partner,
	|	Accruals.Counterparty AS Counterparty,
	|	Accruals.Contract AS Contract,
	|	Accruals.AmountBonusAccrued AS Sum
	|INTO TT_AccrualTableData
	|FROM
	|	Document.AccrualOfVendorRebates.Accruals AS Accruals
	|WHERE
	|	Accruals.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(AccrualTableData.Counterparty) AS Counterparty,
	|	MAX(AccrualTableData.Counterparty.Partner) AS CounterpartySPartner
	|INTO TT_Counterparties
	|FROM
	|	TT_AccrualTableData AS AccrualTableData
	|HAVING
	|	COUNT(DISTINCT AccrualTableData.Counterparty) = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualOfVendorRebates.Organization AS Organization,
	|	CASE
	|		WHEN AccrualOfVendorRebates.BonusType = VALUE(Enum.VendorRebateTypes.Purchases)
	|			THEN ISNULL(Counterparties.Counterparty, VALUE(Catalog.Counterparties.EmptyRef))
	|		ELSE AccrualOfVendorRebates.Counterparty
	|	END AS Counterparty,
	|	CASE
	|		WHEN AccrualOfVendorRebates.BonusType = VALUE(Enum.VendorRebateTypes.Purchases)
	|			THEN ISNULL(Counterparties.CounterpartySPartner, VALUE(Catalog.Partners.EmptyRef))
	|		ELSE AccrualOfVendorRebates.Counterparty.Partner
	|	END AS CounterpartySPartner,
	|	AccrualOfVendorRebates.Currency AS Currency,
	|	AccrualOfVendorRebates.TermDocument AS TermDocument,
	|	AccrualOfVendorRebates.BeginOfPeriod AS BeginOfPeriod,
	|	AccrualOfVendorRebates.PeriodEnding AS PeriodEnding,
	|	AccrualOfVendorRebates.BonusType AS BonusType
	|INTO TT_HeaderData_
	|FROM
	|	Document.AccrualOfVendorRebates AS AccrualOfVendorRebates
	|	LEFT JOIN TT_Counterparties AS Counterparties
	|		ON AccrualOfVendorRebates.BonusType = VALUE(Enum.VendorRebateTypes.Purchases)
	|WHERE
	|	AccrualOfVendorRebates.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Counterparty AS Counterparty,
	|	HeaderData_.CounterpartySPartner AS Partner,
	|	HeaderData_.Currency AS Currency,
	|	MAX(Contracts.Ref) AS Contract,
	|	MAX(Contracts.FinancialAccountingGroup) AS FinancialAccountingGroup,
	|	MAX(Contracts.LineOfBusiness) AS LineOfBusiness
	|INTO TT_CounterpartyContracts
	|FROM
	|	TT_HeaderData_ AS HeaderData_
	|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON HeaderData_.Organization = Contracts.Organization
	|		 AND HeaderData_.Counterparty = Contracts.Counterparty
	|		 AND HeaderData_.CounterpartySPartner = Contracts.Partner
	|		 AND HeaderData_.Currency = Contracts.ARAPCurrency
	|		 AND Contracts.ContractType IN (&ContractTypes)
	|		 AND Contracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|		 AND NOT Contracts.DeletionMark
	|GROUP BY
	|	HeaderData_.Organization,
	|	HeaderData_.Counterparty,
	|	HeaderData_.CounterpartySPartner,
	|	HeaderData_.Currency
	|HAVING
	|	COUNT(DISTINCT Contracts.Ref) = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccrualTableData.Counterparty AS Counterparty
	|FROM
	|	TT_AccrualTableData AS AccrualTableData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualTableData.Partner AS Partner,
	|	AccrualTableData.Contract AS Contract,
	|	SUM(AccrualTableData.Sum) AS Sum,
	|	ISNULL(HeaderData_.TermDocument, VALUE(Document.ConditionsOfVendorRebates.EmptyRef)) AS TermDocument,
	|	ISNULL(HeaderData_.BeginOfPeriod, DATETIME(1, 1, 1)) AS BeginOfPeriod,
	|	ISNULL(HeaderData_.PeriodEnding, DATETIME(1, 1, 1)) AS PeriodEnding
	|FROM
	|	TT_AccrualTableData AS AccrualTableData
	|		LEFT JOIN TT_HeaderData_ AS HeaderData_
	|		ON TRUE
	|GROUP BY
	|	AccrualTableData.Partner,
	|	AccrualTableData.Contract,
	|	ISNULL(HeaderData_.TermDocument, VALUE(Document.ConditionsOfVendorRebates.EmptyRef)),
	|	ISNULL(HeaderData_.CounterpartySPartner, VALUE(Catalog.Partners.EmptyRef)),
	|	ISNULL(HeaderData_.BeginOfPeriod, DATETIME(1, 1, 1)),
	|	ISNULL(HeaderData_.PeriodEnding, DATETIME(1, 1, 1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Counterparty AS Counterparty,
	|	HeaderData_.CounterpartySPartner AS Partner,
	|	ISNULL(CounterpartyContracts.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS Contract,
	|	ISNULL(CounterpartyContracts.FinancialAccountingGroup, VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef)) AS FinancialAccountingGroup,
	|	ISNULL(CounterpartyContracts.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	HeaderData_.Currency AS Currency,
	|	HeaderData_.BonusType AS BonusType
	|FROM
	|	TT_HeaderData_ AS HeaderData_
	|		LEFT JOIN TT_CounterpartyContracts AS CounterpartyContracts
	|		ON HeaderData_.Organization = CounterpartyContracts.Organization
	|		 AND HeaderData_.Counterparty = CounterpartyContracts.Counterparty
	|		 AND HeaderData_.CounterpartySPartner = CounterpartyContracts.Partner
	|		 AND HeaderData_.Currency = CounterpartyContracts.Currency";
	
	ContractTypes = New Array; // Array of EnumRef.ContractTypes
	ContractTypes.Add(Enums.ContractTypes.WithVendor);
	ContractTypes.Add(Enums.ContractTypes.Import);
	ContractTypes.Add(Enums.ContractTypes.PurchaseEAEU);
	ContractTypes.Add(Enums.ContractTypes.ReceivingForCustody);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentAccruals);
	Query.SetParameter("ContractTypes", ContractTypes);
	
	QueryResults = Query.ExecuteBatch();
	NumberOfResults = QueryResults.UBound();
	ResultHeader__ = QueryResults[NumberOfResults].Select();
	ResultRowData = QueryResults[NumberOfResults - 1].Select();
	ResultCounterparties = QueryResults[NumberOfResults - 2].Select();
	
	Result = New Structure;
	Result.Insert("Header", ResultHeader__);
	Result.Insert("RowsData", ResultRowData);
	Result.Insert("Counterparties", ResultCounterparties);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function QueryTextTableVendorRebates(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(Enum.AccumulationRecordTypes.Receipt) AS TypeOfRegisterMovement,
	|	Header.Date AS Period,
	|	Header.Organization AS Organization,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	TableData.Contract AS Contract,
	|	Header.BeginOfPeriod AS BeginOfPeriod,
	|	Header.PeriodEnding AS PeriodEnding,
	|	Header.TermDocument AS TermDocument,
	|	Header.Currency AS Currency,
	|	SUM(TableData.AmountBonusAccrued) AS Accrued,
	|	SUM(0) AS Certified,
	|	SUM(0) AS WrittenOff,
	|	SUM(0) AS ToWriteOff
	|FROM
	|	DocumentDataAccrualTable AS TableData
	|		LEFT JOIN DocumentDataHeader AS Header
	|		ON TableData.Ref = Header.Ref
	|WHERE
	|	TableData.Ref = &Ref
	|GROUP BY
	|	VALUE(AccumulationRecordType.Receipt),
	|	Header.Date,
	|	Header.Organization,
	|	TableData.Counterparty,
	|	TableData.Partner,
	|	TableData.Contract,
	|	Header.BeginOfPeriod,
	|	Header.PeriodEnding,
	|	Header.TermDocument,
	|	Header.Currency,
	|	VALUE(Enum.AccumulationRecordTypes.Receipt)
	|HAVING
	|	SUM(TableData.AmountBonusAccrued) <> 0";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(
			QueryText,
			"DocumentDataAccrualTable",
			"Document.AccrualOfVendorRebates.Accruals");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region DocumentData

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array; // Array of String
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDataAccrualTable(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.TermDocument AS TermDocument,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.PeriodEnding AS PeriodEnding,
	|	DocumentData.Currency AS Currency
	|INTO DocumentDataHeader
	|FROM
	|	Document.AccrualOfVendorRebates AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataAccrualTable(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Counterparty AS Counterparty,
	|	DataTable.Partner AS Partner,
	|	DataTable.Contract AS Contract,
	|	DataTable.Revenue AS Revenue,
	|	DataTable.CalculationBase AS CalculationBase,
	|	DataTable.AmountAccruedBonus AS AmountAccruedBonus,
	|	DataTable.AmountBonusAccrued AS AmountBonusAccrued
	|INTO DocumentDataAccrualTable
	|FROM
	|	Document.AccrualOfVendorRebates.Accruals AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|	AND DataTable.AmountBonusAccrued <> 0
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

// Returns:
//  String
//
Function DocumentHeaderTemplate() Export
	
	If GetFunctionalOption("DisplayFullNamesOfVendorRebates") Then
		
		DocumentHeaderTemplate = NStr("vi = 'Tính thưởng lũy kế của nhà cung cấp %1';
										|ru = 'Начисление ретро-бонусов поставщика %1';
										|en = 'Accrual of vendor rebates %1'; fa = 'Accrual of vendor rebates %1';
										|it = 'Начисление ретро-бонусов поставщика %1';
										|pl = 'Accrual of vendor rebates %1';
										|tr = '%1 tedarikçisinin retro bonusu tahakkuku'");
		
	Else
		
		DocumentHeaderTemplate = NStr("vi = 'Tính thưởng lũy kế của nhà cung cấp %1';
										|ru = 'Начисление ретро-бонусов поставщика %1';
										|en = 'Accrual of vendor rebates %1'; fa = 'Accrual of vendor rebates %1';
										|it = 'Начисление ретро-бонусов поставщика %1';
										|pl = 'Accrual of vendor rebates %1';
										|tr = '%1 tedarikçisinin retro bonusu tahakkuku'");
		
	EndIf;
	
	Return DocumentHeaderTemplate;
	
EndFunction

#EndRegion
	
#EndRegion

#EndIf