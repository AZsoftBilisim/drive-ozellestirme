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
	
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.MovementOfOtherAssetsAndLiabilities") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
EndProcedure

// Adds the "Movement of other assets and liabilities" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined, ValueTableRow - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.MovementOfOtherAssetsAndLiabilities) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfOtherAssetsAndLiabilities.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.MovementOfOtherAssetsAndLiabilities);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAccountingOfOtherAssetsAndLiabilities,UseAccountingOfOtherIncomeExpenses";
	

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
	
EndProcedure

// Fills in the table of other expenses for the remaining construction expenses of the OS
//
// Parameters:
//  SelectionData_ - Structure - fields that will be used to select balances for filling in the document
//                     Date-date - the cut-off date for which the remaining balances will be received
//                     Currency       Spravochnike.Currency - the currency of the document
//                     Link-Document Link.Cost allocationprochie assets, Undefined-document
//                         that needs to be updated
//                     Organization-Reference Link.Organizations, Undefined - the Organization for which the balance will
//                                                                                be selected
//                     Type Of Article-Enum Link.Asset types-the type of register from which
//                                                                                  the balances will be obtained
//  Expenses - FormDataCollection - the expense table that the data will be placed in.
//
Procedure FillInBalancesInRegister(SelectionData_, Expenses) Export
	
	// Data on the remaining items of the order
	SamplingCosts = GetResultOfRequestForRegisterBalances(SelectionData_).Select();
	
	While SamplingCosts.Next() Do
		FillPropertyValues(Expenses.Add(), SamplingCosts);
	EndDo;
	
EndProcedure

// Fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	Source - EnumRef.TypesOfAssetAndLiabilityItems - The selected type of articles
//	Recipient - EnumRef.TypesOfAssetAndLiabilityItems - The selected type of articles
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(Source, Recipient, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("PostingData.AssetsLiabilitiesDimensionRecipient");
	ArrayOfAllProps.Add("PostingData.IncomeDimensionRecipient");
	ArrayOfAllProps.Add("PostingData.ExpensesDimensionRecipient");
	
	ArrayOfAllProps.Add("PostingData.AssetsLiabilitiesDimensionSource");
	ArrayOfAllProps.Add("PostingData.IncomeDimensionSource");
	ArrayOfAllProps.Add("PostingData.ExpensesDimensionSource");
	
	ArrayOfAllProps.Add("PostingData.AmountExcludingVAT");
	
	ArrayOfOperationDetails = New Array;
	If Recipient = Enums.TypesOfAssetAndLiabilityItems.IncomeItem Then
		ArrayOfOperationDetails.Add("PostingData.IncomeDimensionRecipient");
	ElsIf Recipient = Enums.TypesOfAssetAndLiabilityItems.ExpenseItem Then
		ArrayOfOperationDetails.Add("PostingData.ExpensesDimensionRecipient");
		ArrayOfOperationDetails.Add("PostingData.AmountExcludingVAT");
	ElsIf Recipient = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem Then
		ArrayOfOperationDetails.Add("PostingData.AssetsLiabilitiesDimensionRecipient");
	Else
		ArrayOfOperationDetails.Add("PostingData.AssetsLiabilitiesDimensionRecipient");
	EndIf;
	
	If Source = Enums.TypesOfAssetAndLiabilityItems.IncomeItem Then
		ArrayOfOperationDetails.Add("PostingData.IncomeDimensionSource");
	ElsIf Source = Enums.TypesOfAssetAndLiabilityItems.ExpenseItem Then
		ArrayOfOperationDetails.Add("PostingData.ExpensesDimensionSource");
		ArrayOfOperationDetails.Add("PostingData.AmountExcludingVAT");
	ElsIf Source = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem Then
		ArrayOfOperationDetails.Add("PostingData.AssetsLiabilitiesDimensionSource");
	Else
		ArrayOfOperationDetails.Add("PostingData.AssetsLiabilitiesDimensionSource");
	EndIf;
	
EndProcedure

// Returns the ID of the combination of the type of Registered Recording and the types of articles
//
// Parameters:
//  Increase - Boolean - an indication of an increase or decrease in other assets and liabilities.
//  Recipient - EnumRef.TypesOfAssetAndLiabilityItems - the type of items of other assets and liabilities.
//  Source - EnumRef.TypesOfAssetAndLiabilityItems - the type of items of other assets and liabilities or income and expenses.
//
// Returns:
//  String - ID of the variant Of document RegisteredRecords.
//
Function RegisteredRecordedID(Increase, Recipient, Source) Export
	
	IdStrings = New Array();
	IdStrings.Add(XMLString(Increase));
	IdStrings.Add(XMLString(Recipient));
	
	If ValueIsFilled(Source) Then
		IdStrings.Add(XMLString(Source));
	EndIf;
	
	Return StrConcat(IdStrings, "\");
	
EndFunction

// Forms the correspondence of movement names to possible combinations of articles
//
// Returns:
//  Map - text representations of document movement options.
//
Function RegisterRecordsDetails() Export
	
	DetailsList1 = New Map;
	
	TypesOfArticles = Enums.TypesOfAssetAndLiabilityItems;
	Increase = True;
	
	// Increase in assets
	DetailsList1.Insert(RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.AssetItem),
					NStr("vi = 'Tăng tài sản và giảm tài sản khác';
						|ru = 'Выполняется увеличение активов и уменьшение других активов';
						|en = 'Asset increase and other asset decrease'; fa = 'Asset increase and other asset decrease';
						|it = 'Viene eseguito l''incremento degli attivi e la diminuzione di altri attivi';
						|pl = 'Trwa zwiększenie aktywów i zmniejszenie innych aktywów';
						|tr = 'Varlıkların artışı ve diğer varlıkların azalışı gerçekleştiriliyor'"));
	DetailsList1.Insert(RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.LiabilityItem),
					NStr("vi = 'Tăng tài sản và tăng nợ phải trả';
						|ru = 'Выполняется увеличение активов и увеличение пассивов';
						|en = 'Asset increase and liability increase'; fa = 'Asset increase and liability increase';
						|it = 'Viene eseguito l''incremento degli attivi e l''incremento dei passivi';
						|pl = 'Trwa zwiększenie aktywów i zwiększenie zobowiązań';
						|tr = 'Varlıkların ve yükümlülüklerin artışı gerçekleştiriliyor'"));
	DetailsList1.Insert(RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.ExpenseItem),
					NStr("vi = 'Tăng tài sản và giảm chi phí';
						|ru = 'Выполняется увеличение активов и уменьшение расходов';
						|en = 'Asset increase and expense decrease'; fa = 'Asset increase and expense decrease';
						|it = 'Viene eseguito l''incremento degli attivi e la diminuzione delle spese';
						|pl = 'Trwa zwiększenie aktywów i zmniejszenie rozchodów';
						|tr = 'Varlıkların artışı ve giderlerin azalışı gerçekleştiriliyor'"));
	DetailsList1.Insert(RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.IncomeItem),
					NStr("vi = 'Tăng tài sản và tạo thu nhập';
						|ru = 'Выполняется увеличение активов и возникновение доходов';
						|en = 'Asset increase and income incurrence'; fa = 'Asset increase and income incurrence';
						|it = 'Viene eseguito l''incremento degli attivi e la generazione di ricavi';
						|pl = 'Trwa zwiększenie aktywów i powstanie dochodów';
						|tr = 'Varlıkların artışı ve gelirlerin oluşumu gerçekleştiriliyor'"));
	
	// Increase in liabilities
	DetailsList1.Insert(RegisteredRecordedID(Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.LiabilityItem),
					NStr("vi = 'Tăng nguồn vốn và giảm các khoản nợ khác';
						|ru = 'Выполняется увеличение пассивов и уменьшение других пассивов';
						|en = 'Liability increase and other liability decrease'; fa = 'Liability increase and other liability decrease';
						|it = 'Viene eseguito l''incremento dei passivi e la diminuzione di altri passivi';
						|pl = 'Trwa zwiększenie zobowiązań i zmniejszenie innych zobowiązań';
						|tr = 'Yükümlülüklerin artışı ve diğer yükümlülüklerin azalışı gerçekleştiriliyor'"));
	DetailsList1.Insert(RegisteredRecordedID(Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.ExpenseItem),
					NStr("vi = 'nguồn vốn tăng và chi phí phát sinh';
						|ru = 'Выполняется увеличение пассивов и возникновение расходов';
						|en = 'Liability increase and expense incurrence'; fa = 'Liability increase and expense incurrence';
						|it = 'Viene eseguito l''incremento dei passivi e la generazione dei costi';
						|pl = 'Trwa zwiększenie zobowiązań i powstanie rozchodów';
						|tr = 'Yükümlülüklerin artışı ve giderlerin oluşumu gerçekleştiriliyor'"));
	DetailsList1.Insert(RegisteredRecordedID(Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.IncomeItem),
					NStr("vi = 'Tăng nợ và giảm thu nhập';
						|ru = 'Выполняется увеличение пассивов и уменьшение доходов';
						|en = 'Liability increase and income decrease'; fa = 'Liability increase and income decrease';
						|it = 'Viene eseguito l''incremento dei passivi e la diminuzione di ricavi';
						|pl = 'Trwa zwiększenie zobowiązań i zmniejszenie dochodów';
						|tr = 'Yükümlülüklerin artışı ve gelirlerin azalışı gerçekleştiriliyor'"));
	
	// Decrease in assets
	DetailsList1.Insert(RegisteredRecordedID(Not Increase, TypesOfArticles.AssetItem, TypesOfArticles.LiabilityItem),
					NStr("vi = 'Đang giảm tài sản và giảm nguồn vốn';
						|ru = 'Выполняется уменьшение активов и уменьшение пассивов';
						|en = 'Asset decrease and liability decrease'; fa = 'Asset decrease and liability decrease';
						|it = 'Выполняется уменьшение активов и уменьшение пассивов';
						|pl = 'Asset decrease and liability decrease';
						|tr = 'Varlıkların düşüşü ve yükümlülüklerin düşüşü gerçekleştirilmektedir'"));
	DetailsList1.Insert(RegisteredRecordedID(Not Increase, TypesOfArticles.AssetItem, TypesOfArticles.ExpenseItem),
					NStr("vi = 'Đang giảm tài sản và tăng chi phí';
						|ru = 'Выполняется уменьшение активов и возникновение расходов';
						|en = 'Asset decrease and expense incurrence'; fa = 'Asset decrease and expense incurrence';
						|it = 'Выполняется уменьшение активов и возникновение расходов';
						|pl = 'Asset decrease and expense incurrence';
						|tr = 'Varlıkların düşüşü ve giderlerin ortaya çıkması gerçekleştirilmektedir'"));
	DetailsList1.Insert(RegisteredRecordedID(Not Increase, TypesOfArticles.AssetItem, TypesOfArticles.IncomeItem),
					NStr("vi = 'Đang giảm tài sản và giảm thu nhập';
						|ru = 'Выполняется уменьшение активов и уменьшение доходов';
						|en = 'Asset decrease and income decrease'; fa = 'Asset decrease and income decrease';
						|it = 'Выполняется уменьшение активов и уменьшение доходов';
						|pl = 'Asset decrease and income decrease';
						|tr = 'Varlıkların düşüşü ve gelirlerin düşüşü gerçekleştirilmektedir'"));
	
	// Reduction of liabilities
	DetailsList1.Insert(RegisteredRecordedID(Not Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.ExpenseItem),
					NStr("vi = 'Đang giảm nguồn vốn và giảm chi phí';
						|ru = 'Выполняется уменьшение пассивов и уменьшение расходов';
						|en = 'Liability decrease and expense decrease'; fa = 'Liability decrease and expense decrease';
						|it = 'Выполняется уменьшение пассивов и уменьшение расходов';
						|pl = 'Liability decrease and expense decrease';
						|tr = 'Yükümlülüklerin düşüşü ve giderlerin düşüşü gerçekleştirilmektedir'"));
	DetailsList1.Insert(RegisteredRecordedID(Not Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.IncomeItem),
					NStr("vi = 'Đang giảm nguồn vốn và tăng thu nhập';
						|ru = 'Выполняется уменьшение пассивов и возникновение доходов';
						|en = 'Liability decrease and income incurrence'; fa = 'Liability decrease and income incurrence';
						|it = 'Выполняется уменьшение пассивов и возникновение доходов';
						|pl = 'Liability decrease and income incurrence';
						|tr = 'Yükümlülüklerin düşüşü ve gelirlerin ortaya çıkması gerçekleştirilmektedir'"));
	
	Return DetailsList1;
	
EndFunction

// Returns a match in which for each identifier
// that Registered Records consist of, its value is matched 
//
// Returns:
//  Map - ID values.
//
Function IdentifierValues() Export
	
	IdentifierValues = New Map();
	RegisterRecordsDetails = RegisterRecordsDetails();
	
	BooleanType = Type("Boolean");
	TypeArticleTypes = Type("EnumRef.TypesOfAssetAndLiabilityItems");
	
	For Each RegisterRecordDetails In RegisterRecordsDetails Do
		ThisIsTypeOfArticle = False;
		IdStrings = StrSplit(RegisterRecordDetails.Key, "\");
		For Each Id In IdStrings Do
			ValueType = ?(ThisIsTypeOfArticle, TypeArticleTypes, BooleanType);
			IdValue = XMLValue(ValueType, Id);
			IdentifierValues.Insert(Id, IdValue);
			ThisIsTypeOfArticle = True;
		EndDo;
	EndDo;
	
	Return IdentifierValues;
	
EndFunction

// Sets parameters for the dynamic list of documents for the movementpassable assets.
//
// Parameters:
//	List - DynamicList - the requisite forms containing the dynamic list.
//
Procedure SetDynamicListParameters(List) Export
	
	LongDesc = RegisterRecordsDetails();
	TypesOfArticles = Enums.TypesOfAssetAndLiabilityItems;
	Increase = True;
	
	// Increase in assets
	ID = RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.AssetItem);
	List.Parameters.SetParameterValue("ReceiptOfAssetsAssets", LongDesc[ID]);
	ID = RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.LiabilityItem);
	List.Parameters.SetParameterValue("ReceiptAssetsLiabilities", LongDesc[ID]);
	ID = RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.ExpenseItem);
	List.Parameters.SetParameterValue("ReceiptAssetsExpenses", LongDesc[ID]);
	ID = RegisteredRecordedID(Increase, TypesOfArticles.AssetItem, TypesOfArticles.IncomeItem);
	List.Parameters.SetParameterValue("ReceiptOfAssetsIncome", LongDesc[ID]);
	
	// Increase in liabilities
	ID = RegisteredRecordedID(Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.LiabilityItem);
	List.Parameters.SetParameterValue("ReceiptLiabilitiesLiabilities", LongDesc[ID]);
	ID = RegisteredRecordedID(Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.ExpenseItem);
	List.Parameters.SetParameterValue("ReceiptsLiabilitiesExpenses", LongDesc[ID]);
	ID = RegisteredRecordedID(Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.IncomeItem);
	List.Parameters.SetParameterValue("ReceiptsLiabilitiesIncome", LongDesc[ID]);
	
	// Decrease in assets
	ID = RegisteredRecordedID(Not Increase, TypesOfArticles.AssetItem, TypesOfArticles.LiabilityItem);
	List.Parameters.SetParameterValue("ExpenseAssetsLiabilities", LongDesc[ID]);
	ID = RegisteredRecordedID(Not Increase, TypesOfArticles.AssetItem, TypesOfArticles.ExpenseItem);
	List.Parameters.SetParameterValue("ExpenseAssetsExpense", LongDesc[ID]);
	ID = RegisteredRecordedID(Not Increase, TypesOfArticles.AssetItem, TypesOfArticles.IncomeItem);
	List.Parameters.SetParameterValue("ExpenseAssetsIncome", LongDesc[ID]);
	
	// Reduction of liabilities
	ID = RegisteredRecordedID(Not Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.ExpenseItem);
	List.Parameters.SetParameterValue("ExpenseLiabilitiesExpenses", LongDesc[ID]);
	ID = RegisteredRecordedID(Not Increase, TypesOfArticles.LiabilityItem, TypesOfArticles.IncomeItem);
	List.Parameters.SetParameterValue("ExpenseLiabilitiesIncome", LongDesc[ID]);
	
EndProcedure

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	Source - EnumRef.TypesOfAssetAndLiabilityItems - Type of source article.
// 	Recipient - EnumRef.TypesOfAssetAndLiabilityItems - Type of recipient's article.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(Source, Recipient) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region SourceItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.PostingData";
	ChoiceParameters.AssetRef = "SourceItem";
	ChoiceParameters.ArticleType = "ItemSourceItemType";
	ChoiceParameters.FormItems.AssetRef.Add("PostingDataSourceItem");
	
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = Source = Enums.TypesOfAssetAndLiabilityItems.AssetItem
											Or Source = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem
											Or Not ValueIsFilled(Source);
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimensionSource";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("PostingDataAssetsLiabilitiesDimensionSource");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = Source = Enums.TypesOfAssetAndLiabilityItems.ExpenseItem;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionSource";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("PostingDataExpensesDimensionSource");
	#EndRegion
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = Source = Enums.TypesOfAssetAndLiabilityItems.IncomeItem;
	ChoiceParameters.DimensionOfRevenue = "IncomeDimensionSource";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("PostingDataIncomeDimensionSource");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ItemRecipient
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.PostingData";
	ChoiceParameters.AssetRef = "ItemRecipient";
	ChoiceParameters.ArticleType = "ItemRecipientItemType";
	ChoiceParameters.FormItems.AssetRef.Add("PostingDataItemRecipient");
	
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = Recipient = Enums.TypesOfAssetAndLiabilityItems.AssetItem
											Or Recipient = Enums.TypesOfAssetAndLiabilityItems.LiabilityItem
											Or Not ValueIsFilled(Recipient);
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimensionRecipient";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("PostingDataAssetsLiabilitiesDimensionRecipient");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = Recipient = Enums.TypesOfAssetAndLiabilityItems.ExpenseItem;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionRecipient";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("PostingDataExpensesDimensionRecipient");
	#EndRegion
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = Recipient = Enums.TypesOfAssetAndLiabilityItems.IncomeItem;
	ChoiceParameters.DimensionOfRevenue = "IncomeDimensionRecipient";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("PostingDataIncomeDimensionRecipient");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
		
	Return ArrayOfSelectionParameters;
	
EndFunction


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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	CASE WHEN Document.Source IN (
	|		VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem),
	|		VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem))
	|	THEN TRUE
	|	ELSE FALSE
	|	END					AS SourceAsset,
	|	CASE WHEN Document.Recipient IN (
	|		VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem),
	|		VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem))
	|	THEN TRUE
	|	ELSE FALSE
	|	END					AS RecipientAsset,
	|	Document.Date			AS Date,
	|	Document.Currency			AS Currency,
	|	Document.Source		AS Source,
	|	Document.Recipient		AS Recipient,
	|	Document.Increase		AS Increase,
	|	Document.Organization	AS Organization
	|FROM
	|	Document.MovementOfOtherAssetsAndLiabilities AS Document
	|WHERE
	|	Document.Ref = &Ref";

	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Attributes.Currency,
		Undefined,
		Attributes.Date,
		Attributes.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",	Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("Ref",					DocumentRef);
	Query.SetParameter("Organization",			Attributes.Organization);
	Query.SetParameter("DocumentDate",			Attributes.Date);
	Query.SetParameter("Period",			        Attributes.Date);
	Query.SetParameter("DocumentCurrency",		Attributes.Currency);
	Query.SetParameter("SourceAsset",			Attributes.SourceAsset);
	Query.SetParameter("RecipientAsset",		Attributes.RecipientAsset);
	Query.SetParameter("Source",				Attributes.Source);
	Query.SetParameter("Recipient",				Attributes.Recipient);
	Query.SetParameter("Increase",				Attributes.Increase);
	Query.SetParameter("ViewInWriteOffMode",		?(Attributes.Increase,AccumulationRecordType.Receipt,AccumulationRecordType.Expense));
	If (Attributes.Increase And Attributes.RecipientAsset = Attributes.SourceAsset)
		 Or (Not Attributes.Increase And Not Attributes.RecipientAsset = Attributes.SourceAsset) Then
		ViewInReceiptForm = AccumulationRecordType.Expense;
	Else
		ViewInReceiptForm = AccumulationRecordType.Receipt;
	EndIf;
	Query.SetParameter("ViewInReceiptForm",	ViewInReceiptForm);
	Query.SetParameter("BusinessOperation",	Enums.BusinessTransactions.RecordOfOtherAssetsLiabilities);
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTTData(Query, QueryTexts)
	
	RegisterName = "TTData"; 
	
	QueryText = "
	// Recipient
	|SELECT
	|	CASE WHEN DATEDIFF(Rows.DateRecord, &DocumentDate, DAY) = 0
	|				OR Rows.DateRecord = DATETIME(1, 1, 1) THEN
	|		&DocumentDate
	|	ELSE
	|		Rows.DateRecord
	|	END                                                AS Period,
	|	&Organization                                         AS Organization,
	|	&BusinessOperation                               AS BusinessOperation,
	|	Rows.ReceivingBusinessUnit                       AS Department,
	|	Rows.LineOfBusinessRecipient             AS LineOfBusiness,
	|	&ViewInWriteOffMode                                  AS RecordType,
	|	Rows.LineNumber                                   AS LineNumber,
	|
	|	// Recipient
	|	Rows.ItemRecipient                              AS AssetRef,
	|	CASE WHEN &Recipient = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem) THEN
	|		Rows.ExpensesDimensionRecipient
	|	WHEN &Recipient = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem) THEN
	|		Rows.IncomeDimensionRecipient
	|	ELSE
	|		Rows.AssetsLiabilitiesDimensionRecipient
	|	END                                                AS Dimension,
	|
	|	// Sum
	|	Rows.Sum * &ConversionRateToManCurrency       AS SumMan,
	|	Rows.AmountExcludingVAT * &ConversionRateToManCurrency AS AmountExcludingVATMan,
	|	Rows.Sum                                         AS Sum,
	|	Rows.AmountExcludingVAT                                   AS AmountExcludingVAT,
	|
	|	// The register type
	|	CASE WHEN &Recipient = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem) THEN
	|		""Expenses""
	|	WHEN &Recipient = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem) THEN
	|		""Income""
	|	ELSE
	|		""AssetsLiabilities""
	|	END                                                AS RegisterType_,
	|	&Recipient                                          AS ArticleType,
	|	NOT &Increase                                       AS WriteOff,
	|	&IDOfUnusedFinRecord                AS FinRecordID,
	|	UNDEFINED                                         AS BusinessTransactionSetting
	|
	|INTO TTData
	|
	|FROM
	|	Document.MovementOfOtherAssetsAndLiabilities.PostingData AS Rows
	|WHERE 
	|	Rows.Ref = &Ref
	|
	|UNION ALL
	|
	// Source
	|SELECT
	|	CASE WHEN DATEDIFF(Rows.DateRecord, &DocumentDate, DAY) = 0
	|				OR Rows.DateRecord = DATETIME(1, 1, 1) THEN
	|		&DocumentDate
	|	ELSE
	|		Rows.DateRecord
	|	END                                                AS Period,
	|	&Organization                                         AS Organization,
	|	&BusinessOperation                               AS BusinessOperation,
	|	Rows.BusinessUnitSource                         AS Department,
	|	Rows.LineOfBusinessSource               AS LineOfBusiness,
	|	&ViewInReceiptForm                               AS RecordType,
	|	Rows.LineNumber                                   AS LineNumber,
	|
	|	// Source
	|	Rows.SourceItem                                AS AssetRef,
	|	CASE WHEN &Source = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem) THEN
	|		Rows.ExpensesDimensionSource
	|	WHEN &Source = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem) THEN
	|		Rows.IncomeDimensionSource
	|	ELSE
	|		Rows.AssetsLiabilitiesDimensionSource
	|	END                                                AS Dimension,
	|
	|	// Sum
	|	Rows.Sum * &ConversionRateToManCurrency       AS SumMan,
	|	Rows.AmountExcludingVAT * &ConversionRateToManCurrency AS AmountExcludingVATMan,
	|	Rows.Sum                                         AS Sum,
	|	Rows.AmountExcludingVAT                                   AS AmountExcludingVAT,
	|
	|	// The register type
	|	CASE WHEN &Source = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem) THEN
	|		""Expenses""
	|	WHEN &Source = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem) THEN
	|		""Income""
	|	ELSE
	|		""AssetsLiabilities""
	|	END                                                AS RegisterType_,
	|	&Source                                            AS ArticleType,
	|	&Increase                                          AS WriteOff,
	|	&IDOfUnusedFinRecord                AS FinRecordID,
	|	UNDEFINED                                         AS BusinessTransactionSetting
	|
	|FROM
	|	Document.MovementOfOtherAssetsAndLiabilities.PostingData AS Rows
	|WHERE 
	|	Rows.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
		
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTData", QueryTexts) Then
		QueryTextTTData(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;

	QueryText = "
	|SELECT
	|	Rows.Period					AS Period,
	|	CASE WHEN Rows.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem) THEN
	|		// For articles of liabilities, the sign changes to the opposite, i.e. ""increase in liabilities"" is ""Expense"" in the register, and vice versa
	|		CASE WHEN Rows.RecordType = VALUE(AccumulationRecordType.Receipt) THEN VALUE(AccumulationRecordType.Expense) ELSE VALUE(AccumulationRecordType.Receipt) END
	|	ELSE
	|		Rows.RecordType
	|	END							AS RecordType,
	|	Rows.Organization				AS Organization,
	|	Rows.Department			AS Department,
	|	Rows.LineOfBusiness	AS LineOfBusiness,
	|	Rows.AssetRef					AS AssetRef,
	|	CASE
	|		WHEN Rows.Dimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE Rows.Dimension
	|	END							AS Dimension,
	|	Rows.SumMan					AS Sum
	|FROM
	|	TTData AS Rows
	|WHERE 
	|	Rows.RegisterType_ = ""AssetsLiabilities""
	|
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTData", QueryTexts) Then
		QueryTextTTData(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	Rows.LineNumber                    AS LineNumber,
	|	Rows.Period                         AS Period,
	|	Rows.BusinessOperation          AS BusinessOperation,
	|	Rows.Organization                    AS Organization,
	|	Rows.Department                  AS Department,
	|	Rows.LineOfBusiness        AS LineOfBusiness,
	|	Rows.AssetRef                         AS IncomeItem,
	|	Rows.Dimension                      AS DimensionOfRevenue,
	|	Rows.SumMan                       AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN Rows.AmountExcludingVATMan
	|		ELSE 0 END)                    AS SumMan,
	|	Rows.FinRecordID         AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTData AS Rows
	|WHERE 
	|	Rows.RegisterType_ = ""Income""
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTData", QueryTexts) Then
		QueryTextTTData(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	Source.Period						AS Period,
	|	Source.Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.FlowOfAssetsLiabilitiesDueToAssetsLiabilities) AS BusinessOperation,
	|
	|	Source.Department				AS Department,
	|	Source.LineOfBusiness	AS LineOfBusiness,
	|	Source.AssetRef						AS AssetRef,
	|	UNDEFINED						AS DimensionOfRevenue,
	|	UNDEFINED						AS DimensionOfExpenses,
	|	Source.Dimension					AS AssetsLiabilitiesDimension,
	|
	|	Recipient.Department			AS DebitBusinessUnit,
	|	Recipient.LineOfBusiness	AS CorLineOfBusiness,
	|	Recipient.AssetRef					AS CorItem,
	|	UNDEFINED						AS CorIncomeDimension,
	|	UNDEFINED						AS CorExpenditureDimension,
	|	Recipient.Dimension				AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan					AS Sum,
	|	Source.AmountExcludingVATMan				AS SumMan,
	|	0									AS SumCompl,
	|	
	|	&DocumentCurrency					AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND Source.WriteOff
	|		AND NOT Recipient.WriteOff
	|		AND Source.ArticleType IN (VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem),
	|							VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem))
	|		AND Recipient.ArticleType IN (VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem),
	|								VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem))
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.OtherIncomeAssetsLiabilities) AS BusinessOperation,
	|
	|	Source.Department				AS Department,
	|	Source.LineOfBusiness	AS LineOfBusiness,
	|	Source.AssetRef						AS AssetRef,
	|	Source.Dimension					AS DimensionOfRevenue,
	|	UNDEFINED						AS DimensionOfExpenses,
	|	UNDEFINED						AS AssetsLiabilitiesDimension,
	|
	|	Recipient.Department			AS DebitBusinessUnit,
	|	Recipient.LineOfBusiness	AS CorLineOfBusiness,
	|	Recipient.AssetRef					AS CorItem,
	|	UNDEFINED						AS CorIncomeDimension,
	|	UNDEFINED						AS CorExpenditureDimension,
	|	Recipient.Dimension				AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan					AS Sum,
	|	Source.AmountExcludingVATMan				AS SumMan,
	|	0									AS SumCompl,
	|	
	|	&DocumentCurrency					AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND Source.WriteOff
	|		AND NOT Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses) AS BusinessOperation,
	|
	|	Source.Department				AS Department,
	|	Source.LineOfBusiness	AS LineOfBusiness,
	|	Source.AssetRef						AS AssetRef,
	|	UNDEFINED						AS DimensionOfRevenue,
	|	Source.Dimension					AS DimensionOfExpenses,
	|	UNDEFINED						AS AssetsLiabilitiesDimension,
	|
	|	Recipient.Department			AS DebitBusinessUnit,
	|	Recipient.LineOfBusiness	AS CorLineOfBusiness,
	|	Recipient.AssetRef					AS CorItem,
	|	UNDEFINED						AS CorIncomeDimension,
	|	UNDEFINED						AS CorExpenditureDimension,
	|	Recipient.Dimension				AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan					AS Sum,
	|	CASE
	|		WHEN Source.AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			Source.AmountExcludingVATMan
	|	END AS SumMan,
	|	0									AS SumCompl,
	|	
	|	&DocumentCurrency					AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND Source.WriteOff
	|		AND NOT Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.WriteOffOtherIncome) AS BusinessOperation,
	|
	|	Source.Department				AS Department,
	|	Source.LineOfBusiness	AS LineOfBusiness,
	|	Source.AssetRef						AS AssetRef,
	|	Source.Dimension					AS DimensionOfRevenue,
	|	UNDEFINED						AS DimensionOfExpenses,
	|	UNDEFINED						AS AssetsLiabilitiesDimension,
	|
	|	Recipient.Department			AS DebitBusinessUnit,
	|	Recipient.LineOfBusiness	AS CorLineOfBusiness,
	|	Recipient.AssetRef					AS CorItem,
	|	UNDEFINED						AS CorIncomeDimension,
	|	UNDEFINED						AS CorExpenditureDimension,
	|	Recipient.Dimension				AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan					AS Sum,
	|	Source.AmountExcludingVATMan				AS SumMan,
	|	0									AS SumCompl,
	|	
	|	&DocumentCurrency					AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND Source.WriteOff
	|		AND NOT Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.OtherExpensesLiabilities) AS BusinessOperation,
	|
	|	Source.Department				AS Department,
	|	Source.LineOfBusiness	AS LineOfBusiness,
	|	Source.AssetRef						AS AssetRef,
	|	UNDEFINED						AS DimensionOfRevenue,
	|	Source.Dimension					AS DimensionOfExpenses,
	|	UNDEFINED						AS AssetsLiabilitiesDimension,
	|
	|	Recipient.Department			AS DebitBusinessUnit,
	|	Recipient.LineOfBusiness	AS CorLineOfBusiness,
	|	Recipient.AssetRef					AS CorItem,
	|	UNDEFINED						AS CorIncomeDimension,
	|	UNDEFINED						AS CorExpenditureDimension,
	|	Recipient.Dimension				AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan					AS Sum,
	|	CASE
	|		WHEN Source.AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			Source.AmountExcludingVATMan
	|	END AS SumMan,
	|	0									AS SumCompl,
	|	
	|	&DocumentCurrency					AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND Source.WriteOff
	|		AND NOT Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization					AS Organization,
	|	VALUE(Enum.BusinessTransactions.OtherExpensesLiabilities) AS BusinessOperation,
	|
	|	Recipient.Department				AS Department,
	|	Recipient.LineOfBusiness	AS LineOfBusiness,
	|	Recipient.AssetRef						AS AssetRef,
	|	UNDEFINED							AS DimensionOfRevenue,
	|	UNDEFINED							AS DimensionOfExpenses,
	|	Recipient.Dimension					AS AssetsLiabilitiesDimension,
	|
	|	Source.Department				AS DebitBusinessUnit,
	|	Source.LineOfBusiness	AS CorLineOfBusiness,
	|	Source.AssetRef						AS CorItem,
	|	UNDEFINED							AS CorIncomeDimension,
	|	Source.Dimension					AS CorExpenditureDimension,
	|	UNDEFINED							AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan						AS Sum,
	|	CASE
	|		WHEN Source.AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			Source.AmountExcludingVATMan
	|	END									AS SumMan,
	|	0										AS SumCompl,
	|	
	|	&DocumentCurrency						AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND NOT Source.WriteOff
	|		AND Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization					AS Organization,
	|	VALUE(Enum.BusinessTransactions.WriteOffOtherIncome) AS BusinessOperation,
	|
	|	Recipient.Department				AS Department,
	|	Recipient.LineOfBusiness	AS LineOfBusiness,
	|	Recipient.AssetRef						AS AssetRef,
	|	UNDEFINED							AS DimensionOfRevenue,
	|	UNDEFINED							AS DimensionOfExpenses,
	|	Recipient.Dimension					AS AssetsLiabilitiesDimension,
	|
	|	Source.Department				AS DebitBusinessUnit,
	|	Source.LineOfBusiness	AS CorLineOfBusiness,
	|	Source.AssetRef						AS CorItem,
	|	Source.Dimension					AS CorIncomeDimension,
	|	UNDEFINED							AS CorExpenditureDimension,
	|	UNDEFINED							AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan						AS Sum,
	|	Source.AmountExcludingVATMan				AS SumMan,
	|	0										AS SumCompl,
	|	
	|	&DocumentCurrency						AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND NOT Source.WriteOff
	|		AND Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization					AS Organization,
	|	VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses) AS BusinessOperation,
	|
	|	Recipient.Department				AS Department,
	|	Recipient.LineOfBusiness	AS LineOfBusiness,
	|	Recipient.AssetRef						AS AssetRef,
	|	UNDEFINED							AS DimensionOfRevenue,
	|	UNDEFINED							AS DimensionOfExpenses,
	|	Recipient.Dimension					AS AssetsLiabilitiesDimension,
	|
	|	Source.Department				AS DebitBusinessUnit,
	|	Source.LineOfBusiness	AS CorLineOfBusiness,
	|	Source.AssetRef						AS CorItem,
	|	UNDEFINED							AS CorIncomeDimension,
	|	Source.Dimension					AS CorExpenditureDimension,
	|	UNDEFINED							AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan						AS Sum,
	|	CASE
	|		WHEN Source.AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			Source.AmountExcludingVATMan
	|	END									AS SumMan,
	|	0										AS SumCompl,
	|	
	|	&DocumentCurrency						AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND NOT Source.WriteOff
	|		AND Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Source.Period						AS Period,
	|	Source.Organization					AS Organization,
	|	VALUE(Enum.BusinessTransactions.OtherIncomeAssetsLiabilities) AS BusinessOperation,
	|
	|	Recipient.Department				AS Department,
	|	Recipient.LineOfBusiness	AS LineOfBusiness,
	|	Recipient.AssetRef						AS AssetRef,
	|	UNDEFINED							AS DimensionOfRevenue,
	|	UNDEFINED							AS DimensionOfExpenses,
	|	Recipient.Dimension					AS AssetsLiabilitiesDimension,
	|
	|	Source.Department				AS DebitBusinessUnit,
	|	Source.LineOfBusiness	AS CorLineOfBusiness,
	|	Source.AssetRef						AS CorItem,
	|	Source.Dimension					AS CorIncomeDimension,
	|	UNDEFINED							AS CorExpenditureDimension,
	|	UNDEFINED							AS CorDimensionOfAssetsLiabilities,
	|	
	|	Source.SumMan						AS Sum,
	|	Source.AmountExcludingVATMan				AS SumMan,
	|	0										AS SumCompl,
	|	
	|	&DocumentCurrency						AS Currency,
	|	Source.Sum						AS AmountInCurrency
	|	
	|FROM
	|	TTData AS Source
	|	INNER JOIN TTData AS Recipient
	|	ON Source.LineNumber = Recipient.LineNumber
	|		AND NOT Source.WriteOff
	|		AND Recipient.WriteOff
	|		AND Source.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem)
	|		AND Recipient.ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTData", QueryTexts) Then
		QueryTextTTData(Query, QueryTexts);
	EndIf; 

	QueryText = "
	|SELECT
	|	Rows.LineNumber                    AS LineNumber,
	|	Rows.Period                         AS Period,
	|	// always a parish, because an expense is made only by an expense allocation document
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Rows.Organization                    AS Organization,
	|	Rows.Department                  AS Department,
	|	Rows.LineOfBusiness        AS LineOfBusiness,
	|	Rows.AssetRef                         AS ExpenseItem,
	|	Rows.Dimension                      AS DimensionOfExpenses,
	|	UNDEFINED                          AS VATActivityType,
	|
	|	// for a flow reduction operation, the sign will be negative
	|	CASE
	|		WHEN Rows.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|			THEN Rows.SumMan
	|		ELSE -Rows.SumMan
	|	END                                 AS AmountIncludingVAT,
	|	CASE
	|		WHEN Rows.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|			THEN Rows.AmountExcludingVATMan
	|		ELSE -Rows.AmountExcludingVATMan
	|	END                                 AS AmountExcludingVAT,
	|	0                                     AS AmountExcludingVATMan,
	|
	|	0                                     AS AmountIncludingVATCompl,
	|	0                                     AS AmountExcludingVATCompl,
	|	0                                     AS PermanentDifference,
	|	0                                     AS CostTD,
	|
	|	Rows.BusinessOperation          AS BusinessOperation,
	|	UNDEFINED                          AS ItemsLocationAttributes,
	|	Rows.FinRecordID         AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTData AS Rows
	|WHERE 
	|	Rows.RegisterType_ = ""Expenses""
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTData", QueryTexts) Then
		QueryTextTTData(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	Rows.Period                  AS Period,
	|	Rows.RecordType             AS RecordType,
	|	&Ref                        AS ExpenseReceiptDocument,
	|	Rows.Organization             AS Organization,
	|	Rows.Department           AS Department,
	|	Rows.LineOfBusiness AS LineOfBusiness,
	|	Rows.AssetRef                  AS ExpenseItem,
	|	Rows.Dimension               AS DimensionOfExpenses,
	|	UNDEFINED                   AS AssetsLiabilitiesDimension,
	|	UNDEFINED                   AS LotVendorAttributes,
	|	UNDEFINED                   AS ItemsLocationAttributes,
	|	UNDEFINED                   AS VATActivityType,
	|	
	|	Rows.SumMan                AS Cost,
	|	Rows.AmountExcludingVATMan          AS CostExcludingVAT,
	|	0                              AS VATManag,
	|
	|	0                              AS LocalCost,
	|	0                              AS VATLocal,
	|	0                              AS PermanentDifference,
	|	0                              AS CostTD,
	|	Rows.BusinessOperation   AS BusinessOperation,
	|	Rows.FinRecordID  AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTData AS Rows
	|WHERE 
	|	Rows.RegisterType_ = ""Expenses""
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function GetResultOfRequestForRegisterBalances(SelectionData_)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	// Recalculation of the amount
	Query.SetParameter("Currency",			SelectionData_.Currency);
	Query.SetParameter("CurrencyOfMan",		Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("BaseCurrency",	SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
	// Selection parameters
	Query.SetParameter("ArticleType",		SelectionData_.ArticleType);
	Query.SetParameter("Ref",			SelectionData_.Ref);
	Query.SetParameter("Organization",	SelectionData_.Organization);
	Query.SetParameter("Boundary",		New Boundary(EndOfDay(SelectionData_.Date), BoundaryType.Including));
	
	Query.Text =
	"SELECT
	|	""AssetBalanceSheetName"" AS AssetLiability,
	|	T.Ref AS Ref
	|INTO TTArticles
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems AS T
	|WHERE
	|	T.AssetLiability = VALUE(Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName)
	|	AND &ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.AssetItem)
	|
	|UNION ALL
	|
	|SELECT
	|	""Liabilities"" AS AssetLiability,
	|	T.Ref
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems AS T
	|WHERE
	|	T.AssetLiability = VALUE(Enum.KindsOfBalanceSheetStatementItems.Liabilities)
	|	AND &ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.LiabilityItem)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Organization					AS Organization,
	|	NestedQuery.Department				AS Department,
	|	NestedQuery.AssetRef						AS AssetRef,
	|	NestedQuery.DimensionOfExpenses			AS DimensionOfExpenses,
	|	NestedQuery.DimensionOfRevenue			AS DimensionOfRevenue,
	|	NestedQuery.AssetsLiabilitiesDimension	AS AssetsLiabilitiesDimension,
	|	SUM(NestedQuery.Sum)				AS Sum
	|INTO TTExpenses
	|FROM
	|	(
	//	Other expenses
	|	SELECT
	|		Register.Organization				AS Organization,
	|		Register.Department			AS Department,
	|		Register.ExpenseItem			AS AssetRef,
	|		Register.DimensionOfExpenses		AS DimensionOfExpenses,
	|		UNDEFINED					AS DimensionOfRevenue,
	|		UNDEFINED					AS AssetsLiabilitiesDimension,
	|		Register.SumBalance			AS Sum
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(
	|			&Boundary,
	|			Organization = &Organization
	|			AND &ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem)) AS Register
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Register.Organization				AS Organization,
	|		Register.Department			AS Department,
	|		Register.ExpenseItem			AS AssetRef,
	|		Register.DimensionOfExpenses		AS DimensionOfExpenses,
	|		UNDEFINED					AS DimensionOfRevenue,
	|		UNDEFINED					AS AssetsLiabilitiesDimension,
	|		CASE WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense) THEN
	|			Register.Sum
	|		ELSE
	|			-Register.Sum
	|		END							AS Sum
	|	FROM
	|		AccumulationRegister.OtherExpenses AS Register
	|	WHERE
	|		Register.Recorder = &Ref
	|		AND &ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.ExpenseItem)
	|	
	|	UNION ALL
	|	
	//	Other income
	|	SELECT
	|		Register.Organization				AS Organization,
	|		Register.Department			AS Department,
	|		Register.IncomeItem			AS AssetRef,
	|		UNDEFINED					AS DimensionOfExpenses,
	|		Register.DimensionOfRevenue		AS DimensionOfRevenue,
	|		UNDEFINED					AS AssetsLiabilitiesDimension,
	|		Register.SumTurnover				AS Sum
	|	FROM
	|		AccumulationRegister.OtherIncome.Turnovers(,
	|			&Boundary,
	|			,
	|			Organization = &Organization
	|			AND &ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem)) AS Register
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Register.Organization				AS Organization,
	|		Register.Department			AS Department,
	|		Register.IncomeItem			AS AssetRef,
	|		UNDEFINED					AS DimensionOfExpenses,
	|		Register.DimensionOfRevenue		AS DimensionOfRevenue,
	|		UNDEFINED					AS AssetsLiabilitiesDimension,
	|		CASE WHEN Register.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness THEN
	|			Register.Sum
	|		ELSE
	|			-Register.Sum
	|		END							AS Sum
	|	FROM
	|		AccumulationRegister.OtherIncome AS Register
	|	WHERE
	|		Register.Recorder = &Ref
	|		AND &ArticleType = VALUE(Enum.TypesOfAssetAndLiabilityItems.IncomeItem)
	|	
	|	UNION ALL
	|	
	//	Other assets and liabilities
	|	SELECT
	|		Register.Organization				AS Organization,
	|		UNDEFINED					AS Department,
	|		Register.AssetRef					AS AssetRef,
	|		UNDEFINED					AS DimensionOfExpenses,
	|		UNDEFINED					AS DimensionOfRevenue,
	|		Register.Dimension				AS AssetsLiabilitiesDimension,
	|		Register.SumBalance			AS Sum
	|	FROM
	|		AccumulationRegister.OtherAssetsLiabilities.Balance(
	|			&Boundary,
	|			Organization = &Organization
	|			AND AssetRef IN (SELECT T.Ref FROM TTArticles AS T)) AS Register
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Register.Organization				AS Organization,
	|		UNDEFINED					AS Department,
	|		Register.AssetRef					AS AssetRef,
	|		UNDEFINED					AS DimensionOfExpenses,
	|		UNDEFINED					AS DimensionOfRevenue,
	|		Register.Dimension				AS AssetsLiabilitiesDimension,
	|		CASE WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense) AND T.AssetLiability = ""AssetBalanceSheetName"" THEN
	|			Register.Sum // AssetBalanceSheetName
	|		WHEN Register.RecordType = VALUE(AccumulationRecordType.Receipt) AND T.AssetLiability = ""AssetBalanceSheetName"" THEN
	|			-Register.Sum // AssetBalanceSheetName
	|		WHEN Register.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Register.Sum // Liabilities
	|		ELSE
	|			-Register.Sum // Liabilities
	|		END							AS Sum
	|	FROM
	|		AccumulationRegister.OtherAssetsLiabilities AS Register
	|		
	|		INNER JOIN
	|			TTArticles AS T
	|		ON
	|			Register.AssetRef = T.Ref
	|	WHERE
	|		Register.Recorder = &Ref
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Department,
	|	NestedQuery.AssetRef,
	|	NestedQuery.DimensionOfExpenses,
	|	NestedQuery.DimensionOfRevenue,
	|	NestedQuery.AssetsLiabilitiesDimension
	|
	|HAVING
	|	SUM(NestedQuery.Sum) <> 0
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTExpenses.Organization				AS Organization,
	|	TTExpenses.Department				AS Department,
	|	TTExpenses.AssetRef					AS AssetRef,
	|	TTExpenses.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TTExpenses.DimensionOfRevenue			AS DimensionOfRevenue,
	|	TTExpenses.AssetsLiabilitiesDimension	AS AssetsLiabilitiesDimension,
	|
	|	ISNULL(ExpenseItems.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) AS AllocationOption,
	|
	|	CASE WHEN &CurrencyOfMan = &Currency
	|			OR ManCourses.Currency IS NULL
	|			OR ExRates.Currency IS NULL
	|			OR ExRates.CourseNumerator * ManCourses.CourseDenominator = 0 THEN
	|		TTExpenses.Sum
	|	ELSE
	|		CAST((TTExpenses.Sum * ManCourses.CourseNumerator * ExRates.CourseDenominator) / (ExRates.CourseNumerator * ManCourses.CourseDenominator) AS NUMBER(31,2))
	|	END AS Sum
	|FROM
	|	TTExpenses AS TTExpenses
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = TTExpenses.AssetRef
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Boundary,
	|									(NOT &CurrencyOfMan = &Currency AND Currency = &CurrencyOfMan) AND BaseCurrency = &BaseCurrency) AS ManCourses
	|		ON TRUE
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Boundary,
	|									(NOT &CurrencyOfMan = &Currency AND Currency = &Currency) AND BaseCurrency = &BaseCurrency) AS ExRates
	|		ON TRUE
	|
	|ORDER BY
	|	Organization,
	|	Department,
	|	AssetRef,
	|	DimensionOfExpenses,
	|	DimensionOfRevenue,
	|	AssetsLiabilitiesDimension
	|";
	
	SetPrivilegedMode(True);
	
	Return Query.Execute();
	
EndFunction

#EndRegion

#EndRegion

#EndIf
