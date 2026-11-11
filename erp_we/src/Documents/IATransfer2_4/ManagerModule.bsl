#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("ImpairmentFA");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	IATransferLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.IATransfer2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTexts = New ValueList;
		
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		
		QueryTextTableIntangibleAssetsRegistrationPlace(QueryTexts, Registers);
		QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableCGUComposition(QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		IATransferLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains temporary tables that are used in the formation of Registered Records.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	GetDocumentData(Query);

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	QueryTexts = New ValueList;
	QueryTextTableIACost(QueryTexts);
	QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts);
	QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Undefined);
	QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	IATransferLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ChangeIntangibleAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	
	IATransferLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command of creation of the document "the Movement of intangible assets".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.IATransfer2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IATransfer2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IATransfer2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	IATransferLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.IATransfer2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("SenderInformation",  """""");
	RedefiningParameterCalculation.Insert("RecipientInformation", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);

	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);
	
	Query.Text = 
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Number                           AS Number,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.CompanyRecipient           AS CompanyRecipient,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.ReceivingBusinessUnit         AS ReceivingBusinessUnit
	|FROM
	|	DocumentDataDetails AS DocumentData
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;

	Query.SetParameter("BorderInFrontOfDocument", New Boundary(Attributes.Period, BoundaryType.Excluding));
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
EndProcedure

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.IATransfer2_4 AS DocumentsList
	|
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	Query.Execute();
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInLocalAccounting,
	|	DocumentData.Date                            AS Period,
	|	DocumentData.Number                           AS Number,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.CompanyRecipient           AS CompanyRecipient,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.ReceivingBusinessUnit         AS ReceivingBusinessUnit,
	|	DocumentData.CGURecipient                  AS CGURecipient,
	|	DocumentData.EmployeeResponsible                   AS EmployeeResponsible,
	|	DocumentData.Comment                     AS Comment,
	|	DocumentData.Posted                        AS Posted,
	|	DocumentData.DeletionMark                 AS DeletionMark,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetsCostTransferToAnotherCompany)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetsCostParameterChange)
	|	END AS BO_CostSender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsCostFromAnotherCompany)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetsCostParameterChange)
	|	END AS BT_CostRecipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetAmortizationTransferToAnotherCompany)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetAmortizationParameterChange)
	|	END AS BT_DepreciationSender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetAmortizationTransferFromAnotherCompany)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.IntangibleAssetAmortizationParameterChange)
	|	END AS BT_DepreciationRecipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.TransferIntangibleAssetRevaluationReserveToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeIntangibleAssetRevaluationReserve)
	|	END AS HO_CostRevaluationReserve_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetRevaluationReserveFromAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeIntangibleAssetRevaluationReserve)
	|	END AS HO_CostRevaluationReserve_Recipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsCostTransferToAnotherCompany)
	|		ELSE
	|			VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsCostParameterChange)
	|	END AS SettingUpHO_CostSender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Catalog.BusinessTransactionsSettings.TransferIntangibleAssetsCostFromAnotherCompany)
	|		ELSE
	|			VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsCostParameterChange)
	|	END AS SettingUpHO_CostRecipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetAmortizationTransferToAnotherCompany)
	|		ELSE
	|			VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetAmortizationParameterChange)
	|	END AS SettingUpHO_DepreciationSender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice) THEN
	|			VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetAmortizationTransferFromAnotherCompany)
	|		ELSE
	|			VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetAmortizationParameterChange)
	|	END AS SettingUpHO_DepreciationRecipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferIntangibleAssetRevaluationReserveToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ChangeIntangibleAssetRevaluationReserve)
	|	END AS SettingUpHO_ReserveForRevaluationOfCosts_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferIntangibleAssetRevaluationReserveFromAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ChangeIntangibleAssetRevaluationReserve)
	|	END AS SettingUpHO_ReserveForRevaluationOfCosts_Recipient
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.IATransfer2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataIATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.IATransfer2_4.IA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Điều chuyển tài sản cố định vô hình';
															|ru = 'Перемещение НМА';
															|en = 'Transfer intangible assets'; fa = 'انتقال دارایی‌های نامشهود';
															|it = 'Trasferimento dei beni immateriali';
															|pl = 'Przemieszczenie wartości niematerialnych';
															|tr = 'Maddi olmayan varlıkların transferi'"));
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.IATransfer2_4"));

	ValuesOfHoldingParameters.Insert("Ap_nmaArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	ValuesOfHoldingParameters.Insert("Article6_ProfitLoss", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		NonCurrentAssetsInternal.SetValuesOfHoldingParametersWhenMoving(Attributes, ValuesOfHoldingParameters);
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0)           AS RecNo,
	|	DocumentData.Ref                          AS Ref,
	|	TableOfIA.IntangibleAsset                  AS IntangibleAsset,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.Date                            AS Date,
	|	&MetadataIdentifier                        AS RefType,
	|	FALSE                                            AS AdditionalRecord,
	|	DocumentData.Posted                        AS Posted,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInTA
	|FROM
	|	Document.IATransfer2_4 AS DocumentData
	|
	|		LEFT JOIN Document.IATransfer2_4.IA AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0)           AS RecNo,
	|	DocumentData.Ref                          AS Ref,
	|	TableOfIA.IntangibleAsset                  AS IntangibleAsset,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.CompanyRecipient           AS Organization,
	|	DocumentData.ReceivingBusinessUnit         AS Department,
	|	DocumentData.Date                            AS Date,
	|	&MetadataIdentifier                        AS RefType,
	|	TRUE                                          AS AdditionalRecord,
	|	DocumentData.Posted                        AS Posted,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInTA
	|FROM
	|	Document.IATransfer2_4 AS DocumentData
	|
	|		LEFT JOIN Document.IATransfer2_4.IA AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	&RecipientInformation AS More,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.IATransfer2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.Number,
	|	&MetadataIdentifier,
	|	DocumentData.CompanyRecipient,
	|	DocumentData.BusinessOperation,
	|	UNDEFINED,
	|	DocumentData.ReceivingBusinessUnit,
	|	DocumentData.EmployeeResponsible,
	|	DocumentData.Comment,
	|	DocumentData.Posted,
	|	DocumentData.DeletionMark,
	|	TRUE,
	|	&SenderInformation,
	|	DocumentData.Date,
	|	&NumberForPrinting,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.IATransfer2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|	AND DocumentData.CompanyRecipient <> VALUE(Catalog.Companies.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIntangibleAssetsRegistrationPlace(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsRegistrationPlace";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTIAAccountingParameters.RecordInLocalAccounting  AS RecordInLocalAccounting,
	|	TTIAAccountingParameters.RecordInManAccounting   AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IATransfer)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	DocumentData.CompanyRecipient   AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTIAAccountingParameters.RecordInLocalAccounting  AS RecordInLocalAccounting,
	|	TTIAAccountingParameters.RecordInManAccounting   AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                                      AS Recorder,
	|	DocumentData.Period                                      AS Period,
	|	DocumentData.CompanyRecipient                       AS Organization,
	|	InitialInformation.IntangibleAsset                  AS IntangibleAsset,
	|	InitialInformation.ReceiptMethod                    AS ReceiptMethod,
	|	InitialInformation.InitialCostMA            AS InitialCostMA,
	|	InitialInformation.InitialCostLocalAccounting            AS InitialCostLocalAccounting,
	|	InitialInformation.DepreciationMethodAccounting         AS DepreciationMethodAccounting,
	|	InitialInformation.PurchaseDate                     AS PurchaseDate,
	|	InitialInformation.DateOfRecognitionManagementAccounting                 AS DateOfRecognitionManagementAccounting,
	|	InitialInformation.DateOfRecognitionAccounting                 AS DateOfRecognitionAccounting,
	|	InitialInformation.DocumentOfRecognitionManagementAccounting             AS DocumentOfRecognitionManagementAccounting,
	|	InitialInformation.DocumentOfRecognitionAccounting             AS DocumentOfRecognitionAccounting,
	|	InitialInformation.DocumentWriteOffs                     AS DocumentWriteOffs
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTInitialInformationOfIA AS InitialInformation
	|		ON DocumentData.Ref = InitialInformation.Ref
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	DocumentData.CompanyRecipient   AS Organization,
	|	TTIAAccountingParameters.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness      AS LineOfBusiness,
	|	TTIAAccountingParameters.EstimatedRunningTime               AS EstimatedRunningTime,
	|	TTIAAccountingParameters.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	TTIAAccountingParameters.RecordInManAccounting            AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForNmabu(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                               AS Recorder,
	|	DocumentData.Period                               AS Period,
	|	TableOfIA.IntangibleAsset                       AS IntangibleAsset,
	|	DocumentData.Organization                          AS Organization,
	|	VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)   AS BUState,
	|	VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)   AS StateTa,
	|	FALSE                                                 AS DepreciationAccrualAccounting,
	|	FALSE                                                 AS DepreciationAccrualTaxAccounting,
	|	UNDEFINED                                         AS ExpenseItemAccounting,
	|	UNDEFINED                                         AS ExpensesDimensionAccounting,
	|	UNDEFINED                                         AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                         AS ExpensesDimensionTaxAccounting,
	|	UNDEFINED                                         AS DepreciationRecordMethodLA,
	|	UNDEFINED                                         AS DepreciationRecordMethodTA,
	|	FALSE                                                 AS TransferExpensesToAnotherCompany,
	|	UNDEFINED                                         AS CompanyRecipientOfExpenses,
	|	UNDEFINED                                         AS VATTaxation,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.InvestmentTaxDeduction       AS InvestmentTaxDeduction
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForNmabu AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON IABookkeepingProcedureBookkeepingAndTaxAccounting.Ref = TableOfIA.Ref
	|			AND IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                               AS Recorder,
	|	DocumentData.Period                               AS Period,
	|	TableOfIA.IntangibleAsset                       AS IntangibleAsset,
	|	DocumentData.CompanyRecipient                AS Organization,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState                        AS BUState,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa                        AS StateTa,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.DepreciationAccrualAccounting             AS DepreciationAccrualAccounting,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.DepreciationAccrualTaxAccounting             AS DepreciationAccrualTaxAccounting,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.ExpenseItemAccounting                   AS ExpenseItemAccounting,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.ExpensesDimensionAccounting                AS ExpensesDimensionAccounting,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.ExpenseItemTaxAccounting                   AS ExpenseItemTaxAccounting,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.ExpensesDimensionTaxAccounting                AS ExpensesDimensionTaxAccounting,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.DepreciationRecordMethodLA       AS DepreciationRecordMethodLA,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.DepreciationRecordMethodTA       AS DepreciationRecordMethodTA,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.CompanyRecipientOfExpenses      AS CompanyRecipientOfExpenses,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.VATTaxation                 AS VATTaxation,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.InvestmentTaxDeduction       AS InvestmentTaxDeduction
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForNmabu AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON IABookkeepingProcedureBookkeepingAndTaxAccounting.Ref = TableOfIA.Ref
	|			AND IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForNMAU(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	DocumentData.Organization             AS Organization,
	|	VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting) AS State,
	|	FALSE                                    AS AccrueDepreciationOrAmortization,
	|	UNDEFINED                            AS ExpenseItem,
	|	UNDEFINED                            AS DimensionOfExpenses,
	|	UNDEFINED                            AS DepreciationRecordMethod,
	|	FALSE                                    AS TransferExpensesToAnotherCompany,
	|	UNDEFINED                            AS CompanyRecipientOfExpenses
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataIATable AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                               AS Recorder,
	|	DocumentData.Period                               AS Period,
	|	TableOfIA.IntangibleAsset                       AS IntangibleAsset,
	|	DocumentData.CompanyRecipient                AS Organization,
	|	VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)     AS State,
	|	AccountingProcedure.AccrueDepreciationOrAmortization                    AS AccrueDepreciationOrAmortization,
	|	AccountingProcedure.ExpenseItem                          AS ExpenseItem,
	|	AccountingProcedure.DimensionOfExpenses                       AS DimensionOfExpenses,
	|	AccountingProcedure.DepreciationRecordMethod              AS DepreciationRecordMethod,
	|	AccountingProcedure.TransferExpensesToAnotherCompany     AS TransferExpensesToAnotherCompany,
	|	AccountingProcedure.CompanyRecipientOfExpenses           AS CompanyRecipientOfExpenses
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForNMAU AS AccountingProcedure
	|		ON AccountingProcedure.Ref = TableOfIA.Ref
	|			AND AccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetAmortizationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTNmauuDepreciationParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                           AS Recorder,
	|	DocumentData.Period                           AS Period,
	|	TableOfIA.IntangibleAsset                   AS IntangibleAsset,
	|	DocumentData.CompanyRecipient            AS Organization,
	|
	|	DepreciationParameters.LastChangeDate     AS LastChangeDate,
	|	DepreciationParameters.UsefulLifeMonths           AS UsefulLifeMonths,
	|	DepreciationParameters.AccelerationFactor        AS AccelerationFactor,
	|	DepreciationParameters.DepreciationMethod  AS DepreciationMethod,
	|	DepreciationParameters.ResidualValueMan     AS ResidualValueMan,
	|	DepreciationParameters.ResidualValueLocal AS ResidualValueLocal,
	|	DepreciationParameters.UsefulLifeForCalculatingDepreciationMonth    AS UsefulLifeForCalculatingDepreciationMonth,
	|	DepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits  AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTNmauuDepreciationParameters AS DepreciationParameters
	|		ON DepreciationParameters.Ref = TableOfIA.Ref
	|			AND DepreciationParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IADepreciationParametersBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersNMABU(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	TableOfIA.IntangibleAsset                         AS IntangibleAsset,
	|	DocumentData.CompanyRecipient                  AS Organization,
	|
	|	DepreciationParameters.LastChangeDate           AS LastChangeDate,
	|	DepreciationParameters.UsefulLifeMonthsAC      AS UsefulLifeMonthsAC,
	|	DepreciationParameters.UsefulLifeMonthsTA      AS UsefulLifeMonthsTA,
	|	DepreciationParameters.DepreciationAccrualFactor                     AS DepreciationAccrualFactor,
	|	DepreciationParameters.SpecialFactor            AS SpecialFactor,
	|	DepreciationParameters.ResidualValueMan           AS ResidualValueMan,
	|	DepreciationParameters.UsefulLifeForCalculatingDepreciationMonth    AS UsefulLifeForCalculatingDepreciationMonth,
	|	DepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits  AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN WDepreciationParametersNMABU AS DepreciationParameters
	|		ON DepreciationParameters.Ref = TableOfIA.Ref
	|			AND DepreciationParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIACost(QueryTexts)

	RegisterName = "IACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.BO_CostSender      AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|	TableOfIA.IntangibleAsset               AS IntangibleAsset,
	|	DocumentData.Department                AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|
	|	IACost.Cost                       AS Cost,
	|	IACost.LocalCost                   AS LocalCost,
	|	IACost.CostInTaxAccounting                     AS CostInTaxAccounting,
	|	IACost.CostPermanentDifference                     AS CostPermanentDifference,
	|	IACost.CostTemporaryDifference                     AS CostTemporaryDifference,
	|	IACost.CostTargetFinancing                     AS CostTargetFinancing,
	|	IACost.CostTargetFinancingTA                   AS CostTargetFinancingTA,
	|	IACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|	IACost.CostTargetFinancingTD                   AS CostTargetFinancingTD,
	|	IACost.TAExpenseAmountOfInvestmentTaxDeduction           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	IACost.SecurityDepositValue              AS SecurityDepositValue,
	|	IACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	IACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	IACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	IACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|
	|	0                                            AS CostGainMA,
	|	0                                            AS CostGainLocal,
	|
	|	DocumentData.CompanyRecipient        AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit      AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                 AS CorExpenseItem,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID               AS FinRecordID,
	|	DocumentData.SettingUpHO_CostSender AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.BT_CostRecipient       AS BusinessOperation,
	|	DocumentData.CompanyRecipient        AS Organization,
	|	TableOfIA.IntangibleAsset               AS IntangibleAsset,
	|	DocumentData.ReceivingBusinessUnit      AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|
	|	IACost.Cost                       AS Cost,
	|	IACost.LocalCost                   AS LocalCost,
	|	IACost.CostInTaxAccounting                     AS CostInTaxAccounting,
	|	IACost.CostPermanentDifference                     AS CostPermanentDifference,
	|	IACost.CostTemporaryDifference                     AS CostTemporaryDifference,
	|	IACost.CostTargetFinancing                     AS CostTargetFinancing,
	|	IACost.CostTargetFinancingTA                   AS CostTargetFinancingTA,
	|	IACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|	IACost.CostTargetFinancingTD                   AS CostTargetFinancingTD,
	|	IACost.TAExpenseAmountOfInvestmentTaxDeduction           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	IACost.SecurityDepositValue              AS SecurityDepositValue,
	|	IACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	IACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	IACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	IACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|
	|	0                                            AS CostGainMA,
	|	0                                            AS CostGainLocal,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                 AS CorExpenseItem,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID               AS FinRecordID,
	|	DocumentData.SettingUpHO_CostRecipient AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.HO_CostRevaluationReserve_Sender AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|	TableOfIA.IntangibleAsset               AS IntangibleAsset,
	|	DocumentData.Department                AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|
	|	0                                            AS Cost,
	|	0                                            AS LocalCost,
	|	0                                            AS CostInTaxAccounting,
	|	0                                            AS CostPermanentDifference,
	|	0                                            AS CostTemporaryDifference,
	|	0                                            AS CostTargetFinancing,
	|	0                                            AS CostTargetFinancingTA,
	|	0                                            AS CostTargetFinancingPD,
	|	0                                            AS CostTargetFinancingTD,
	|	0                                            AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                            AS SecurityDepositValue,
	|	0                                            AS PreliminaryCostMan,
	|	0                                            AS PreliminaryCostLocal,
	|	0                                            AS CostRevaluationReserve,
	|	0                                            AS CostRevaluationReserveLocal,
	|
	|	IACost.CostGainMA                AS CostGainMA,
	|	IACost.CostGainLocal            AS CostGainLocal,
	|
	|	DocumentData.CompanyRecipient        AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit      AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                 AS CorExpenseItem,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID               AS FinRecordID,
	|	DocumentData.SettingUpHO_ReserveForRevaluationOfCosts_Sender AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	(IACost.CostGainMA <> 0 
	|		OR IACost.CostGainLocal <> 0)
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.HO_CostRevaluationReserve_Recipient AS BusinessOperation,
	|	DocumentData.CompanyRecipient        AS Organization,
	|	TableOfIA.IntangibleAsset               AS IntangibleAsset,
	|	DocumentData.ReceivingBusinessUnit      AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|
	|	0                                            AS Cost,
	|	0                                            AS LocalCost,
	|	0                                            AS CostInTaxAccounting,
	|	0                                            AS CostPermanentDifference,
	|	0                                            AS CostTemporaryDifference,
	|	0                                            AS CostTargetFinancing,
	|	0                                            AS CostTargetFinancingTA,
	|	0                                            AS CostTargetFinancingPD,
	|	0                                            AS CostTargetFinancingTD,
	|	0                                            AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                            AS SecurityDepositValue,
	|	0                                            AS PreliminaryCostMan,
	|	0                                            AS PreliminaryCostLocal,
	|	0                                            AS CostRevaluationReserve,
	|	0                                            AS CostRevaluationReserveLocal,
	|
	|	IACost.CostGainMA                AS CostGainMA,
	|	IACost.CostGainLocal            AS CostGainLocal,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                 AS CorExpenseItem,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID               AS FinRecordID,
	|	DocumentData.SettingUpHO_ReserveForRevaluationOfCosts_Recipient AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	(IACost.CostGainMA <> 0 
	|		OR IACost.CostGainLocal <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts)

	RegisterName = "IntangibleAssetsAmortizationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)           AS RecordType,
	|	DocumentData.Ref                           AS Recorder,
	|	DocumentData.Period                           AS Period,
	|	DocumentData.BT_DepreciationSender        AS BusinessOperation,
	|	DocumentData.Organization                      AS Organization,
	|	TableOfIA.IntangibleAsset                   AS IntangibleAsset,
	|	DocumentData.Department                    AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness      AS LineOfBusiness,
	|	UNDEFINED                                     AS Counterparty,
	|	IntangibleAssetsAmortizationCharge.Depreciation                       AS Depreciation,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal                   AS DepreciationLocal,
	|	IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting                     AS DepreciationInTaxAccounting,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences                     AS DepreciationPermanentDifferences,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD                     AS DepreciationTD,
	|	IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing                     AS FixedAssetDepreciationTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing                   AS DepreciationTaxAccountingTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD                   AS DepreciationTargetFinancingPD,
	|	IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD                   AS DepreciationOfTargetFinancingTD,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve       AS DepreciationRevaluationReserve,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveLocal   AS DepreciationRevaluationReserveLocal,
	|	DocumentData.CompanyRecipient            AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit          AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness      AS CorLineOfBusiness,
	|	UNDEFINED                                     AS CorExpenseItem,
	|	UNDEFINED                                     AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup       AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID                   AS FinRecordID,
	|	DocumentData.SettingUpHO_DepreciationSender AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)           AS RecordType,
	|	DocumentData.Ref                           AS Recorder,
	|	DocumentData.Period                           AS Period,
	|	DocumentData.BT_DepreciationRecipient         AS BusinessOperation,
	|	DocumentData.CompanyRecipient            AS Organization,
	|	TableOfIA.IntangibleAsset                   AS IntangibleAsset,
	|	DocumentData.ReceivingBusinessUnit          AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness      AS LineOfBusiness,
	|	UNDEFINED                                     AS Counterparty,
	|	IntangibleAssetsAmortizationCharge.Depreciation                       AS Depreciation,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal                   AS DepreciationLocal,
	|	IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting                     AS DepreciationInTaxAccounting,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences                     AS DepreciationPermanentDifferences,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD                     AS DepreciationTD,
	|	IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing                     AS FixedAssetDepreciationTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing                   AS DepreciationTaxAccountingTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD                   AS DepreciationTargetFinancingPD,
	|	IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD                   AS DepreciationOfTargetFinancingTD,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve       AS DepreciationRevaluationReserve,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveLocal   AS DepreciationRevaluationReserveLocal,
	|	DocumentData.Organization                      AS CorCompany,
	|	DocumentData.Department                    AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness      AS CorLineOfBusiness,
	|	UNDEFINED                                     AS CorExpenseItem,
	|	UNDEFINED                                     AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup       AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID                   AS FinRecordID,
	|	DocumentData.SettingUpHO_DepreciationRecipient AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"// Moving depreciation for the sender
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.BT_DepreciationSender AS BusinessOperation,
	|	DocumentData.Organization        AS Organization,
	|
	|	DocumentData.Department      AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                      AS AssetRef,
	|	UNDEFINED                       AS DimensionOfRevenue,
	|	UNDEFINED                       AS DimensionOfExpenses,
	|	TableOfIA.IntangibleAsset     AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&Ap_nmaArticle       AS CorItem,
	|	UNDEFINED                       AS CorIncomeDimension,
	|	UNDEFINED                       AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset     AS CorDimensionOfAssetsLiabilities,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.CompanyRecipient AS CorCompany,
	|
	|	IntangibleAssetsAmortizationCharge.Depreciation         AS Sum,
	|	IntangibleAssetsAmortizationCharge.Depreciation         AS SumMan,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal + IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|
	|UNION ALL
	|
	|// Moving depreciation for the recipient
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.BT_DepreciationRecipient AS BusinessOperation,
	|	DocumentData.CompanyRecipient AS Organization,
	|
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                      AS AssetRef,
	|	UNDEFINED                       AS DimensionOfRevenue,
	|	UNDEFINED                       AS DimensionOfExpenses,
	|	TTIAAccountingParameters.IntangibleAsset     AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.Department      AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&Ap_nmaArticle                      AS CorItem,
	|	UNDEFINED                       AS CorIncomeDimension,
	|	UNDEFINED                       AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset     AS CorDimensionOfAssetsLiabilities,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization        AS CorCompany,
	|
	|	IntangibleAssetsAmortizationCharge.Depreciation         AS Sum,
	|	IntangibleAssetsAmortizationCharge.Depreciation         AS SumMan,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal + IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|
	|UNION ALL
	|
	|// Moving the cost for the sender
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.BO_CostSender AS BusinessOperation,
	|	DocumentData.Organization        AS Organization,
	|
	|	DocumentData.Department      AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                      AS AssetRef,
	|	UNDEFINED                       AS DimensionOfRevenue,
	|	UNDEFINED                       AS DimensionOfExpenses,
	|	TableOfIA.IntangibleAsset     AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&Ap_nmaArticle                      AS CorItem,
	|	UNDEFINED                       AS CorIncomeDimension,
	|	UNDEFINED                       AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset     AS CorDimensionOfAssetsLiabilities,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	DocumentData.CompanyRecipient AS CorCompany,
	|
	|	IACost.Cost             AS Sum,
	|	IACost.Cost             AS SumMan,
	|	IACost.LocalCost + IACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IACost.Ref = TableOfIA.Ref
	|
	|UNION ALL
	|
	|// Moving the value for the recipient
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.BT_CostRecipient AS BusinessOperation,
	|	DocumentData.CompanyRecipient AS Organization,
	|
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                      AS AssetRef,
	|	UNDEFINED                       AS DimensionOfRevenue,
	|	UNDEFINED                       AS DimensionOfExpenses,
	|	TableOfIA.IntangibleAsset     AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.Department      AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&Ap_nmaArticle                      AS CorItem,
	|	UNDEFINED                       AS CorIncomeDimension,
	|	UNDEFINED                       AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset     AS CorDimensionOfAssetsLiabilities,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization        AS CorCompany,
	|
	|	IACost.Cost             AS Sum,
	|	IACost.Cost             AS SumMan,
	|	IACost.LocalCost + IACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IACost.Ref = TableOfIA.Ref
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Department      AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.CompanyRecipient AS Dimension,
	|	UNDEFINED                       AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	IACost.LocalCost + IACost.CostTargetFinancing AS SumCompl,
	|	IACost.CostPermanentDifference + IACost.CostTargetFinancingPD AS PermanentDifference,
	|	IACost.CostTemporaryDifference + IACost.CostTargetFinancingTD AS CostTD,
	|	IACost.Cost AS SumMan,
	|	IACost.Cost AS AmountIncludingVAT,
	|	IACost.Cost AS AmountExcludingVAT,
	|
	|	TableOfIA.RowID AS FinRecordID,
	|	DocumentData.SettingUpHO_CostSender AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IACost.Ref = TableOfIA.Ref
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.CompanyRecipient AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.Organization                       AS Dimension,
	|	UNDEFINED                       AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	IACost.LocalCost + IACost.CostTargetFinancing AS SumCompl,
	|	IACost.CostPermanentDifference + IACost.CostTargetFinancingPD AS PermanentDifference,
	|	IACost.CostTemporaryDifference + IACost.CostTargetFinancingTD AS CostTD,
	|	IACost.Cost AS SumMan,
	|	IACost.Cost AS AmountIncludingVAT,
	|	IACost.Cost AS AmountExcludingVAT,
	|	
	|	TableOfIA.RowID AS FinRecordID,
	|	DocumentData.SettingUpHO_CostRecipient AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IACost.Ref = TableOfIA.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Department      AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.CompanyRecipient AS Dimension,
	|	UNDEFINED                       AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|	
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal + IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences + IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD AS PermanentDifference,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD + IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD AS CostTD,
	|	IntangibleAssetsAmortizationCharge.Depreciation AS SumMan,
	|	IntangibleAssetsAmortizationCharge.Depreciation AS AmountIncludingVAT,
	|	IntangibleAssetsAmortizationCharge.Depreciation AS AmountExcludingVAT,
	|	
	|	TableOfIA.RowID AS FinRecordID,
	|	DocumentData.SettingUpHO_DepreciationSender AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.CompanyRecipient AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.Organization        AS Dimension,
	|	UNDEFINED                       AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal + IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences + IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD AS PermanentDifference,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD + IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD AS CostTD,
	|	IntangibleAssetsAmortizationCharge.Depreciation AS SumMan,
	|	IntangibleAssetsAmortizationCharge.Depreciation AS AmountIncludingVAT,
	|	IntangibleAssetsAmortizationCharge.Depreciation AS AmountExcludingVAT,
	|	
	|	TableOfIA.RowID AS FinRecordID,
	|	DocumentData.SettingUpHO_DepreciationRecipient AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers = Undefined)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Ref AS Document,
	|	DocumentData.Organization AS Organization,
	|	BEGINOFPERIOD(DocumentData.Period, DAY) AS DateRecord,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Ref AS Document,
	|	DocumentData.CompanyRecipient AS Organization,
	|	BEGINOFPERIOD(DocumentData.Period, DAY) AS DateRecord,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCGUComposition(QueryTexts, Registers)
	
	RegisterName = "CGUComposition";

	If Not GetFunctionalOption("UseFixedAssetImpairment") Then
		Return "";
	EndIf;	
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"// The State of the binding of the IA to the CGU before the document.
	|SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset,
	|	CGUCompositionSliceLast.Organization AS Organization,
	|	CGUCompositionSliceLast.CGU AS CGU
	|	
	|INTO InitialStateOfCGU
	|
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(
	|		&BorderInFrontOfDocument,
	|			NonCurrentAsset IN (
	|								SELECT 
	|									TableOfIA.IntangibleAsset
	|								FROM DocumentDataIATable AS TableOfIA
	|								)
	|			AND
	|			Organization = &Organization) AS CGUCompositionSliceLast
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|// Transferring intangible assets to another CGU. If the CGU is different from the current value.
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|
	|	CASE
	|		WHEN DocumentData.CompanyRecipient = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Organization
	|		ELSE DocumentData.CompanyRecipient
	|	END AS Organization,
	|
	|	TableOfIA.IntangibleAsset AS NonCurrentAsset,
	|	DocumentData.CGURecipient AS CGU
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN InitialStateOfCGU AS InitialStateOfCGU
	|		ON DocumentData.CGURecipient = InitialStateOfCGU.CGU
	|		AND TableOfIA.IntangibleAsset = InitialStateOfCGU.NonCurrentAsset
	|		AND CASE
	|			WHEN DocumentData.CompanyRecipient = VALUE(Catalog.Companies.EmptyRef)
	|				THEN DocumentData.Organization
	|			ELSE DocumentData.CompanyRecipient
	|			END = InitialStateOfCGU.Organization
	|WHERE
	|	InitialStateOfCGU.CGU IS NULL
	|
	|UNION
	|
	|// clearing CGU by the sending organization 
	|// when moving to a division with a dedicated balance.
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.Organization        AS Organization,
	|	TableOfIA.IntangibleAsset     AS NonCurrentAsset,
	|	VALUE(Catalog.CashGeneratingUnits.EmptyRef) AS CGU
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.CompanyRecipient <> VALUE(Catalog.Companies.EmptyRef)
	|	AND DocumentData.CompanyRecipient <> DocumentData.Organization
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return IATransferLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return IATransferLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	IATransferLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#Region Other

// 
// Parameters:
//  Object - DocumentObject.IATransfer2_4 - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array, Undefined - 
Procedure FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DataToFill = Documents.IntangibleAssetsPhysicalCount.FillingDataBasedOnInventory(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.Move, 
							ArrayOfLineNumbers);
							
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có dòng nào yêu cầu tạo điều chuyển';
							|ru = 'В документе %1 отсутствуют строки требующие создания перемещения';
							|en = 'There are no lines which require transfer in the %1 document'; fa = 'There are no lines which require transfer in the %1 document';
							|it = 'There are no lines which require transfer in the %1 document';
							|pl = 'There are no lines which require transfer in the %1 document';
							|tr = '%1 belgesinde transfer oluşturulması gereken satır bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return;
		
	EndIf;
	
	SampleBankingDetails = DataToFill.Attributes[0];
	
	Object.ReceivingBusinessUnit = SampleBankingDetails.Department;
	
	For Each TSSampling In DataToFill.TabularSection Do
		
		If Not ValueIsFilled(Object.Organization) Then
			Object.Organization = TSSampling.LocationOrganization;
		EndIf;
		
		If Not ValueIsFilled(Object.Department) Then
			Object.Department = TSSampling.LocationDivision;
		EndIf;
		
		If Object.Organization = TSSampling.LocationOrganization
			And Object.Department = TSSampling.LocationDivision Then
			FillPropertyValues(Object.IA.Add(), TSSampling);
		EndIf;
		
	EndDo;
	
	If Object.Organization <> SampleBankingDetails.Organization
		And ValueIsFilled(Object.Organization) Then
			
		Object.CompanyRecipient = SampleBankingDetails.Organization;
		Object.BusinessOperation = Enums.BusinessTransactions.TransferIntangibleAssetsToBranchOffice;
	Else
		Object.BusinessOperation = Enums.BusinessTransactions.IATransfer;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
