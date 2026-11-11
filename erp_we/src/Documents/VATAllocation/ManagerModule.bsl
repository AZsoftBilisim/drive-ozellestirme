#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//                                          registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	VATAllocationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.VATAllocation") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return FormRegisteredRecords(GetDocumentData(DocumentRef), Registers, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
	VATAllocationLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command creation of the document "Distribution of VAT".
// 
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined - Add a create command based on
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.VATAllocation) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.VATAllocation.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.VATAllocation);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSeparateAccountingByTaxation,EnterpriseManagement,ComplexAutomation";
		
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
	VATAllocationLocalization.AddReportCommands(ReportsCommands, Parameters);
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	VATAllocationLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - The text of the reflection request in the regl. accounting.
//
Function TextOfReflectionInLocalAccounting() Export
	Return VATAllocationLocalization.TextOfReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return VATAllocationLocalization.RequestTextTTReflectedInLocalAccounting();
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	Object - DocumentObject.VATAllocation - Details of the VAT distribution document
// 	
// Returns:
//	Array of Structure - See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters(Object) Export
	
	ArrayOfSelectionParameters = New Array;
	
	ItIsNecessaryToDistributeVATOnGoods = Documents.VATAllocation.ItIsNecessaryToDistributeVATOnGoods(Object.Organization, Object.Date); 
	
	#Region ExpenseItemVATExempt
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItemVATExempt";
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpenseDimensionVATExempt";
	ChoiceParameters.AvailabilityByOperation = (ItIsNecessaryToDistributeVATOnGoods Or Not Object.WriteOffVATByExpensesAndAssetsToRecordItems);
		
	
	ChoiceParameters.FormItems.AssetRef.Add("CostItemNotVAT");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpenseDimensionVATExempt");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	VATAllocationLocalization.AddOptionsForSelectingArticlesAndAnalytics(ArrayOfSelectionParameters, 
		Object,
		ItIsNecessaryToDistributeVATOnGoods);
		
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns whether VAT should be distributed by product
//
// Parameters:
// 	Organization -  CatalogRef.Companies - The organization where VAT distribution is performed.
// 	Period -  Date - The period when the VAT distribution is completed.
//
// Returns:
// 	Boolean - A sign of the need to distribute VAT on goods.
//
Function ItIsNecessaryToDistributeVATOnGoods(Organization, Val Period) Export
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	1
	|FROM
	|	AccumulationRegister.LotsVATForAllocation AS LotsVATForAllocation
	|WHERE
	|	LotsVATForAllocation.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND LotsVATForAllocation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND LotsVATForAllocation.Organization = &Organization
	|	AND LotsVATForAllocation.ExpenseItem = UNDEFINED
	|	AND LotsVATForAllocation.VATLocal <> 0
	|";
	
	VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings", Organization, Period);
	
	If VATAccountingSettings = Undefined Then
		FrequencyOfVATAllocation = Enums.Periodicity.Quarter;
	Else
		FrequencyOfVATAllocation = VATAccountingSettings.FrequencyOfVATAllocation;
	EndIf;

	If FrequencyOfVATAllocation = Enums.Periodicity.Month Then
		BeginOfPeriod = BegOfMonth(Period);
		EndOfPeriod = EndOfMonth(Period);
	ElsIf FrequencyOfVATAllocation = Enums.Periodicity.Quarter Then
		BeginOfPeriod = BegOfQuarter(Period);
		EndOfPeriod = EndOfQuarter(Period);
	Else
		Raise StrTemplate(NStr("vi = 'Không hỗ trợ định kỳ phân bổ thuế GTGT ""%1"".';
								|ru = 'Периодичность распределения НДС ""%1"" не поддерживается.';
								|en = 'Frequency of VAT allocation ""%1"" is not provided.'; fa = 'Frequency of VAT allocation ""%1"" is not provided.';
								|it = 'La periodicità di ripartizione IVA ""%1"" non è supportata.';
								|pl = 'Okresowość przydziału VAT ""%1"" nie jest obsługiwana.';
								|tr = 'KDV dağıtım sıklığı ""%1"" desteklenmiyor.'"), String(FrequencyOfVATAllocation));
	EndIf;
	
	Query.SetParameter("Organization",   Organization);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  EndOfPeriod);
	
	Result = Not Query.Execute().IsEmpty();
	
	Return Result;
	
EndFunction

// Returns whether VAT distribution is required for the period
//
// Parameters:
// 	Organization -  CatalogRef.Companies - The organization where VAT distribution is performed.
// 	Period -  Date - The period when the VAT distribution is completed.
//
// Returns:
// 	Boolean - A sign of the need for VAT distribution.
//
Function VATDistributionIsRequired(Organization, Val Period) Export
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 
	|	1
	|FROM
	|	AccumulationRegister.LotsVATForAllocation AS LotsVATForAllocation
	|WHERE
	|	LotsVATForAllocation.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND LotsVATForAllocation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND LotsVATForAllocation.Organization = &Organization
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	LotsVATForAllocationBalance.Organization
	|FROM
	|	AccumulationRegister.LotsVATForAllocation.Balance(
	|			&BeginOfPeriod,
	|			Organization = &Organization) AS LotsVATForAllocationBalance
	|";
	
	Query.SetParameter("Organization", Organization);
	
	VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings", Organization, Period);
	
	If VATAccountingSettings = Undefined Then
		FrequencyOfVATAllocation = Enums.Periodicity.Quarter ;
	Else
		FrequencyOfVATAllocation = VATAccountingSettings.FrequencyOfVATAllocation;
	EndIf;
	
	If FrequencyOfVATAllocation = Enums.Periodicity.Month Then
		BeginOfPeriod = BegOfMonth(Period);
		EndOfPeriod = EndOfMonth(Period);
	ElsIf FrequencyOfVATAllocation = Enums.Periodicity.Quarter Then
		BeginOfPeriod = BegOfQuarter(Period);
		EndOfPeriod = EndOfQuarter(Period);
	Else
		Raise StrTemplate(NStr("vi = 'Không hỗ trợ định kỳ phân bổ thuế GTGT ""%1"".';
								|ru = 'Периодичность распределения НДС ""%1"" не поддерживается.';
								|en = 'Frequency of VAT allocation ""%1"" is not provided.'; fa = 'Frequency of VAT allocation ""%1"" is not provided.';
								|it = 'La periodicità di ripartizione IVA ""%1"" non è supportata.';
								|pl = 'Okresowość przydziału VAT ""%1"" nie jest obsługiwana.';
								|tr = 'KDV dağıtım sıklığı ""%1"" desteklenmiyor.'"), String(FrequencyOfVATAllocation));
	EndIf;
		
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  EndOfPeriod);
	
	Result = Not Query.Execute().IsEmpty();
	
	Return Result;
	
EndFunction

// Performs VAT distribution for the specified period in the specified organizations. It is intended for calling within the framework.
//
// Parameters:
//	Period - Date - the month for which you need to create distribution documents.
//	Organization - Array of CatalogRef.Companies, CatalogRef.Companies, Undefined - selection of organizations for which documents are created.
//		If an empty parameter is passed, documents will be created for all organizations.
//	EventNameLR - String - name of the error event for the log entry
//	TTRegisterCacheManager - TempTablesManager - contains a cache of register revolutions/balances.
//		Used only when this method is called during calculation execution by the batch accounting engine version 2.2.
//	CostCalculationIsUnderway - Boolean - indicates whether the VAT distribution is called from the batch and cost calculation mechanism.
//
// Returns:
//		Structure - VAT distribution result; structure keys:
//		  * DocumentsArray - Array of DocumentRef - links to all processed VAT distribution documents (regardless of whether they contain errors)
//		  * CalculatedOrganizations - Array of CatalogRef.Companies - links to organizations for which the distribution of VAT was performed without errors
//		  * ErrorText - String - the text of all errors recorded in the allocation of VAT.
//
Function DistributeVAT(Period, Organization, EventNameLR = "", TTRegisterCacheManager = Undefined, CostCalculationIsUnderway = False) Export
	
	ResultOfVATDistribution = New Structure;
	ResultOfVATDistribution.Insert("DocumentsArray", 		  New Array);
	ResultOfVATDistribution.Insert("CalculatedOrganizations", New Array);
	ResultOfVATDistribution.Insert("ErrorText", 	   		  "");
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CatalogData.Ref AS Organization
	|INTO TTOrganizations
	|FROM
	|	Catalog.Companies AS CatalogData
	|WHERE
	|	CatalogData.Ref IN (&CompanyArray)
	|	AND (CatalogData.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|		OR &ConsiderManOrganization)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTOrganizations.Organization	 	 AS Organization,
	|	MAX(ISNULL(DistributionOfVATHasBeenCarriedOut.Ref, DistributionOfVATCreated.Ref)) AS Document
	|INTO SourceDistributionDocuments
	|FROM
	|	TTOrganizations AS TTOrganizations
	|		LEFT JOIN Document.VATAllocation AS DistributionOfVATHasBeenCarriedOut
	|		ON TTOrganizations.Organization = DistributionOfVATHasBeenCarriedOut.Organization
	|			AND NOT DistributionOfVATHasBeenCarriedOut.Patch
	|			AND DistributionOfVATHasBeenCarriedOut.Posted
	|			AND DistributionOfVATHasBeenCarriedOut.Date BETWEEN &StartDate AND &EndDate
	|		LEFT JOIN Document.VATAllocation AS DistributionOfVATCreated
	|		ON TTOrganizations.Organization = DistributionOfVATCreated.Organization
	|			AND NOT DistributionOfVATCreated.Patch
	|			AND NOT DistributionOfVATCreated.DeletionMark
	|			AND DistributionOfVATCreated.Date BETWEEN &StartDate AND &EndDate
	|	
	|GROUP BY
	|	TTOrganizations.Organization
	|
	|INDEX BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentCorrection.CorrectedDocument AS CorrectedDocument,
	|	DocumentCorrection.DocumentToCorrectIsReversed AS DocumentWasCancelled,
	|	DocumentCorrection.LastChainDocument AS ActualDocument
	|INTO CurrentDistributionDocuments
	|FROM
	|	InformationRegister.DocumentCorrections.SliceLast(
	|			,
	|			CorrectedDocument IN
	|				(SELECT
	|					T.Document
	|				FROM
	|					SourceDistributionDocuments AS T)) AS DocumentCorrection
	|WHERE
	|	NOT (DocumentCorrection.LastChainDocument = UNDEFINED
	|				AND DocumentCorrection.DocumentToCorrectIsReversed = FALSE)
	|
	|INDEX BY
	|	CorrectedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SourceDistributionDocuments.Organization AS Organization,
	|	CASE
	|		WHEN NOT RelevantDocuments.CorrectedDocument IS NULL
	|			THEN RelevantDocuments.ActualDocument
	|		ELSE SourceDistributionDocuments.Document
	|	END AS Document
	|FROM
	|	SourceDistributionDocuments AS SourceDistributionDocuments
	|		LEFT JOIN CurrentDistributionDocuments AS RelevantDocuments
	|		ON SourceDistributionDocuments.Document = RelevantDocuments.CorrectedDocument
	|			AND ISNULL(RelevantDocuments.DocumentWasCancelled, FALSE) = FALSE";
	
	Query.SetParameter("StartDate",    			 BegOfMonth(Period));
	Query.SetParameter("EndDate", 			 EndOfMonth(Period));
	Query.SetParameter("ConsiderManOrganization", GetFunctionalOption("UseManagementCompany"));
	Query.SetParameter("CompanyArray",  	 TMCommonUseClientServer.Array(Organization));
	
	Selection = Query.Execute().Select();
	
	ErrorsInDatesWhenChangesWereBanned = "";
	FillingVerificationErrors  = "";
	ConductErrors		  = "";
	
	While Selection.Next() Do 
		
		// When calling the VAT distribution from the distribution procedure, it is not necessary to Check the State of the stage()
		// , because the VAT distribution is performed in this case within the "Cost allocation and cost calculation" stage. 
		If TTRegisterCacheManager <> Undefined Then
			State = Enums.StatesOfMonthEndClosingOperations.NotCompleted;
		Else
			State = MonthEndTransactionsServer.DetermineStateOfCalculationSteps(
				Catalogs.MonthEndClosingOperations.VATAllocation,
				Period,
				Selection.Organization,
				Not CostCalculationIsUnderway,
				,
				Catalogs.MonthEndClosingOperations.VATAllocation);
		EndIf;
		
		If State <> Enums.StatesOfMonthEndClosingOperations.NotCompleted
		 And State <> Enums.StatesOfMonthEndClosingOperations.DoneWithErrors Then
			Continue;
		EndIf;
		
		RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
			?(CostCalculationIsUnderway,
				Catalogs.MonthEndClosingOperations.LotsAndCostCalculation,
				Catalogs.MonthEndClosingOperations.VATAllocation),
			Selection.Organization,
			BegOfMonth(Period));
			
		ErrorLoggingText = StrReplace(
			NStr("vi = 'Khi %Operation% cho Doanh nghiệp ""%1"" trong kỳ %2, đã chẩn đoán được lỗi';
				|ru = 'При %Operation% по организации ""%1"" за период %2 были диагностированы ошибки';
				|en = 'Errors were found during %Operation% for the ""%1"" company for period %2'; fa = 'Errors were found during %Operation% for the ""%1"" company for period %2';
				|it = 'Durante %Operation%con la società ""%1"" per il periodo %2 sono stati riscontrati errori';
				|pl = 'Podczas %Operation% według firmy ""%1"" za okres %2 wykryto błędy.';
				|tr = '""%1"" iş yeri için %2 dönemi için %Operation% sırasında hatalar tespit edildi'", Common.DefaultLanguageCode()),
			"%operation%",
			?(CostCalculationIsUnderway, NStr("vi = 'phân bổ thuế GTGT';
												|ru = 'распределении НДС';
												|en = 'VAT allocation'; fa = 'تسهیم مالیات بر ارزش افزوده';
												|it = 'ripartizione IVA';
												|pl = 'podziału VAT';
												|tr = 'KDV dağıtımı'", Common.DefaultLanguageCode()), NStr("vi = 'tính toán';
																											|ru = 'выполнении расчета';
																											|en = 'calculation'; fa = 'calculation';
																											|it = 'esecuzione del calcolo';
																											|pl = 'wykonania obliczeń';
																											|tr = 'mutabakatın gerçekleştirilmesi'", Common.DefaultLanguageCode())));
			
		BeginTransaction();
		
		Try
		
			If Not ValueIsFilled(Selection.Document) Then
				
				DocumentObject = Documents.VATAllocation.CreateDocument();
				DocumentObject.Date 		 = EndOfMonth(Period);
				DocumentObject.Organization 	 = Selection.Organization;
				DocumentObject.EmployeeResponsible = Users.CurrentUser();
				
				CorrectionStructure = New Structure;
				CorrectionStructure.Insert("Patch", False);
				CorrectionStructure.Insert("CorrectedDocument", Undefined);
				Documents.VATAllocation.SetStartOfPeriod(DocumentObject.BeginOfPeriod, Period, Selection.Organization, CorrectionStructure);
				
				VATDebitingRules = Documents.VATAllocation.FillInRulesForDebitingVAT(Selection.Organization);
				FillPropertyValues(DocumentObject, VATDebitingRules);
				
			Else
				
				Block = New DataLock;
				LockItem = Block.Add("Document.VATAllocation");
				LockItem.SetValue("Ref", Selection.Document);
				Block.Lock();
				
				DocumentObject = Selection.Document.GetObject();
				
			EndIf;
		
			// Let's check that the document is in the period available for modification.
			DateErrorDescription = "";
			
			If PeriodClosingDates.DataChangesDenied(DocumentObject, , DateErrorDescription) Then
				
				ErrorsInDatesWhenChangesWereBanned = ErrorsInDatesWhenChangesWereBanned + ?(ErrorsInDatesWhenChangesWereBanned = "", "", "
					|") + CostCalculationProtocol.PresentationOfMultilineText(DateErrorDescription);
				
				MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
					RegistrationParameters,
					ErrorLoggingText,
					,
					DateErrorDescription);
				
				RollbackTransaction();
				
				Continue;
				
			EndIf;
			
			// Fill in the additional properties of the document.
			DocumentObject.AdditionalProperties.Insert("RoutineOperations");
			
			If CostCalculationIsUnderway Then
			    CostCalculationAppliedAlgorithms.SetAttributeForPerformingCalculationOfBatchesAndCost(DocumentObject);
			EndIf;
			
			If TTRegisterCacheManager <> Undefined Then
				// Called from batch accounting version 2.2.
				DocumentObject.AdditionalProperties.Insert("TTRegisterCacheManager", TTRegisterCacheManager);
				DocumentObject.AdditionalProperties.Insert("BatchCalculationPeriod", 	   Period);
			EndIf;
			
			If DocumentObject.IsNew() Then
				// The regulatory document should remain in the IB regardless of whether it will be possible to conduct it or not.
				DocumentObject.Write(DocumentWriteMode.Write);
			EndIf;
			
			// Let's check the correctness of filling out the document.
			VerificationMessages = CostCalculationAppliedAlgorithms.CheckIfObjectIsFullWithMessageInterception(DocumentObject);
			
			If ValueIsFilled(VerificationMessages) Then
				
				// Checking the completion of the document found errors.
				FillingVerificationErrors = FillingVerificationErrors	+ ?(FillingVerificationErrors = "", "", "
					|") + StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Khi kiểm tra chứng từ ""%1"" đã tìm thấy lỗi:
								|%2';
								|ru = 'При проверке документа ""%1"" были обнаружены ошибки:
								|%2';
								|en = 'Errors were detected while checking the ""%1"" document:
								|%2'; fa = 'Errors were detected while checking the ""%1"" document:
								|%2';
								|it = 'Durante il controllo dei documenti ""%1"" sono stati riscontrati errori:
								|%2';
								|pl = 'Podczas sprawdzenia dokumentu ""%1"" wykryto błędy: 
								|%2';
								|tr = '""%1"" belgesini kontrol ederken hatalar bulundu:
								|%2'", Common.DefaultLanguageCode()),
							TrimAll(DocumentObject),
							CostCalculationProtocol.PresentationOfMultilineText(VerificationMessages, " - "));
				
				MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
					RegistrationParameters,
					ErrorLoggingText,
					,
					FillingVerificationErrors,
					DocumentObject.Ref);
				
			Else
				DocumentObject.Write(DocumentWriteMode.Posting);
				ResultOfVATDistribution.CalculatedOrganizations.Add(Selection.Organization); // distribution completed successfully
			EndIf;
			
			ResultOfVATDistribution.DocumentsArray.Add(DocumentObject.Ref);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			ConductErrors = ConductErrors + ?(ConductErrors = "", "", "
				|") + ErrorText;
			
			MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
				RegistrationParameters,
				ErrorLoggingText,
				,
				ErrorText);
			
		EndTry;
		
	EndDo;
	
	// We will process the error information.
	If ValueIsFilled(ErrorsInDatesWhenChangesWereBanned)
	 Or ValueIsFilled(FillingVerificationErrors)
	 Or ValueIsFilled(ConductErrors) Then
		
		ResultOfVATDistribution.ErrorText = ErrorsInDatesWhenChangesWereBanned;
		
		ResultOfVATDistribution.ErrorText =
			?(ResultOfVATDistribution.ErrorText = "", "", ResultOfVATDistribution.ErrorText + "
				|") + FillingVerificationErrors;
		
		ResultOfVATDistribution.ErrorText =
			?(ResultOfVATDistribution.ErrorText = "", "", ResultOfVATDistribution.ErrorText + "
				|") + ConductErrors;
		
		If ValueIsFilled(EventNameLR) Then
			
			TextForLog = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể phân bổ thuế GTGT do nguyên nhân:
					|%1';
					|ru = 'Не удалось выполнить распределение НДС по причине:
					|%1';
					|en = 'Cannot allocate VAT. Reason:
					|%1'; fa = 'Cannot allocate VAT. Reason:
					|%1';
					|it = 'Non è stato possibile eseguire la ripartizione IVA a causa di:
					|%1';
					|pl = 'Nie udało się dokonać podziału VAT z powodu:
					|%1';
					|tr = 'KDV dağıtımı şu nedenle gerçekleştirilemedi:
					|%1'"),
				ResultOfVATDistribution.ErrorText);
			
			WriteLogEvent(
				EventNameLR,
				EventLogLevel.Error,
				Metadata.Documents.VATAllocation,
				,
				TextForLog);
			
		EndIf;
		
 	EndIf;
	
	Return ResultOfVATDistribution;
	
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

// Gets matching values for conversion.
// 
// Returns:
//  Map of EnumRef.VATTaxationTypes, String - Compliance of revenue details with VAT taxation types:
//  * Key - EnumRef.VATTaxationTypes - types of VAT taxation.
//  * Value - String - Attribute name
//
Function ComplianceOfRevenueDetailsWithVATTaxationTypes() Export
	MatchingBankDetails = New Map();
	MatchingBankDetails.Insert(Enums.VATTaxationTypes.SaleIsSubjectToVAT, "VATRevenue");
	MatchingBankDetails.Insert(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT, "RevenueVATExempt");
	MatchingBankDetails.Insert(Enums.VATTaxationTypes.ExportSale, "VATRevenue0");
	VATAllocationLocalization.SupplementComplianceOfRevenueDetailsWithVATTaxation(MatchingBankDetails);
	Return MatchingBankDetails
EndFunction

// Gets matching values for conversion.
//
// Returns:
//  Map of EnumRef.VATTaxationTypes, String - compliance of expenditure analyst
//                                                                      items with VAT taxation.
//
Function ComplianceOfExpenditureAnalystItemsWithVATTaxation() Export
	
	MatchingBankDetails = New Map();
	
	AttributesArray = New Array();
	AttributesArray.Add("ExpenseItemVATExempt");
	AttributesArray.Add("ExpenseDimensionVATExempt");
	MatchingBankDetails.Insert(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT, AttributesArray);
	
	VATAllocationLocalization.SupplementComplianceOfExpenditureAnalystItemsWithVATTaxation(MatchingBankDetails);
	Return MatchingBankDetails
EndFunction

// Gets matching values for conversion.
//
// Returns:
//		Array of String
//
Function DocumentAttributes() Export
	
	DocumentAttributes = New Array();
	
	ComplianceOfArticleDetails_ = ComplianceOfExpenditureAnalystItemsWithVATTaxation();
	For Each ComplianceElement In ComplianceOfArticleDetails_ Do
		CommonClientServer.SupplementArray(DocumentAttributes, ComplianceElement.Value);
	EndDo;
	
	ComplianceWithRevenueDetails = ComplianceOfRevenueDetailsWithVATTaxationTypes();
	For Each ComplianceElement In ComplianceWithRevenueDetails Do
		DocumentAttributes.Add(ComplianceElement.Value);
	EndDo;
	
	DocumentAttributes.Add("Patch");
	DocumentAttributes.Add("ReversedDocument");
	DocumentAttributes.Add("CorrectedDocument");
	
	Return TMCommonUse.DeleteDuplicateElementsFromArray(DocumentAttributes);
	
EndFunction

Function AddDocumentDetailsToRequestText_(QueryText, TableName) 
	StringSubstitution = "";
	Template = ", " + TableName + ".%1";
	For Each DocumentAttribute In DocumentAttributes() Do
		StringAttribute = StringFunctionsClientServer.SubstituteParametersToString(Template, DocumentAttribute);
		StringSubstitution = StringSubstitution + StringAttribute; 
	EndDo;
	
	QueryText = StrReplace(QueryText, ",&AdditionalAttributes", StringSubstitution);
	
	Return QueryText;
	
EndFunction

#Region Posting

#Region InitializationOfEvent

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources;

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	FullDocumentName = "Document.VATAllocation";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.VATAllocation"));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.VATAllocation);
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextDocumentsRegistry();
		SynonymForDocumentTable = "DocumentData";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

// Get the document data.
// 
// Parameters:
//  DocumentRef - DocumentRef - Document link
// 
// Returns:
//  Structure - Get Document Data:
// * DistributionForFullPeriod - Boolean -
// * PeriodBeginning - Arbitrary -
// * PeriodEnd - Date -
// * SeparateAccountingOfItemizedProductionCostsForVATTaxation - Boolean -
// * AllocateVATToCapitalExpenditureInReceiptMonth - Boolean -
// * UseVNA2_4 - Boolean -
//
Function GetDocumentData(DocumentRef) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref							AS Ref,
	|	DocumentData.Date							AS DateOfDistribution,
	|	ISNULL(DocumentBeingCorrectedIsLink.Date, DocumentData.Date)		AS Period,
	|	DocumentData.BeginOfPeriod					AS BeginOfPeriod,
	|	ENDOFPERIOD(ISNULL(DocumentBeingCorrectedIsLink.Date, DocumentData.Date), MONTH)	AS BasePeriod,
	|	DocumentData.Organization						AS Organization,
	|	DocumentData.WriteOffVATByExpensesAndAssetsToRecordItems AS WriteOffVATByExpensesAndAssetsToRecordItems,
	|	DocumentData.Apply5PecentRule		AS Apply5PecentRule
	|	,&AdditionalAttributes
	|FROM
	|	Document.VATAllocation AS DocumentData
	|		LEFT JOIN Document.VATAllocation AS DocumentBeingCorrectedIsLink
	|		ON DocumentData.CorrectedDocument = DocumentBeingCorrectedIsLink.Ref
	|			AND DocumentData.Patch
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentRef);
	AddDocumentDetailsToRequestText_(Query.Text, "DocumentData");
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	Attributes = New Structure;
	
	For Each Column In Result.Columns Do
		Attributes.Insert(Column.Name, Selection[Column.Name]);
	EndDo;

	PeriodEnd = EndOfMonth(Selection.Period);
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
		Selection.Organization, 
		PeriodEnd);
	
	If AccountingPolicyParameters = Undefined Then
		FrequencyOfVATAllocation = Enums.Periodicity.Quarter;
	Else
		FrequencyOfVATAllocation = AccountingPolicyParameters.FrequencyOfVATAllocation;
	EndIf;
		
	If FrequencyOfVATAllocation = Enums.Periodicity.Quarter Then
		Attributes.Insert("DistributionForFullPeriod", (Month(Selection.Period)%3=0));
	ElsIf FrequencyOfVATAllocation = Enums.Periodicity.Month Then
		Attributes.Insert("DistributionForFullPeriod", True);
	EndIf;
	
	Attributes.Insert("PeriodBeginning",    Selection.BeginOfPeriod);
	Attributes.Insert("PeriodEnd", PeriodEnd);
	
	AccountingPolicyParametersOfFinAccounting = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Selection.Organization,
		PeriodEnd);
		
	VATAccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
		Selection.Organization,
		PeriodEnd);
	
	Attributes.Insert("SeparateAccountingOfItemizedProductionCostsForVATTaxation",
			?(Not AccountingPolicyParameters = Undefined And Not AccountingPolicyParametersOfFinAccounting = Undefined, 
				AccountingPolicyParameters.SeparateAccountingOfItemizedProductionCostsForVATTaxation
					And AccountingPolicyParametersOfFinAccounting.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation,
				False));
	Attributes.Insert("AllocateVATToCapitalExpenditureInReceiptMonth",
			?(Not VATAccountingPolicyParameters = Undefined,
				VATAccountingPolicyParameters.AllocateVATToCapitalExpenditureInReceiptMonth,
				False));
	
	UseVNA2_4 = NonCurrentAssets.VNAManagementIsUsed_2_4(Attributes.Period);
	Attributes.Insert("UseVNA2_4", UseVNA2_4);
	Attributes.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.VATAllocation"));
	
	Return Attributes;
	
EndFunction

// Data for distribution
// 
// Parameters:
// 	Attributes - Structure - LongDesc:
// * PeriodEnd - Date -
// * DistributionForFullPeriod - Boolean -
// 	AddlParameters - Structure, Undefined -
// Returns:
// 	Structure - LongDesc:
// * NonCurrentAssets - ValueTable, ValueTree -
// * LotsVATForAllocation - ValueTable, ValueTree -
Function DataForDistribution(Attributes, AddlParameters)
	
	Query = New Query;
	
	Query.SetParameter("DistributionForFullPeriod", Attributes.DistributionForFullPeriod); // End-of-quarter condition.
	Query.SetParameter("Period",             Attributes.Period);
	Query.SetParameter("BasePeriod",         Attributes.BasePeriod);
	Query.SetParameter("PeriodBeginning",       Attributes.PeriodBeginning);
	Query.SetParameter("PeriodEnd",    Attributes.PeriodEnd);
	Query.SetParameter("Organization",        Attributes.Organization);
	Query.SetParameter("Boundary",            New Boundary(Attributes.PeriodEnd, BoundaryType.Including));
	Query.SetParameter("DocumentRef",     Attributes.Ref);
	Query.SetParameter("Patch",          Attributes.Patch);
	Query.SetParameter("CorrectedDocument", Attributes.CorrectedDocument);
	Query.SetParameter("SeparateAccountingOfItemizedProductionCostsForVATTaxation", 
		Attributes.SeparateAccountingOfItemizedProductionCostsForVATTaxation);
	Query.SetParameter("UseSeparateFAAccountingByTaxation",
		GetFunctionalOption("UseSeparateFAAccountingByTaxation"));
	Query.SetParameter("AllocateVATToCapitalExpenditureInReceiptMonth",
		Attributes.AllocateVATToCapitalExpenditureInReceiptMonth);
	If AddlParameters <> Undefined And AddlParameters.Property("TTRegisterCacheManager") Then
		
		// Called from batch accounting version 2.2.
		// It is necessary to adjust the balances at the end of the period:
		// subtract from them the "calculated" movements stored in the IB (the results of the last batch calculation)
		// and add the "calculated" movements stored in the temporary table (the results of the batch calculation currently being performed).
		
		Query.TempTablesManager = AddlParameters.TTRegisterCacheManager; // contains a VT cache partyinddistribution
		
		// The batch calculation period (month) may differ from the data sampling period for distribution (month or quarter).
		Query.SetParameter("StartOfBatchCalculationPeriod", BegOfMonth(AddlParameters.BatchCalculationPeriod));
		Query.SetParameter("EndOfBatchCalculationPeriod",  EndOfMonth(AddlParameters.BatchCalculationPeriod));
		
		Query.Text =
		"SELECT
		|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -1
		|		ELSE 1
		|	END                         AS Character,
		|	ISNULL(ENDOFPERIOD(RegistryDocumentToBeCorrected.IBDocumentDate, QUARTER), &BasePeriod) AS BasePeriod,
		|	T.Organization                 AS Organization,
		|	T.Department               AS Department,
		|	T.ExpenseItem              AS ExpenseItem,
		|	T.DimensionOfExpenses           AS DimensionOfExpenses,
		|	T.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
		|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
		|	T.Vendor                   AS Vendor,
		|	T.AssetTaxClass                 AS AssetTaxClass,
		|	T.LineOfBusiness     AS LineOfBusiness,
		|	T.VATRate                   AS VATRate,
		|	T.VATActivityType          AS VATActivityType,
		|	T.LocalCost               AS LocalCost,
		|	T.VATLocal                     AS VATLocal,
		|	T.VATManag                      AS VATManag
		|INTO TTAdjustmentOfNdskBatchBalancesByDistribution
		|FROM
		|	AccumulationRegister.LotsVATForAllocation AS T
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegistryFixStorno
		|	ON
		|		T.Recorder = RegistryFixStorno.Ref
		|		AND RegistryFixStorno.ReverseTransactionCorrection
		|		AND NOT RegistryFixStorno.AdditionalRecord
		|	
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegistryDocumentToBeCorrected
		|	ON
		|		RegistryFixStorno.CorrectedDocument = RegistryDocumentToBeCorrected.Ref 
		|		AND NOT RegistryDocumentToBeCorrected.AdditionalRecord
		|	
		|WHERE
		|	T.Period BETWEEN &StartOfBatchCalculationPeriod AND &EndOfBatchCalculationPeriod
		|	AND T.Organization = &Organization
		|	AND T.Active
		|	AND T.LotCalculation
		|	AND T.Recorder <> &DocumentRef
		|	AND (T.LocalCost <> 0 
		|		OR T.VATLocal <> 0)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN 1
		|		ELSE -1
		|	END                         AS Character,
		|	ISNULL(RegistryDocumentToBeCorrected.IBDocumentDate, &BasePeriod) AS BasePeriod,
		|	T.Organization                 AS Organization,
		|	T.Department               AS Department,
		|	T.ExpenseItem              AS ExpenseItem,
		|	T.DimensionOfExpenses           AS DimensionOfExpenses,
		|	T.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
		|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
		|	T.Vendor                   AS Vendor,
		|	T.AssetTaxClass                 AS AssetTaxClass,
		|	T.LineOfBusiness     AS LineOfBusiness,
		|	T.VATRate                   AS VATRate,
		|	T.VATActivityType          AS VATActivityType,
		|	T.LocalCost               AS LocalCost,
		|	T.VATLocal                     AS VATLocal,
		|	T.VATManag                      AS VATManag
		|FROM
		|	TTCachePartyNDSKDistribution AS T
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegistryFixStorno
		|	ON
		|		T.Recorder = RegistryFixStorno.Ref
		|		AND RegistryFixStorno.ReverseTransactionCorrection
		|		AND NOT RegistryFixStorno.AdditionalRecord
		|	
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegistryDocumentToBeCorrected
		|	ON
		|		RegistryFixStorno.CorrectedDocument = RegistryDocumentToBeCorrected.Ref 
		|		AND NOT RegistryDocumentToBeCorrected.AdditionalRecord
		|WHERE
		|	T.Period BETWEEN &StartOfBatchCalculationPeriod AND &EndOfBatchCalculationPeriod
		|	AND T.Organization = &Organization
		|	AND T.LotCalculation
		|	AND T.Recorder <> &DocumentRef
		|	AND (T.LocalCost <> 0 
		|		OR T.VATLocal <> 0)";
		
	Else
		
		// It is not caused from batch accounting version 2.2.
		// It is not necessary to adjust the balances at the end of the period - the "calculated" movements are stored only in the IB.
		Query.TempTablesManager = New TempTablesManager;
		
		Query.Text =
		"SELECT TOP 0
		|	0                             AS Character,
		|	&BasePeriod                   AS BasePeriod,
		|	T.Organization                 AS Organization,
		|	T.Department               AS Department,
		|	T.ExpenseItem              AS ExpenseItem,
		|	T.DimensionOfExpenses           AS DimensionOfExpenses,
		|	T.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
		|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
		|	T.Vendor                   AS Vendor,
		|	T.AssetTaxClass                 AS AssetTaxClass,
		|	T.LineOfBusiness     AS LineOfBusiness,
		|	T.VATRate                   AS VATRate,
		|	T.VATActivityType          AS VATActivityType,
		|	T.LocalCost               AS LocalCost,
		|	T.VATLocal                     AS VATLocal,
		|	T.VATManag                      AS VATManag
		|INTO TTAdjustmentOfNdskBatchBalancesByDistribution
		|FROM
		|	AccumulationRegister.LotsVATForAllocation AS T";
		
	EndIf;
	
	Query.Execute(); // A correction is being formed for the partyinddistribution
	
	Query.Text = "
	|SELECT DISTINCT
	|	ISNULL(TheseAreReasonsForAdjustment.RecorderDate, &BasePeriod) AS BasePeriod,
	|	PurchaseAdjustment.DocumentBasis  AS BasisOfAdjustment,
	|	LotsVATForAllocation.Organization  AS Organization,
	|	LotsVATForAllocation.Department  AS Department,
	|	LotsVATForAllocation.ExpenseItem  AS ExpenseItem,
	|	LotsVATForAllocation.DimensionOfExpenses  AS DimensionOfExpenses,
	|	LotsVATForAllocation.AssetsLiabilitiesDimension  AS AssetsLiabilitiesDimension,
	|	LotsVATForAllocation.ExpenseReceiptDocument  AS ExpenseReceiptDocument,
	|	LotsVATForAllocation.Vendor AS Vendor,
	|	LotsVATForAllocation.AssetTaxClass AS AssetTaxClass,
	|	LotsVATForAllocation.LineOfBusiness  AS LineOfBusiness,
	|	LotsVATForAllocation.VATRate AS VATRate,
	|	LotsVATForAllocation.VATActivityType  AS VATActivityType
	|INTO NdskPartyDistributionAdjustment
	|FROM
	|	AccumulationRegister.LotsVATForAllocation AS LotsVATForAllocation
	|	INNER JOIN
	|		Document.PurchaseAdjustment AS PurchaseAdjustment
	|	ON
	|		LotsVATForAllocation.Recorder = PurchaseAdjustment.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.SourceDocumentsData AS TheseAreReasonsForAdjustment
	|	ON
	|		PurchaseAdjustment.Organization = TheseAreReasonsForAdjustment.Organization
	|		AND PurchaseAdjustment.DocumentBasis = TheseAreReasonsForAdjustment.Document
	|WHERE
	|	LotsVATForAllocation.Period BETWEEN &PeriodBeginning AND &PeriodEnd 
	|		AND LotsVATForAllocation.Organization = &Organization
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ISNULL(TheseAreReasonsForAdjustment.RecorderDate, &BasePeriod) AS BasePeriod,
	|	PurchaseAdjustment.DocumentBasis  AS BasisOfAdjustment,
	|	LotsVATForAllocation.Organization  AS Organization,
	|	LotsVATForAllocation.Department  AS Department,
	|	LotsVATForAllocation.ExpenseItem  AS ExpenseItem,
	|	LotsVATForAllocation.DimensionOfExpenses  AS DimensionOfExpenses,
	|	LotsVATForAllocation.AssetsLiabilitiesDimension  AS AssetsLiabilitiesDimension,
	|	LotsVATForAllocation.ExpenseReceiptDocument  AS ExpenseReceiptDocument,
	|	LotsVATForAllocation.Vendor AS Vendor,
	|	LotsVATForAllocation.AssetTaxClass AS AssetTaxClass,
	|	LotsVATForAllocation.LineOfBusiness  AS LineOfBusiness,
	|	LotsVATForAllocation.VATRate AS VATRate,
	|	LotsVATForAllocation.VATActivityType  AS VATActivityType
	|FROM
	|	AccumulationRegister.LotsVATForAllocation AS LotsVATForAllocation
	|	INNER JOIN
	|		Document.InventoryConsumption AS PurchaseAdjustment
	|	ON
	|		LotsVATForAllocation.Recorder = PurchaseAdjustment.Ref
	|		AND PurchaseAdjustment.Patch
	|	
	|	LEFT JOIN
	|		InformationRegister.SourceDocumentsData AS TheseAreReasonsForAdjustment
	|	ON
	|		PurchaseAdjustment.Organization = TheseAreReasonsForAdjustment.Organization
	|		AND PurchaseAdjustment.DocumentBasis = TheseAreReasonsForAdjustment.Document
	|WHERE
	|	LotsVATForAllocation.Period BETWEEN &PeriodBeginning AND &PeriodEnd 
	|		AND LotsVATForAllocation.Organization = &Organization
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	ExpenseReceiptDocument
	|;
	|
	|//////////////////////////////////////////////////////////////
	|SELECT
	|	T.BasePeriod                    AS BasePeriod,
	|	T.Organization                   AS Organization,
	|	T.Department                 AS Department,
	|	T.ExpenseItem                AS ExpenseItem,
	|	T.DimensionOfExpenses             AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension      AS AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument   AS ExpenseReceiptDocument,
	|	T.Vendor                     AS Vendor,
	|	T.AssetTaxClass                   AS AssetTaxClass,
	|	T.LineOfBusiness       AS LineOfBusiness,
	|	T.VATRate                     AS VATRate,
	|	T.VATActivityType            AS VATActivityType,
	|	SUM(T.Character * T.LocalCost) AS LocalCost,
	|	SUM(T.Character * T.VATLocal)       AS VATLocal,
	|	SUM(T.Character * T.VATManag)        AS VATManag
	|INTO LotsVATForAllocationBalance
	|FROM
	|	(SELECT
	|		1 							  AS Character,
	|		&BasePeriod                   AS BasePeriod,
	|		T.Organization                 AS Organization,
	|		T.Department               AS Department,
	|		T.ExpenseItem              AS ExpenseItem,
	|		T.DimensionOfExpenses           AS DimensionOfExpenses,
	|		T.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
	|		T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|		T.Vendor                   AS Vendor,
	|		T.AssetTaxClass                 AS AssetTaxClass,
	|		T.LineOfBusiness     AS LineOfBusiness,
	|		T.VATRate                   AS VATRate,
	|		T.VATActivityType          AS VATActivityType,
	|		T.LocalCostBalance        AS LocalCost,
	|		T.VATLocalBalance              AS VATLocal,
	|		T.VATManagBalance               AS VATManag
	|	FROM
	|		AccumulationRegister.LotsVATForAllocation.Balance(&PeriodBeginning, Organization = &Organization) AS T
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -1
	|			ELSE 1
	|		END                         AS Character,
	|		ISNULL(ENDOFPERIOD(RegistryDocumentToBeCorrected.IBDocumentDate, QUARTER), &BasePeriod) AS BasePeriod,
	|		T.Organization                 AS Organization,
	|		T.Department               AS Department,
	|		T.ExpenseItem              AS ExpenseItem,
	|		T.DimensionOfExpenses           AS DimensionOfExpenses,
	|		T.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
	|		T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|		T.Vendor                   AS Vendor,
	|		T.AssetTaxClass                 AS AssetTaxClass,
	|		T.LineOfBusiness     AS LineOfBusiness,
	|		T.VATRate                   AS VATRate,
	|		T.VATActivityType          AS VATActivityType,
	|		T.LocalCost               AS LocalCost,
	|		T.VATLocal                     AS VATLocal,
	|		T.VATManag                      AS VATManag
	|	FROM
	|		AccumulationRegister.LotsVATForAllocation AS T
	|		LEFT JOIN
	|			InformationRegister.DocumentsRegistry AS RegistryFixStorno
	|		ON
	|			T.Recorder = RegistryFixStorno.Ref
	|			AND RegistryFixStorno.ReverseTransactionCorrection
	|			AND NOT RegistryFixStorno.AdditionalRecord
	|		
	|		LEFT JOIN
	|			InformationRegister.DocumentsRegistry AS RegistryDocumentToBeCorrected
	|		ON
	|			RegistryFixStorno.CorrectedDocument = RegistryDocumentToBeCorrected.Ref 
	|			AND NOT RegistryDocumentToBeCorrected.AdditionalRecord
	|	
	|	WHERE
	|		T.Period BETWEEN &PeriodBeginning AND &PeriodEnd
	|		AND T.Organization = &Organization
	|		AND T.Recorder <> &DocumentRef
	|		AND CASE
	|			WHEN VALUETYPE(T.Recorder) <> TYPE(Document.VATAllocation)
	|				THEN TRUE
	|			WHEN &Patch
	|				THEN T.Recorder <> &CorrectedDocument
	|			ELSE TRUE
	|		END
	|
	|	UNION ALL
	|	
	|	SELECT
	|		T.Character						  AS Character,
	|		T.BasePeriod                  AS BasePeriod,
	|		T.Organization                 AS Organization,
	|		T.Department               AS Department,
	|		T.ExpenseItem              AS ExpenseItem,
	|		T.DimensionOfExpenses           AS DimensionOfExpenses,
	|		T.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
	|		T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|		T.Vendor                   AS Vendor,
	|		T.AssetTaxClass                 AS AssetTaxClass,
	|		T.LineOfBusiness     AS LineOfBusiness,
	|		T.VATRate                   AS VATRate,
	|		T.VATActivityType          AS VATActivityType,
	|		T.LocalCost		  		  AS LocalCost,
	|		T.VATLocal			  	  	  AS VATLocal,
	|		T.VATManag			  	  	  AS VATManag
	|	FROM
	|		TTAdjustmentOfNdskBatchBalancesByDistribution AS T
	|	
	|	) AS T
	|
	|GROUP BY
	|	T.BasePeriod,
	|	T.Organization,
	|	T.Department,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.Vendor,
	|	T.AssetTaxClass,
	|	T.LineOfBusiness,
	|	T.VATRate,
	|	T.VATActivityType
	|
	|HAVING
	|	SUM(T.Character * T.LocalCost) <> 0 
	|	OR SUM(T.Character * T.VATLocal) <> 0
	|
	|INDEX BY
	|	ExpenseItem
	|;
	|
	|////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceTable.BasePeriod                                    AS BasePeriod,
	|	BalanceTable.Organization                                   AS Organization,
	|	BalanceTable.Department                                 AS Department,
	|	BalanceTable.LineOfBusiness                       AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                                AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                             AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension                      AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument                   AS ExpenseReceiptDocument,
	|	BalanceTable.Vendor                                     AS Vendor,
	|	BalanceTable.AssetTaxClass                                   AS AssetTaxClass,
	|	BalanceTable.VATRate                                     AS VATRate,
	|	BalanceTable.VATActivityType                            AS VATActivityType,
	|	BalanceTable.VATActivityType                            AS PartyVATTaxation,
	|	
	|	ExpenseItems.CostAllocationOptionLocal               AS OptionOfDistributionOfExpensesOfArticle,
	|	ExpenseItems.VATAssetTaxClass                                 AS TypeOfValueVATExpenseItems,
	|	ExpenseItems.SeparateVATAccountingOption                     AS OptionOfSeparateAccountingOfVATExpenseItems,
	|	
	|	BalanceTable.LocalCost                                 AS LocalCost,
	|	BalanceTable.VATLocal                                       AS VATLocal,
	|	BalanceTable.VATManag                                        AS VATManag
	|INTO BalanceTable
	|FROM
	|	LotsVATForAllocationBalance AS BalanceTable
	|	
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		BalanceTable.ExpenseItem = ExpenseItems.Ref
	|
	|INDEX BY SETS
	|(
	|	(DimensionOfExpenses,
	|	ExpenseReceiptDocument),
	|	(PartyVATTaxation)
	|)
	|;
	|
	|///////////////////////////////////////////////
	|DROP LotsVATForAllocationBalance
	|;
	|";
	
	Query.Execute(); // tables of partiesindistributioncorrection, tables of statistics are formed
	VATAllocationLocalization.InitializeTTNonCurrentAssets(Query.TempTablesManager, Attributes);
	If Not DocumentsPosting.ThereIsQueryTable("TTNonCurrentAssets", Undefined, Query.TempTablesManager) Then
		Query.Text =
		"SELECT
		|	DATETIME(1,1,1) AS DateOfRecognition,
		|	""FA"" AS NonCurrentAsset,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.Assets.EmptyRef) AS Object,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
		|	FALSE AS DistributeVAT_,
		|	FALSE AS ThisIsCommissioning,
		|	FALSE AS IncludedInTaExpensesWhenAcceptedForAccounting,
		|	UNDEFINED AS ExpenseDivisionTa,
		|	UNDEFINED AS ExpenseItemTaxAccounting,
		|	UNDEFINED AS ExpensesDimensionTaxAccounting
		|INTO TTNonCurrentAssets
		|WHERE
		|	FALSE
		|";
		Query.Execute();
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTNonCurrentAssetsQuarter", Undefined, Query.TempTablesManager) Then
		Query.Text =
		"SELECT
		|	DATETIME(1,1,1) AS DateOfRecognition,
		|	""FA"" AS NonCurrentAsset,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.Assets.EmptyRef) AS Object,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
		|	FALSE AS DistributeVAT_,
		|	FALSE AS ThisIsCommissioning,
		|	FALSE AS IncludedInTaExpensesWhenAcceptedForAccounting,
		|	UNDEFINED AS ExpenseDivisionTa,
		|	UNDEFINED AS ExpenseItemTaxAccounting,
		|	UNDEFINED AS ExpensesDimensionTaxAccounting
		|INTO TTNonCurrentAssetsQuarter
		|WHERE
		|	FALSE
		|";
		Query.Execute();
	EndIf;
	
	// Obtaining tables for analyzing the conditions for the distribution of incoming VAT by FA and IA.
	
	BegOfMonth = BegOfMonth(Attributes.Period);
	EndOfMonth = EndOfMonth(Attributes.Period);
	EndOfQuarter = EndOfQuarter(Attributes.Period);
	
	Query.SetParameter("BegOfMonth", BegOfMonth);
	Query.SetParameter("EndOfMonth", EndOfMonth);
	If Attributes.Patch Then 
		Query.SetParameter("EndOfMonthBorder", New Boundary(Attributes.CorrectedDocument.PointInTime(),BoundaryType.Excluding));
		Query.SetParameter("EndOfQuarter", New Boundary(Attributes.CorrectedDocument.PointInTime(), BoundaryType.Excluding));
	Else
		Query.SetParameter("EndOfMonthBorder", New Boundary(EndOfMonth, BoundaryType.Including));
		Query.SetParameter("EndOfQuarter", New Boundary(EndOfQuarter, BoundaryType.Including));
	EndIf;
	Query.SetParameter("EndOfPreviousMonthBorder", New Boundary(BegOfMonth - 1, BoundaryType.Including));
	
	Query.Text =
	"
	|SELECT
	|	T.ExpenseItem AS ExpenseItem,
	|	&BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.LocalCostBalance AS LocalCost,
	|	T.VATLocalBalance AS VATLocal,
	|	T.VATManagBalance AS VATManag,
	|	FALSE AS ThisIsFinalDistribution,
	|	TRUE AS TheseAreLeftovers
	|INTO LotReferencesTTBalancesAndExpenses_PreliminaryQuarter
	|FROM
	|	AccumulationRegister.LotsVATForAllocation.Balance(
	|		&EndOfQuarter,
	|		Organization = &Organization
	|			AND DimensionOfExpenses IN
	|				(SELECT
	|					T.Object
	|					FROM
	|						TTNonCurrentAssetsQuarter AS T
	|					WHERE 
	|						T.ThisIsCommissioning)
	|	) AS T
	|	
	|UNION ALL
	|	
	|SELECT
	|	T.ExpenseItem,
	|	T.BasePeriod,
	|	T.Organization,
	|	T.Department,
	|	T.DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.Vendor,
	|	T.AssetTaxClass,
	|	T.LineOfBusiness,
	|	T.VATRate,
	|	T.VATActivityType,
	|	T.LocalCost,
	|	T.VATLocal,
	|	T.VATManag,
	|	CASE WHEN T.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|		THEN FALSE
	|		ELSE TRUE
	|	END,
	|	FALSE AS TheseAreLeftovers
	|	FROM
	|		AccumulationRegister.LotsVATForAllocation AS T
	|			INNER JOIN TTNonCurrentAssetsQuarter AS OutOfOfficeAssets
	|			ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|				AND OutOfOfficeAssets.ThisIsCommissioning
	|	WHERE
	|		&AllocateVATToCapitalExpenditureInReceiptMonth
	|		AND T.Period < &BegOfMonth
	|		AND T.Organization = &Organization
	|		AND T.Active
	|		AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|UNION ALL
	|	
	|SELECT
	|	T.ExpenseItem,
	|	&BasePeriod,
	|	T.Organization,
	|	T.Department,
	|	T.DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.Vendor,
	|	T.AssetTaxClass,
	|	T.LineOfBusiness,
	|	T.VATRate,
	|	T.VATActivityType,
	|	T.LocalCost,
	|	T.VATLocal,
	|	T.VATManag,
	|	FALSE,
	|	TRUE AS TheseAreLeftovers
	|	FROM
	|		AccumulationRegister.LotsVATForAllocation AS T
	|			INNER JOIN TTNonCurrentAssetsQuarter AS OutOfOfficeAssets
	|			ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|				AND OutOfOfficeAssets.ThisIsCommissioning
	|	WHERE
	|		T.Recorder = &DocumentRef
	|
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses
	|;
	|
	|SELECT
	|	T.ExpenseItem AS ExpenseItem,
	|	&BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.LocalCostBalance AS LocalCost,
	|	T.VATLocalBalance AS VATLocal,
	|	T.VATManagBalance AS VATManag,
	|	TRUE AS TheseAreLeftovers
	|INTO LotReferenceTTBalanceAndExpenses_PreliminaryMonth
	|FROM
	|	AccumulationRegister.LotsVATForAllocation.Balance(
	|		&EndOfMonthBorder,
	|		Organization = &Organization
	|			AND DimensionOfExpenses IN
	|				(SELECT
	|					T.Object
	|					FROM
	|						TTNonCurrentAssets AS T
	|					WHERE 
	|						T.ThisIsCommissioning)
	|	) AS T
	|	
	|UNION ALL
	|	
	|SELECT
	|	T.ExpenseItem,
	|	T.BasePeriod,
	|	T.Organization,
	|	T.Department,
	|	T.DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.Vendor,
	|	T.AssetTaxClass,
	|	T.LineOfBusiness,
	|	T.VATRate,
	|	T.VATActivityType,
	|	T.LocalCost,
	|	T.VATLocal,
	|	T.VATManag,
	|	FALSE AS TheseAreLeftovers
	|	FROM
	|		AccumulationRegister.LotsVATForAllocation AS T
	|			INNER JOIN TTNonCurrentAssets AS OutOfOfficeAssets
	|			ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|				AND OutOfOfficeAssets.ThisIsCommissioning
	|	WHERE
	|		&AllocateVATToCapitalExpenditureInReceiptMonth
	|		AND T.Period < &BegOfMonth
	|		AND T.Organization = &Organization
	|		AND T.Active
	|		AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|	
	|UNION ALL
	|	
	|SELECT
	|	T.ExpenseItem,
	|	&BasePeriod,
	|	T.Organization,
	|	T.Department,
	|	T.DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.Vendor,
	|	T.AssetTaxClass,
	|	T.LineOfBusiness,
	|	T.VATRate,
	|	T.VATActivityType,
	|	T.LocalCost,
	|	T.VATLocal,
	|	T.VATManag,
	|	TRUE AS TheseAreLeftovers
	|	FROM
	|		AccumulationRegister.LotsVATForAllocation AS T
	|			INNER JOIN TTNonCurrentAssets AS OutOfOfficeAssets
	|			ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|				AND OutOfOfficeAssets.ThisIsCommissioning
	|	WHERE
	|		T.Recorder = &DocumentRef
	|
	|INDEX BY
	|	ExpenseItem
	|;
	|
	|SELECT
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.VATActivityType AS PartyVATTaxation,
	|	T.TheseAreLeftovers AS TheseAreLeftovers,
	|	ExpenseItems.CostAllocationOptionLocal AS OptionOfDistributionOfExpensesOfArticle,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth
	|FROM
	|	LotReferenceTTBalanceAndExpenses_PreliminaryMonth AS T
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		T.ExpenseItem = ExpenseItems.Ref
	|
	|GROUP BY
	|	T.DimensionOfExpenses,
	|	T.ExpenseReceiptDocument,
	|	T.BasePeriod,
	|	T.Organization,
	|	T.Department,
	|	T.ExpenseItem, 
	|	T.AssetsLiabilitiesDimension,
	|	T.Vendor,
	|	T.AssetTaxClass,
	|	T.LineOfBusiness,
	|	T.VATRate,
	|	T.VATActivityType,
	|	T.TheseAreLeftovers,
	|	ExpenseItems.CostAllocationOptionLocal
	|
	|HAVING
	|	(SUM(T.LocalCost) <> 0
	|		OR SUM(T.VATLocal) <> 0)
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	ExpenseReceiptDocument
	|;
	|
	|SELECT
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.VATActivityType AS PartyVATTaxation,
	|	T.TheseAreLeftovers AS TheseAreLeftovers,
	|	ExpenseItems.CostAllocationOptionLocal AS OptionOfDistributionOfExpensesOfArticle,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter
	|FROM
	|	LotReferencesTTBalancesAndExpenses_PreliminaryQuarter AS T
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		T.ExpenseItem = ExpenseItems.Ref
	|
	|GROUP BY
	|	T.DimensionOfExpenses,
	|	T.ExpenseReceiptDocument,
	|	T.BasePeriod,
	|	T.Organization,
	|	T.Department,
	|	T.ExpenseItem, 
	|	T.AssetsLiabilitiesDimension,
	|	T.Vendor,
	|	T.AssetTaxClass,
	|	T.LineOfBusiness,
	|	T.VATRate,
	|	T.VATActivityType,
	|	T.TheseAreLeftovers,
	|	ExpenseItems.CostAllocationOptionLocal
	|
	|HAVING
	|	(SUM(T.LocalCost) <> 0
	|		OR SUM(T.VATLocal) <> 0)
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	ExpenseReceiptDocument
	|;
	|
	|DROP LotReferenceTTBalanceAndExpenses_PreliminaryMonth
	|; 
	|
	|SELECT
	|	LotsVATForAllocation.Organization                 AS Organization,
	|	LotsVATForAllocation.Department               AS Department,
	|	LotsVATForAllocation.LineOfBusiness     AS LineOfBusiness,
	|	LotsVATForAllocation.ExpenseItem              AS ExpenseItem,
	|	LotsVATForAllocation.DimensionOfExpenses           AS DimensionOfExpenses,
	|	LotsVATForAllocation.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
	|	LotsVATForAllocation.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	LotsVATForAllocation.VATActivityType          AS VATActivityType,
	|	
	|	LotsVATForAllocation.Vendor                   AS Vendor,
	|	LotsVATForAllocation.VATActivityType          AS PartyVATTaxation,
	|	LotsVATForAllocation.VATRate                   AS VATRate,
	|	
	|	OutOfOfficeAssets.DistributeVAT_                         AS DistributeVAT_,
	|	
	|	ENDOFPERIOD(LotsVATForAllocation.Period, MONTH) AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	
	|	CASE WHEN OutOfOfficeAssets.DistributeVAT_
	|		THEN UNDEFINED
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                               AS NewVATTaxation,
	|	OutOfOfficeAssets.NonCurrentAsset                       AS NonCurrentAsset,
	|	
	|	OutOfOfficeAssets.IncludedInTaExpensesWhenAcceptedForAccounting   AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	OutOfOfficeAssets.ExpenseDivisionTa                 AS ExpenseDivisionTa,
	|	OutOfOfficeAssets.ExpenseItemTaxAccounting                        AS ExpenseItemTaxAccounting,
	|	OutOfOfficeAssets.ExpensesDimensionTaxAccounting                     AS ExpensesDimensionTaxAccounting,
	|	
	|	LotsVATForAllocation.AssetTaxClass                 AS AssetTaxClass,
	|	CASE WHEN LotsVATForAllocation.Period < &BegOfMonth
	|		THEN FALSE
	|		ELSE TRUE
	|	END                                               AS TheseAreLeftovers,
	|	
	|	LotsVATForAllocation.LocalCost               AS LocalCost,
	|	LotsVATForAllocation.VATLocal                     AS VATLocal,
	|	LotsVATForAllocation.VATManag                      AS VATManag
	|INTO TTLotREFERENCESOfVATOnHVACommissionedThisMonth
	|FROM
	|	AccumulationRegister.LotsVATForAllocation AS LotsVATForAllocation
	|	
	|	INNER JOIN 
	|		TTNonCurrentAssets AS OutOfOfficeAssets
	|	ON 
	|		LotsVATForAllocation.DimensionOfExpenses = OutOfOfficeAssets.Object
	|
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		LotsVATForAllocation.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND LotsVATForAllocation.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND LotsVATForAllocation.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND LotsVATForAllocation.Department = NdskPartyDistributionAdjustment.Department
	|		AND LotsVATForAllocation.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND LotsVATForAllocation.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND LotsVATForAllocation.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND LotsVATForAllocation.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND LotsVATForAllocation.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND LotsVATForAllocation.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND LotsVATForAllocation.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|WHERE
	|	&AllocateVATToCapitalExpenditureInReceiptMonth
	|	AND LotsVATForAllocation.Organization = &Organization
	|	AND LotsVATForAllocation.Active
	|	AND LotsVATForAllocation.Period <= &EndOfMonth
	|	AND LotsVATForAllocation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND LotsVATForAllocation.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	AND (OutOfOfficeAssets.DistributeVAT_ OR  OutOfOfficeAssets.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT))
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|	VATInvoiced.VATActivityType AS VATActivityType,
	|	VATInvoiced.VATBalance AS VATAmount
	|INTO TTVATAmountPresented
	|FROM
	|	AccumulationRegister.VATInvoiced.Balance(
	|			&EndOfPreviousMonthBorder,
	|			(TaxInvoice, AssetTaxClass, VATRate, VATActivityType) IN
	|				(SELECT
	|					T.ExpenseReceiptDocument,
	|					T.AssetTaxClass,
	|					T.VATRate,
	|					T.VATActivityType
	|				FROM
	|					TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter  AS T
	|				WHERE
	|					&DistributionForFullPeriod)) AS VATInvoiced
	|
	|UNION ALL
	|
	|SELECT
	|	VATInvoiced.TaxInvoice AS TaxInvoice,
	|	VATInvoiced.AssetTaxClass AS AssetTaxClass,
	|	VATInvoiced.VATRate AS VATRate,
	|	VATInvoiced.VATActivityType AS VATActivityType,
	|	VATInvoiced.VATBalance AS VATAmount
	|FROM
	|	AccumulationRegister.VATInvoiced.Balance(
	|			&EndOfPreviousMonthBorder,
	|			(TaxInvoice, AssetTaxClass, VATRate, VATActivityType) IN
	|				(SELECT
	|					T.ExpenseReceiptDocument,
	|					T.AssetTaxClass,
	|					T.VATRate,
	|					T.VATActivityType
	|				FROM
	|					TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth AS T
	|				WHERE
	|					NOT &DistributionForFullPeriod)) AS VATInvoiced
	|
	|UNION ALL
	|
	|SELECT
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.VATActivityType,
	|	VATInvoiced.VAT
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|		INNER JOIN TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter AS Lots
	|		ON (Lots.ExpenseReceiptDocument = VATInvoiced.TaxInvoice)
	|			AND (Lots.AssetTaxClass = VATInvoiced.AssetTaxClass)
	|			AND (Lots.VATRate = VATInvoiced.VATRate)
	|			AND (Lots.VATActivityType = VATInvoiced.VATActivityType)
	|WHERE
	|	&DistributionForFullPeriod
	|	AND VATInvoiced.Active
	|	AND NOT VATInvoiced.PeriodEndTransaction
	|	AND VATInvoiced.Period >= &BegOfMonth
	|	AND VATInvoiced.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|UNION ALL
	|
	|SELECT
	|	VATInvoiced.TaxInvoice,
	|	VATInvoiced.AssetTaxClass,
	|	VATInvoiced.VATRate,
	|	VATInvoiced.VATActivityType,
	|	VATInvoiced.VAT
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|		INNER JOIN TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth AS Lots
	|		ON (Lots.ExpenseReceiptDocument = VATInvoiced.TaxInvoice)
	|			AND (Lots.AssetTaxClass = VATInvoiced.AssetTaxClass)
	|			AND (Lots.VATRate = VATInvoiced.VATRate)
	|			AND (Lots.VATActivityType = VATInvoiced.VATActivityType)
	|WHERE
	|	NOT &DistributionForFullPeriod
	|	AND VATInvoiced.Active
	|	AND NOT VATInvoiced.PeriodEndTransaction
	|	AND VATInvoiced.Period >= &BegOfMonth
	|	AND VATInvoiced.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|UNION ALL
	|
	|SELECT
	|	VATWriteOff.TaxInvoice,
	|	TSAssets_.AssetTaxClass,
	|	TSAssets_.VATRate,
	|	TSAssets_.VATActivityType,
	|	TSAssets_.VAT
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter AS Lots
	|		INNER JOIN Document.VATWritingOffAsExpenses AS VATWriteOff
	|			ON (Lots.ExpenseReceiptDocument = VATWriteOff.TaxInvoice)
	|		INNER JOIN Document.VATWritingOffAsExpenses.Assets_ AS TSAssets_
	|		ON (TSAssets_.Ref = VATWriteOff.Ref)
	|			AND (Lots.AssetTaxClass = TSAssets_.AssetTaxClass)
	|			AND (Lots.VATRate = TSAssets_.VATRate)
	|			AND (Lots.VATActivityType = TSAssets_.VATActivityType)
	|WHERE
	|	&DistributionForFullPeriod
	|	AND VATWriteOff.Posted
	|	AND VATWriteOff.Date < &BegOfMonth
	|
	|UNION ALL
	|
	|SELECT
	|	VATWriteOff.TaxInvoice,
	|	TSAssets_.AssetTaxClass,
	|	TSAssets_.VATRate,
	|	TSAssets_.VATActivityType,
	|	TSAssets_.VAT
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth AS Lots
	|		INNER JOIN Document.VATWritingOffAsExpenses AS VATWriteOff
	|			ON (Lots.ExpenseReceiptDocument = VATWriteOff.TaxInvoice)
	|		INNER JOIN Document.VATWritingOffAsExpenses.Assets_ AS TSAssets_
	|		ON (TSAssets_.Ref = VATWriteOff.Ref)
	|			AND (Lots.AssetTaxClass = TSAssets_.AssetTaxClass)
	|			AND (Lots.VATRate = TSAssets_.VATRate)
	|			AND (Lots.VATActivityType = TSAssets_.VATActivityType)
	|WHERE
	|	NOT &DistributionForFullPeriod
	|	AND VATWriteOff.Posted
	|	AND VATWriteOff.Date < &BegOfMonth
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTVATAmountPresented.TaxInvoice AS TaxInvoice,
	|	SUM(TTVATAmountPresented.VATAmount) AS VATAmount
	|INTO TTVATAmountSubmittedBySF
	|FROM
	|	TTVATAmountPresented AS TTVATAmountPresented
	|
	|GROUP BY
	|	TTVATAmountPresented.TaxInvoice
	|
	|INDEX BY
	|	TaxInvoice
	|;
	|
	|DROP TTVATAmountPresented
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter.ExpenseReceiptDocument AS TaxInvoice,
	|	SUM(TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter.VATLocal) AS VATLocal
	|INTO TTVATAmountOfLotReferenceAndExpensesFromPreviousMonthsToHPA
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter AS TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter
	|WHERE
	|	&DistributionForFullPeriod
	|
	|GROUP BY
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter.ExpenseReceiptDocument
	|
	|
	|UNION ALL
	|
    |SELECT
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth.ExpenseReceiptDocument AS TaxInvoice,
	|	SUM(TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth.VATLocal) AS VATLocal
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth AS TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth
	|WHERE
	|	NOT &DistributionForFullPeriod
	|
	|GROUP BY
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth.ExpenseReceiptDocument
	|INDEX BY
	|	TaxInvoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(VATSubmittedBySF.VATAmount, 0) = Lots.VATLocal AS NoDeductionWasClaimed,
	|	Lots.TaxInvoice AS TaxInvoice
	|INTO TTDeductionData
	|FROM
	|	TTVATAmountSubmittedBySF AS VATSubmittedBySF
	|		INNER JOIN TTVATAmountOfLotReferenceAndExpensesFromPreviousMonthsToHPA AS Lots
	|		ON Lots.TaxInvoice = VATSubmittedBySF.TaxInvoice
	|;
	|
	|DROP TTVATAmountOfLotReferenceAndExpensesFromPreviousMonthsToHPA
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.PartyVATTaxation AS PartyVATTaxation,
	|	T.OptionOfDistributionOfExpensesOfArticle AS OptionOfDistributionOfExpensesOfArticle,
	|	T.TheseAreLeftovers AS TheseAreLeftovers,
	|	T.LocalCost AS LocalCost,
	|	T.VATLocal AS VATLocal,
	|	T.VATManag AS VATManag
	|INTO TTLotReferenceChangeTaxableToNonTaxableDeductionWasDeclared
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter AS T
	|
	|	INNER JOIN TTNonCurrentAssetsQuarter AS OutOfOfficeAssets
	|	ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|
	|	LEFT JOIN TTDeductionData AS DeductionData
	|	ON T.ExpenseReceiptDocument = DeductionData.TaxInvoice
	|		AND DeductionData.NoDeductionWasClaimed
	|	
	|WHERE
	|	DeductionData.TaxInvoice IS NULL
	|	AND T.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	AND (OutOfOfficeAssets.DistributeVAT_
	|		OR OutOfOfficeAssets.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT))
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					LotReferencesTTBalancesAndExpenses_PreliminaryQuarter AS Lots
	|				WHERE
	|					Lots.DimensionOfExpenses = T.DimensionOfExpenses
	|					AND Lots.ExpenseReceiptDocument = T.ExpenseReceiptDocument
	|					AND Lots.ThisIsFinalDistribution)
	|	
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	ExpenseReceiptDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.PartyVATTaxation AS PartyVATTaxation,
	|	T.OptionOfDistributionOfExpensesOfArticle AS OptionOfDistributionOfExpensesOfArticle,
	|	T.TheseAreLeftovers AS TheseAreLeftovers,
	|	T.LocalCost AS LocalCost,
	|	T.VATLocal AS VATLocal,
	|	T.VATManag AS VATManag
	|INTO TTOfPartyChangeTaxableToNonTaxableDeductionWasNotDeclared
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth AS T
	|
	|	INNER JOIN TTNonCurrentAssets AS OutOfOfficeAssets
	|	ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|
	|	INNER JOIN TTDeductionData AS DeductionData
	|	ON T.ExpenseReceiptDocument = DeductionData.TaxInvoice
	|		AND DeductionData.NoDeductionWasClaimed
	|	
	|WHERE
	|	T.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	AND OutOfOfficeAssets.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	ExpenseReceiptDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.VATActivityType AS PartyVATTaxation,
	|	T.OptionOfDistributionOfExpensesOfArticle AS OptionOfDistributionOfExpensesOfArticle,
	|	T.TheseAreLeftovers AS TheseAreLeftovers,
	|	T.LocalCost AS LocalCost,
	|	T.VATLocal AS VATLocal,
	|	T.VATManag AS VATManag
	|INTO TTLotReferenceChangeOfTaxableToDistributableDeductionWasNotDeclared
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter AS T
	|
	|	INNER JOIN TTNonCurrentAssetsQuarter AS OutOfOfficeAssets
	|	ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|		AND (OutOfOfficeAssets.DistributeVAT_)
	|
	|	INNER JOIN TTDeductionData AS DeductionData
	|	ON T.ExpenseReceiptDocument = DeductionData.TaxInvoice
	|		AND (DeductionData.NoDeductionWasClaimed)
	|WHERE
	|	&DistributionForFullPeriod
	|	AND T.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					LotReferencesTTBalancesAndExpenses_PreliminaryQuarter AS Lots
	|				WHERE
	|					Lots.DimensionOfExpenses = T.DimensionOfExpenses
	|					AND Lots.ExpenseReceiptDocument = T.ExpenseReceiptDocument
	|					AND Lots.ThisIsFinalDistribution)
	|
	|UNION ALL
	|
    |SELECT
	|	T.BasePeriod AS BasePeriod,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	T.Vendor AS Vendor,
	|	T.AssetTaxClass AS AssetTaxClass,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.VATRate AS VATRate,
	|	T.VATActivityType AS VATActivityType,
	|	T.VATActivityType AS PartyVATTaxation,
	|	T.OptionOfDistributionOfExpensesOfArticle AS OptionOfDistributionOfExpensesOfArticle,
	|	T.TheseAreLeftovers AS TheseAreLeftovers,
	|	T.LocalCost AS LocalCost,
	|	T.VATLocal AS VATLocal,
	|	T.VATManag AS VATManag
	|FROM
	|	TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth AS T
	|
	|	INNER JOIN TTNonCurrentAssets AS OutOfOfficeAssets
	|	ON T.DimensionOfExpenses = OutOfOfficeAssets.Object
	|
	|	INNER JOIN TTDeductionData AS DeductionData
	|	ON T.ExpenseReceiptDocument = DeductionData.TaxInvoice
	|		AND (DeductionData.NoDeductionWasClaimed)
	|WHERE
	|	NOT &DistributionForFullPeriod
	|	AND T.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	AND (OutOfOfficeAssets.DistributeVAT_ OR  OutOfOfficeAssets.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT))
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	ExpenseReceiptDocument
	|;
	|
	|DROP LotReferencesTTBalancesAndExpenses_PreliminaryQuarter
	|;
	|
	|DROP TTDeductionData
	|;
	|
	|DROP TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAQuarter
	|;
	|
	|DROP TTBalancesOfVATLotReferencesAndExpensesOfPreviousMonthsForHPAMonth
	|;
    |
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Lots.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	Lots.Organization AS Organization,
	|	Lots.Department AS Department,
	|	Lots.ExpenseItem AS ExpenseItem,
	|	Lots.DimensionOfExpenses AS DimensionOfExpenses,
	|	Lots.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Lots.Vendor AS Vendor,
	|	Lots.AssetTaxClass AS AssetTaxClass,
	|	Lots.LineOfBusiness AS LineOfBusiness,
	|	Lots.VATRate AS VATRate,
	|	Lots.VATActivityType AS VATActivityType,
	|	Lots.TheseAreLeftovers                  AS TheseAreLeftovers,
	|
	|	FALSE                               AS DistributeVAT_,
	|	Lots.BasePeriod                  AS BasePeriod,
	|	UNDEFINED                       AS BasisOfAdjustment,
	|	Lots.VATActivityType          AS NewVATTaxation,
	|	Lots.DimensionOfExpenses           AS NonCurrentAsset,
	|	
	|	TRUE                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                       AS ExpenseDivisionTa,
	|	UNDEFINED                       AS ExpenseItemTaxAccounting,
	|	UNDEFINED                       AS ExpensesDimensionTaxAccounting,
	|
	|	Lots.LocalCost               AS LocalCost,
	|	Lots.VATLocal                     AS VATLocal,
	|	Lots.VATManag                      AS VATManag
	|INTO TTSpecialConditionsOfCommissioning
	|FROM
	|	TTLotReferenceChangeTaxableToNonTaxableDeductionWasDeclared AS Lots
	|WHERE
	|	(Lots.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR Lots.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|	AND &DistributionForFullPeriod
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Lots.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	Lots.Organization AS Organization,
	|	Lots.Department AS Department,
	|	Lots.ExpenseItem AS ExpenseItem,
	|	Lots.DimensionOfExpenses AS DimensionOfExpenses,
	|	Lots.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Lots.Vendor AS Vendor,
	|	Lots.AssetTaxClass AS AssetTaxClass,
	|	Lots.LineOfBusiness AS LineOfBusiness,
	|	Lots.VATRate AS VATRate,
	|	Lots.VATActivityType AS VATActivityType,
	|	Lots.TheseAreLeftovers                  AS TheseAreLeftovers,
	|
	|	FALSE                               AS DistributeVAT_,
	|	Lots.BasePeriod                  AS BasePeriod,
	|	UNDEFINED                       AS BasisOfAdjustment,
	|	Lots.VATActivityType          AS NewVATTaxation,
	|	Lots.DimensionOfExpenses           AS NonCurrentAsset,
	|	
	|	TRUE                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                       AS ExpenseDivisionTa,
	|	UNDEFINED                       AS ExpenseItemTaxAccounting,
	|	UNDEFINED                       AS ExpensesDimensionTaxAccounting,
	|
	|	Lots.LocalCost               AS LocalCost,
	|	Lots.VATLocal                     AS VATLocal,
	|	Lots.VATManag                      AS VATManag

	|FROM
	|	TTOfPartyChangeTaxableToNonTaxableDeductionWasNotDeclared AS Lots
	|WHERE
	|	(Lots.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR Lots.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|
	|UNION ALL
	|
	|SELECT
	|	Lots.ExpenseReceiptDocument,
	|	Lots.Organization,
	|	Lots.Department,
	|	Lots.ExpenseItem,
	|	Lots.DimensionOfExpenses,
	|	Lots.AssetsLiabilitiesDimension,
	|	Lots.Vendor,
	|	Lots.AssetTaxClass,
	|	Lots.LineOfBusiness,
	|	Lots.VATRate,
	|	Lots.VATActivityType,
	|	Lots.TheseAreLeftovers                  AS TheseAreLeftovers,
	|
	|	FALSE                               AS DistributeVAT_,
	|	Lots.BasePeriod                  AS BasePeriod,
	|	UNDEFINED                       AS BasisOfAdjustment,
	|	Lots.VATActivityType          AS NewVATTaxation,
	|	Lots.DimensionOfExpenses           AS NonCurrentAsset,
	|	
	|	TRUE                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                       AS ExpenseDivisionTa,
	|	UNDEFINED                       AS ExpenseItemTaxAccounting,
	|	UNDEFINED                       AS ExpensesDimensionTaxAccounting,
	|	
	|	Lots.LocalCost               AS LocalCost,
	|	Lots.VATLocal                     AS VATLocal,
	|	Lots.VATManag                      AS VATManag
	|FROM
	|	TTLotREFERENCESOfVATOnHVACommissionedThisMonth AS Lots
	|
	|UNION ALL
	|
	|SELECT
	|	Lots.ExpenseReceiptDocument,
	|	Lots.Organization,
	|	Lots.Department,
	|	Lots.ExpenseItem,
	|	Lots.DimensionOfExpenses,
	|	Lots.AssetsLiabilitiesDimension,
	|	Lots.Vendor,
	|	Lots.AssetTaxClass,
	|	Lots.LineOfBusiness,
	|	Lots.VATRate,
	|	Lots.VATActivityType,
	|	Lots.TheseAreLeftovers                  AS TheseAreLeftovers,
	|
	|	FALSE                               AS DistributeVAT_,
	|	Lots.BasePeriod                  AS BasePeriod,
	|	UNDEFINED                       AS BasisOfAdjustment,
	|	Lots.VATActivityType          AS NewVATTaxation,
	|	Lots.DimensionOfExpenses           AS NonCurrentAsset,
	|	
	|	TRUE                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                       AS ExpenseDivisionTa,
	|	UNDEFINED                       AS ExpenseItemTaxAccounting,
	|	UNDEFINED                       AS ExpensesDimensionTaxAccounting,
	|	
	|	Lots.LocalCost               AS LocalCost,
	|	Lots.VATLocal                     AS VATLocal,
	|	Lots.VATManag                      AS VATManag
	|FROM
	|	TTLotReferenceChangeOfTaxableToDistributableDeductionWasNotDeclared AS Lots
	|
	|WHERE
	|	(Lots.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR Lots.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|
	|INDEX BY
	|	ExpenseReceiptDocument";
	
	Query.Execute();
	
	
	Query.Text =
	// Distribution of VAT on export operations
	"SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	FALSE                                             AS DistributeVAT_,
	|	
	|	ENDOFPERIOD(ISNULL(NdskPartyDistributionAdjustment.BasePeriod, BalanceTable.BasePeriod), QUARTER) AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	
	|	BalanceTable.PartyVATTaxation         AS NewVATTaxation,
	|	""""                                             AS NonCurrentAsset,
	|	
	|	FALSE                                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                                     AS ExpenseDivisionTa,
	|	UNDEFINED                                     AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                     AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                      AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                    AS LocalCost,
	|	BalanceTable.VATLocal                          AS VATLocal,
	|	BalanceTable.VATManag                           AS VATManag
	|FROM
	|	BalanceTable AS BalanceTable
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	BalanceTable.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	AND NOT BalanceTable.OptionOfSeparateAccountingOfVATExpenseItems = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|
	|UNION ALL 
	|
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	TRUE                                           AS DistributeVAT_,
	|
	|	ENDOFPERIOD(ISNULL(NdskPartyDistributionAdjustment.BasePeriod, BalanceTable.BasePeriod), QUARTER) AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|
	|	UNDEFINED                                     AS NewVATTaxation,
	|	
	|	CASE WHEN BalanceTable.TypeOfValueVATExpenseItems = VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|		THEN ""ConstructionObject""
	|	ELSE """"
	|	END                                            AS NonCurrentAsset,
	|	FALSE                                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                                     AS ExpenseDivisionTa,
	|	UNDEFINED                                     AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                     AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                      AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                    AS LocalCost,
	|	BalanceTable.VATLocal                          AS VATLocal,
	|	BalanceTable.VATManag                           AS VATManag
	|FROM
	|	BalanceTable AS BalanceTable
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	(BalanceTable.PartyVATTaxation <> VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|		OR BalanceTable.OptionOfSeparateAccountingOfVATExpenseItems = VALUE(Enum.SeparateVATAccountingOptions.Allocation))
	|	AND ISNULL(BalanceTable.OptionOfDistributionOfExpensesOfArticle, VALUE(Enum.CostAllocationOptions.EmptyRef)) 
	|		<> VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|	AND BalanceTable.PartyVATTaxation <> VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|	AND &DistributionForFullPeriod
	|
	|UNION ALL
	|
	// General conditions for the distribution of VAT during the commissioning of FA and IA
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|	
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	OutOfOfficeAssets.DistributeVAT_                      AS DistributeVAT_,
	|	
	|	ENDOFPERIOD(OutOfOfficeAssets.DateOfRecognition, MONTH) AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	
	|	CASE 
	|		WHEN NOT OutOfOfficeAssets.DistributeVAT_
	|			THEN OutOfOfficeAssets.VATTaxation
	|		ELSE UNDEFINED
	|	END                                             AS NewVATTaxation,
	|	OutOfOfficeAssets.NonCurrentAsset                     AS NonCurrentAsset,
	|	
	|	OutOfOfficeAssets.IncludedInTaExpensesWhenAcceptedForAccounting AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	OutOfOfficeAssets.ExpenseDivisionTa               AS ExpenseDivisionTa,
	|	OutOfOfficeAssets.ExpenseItemTaxAccounting                      AS ExpenseItemTaxAccounting,
	|	OutOfOfficeAssets.ExpensesDimensionTaxAccounting                   AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                       AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                     AS LocalCost,
	|	BalanceTable.VATLocal                           AS VATLocal,
	|	BalanceTable.VATManag                            AS VATManag
	|FROM
	|	BalanceTable AS BalanceTable
	|	
	|	INNER JOIN 
	|		TTNonCurrentAssets AS OutOfOfficeAssets
	|	ON 
	|		BalanceTable.DimensionOfExpenses = OutOfOfficeAssets.Object
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTSpecialConditionsOfCommissioning AS TTSpecialConditionsOfCommissioning
	|				WHERE
	|					BalanceTable.DimensionOfExpenses = TTSpecialConditionsOfCommissioning.DimensionOfExpenses
	|					AND BalanceTable.ExpenseReceiptDocument = TTSpecialConditionsOfCommissioning.ExpenseReceiptDocument
	|					AND BalanceTable.Organization = TTSpecialConditionsOfCommissioning.Organization
	|					AND BalanceTable.Department = TTSpecialConditionsOfCommissioning.Department
	|					AND BalanceTable.ExpenseItem = TTSpecialConditionsOfCommissioning.ExpenseItem
	|					AND BalanceTable.AssetsLiabilitiesDimension = TTSpecialConditionsOfCommissioning.AssetsLiabilitiesDimension
	|					AND BalanceTable.Vendor = TTSpecialConditionsOfCommissioning.Vendor
	|					AND BalanceTable.AssetTaxClass = TTSpecialConditionsOfCommissioning.AssetTaxClass
	|					AND BalanceTable.LineOfBusiness = TTSpecialConditionsOfCommissioning.LineOfBusiness
	|					AND BalanceTable.VATRate = TTSpecialConditionsOfCommissioning.VATRate
	|					AND BalanceTable.VATActivityType = TTSpecialConditionsOfCommissioning.VATActivityType)
	|	AND (BalanceTable.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR BalanceTable.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|	AND NOT (NOT &DistributionForFullPeriod
	|			AND BalanceTable.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			AND (OutOfOfficeAssets.DistributeVAT_
	|				OR OutOfOfficeAssets.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)))
	|
	|UNION ALL
	|
	// Restoration of VAT and write-off for expenses when changing the type of activity 
	// from "Taxable" to "Distributable"/"Non-taxable" in "Acceptance for accounting", if the deduction was claimed
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|	
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	OutOfOfficeAssets.DistributeVAT_                      AS DistributeVAT_,
	|	
	|	ENDOFPERIOD(OutOfOfficeAssets.DateOfRecognition, QUARTER) AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	
	|	CASE 
	|		WHEN NOT OutOfOfficeAssets.DistributeVAT_
	|			THEN OutOfOfficeAssets.VATTaxation
	|		ELSE UNDEFINED
	|	END                                             AS NewVATTaxation,
	|	OutOfOfficeAssets.NonCurrentAsset                     AS NonCurrentAsset,
	|	
	|	OutOfOfficeAssets.IncludedInTaExpensesWhenAcceptedForAccounting AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	OutOfOfficeAssets.ExpenseDivisionTa               AS ExpenseDivisionTa,
	|	OutOfOfficeAssets.ExpenseItemTaxAccounting                      AS ExpenseItemTaxAccounting,
	|	OutOfOfficeAssets.ExpensesDimensionTaxAccounting                   AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                       AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                     AS LocalCost,
	|	BalanceTable.VATLocal                           AS VATLocal,
	|	BalanceTable.VATManag                            AS VATManag
	|FROM
	|	TTLotReferenceChangeTaxableToNonTaxableDeductionWasDeclared AS BalanceTable
	|	
	|	INNER JOIN 
	|		TTNonCurrentAssetsQuarter AS OutOfOfficeAssets
	|	ON 
	|		BalanceTable.DimensionOfExpenses = OutOfOfficeAssets.Object
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	(BalanceTable.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR BalanceTable.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|	AND &DistributionForFullPeriod
	|
	|UNION ALL
	|
	// Inclusion of VAT in the cost when changing the type of activity 
	// from "Taxable" to "Non-taxable" in the "Acceptance for accounting", if the deduction was not claimed
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|	
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	OutOfOfficeAssets.DistributeVAT_                      AS DistributeVAT_,
	|	
	|	BalanceTable.BasePeriod                       AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	
	|	OutOfOfficeAssets.VATTaxation                    AS NewVATTaxation,
	|	OutOfOfficeAssets.NonCurrentAsset                     AS NonCurrentAsset,
	|	
	|	OutOfOfficeAssets.IncludedInTaExpensesWhenAcceptedForAccounting AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	OutOfOfficeAssets.ExpenseDivisionTa               AS ExpenseDivisionTa,
	|	OutOfOfficeAssets.ExpenseItemTaxAccounting                      AS ExpenseItemTaxAccounting,
	|	OutOfOfficeAssets.ExpensesDimensionTaxAccounting                   AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                       AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                     AS LocalCost,
	|	BalanceTable.VATLocal                           AS VATLocal,
	|	BalanceTable.VATManag                            AS VATManag
	|FROM
	|	TTOfPartyChangeTaxableToNonTaxableDeductionWasNotDeclared AS BalanceTable
	|	
	|	INNER JOIN 
	|		TTNonCurrentAssets AS OutOfOfficeAssets
	|	ON 
	|		BalanceTable.DimensionOfExpenses = OutOfOfficeAssets.Object
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	(BalanceTable.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR BalanceTable.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|
	|UNION ALL
	|
	// Inclusion in the cost in proportion to the month of receipt on the 08 account when changing activities 
	// from "Taxable" to "Distributable" in "Acceptance for accounting", if the deduction was not claimed
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|	
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	OutOfOfficeAssets.DistributeVAT_                      AS DistributeVAT_,
	|	
	|	BalanceTable.BasePeriod                       AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	
	|	CASE 
	|		WHEN NOT OutOfOfficeAssets.DistributeVAT_
	|			THEN OutOfOfficeAssets.VATTaxation
	|		ELSE UNDEFINED
	|	END                                             AS NewVATTaxation,
	|	OutOfOfficeAssets.NonCurrentAsset                     AS NonCurrentAsset,
	|	
	|	OutOfOfficeAssets.IncludedInTaExpensesWhenAcceptedForAccounting AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	OutOfOfficeAssets.ExpenseDivisionTa               AS ExpenseDivisionTa,
	|	OutOfOfficeAssets.ExpenseItemTaxAccounting                      AS ExpenseItemTaxAccounting,
	|	OutOfOfficeAssets.ExpensesDimensionTaxAccounting                   AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                       AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                     AS LocalCost,
	|	BalanceTable.VATLocal                           AS VATLocal,
	|	BalanceTable.VATManag                            AS VATManag
	|FROM
	|	TTLotReferenceChangeOfTaxableToDistributableDeductionWasNotDeclared AS BalanceTable
	|	
	|	INNER JOIN 
	|		TTNonCurrentAssetsQuarter AS OutOfOfficeAssets
	|	ON 
	|		BalanceTable.DimensionOfExpenses = OutOfOfficeAssets.Object
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	&DistributionForFullPeriod
	|	AND (BalanceTable.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR BalanceTable.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|
	|UNION ALL
	|
	// Inclusion in the cost in the proportion of the month of receipt on the 08 account when changing activities 
	// from "Taxable" to "Distributable" in the "Acceptance for accounting" in the proportion of the month, if the deduction was not claimed
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|	
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	OutOfOfficeAssets.DistributeVAT_                      AS DistributeVAT_,
	|	
	|	BalanceTable.BasePeriod                       AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	
	|	CASE 
	|		WHEN NOT OutOfOfficeAssets.DistributeVAT_
	|			THEN OutOfOfficeAssets.VATTaxation
	|		ELSE UNDEFINED
	|	END                                             AS NewVATTaxation,
	|	OutOfOfficeAssets.NonCurrentAsset                     AS NonCurrentAsset,
	|	
	|	OutOfOfficeAssets.IncludedInTaExpensesWhenAcceptedForAccounting AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	OutOfOfficeAssets.ExpenseDivisionTa               AS ExpenseDivisionTa,
	|	OutOfOfficeAssets.ExpenseItemTaxAccounting                      AS ExpenseItemTaxAccounting,
	|	OutOfOfficeAssets.ExpensesDimensionTaxAccounting                   AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                       AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                     AS LocalCost,
	|	BalanceTable.VATLocal                           AS VATLocal,
	|	BalanceTable.VATManag                            AS VATManag
	|FROM
	|	TTLotReferenceChangeOfTaxableToDistributableDeductionWasNotDeclared AS BalanceTable
	|	
	|	INNER JOIN 
	|		TTNonCurrentAssets AS OutOfOfficeAssets
	|	ON 
	|		BalanceTable.DimensionOfExpenses = OutOfOfficeAssets.Object
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	NOT &DistributionForFullPeriod
	|	AND (BalanceTable.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR BalanceTable.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning))
	|
	|UNION ALL
	|
	// Distribution in proportion of the month of receipt on the 08 account when changing activities 
	// from "Non-taxable" to "Distributable"/"Taxable" in "Acceptance for accounting"
	|SELECT
	|	LotsVATForAllocation.Organization                 AS Organization,
	|	LotsVATForAllocation.Department               AS Department,
	|	LotsVATForAllocation.LineOfBusiness     AS LineOfBusiness,
	|	LotsVATForAllocation.ExpenseItem              AS ExpenseItem,
	|	LotsVATForAllocation.DimensionOfExpenses           AS DimensionOfExpenses,
	|	LotsVATForAllocation.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
	|	LotsVATForAllocation.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	LotsVATForAllocation.VATActivityType          AS VATActivityType,
	|	LotsVATForAllocation.Vendor                   AS Vendor,
	|	LotsVATForAllocation.VATActivityType          AS PartyVATTaxation,
	|	LotsVATForAllocation.VATRate                   AS VATRate,
	|	LotsVATForAllocation.DistributeVAT_             AS DistributeVAT_,
	|	LotsVATForAllocation.BasePeriod                  AS BasePeriod,
	|	LotsVATForAllocation.BasisOfAdjustment      AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	LotsVATForAllocation.NewVATTaxation     AS NewVATTaxation,
	|	LotsVATForAllocation.NonCurrentAsset           AS NonCurrentAsset,
	|	
	|	LotsVATForAllocation.IncludedInTaExpensesWhenAcceptedForAccounting   AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	LotsVATForAllocation.ExpenseDivisionTa                 AS ExpenseDivisionTa,
	|	LotsVATForAllocation.ExpenseItemTaxAccounting                        AS ExpenseItemTaxAccounting,
	|	LotsVATForAllocation.ExpensesDimensionTaxAccounting                     AS ExpensesDimensionTaxAccounting,
	|	
	|	LotsVATForAllocation.AssetTaxClass                 AS AssetTaxClass,
	|	LotsVATForAllocation.LocalCost               AS LocalCost,
	|	LotsVATForAllocation.VATLocal                     AS VATLocal,
	|	LotsVATForAllocation.VATManag                      AS VATManag
	|FROM
	|	TTLotREFERENCESOfVATOnHVACommissionedThisMonth AS LotsVATForAllocation
	|
	|UNION ALL
	|
	// Restoration of batches under special conditions of commissioning
	|SELECT
	|	LotsVATForAllocation.Organization                 AS Organization,
	|	LotsVATForAllocation.Department               AS Department,
	|	LotsVATForAllocation.LineOfBusiness     AS LineOfBusiness,
	|	LotsVATForAllocation.ExpenseItem              AS ExpenseItem,
	|	LotsVATForAllocation.DimensionOfExpenses           AS DimensionOfExpenses,
	|	LotsVATForAllocation.AssetsLiabilitiesDimension    AS AssetsLiabilitiesDimension,
	|	LotsVATForAllocation.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	LotsVATForAllocation.VATActivityType          AS VATActivityType,
	|	LotsVATForAllocation.Vendor                   AS Vendor,
	|	LotsVATForAllocation.VATActivityType          AS PartyVATTaxation,
	|	LotsVATForAllocation.VATRate                   AS VATRate,
	|	LotsVATForAllocation.DistributeVAT_             AS DistributeVAT_,
	|	LotsVATForAllocation.BasePeriod                  AS BasePeriod,
	|	LotsVATForAllocation.BasisOfAdjustment      AS BasisOfAdjustment,
	|	UNDEFINED                                        AS BusinessTransactionSetting,
	|	LotsVATForAllocation.NewVATTaxation     AS NewVATTaxation,
	|	LotsVATForAllocation.NonCurrentAsset           AS NonCurrentAsset,
	|	
	|	LotsVATForAllocation.IncludedInTaExpensesWhenAcceptedForAccounting   AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	LotsVATForAllocation.ExpenseDivisionTa                 AS ExpenseDivisionTa,
	|	LotsVATForAllocation.ExpenseItemTaxAccounting                        AS ExpenseItemTaxAccounting,
	|	LotsVATForAllocation.ExpensesDimensionTaxAccounting                     AS ExpensesDimensionTaxAccounting,
	|	
	|	LotsVATForAllocation.AssetTaxClass                 AS AssetTaxClass,
	|	-LotsVATForAllocation.LocalCost              AS LocalCost,
	|	-LotsVATForAllocation.VATLocal                    AS VATLocal,
	|	-LotsVATForAllocation.VATManag                     AS VATManag
	|FROM
	|	TTSpecialConditionsOfCommissioning AS LotsVATForAllocation
	|WHERE
	|	NOT LotsVATForAllocation.TheseAreLeftovers
	|
	|UNION ALL
	|
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|	
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	CASE BalanceTable.PartyVATTaxation
	|		WHEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|			THEN TRUE
	|		WHEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                            AS DistributeVAT_,
	|	
	|	BalanceTable.BasePeriod                       AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	UNDEFINED                                     AS BusinessTransactionSetting,
	|	
	|	CASE BalanceTable.PartyVATTaxation
	|		WHEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|			THEN UNDEFINED
	|		WHEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN UNDEFINED
	|		WHEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                            AS NewVATTaxation,
	|	CASE
	|		WHEN BalanceTable.TypeOfValueVATExpenseItems = VALUE(Enum.AssetKinds.FA)
	|			THEN ""FA""
	|		ELSE ""IA""
	|	END                                            AS NonCurrentAsset,
	|	
	|	FALSE                                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                                     AS ExpenseDivisionTa,
	|	UNDEFINED                                     AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                     AS ExpensesDimensionTaxAccounting,
	|	
	|	BalanceTable.AssetTaxClass                      AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                    AS LocalCost,
	|	BalanceTable.VATLocal                          AS VATLocal,
	|	BalanceTable.VATManag                           AS VATManag
	|FROM
	|	BalanceTable AS BalanceTable
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|	
	|WHERE
	|	NOT TRUE IN (SELECT TOP 1 TRUE FROM TTNonCurrentAssets AS T WHERE T.Object = BalanceTable.DimensionOfExpenses)
	|	AND &AllocateVATToCapitalExpenditureInReceiptMonth
	|	AND BalanceTable.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|	AND BalanceTable.TypeOfValueVATExpenseItems <> VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|	
	|UNION ALL
	|
	|SELECT
	|	BalanceTable.Organization                      AS Organization,
	|	BalanceTable.Department                    AS Department,
	|	BalanceTable.LineOfBusiness          AS LineOfBusiness,
	|	BalanceTable.ExpenseItem                   AS ExpenseItem,
	|	BalanceTable.DimensionOfExpenses                AS DimensionOfExpenses,
	|	BalanceTable.AssetsLiabilitiesDimension         AS AssetsLiabilitiesDimension,
	|	BalanceTable.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	BalanceTable.VATActivityType               AS VATActivityType,
	|	
	|	BalanceTable.Vendor                        AS Vendor,
	|	BalanceTable.PartyVATTaxation         AS PartyVATTaxation,
	|	BalanceTable.VATRate                        AS VATRate,
	|	
	|	TRUE                                           AS DistributeVAT_,
	|	
	|	ENDOFPERIOD(ISNULL(NdskPartyDistributionAdjustment.BasePeriod, BalanceTable.BasePeriod), QUARTER) AS BasePeriod,
	|	ISNULL(NdskPartyDistributionAdjustment.BasisOfAdjustment, UNDEFINED) AS BasisOfAdjustment,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATAllocation) AS BusinessTransactionSetting,
	|	
	|	UNDEFINED                                     AS NewVATTaxation,
	|
	|	CASE 
	|		WHEN BalanceTable.TypeOfValueVATExpenseItems = VALUE(Enum.AssetKinds.FA)
	|			THEN ""FA""
	|		WHEN BalanceTable.TypeOfValueVATExpenseItems = VALUE(Enum.AssetKinds.IA)
	|			THEN ""IA""
	|		ELSE ""ConstructionObject""
	|	END                                            AS NonCurrentAsset,
	|	FALSE                                             AS IncludedInTaExpensesWhenAcceptedForAccounting,
	|	UNDEFINED                                     AS ExpenseDivisionTa,
	|	UNDEFINED                                     AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                     AS ExpensesDimensionTaxAccounting,
	|
	|	BalanceTable.AssetTaxClass                      AS AssetTaxClass,
	|	
	|	BalanceTable.LocalCost                    AS LocalCost,
	|	BalanceTable.VATLocal                          AS VATLocal,
	|	BalanceTable.VATManag                           AS VATManag
	|FROM
	|	BalanceTable AS BalanceTable
	|	
	|	LEFT JOIN
	|		NdskPartyDistributionAdjustment AS NdskPartyDistributionAdjustment
	|	ON
	|		BalanceTable.DimensionOfExpenses = NdskPartyDistributionAdjustment.DimensionOfExpenses
	|		AND BalanceTable.ExpenseReceiptDocument = NdskPartyDistributionAdjustment.ExpenseReceiptDocument
	|		AND BalanceTable.Organization = NdskPartyDistributionAdjustment.Organization  
	|		AND BalanceTable.Department = NdskPartyDistributionAdjustment.Department
	|		AND BalanceTable.ExpenseItem = NdskPartyDistributionAdjustment.ExpenseItem
	|		AND BalanceTable.AssetsLiabilitiesDimension = NdskPartyDistributionAdjustment.AssetsLiabilitiesDimension
	|		AND BalanceTable.Vendor = NdskPartyDistributionAdjustment.Vendor
	|		AND BalanceTable.AssetTaxClass = NdskPartyDistributionAdjustment.AssetTaxClass
	|		AND BalanceTable.LineOfBusiness = NdskPartyDistributionAdjustment.LineOfBusiness
	|		AND BalanceTable.VATRate = NdskPartyDistributionAdjustment.VATRate
	|		AND BalanceTable.VATActivityType = NdskPartyDistributionAdjustment.VATActivityType
	|
	|WHERE
	|	NOT TRUE IN (SELECT TOP 1 TRUE FROM TTNonCurrentAssets AS T WHERE T.Object = BalanceTable.DimensionOfExpenses)
	|	AND BalanceTable.PartyVATTaxation <> VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	AND BalanceTable.OptionOfDistributionOfExpensesOfArticle = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|	AND &DistributionForFullPeriod
	|	AND (BalanceTable.TypeOfValueVATExpenseItems = VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|		OR NOT &UseSeparateFAAccountingByTaxation
	|		OR BalanceTable.PartyVATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation))
	|;
	|
	|///////////////////////////////////////////////////////////////////
	|SELECT
	|	NonCurrentAssets.Organization AS Organization,
	|	NonCurrentAssets.Object AS Object
	|FROM
	|	TTNonCurrentAssets AS NonCurrentAssets
	|;
	|
	|///////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesOfVATPresented.TaxInvoice,
	|	BalancesOfVATPresented.VATAmount
	|FROM
	|	TTVATAmountSubmittedBySF AS BalancesOfVATPresented
	|";
	
	QueryResults = Query.ExecuteBatch();
	
	Result = New Structure;
	
	Result.Insert("LotsVATForAllocation", QueryResults[0].Unload());
	Result.Insert("NonCurrentAssets",   QueryResults[1].Unload());
	Result.Insert("BalancesOfVATPresented", QueryResults[2].Unload());
	// We will destroy all the generated temporary tables.
	// If this is not done, then when calling this method from batch accounting version 2.2
	// , an error of the form "Temporary table already exists" may occur.
	
	Query.Text = "
	|DROP TTNonCurrentAssets
	|;
	|
	|DROP TTSpecialConditionsOfCommissioning
	|;
	|
	|DROP TTNonCurrentAssetsQuarter
	|;
	|
	|DROP TTLotREFERENCESOfVATOnHVACommissionedThisMonth
	|;
	|
	|DROP TTLotReferenceChangeTaxableToNonTaxableDeductionWasDeclared
	|;
	|
	|DROP TTLotReferenceChangeOfTaxableToDistributableDeductionWasNotDeclared
	|;
	|
	|DROP TTVATAmountSubmittedBySF
	|;
	|DROP TTAdjustmentOfNdskBatchBalancesByDistribution
	|;
	|DROP BalanceTable
	|;
	|DROP NdskPartyDistributionAdjustment
	|";
	
	Query.Execute();
	
	Return Result;
	
EndFunction

Function FormRegisteredRecords(Attributes, Registers, AddlParameters)
	
	TablesForRegisteredRecords = New Structure;
	TablesForRegisteredRecords.Insert("Table"+ "DocumentsRegistry", TableDocumentRegistry(Attributes));
	
	Query = New Query;
	Query.SetParameter("Ref", Attributes.Ref);
	Query.SetParameter("Organization", Attributes.Organization);
	QueryTexts = New ValueList;
	
	PerformDistribution = True;
	RegistersByString = "";
	If TypeOf(Registers) = Type("Structure") Then
		RegistersByString = CommonClientServer.StructureKeysToString(Registers)
	ElsIf TypeOf(Registers) = Type("String") Then
		RegistersByString = RegistersByString;
	EndIf;
	
	If RegistersByString = "DocumentsRegistry" Then 
		PerformDistribution = False;
	EndIf;
	
	If PerformDistribution Then
		DataForDistribution = DataForDistribution(Attributes, AddlParameters);
		AllocationResult = DistributeBatchesOfVATOnDatabase(DataForDistribution, Attributes, AddlParameters);
		
		TableVATBatchDistribution = "Table" + "LotsVATForAllocation";
		TablesForRegisteredRecords.Insert(TableVATBatchDistribution, TableVATBatchDistribution(AllocationResult, Attributes));
		TablesForRegisteredRecords.Insert("Table" + "OtherExpenses", TableOtherExpenses(AllocationResult, Attributes, TablesForRegisteredRecords[TableVATBatchDistribution]));
		
		VATAllocationLocalization.FormRegisteredRecords(TablesForRegisteredRecords, DataForDistribution, AllocationResult, Attributes, Registers);
	EndIf;
	
	For Each Table In TablesForRegisteredRecords Do
		RegisterName = Table.Key;
		If Upper(Left(RegisterName, StrLen("Table")))= "TABLE" Then
			RegisterName = Right(RegisterName, StrLen(RegisterName) - StrLen("Table"));
		EndIf;
		
		If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
			TablesForRegisteredRecords.Delete(Table.Key);
		EndIf;
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	StornoTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	For Each CrntTable In StornoTables Do 
		
		If CrntTable.Key = "VATTableOfSalesBookEntries"
			Or CrntTable.Key = "VATTableOfPurchaseBookEntry" Then 
			Continue;
		EndIf;
		
		If TablesForRegisteredRecords.Property(CrntTable.Key) Then 
			CommonClientServer.SupplementTable(CrntTable.Value, TablesForRegisteredRecords[CrntTable.Key]);
		Else 
			TablesForRegisteredRecords.Insert(CrntTable.Key, CrntTable.Value);
		EndIf;
		
	EndDo;
	
	Return TablesForRegisteredRecords;
	
EndFunction

Function DistributeBatchesOfVATOnDatabase(DataForDistribution, Attributes, AddlParameters)
	
	LotsVATForAllocation = DataForDistribution.LotsVATForAllocation;
	
	DistributionTables = New Map;
	TypesOfVATDistributionTaxation = ComplianceOfRevenueDetailsWithVATTaxationTypes();
	For Each KeyAndValue In TypesOfVATDistributionTaxation Do
		DistributionTables.Insert(KeyAndValue.Key, DistributionResultTable());
	EndDo;
	
	TypesOfActivitiesVATIsAcceptedForReimbursement = VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement();
	ActivitiesVATIsIncludedInCost = VATAccountingERP.ActivitiesVATIsIncludedInCost();
	
	MatchingDetailsOfAnalystArticles =  ComplianceOfExpenditureAnalystItemsWithVATTaxation();
	
	AllocationBase = AllocationBase(LotsVATForAllocation, Attributes, AddlParameters);
	
	For Each OtherExpensesLine In LotsVATForAllocation Do
		
		If OtherExpensesLine.DistributeVAT_ Then
			
			PeriodBase = AllocationBase.Find(OtherExpensesLine.BasePeriod, "BasePeriod");
			
			BasisOfDistributionByLine = New Map;
			For Each KeyAndValue In TypesOfVATDistributionTaxation Do
				BasisOfDistributionByLine.Insert(KeyAndValue.Key, PeriodBase[KeyAndValue.Value]);
			EndDo;
			
			VATAllocationLocalization.AdjustingBaseByRowToDistribution(BasisOfDistributionByLine, OtherExpensesLine, PeriodBase.Apply5PecentRule);
			
			Coefficients = New Array;
			For Each KeyAndValue In BasisOfDistributionByLine Do
				Coefficients.Add(KeyAndValue.Value);
			EndDo;
			
			DistributionLocalCost = Common.DistributeAmountInProportionToCoefficients(OtherExpensesLine.LocalCost, Coefficients); 
			DistributionOfVATLocal = Common.DistributeAmountInProportionToCoefficients(OtherExpensesLine.VATLocal, Coefficients);
			DistributionOfVATMan = Common.DistributeAmountInProportionToCoefficients(OtherExpensesLine.VATManag, Coefficients);
			
			IndexOf = 0;
			For Each KeyAndValue In DistributionTables Do
				
				Taxation = KeyAndValue.Key;
				Table = KeyAndValue.Value;
				
				LocalCost = ?(DistributionLocalCost <> Undefined, DistributionLocalCost[IndexOf], 0);
				VATLocal       = ?(DistributionOfVATLocal       <> Undefined, DistributionOfVATLocal[IndexOf], 0);
				VATManag        = ?(DistributionOfVATMan        <> Undefined, DistributionOfVATMan[IndexOf], 0);
				
				IndexOf = IndexOf + 1;
				If LocalCost = 0 And VATLocal = 0 And VATManag = 0 Then
					Continue;
				EndIf;
				
				NewRow = Table.Add();
				FillPropertyValues(NewRow, OtherExpensesLine, , "LocalCost, VATLocal");
				NewRow.LocalCost = LocalCost;
				NewRow.VATLocal       = VATLocal;
				NewRow.VATManag        = VATManag;
				
				If ValueIsFilled(OtherExpensesLine.NonCurrentAsset) Then
					Continue;
				EndIf;
				
				If Not PeriodBase.WriteOffVATByExpensesAndAssetsToRecordItems Or NewRow.ExpenseItem = Undefined Then
					DetailsOfAnalyticsArticle = MatchingDetailsOfAnalystArticles.Get(Taxation);
					If DetailsOfAnalyticsArticle <> Undefined Then
						ArticleDetails_ = DetailsOfAnalyticsArticle[0];
						AnalyticsDetails = DetailsOfAnalyticsArticle[1];
						NewRow.ExpenseItem_ = PeriodBase[ArticleDetails_];
						NewRow.ExpensesPostingDimension = PeriodBase[AnalyticsDetails];
						NewRow.ExpenseItemTaxAccounting = PeriodBase[ArticleDetails_];
					EndIf;
				Else
					NewRow.ExpenseItem_ = NewRow.ExpenseItem;
					NewRow.ExpensesPostingDimension = NewRow.DimensionOfExpenses;
					NewRow.ExpenseItemTaxAccounting = NewRow.ExpenseItem;
				EndIf;
				
			EndDo;
			
		Else
			
			Table = DistributionTables[OtherExpensesLine.NewVATTaxation];
			If Table = Undefined Then
				MessageText = StrTemplate(
					NStr("vi = 'Chưa xác định hệ thống thuế theo tài sản dài hạn %1.';
						|ru = 'Не определено налогообложение по внеоборотному активу %1.';
						|en = 'Taxation by fixed asset %1 is not defined.'; fa = 'Taxation by fixed asset %1 is not defined.';
						|it = 'Taxation by fixed asset %1 is not defined.';
						|pl = 'Taxation by fixed asset %1 is not defined.';
						|tr = '%1 duran varlığın vergilendirilmesi tanımlanmadı.'"), 
					OtherExpensesLine.DimensionOfExpenses);
				Raise MessageText;
			EndIf;
			
			NewRow = Table.Add();
			FillPropertyValues(NewRow, OtherExpensesLine);
			
		EndIf;
		
	EndDo;
	
	VATAllocationLocalization.CalculateRecoveryOfNDSIWriteOffForExpenses(
		DistributionTables, DataForDistribution, Attributes);
	
	VATAllocationLocalization.DistributeNdskBatchesByBaseDistribution(DistributionTables, Attributes);
	
	For Each KeyAndValue In DistributionTables Do
		Taxation = KeyAndValue.Key;
		Table = KeyAndValue.Value;
		Table.FillValues(Taxation, "CorVATActivityTypes");
		
		For Each String In Table Do
			String.FinRecordID = New UUID();
			If TypesOfActivitiesVATIsAcceptedForReimbursement.Find(String.VATActivityType) <> Undefined
				And ActivitiesVATIsIncludedInCost.Find(String.CorVATActivityTypes) <> Undefined Then
				String.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.InclusionExclusionOfVATInCost;
			ElsIf ActivitiesVATIsIncludedInCost.Find(String.VATActivityType) <> Undefined
				And TypesOfActivitiesVATIsAcceptedForReimbursement.Find(String.CorVATActivityTypes) <> Undefined Then
				String.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.InclusionExclusionOfVATInCost;
			EndIf;
		EndDo;
		
	EndDo;
	
	VATAllocationLocalization.DistributeNonCurrentAssetsExportOfCommoditiesAndServices(DistributionTables);
	
	VATAllocationLocalization.AllocateToEmptyImplementationForAcceptanceToDeduction(DistributionTables);
	
	Return DistributionTables;
	
EndFunction

Function AllocationBase(LotsVATForAllocation, Attributes, AddlParameters)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	BasePeriods.BasePeriod
	|INTO BasePeriods
	|FROM
	|	&BasePeriods AS BasePeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////
	// we select the last correction of the VAT Distribution for this period, for which there was no storno
	|SELECT
	|	BasePeriods.BasePeriod AS BasePeriod,
	|	VATAllocation.Ref AS DocumentDistributions
	|INTO SourceDistributionDocuments
	|FROM
	|	BasePeriods AS BasePeriods
	|	LEFT JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		BasePeriods.BasePeriod = ENDOFPERIOD(VATAllocation.Date, MONTH)
	|		AND VATAllocation.Organization = &Organization 
	|		AND NOT VATAllocation.Patch
	|		AND VATAllocation.Posted
	|
	|INDEX BY
	|	DocumentDistributions
	|;
	|
	|////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentCorrection.CorrectedDocument AS CorrectedDocument,
	|	DocumentCorrection.DocumentToCorrectIsReversed AS DocumentWasCancelled,
	|	DocumentCorrection.LastChainDocument AS ActualDocument
	|INTO CurrentDistributionDocuments
	|FROM
	|	InformationRegister.DocumentCorrections.SliceLast(
	|			&DateOfDistribution,
	|			CorrectedDocument IN
	|				(SELECT
	|					T.DocumentDistributions
	|				FROM
	|					SourceDistributionDocuments AS T)) AS DocumentCorrection
	|WHERE
	|	NOT (DocumentCorrection.LastChainDocument = UNDEFINED
	|				AND DocumentCorrection.DocumentToCorrectIsReversed = FALSE)
	|
	|INDEX BY
	|	CorrectedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SourceDistributionDocuments.BasePeriod AS BasePeriod,
	|	CASE
	|		WHEN NOT RelevantDocuments.CorrectedDocument IS NULL
	|			THEN RelevantDocuments.ActualDocument
	|		ELSE SourceDistributionDocuments.DocumentDistributions
	|	END AS Document,
	|	SourceDistributionDocuments.DocumentDistributions AS CorrectedDocument
	|INTO DistributionDocuments
	|FROM
	|	SourceDistributionDocuments AS SourceDistributionDocuments
	|		LEFT JOIN CurrentDistributionDocuments AS RelevantDocuments
	|		ON SourceDistributionDocuments.DocumentDistributions = RelevantDocuments.CorrectedDocument
	|WHERE
	|	ISNULL(RelevantDocuments.DocumentWasCancelled, FALSE) = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasePeriods.BasePeriod AS BasePeriod,
	|	&SelectedFields, 
	|	ISNULL(VATAllocation.Apply5PecentRule, &Apply5PecentRule) AS Apply5PecentRule,
	|	ISNULL(VATAllocation.WriteOffVATByExpensesAndAssetsToRecordItems, 
	|				&WriteOffVATByExpensesAndAssetsToRecordItems) AS WriteOffVATByExpensesAndAssetsToRecordItems
	|FROM
	|	BasePeriods AS BasePeriods
	|	LEFT JOIN
	|		DistributionDocuments AS DistributionDocuments
	|	ON
	|		BasePeriods.BasePeriod = DistributionDocuments.BasePeriod
	|		AND DistributionDocuments.BasePeriod <> &BasePeriod
	|
	|	LEFT JOIN
	|		Document.VATAllocation AS VATAllocation
	|	ON
	|		DistributionDocuments.Document = VATAllocation.Ref
	|";
	
	ArrayOfSelectedBankingDetails = New Array;

	ComplianceOfRevenueDetailsWithVATTaxationTypes = ComplianceOfRevenueDetailsWithVATTaxationTypes();
	For Each KeyAndValue In ComplianceOfRevenueDetailsWithVATTaxationTypes Do
		ArrayOfSelectedBankingDetails.Add(KeyAndValue.Value);
	EndDo;
	ComplianceOfDetailsOfArticlesWithTypesOfTaxation = ComplianceOfExpenditureAnalystItemsWithVATTaxation();
	For Each KeyAndValue In ComplianceOfDetailsOfArticlesWithTypesOfTaxation Do
		CommonClientServer.SupplementArray(ArrayOfSelectedBankingDetails, KeyAndValue.Value);
	EndDo;
	ArrayOfSelectedBankingDetails = TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfSelectedBankingDetails);
	
	ArrayOfSelectionExpressions = New Array;
	TemplateForFieldToSelect = "ISNULL(VATAllocation.%1, &%1) AS %1";
	For Each Item In ArrayOfSelectedBankingDetails Do
		ArrayOfSelectionExpressions.Add(StrTemplate(TemplateForFieldToSelect, Item))
	EndDo;
	
	TextOfSelectedFields = StrConcat(ArrayOfSelectionExpressions, "
	                                                           |,");
	Query.Text = StrReplace(Query.Text, "&SelectedFields", TextOfSelectedFields);
	
	BasePeriods = LotsVATForAllocation.Copy();
	BasePeriods.GroupBy("BasePeriod");
	Query.SetParameter("BasePeriods", BasePeriods);
	
	Query.SetParameter("CallFromEndOfMonth", AddlParameters <> Undefined And AddlParameters.Property("RoutineOperations"));
	
	For Each Attribute In Attributes Do
		Query.SetParameter(Attribute.Key, Attributes[Attribute.Key]);
	EndDo;
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Function DistributionResultTable()
	
	RecordSet = AccumulationRegisters.LotsVATForAllocation.CreateRecordSet();
	Result = RecordSet.UnloadColumns();
	
	Result.Columns.Delete("Active");
	Result.Columns.Delete("PointInTime");
	
	Result.Columns.Add("BasisOfAdjustment",  Metadata.Documents.PurchaseAdjustment.Attributes.DocumentBasis.Type);
	
	Result.Columns.Add("PartyVATTaxation",         New TypeDescription("EnumRef.VATTaxationTypes"));
	
	Result.Columns.Add("NonCurrentAsset",                     New TypeDescription("String"));
	Result.Columns.Add("IncludedInTaExpensesWhenAcceptedForAccounting", New TypeDescription("Boolean"));
	Result.Columns.Add("ExpenseDivisionTa",               New TypeDescription("CatalogRef.BusinessStructure"));
	Result.Columns.Add("ExpenseItemTaxAccounting",                      New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
	Result.Columns.Add("ExpensesDimensionTaxAccounting",                   New TypeDescription(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type, "Null"));
	
	Return Result;
	
EndFunction

Function TableVATBatchDistribution(AllocationResult, Attributes)
	
	LotsVATForAllocation = AccumulationRegisters.LotsVATForAllocation.CreateRecordSet().UnloadColumns();
	LotsVATForAllocation.Columns.Delete("Active");
	
	For Each DistributionTable_1 In AllocationResult Do
		CommonClientServer.SupplementTable(DistributionTable_1.Value, LotsVATForAllocation);
	EndDo;
	
	LotsVATForAllocation.FillValues(AccumulationRecordType.Expense, "RecordType");
	LotsVATForAllocation.FillValues(Attributes.DateOfDistribution,   "Period");
	
	Return LotsVATForAllocation;
	
EndFunction

Function TableOtherExpenses(AllocationResult, Attributes, LotsVATForAllocation)
	
	OtherExpenses = AccumulationRegisters.OtherExpenses.CreateRecordSet().UnloadColumns();
	OtherExpenses.Columns.Delete("Active");
	
	TypesOfVATTaxationNonTaxable = VATAccountingERP.TypesOfVATTaxationNonTaxable();
	For Each KeyAndValue In AllocationResult Do
		
		If TypesOfVATTaxationNonTaxable.Find(KeyAndValue.Key) <> Undefined
			Or KeyAndValue.Key = Enums.VATTaxationTypes.ExportSalesOfWorkServices Then
			OtherExpensesAddLinesInclusionInPrice(OtherExpenses, KeyAndValue.Value, Attributes);
		Else
			OtherExpensesAddLinesExclusionFromCost(OtherExpenses, KeyAndValue.Value, Attributes);
		EndIf;
		
	EndDo;
	
	QueryTextArray = New Array;
	QueryTextTTInitialOtherExpenses = 
	"SELECT
	|	OtherExpenses.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	OtherExpenses.SumMan AS AmountExcludingVATMan,
	|	OtherExpenses.SumCompl AS AmountIncludingVATCompl,
	|	OtherExpenses.SumCompl AS AmountExcludingVATCompl,
	|	OtherExpenses.PermanentDifference AS PermanentDifference,
	|	OtherExpenses.CostTD AS CostTD,
	|	OtherExpenses.BusinessOperation,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	OtherExpenses.FinRecordID AS FinRecordID,
	|	OtherExpenses.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|INTO TTInitialOtherExpenses
	|FROM
	|	&OtherExpenses AS OtherExpenses
	|";
	QueryTextArray.Add(QueryTextTTInitialOtherExpenses);
	QueryTextArray.Add(AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("ReversingEntry"));
	QueryTextArray.Add(AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("ReversingEntry"));
	
	Query = New Query(StrConcat(QueryTextArray, Common.QueryBatchSeparator()));
	Query.SetParameter("OtherExpenses",	OtherExpenses);
	Query.SetParameter("Period", 		Attributes.Period);
	Query.SetParameter("Organization",	Attributes.Organization);
	Query.SetParameter("Ref",			Attributes.Ref);

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	OtherExpenses = Query.Execute().Unload(); 
	
	
	Return OtherExpenses;
	
EndFunction

Procedure OtherExpensesAddLinesInclusionInPrice(OtherExpenses, SourceTable1, Attributes)
	
	UseVNA2_4 = False;
	UseVNA2_4 = NonCurrentAssets.VNAManagementIsUsed_2_4(Attributes.Period);
	TypesOfVATTaxationNonTaxable = VATAccountingERP.TypesOfVATTaxationNonTaxable();
	For Each String In SourceTable1 Do
		
		If Not IsBlankString(String.NonCurrentAsset) 
			 And Not String.IncludedInTaExpensesWhenAcceptedForAccounting
			 And Not UseVNA2_4 Then 
			Continue;
		EndIf;
		
		If TypesOfVATTaxationNonTaxable.Find(String.PartyVATTaxation) <> Undefined
			Or String.CorVATActivityTypes = Enums.VATTaxationTypes.ExportSalesOfWorkServices Then
				// Already in expenses
				Continue;
		EndIf;
		
		If Not IsBlankString(String.NonCurrentAsset) And String.IncludedInTaExpensesWhenAcceptedForAccounting Then
			Department       = String.ExpenseDivisionTa;
			ExpenseItem		= String.ExpenseItemTaxAccounting;
			DimensionOfExpenses	= String.ExpensesDimensionTaxAccounting;
		ElsIf ValueIsFilled(String.ExpenseItem_) Then
			Department		= String.Department;
			ExpenseItem		= String.ExpenseItem_;
			DimensionOfExpenses	= String.ExpensesPostingDimension;
		Else
			Department		= String.Department;
			ExpenseItem		= String.ExpenseItem;
			DimensionOfExpenses	= String.DimensionOfExpenses;
		EndIf;
		
		If Not ValueIsFilled(ExpenseItem) 
				Or TypeOf(ExpenseItem) <> Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
			// This is not an expense
			Continue;
		EndIf;
		
		NewRow = OtherExpenses.Add();
		NewRow.Period					= Attributes.DateOfDistribution;
		NewRow.Organization				= Attributes.Organization;
		NewRow.BusinessOperation	= Enums.BusinessTransactions.VATAllocation;
		NewRow.LineOfBusiness = String.LineOfBusiness;
		NewRow.Department			= Department;
		NewRow.ExpenseItem			= ExpenseItem;
		NewRow.DimensionOfExpenses		= DimensionOfExpenses;		
		
		NewRow.FinRecordID  = String.FinRecordID;
		NewRow.BusinessTransactionSetting = String.BusinessTransactionSetting;
		
		If Not IsBlankString(String.NonCurrentAsset) And String.IncludedInTaExpensesWhenAcceptedForAccounting Then
			NewRow.CostTD = -String.VATLocal;
		Else
			NewRow.SumCompl = String.VATLocal;
		EndIf;
		NewRow.SumMan = String.VATManag;
		
	EndDo;
	
EndProcedure

Procedure OtherExpensesAddLinesExclusionFromCost(OtherExpenses, SourceTable1, Attributes)
	
	UseVNA2_4 = False;
	UseVNA2_4 = NonCurrentAssets.VNAManagementIsUsed_2_4(Attributes.Period);
	TypesOfVATTaxationNonTaxable = VATAccountingERP.TypesOfVATTaxationNonTaxable();
	
	For Each String In SourceTable1 Do
		
		If Not IsBlankString(String.NonCurrentAsset) And Not UseVNA2_4 Then 
			Continue;
		EndIf;
		
		If Not ValueIsFilled(String.ExpenseItem) Then
			// This is not an expense
			Continue;
		EndIf;
		
		If TypesOfVATTaxationNonTaxable.Find(String.PartyVATTaxation) = Undefined Then
			Continue;
		EndIf;
		
		NewRow = OtherExpenses.Add();
		NewRow.Period					= Attributes.DateOfDistribution;
		NewRow.Organization				= Attributes.Organization;
		NewRow.Department			= String.Department;
		NewRow.LineOfBusiness = String.LineOfBusiness;
		NewRow.BusinessOperation	= Enums.BusinessTransactions.VATAllocation;
		NewRow.ExpenseItem			= String.ExpenseItem;
		NewRow.DimensionOfExpenses		= String.DimensionOfExpenses;
		
		NewRow.FinRecordID  = String.FinRecordID;
		NewRow.BusinessTransactionSetting = String.BusinessTransactionSetting;
		
		NewRow.SumCompl = -String.VATLocal;
		NewRow.SumMan = -String.VATManag;
		
	EndDo;
	
EndProcedure

Function TableDocumentRegistry(Attributes)
	
	Query = New Query;
	Query.Text = QueryTextDocumentsRegistry();
	
	Query.SetParameter("MetadataIdentifier", Attributes.MetadataIdentifier);
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.VATAllocation);
	Query.SetParameter("Ref", Attributes.Ref);
	
	Table = Query.Execute().Unload();
	If Table.Count() > 0 Then
		
		Table.FillValues(ObjectsPrefixesClientServer.NumberForPrinting(Table[0].SourceDocumentNumber),
			"SourceDocumentNumber");
		
	EndIf;
	
	Return Table;
	
EndFunction

Function QueryTextDocumentsRegistry()
	
	QueryText = 
	"SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	UNDEFINED AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Date AS SourceDocumentDate,
	|	DocumentData.Number AS SourceDocumentNumber,
	|	0 AS Sum,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.Patch           AS ReverseTransactionCorrection,
	|	DocumentData.ReversedDocument  AS ReversedDocument,
	|	DocumentData.CorrectedDocument  AS CorrectedDocument,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.VATAllocation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region InitializationAndFilling

// Fill out the rules for deducting VAT.
// 
// Parameters:
//  Organization - CatalogRef.Companies
// 
// Returns:
// 	Structure
//  
Function FillInRulesForDebitingVAT(Organization = Undefined) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED TOP 1
	|	&Attributes
	|FROM
	|	Document.VATAllocation AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND (CASE
	|		WHEN &Organization = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TRUE
	|		ELSE DocumentData.Organization = &Organization
	|	END)
	|
	|ORDER BY
	|	DocumentData.Date DESC
	|";
	
	Query.SetParameter("Organization",?(Organization = Undefined,Catalogs.Companies.EmptyRef(),Organization));
	
	FieldList = New Array;
	FieldList.Add("WriteOffVATByExpensesAndAssetsToRecordItems");
	ComplianceOfArticleDetails = ComplianceOfExpenditureAnalystItemsWithVATTaxation();
	For Each KeyAndValue In ComplianceOfArticleDetails Do
		CommonClientServer.SupplementArray(FieldList, KeyAndValue.Value);
	EndDo;
	SelectionFields1 = StrConcat(FieldList, ",
	                                       |");
	                                       
	Query.Text = StrReplace(Query.Text, "&Attributes", SelectionFields1);
	
	QueryResult = Query.Execute();
	RulesForDebiting = New Structure();
	For Each Column In QueryResult.Columns Do
		RulesForDebiting.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(RulesForDebiting,Selection);
	Else
		RulesForDebiting.WriteOffVATByExpensesAndAssetsToRecordItems = 1;
	EndIf;
	
	Return RulesForDebiting;
	
EndFunction

// Get the VAT distribution base.
// 
// Parameters:
//  Date - Date - Date
//  BeginOfPeriod - Date- Beginning of the period
//  Organization -CatalogRef.Companies - Organization
//  AdditionalRevenueGenerationParameters - Undefined - Additional parameters for receiving revenue
// 
// Returns:
//  Structure - Get the VAT Distribution Base:
//  * UTIIRevenue - Number
//  * VATRevenue - Number
//  * VATRevenue0 - Number
//  * VATRevenue0SpaceActivity -  Number
//  * Revenue0VATNonCommodityGoods - Number
//  * Revenue0VATCommoditiesServices - Number
//  * VATRevenueManufacturedProductsWithLongProductionCycle - Number
//  * RevenueVATExempt - Number
//  * RevenueFromSaleOfWorksServicesOutsideTerritoryOfRF - Number
//  * DocumentsExport - ValueTable - shipment documents with the amount of revenue and its adjustments:
//    ** Document - DocumentRef - the shipment document.
//    ** RevenueAmount - Number - the amount of revenue.
//    ** RevenueAdjustment - Number - the amount of revenue adjustment.
//
Function GetVATDistributionBase(Date, BeginOfPeriod, Organization, AdditionalRevenueGenerationParameters = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RevenueData = New Structure;
	RevenueData.Insert("RevenueFromVATTaxation");
	RevenueData.Insert("DocumentsExport");
	VATAllocationLocalization.GetRevenueData(RevenueData, Date, BeginOfPeriod, Organization, AdditionalRevenueGenerationParameters);
	If RevenueData.RevenueFromVATTaxation = Undefined Then
		
		VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		                   "VATAccountingSettings", Organization, Date);
		
		If VATAccountingSettings = Undefined Then
			VATBase = Enums.KindsOfVATBase.CurrentQuarterRevenue;
		Else
			VATBase = VATAccountingSettings.VATBase;
		EndIf;
		
		If VATBase = Enums.KindsOfVATBase.LastYearRevenue Then
			PeriodBeginning = BegOfYear(BegOfYear(Date) - 1);
			PeriodEnd = EndOfYear(BegOfYear(Date) - 1);
		ElsIf VATBase = Enums.KindsOfVATBase.CurrentYearRevenue Then
			PeriodBeginning = BegOfYear(Date);
			PeriodEnd = EndOfMonth(Date);
		ElsIf VATBase = Enums.KindsOfVATBase.CurrentQuarterRevenue Then
			PeriodBeginning = BegOfQuarter(Date);
			PeriodEnd = EndOfMonth(Date);
		ElsIf VATBase = Enums.KindsOfVATBase.CurrentMonthRevenue Then
			PeriodBeginning = BegOfMonth(Date);
			PeriodEnd = EndOfMonth(Date);
		Else
			Raise StrTemplate(NStr("vi = 'Chưa xác định kỳ nhận cơ sở thuế GTGT';
									|ru = 'Не определен период получения базы НДС';
									|en = 'Period of getting VAT base is not defined.'; fa = 'Period of getting VAT base is not defined.';
									|it = 'Non è stato definito il periodo di imponibile IVA';
									|pl = 'Nie określono okresu otrzymania podstawy VAT';
									|tr = 'KDV matrahının alınacağı dönem belirlenmedi'"));
		EndIf;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	NestedQuery.VATTaxation AS VATTaxation,
		|	SUM(NestedQuery.Revenue)     AS Revenue
		|FROM
		|	(SELECT
		|		CASE 
		|			WHEN RevenueAndCOGS.VATTaxation IN (&TypesOfTaxationExport)
		|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|			ELSE RevenueAndCOGS.VATTaxation 
		|		END AS VATTaxation,
		|		RevenueAndCOGS.RevenueAmountExclVATLocal   AS Revenue
		|	FROM
		|		AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
		|	WHERE
		|		RevenueAndCOGS.Period BETWEEN &PeriodBeginning AND &PeriodEnd
		|		AND RevenueAndCOGS.AccountingDimensionByPartners.Organization = &Organization
		|		AND RevenueAndCOGS.InventoryType IN (&InventoryTypeOwn)
		|
		|	UNION ALL
		|
		|	SELECT
		|		CASE 
		|			WHEN RevenueServicesAndAssets.VATTaxation IN (&TypesOfTaxationExport)
		|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|			ELSE RevenueServicesAndAssets.VATTaxation 
		|		END AS VATTaxation,
		|		RevenueServicesAndAssets.RevenueExcludingVATLocal  AS Revenue
		|	FROM
		|		AccumulationRegister.RevenueServicesAndAssets AS RevenueServicesAndAssets
		|	WHERE
		|		RevenueServicesAndAssets.Period BETWEEN &PeriodBeginning AND &PeriodEnd
		|		AND RevenueServicesAndAssets.Organization = &Organization) NestedQuery
		|
		|GROUP BY
		|	NestedQuery.VATTaxation
		|;
		|
		|SELECT
		|	NestedQuery.Document             AS Document,
		|	SUM(NestedQuery.Revenue)       AS RevenueAmount,
		|	SUM(NestedQuery.RevenueAdjustment) AS RevenueAdjustment
		|FROM
		|	(SELECT
		|		RevenueAndCOGS.Recorder AS Document,
		|		CASE
		|			WHEN NOT RevenueAndCOGS.Recorder REFS Document.SaleAdjustment
		|				THEN RevenueAndCOGS.RevenueAmountExclVATLocal
		|			ELSE 0
		|		END AS Revenue,
		|		CASE
		|			WHEN RevenueAndCOGS.Recorder REFS Document.SaleAdjustment
		|				THEN RevenueAndCOGS.RevenueAmountExclVATLocal
		|			ELSE 0
		|		END AS RevenueAdjustment
		|	FROM
		|		AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
		|	WHERE
		|		RevenueAndCOGS.Period BETWEEN &PeriodBeginning AND &PeriodEnd
		|		AND RevenueAndCOGS.AccountingDimensionByPartners.Organization = &Organization
		|		AND RevenueAndCOGS.InventoryType IN (&InventoryTypeOwn)
		|		AND RevenueAndCOGS.VATTaxation IN (&TypesOfTaxationExport)
		|
		|	UNION ALL
		|
		|	SELECT
		|		RevenueServicesAndAssets.Recorder AS Document,
		|		CASE
		|			WHEN NOT RevenueServicesAndAssets.Recorder REFS Document.SaleAdjustment
		|				THEN RevenueServicesAndAssets.RevenueExcludingVATLocal
		|			ELSE 0
		|		END AS Revenue,
		|		CASE
		|			WHEN RevenueServicesAndAssets.Recorder REFS Document.SaleAdjustment
		|				THEN RevenueServicesAndAssets.RevenueExcludingVATLocal
		|			ELSE 0
		|		END AS RevenueAdjustment
		|	FROM
		|		AccumulationRegister.RevenueServicesAndAssets AS RevenueServicesAndAssets
		|	WHERE
		|		RevenueServicesAndAssets.Period BETWEEN &PeriodBeginning AND &PeriodEnd
		|		AND RevenueServicesAndAssets.Organization = &Organization
		|		AND RevenueServicesAndAssets.VATTaxation IN (&TypesOfTaxationExport)) NestedQuery
		|GROUP BY
		|	NestedQuery.Document
		|";
		Query.SetParameter("PeriodBeginning",          PeriodBeginning);
		Query.SetParameter("PeriodEnd",       PeriodEnd);
		Query.SetParameter("Organization",           Organization);
		Query.SetParameter("InventoryTypeOwn", VATAccountingERPInternal.InventoryTypesOwn());
		Query.SetParameter("TypesOfTaxationExport", VATAccountingERPInternal.TaxationOfVATSalesForExport());
		Result = Query.ExecuteBatch();
		
		RevenueData.RevenueFromVATTaxation = Result[0].Unload();
		RevenueData.DocumentsExport             = Result[1].Unload();
	EndIf;
	
	Result = New Structure;
	Attributes = ComplianceOfRevenueDetailsWithVATTaxationTypes();
	For Each KeyAndValue In Attributes Do
		RevenueLine = RevenueData.RevenueFromVATTaxation.Find(KeyAndValue.Key, "VATTaxation");
		Revenue = ?(RevenueLine <> Undefined, RevenueLine.Revenue, 0);
		// one revenue Attribute may correspond to several taxation VAT
		If Result.Property(KeyAndValue.Value) Then
			Result[KeyAndValue.Value] = Result[KeyAndValue.Value] + Revenue;
		Else
			Result.Insert(KeyAndValue.Value, Revenue);
		EndIf;
	EndDo;
	Result.Insert("DocumentsExport", RevenueData.DocumentsExport);
	
	Return Result;
	
EndFunction

// Fills in the distribution database
// 
// Parameters:
// 	ObjectOrForm - DocumentObject, ClientApplicationForm -
// 	AllocationBase - Structure -
Procedure FillInDistributionDatabase(ObjectOrForm, AllocationBase) Export
	
	If AllocationBase = Undefined Then
		Return;
	EndIf;
	
	For Each KeyAndValue In AllocationBase Do
		
		If TypeOf(KeyAndValue.Value) = Type("ValueTable") Then
			ObjectOrForm[KeyAndValue.Key].Load(KeyAndValue.Value);
		Else
			ObjectOrForm[KeyAndValue.Key] = KeyAndValue.Value;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetStartOfPeriod(BeginOfPeriod, Date, Organization, CorrectionStructure) Export
	
	If CorrectionStructure.Patch
		And ValueIsFilled(BeginOfPeriod) Then 
		Return;
	EndIf;
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"VATAccountingSettings",
		Organization,
		Date);
	
	If AccountingPolicyParameters = Undefined Then
		FrequencyOfVATAllocation = Enums.Periodicity.Quarter;
	Else
		FrequencyOfVATAllocation = AccountingPolicyParameters.FrequencyOfVATAllocation;
	EndIf;
	
	If FrequencyOfVATAllocation = Enums.Periodicity.Quarter Then
		BeginOfPeriod = BegOfQuarter(Date);
	ElsIf FrequencyOfVATAllocation = Enums.Periodicity.Month Then
		BeginOfPeriod = BegOfMonth(Date);
	Else
		Raise StrTemplate(NStr("vi = 'Không hỗ trợ định kỳ phân bổ thuế GTGT ""%1"".';
								|ru = 'Периодичность распределения НДС ""%1"" не поддерживается.';
								|en = 'Frequency of VAT allocation ""%1"" is not provided.'; fa = 'Frequency of VAT allocation ""%1"" is not provided.';
								|it = 'La periodicità di ripartizione IVA ""%1"" non è supportata.';
								|pl = 'Okresowość przydziału VAT ""%1"" nie jest obsługiwana.';
								|tr = 'KDV dağıtım sıklığı ""%1"" desteklenmiyor.'"), String(FrequencyOfVATAllocation));
	EndIf;
	
	VATAllocationLocalization.SetStartOfPeriod(BeginOfPeriod, Date, Organization);
			
EndProcedure

#EndRegion

#Region InfobaseUpdate

// The ut 11.4.2 update handler
// fills in the "beginning of the period"field.
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query("
	|SELECT
	|	VATAllocation.Ref AS Ref
	|FROM
	|	Document.VATAllocation AS VATAllocation
	|WHERE
	|	VATAllocation.BeginOfPeriod = DATETIME(1, 1, 1)");
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.VATAllocation";
	MetadataOfDocument = Metadata.FindByFullName(FullObjectName);
	
	TempTablesManager = New TempTablesManager;
	Result = InfobaseUpdate.CreateTemporaryTableOfRefsToProcess(Parameters.Queue, FullObjectName, TempTablesManager);
	
	If Not Result.HasDataToProcess Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	If Not Result.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf; 
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	QueryText = "
	|SELECT DISTINCT
	|	VATAllocation.Ref AS Ref,
	|	VATAllocation.DataVersion AS DataVersion,
	|	VATAllocation.Date AS Date
	|FROM
	|	&TTDocumentsToProcess AS ToProcessing
	|		INNER JOIN Document.VATAllocation AS VATAllocation
	|		ON VATAllocation.Ref = ToProcessing.Ref
	|";
	Query.Text = StrReplace(QueryText, "&TTDocumentsToProcess", Result.TempTableName);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
				
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			If Month(Selection.Date)%3 = 0 Then // this is the last month of the quarter
				DocumentObject.BeginOfPeriod = BegOfQuarter(Selection.Date);
			Else
				DocumentObject.BeginOfPeriod = BegOfMonth(Selection.Date);
			EndIf;
			
			InfobaseUpdate.WriteObject(DocumentObject);
			CommitTransaction();
		Except
			RollbackTransaction();
			MessageText = NStr("vi = 'Không thể xử lý chứng từ: %Ref% do: %Cause%';
								|ru = 'Не удалось обработать документ: %Ref% по причине: %Cause%';
								|en = 'Cannot process the document: %Ref%. Reason: %Cause%'; fa = 'Cannot process the document: %Ref%. Reason: %Cause%';
								|it = 'Non è stato possibile elaborare il documento: %Ref% a causa di: %Cause%';
								|pl = 'Nie można przetworzyć dokumentu: %Ref% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle %Ref% belgesi işlenemedi'");
			MessageText = StrReplace(MessageText, "%Ref%", Selection.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				MetadataOfDocument,
				Selection.Ref,
				MessageText);
			Continue;
		EndTry;
	EndDo;
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
