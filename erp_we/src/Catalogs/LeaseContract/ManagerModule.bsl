#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Searches for a valid contract for a document.
// If one valid contract is found, it returns a link to it, otherwise it returns an empty link.
// 
// Parameters:
// 	Organization - CatalogRef.Companies - 
// 	Partner - CatalogRef.Partners - 
// 	Counterparty - CatalogRef.Counterparties - 
// 	CurContract - CatalogRef.LeaseContract -
// 	ContractType - EnumRef.TypesOfLeaseContracts -
// 	
// Returns:
// 	CatalogRef.LeaseContract - 
Function DefaultContract(Organization, Partner, Counterparty, CurContract, ContractType = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	LeaseContract.Ref AS Ref
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	(NOT LeaseContract.DeletionMark)
	|	AND LeaseContract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND LeaseContract.Partner = &Partner
	|	AND LeaseContract.Counterparty = &Counterparty
	|	AND LeaseContract.Organization = &Organization
	|	AND LeaseContract.Ref = &CurContract
	|	AND (LeaseContract.ContractType = &ContractType
	|		OR &ContractType = UNDEFINED)
	|;
	|
	|SELECT ALLOWED TOP 2
	|	LeaseContract.Ref AS Ref
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	(NOT LeaseContract.DeletionMark)
	|	AND LeaseContract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND LeaseContract.Partner = &Partner
	|	AND LeaseContract.Counterparty = &Counterparty
	|	AND LeaseContract.Organization = &Organization
	|	AND (LeaseContract.ContractType = &ContractType
	|		OR &ContractType = UNDEFINED)
	|";
	Query.SetParameter("CurContract", CurContract);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ContractType", ContractType);
	
	ResultsArray = Query.ExecuteBatch();
	
	If Not ResultsArray[0].IsEmpty() Then
		
		Selection = ResultsArray[0].Select();
		Selection.Next();
		
		DefaultContract = Selection.Ref;
		
	Else
		Selection = ResultsArray[1].Select();
	
		If Not Selection.Next() Then
			DefaultContract = Catalogs.LeaseContract.EmptyRef();
		ElsIf Selection.Count() = 1 Then
			DefaultContract = Selection.Ref;
		Else
			DefaultContract = Catalogs.LeaseContract.EmptyRef();
		EndIf;
	EndIf;
	
	Return DefaultContract;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//  Array - a list of the names of the object's details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Partner");
	Result.Add("Counterparty");
	Result.Add("Organization");
	Result.Add("Department");
	Result.Add("LineOfBusiness");
	Result.Add("ForeignCurrencyTransaction");
	Result.Add("KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments");
	Result.Add("ARAPCurrency");
	
	Result.Add("AssetHolder");
	Result.Add("HasSecurityDeposit");
	Result.Add("ThereIsBuyoutOfLeasedAssets");
	Result.Add("ThereIsPrepaymentOfBuyoutValue");
	
	Result.Add("FinancialAccountingGroup");
	
	Result.Add("ContractType");
	Result.Add("MethodForDeterminingCostOfAssets;MethodOfDeterminingTheValueOfAssetsDiscounting,MethodOfDeterminingTheValueOfAssetsAtTheirActualCost");
	Result.Add("RecognizeLeasedItemsInLocalAccounting;OptionToReflectAllInAccounting,OptionOfReflectionInReglAccounting,OptionOfReflectionInTheAccountingOfUPR");
	Result.Add("RecognizeLeasedAssetsInManagementAccounting;OptionToReflectAllInAccounting,OptionOfReflectionInReglAccounting,OptionOfReflectionInTheAccountingOfUPR");
	

	Return Result;
	
EndFunction

// Returns the available types of payment on the contract
//
// Parameters:
//    Contract - CatalogRef.LeaseContract - .
//
// Returns:
//    Array - Types of accruals available under the contract.
//
Function TypesOfPaymentsUnderAgreement(Contract) Export
	
	Result = New Array;
	Result.Add(Enums.TypesOfLeasePayments.RentalService);
	
	If Not ValueIsFilled(Contract) Then
		Return Result;
	EndIf;
	
	Attributes = "HasSecurityDeposit,ThereIsBuyoutOfLeasedAssets,KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments";
	AttributesValues = Common.ObjectAttributesValues(Contract, Attributes);
	
	If AttributesValues.HasSecurityDeposit Then
		Result.Add(Enums.TypesOfLeasePayments.DepositPayment);
	EndIf;

	If AttributesValues.ThereIsBuyoutOfLeasedAssets Then
		Result.Add(Enums.TypesOfLeasePayments.BuyoutValue);
	EndIf;
	
	If AttributesValues.KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments Then
		Result.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
	EndIf;

	Return Result;
	
EndFunction

// Returns the document of the conclusion of the lease Contract
//
// Parameters:
//	Contract - CatalogRef.LeaseContract
//
// Returns:
//	DocumentRef.SigningOfLeaseContract
//
Function DocumentOfConclusionOfContractOfLease(Contract) Export
	
	Query = New Query;
	Query.SetParameter("Contract", Contract);
	Query.Text = "SELECT TOP 1
	|	SigningOfLeaseContract.Ref
	|FROM
	|	Document.SigningOfLeaseContract AS SigningOfLeaseContract
	|WHERE
	|	SigningOfLeaseContract.Posted
	|	AND SigningOfLeaseContract.Contract = &Contract
	|
	|ORDER BY
	|	SigningOfLeaseContract.Date DESC";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Documents.SigningOfLeaseContract.EmptyRef();
	EndIf;
	
EndFunction

// Returns the flag of the need for paperwork "Application for the import of goods from the EAEU"
//
// Parameters:
//	Contract - CatalogRef.LeaseContract - The Contract for which it is required to check the need for applications.
//
// Returns:
//	Boolean - a sign of the need to issue an application for the import of goods
//
Function RegistrationOfApplicationsForImportOfGoodsFromEAEUIsRequired(Contract) Export
	
	Return Common.ObjectAttributeValue(Contract, "RegisterImportApplications");
	
EndFunction

// Initializes parameters for filling in VAT taxation for purchases
//
// Parameters:
//  Object		- CatalogObject.LeaseContract, FormDataStructure	- Contract for which you need to get parameters.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases.
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillParameters.Counterparty     = Object.Counterparty;
	FillParameters.RentalService = True;    
	FillParameters.Period = ?(ValueIsFilled(Object.ValidityStartDate),Object.ValidityStartDate, CurrentSessionDate());
	FillParameters.RentalServiceTaxAgent = (Object.ContractType = Enums.TypesOfLeaseContracts.Lease
														And Object.AssetHolder = Enums.LeasedAssetHolder.Lessor);
	
	FillParameters.ImportOfGoodsFromCustomsUnion = Object.ContractType = Enums.TypesOfLeaseContracts.Leasing
															And Object.RegisterImportApplications;
	
	Return FillParameters;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization, ForeignCurrencyTransaction";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty, ForeignCurrencyTransaction";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
EndProcedure

#Region Commands

// Adds a command to create the directory "lease Agreements".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//	- ValueTableRow: See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	- Undefined
//
Function AddGenerateCommand(GenerationCommands) Export
	
	CatalogMetadata = Metadata.Catalogs.LeaseContract;
	
	If AccessRight("Insert", CatalogMetadata) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = CatalogMetadata.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(CatalogMetadata);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	CommandDetails = Documents.SigningOfLeaseContract.AddGenerateCommand(GenerationCommands, 1);
	If CommandDetails <> Undefined Then
		CommandDetails.Importance = "Important";
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "Status", Enums.CounterpartyContractStatuses.Valid);
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "DeletionMark", False);
	EndIf;

	CommandDetails = Documents.FixedAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands, 2);
	If CommandDetails <> Undefined Then
		CommandDetails.Importance = "Important";
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "Status", Enums.CounterpartyContractStatuses.Valid);
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "DeletionMark", False);
	EndIf;
	
	CommandDetails = Documents.ReceivingLeaseServices.AddGenerateCommand(GenerationCommands, 3);
	If CommandDetails <> Undefined Then
		CommandDetails.Importance = "Important";
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "Status", Enums.CounterpartyContractStatuses.Valid);
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "DeletionMark", False);
	EndIf;

	CommandDetails = Documents.LeaseTermAdjustment.AddGenerateCommand(GenerationCommands, 4);
	If CommandDetails <> Undefined Then
		CommandDetails.Importance = "Important";
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "Status", Enums.CounterpartyContractStatuses.Valid);
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "DeletionMark", False);
	EndIf;
	
	CommandDetails = Documents.VendorInvoiceLeasedAssets.AddGenerateCommand(GenerationCommands, 5);
	If CommandDetails <> Undefined Then
		CommandDetails.Importance = "Important";
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "Status", Enums.CounterpartyContractStatuses.Valid);
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "ThereIsBuyoutOfLeasedAssets", True);
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "DeletionMark", False);
	EndIf;
	
	CommandDetails = Documents.LeaseTermination.AddGenerateCommand(GenerationCommands, 6);
	If CommandDetails <> Undefined Then
		CommandDetails.Importance = "Important";
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "Status", Enums.CounterpartyContractStatuses.Valid);
		AttachableCommands.AddCommandVisibilityCondition(CommandDetails, "DeletionMark", False);
	EndIf;
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands, 7);
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands, 8);
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands, 9);
	
	Documents.ApplicationForImportationOfGoods.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	LeasedAssetAccounting.AddLeaseSettlementStatementReportCommand(ReportsCommands);

	Reports.VarianceAnalysisOfPaymentsAndAccrualsForLease.AddReportCommand(ReportsCommands, "ByCustomerContract");
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If Not AccessRight("Read", Metadata.Documents.SigningOfLeaseContract) Then
		Return;
	EndIf;

	AddCommandToDecryptPercentageCalculation(PrintCommands);

EndProcedure

// Adds a command to decrypt the calculation of interest.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//   
// Returns:
//	ValueTableRow -
Function AddCommandToDecryptPercentageCalculation(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "Catalog.LeaseContract";
	PrintCommand.Id = "ExplanationOfInterestCalculation";
	PrintCommand.Presentation = NStr("vi = 'Diễn giải tính lãi';
									|ru = 'Расшифровка расчета процентов';
									|en = 'Drill down interest '; fa = 'Drill down interest ';
									|it = 'Decrittazione calcolo interessi';
									|pl = 'Szczegóły obliczenia odsetek';
									|tr = 'Faiz hesaplaması ayrıntıları'");
	
	Return PrintCommand;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.PartnerHierarchy AS T2 
	|	ON T2.Parent = T.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T2.Partner)
	|	AND ValueAllowed(T.Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
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

#Region Print

// Create printed forms of objects
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ExplanationOfInterestCalculation") Then
		
		SpreadsheetDocument = GenerateTranscriptOfInterestCalculation(ObjectsArray, PrintObjects, PrintParameters, Undefined);
				
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ExplanationOfInterestCalculation",
			NStr("vi = 'Diễn giải tính lãi';
				|ru = 'Расшифровка расчета процентов';
				|en = 'Drill down interest'; fa = 'Drill down interest';
				|it = 'Decrittazione calcolo interessi';
				|pl = 'Szczegóły obliczenia odsetek';
				|tr = 'Faiz hesaplaması ayrıntıları'"),
			SpreadsheetDocument);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("FixedAsset") And ValueIsFilled(Parameters.FixedAsset) Then
		Parameters.Filter.Insert("LineOfBusiness", NonCurrentAssetsServerCall.LineOfBusiness(Parameters.FixedAsset));
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Parameters.Property("FixedAsset") And ValueIsFilled(Parameters.FixedAsset) Then
		Parameters.Filter.Insert("LineOfBusiness", NonCurrentAssetsServerCall.LineOfBusiness(Parameters.FixedAsset));
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region AccountingMechanisms

// 
// Returns:
// 	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions - 
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	// Services
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemServices";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionServices";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemServices");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionServices");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	// Interests
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemInterest";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionInterest";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemInterest");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionInterest");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

#EndRegion

#Region Print

Function GenerateTranscriptOfInterestCalculation(ObjectsArray, PrintObjects, PrintParameters, PrintKits_)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PageOrientation  = PageOrientation.Landscape;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTS_ExplanationOfCalculationOfRentalInterest";
	
	Template = PrintManagement.PrintFormTemplate("Catalog.LeaseContract.PF_MXL_ExplanationOfInterestCalculation");
	
	HeaderArea_ = Template.GetArea("Title");
	SectionHeader = Template.GetArea("Header");
	Area_TableHeader = Template.GetArea("TableHeader");
	AreaTableRow = Template.GetArea("TableRow");
	AreaRowTotalTable = Template.GetArea("RowTotalTable");
	BasementArea = Template.GetArea("Footer");

	ObjectDecryptionData = DataDecryptionOfInterestCalculation(ObjectsArray);
	
	FirstDocument = True;
	
	For Each DetailsData In ObjectDecryptionData Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		If TypeOf(DetailsData.Ref) = Type("DocumentRef.SigningOfLeaseContract")
			Or TypeOf(DetailsData.Ref) = Type("DocumentRef.LeaseTermAdjustment")
			Or TypeOf(DetailsData.Ref) = Type("DocumentRef.OBEntryOfLeaseSettlements") Then
			
			DecryptionContext = DetailsData.Ref;
			ContextPresentation = StrTemplate(NStr("vi = '(theo chứng từ %1)';
													|ru = '(по документу %1)';
													|en = '(by document %1)'; fa = '(by document %1)';
													|it = '(secondo il documento %1)';
													|pl = '(według dokumentu %1)';
													|tr = '(%1belgesine göre)'"), DetailsData.Ref);
			
		Else
			DecryptionContext = Undefined;
			ContextPresentation = "";
		EndIf;
		
		AreaParameters_ = New Structure;
		AreaParameters_.Insert("Context", DecryptionContext);
		AreaParameters_.Insert("ContextPresentation", ContextPresentation);
		HeaderArea_.Parameters.Fill(AreaParameters_);
		SpreadsheetDocument.Put(HeaderArea_);
		
		#Region Header
		SectionHeader.Parameters.Fill(DetailsData.HeaderData_);
		SpreadsheetDocument.Put(SectionHeader);
		#EndRegion

		#Region Table
		
		TableResults = New Structure;
		TableResults.Insert("PaymentAmount", 0);
		TableResults.Insert("PaymentAmountWithoutVAT", 0);
		TableResults.Insert("DebtAmountWithoutVAT", 0);
		TableResults.Insert("Interests", 0);

		SpreadsheetDocument.Put(Area_TableHeader);
		For Each DecryptionString In DetailsData.SettlementDetails Do
		
			AreaTableRow.Parameters.Fill(DecryptionString);
			SpreadsheetDocument.Put(AreaTableRow);
		
			TableResults.PaymentAmount = TableResults.PaymentAmount + DecryptionString.PaymentAmount;
			TableResults.PaymentAmountWithoutVAT = TableResults.PaymentAmountWithoutVAT + DecryptionString.PaymentAmountWithoutVAT; 
			TableResults.Interests = TableResults.Interests + DecryptionString.Interests;
			
		EndDo;
		
		AreaRowTotalTable.Parameters.Fill(TableResults);
		SpreadsheetDocument.Put(AreaRowTotalTable);
		
		#EndRegion

		SpreadsheetDocument.Put(BasementArea);

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, DetailsData.Ref);

	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function DataDecryptionOfInterestCalculation(ObjectsArray)

	ObjectDecryptionData = New ValueTable;
	ObjectDecryptionData.Columns.Add("Ref");
	ObjectDecryptionData.Columns.Add("HeaderData_");
	ObjectDecryptionData.Columns.Add("SettlementDetails");
	QueryText = 
	"SELECT
	|	SigningOfLeaseContract.Ref AS TermsOfAgreement_
	|INTO TTRecorders_
	|FROM
	|	Document.SigningOfLeaseContract AS SigningOfLeaseContract
	|WHERE
	|	SigningOfLeaseContract.Ref IN(&ObjectsArray)
	|
	|UNION
	|
	|SELECT
	|	LeaseTermAdjustment.Ref
	|FROM
	|	Document.LeaseTermAdjustment AS LeaseTermAdjustment
	|WHERE
	|	LeaseTermAdjustment.Ref IN(&ObjectsArray)
	|
	|UNION
	|
	|SELECT
	|	OBEntryOfLeaseSettlements.Ref
	|FROM
	|	Document.OBEntryOfLeaseSettlements AS OBEntryOfLeaseSettlements
	|WHERE
	|	OBEntryOfLeaseSettlements.Ref IN(&ObjectsArray)
	|
	|UNION
	|
	|SELECT
	|	TermsOfLeaseContractsSliceLast.EffectiveContractTerms
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract IN (&ObjectsArray)) AS TermsOfLeaseContractsSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.Period AS Period,
	|	TermsOfLeaseContracts.LeaseStartDate AS LeaseStartDate,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms
	|INTO TTConditionsPreliminary
	|FROM
	|	InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|WHERE
	|	TermsOfLeaseContracts.Recorder IN
	|			(SELECT
	|				Recorders.TermsOfAgreement_
	|			FROM
	|				TTRecorders_ AS Recorders)
	|
	|INDEX BY
	|	Period,
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ConditionsPreliminary.Period) AS Period,
	|	ConditionsPreliminary.EffectiveContractTerms AS EffectiveContractTerms
	|INTO TTOfTermsAndConditionsDate
	|FROM
	|	TTConditionsPreliminary AS ConditionsPreliminary
	|
	|GROUP BY
	|	ConditionsPreliminary.EffectiveContractTerms
	|
	|INDEX BY
	|	Period,
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConditionsPreliminary.Contract AS Contract,
	|	ConditionsPreliminary.EffectiveContractTerms AS EffectiveContractTerms,
	|	BEGINOFPERIOD(ConditionsPreliminary.Period, DAY) AS ChangeDate,
	|	ConditionsPreliminary.LeaseStartDate AS LeaseStartDate
	|INTO TTConditions
	|FROM
	|	TTConditionsPreliminary AS ConditionsPreliminary
	|		INNER JOIN TTOfTermsAndConditionsDate AS TTOfTermsAndConditionsDate
	|		ON (ConditionsPreliminary.EffectiveContractTerms = TTOfTermsAndConditionsDate.EffectiveContractTerms
	|				AND ConditionsPreliminary.Period = TTOfTermsAndConditionsDate.Period)
	|
	|INDEX BY
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTConditions.Contract AS Contract,
	|	TTConditions.EffectiveContractTerms AS EffectiveContractTerms,
	|	SigningOfLeaseContractServicePaymentSchedule.Date AS Date,
	|	SigningOfLeaseContractServicePaymentSchedule.RentalService AS RentalService,
	|	SigningOfLeaseContractServicePaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|	SigningOfLeaseContractServicePaymentSchedule.DepositPayment AS DepositPayment,
	|	SigningOfLeaseContractServicePaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	SigningOfLeaseContractServicePaymentSchedule.BuyoutValue AS BuyoutValue,
	|	SigningOfLeaseContractServicePaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT
	|INTO TTServices
	|FROM
	|	Document.SigningOfLeaseContract.ServicePaymentSchedule AS SigningOfLeaseContractServicePaymentSchedule
	|		INNER JOIN TTConditions AS TTConditions
	|		ON (TTConditions.EffectiveContractTerms = SigningOfLeaseContractServicePaymentSchedule.Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	TTConditions.Contract,
	|	TTConditions.EffectiveContractTerms,
	|	LeaseTermAdjustmentServicePaymentSchedule.Date,
	|	LeaseTermAdjustmentServicePaymentSchedule.RentalService,
	|	LeaseTermAdjustmentServicePaymentSchedule.RentalServiceVAT,
	|	LeaseTermAdjustmentServicePaymentSchedule.DepositPayment,
	|	LeaseTermAdjustmentServicePaymentSchedule.SecurityPaymentVATAmount,
	|	LeaseTermAdjustmentServicePaymentSchedule.BuyoutValue,
	|	LeaseTermAdjustmentServicePaymentSchedule.BuyoutValueVAT
	|FROM
	|	Document.LeaseTermAdjustment.ServicePaymentSchedule AS LeaseTermAdjustmentServicePaymentSchedule
	|		INNER JOIN TTConditions AS TTConditions
	|		ON (TTConditions.EffectiveContractTerms = LeaseTermAdjustmentServicePaymentSchedule.Ref)
	|		AND LeaseTermAdjustmentServicePaymentSchedule.Date >= TTConditions.ChangeDate
	|
	|UNION ALL
	|
	|SELECT
	|	TTConditions.Contract,
	|	TTConditions.EffectiveContractTerms,
	|	OBEntryOfLeaseSettlementsServicePaymentSchedule.Date,
	|	OBEntryOfLeaseSettlementsServicePaymentSchedule.RentalService,
	|	OBEntryOfLeaseSettlementsServicePaymentSchedule.RentalServiceVAT,
	|	OBEntryOfLeaseSettlementsServicePaymentSchedule.DepositPayment,
	|	OBEntryOfLeaseSettlementsServicePaymentSchedule.SecurityPaymentVATAmount,
	|	OBEntryOfLeaseSettlementsServicePaymentSchedule.BuyoutValue,
	|	OBEntryOfLeaseSettlementsServicePaymentSchedule.BuyoutValueVAT
	|FROM
	|	Document.OBEntryOfLeaseSettlements.ServicePaymentSchedule AS OBEntryOfLeaseSettlementsServicePaymentSchedule
	|		INNER JOIN TTConditions AS TTConditions
	|		ON (TTConditions.EffectiveContractTerms = OBEntryOfLeaseSettlementsServicePaymentSchedule.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTConditions.Contract AS Contract,
	|	TTConditions.EffectiveContractTerms AS EffectiveContractTerms,
	|	ConclusionOfLeaseContractInterest.Date AS Date,
	|	ConclusionOfLeaseContractInterest.Interests AS Interests
	|INTO TTInterest
	|FROM
	|	Document.SigningOfLeaseContract.InterestAccrualSchedule AS ConclusionOfLeaseContractInterest
	|		INNER JOIN TTConditions AS TTConditions
	|		ON (TTConditions.EffectiveContractTerms = ConclusionOfLeaseContractInterest.Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	TTConditions.Contract,
	|	TTConditions.EffectiveContractTerms,
	|	ChangeInTermsOfLeaseContractInterest.Date,
	|	ChangeInTermsOfLeaseContractInterest.Interests
	|FROM
	|	Document.LeaseTermAdjustment.InterestAccrualSchedule AS ChangeInTermsOfLeaseContractInterest
	|		INNER JOIN TTConditions AS TTConditions
	|		ON (TTConditions.EffectiveContractTerms = ChangeInTermsOfLeaseContractInterest.Ref)
	|		AND ChangeInTermsOfLeaseContractInterest.Date >= TTConditions.ChangeDate
	|
	|UNION ALL
	|
	|SELECT
	|	TTConditions.Contract,
	|	TTConditions.EffectiveContractTerms,
	|	OBEntryOfLeaseSettlementsInterest.Date,
	|	OBEntryOfLeaseSettlementsInterest.Interests
	|FROM
	|	Document.OBEntryOfLeaseSettlements.InterestAccrualSchedule AS OBEntryOfLeaseSettlementsInterest
	|		INNER JOIN TTConditions AS TTConditions
	|		ON (TTConditions.EffectiveContractTerms = OBEntryOfLeaseSettlementsInterest.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTConditions.Contract AS Contract,
	|	TTConditions.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTServices.Date AS Date,
	|	TTConditions.LeaseStartDate AS LeaseStartDate
	|INTO TTConditionsWithDates
	|FROM
	|	TTConditions AS TTConditions
	|		LEFT JOIN TTServices AS TTServices
	|		ON TTConditions.Contract = TTServices.Contract
	|		AND TTConditions.EffectiveContractTerms = TTServices.EffectiveContractTerms
	|
	|UNION
	|
	|SELECT
	|	TTConditions.Contract,
	|	TTConditions.EffectiveContractTerms,
	|	TTInterest.Date,
	|	TTConditions.LeaseStartDate
	|FROM
	|	TTConditions AS TTConditions
	|		LEFT JOIN TTInterest AS TTInterest
	|		ON TTConditions.Contract = TTInterest.Contract
	|		AND TTConditions.EffectiveContractTerms = TTInterest.EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTConditionsWithDates.Contract AS Contract,
	|	TTConditionsWithDates.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTConditionsWithDates.Date AS Date,
	|	TTConditionsWithDates.LeaseStartDate AS LeaseStartDate,
	|	TTConditionsWithDates.Date < TTConditionsWithDates.LeaseStartDate AS ThisIsAdvance,
	|	ISNULL(TTServices.RentalService, 0) AS RentalService,
	|	ISNULL(TTServices.RentalServiceVAT, 0) AS RentalServiceVAT,
	|	ISNULL(TTServices.DepositPayment, 0) AS DepositPayment,
	|	ISNULL(TTServices.SecurityPaymentVATAmount, 0) AS SecurityPaymentVATAmount,
	|	ISNULL(TTServices.BuyoutValue, 0) AS BuyoutValue,
	|	ISNULL(TTServices.BuyoutValueVAT, 0) AS BuyoutValueVAT,
	|	ISNULL(TTInterest.Interests, 0) AS Interests
	|INTO TTAmounts
	|FROM
	|	TTConditionsWithDates AS TTConditionsWithDates
	|		LEFT JOIN TTServices AS TTServices
	|		ON TTConditionsWithDates.Contract = TTServices.Contract
	|		AND TTConditionsWithDates.EffectiveContractTerms = TTServices.EffectiveContractTerms
	|		AND TTConditionsWithDates.Date = TTServices.Date
	|		LEFT JOIN TTInterest AS TTInterest
	|		ON TTConditionsWithDates.Contract = TTInterest.Contract
	|		AND TTConditionsWithDates.EffectiveContractTerms = TTInterest.EffectiveContractTerms
	|		AND TTConditionsWithDates.Date = TTInterest.Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAmounts.Contract AS Contract,
	|	TTAmounts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTAmounts.Date AS Date,
	|	TTAmounts.ThisIsAdvance AS ThisIsAdvance,
	|	TTAmounts.RentalService + TTAmounts.DepositPayment + TTAmounts.BuyoutValue AS Sum,
	|	TTAmounts.RentalService - TTAmounts.RentalServiceVAT + TTAmounts.DepositPayment - TTAmounts.SecurityPaymentVATAmount
	|		+ TTAmounts.BuyoutValue - TTAmounts.BuyoutValueVAT AS AmountExcludingVAT,
	|	TTAmounts.Interests AS Interests
	|INTO TTDataForReport
	|FROM
	|	TTAmounts AS TTAmounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataForReport.Contract AS Contract,
	|	TTDataForReport.EffectiveContractTerms AS EffectiveContractTerms,
	|	SUM(TTDataForReport.Sum) AS Sum,
	|	SUM(TTDataForReport.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(TTDataForReport.Interests) AS Interests,
	|	""Totals"" AS Field1
	|FROM
	|	TTDataForReport AS TTDataForReport
	|GROUP BY
	|	TTDataForReport.Contract,
	|	TTDataForReport.EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTConditions.Contract.Counterparty AS Counterparty,
	|	TTConditions.Contract.Counterparty.Presentation AS CounterpartyPresentation,
	|	TTConditions.Contract AS Contract,
	|	TTConditions.Contract.Presentation AS ContractPresentation,
	|	TTConditions.Contract.ARAPCurrency.Presentation AS ARAPCurrency,
	|	TTConditions.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTConditions.EffectiveContractTerms.Presentation AS EffectiveContractTermsPresentation,
	|	TTConditions.EffectiveContractTerms.Date AS DocumentDate,
	|	TTConditions.LeaseStartDate AS LeaseStartDate,
	|	TTConditions.EffectiveContractTerms.PresentValue AS PresentValue,
	|	TTConditions.EffectiveContractTerms.AmountIncludingVAT AS ContractAmount,
	|	TTConditions.EffectiveContractTerms.AmountIncludingVAT - TTConditions.EffectiveContractTerms.VATAmount AS ContractAmountWithoutVAT,
	|	TTConditions.EffectiveContractTerms.InterestRate AS InterestRate,
	|	SUM(ISNULL(TTDataForReport.Sum, 0)) AS AdvancePayments,
	|	""Header"" AS Field1
	|FROM
	|	TTConditions AS TTConditions
	|		LEFT JOIN TTDataForReport AS TTDataForReport
	|		ON TTConditions.Contract = TTDataForReport.Contract
	|		AND TTConditions.EffectiveContractTerms = TTDataForReport.EffectiveContractTerms
	|		AND (TTDataForReport.ThisIsAdvance)
	|GROUP BY
	|	TTConditions.Contract,
	|	TTConditions.Contract.Presentation,
	|	TTConditions.Contract.ARAPCurrency.Presentation,
	|	TTConditions.EffectiveContractTerms,
	|	TTConditions.EffectiveContractTerms.Presentation,
	|	TTConditions.EffectiveContractTerms.Date,
	|	TTConditions.LeaseStartDate,
	|	TTConditions.Contract.Counterparty,
	|	TTConditions.Contract.Counterparty.Presentation,
	|	TTConditions.EffectiveContractTerms.PresentValue,
	|	TTConditions.EffectiveContractTerms.AmountIncludingVAT,
	|	TTConditions.EffectiveContractTerms.AmountIncludingVAT - TTConditions.EffectiveContractTerms.VATAmount,
	|	TTConditions.EffectiveContractTerms.InterestRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataForReport.Contract AS Contract,
	|	TTDataForReport.EffectiveContractTerms AS EffectiveContractTerms,
	|	TTDataForReport.Date AS Date,
	|	TTDataForReport.ThisIsAdvance AS ThisIsAdvance,
	|	TTDataForReport.Sum AS PaymentAmount,
	|	TTDataForReport.AmountExcludingVAT AS PaymentAmountWithoutVAT,
	|	TTDataForReport.Interests AS Interests
	|FROM
	|	TTDataForReport AS TTDataForReport
	|WHERE
	|	TTDataForReport.ThisIsAdvance = FALSE
	|
	|ORDER BY
	|	Contract,
	|	EffectiveContractTerms,
	|	Date";

	Query = New Query(QueryText);
	Query.SetParameter("ObjectsArray", ObjectsArray);

	Result = Query.ExecuteBatch();

	InterestAccrualSchedule = Result[Result.UBound()].Unload();

	Selection = Result[Result.UBound() - 1].Select();
	While Selection.Next() Do

		DetailsData = ObjectDecryptionData.Add();
		DetailsData.Ref = Selection.EffectiveContractTerms;

		HeaderData_ = New Structure;
		DetailsData.HeaderData_ = HeaderData_;
		HeaderData_.Insert("Counterparty", Selection.Counterparty);
		HeaderData_.Insert("CounterpartyPresentation", Selection.CounterpartyPresentation);
		HeaderData_.Insert("Contract", Selection.Contract);
		HeaderData_.Insert("ContractPresentation", Selection.ContractPresentation);
		HeaderData_.Insert("ARAPCurrency", Selection.ARAPCurrency);
		HeaderData_.Insert("ContractAmount", Selection.ContractAmount);
		HeaderData_.Insert("ContractAmountWithoutVAT", Selection.ContractAmountWithoutVAT);
		HeaderData_.Insert("InterestRate", Selection.InterestRate);
		HeaderData_.Insert("PresentValue", Selection.PresentValue);
		HeaderData_.Insert("AdvancePayments", Selection.AdvancePayments);

		SettlementDetails = New ValueTable;
		SettlementDetails.Columns.Add("Date");
		SettlementDetails.Columns.Add("PaymentAmount");
		SettlementDetails.Columns.Add("PaymentAmountWithoutVAT");
		SettlementDetails.Columns.Add("DebtAmountWithoutVAT");
		SettlementDetails.Columns.Add("DaysOfDebt");
		SettlementDetails.Columns.Add("Interests");
		DetailsData.SettlementDetails = SettlementDetails;

		PreviousDate = Selection.LeaseStartDate;

		If Not LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Selection.EffectiveContractTerms) Then
			PreviousDate = Selection.LeaseStartDate;
		Else
			PreviousDate = BegOfDay(Selection.DocumentDate) - 86400;
		EndIf;

		DebtAmountWithoutVAT = HeaderData_.PresentValue;

		For Each PlotLine In InterestAccrualSchedule Do

			If PlotLine.EffectiveContractTerms <> Selection.EffectiveContractTerms Then
				Continue;
			EndIf;

			DecryptionString = SettlementDetails.Add();
			DecryptionString.Date = PlotLine.Date;
			DecryptionString.PaymentAmount = PlotLine.PaymentAmount;
			DecryptionString.PaymentAmountWithoutVAT = PlotLine.PaymentAmountWithoutVAT;
			DecryptionString.DebtAmountWithoutVAT = DebtAmountWithoutVAT;
			DecryptionString.Interests = PlotLine.Interests;

			DecryptionString.DaysOfDebt = Round((DecryptionString.Date - PreviousDate) / 86400, 0);

			PreviousDate = DecryptionString.Date;
			DebtAmountWithoutVAT = Max(DebtAmountWithoutVAT - DecryptionString.PaymentAmountWithoutVAT
			+ DecryptionString.Interests, 0);

		EndDo;

	EndDo;

	Return ObjectDecryptionData;
EndFunction

#EndRegion

#EndRegion

#EndIf
