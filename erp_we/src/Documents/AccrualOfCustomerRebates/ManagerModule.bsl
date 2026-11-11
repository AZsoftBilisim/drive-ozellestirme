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
//  Document - DocumentRef.AccrualOfCustomerRebates, DocumentObject.AccrualOfCustomerRebates - link to the document or object for which you want to get data
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
	
	If TypeOf(Document) = Type("DocumentObject.AccrualOfCustomerRebates") Then
		
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
		
		QueryTextTableCustomerRebates(QueryTexts, Registers, DocumentObject);
		QueryTextTableCustomerRebatesAccrualPeriods(QueryTexts, Registers, DocumentObject);
		
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
	
	#Region CreatingWriteOff
	NewCommand = Documents.DebitCustomerRebates.AddGenerateCommand(
		GenerationCommands, Parameters);
	If NewCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"MultipleCounterparties",
			False,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	#EndRegion
	
	#Region CreatingActOfAwardToClient
	NewCommand = Documents.CustomerBonusCertificate.AddGenerateCommand(
		GenerationCommands, Parameters);
	If NewCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"MultipleCounterparties",
			False,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	#EndRegion
	
EndProcedure

// Adds a Command to create a document "Accrual of retro customer bonuses".
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
	
	If AccessRight("Insert", Metadata.Documents.AccrualOfCustomerRebates) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AccrualOfCustomerRebates.FullName();
		CreateBasedOnCommand.Presentation = 
			TMCommonUse.ObjectPresentation(Metadata.Documents.AccrualOfCustomerRebates);
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
	
	ReportCommand = Reports.CalculateCustomerRebates.AddCalculationOfCustomerRebatesCommand(
		ReportsCommands,
		"CalculationOfCustomerRebatesContext");
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
	
	If GetFunctionalOption("DisplayFullNamesOfCustomerRebates") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

// Parameters:
//  Data - Structure - Document data:
//  * Ref - DocumentRef.AccrualOfCustomerRebates
//  * Number - String -
//  * Date - Date
//  Presentation - String - Presentation
//  StandardProcessing - Boolean - Standard treatment
//
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Not GetFunctionalOption("DisplayFullNamesOfCustomerRebates") Then
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

#Region Other

// Parameters:
//  DocumentAccruals - DocumentRef.AccrualOfCustomerRebates
// 
// Returns:
//  Undefined, QueryResultSelection -:
//  * Organization - CatalogRef.Companies
//  * Counterparty - CatalogRef.Counterparties
//  * CounterpartySPartner - CatalogRef.Partners
//  * Currency - CatalogRef.Currencies
//  * Partner - CatalogRef.Partners
//  * TermDocument - DocumentRef.ConditionsOfCustomerRebates
//  * BeginOfPeriod - Date
//  * PeriodEnding - Date
//  * Sum - CatalogRef.Companies
//
Function DataOfAccrualDocument(DocumentAccruals) Export
	
	HeaderData_ = Undefined;
	
	QueryText =
	"SELECT
	|	AccrualPeriods.Organization AS Organization,
	|	AccrualPeriods.Counterparty AS Counterparty,
	|	AccrualPeriods.Counterparty.Partner AS CounterpartySPartner,
	|	AccrualPeriods.Currency AS Currency,
	|	AccrualPeriods.Partner AS Partner,
	|	AccrualPeriods.TermDocument AS TermDocument,
	|	AccrualPeriods.BeginOfPeriod AS BeginOfPeriod,
	|	AccrualPeriods.PeriodEnding AS PeriodEnding,
	|	ISNULL(CustomerRebates.AmountBonus, 0) AS Sum
	|FROM
	|	InformationRegister.CustomerRebatesAccrualPeriods AS AccrualPeriods
	|		LEFT JOIN AccumulationRegister.CustomerRebates AS CustomerRebates
	|		ON AccrualPeriods.Recorder = CustomerRebates.Recorder
	|		AND CustomerRebates.AmountBonus > 0
	|		AND AccrualPeriods.TermDocument = CustomerRebates.TermDocument
	|		AND AccrualPeriods.Counterparty = CustomerRebates.Counterparty
	|		AND AccrualPeriods.Partner = CustomerRebates.Partner
	|WHERE
	|	AccrualPeriods.Recorder = &Recorder
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Organization,
	|	Counterparty,
	|	Currency";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Recorder", DocumentAccruals);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		SampleOrganization = QueryResult.Select(QueryResultIteration.ByGroups);
		While SampleOrganization.Next() Do
			
			CounterpartySelection = SampleOrganization.Select(QueryResultIteration.ByGroups);
			While CounterpartySelection.Next() Do
				
				HeaderData_ = CounterpartySelection.Select(QueryResultIteration.ByGroups);
				HeaderData_.Next();
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Return HeaderData_;
	
EndFunction

#EndRegion

#Region ConditionalAppearance

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//  Items - FormAllItems
//
Procedure SetConditionalAppearanceOfCounterpartyList(ConditionalAppearance, Items) Export
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.MultipleCounterparties");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<nhiều>';
													|ru = '<несколько>';
													|en = '<several>'; fa = '<several>';
													|it = '<несколько>';
													|pl = '<several>';
													|tr = '<birkaç>'"));
	
EndProcedure

// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance
//  Items - FormAllItems
//
Procedure SetConditionalAppearanceOfPartnerList(ConditionalAppearance, Items) Export
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Partner.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.SeveralPartners");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<nhiều>';
													|ru = '<несколько>';
													|en = '<several>'; fa = '<several>';
													|it = '<несколько>';
													|pl = '<several>';
													|tr = '<birkaç>'"));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Other

// Returns:
//  String
//
Function DocumentHeaderTemplate() Export
	
	If GetFunctionalOption("DisplayFullNamesOfCustomerRebates") Then
		
		DocumentHeaderTemplate = NStr("vi = 'Tính thưởng lũy kế cho khách hàng %1';
										|ru = 'Начисление ретро-бонусов клиента %1';
										|en = 'Accrual of customer rebates %1'; fa = 'Accrual of customer rebates %1';
										|it = 'Начисление ретро-бонусов клиента %1';
										|pl = 'Accrual of customer rebates %1';
										|tr = '%1 müşterisinin retro bonusu tahakkuku'");
		
	Else
		
		DocumentHeaderTemplate = NStr("vi = 'Tính thưởng lũy kế cho khách hàng %1';
										|ru = 'Начисление ретро-бонусов клиента %1';
										|en = 'Accrual of customer rebates %1'; fa = 'Accrual of customer rebates %1';
										|it = 'Начисление ретро-бонусов клиента %1';
										|pl = 'Accrual of customer rebates %1';
										|tr = '%1 müşterisinin retro bonusu tahakkuku'");
		
	EndIf;
	
	Return DocumentHeaderTemplate;
	
EndFunction

#EndRegion

#Region Posting

Function QueryTextTableCustomerRebates(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Header.Date AS Period,
	|	Header.Organization AS Organization,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	Header.BeginOfPeriod AS BeginOfPeriod,
	|	Header.PeriodEnding AS PeriodEnding,
	|	Header.TermDocument AS TermDocument,
	|	Header.Currency AS Currency,
	|	SUM(TableData.AmountBonusAccrued) AS AmountBonus,
	|	SUM(0) AS ToCertify,
	|	SUM(0) AS ToSign,
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
	|	Header.BeginOfPeriod,
	|	Header.PeriodEnding,
	|	Header.TermDocument,
	|	Header.Currency
	|HAVING
	|	SUM(TableData.AmountBonusAccrued) <> 0";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(
			QueryText,
			"DocumentDataAccrualTable",
			"Document.AccrualOfCustomerRebates.Accruals");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCustomerRebatesAccrualPeriods(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CustomerRebatesAccrualPeriods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	Header.Date AS Period,
	|	Header.Organization AS Organization,
	|	TableData.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	Header.BeginOfPeriod AS BeginOfPeriod,
	|	Header.PeriodEnding AS PeriodEnding,
	|	Header.TermDocument AS TermDocument,
	|	Header.Currency AS Currency
	|FROM
	|	DocumentDataAccrualTable AS TableData
	|		LEFT JOIN DocumentDataHeader AS Header
	|		ON TableData.Ref = Header.Ref
	|WHERE
	|	TableData.Ref = &Ref";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(
			QueryText,
			"DocumentDataAccrualTable",
			"Document.AccrualOfCustomerRebates.Accruals");
		
		QueryText = StrReplace(
			QueryText,
			"DocumentDataHeader",
			"Document.AccrualOfCustomerRebates");
		
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
	|	DocumentData.Currency AS Currency,
	|	DocumentData.TermDocument.PartyCountDetails AS PartyCountDetails
	|INTO DocumentDataHeader
	|FROM
	|	Document.AccrualOfCustomerRebates AS DocumentData
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
	|	DataTable.DocumentSales AS DocumentSales,
	|	DataTable.Revenue AS Revenue,
	|	DataTable.CalculationBase AS CalculationBase,
	|	DataTable.AmountAccruedBonus AS AmountAccruedBonus,
	|	DataTable.AmountBonusAccrued AS AmountBonusAccrued
	|INTO DocumentDataAccrualTable
	|FROM
	|	Document.AccrualOfCustomerRebates.Accruals AS DataTable
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

#EndRegion

#EndIf