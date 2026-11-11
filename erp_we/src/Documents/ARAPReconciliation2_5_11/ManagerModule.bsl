#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the "Reconciliation of settlements" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	Undefined - LongDesc
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ARAPReconciliation2_5_11) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ARAPReconciliation2_5_11.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ARAPReconciliation2_5_11);
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
	
	Reports.FinancialInstrumentsARAPCard.AddReportCommand(ReportsCommands);
	ARAPAccountingServer.StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands);
	ARAPAccountingServer.StatementOfSettlementsBetweenOrganizations_AddReportCommand(ReportsCommands);
	
EndProcedure

// Fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	ParametersStructure - Structure - Structure of filling parameters:
//		* DrillDownByOrders - Boolean - Indicates decryption by orders.
//		* DrillDownByPartners - Boolean - Indicates decryption by partners.
//		* DrillDownByContracts - Boolean - flag for decryption under Contracts.
//		* Partner - CatalogRef.Partners - partner of the document.
//		* Contract - CatalogRef.CounterpartyContracts - A contract document.
//	ArrayOfAllProps - Array of String - Array of all the names of banking details that depend on the business operation.
//	ArrayOfOperationDetails - Array of String - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(ParametersStructure, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("SummaryRecords.PaymentType_");
	ArrayOfAllProps.Add("SummaryRecords.Contract");
	
	ArrayOfOperationDetails = New Array;
	If ParametersStructure.ShowCalculationType Then
		ArrayOfOperationDetails.Add("SummaryRecords.PaymentType_");
	EndIf;
	If ParametersStructure.ShowContract Then
		ArrayOfOperationDetails.Add("SummaryRecords.Contract");
	EndIf;
	
EndProcedure

// Specifies the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef.ARAPReconciliation2_5_11 - link to the document.
//
// Returns:
//	Undefined, QueryResultSelection - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization,
	|	DocumentData.Counterparty,
	|	DocumentData.BeginOfPeriod,
	|	DocumentData.EndOfPeriod,
	|	MAX(ARAPReconciliationOfFinalRecords.PaymentType_) AS PaymentType_,
	|	COUNT(DISTINCT ARAPReconciliationOfFinalRecords.PaymentType_) AS TotalTypesOfCalculations
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS DocumentData
	|		LEFT JOIN Document.ARAPReconciliation2_5_11.SummaryRecords AS ARAPReconciliationOfFinalRecords
	|		ON ARAPReconciliationOfFinalRecords.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|GROUP BY
	|	DocumentData.Organization,
	|	DocumentData.Counterparty,
	|	DocumentData.BeginOfPeriod,
	|	DocumentData.EndOfPeriod
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	Else
		Return Undefined;
	EndIf;

EndFunction

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array of DocumentRef.ARAPReconciliation2_5_11- Array of links to documents to check.
//	NewStatus - String - Name of the new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfARAPReconciliation2_5_11[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string.
//	NewStatus - EnumRef - new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the document "Sparklecounts"
	
EndFunction

// Returns the key of the Object to save to the storage of General user settings
// 
// Returns:
// 	String - LongDesc
Function UserSettingsObjectKey() Export
	
	Return "Document.ARAPReconciliation2_5_11";
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND (ValueAllowed(Counterparty ONLY Catalog.Companies)
	|		OR ValueAllowed(Counterparty.Partner) 
	|			AND ForAllRows(ValueAllowed(SummaryRecords.Partner, EmptyRef AS TRUE, Null AS TRUE))
	|	)";

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

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Act of reconciliation of mutual settlements
	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "PrintManagementTMClient.PrintingReconciliationReport";
	PrintCommand.Id = "APARAccountsReconciliationStatement";
	PrintCommand.Presentation = NStr("vi = 'Biên bản đối chiếu công nợ';
									|ru = 'Акт сверки взаимных расчетов';
									|en = 'AR/AP reconciliation statement'; fa = 'صورت تطبیق دریافتنی/پرداختنی';
									|it = 'Акт сверки взаимных расчетов';
									|pl = 'Protokół uzgadniania wzajemnych rozliczeń';
									|tr = 'Mutabakat raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

// Create printed forms of objects
//
// Parameters:
//   ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//   PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//   PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//   PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//   OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "APARAccountsReconciliationStatement") Then
		
		PrintingDocuments = PrintingDocuments(ObjectsArray);
		
		PrintTemplate_ = New SpreadsheetDocument;
		If PrintingDocuments.Count() > 0 Then
			PrintTemplate_ = GeneratePrintedFormOfReconciliationReport(PrintingDocuments, PrintObjects);
		EndIf;
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
			"APARAccountsReconciliationStatement",
			NStr("vi = 'Biên bản đối chiếu công nợ';
				|ru = 'Акт сверки взаимных расчетов';
				|en = 'AR/AP reconciliation statement'; fa = 'صورت تطبیق دریافتنی/پرداختنی';
				|it = 'Акт сверки взаимных расчетов';
				|pl = 'Protokół uzgadniania wzajemnych rozliczeń';
				|tr = 'Mutabakat raporu'"),
			PrintTemplate_);
			
		PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, PrintingDocuments, PrintFormsCollection);
		
	EndIf;
	
EndProcedure

// To form a printed form of the reconciliation report of mutual settlements
//
// Parameters:
//   ObjectsArray  - Array of DocumentRef.ARAPReconciliation2_5_11 - Array of links to objects that need to be printed.
//   PrintObjects - ValueList -
//   ForDebugging - Boolean, Structure -
//
// Returns:
//  SpreadsheetDocument - Generate A Printed Form Of Reconciliation Report
Function GeneratePrintedFormOfReconciliationReport(ObjectsArray, PrintObjects, ForDebugging = Undefined) Export

	SetPrivilegedMode(True);
	PrintSettings = Common.CommonSettingsStorageLoad(
							UserSettingsObjectKey(),
							"PrintSettings");
	If PrintSettings = Undefined Then
		PrintSettings = DefaultPrintSettings();
	EndIf;
	If TypeOf(ForDebugging) = Type("Structure") Then
		PrintSettings.Insert("ForDebugging", ForDebugging);
	EndIf;
	
	RequestDataForPrinting = RequestDataForPrinting(ObjectsArray, PrintSettings);
	QueryResult = RequestDataForPrinting.Execute();
	TotalResultsForGroupingItem = RequestDataForPrinting.TempTablesManager.Tables["TTTotalResultsForGroupingItem"].GetData().Unload();
	TotalResultsForGroupingItem.GroupBy("DocumentRef,GroupingObject,ComplCurrency,ReconciliationCurrency,PaymentType_,ReconciliationUnderContracts",
		"OpeningBalanceDr,OpeningBalanceCr,TurnoverDr,TurnoverCr,ClosingBalanceDr,ClosingBalanceCr,"
		+"OpeningBalanceDrCounterparty,OpeningBalanceCrCounterparty,TurnoverDrCounterparty,TurnoverCrCounterparty,ClosingBalanceDrCounterparty,ClosingBalanceCrCounterparty,"
		+"InitialBalanceOfDebt,InitialBalanceAdvance,FinalBalanceOfDebt,FinalBalanceAdvance,"
		+"InitialBalanceDebtCounterparty,InitialBalanceAdvanceCounterparty,FinalBalanceDebtCounterparty,FinalBalanceAdvanceCounterparty");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	FirstDocument = True;
	ReconciliationData = QueryResult.Unload(QueryResultIteration.ByGroups);
	For Each DocumentData In ReconciliationData.Rows Do
		
		Template = PrintManagement.PrintFormTemplate("Document.ARAPReconciliation2_5_11.PF_MXL_APARAccountsReconciliationStatement"); // SpreadsheetDocument - 
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		#Region DocumentHeader
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, DocumentData.DocumentRef);
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(DocumentData, NStr("vi = 'Biên bản đối chiếu công nợ';
																					|ru = 'Акт сверки взаимных расчетов';
																					|en = 'AR/AP reconciliation statement'; fa = 'صورت تطبیق دریافتنی/پرداختنی';
																					|it = 'Акт сверки взаимных расчетов';
																					|pl = 'Protokół uzgadniania wzajemnych rozliczeń';
																					|tr = 'Mutabakat raporu'", Common.DefaultLanguageCode()));
		
		ThereAreTurnoverBalancesForPeriod = DocumentData.ThereAreRevolutions Or DocumentData.OpeningBalanceDr <> 0 Or DocumentData.OpeningBalanceCr <> 0
			Or DocumentData.ClosingBalanceDr <> 0 Or DocumentData.ClosingBalanceCr <> 0;
		
		If DocumentData.BeginOfPeriod = '00010101' Then
			
			PeriodPresentation = StrTemplate(NStr("vi = 'theo trạng thái tại %1';
													|ru = 'по состоянию на %1';
													|en = 'as of %1'; fa = 'as of %1';
													|it = 'по состоянию на %1';
													|pl = 'według stanu na %1';
													|tr = '%1 tarihi itibari ile'", Common.DefaultLanguageCode()), Format(DocumentData.EndOfPeriod, "DLF=DD"),);
			
			PresentationOfTheSettlementPeriod = StrTemplate(NStr("vi = 'Theo trạng thái tại %1';
																|ru = 'По состоянию на %1';
																|en = 'As of %1'; fa = 'As of %1';
																|it = 'По состоянию на %1';
																|pl = 'Według stanu na %1';
																|tr = '%1 tarihi itibari ile'", Common.DefaultLanguageCode()), Format(DocumentData.EndOfPeriod, "DLF=DD"),);
			
		Else
			
			PeriodPresentation = PeriodPresentation(DocumentData.BeginOfPeriod, EndOfDay(DocumentData.EndOfPeriod));

			FirstCharacterPresentationOfPeriod = Left(PeriodPresentation, 1);
			If  CharCode(FirstCharacterPresentationOfPeriod) >= 48
				And CharCode(FirstCharacterPresentationOfPeriod) <= 57 Then
				PeriodPresentation = StrTemplate(NStr("vi = 'trong kỳ: %1';
														|ru = 'за период: %1';
														|en = 'for the period: %1'; fa = 'for the period: %1';
														|it = 'за период: %1';
														|pl = 'za okres: %1';
														|tr = 'dönem: %1'", Common.DefaultLanguageCode()), PeriodPresentation);
				
			Else
				PeriodPresentation = StrTemplate(NStr("vi = 'cho %1';
														|ru = 'за %1';
														|en = 'for %1'; fa = 'for %1';
														|it = 'за %1';
														|pl = 'za %1';
														|tr = '%1 için'", Common.DefaultLanguageCode()), PeriodPresentation);
				
			EndIf;
			
			SettlementPeriodTemplate = NStr("vi = 'Trong kỳ từ %1 đến %2, đã thực hiện các phép tính sau';
											|ru = 'В период с %1 по %2 были осуществлены следующие расчеты';
											|en = 'In the period from %1 to %2 the following settlements were made'; fa = 'In the period from %1 to %2 the following settlements were made';
											|it = 'В период с %1 по %2 были осуществлены следующие расчеты';
											|pl = 'W okresie od %1 do %2 następujących wykonano obliczenia';
											|tr = 'Dönem %1 ila %2''de aşağıdaki hesaplamalar yapılmıştır'", Common.DefaultLanguageCode())+":";
			If Not ThereAreTurnoverBalancesForPeriod Then
				SettlementPeriodTemplate = NStr("vi = 'Trong kỳ từ %1 đến %2, không có hoạt động thanh toán nào được thực hiện.';
												|ru = 'В период с %1 по %2 операции по расчетам не производились.';
												|en = 'In the period from %1 to %2 no settlement operations were performed.'; fa = 'In the period from %1 to %2 no settlement operations were performed.';
												|it = 'В период с %1 по %2 операции по расчетам не производились.';
												|pl = 'W okresie od %1 do %2 obliczenia nie były dokonywane.';
												|tr = 'Dönem %1 ila %2''de herhangi bir takas işlemi gerçekleşmemiştir.'", Common.DefaultLanguageCode());
			EndIf;
			
			PresentationOfTheSettlementPeriod = StrTemplate(
				SettlementPeriodTemplate,
				Format(DocumentData.BeginOfPeriod, "DLF=DD"),
				Format(DocumentData.EndOfPeriod, "DLF=DD"),);
			
		EndIf;

		CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(DocumentData.Organization, DocumentData.Date);
		RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(CompanyInformation, 
									"FullDescr");
		CounterpartyInformation_  = PrintFormGeneration.InformationAboutLegalEntity(DocumentData.Counterparty,  DocumentData.Date);
		CounterpartyName_ = PrintFormGeneration.OrganizationDescription(CounterpartyInformation_, 
								  "FullDescr");
		
		StructureOfParticipantsPresentations = New Structure;
		StructureOfParticipantsPresentations.Insert("RepresentationOfTheOrganization", RepresentationOfTheOrganization);
		StructureOfParticipantsPresentations.Insert("CounterpartyName_", CounterpartyName_);
		
		TemplateArea.Parameters.Fill(DocumentData);
		TemplateArea.Parameters.Fill(StructureOfParticipantsPresentations);
		TemplateArea.Parameters.TemplateTitleText         = TitleText;
		TemplateArea.Parameters.FullNameOfCounterpartyExecutive   = TrimAll(DocumentData.FullNameOfCounterpartyExecutive);
		TemplateArea.Parameters.PeriodPresentation         = PeriodPresentation;
		TemplateArea.Parameters.PresentationOfTheSettlementPeriod = PresentationOfTheSettlementPeriod;
		
		SpreadsheetDocument.Put(TemplateArea);
		#EndRegion
		
		#Region DetailedRecords
		DocumentData.Rows.Sort("PresentationTypeOfCalculations");
		NumberType = TMCommonUse.MoneyFieldTypeDescription();
		TotalDebt_ = New ValueTable;
		TotalDebt_.Columns.Add("Currency");
		TotalDebt_.Columns.Add("SumDr", NumberType);
		TotalDebt_.Columns.Add("SumCr", NumberType);
		
		PrintSettings.Insert("PresentationsOfParticipants", StructureOfParticipantsPresentations);
		
		#Region OutputParameters
		DataFromOutput = New Structure();
		DataFromOutput.Insert("DocumentData", DocumentData);
		DataFromOutput.Insert("Template", Template);
		DataFromOutput.Insert("TotalDebt_", TotalDebt_);
		DataFromOutput.Insert("PrintSettings", PrintSettings);
		#EndRegion
		For Each DataByTypeOfCalculations In DocumentData.Rows Do
			DataByTypeOfCalculations.Rows.Sort("DimensionObjectPresentation");
			For Each DataForGroupingItem In DataByTypeOfCalculations.Rows Do
				Filter = New Structure("DocumentRef,PaymentType_,ReconciliationCurrency,GroupingObject");
				FillPropertyValues(Filter, DataForGroupingItem);
				FoundResults = TotalResultsForGroupingItem.FindRows(Filter);
				If FoundResults.Count() > 0 Then
					FillPropertyValues(DataForGroupingItem, FoundResults[0]);
				EndIf;
				ThereAreDataFromContract = DataForGroupingItem.OpeningBalanceDr <> 0
										Or DataForGroupingItem.OpeningBalanceCr <> 0
										Or DataForGroupingItem.ThereAreRevolutions;
				If ThereAreDataFromContract Then
					SpreadsheetDocument.Put(OutputDetailedRecords(DataForGroupingItem, DataFromOutput));
				EndIf;
			EndDo; // by detailed records
		EndDo; // by types of settlements Mutual settlements/Financial tools
		#EndRegion
		
		#Region Debt_
		If TotalDebt_.Count() > 0 Then
			
			HeaderTemplateArea	= Template.GetArea("TitleArrears");
			AreaOfResponsibility				= Template.GetArea("RowArrears");
			EmptyStringArea		= Template.GetArea("IsBlankString");
			
			HeaderTemplateArea.Parameters.ReconciliationPeriodEnd = Format(DocumentData.EndOfPeriod, "DLF=DD");
			SpreadsheetDocument.Put(HeaderTemplateArea);
			UsePartnersAndCounterparties = GetFunctionalOption("UsePartnersAndCounterparties");
			
			CurrencyArrears = TotalDebt_.Copy(); // ValueTable
			CurrencyArrears.GroupBy("Currency", "SumDr,SumCr");
			For Each DebtInForeignCurrency In CurrencyArrears Do
				
				OutputBlankRow = True;
				PartnerPresentation_ = DocumentData.PartnerPresentation_;
				If Not ValueIsFilled(DocumentData.Partner)
						Or Not UsePartnersAndCounterparties Then
					PartnerPresentation_ = StructureOfParticipantsPresentations.CounterpartyName_;
				EndIf;
				
				If DebtInForeignCurrency.SumDr <> 0 And DebtInForeignCurrency.SumCr <> 0 Then
					CalculateBalance(DebtInForeignCurrency, "Sum");
				EndIf;
				
				AreaOfResponsibility.Parameters.Currency = DebtInForeignCurrency.Currency;
				
				// The duty of a partner
				AmountOfDebt = 0;
				If DebtInForeignCurrency.SumDr > 0 Then
					AmountOfDebt = DebtInForeignCurrency.SumDr;
					AreaOfResponsibility.Parameters.Sum = Format(DebtInForeignCurrency.SumDr, "NFD=2; NZ=0; NG=3,0");
					AreaOfResponsibility.Parameters.Debtor = PartnerPresentation_;
				Else
					// Our duty
					AmountOfDebt = DebtInForeignCurrency.SumCr;
					AreaOfResponsibility.Parameters.Sum = Format(DebtInForeignCurrency.SumCr, "NFD=2; NZ=0; NG=3,0");
					AreaOfResponsibility.Parameters.Debtor = StrTemplate(
							NStr("vi = '%1 trước %2';
								|ru = '%1 перед %2';
								|en = '%1 before %2'; fa = '%1 before %2';
								|it = '%1 перед %2';
								|pl = '%1 przed %2';
								|tr = '%2 önce %1'"),
							StructureOfParticipantsPresentations.RepresentationOfTheOrganization,
							PartnerPresentation_);
				EndIf;
				AreaOfResponsibility.Parameters.AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountOfDebt,DebtInForeignCurrency.Currency);
				SpreadsheetDocument.Put(AreaOfResponsibility);
				
				If OutputBlankRow Then
					SpreadsheetDocument.Put(EmptyStringArea);
				EndIf;
			EndDo; 
			
		Else
		
			TemplateArea = Template.GetArea("DebtHeadingIsMissing");
			TemplateArea.Parameters.ReconciliationPeriodEnd = Format(DocumentData.EndOfPeriod, "DLF=DD");
			SpreadsheetDocument.Put(TemplateArea);
		
		EndIf;
		#EndRegion 
		
		// NO DISCREPANCIES WERE FOUND
		CounterpartyDataFilledIn = Not PrintSettings.DoNotFillInTheCounterpartySData;
		If Not DocumentData.ThereAreDiscrepancies And CounterpartyDataFilledIn Then
			TemplateArea = Template.GetArea("HeadlineDiscrepancies");
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		#Region Signatures
		TemplateArea = Template.GetArea("Signatures");
		TemplateArea.Parameters.Fill(DocumentData);
		TemplateArea.Parameters.RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(CompanyInformation, 
												  			  "FullDescr,TIN,LegalAddress");
		TemplateArea.Parameters.CounterpartyName_   = PrintFormGeneration.OrganizationDescription(CounterpartyInformation_, 
												  			  "FullDescr,TIN,LegalAddress");
		SpreadsheetDocument.Put(TemplateArea);
		#EndRegion
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, DocumentData.DocumentRef);
	
	EndDo; // end of the cycle according to the document

	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	If TypeOf(ForDebugging) = Type("Structure") Then
		ForDebugging.Insert("SpreadsheetDocument", SpreadsheetDocument);
	EndIf;
	
	SpreadsheetDocument.ReadOnly = True;
	Return SpreadsheetDocument;
	
EndFunction

Function OutputDetailedRecords(DataForGroupingItem, DataFromOutput)
	
	Template = DataFromOutput.Template;
	TotalDebt_ = DataFromOutput.TotalDebt_;
	PrintSettings = DataFromOutput.PrintSettings;
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	StructureOfParticipantsPresentations = PrintSettings.PresentationsOfParticipants;
	
	TheseAreFinancialInstruments = DataForGroupingItem.FinancialInstruments;
	WithdrawDebtInAdvance = Not TheseAreFinancialInstruments And PrintSettings.DebitAsDebt;
	SpreadsheetDocument = New SpreadsheetDocument;
	
	#Region PrintAreas
	DimensionTemplateArea = Template.GetArea("GroupingObjectContractCurrency");
	HeaderTemplateArea_       = Template.GetArea("TableHeader");
	InitialTemplateArea  = Template.GetArea("RowOfInitialBalanceTable");
	LayoutAreaString      = Template.GetArea("TableRow");
	RevolutionsTemplateArea     = Template.GetArea("TurnoverForAPeriod");
	ConeTemplateArea  = Template.GetArea("TableRowConRemainder");
	If PrintSettings.DoNotFillInTheCounterpartySData Then
		InitialTemplateArea.Area("AmountCounterpartyBalance").Format = "NFD=2";
		LayoutAreaString.Area("AmountCounterparty").Format = "NFD=2";
		RevolutionsTemplateArea.Area("AmountCounterpartyTurnover").Format = "NFD=2";
		ConeTemplateArea.Area("AmountCounterpartyConBalance").Format = "NFD=2";
	EndIf;
	#EndRegion
	
	#Region DisplayingNameOfDimension
	FragmentsOfTitle = New Array;
	FragmentsOfTitle.Add(DataForGroupingItem.PresentationTypeOfCalculations);
	If PrintSettings.MutualSettlementsDetails = "ARAPObject"
			And TypeOf(DataForGroupingItem.GroupingObject) = Type("CatalogRef.ARAPObjects") Then
		FragmentsOfTitle.Add(NStr("vi = 'theo đối tượng hạch toán';
									|ru = 'по объекту расчетов';
									|en = 'by AR/AP object'; fa = 'by AR/AP object';
									|it = 'по объекту расчетов';
									|pl = 'na temat obliczeń';
									|tr = 'alacak/borç nesnesi kapsamında'", DefaultLanguageCode));
	ElsIf PrintSettings.MutualSettlementsDetails = "Contract" Then
		FragmentsOfTitle.Add(NStr("vi = 'theo hợp đồng';
									|ru = 'по договору';
									|en = 'by contract'; fa = 'بر اساس قرارداد';
									|it = 'по договору';
									|pl = 'wg kontraktu';
									|tr = 'sözleşme kapsamında'", DefaultLanguageCode));
	EndIf;
	If PrintSettings.MutualSettlementsDetails <> "Currency" Then
		If ValueIsFilled(DataForGroupingItem.DimensionObjectPresentation) Then
			FragmentsOfTitle.Add(DataForGroupingItem.DimensionObjectPresentation);
		Else
			FragmentsOfTitle.Add("<" + NStr("vi = 'chưa chỉ định';
											|ru = 'не указан';
											|en = 'not specified'; fa = 'مشخص نشده';
											|it = 'не указан';
											|pl = 'nie określony';
											|tr = 'belirtilmedi'", DefaultLanguageCode) + ">");
		EndIf;
	EndIf;
	Currency = NStr("vi = 'ngoại tệ';
					|ru = 'в валюте';
					|en = 'in currency'; fa = 'به ارز';
					|it = 'в валюте';
					|pl = 'w walucie';
					|tr = 'para biriminde'", DefaultLanguageCode) + " " + DataForGroupingItem.PresentationCurrency_;
	FragmentsOfTitle.Add(Currency);
	GroupHeader = StrConcat(FragmentsOfTitle," ");
	
	DimensionTemplateArea.Parameters.GroupHeader = GroupHeader;
	SpreadsheetDocument.Put(DimensionTemplateArea);
	#EndRegion
	
	#Region TableHeaderOutput
	HeaderTemplateArea_.Parameters.Fill(StructureOfParticipantsPresentations);
	HeaderTemplateArea_.Parameters.Debit = NStr("vi = 'Nợ';
												|ru = 'Дебет';
												|en = 'Debit'; fa = 'بدهکار';
												|it = 'Дебет';
												|pl = 'Debet';
												|tr = 'Borç'", DefaultLanguageCode);
	HeaderTemplateArea_.Parameters.Credit = NStr("vi = 'Có';
												|ru = 'Кредит';
												|en = 'Credit'; fa = 'بستانکار';
												|it = 'Кредит';
												|pl = 'Ma';
												|tr = 'Alacak'", DefaultLanguageCode);
	InitialTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư đầu';
														|ru = 'Сальдо начальное';
														|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
														|it = 'Сальдо начальное';
														|pl = 'Saldo początkowe';
														|tr = 'Açılış bakiyesi'", DefaultLanguageCode);
	ConeTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư cuối';
													|ru = 'Сальдо конечное';
													|en = 'Closing balance'; fa = 'مانده پایان دوره';
													|it = 'Сальдо конечное';
													|pl = 'Saldo końcowe';
													|tr = 'Kapanış bakiyesi'", DefaultLanguageCode);
	If PrintSettings.DebitAsDebt Then
		HeaderTemplateArea_.Parameters.Debit = NStr("vi = 'Công nợ';
													|ru = 'Долг';
													|en = 'Debt'; fa = 'بدهی';
													|it = 'Долг';
													|pl = 'Debt';
													|tr = 'Borç'", DefaultLanguageCode);
		HeaderTemplateArea_.Parameters.Credit = NStr("vi = 'Ứng trước';
													|ru = 'Аванс';
													|en = 'Prepayment'; fa = 'پیش‌پرداخت';
													|it = 'Аванс';
													|pl = 'Prepayment';
													|tr = 'Avans'", DefaultLanguageCode);
		InitialTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư đầu';
															|ru = 'Сальдо начальное';
															|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
															|it = 'Сальдо начальное';
															|pl = 'Saldo początkowe';
															|tr = 'Açılış bakiyesi'", DefaultLanguageCode);
		ConeTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư cuối';
														|ru = 'Сальдо конечное';
														|en = 'Closing balance'; fa = 'مانده پایان دوره';
														|it = 'Сальдо конечное';
														|pl = 'Saldo końcowe';
														|tr = 'Kapanış bakiyesi'", DefaultLanguageCode);
	EndIf;
	SpreadsheetDocument.Put(HeaderTemplateArea_);
	#EndRegion
	
	#Region OutputOfInitialRemainder
	CollapseBalance(DataForGroupingItem.OpeningBalanceDr, DataForGroupingItem.OpeningBalanceCr);
	InitialTemplateArea.Parameters.DebitAmount = DataForGroupingItem.OpeningBalanceDr;
	InitialTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.OpeningBalanceCr;
	
	CollapseBalance(DataForGroupingItem.OpeningBalanceDrCounterparty, DataForGroupingItem.OpeningBalanceCrCounterparty);
	InitialTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.OpeningBalanceDrCounterparty;
	InitialTemplateArea.Parameters.AmountCreditCounterparty = DataForGroupingItem.OpeningBalanceCrCounterparty;
	If WithdrawDebtInAdvance Then
		ClearDebitCredit(InitialTemplateArea);
		CollapseBalance(DataForGroupingItem.InitialBalanceOfDebt, DataForGroupingItem.InitialBalanceAdvance);
		InitialTemplateArea.Parameters.DebitAmount = DataForGroupingItem.InitialBalanceOfDebt;
		InitialTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.InitialBalanceAdvance;
		
		CollapseBalance(DataForGroupingItem.InitialBalanceDebtCounterparty, DataForGroupingItem.InitialBalanceAdvanceCounterparty);
		InitialTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.InitialBalanceDebtCounterparty;
		InitialTemplateArea.Parameters.AmountCreditCounterparty = DataForGroupingItem.InitialBalanceAdvanceCounterparty;
	EndIf;
	If PrintSettings.DoNotFillInTheCounterpartySData Then
		InitialTemplateArea.Parameters.AmountDebitCounterparty = 0;
		InitialTemplateArea.Parameters.AmountCreditCounterparty = 0;
	EndIf;
	SpreadsheetDocument.Put(InitialTemplateArea);
	#EndRegion
	
	SettlementDocumentsOfPeriod = New Array;
	If DataForGroupingItem.ThereAreRevolutions Then
		For Each DetailedRecords In DataForGroupingItem.Rows Do
	
			If (DetailedRecords.DocumentName3 = DocumentNameIsStorno()
					Or DetailedRecords.DocumentName3 = NameOfCorrectionDocument())
				And ValueIsFilled(DetailedRecords.RelatedDocuments) Then
				DocumentTemplate_ = "%DocumentName%";
			Else
				DocumentTemplate_ = NStr("vi = '%DocumentName% STT%Number% ngày %Date%';
										|ru = '%DocumentName% №%Number% от %Date%';
										|en = '%DocumentName% %Number% dated %Date%'; fa = '%DocumentName% %Number% dated %Date%';
										|it = '%DocumentName% №%Number% от %Date%';
										|pl = '%DocumentName% %Number% dated %Date%';
										|tr = '%Date% itibarıyla %Number% numaralı %DocumentName%'");
			EndIf;
			DocumentDetails = StrReplace(DocumentTemplate_, "%DocumentName%", DetailedRecords.DocumentName3);
			If ValueIsFilled(DetailedRecords.DocumentNumber) Then
				DocumentDetails = StrReplace(DocumentDetails, "%Number%", DetailedRecords.DocumentNumber);
			Else
				DocumentDetails = StrReplace(DocumentDetails, "%Number%", "______");
			EndIf;
			If ValueIsFilled(DetailedRecords.DocumentDate) Then
				DocumentDetails = StrReplace(DocumentDetails, "%Date%", Format(DetailedRecords.DocumentDate, "DLF=D"));
			Else
				DocumentDetails = StrReplace(DocumentDetails, "%Date%", "  .  .  ");
			EndIf;
			If ValueIsFilled(DetailedRecords.RelatedDocuments)
				And StrFind(DetailedRecords.RelatedDocuments, DetailedRecords.DocumentName3) = 0 Then
				DocumentDetails = DocumentDetails + " (" + DetailedRecords.RelatedDocuments + ")";
			EndIf;
			
			SettlementDocumentsOfPeriod.Add(DetailedRecords.ARAPDocument);
			
			LayoutAreaString = Template.GetArea("TableRow");
			If PrintSettings.DoNotFillInTheCounterpartySData Then
				LayoutAreaString.Area("AmountCounterparty").Format = "NFD=2";
			EndIf;
			
			FillPropertyValues(LayoutAreaString.Parameters, DetailedRecords);
			LayoutAreaString.Parameters.Date = Format(DetailedRecords.DateOfTransaction, "DLF=D");
			LayoutAreaString.Parameters.DocumentDetails = DocumentDetails;
			If WithdrawDebtInAdvance Then
				ClearDebitCredit(LayoutAreaString);
				LayoutAreaString.Parameters.DebitAmount = DetailedRecords.DebtAmount_;
				LayoutAreaString.Parameters.LoanAmount_ = DetailedRecords.AmountPrepayment;
				LayoutAreaString.Parameters.AmountDebitCounterparty = DetailedRecords.DebtAmountCounterparty;
				LayoutAreaString.Parameters.AmountCreditCounterparty = DetailedRecords.AmountPrepaymentCounterparty;
			EndIf;
			If PrintSettings.DoNotFillInTheCounterpartySData Then
				LayoutAreaString.Parameters.DocumentAmountCounterparty = 0;
				LayoutAreaString.Parameters.AmountDebitCounterparty = 0;
				LayoutAreaString.Parameters.AmountCreditCounterparty = 0;
			EndIf;
			SpreadsheetDocument.Put(LayoutAreaString);
		EndDo; 
	EndIf;
	
	#Region OutputOfRevolutionsForPeriod
	FillPropertyValues(RevolutionsTemplateArea.Parameters, DataForGroupingItem);
	RevolutionsTemplateArea.Parameters.DebitAmount = DataForGroupingItem.DebitAmount;
	RevolutionsTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.LoanAmount_;
	RevolutionsTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.AmountDebitCounterparty;
	RevolutionsTemplateArea.Parameters.AmountCreditCounterparty = DataForGroupingItem.AmountCreditCounterparty;
	If WithdrawDebtInAdvance Then
		ClearDebitCredit(RevolutionsTemplateArea);
		RevolutionsTemplateArea.Parameters.DebitAmount = DataForGroupingItem.DebtAmount_;
		RevolutionsTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.AmountPrepayment;
		RevolutionsTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.DebtAmountCounterparty;
		RevolutionsTemplateArea.Parameters.AmountCreditCounterparty = DataForGroupingItem.AmountPrepaymentCounterparty;
	EndIf;
	
	If PrintSettings.DoNotFillInTheCounterpartySData Then
		RevolutionsTemplateArea.Parameters.AmountDebitCounterparty = 0;
		RevolutionsTemplateArea.Parameters.AmountCreditCounterparty = 0;
	EndIf;
	If SettlementDocumentsOfPeriod.Count() > 0 Then
		SpreadsheetDocument.Put(RevolutionsTemplateArea);
	EndIf;
	#EndRegion
	
	#Region OutputOfFinalRemainder
	CollapseBalance(DataForGroupingItem.ClosingBalanceDr, DataForGroupingItem.ClosingBalanceCr);
	FillPropertyValues(ConeTemplateArea.Parameters, DataForGroupingItem);
	
	ConeTemplateArea.Parameters.DebitAmount = DataForGroupingItem.ClosingBalanceDr;
	ConeTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.ClosingBalanceCr;
	
	ConeTemplateArea.Parameters.AmountDebitCounterparty = 0;
	ConeTemplateArea.Parameters.AmountCreditCounterparty = 0;
	
	CollapseBalance(DataForGroupingItem.ClosingBalanceDrCounterparty, DataForGroupingItem.ClosingBalanceCrCounterparty);
	ConeTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.ClosingBalanceDrCounterparty;
	ConeTemplateArea.Parameters.AmountCreditCounterparty = DataForGroupingItem.ClosingBalanceCrCounterparty;
	If WithdrawDebtInAdvance Then
		ClearDebitCredit(ConeTemplateArea);
		
		CollapseBalance(DataForGroupingItem.FinalBalanceOfDebt, DataForGroupingItem.FinalBalanceAdvance);
		ConeTemplateArea.Parameters.DebitAmount = DataForGroupingItem.FinalBalanceOfDebt;
		ConeTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.FinalBalanceAdvance;
		
		CollapseBalance(DataForGroupingItem.FinalBalanceDebtCounterparty, DataForGroupingItem.FinalBalanceAdvanceCounterparty);
		ConeTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.FinalBalanceDebtCounterparty;
		ConeTemplateArea.Parameters.AmountCreditCounterparty = DataForGroupingItem.FinalBalanceAdvanceCounterparty;
	EndIf;
	If PrintSettings.DoNotFillInTheCounterpartySData Then
		ConeTemplateArea.Parameters.AmountDebitCounterparty = 0;
		ConeTemplateArea.Parameters.AmountCreditCounterparty = 0;
	EndIf;
	SpreadsheetDocument.Put(ConeTemplateArea);
	#EndRegion

	Debt_ = TotalDebt_.Add();
	Debt_.Currency = DataForGroupingItem.Currency;
	Debt_.SumDr = DataForGroupingItem.ClosingBalanceDr;
	Debt_.SumCr = DataForGroupingItem.ClosingBalanceCr;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure CollapseBalance(ClosingBalanceDr, ClosingBalanceCr)
	
	ClosingBalance = ClosingBalanceDr - ClosingBalanceCr;
	If ClosingBalance > 0 Then
		ClosingBalanceDr = ClosingBalance;
		ClosingBalanceCr = 0;
	Else
		ClosingBalanceDr = 0;
		ClosingBalanceCr = -ClosingBalance;
	EndIf;
	
EndProcedure

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Counterparty";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CounterpartyData.Partner");
	Else
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty.Partner");
	EndIf;
	
EndProcedure

// Default print settings.
// 
// Returns:
//  Structure - Default Print Settings:
// * MutualSettlementsDetails - Number
// * DetailingFinancialInstruments - Number
// * DebitAsDebt - Boolean
// * DoNotFillInTheCounterpartySData - Boolean
// * MergeCustomersSuppliers - Boolean
Function DefaultPrintSettings() Export
	
	Result = New Structure;
	Result.Insert("MutualSettlementsDetails", 0);
	Result.Insert("DetailingFinancialInstruments", 0);
	Result.Insert("DebitAsDebt", False);
	Result.Insert("DoNotFillInTheCounterpartySData", False);
	Result.Insert("MergeCustomersSuppliers", True);
	Return Result;
	
EndFunction

Procedure CalculateBalance(DebtInForeignCurrency, Sum)
	
	SumDr = DebtInForeignCurrency[Sum + "Dr"];
	SumCr = DebtInForeignCurrency[Sum + "Cr"];
	Balance_ = SumDr - SumCr;
	If Balance_ > 0 Then
		DebtInForeignCurrency[Sum + "Dr"] = Balance_;
		DebtInForeignCurrency[Sum + "Cr"] = 0;
	Else
		DebtInForeignCurrency[Sum + "Dr"] = 0;
		DebtInForeignCurrency[Sum + "Cr"] = -Balance_;
	EndIf;
	
EndProcedure

#Region GettingDataToPrint

// Request data for printing.
// 
// Parameters:
//  ObjectsArray - Array of DocumentRef.ARAPReconciliation2_5_11- Array of objects
//  PrintSettings - Arbitrary, Date, Undefined, Structure - Print Settings:
// * DebitAsDebt - Boolean -
// * MutualSettlementsDetails - Number - 
// * DetailingFinancialInstruments - Number -
// * DoNotFillInTheCounterpartySData - Boolean -
// * MergeCustomersSuppliers - Boolean -
// 
// Returns:
//  Query - Request Data For Printing
Function RequestDataForPrinting(ObjectsArray, PrintSettings) Export
	
	DecipherDetailSetting(PrintSettings);
	
	RequestDocumentData = New Query;
	TempTablesManager = InitializeTableManager(ObjectsArray);
	RequestDocumentData.TempTablesManager = TempTablesManager;
	
	RequestDocumentData.Text = QueryTextDocumentData(PrintSettings);
	
	RequestDocumentData.SetParameter("PaymentType_", NStr("vi = 'Hạch toán';
															|ru = 'Расчеты';
															|en = 'Settlements'; fa = 'تسویه‌ها';
															|it = 'Расчеты';
															|pl = 'Settlements';
															|tr = 'Mutabakatlar'", Common.DefaultLanguageCode()));
	RequestDocumentData.SetParameter("ObjectsArray", ObjectsArray);
	RequestDocumentData.SetParameter("DebitAsDebt", PrintSettings.DebitAsDebt);
	RequestDocumentData.SetParameter("MergeCustomersSuppliers", PrintSettings.MergeCustomersSuppliers);
	RequestDocumentData.SetParameter("MutualSettlementsDetails", PrintSettings.MutualSettlementsDetails);

	If PrintSettings.Property("ForDebugging") Then
		If PrintSettings.ForDebugging.Property("RequestDataForPrinting") Then
			RequestDocumentData = PrintSettings.ForDebugging.RequestDataForPrinting;
			RequestDocumentData.TempTablesManager = TempTablesManager;
			PrintSettings.ForDebugging.Insert("TempTablesManager", InitializeTableManager(ObjectsArray));
		EndIf;
	EndIf;
	
	Return RequestDocumentData;

EndFunction

Function InitializeTableManager(ObjectsArray)
	
	ParametersOfResponsiblePersons = ResponsiblePersonsServer.DefaultParametersOfResponsiblePersons();
	ParametersOfResponsiblePersons.DetailsResponsiblePersons = StructureAttributesResponsiblePersons();
	
	TempTablesManager = New TempTablesManager;
	If ValueIsFilled(ObjectsArray) Then
		ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager, ParametersOfResponsiblePersons);
	Else
		ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(Documents.ARAPReconciliation2_5_11.EmptyRef(), TempTablesManager, ParametersOfResponsiblePersons);
	EndIf;
	
	MatchingDataAliasesOfResponsiblePersons = New Map();
	
	NamesStructure = ResponsiblePersonsServer.DataAliasesOfResponsiblePersonsByDefault();
	NamesStructure.Description = "CounterpartyCompanyManagerDescription";
	NamesStructure.LASTFIRSTNAME = "HeadOfCounterpartySOrganizationFULLName";
	NamesStructure.JobTitle = "CounterpartyCompanyManagerJobTitle";
	NamesStructure.SignatureRightBasis = "HeadOfCounterpartySOrganizationBasisOfRightOfSignature";
	MatchingDataAliasesOfResponsiblePersons.Insert("CounterpartyCompanyManager", NamesStructure);
	
	NamesStructure = ResponsiblePersonsServer.DataAliasesOfResponsiblePersonsByDefault();
	NamesStructure.Description = "ChiefAccountantOfCounterpartyCompanyDescription";
	NamesStructure.LASTFIRSTNAME = "ChiefAccountantOfCounterpartySOrganizationFULLNAME";
	NamesStructure.JobTitle = "ChiefAccountantOfCounterpartyCompanyJobTitle";
	NamesStructure.SignatureRightBasis = "ChiefAccountantOfCounterpartyOrganizationBasisOfRightOfSignature";
	MatchingDataAliasesOfResponsiblePersons.Insert("ChiefAccountantOfCounterpartyCompany", NamesStructure);
	
	ParametersOfResponsiblePersons = ResponsiblePersonsServer.DefaultParametersOfResponsiblePersons();
	ParametersOfResponsiblePersons.CompanyAttributeName = "Counterparty";
	ParametersOfResponsiblePersons.DetailsResponsiblePersons = StructureAttributesResponsiblePersonsOfCounterpartyOrganization();
	ParametersOfResponsiblePersons.TableNameResponsiblePersons = "TableResponsiblePersonsOfCounterpartyOrganization";
	ParametersOfResponsiblePersons.AliasesOfDataOfResponsiblePersons = MatchingDataAliasesOfResponsiblePersons;
	
	If ValueIsFilled(ObjectsArray) Then
		ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(
			ObjectsArray,
			TempTablesManager,
			ParametersOfResponsiblePersons);
	Else
		ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(
			Documents.ARAPReconciliation2_5_11.EmptyRef(),
			TempTablesManager,
			ParametersOfResponsiblePersons);
	EndIf;
	
	Return TempTablesManager;
	
EndFunction

Function QueryTextDocumentData(PrintSettings)
	
	QueryText = 
	"SELECT
	|	TSResultsOfCalculations.Ref AS Ref,
	|	TSResultsOfCalculations.Ref.Currency AS ReconciliationCurrency,
	|	TSResultsOfCalculations.Ref.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	TSResultsOfCalculations.Ref.Currency = TSResultsOfCalculations.Ref.Organization.LocalAccountingCurrency AS ReconciliationInLocalCurrency,
	|	TSResultsOfCalculations.Ref.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	CASE WHEN &MergeCustomersSuppliers
	|			AND TSResultsOfCalculations.PaymentType_ IN (
	|				VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting),
	|				VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|		THEN &PaymentType_
	|		ELSE TSResultsOfCalculations.PaymentType_
	|	END AS PaymentType_,
	|	TSResultsOfCalculations.Ref.ModeOfARAPTotalsReconciliation = VALUE(Enum.ModeOfARAPTotalsReconciliation.ByContracts) AS ReconciliationUnderContracts,
	|	CASE 
	|		WHEN &MutualSettlementsDetails = ""Currency""
	|			THEN TSResultsOfCalculations.Ref.Currency
	|		WHEN &MutualSettlementsDetails = ""Contract""
	|			THEN TSResultsOfCalculations.Contract
	|		WHEN &MutualSettlementsDetails = ""ARAPObject""
	|			THEN TSResultsOfCalculations.ARAPObject
	|	END AS GroupingObject,
	|	CASE 
	|		WHEN &MutualSettlementsDetails = ""Currency""
	|			THEN REFPRESENTATION(TSResultsOfCalculations.Ref.Currency)
	|		WHEN &MutualSettlementsDetails = ""Contract""
	|			THEN TSResultsOfCalculations.ContractName
	|		WHEN &MutualSettlementsDetails = ""ARAPObject""
	|			THEN REFPRESENTATION(TSResultsOfCalculations.ARAPObject)
	|	END AS DimensionObjectPresentation,
	|	
	|
	|	TSResultsOfCalculations.OpeningBalanceDr AS OpeningBalanceDr,
	|	TSResultsOfCalculations.OpeningBalanceCr AS OpeningBalanceCr,
	|	TSResultsOfCalculations.TurnoverDr AS TurnoverDr,
	|	TSResultsOfCalculations.TurnoverCr AS TurnoverCr,
	|	TSResultsOfCalculations.ClosingBalanceDr AS ClosingBalanceDr,
	|	TSResultsOfCalculations.ClosingBalanceCr AS ClosingBalanceCr,
	|
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN TSResultsOfCalculations.OpeningBalanceCrCounterparty
	|		ELSE TSResultsOfCalculations.OpeningBalanceCr
	|	END AS OpeningBalanceDrCounterparty,
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN TSResultsOfCalculations.OpeningBalanceDrCounterparty
	|		ELSE TSResultsOfCalculations.OpeningBalanceDr
	|	END AS OpeningBalanceCrCounterparty,
	|
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN TSResultsOfCalculations.TurnoverCrCounterparty
	|		ELSE TSResultsOfCalculations.TurnoverCr
	|	END AS TurnoverDrCounterparty,
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN TSResultsOfCalculations.TurnoverDrCounterparty
	|		ELSE TSResultsOfCalculations.TurnoverDr
	|	END AS TurnoverCrCounterparty,
	|
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN TSResultsOfCalculations.ClosingBalanceCrCounterparty
	|		ELSE TSResultsOfCalculations.ClosingBalanceCr
	|	END AS ClosingBalanceDrCounterparty,
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN TSResultsOfCalculations.ClosingBalanceDrCounterparty
	|		ELSE TSResultsOfCalculations.ClosingBalanceDr
	|	END AS ClosingBalanceCrCounterparty,
	|
	|
	|	CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		THEN TSResultsOfCalculations.OpeningBalanceDr
	|		ELSE TSResultsOfCalculations.OpeningBalanceCr
	|	END AS InitialBalanceOfDebt,
	|	CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		THEN TSResultsOfCalculations.OpeningBalanceCr
	|		ELSE TSResultsOfCalculations.OpeningBalanceDr
	|	END AS InitialBalanceAdvance,
	|
	|	CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		THEN TSResultsOfCalculations.ClosingBalanceDr
	|		ELSE TSResultsOfCalculations.ClosingBalanceCr
	|	END AS FinalBalanceOfDebt,
	|	CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		THEN TSResultsOfCalculations.ClosingBalanceCr
	|		ELSE TSResultsOfCalculations.ClosingBalanceDr
	|	END AS FinalBalanceAdvance,
	|
	|
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.OpeningBalanceDrCounterparty
	|				ELSE TSResultsOfCalculations.OpeningBalanceCrCounterparty
	|			END
	|		ELSE CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.OpeningBalanceDr
	|				ELSE TSResultsOfCalculations.OpeningBalanceCr
	|			END
	|	END AS InitialBalanceDebtCounterparty,
	|
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.OpeningBalanceCrCounterparty
	|				ELSE TSResultsOfCalculations.OpeningBalanceDrCounterparty
	|			END
	|		ELSE CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.OpeningBalanceCr
	|				ELSE TSResultsOfCalculations.OpeningBalanceDr
	|			END
	|	END AS InitialBalanceAdvanceCounterparty,
	|
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.ClosingBalanceDrCounterparty
	|				ELSE TSResultsOfCalculations.ClosingBalanceCrCounterparty
	|			END
	|		ELSE CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.ClosingBalanceDr
	|				ELSE TSResultsOfCalculations.ClosingBalanceCr
	|			END
	|	END AS FinalBalanceDebtCounterparty,
	|	CASE WHEN TSResultsOfCalculations.Ref.ThereAreDiscrepancies
	|		THEN CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.ClosingBalanceCrCounterparty
	|				ELSE TSResultsOfCalculations.ClosingBalanceDrCounterparty
	|			END
	|		ELSE CASE WHEN TSResultsOfCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN TSResultsOfCalculations.ClosingBalanceCr
	|				ELSE TSResultsOfCalculations.ClosingBalanceDr
	|			END
	|	END AS FinalBalanceAdvanceCounterparty
	|
	|INTO TTFinalRecordsOfCalculations
	|FROM
	|	Document.ARAPReconciliation2_5_11.SummaryRecords AS TSResultsOfCalculations
	|WHERE
	|	TSResultsOfCalculations.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResultsOfCalculations.Ref AS Ref,
	|	ResultsOfCalculations.Ref.Currency AS ReconciliationCurrency,
	|	ResultsOfCalculations.Ref.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	ResultsOfCalculations.Ref.Currency = ResultsOfCalculations.Ref.Organization.LocalAccountingCurrency AS ReconciliationInLocalCurrency,
	|	ResultsOfCalculations.Ref.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	ResultsOfCalculations.PaymentType_ AS PaymentType_,
	|	ResultsOfCalculations.Ref.ModeOfARAPTotalsReconciliation = VALUE(Enum.ModeOfARAPTotalsReconciliation.ByContracts) AS ReconciliationUnderContracts,
	|	ResultsOfCalculations.GroupingObject AS GroupingObject,
	|	ResultsOfCalculations.DimensionObjectPresentation AS DimensionObjectPresentation,
	|
	|	SUM(ResultsOfCalculations.OpeningBalanceDr) AS OpeningBalanceDr,
	|	SUM(ResultsOfCalculations.OpeningBalanceCr) AS OpeningBalanceCr,
	|	SUM(ResultsOfCalculations.TurnoverDr) AS TurnoverDr,
	|	SUM(ResultsOfCalculations.TurnoverCr) AS TurnoverCr,
	|	SUM(ResultsOfCalculations.ClosingBalanceDr) AS ClosingBalanceDr,
	|	SUM(ResultsOfCalculations.ClosingBalanceCr) AS ClosingBalanceCr,
	|
	|	SUM(ResultsOfCalculations.OpeningBalanceDrCounterparty) AS OpeningBalanceDrCounterparty,
	|	SUM(ResultsOfCalculations.OpeningBalanceCrCounterparty) AS OpeningBalanceCrCounterparty,
	|
	|	SUM(ResultsOfCalculations.TurnoverDrCounterparty) AS TurnoverDrCounterparty,
	|	SUM(ResultsOfCalculations.TurnoverCrCounterparty) AS TurnoverCrCounterparty,
	|
	|	SUM(ResultsOfCalculations.ClosingBalanceDrCounterparty) AS ClosingBalanceDrCounterparty,
	|	SUM(ResultsOfCalculations.ClosingBalanceCrCounterparty) AS ClosingBalanceCrCounterparty,
	|
	|	SUM(ResultsOfCalculations.InitialBalanceOfDebt) AS InitialBalanceOfDebt,
	|	SUM(ResultsOfCalculations.InitialBalanceAdvance) AS InitialBalanceAdvance,
	|
	|	SUM(ResultsOfCalculations.FinalBalanceOfDebt) AS FinalBalanceOfDebt,
	|	SUM(ResultsOfCalculations.FinalBalanceAdvance) AS FinalBalanceAdvance,
	|
	|	SUM(ResultsOfCalculations.InitialBalanceDebtCounterparty) AS InitialBalanceDebtCounterparty,
	|	SUM(ResultsOfCalculations.InitialBalanceAdvanceCounterparty) AS InitialBalanceAdvanceCounterparty,
	|
	|	SUM(ResultsOfCalculations.FinalBalanceDebtCounterparty) AS FinalBalanceDebtCounterparty,
	|	SUM(ResultsOfCalculations.FinalBalanceAdvanceCounterparty) AS FinalBalanceAdvanceCounterparty
	|
	|INTO TTCalculationResults
	|FROM
	|	TTFinalRecordsOfCalculations AS ResultsOfCalculations
	|
	|GROUP BY
	|	ResultsOfCalculations.Ref,
	|	ResultsOfCalculations.PaymentType_,
	|	ResultsOfCalculations.GroupingObject,
	|	ResultsOfCalculations.DimensionObjectPresentation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailedRecords.Ref AS Ref,
	|	DetailedRecords.DateOfTransaction AS DateOfTransaction,
	|	CASE WHEN &MergeCustomersSuppliers
	|			AND DetailedRecords.PaymentType_ IN (
	|				VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting),
	|				VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|		THEN &PaymentType_
	|		ELSE DetailedRecords.PaymentType_
	|	END AS PaymentType_,
	|
	|	CASE 
	|		WHEN &MutualSettlementsDetails = ""Currency""
	|			THEN DetailedRecords.Ref.Currency
	|		WHEN &MutualSettlementsDetails = ""Contract""
	|			THEN DetailedRecords.Contract
	|		WHEN &MutualSettlementsDetails = ""ARAPObject""
	|			THEN DetailedRecords.ARAPObject
	|	END AS GroupingObject,
	|
	|	DetailedRecords.ARAPDocument AS ARAPDocument,
	|	CASE WHEN DetailedRecords.DocumentName3 = """"
	|		AND DetailedRecords.DebitAmount = 0 AND DetailedRecords.LoanAmount_ = 0
	|		THEN DetailedRecords.DocumentNameCounterparty
	|		ELSE DetailedRecords.DocumentName3
	|	END AS DocumentName3,
	|	CASE WHEN DetailedRecords.DocumentName3 = """" AND DetailedRecords.DocumentNumber = """"
	|		AND DetailedRecords.DebitAmount = 0 AND DetailedRecords.LoanAmount_ = 0
	|		THEN DetailedRecords.IncomingNumberCounterparty
	|		ELSE DetailedRecords.DocumentNumber
	|	END AS DocumentNumber,
	|	CASE WHEN DetailedRecords.DocumentName3 = """" AND DetailedRecords.DocumentDate = DATETIME(1,1,1)
	|		AND DetailedRecords.DebitAmount = 0 AND DetailedRecords.LoanAmount_ = 0
	|		THEN DetailedRecords.DocumentDateCounterparty
	|		ELSE DetailedRecords.DocumentDate
	|	END AS DocumentDate,
	|	DetailedRecords.RelatedDocuments AS RelatedDocuments,
	|	ISNULL(SaleOfGoodsAndServices.DateOfTransferOfTitleToGoods, DATETIME(1,1,1)) AS DateOfTransferOfTitleToGoods,
	|	ISNULL(SaleOfGoodsAndServices.Status, UNDEFINED) = VALUE(Enum.StatusesOfCustomerInvoices.InTransit) AS GoodsInTransit,
	|
	|	DetailedRecords.DocumentCurrency AS DocumentCurrency,
	|	DetailedRecords.DocumentAmount AS DocumentAmount,
	|
	|	SUM(DetailedRecords.DebtAmount_) AS DebtAmount_,
	|	SUM(DetailedRecords.AmountPrepayment) AS AmountPrepayment,
	|	SUM(DetailedRecords.DebitAmount) AS DebitAmount,
	|	SUM(DetailedRecords.LoanAmount_) AS LoanAmount_,
	|
	|	SUM(DetailedRecords.AmountDebitCounterparty) AS AmountDebitCounterparty,
	|	SUM(DetailedRecords.AmountCreditCounterparty) AS AmountCreditCounterparty,
	|
	|	SUM(DetailedRecords.AmountDebitCounterparty) AS DebtAmountCounterparty,
	|	SUM(DetailedRecords.AmountCreditCounterparty) AS AmountPrepaymentCounterparty
	|
	|INTO TTDetailedRecordingsPreliminary
	|FROM
	|	Document.ARAPReconciliation2_5_11.DetailedRecords AS DetailedRecords
	|		LEFT JOIN Document.CustomerInvoice AS SaleOfGoodsAndServices
	|			ON DetailedRecords.ARAPDocument = SaleOfGoodsAndServices.Ref
	|WHERE
	|	DetailedRecords.Ref IN(&ObjectsArray)
	|GROUP BY
	|	DetailedRecords.Ref,
	|	DetailedRecords.DateOfTransaction,
	|	CASE WHEN &MergeCustomersSuppliers
	|			AND DetailedRecords.PaymentType_ IN (
	|				VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting),
	|				VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|		THEN &PaymentType_
	|		ELSE DetailedRecords.PaymentType_
	|	END,
	|
	|	CASE 
	|		WHEN &MutualSettlementsDetails = ""Currency""
	|			THEN DetailedRecords.Ref.Currency
	|		WHEN &MutualSettlementsDetails = ""Contract""
	|			THEN DetailedRecords.Contract
	|		WHEN &MutualSettlementsDetails = ""ARAPObject""
	|			THEN DetailedRecords.ARAPObject
	|	END,
	|
	|	DetailedRecords.ARAPDocument,
	|	CASE WHEN DetailedRecords.DocumentName3 = """"
	|		AND DetailedRecords.DebitAmount = 0 AND DetailedRecords.LoanAmount_ = 0
	|		THEN DetailedRecords.DocumentNameCounterparty
	|		ELSE DetailedRecords.DocumentName3
	|	END,
	|	CASE WHEN DetailedRecords.DocumentName3 = """" AND DetailedRecords.DocumentNumber = """"
	|		AND DetailedRecords.DebitAmount = 0 AND DetailedRecords.LoanAmount_ = 0
	|		THEN DetailedRecords.IncomingNumberCounterparty
	|		ELSE DetailedRecords.DocumentNumber
	|	END,
	|	CASE WHEN DetailedRecords.DocumentName3 = """" AND DetailedRecords.DocumentDate = DATETIME(1,1,1)
	|		AND DetailedRecords.DebitAmount = 0 AND DetailedRecords.LoanAmount_ = 0
	|		THEN DetailedRecords.DocumentDateCounterparty
	|		ELSE DetailedRecords.DocumentDate
	|	END,
	|	DetailedRecords.RelatedDocuments,
	|	DetailedRecords.DocumentCurrency,
	|	DetailedRecords.DocumentAmount,
	|	ISNULL(SaleOfGoodsAndServices.DateOfTransferOfTitleToGoods, DATETIME(1,1,1)),
	|	ISNULL(SaleOfGoodsAndServices.Status, UNDEFINED) = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailedRecords.Ref AS Ref,
	|	DetailedRecords.DateOfTransaction AS DateOfTransaction,
	|	DetailedRecords.PaymentType_ AS PaymentType_,
	|
	|	DetailedRecords.GroupingObject AS GroupingObject,
	|
	|	DetailedRecords.ARAPDocument AS ARAPDocument,
	|	DetailedRecords.DocumentName3 AS DocumentName3,
	|	DetailedRecords.DocumentNumber AS DocumentNumber,
	|	DetailedRecords.DocumentDate AS DocumentDate,
	|	DetailedRecords.RelatedDocuments AS RelatedDocuments,
	|	DetailedRecords.DateOfTransferOfTitleToGoods AS DateOfTransferOfTitleToGoods,
	|	DetailedRecords.GoodsInTransit AS GoodsInTransit,
	|
	|	DetailedRecords.DocumentCurrency AS DocumentCurrency,
	|	DetailedRecords.DocumentAmount AS DocumentAmount,
	|
	|	DetailedRecords.DebtAmount_ AS DebtAmount_,
	|	DetailedRecords.AmountPrepayment AS AmountPrepayment,
	|	DetailedRecords.DebitAmount AS DebitAmount,
	|	DetailedRecords.LoanAmount_ AS LoanAmount_,
	|
	|	DetailedRecords.AmountDebitCounterparty AS AmountDebitCounterparty,
	|	DetailedRecords.AmountCreditCounterparty AS AmountCreditCounterparty,
	|
	|	DetailedRecords.AmountDebitCounterparty AS DebtAmountCounterparty,
	|	DetailedRecords.AmountCreditCounterparty AS AmountPrepaymentCounterparty
	|
	|INTO TTDetailedRecordings
	|FROM
	|	TTDetailedRecordingsPreliminary AS DetailedRecords
	|WHERE
	|	NOT ((VALUETYPE(DetailedRecords.ARAPDocument) = TYPE(Document.ARAPSettlement)
	|			OR DetailedRecords.DateOfTransferOfTitleToGoods <> DATETIME(1,1,1)
	|			OR DetailedRecords.GoodsInTransit)
	|		AND DetailedRecords.DebitAmount - DetailedRecords.LoanAmount_ = 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN DetailedRecords.PaymentType_ IN (
	|			VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting),
	|			VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS FinancialInstruments,
	|	ResultsOfCalculations.Ref AS Ref,
	|	ResultsOfCalculations.ReconciliationInLocalCurrency AS ReconciliationInLocalCurrency,
	|	CASE WHEN ResultsOfCalculations.ReconciliationInLocalCurrency
	|		THEN ResultsOfCalculations.ComplCurrency
	|		ELSE ResultsOfCalculations.ReconciliationCurrency
	|	END AS Currency,
	|	ResultsOfCalculations.ReconciliationCurrency AS ReconciliationCurrency,
	|	ResultsOfCalculations.ComplCurrency AS ComplCurrency,
	|	ResultsOfCalculations.ReconciliationUnderContracts AS ReconciliationUnderContracts,
	|	ResultsOfCalculations.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	ResultsOfCalculations.PaymentType_ AS PaymentType_,
	|
	|	ResultsOfCalculations.GroupingObject AS GroupingObject,
	|	ResultsOfCalculations.DimensionObjectPresentation AS DimensionObjectPresentation,
	|
	|	ResultsOfCalculations.OpeningBalanceDr AS OpeningBalanceDr,
	|	ResultsOfCalculations.OpeningBalanceCr AS OpeningBalanceCr,
	|	ResultsOfCalculations.TurnoverDr AS TurnoverDr,
	|	ResultsOfCalculations.TurnoverCr AS TurnoverCr,
	|	ResultsOfCalculations.ClosingBalanceDr AS ClosingBalanceDr,
	|	ResultsOfCalculations.ClosingBalanceCr AS ClosingBalanceCr,
	|
	|	ResultsOfCalculations.OpeningBalanceDrCounterparty AS OpeningBalanceDrCounterparty,
	|	ResultsOfCalculations.OpeningBalanceCrCounterparty AS OpeningBalanceCrCounterparty,
	|	ResultsOfCalculations.TurnoverDrCounterparty AS TurnoverDrCounterparty,
	|	ResultsOfCalculations.TurnoverCrCounterparty AS TurnoverCrCounterparty,
	|	ResultsOfCalculations.ClosingBalanceDrCounterparty AS ClosingBalanceDrCounterparty,
	|	ResultsOfCalculations.ClosingBalanceCrCounterparty AS ClosingBalanceCrCounterparty,
	|
	|	ResultsOfCalculations.InitialBalanceOfDebt AS InitialBalanceOfDebt,
	|	ResultsOfCalculations.InitialBalanceAdvance AS InitialBalanceAdvance,
	|	ResultsOfCalculations.FinalBalanceOfDebt AS FinalBalanceOfDebt,
	|	ResultsOfCalculations.FinalBalanceAdvance AS FinalBalanceAdvance,
	|
	|	ResultsOfCalculations.InitialBalanceDebtCounterparty AS InitialBalanceDebtCounterparty,
	|	ResultsOfCalculations.InitialBalanceAdvanceCounterparty AS InitialBalanceAdvanceCounterparty,
	|	ResultsOfCalculations.FinalBalanceDebtCounterparty AS FinalBalanceDebtCounterparty,
	|	ResultsOfCalculations.FinalBalanceAdvanceCounterparty AS FinalBalanceAdvanceCounterparty,
	|
	|	NOT DetailedRecords.ARAPDocument IS NULL AS ThereAreRevolutions,
	|	ISNULL(DetailedRecords.DateOfTransaction, DATETIME(1,1,1)) AS DateOfTransaction,
	|	ISNULL(DetailedRecords.ARAPDocument, UNDEFINED) AS ARAPDocument,
	|	ISNULL(DetailedRecords.DocumentName3, """") AS DocumentName3,
	|	ISNULL(DetailedRecords.DocumentNumber, """") AS DocumentNumber,
	|	ISNULL(DetailedRecords.DocumentDate, DATETIME(1,1,1)) AS DocumentDate,
	|	ISNULL(DetailedRecords.RelatedDocuments, """") AS RelatedDocuments,
	|	ISNULL(DetailedRecords.DateOfTransferOfTitleToGoods, DATETIME(1,1,1)) AS DateOfTransferOfTitleToGoods,
	|	ISNULL(DetailedRecords.GoodsInTransit, FALSE) AS GoodsInTransit,
	|
	|	CASE WHEN VALUETYPE(DetailedRecords.ARAPDocument) = TYPE(Document.ExchangeDifferenceCalculation)
	|		THEN ResultsOfCalculations.ComplCurrency
	|		ELSE DetailedRecords.DocumentCurrency
	|	END AS DocumentCurrency,
	|	
	|	ISNULL(DetailedRecords.DocumentAmount,0) AS DocumentAmount,
	|	ISNULL(DetailedRecords.DebtAmount_,0) AS DebtAmount_,
	|	ISNULL(DetailedRecords.AmountPrepayment,0) AS AmountPrepayment,
	|	ISNULL(DetailedRecords.DebitAmount,0) AS DebitAmount,
	|	ISNULL(DetailedRecords.LoanAmount_,0) AS LoanAmount_,
	|
	|	CASE WHEN ResultsOfCalculations.ThereAreDiscrepancies
	|		THEN ISNULL(DetailedRecords.AmountCreditCounterparty,0)
	|		ELSE ISNULL(DetailedRecords.LoanAmount_,0)
	|	END AS AmountDebitCounterparty,
	|	CASE WHEN ResultsOfCalculations.ThereAreDiscrepancies
	|		THEN ISNULL(DetailedRecords.AmountDebitCounterparty,0)
	|		ELSE ISNULL(DetailedRecords.DebitAmount,0)
	|	END AS AmountCreditCounterparty,
	|
	|	CASE WHEN ResultsOfCalculations.ThereAreDiscrepancies
	|		THEN ISNULL(DetailedRecords.AmountDebitCounterparty,0)
	|		ELSE ISNULL(DetailedRecords.DebtAmount_,0)
	|	END AS DebtAmountCounterparty,
	|	CASE WHEN ResultsOfCalculations.ThereAreDiscrepancies
	|		THEN ISNULL(DetailedRecords.AmountCreditCounterparty,0)
	|		ELSE ISNULL(DetailedRecords.AmountPrepayment,0)
	|	END AS AmountPrepaymentCounterparty,
	|	
	|	CASE 
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN 10
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN 20
	|		ELSE
	|			0
	|	END AS ARAPObjectSettings,
	|	
	|	0 AS OrderOfAmountType
	|
	|INTO TTDetailedRecordsOfCalculations
	|FROM
	|	TTCalculationResults AS ResultsOfCalculations
	|		LEFT JOIN TTDetailedRecordings AS DetailedRecords
	|		ON ResultsOfCalculations.Ref = DetailedRecords.Ref
	|			AND ResultsOfCalculations.PaymentType_ = DetailedRecords.PaymentType_
	|			AND ResultsOfCalculations.GroupingObject = DetailedRecords.GroupingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailsOfCalculation.Ref AS DocumentRef,
	|	DetailsOfCalculation.GroupingObject AS GroupingObject,
	|	DetailsOfCalculation.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	DetailsOfCalculation.ComplCurrency AS ComplCurrency,
	|	DetailsOfCalculation.ReconciliationCurrency AS ReconciliationCurrency,
	|	DetailsOfCalculation.PaymentType_ AS PaymentType_,
	|	DetailsOfCalculation.ReconciliationUnderContracts AS ReconciliationUnderContracts,
	|
	|	DetailsOfCalculation.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfCalculation.OpeningBalanceCr AS OpeningBalanceCr,
	|	SUM(DetailsOfCalculation.DebitAmount) AS TurnoverDr,
	|	SUM(DetailsOfCalculation.LoanAmount_) AS TurnoverCr,
	|	DetailsOfCalculation.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfCalculation.ClosingBalanceCr AS ClosingBalanceCr,
	|
	|	DetailsOfCalculation.OpeningBalanceDrCounterparty AS OpeningBalanceDrCounterparty,
	|	DetailsOfCalculation.OpeningBalanceCrCounterparty AS OpeningBalanceCrCounterparty,
	|	SUM(DetailsOfCalculation.AmountDebitCounterparty) AS TurnoverDrCounterparty,
	|	SUM(DetailsOfCalculation.AmountCreditCounterparty) AS TurnoverCrCounterparty,
	|	DetailsOfCalculation.ClosingBalanceDrCounterparty AS ClosingBalanceDrCounterparty,
	|	DetailsOfCalculation.ClosingBalanceCrCounterparty AS ClosingBalanceCrCounterparty,
	|
	|	DetailsOfCalculation.InitialBalanceOfDebt AS InitialBalanceOfDebt,
	|	DetailsOfCalculation.InitialBalanceAdvance AS InitialBalanceAdvance,
	|	SUM(DetailsOfCalculation.DebtAmount_) AS DebtAmount_,
	|	SUM(DetailsOfCalculation.AmountPrepayment) AS AmountPrepayment,
	|	DetailsOfCalculation.FinalBalanceOfDebt AS FinalBalanceOfDebt,
	|	DetailsOfCalculation.FinalBalanceAdvance AS FinalBalanceAdvance,
	|
	|	DetailsOfCalculation.InitialBalanceDebtCounterparty AS InitialBalanceDebtCounterparty,
	|	DetailsOfCalculation.InitialBalanceAdvanceCounterparty AS InitialBalanceAdvanceCounterparty,
	|	SUM(DetailsOfCalculation.DebtAmountCounterparty) AS DebtAmountCounterparty,
	|	SUM(DetailsOfCalculation.AmountPrepaymentCounterparty) AS AmountPrepaymentCounterparty,
	|	DetailsOfCalculation.FinalBalanceDebtCounterparty AS FinalBalanceDebtCounterparty,
	|	DetailsOfCalculation.FinalBalanceAdvanceCounterparty AS FinalBalanceAdvanceCounterparty
	|INTO TTTotalResultsForGroupingItem
	|FROM
	|	TTDetailedRecordsOfCalculations AS DetailsOfCalculation
	|	
	|GROUP BY
	|	DetailsOfCalculation.Ref,
	|	DetailsOfCalculation.GroupingObject,
	|	DetailsOfCalculation.DimensionObjectPresentation,
	|	DetailsOfCalculation.ReconciliationCurrency,
	|	DetailsOfCalculation.ComplCurrency,
	|	DetailsOfCalculation.PaymentType_,
	|	DetailsOfCalculation.ReconciliationUnderContracts,
	|	
	|	DetailsOfCalculation.OpeningBalanceDr,
	|	DetailsOfCalculation.OpeningBalanceCr,
	|	DetailsOfCalculation.ClosingBalanceDr,
	|	DetailsOfCalculation.ClosingBalanceCr,
	|
	|	DetailsOfCalculation.InitialBalanceOfDebt,
	|	DetailsOfCalculation.InitialBalanceAdvance,
	|	DetailsOfCalculation.FinalBalanceOfDebt,
	|	DetailsOfCalculation.FinalBalanceAdvance,
	|
	|	DetailsOfCalculation.OpeningBalanceDrCounterparty,
	|	DetailsOfCalculation.OpeningBalanceCrCounterparty,
	|	DetailsOfCalculation.ClosingBalanceDrCounterparty,
	|	DetailsOfCalculation.ClosingBalanceCrCounterparty,
	|
	|	DetailsOfCalculation.InitialBalanceDebtCounterparty,
	|	DetailsOfCalculation.InitialBalanceAdvanceCounterparty,
	|	DetailsOfCalculation.FinalBalanceDebtCounterparty,
	|	DetailsOfCalculation.FinalBalanceAdvanceCounterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReconciliationDocument.Ref AS DocumentRef,
	|	ISNULL(Document_Details.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) AS PaymentType_,
	|	PRESENTATION(ISNULL(Document_Details.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef))) AS PresentationTypeOfCalculations,
	|	ReconciliationDocument.Number AS Number,
	|	ReconciliationDocument.Date AS Date,
	|
	|	ReconciliationDocument.Organization AS Organization,
	|	ReconciliationDocument.Counterparty AS Counterparty,
	|	ReconciliationDocument.Partner AS Partner,
	|	ISNULL(ReconciliationDocument.Partner.DescriptionFull, """") AS PartnerPresentation_,
	|
	|	ReconciliationDocument.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	ReconciliationDocument.BeginOfPeriod AS BeginOfPeriod,
	|	ReconciliationDocument.EndOfPeriod AS EndOfPeriod,
	|
	|	CASE WHEN ReconciliationDocument.EmployeeInCharge_ = VALUE(Enum.PersonsResponsibleAndCompanies.ChiefAccountant)
	|		THEN ISNULL(TableResponsiblePersons.ChiefAccountantDescription, """")
	|		ELSE ISNULL(TableResponsiblePersons.DirectorDescription, """")
	|	END AS NameOfResponsiblePerson,
	|	CASE WHEN ReconciliationDocument.EmployeeInCharge_ = VALUE(Enum.PersonsResponsibleAndCompanies.ChiefAccountant)
	|		THEN ISNULL(TableResponsiblePersons.ChiefAccountantJobTitle, """")
	|		ELSE ISNULL(TableResponsiblePersons.DirectorJobTitle, """")
	|	END AS PositionOfResponsiblePerson,
	|	CASE WHEN VALUETYPE(ReconciliationDocument.Counterparty) = TYPE(Catalog.Companies)
	|		THEN 
	|			CASE WHEN ReconciliationDocument.CounterpartyCompanyPersonResponsible = VALUE(Enum.PersonsResponsibleAndCompanies.ChiefAccountant)
	|				THEN TableResponsiblePersonsOfCounterpartyOrganization.ChiefAccountantOfCounterpartyCompanyDescription
	|				ELSE TableResponsiblePersonsOfCounterpartyOrganization.CounterpartyCompanyManagerDescription
	|			END
	|		ELSE ReconciliationDocument.FullNameOfCounterpartyExecutive
	|	END AS FullNameOfCounterpartyExecutive,
	|	CASE WHEN VALUETYPE(ReconciliationDocument.Counterparty) = TYPE(Catalog.Companies)
	|		THEN 
	|			CASE WHEN ReconciliationDocument.CounterpartyCompanyPersonResponsible = VALUE(Enum.PersonsResponsibleAndCompanies.ChiefAccountant)
	|				THEN TableResponsiblePersonsOfCounterpartyOrganization.ChiefAccountantOfCounterpartyCompanyJobTitle
	|				ELSE TableResponsiblePersonsOfCounterpartyOrganization.CounterpartyCompanyManagerJobTitle
	|			END
	|		ELSE ReconciliationDocument.JobTitleOfCounterpartyExecutive
	|	END AS JobTitleOfCounterpartyExecutive,
	|	
	|	ISNULL(Document_Details.ThereAreRevolutions, FALSE) AS ThereAreRevolutions,
	|	ISNULL(Document_Details.FinancialInstruments, FALSE) AS FinancialInstruments,
	|
	|	ISNULL(Document_Details.GroupingObject, UNDEFINED) AS GroupingObject,
	|	ISNULL(Document_Details.DimensionObjectPresentation, """") AS DimensionObjectPresentation,
	|
	|	ISNULL(Document_Details.DateOfTransaction, DATETIME(1,1,1)) AS DateOfTransaction,
	|	ISNULL(Document_Details.ARAPDocument, UNDEFINED) AS ARAPDocument,
	|	ISNULL(Document_Details.DocumentName3, """") AS DocumentName3,
	|	ISNULL(Document_Details.DocumentNumber, """") AS DocumentNumber,
	|	ISNULL(Document_Details.DocumentDate, DATETIME(1,1,1)) AS DocumentDate,
	|	ISNULL(Document_Details.RelatedDocuments, """") AS RelatedDocuments,
	|	ISNULL(Document_Details.DateOfTransferOfTitleToGoods, DATETIME(1,1,1)) AS DateOfTransferOfTitleToGoods,
	|	ISNULL(Document_Details.GoodsInTransit, FALSE) AS GoodsInTransit,
	|	
	|	ISNULL(Document_Details.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	REFPRESENTATION(Document_Details.Currency) AS PresentationCurrency_,
	|	ISNULL(Document_Details.ReconciliationInLocalCurrency, FALSE) AS ReconciliationInLocalCurrency,
	|	ReconciliationDocument.Currency AS ReconciliationCurrency,
	|
	|	ISNULL(Document_Details.DocumentCurrency, ReconciliationDocument.Organization.LocalAccountingCurrency) AS DocumentCurrency,
	|	REFPRESENTATION(ISNULL(Document_Details.DocumentCurrency, ReconciliationDocument.Organization.LocalAccountingCurrency)) AS PresentationCurrencyOfDocument,
	|	
	|	ISNULL(Document_Details.OpeningBalanceDr, 0) AS OpeningBalanceDr,
	|	ISNULL(Document_Details.OpeningBalanceCr, 0) AS OpeningBalanceCr,
	|	ISNULL(Document_Details.TurnoverDr, 0) AS TurnoverDr,
	|	ISNULL(Document_Details.TurnoverDr, 0) AS TurnoverCr,
	|	ISNULL(Document_Details.ClosingBalanceDr, 0) AS ClosingBalanceDr,
	|	ISNULL(Document_Details.ClosingBalanceCr, 0) AS ClosingBalanceCr,
	|
	|	ISNULL(Document_Details.OpeningBalanceDrCounterparty, 0) AS OpeningBalanceDrCounterparty,
	|	ISNULL(Document_Details.OpeningBalanceCrCounterparty, 0) AS OpeningBalanceCrCounterparty,
	|	ISNULL(Document_Details.TurnoverDrCounterparty, 0) AS TurnoverDrCounterparty,
	|	ISNULL(Document_Details.TurnoverCrCounterparty, 0) AS TurnoverCrCounterparty,
	|	ISNULL(Document_Details.ClosingBalanceDrCounterparty, 0) AS ClosingBalanceDrCounterparty,
	|	ISNULL(Document_Details.ClosingBalanceCrCounterparty, 0) AS ClosingBalanceCrCounterparty,
	|	
	|	ISNULL(Document_Details.DebitAmount, 0) AS DebitAmount,
	|	ISNULL(Document_Details.LoanAmount_, 0) AS LoanAmount_,
	|	
	|	ISNULL(Document_Details.AmountDebitCounterparty, 0) AS AmountDebitCounterparty,
	|	ISNULL(Document_Details.AmountCreditCounterparty, 0) AS AmountCreditCounterparty,
	|	
	|	ISNULL(Document_Details.DocumentAmount, 0) AS DocumentAmount,
	|	ISNULL(Document_Details.DocumentAmount, 0) AS DocumentAmountCounterparty,
	|
	|	ISNULL(Document_Details.InitialBalanceOfDebt, 0) AS InitialBalanceOfDebt,
	|	ISNULL(Document_Details.InitialBalanceAdvance, 0) AS InitialBalanceAdvance,
	|	ISNULL(Document_Details.DebtAmount_, 0) AS DebtAmount_,
	|	ISNULL(Document_Details.AmountPrepayment, 0) AS AmountPrepayment,
	|	ISNULL(Document_Details.FinalBalanceOfDebt, 0) AS FinalBalanceOfDebt,
	|	ISNULL(Document_Details.FinalBalanceAdvance, 0) AS FinalBalanceAdvance,
	|	
	|	ISNULL(Document_Details.InitialBalanceDebtCounterparty, 0) AS InitialBalanceDebtCounterparty,
	|	ISNULL(Document_Details.InitialBalanceAdvanceCounterparty, 0) AS InitialBalanceAdvanceCounterparty,
	|	ISNULL(Document_Details.DebtAmountCounterparty, 0) AS DebtAmountCounterparty,
	|	ISNULL(Document_Details.AmountPrepaymentCounterparty, 0) AS AmountPrepaymentCounterparty,
	|	ISNULL(Document_Details.FinalBalanceDebtCounterparty, 0) AS FinalBalanceDebtCounterparty,
	|	ISNULL(Document_Details.FinalBalanceAdvanceCounterparty, 0) AS FinalBalanceAdvanceCounterparty,
	|	
	|	ISNULL(Document_Details.ARAPObjectSettings, 0) AS ARAPObjectSettings
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS ReconciliationDocument
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON ReconciliationDocument.Ref = TableResponsiblePersons.Ref
	|		
	|		LEFT JOIN TableResponsiblePersonsOfCounterpartyOrganization AS TableResponsiblePersonsOfCounterpartyOrganization
	|		ON ReconciliationDocument.Ref = TableResponsiblePersonsOfCounterpartyOrganization.Ref
	|		
	|		LEFT JOIN TTDetailedRecordsOfCalculations AS Document_Details
	|		ON ReconciliationDocument.Ref = Document_Details.Ref
	|WHERE
	|	ReconciliationDocument.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	DateOfTransaction,
	|	DocumentDate,
	|	DocumentName3,
	|	DocumentNumber,
	|	OrderOfAmountType,
	|	ISNULL(Document_Details.DocumentAmount, 0) DESC
	|
	|TOTALS
	|	MAX(OpeningBalanceDr),
	|	MAX(OpeningBalanceCr),
	|	MAX(TurnoverDr),
	|	MAX(TurnoverDr),
	|	MAX(ClosingBalanceDr),
	|	MAX(ClosingBalanceCr),
	|
	|	MAX(OpeningBalanceDrCounterparty),
	|	MAX(OpeningBalanceCrCounterparty),
	|	MAX(TurnoverDrCounterparty),
	|	MAX(TurnoverDrCounterparty),
	|	MAX(ClosingBalanceDrCounterparty),
	|	MAX(ClosingBalanceCrCounterparty),
	|	
	|	MAX(NameOfResponsiblePerson),
	|	MAX(PositionOfResponsiblePerson),
	|	MAX(FullNameOfCounterpartyExecutive),
	|	MAX(JobTitleOfCounterpartyExecutive),
	|	MAX(Currency),
	|	MAX(PresentationCurrency_),
	|	MAX(DocumentCurrency),
	|	MAX(PresentationCurrencyOfDocument),
	|	MAX(DimensionObjectPresentation),
	|	MAX(FinancialInstruments),
	|	MAX(ThereAreRevolutions),
	|	MAX(ThereAreDiscrepancies),
	|	MAX(DateOfTransferOfTitleToGoods),
	|	MAX(GoodsInTransit),
	|
	|	SUM(DebitAmount),
	|	SUM(LoanAmount_),
	|	
	|	SUM(AmountDebitCounterparty),
	|	SUM(AmountCreditCounterparty),
	|	SUM(DebtAmountCounterparty),
	|	SUM(AmountPrepaymentCounterparty),
	|	
	|	SUM(DocumentAmount),
	|	SUM(DebtAmount_),
	|	SUM(AmountPrepayment)
	|BY
	|	DocumentRef,
	|	PaymentType_,
	|	GroupingObject";
	
	Return QueryText;
	
EndFunction

Procedure DecipherDetailSetting(PrintSettings)
	
	GroupingCalculations = New Array;
	GroupingCalculations.Add("Currency");
	GroupingCalculations.Add("Contract");
	GroupingCalculations.Add("ARAPObject");
	
	GroupingFinTools = New Array;
	GroupingFinTools.Add("Currency");
	GroupingFinTools.Add("ContractOfFinancialInstruments");
	
	PrintSettings.MutualSettlementsDetails = GroupingCalculations[PrintSettings.MutualSettlementsDetails];
	PrintSettings.DetailingFinancialInstruments = GroupingFinTools[PrintSettings.DetailingFinancialInstruments];
	
EndProcedure

Procedure ClearDebitCredit(Area)
	
	AreaParameters_ = New Structure("DebitAmount,LoanAmount_,AmountDebitCounterparty,AmountCreditCounterparty");
	FillPropertyValues(AreaParameters_, Area.Parameters);
	
	Area.Parameters.DebitAmount = 0;
	Area.Parameters.LoanAmount_ = 0;
	If AreaParameters_.AmountDebitCounterparty <> Undefined Then 
		Area.Parameters.AmountDebitCounterparty = 0;
	EndIf;
	If AreaParameters_.AmountCreditCounterparty <> Undefined Then 
		Area.Parameters.AmountCreditCounterparty = 0;
	EndIf;
	
EndProcedure

// Forms a structure with the data of the document to be printed.
// 
// Parameters:
// Data - Structure, ValueTableRow - Document data for preparing data for printing:
// 	*ARAPDocument - DocumentRef - The document that is being described.
// 	*DocumentNumber - String - The incoming number of the document.
// 	*DocumentDate - Date - Part of the document date.
// 	*SourceDocumentName - String - view of the incoming document.
// NamesForPrinting - Map of KeyAndValue - names of printed forms of documents that the user printed:
// 	*Key - DocumentRef - Document.
// 	*Value - String - the name of the printed form.
// DescriptionOfOutgoingDocuments - String
// 
// Returns:
// 	Structure - document Presentation data for printing:
// 	*DocumentNumber - String 
// 	*DocumentDate - Date,String
// 	*DocumentName3 - String
// 	*PresentationForReconciliation - String
// 
Function DataForPrint(Data, NamesForPrinting, DescriptionOfOutgoingDocuments)
	
	PresentationsOfDocuments = PresentationsOfDocuments();
	IncomingInvoices = IncomingInvoices();
	OutgoingInvoices = OutgoingInvoices();
	
	Result = New Structure("DocumentNumber,DocumentDate,DocumentName3","","","");

	If TypeOf(Data.ARAPDocument) = Type("CatalogRef.CounterpartyContracts") Then
		
		Result.DocumentName3 = String(Data.ARAPDocument);
		
	ElsIf Data.ARAPDocument <> Undefined And Not Data.ARAPDocument.IsEmpty() Then

		DocumentName = Data.ARAPDocument.Metadata().Name;
		
		PresentationForReconciliation = "";
		PresentationsOfDocuments.Property(DocumentName, PresentationForReconciliation);
		Result.Insert("PresentationForReconciliation", PresentationForReconciliation);
		PrintFormDescription = NamesForPrinting[Data.ARAPDocument];
		If ValueIsFilled(Data.SourceDocumentName) Then // filled in only at incoming
			Result.DocumentName3 = Data.SourceDocumentName;
		ElsIf PrintFormDescription <> Undefined Then
			Result.DocumentName3 = AbbreviationsOfPrintedForms(PrintFormDescription);
		Else
			Result.DocumentName3 = PresentationForReconciliation;
		EndIf;
		
		// if the "bx Number." is filled in, then we consider that the customer issued the return and display it
		// if it is not filled in, then we consider that the seller issued the return and display the internal number
		If ValueIsFilled(Data.DocumentNumber) Then
			If DocumentName = "BankAccountIssue"
				Or DocumentName = "ReturnOfGoodsFromCustomer" Then
				NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(Data.DocumentNumber,, True);
			ElsIf IncomingInvoices.Property(DocumentName) Then
				NumberForPrinting = RemoveLeadingZeros(Data.SourceDocumentNumber);
			Else
				NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(Data.DocumentNumber);
			EndIf;
			Result.DocumentNumber = NumberForPrinting;
		EndIf;
		
		If ValueIsFilled(Data.DocumentDate) Then
			// if the "Date bx." is filled in, then we consider that the customer issued the return and output it
			// if it is not filled in, then we consider that the return was issued by the seller and output the date of the document
			// for the rest of the incoming documents, output "Date bx." specified in the document
			If IncomingInvoices.Property(DocumentName)
				And Not DocumentName = "ReturnOfGoodsFromCustomer" Then
				Result.DocumentDate = Data.SourceDocumentDate;
			Else
				Result.DocumentDate = Data.DocumentDate;
			EndIf;
		EndIf;
		
	EndIf;

	Return Result;

EndFunction

// Submission of documents.
// 
// Returns:
//  Structure - Presentations Of Documents:
//    * Key - String - The name of the document metadata.
//    * Value - String - presentation of the document.
//  
Function PresentationsOfDocuments() Export
	
	TypesOfCounterpartyDocuments = New Structure;
	
	TypesOfCounterpartyDocuments.Insert("ExpenseReport",                        NStr("vi = 'Phiếu chi';
																					|ru = 'Расходный кассовый ордер';
																					|en = 'Outgoing payment — Cash account'; fa = 'پرداخت خروجی — صندوق';
																					|it = 'Расходный кассовый ордер';
																					|pl = 'Asygnata kasowa rozchodowa';
																					|tr = 'Giden ödeme - kasa hesabı'"));
	TypesOfCounterpartyDocuments.Insert("CustomerInvoiceServices",                   NStr("vi = 'Biên bản nghiệm thu công việc';
																							|ru = 'Акт выполненных работ';
																							|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
																							|it = 'Акт выполненных работ';
																							|pl = 'Protokół wykonanych prac';
																							|tr = 'Müşteri faturası - Hizmetler'"));
	TypesOfCounterpartyDocuments.Insert("ElectronicTicketTransaction",           NStr("vi = 'Vé điện tử';
																						|ru = 'Электронный билет';
																						|en = 'Electronic ticket'; fa = 'بلیت الکترونیکی';
																						|it = 'Biglietto elettronico';
																						|pl = 'Bilet elektroniczny';
																						|tr = 'Elektronik bilet'"));
	TypesOfCounterpartyDocuments.Insert("OBEntry",                          NStr("vi = 'Điều chỉnh công nợ';
																				|ru = 'Корректировка задолженности';
																				|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																				|it = 'Корректировка задолженности';
																				|pl = 'Korekta zadłużenia';
																				|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("OBEntryARAP",            NStr("vi = 'Điều chỉnh công nợ';
																		|ru = 'Корректировка задолженности';
																		|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																		|it = 'Корректировка задолженности';
																		|pl = 'Korekta zadłużenia';
																		|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("OBEntryFinancialInstruments",  NStr("vi = 'Điều chỉnh công nợ';
																			|ru = 'Корректировка задолженности';
																			|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																			|it = 'Корректировка задолженности';
																			|pl = 'Korekta zadłużenia';
																			|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("ARAPSettlement",              NStr("vi = 'Đối trừ công nợ';
																			|ru = 'Взаимозачет задолженности';
																			|en = 'AR/AP offset'; fa = 'تهاتر دریافتنی/پرداختنی';
																			|it = 'Взаимозачет задолженности';
																			|pl = 'Rozliczenie wzajemne zadłużenia';
																			|tr = 'Alacak/Borç mahsubu'"));
	TypesOfCounterpartyDocuments.Insert("IntercompanyGoodsReturn",      NStr("vi = 'Nhận hàng bán bị trả lại';
																			|ru = 'Возврат товаров';
																			|en = 'Return of goods'; fa = 'برگشت کالا';
																			|it = 'Возврат товаров';
																			|pl = 'Zwrot towarów';
																			|tr = 'Ürün iadesi'"));
	TypesOfCounterpartyDocuments.Insert("ReturnOfGoodsFromCustomer",               NStr("vi = 'Nhận hàng bán bị trả lại';
																						|ru = 'Возврат товаров';
																						|en = 'Return of goods'; fa = 'برگشت کالا';
																						|it = 'Возврат товаров';
																						|pl = 'Zwrot towarów';
																						|tr = 'Ürün iadesi'"));
	TypesOfCounterpartyDocuments.Insert("ReturnOfGoodsToVendor",              NStr("vi = 'Nhận hàng bán bị trả lại';
																					|ru = 'Возврат товаров';
																					|en = 'Return of goods'; fa = 'برگشت کالا';
																					|it = 'Возврат товаров';
																					|pl = 'Zwrot towarów';
																					|tr = 'Ürün iadesi'"));
	TypesOfCounterpartyDocuments.Insert("ReturnablePackagingRedemptionByCustomer",           NStr("vi = 'Mua lại bao bì luân chuyển';
																									|ru = 'Выкуп возвратной тары';
																									|en = 'Customer invoice — returnable packaging'; fa = 'فاکتور مشتری — بسته‌بندی برگشتی';
																									|it = 'Выкуп возвратной тары';
																									|pl = 'Wykup tary zwrotnej';
																									|tr = 'Iade ambalajların itfası'"));
	TypesOfCounterpartyDocuments.Insert("RedemptionOfReturnablePackagingFromVendor",        NStr("vi = 'Mua lại bao bì luân chuyển';
																								|ru = 'Выкуп возвратной тары';
																								|en = 'Customer invoice — returnable packaging'; fa = 'فاکتور مشتری — بسته‌بندی برگشتی';
																								|it = 'Выкуп возвратной тары';
																								|pl = 'Wykup tary zwrotnej';
																								|tr = 'Iade ambalajların itfası'"));
	TypesOfCounterpartyDocuments.Insert("RedemptionOfGoodsFromStorage",        NStr("vi = 'Mua';
																					|ru = 'Приобретение';
																					|en = 'Purchase'; fa = 'خرید';
																					|it = 'Приобретение';
																					|pl = 'Purchase';
																					|tr = 'Satın alma'"));
	TypesOfCounterpartyDocuments.Insert("RedemptionOfGoodsByCustodian",                NStr("vi = 'Bán hàng';
																							|ru = 'Реализация';
																							|en = 'Sales'; fa = 'فروش';
																							|it = 'Реализация';
																							|pl = 'Sales';
																							|tr = 'Satış'"));
	TypesOfCounterpartyDocuments.Insert("ARAPAdjustment",            NStr("vi = 'Điều chỉnh công nợ';
																			|ru = 'Корректировка задолженности';
																			|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																			|it = 'Корректировка задолженности';
																			|pl = 'Korekta zadłużenia';
																			|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("ARAPAdjustmentFinancialInstruments", NStr("vi = 'Điều chỉnh công nợ';
																					|ru = 'Корректировка задолженности';
																					|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																					|it = 'Корректировка задолженности';
																					|pl = 'Korekta zadłużenia';
																					|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("PurchaseAdjustment",             NStr("vi = 'Điều chỉnh công nợ';
																				|ru = 'Корректировка задолженности';
																				|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																				|it = 'Корректировка задолженности';
																				|pl = 'Korekta zadłużenia';
																				|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("SaleAdjustment",               NStr("vi = 'Điều chỉnh công nợ';
																			|ru = 'Корректировка задолженности';
																			|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																			|it = 'Корректировка задолженности';
																			|pl = 'Korekta zadłużenia';
																			|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("RegisterAdjustment",                NStr("vi = 'Điều chỉnh công nợ';
																					|ru = 'Корректировка задолженности';
																					|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
																					|it = 'Корректировка задолженности';
																					|pl = 'Korekta zadłużenia';
																					|tr = 'Borç düzeltmesi'"));
	TypesOfCounterpartyDocuments.Insert("LoanAndDepositInterestCharge",          NStr("vi = 'Tính toán';
																						|ru = 'Начисление';
																						|en = 'Accrual'; fa = 'محاسبه';
																						|it = 'Начисление';
																						|pl = 'Accrual';
																						|tr = 'Tahakkuk'"));
	TypesOfCounterpartyDocuments.Insert("PaymentCardTransaction",              NStr("vi = 'Giao dịch theo thẻ thanh toán';
																					|ru = 'Эквайринговая операция';
																					|en = 'Acquiring transaction'; fa = 'معامله پذیرندگی';
																					|it = 'Эквайринговая операция';
																					|pl = 'Operacja acquiringu';
																					|tr = 'PoS işlemi'"));
	TypesOfCounterpartyDocuments.Insert("YandexCheckoutOperation",                 NStr("vi = 'Giao dịch theo thẻ thanh toán';
																						|ru = 'Эквайринговая операция';
																						|en = 'Acquiring transaction'; fa = 'معامله پذیرندگی';
																						|it = 'Эквайринговая операция';
																						|pl = 'Operacja acquiringu';
																						|tr = 'PoS işlemi'"));
	TypesOfCounterpartyDocuments.Insert("ConsignmentReportFromCustomer",                     NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																									|ru = 'Отчет комитенту';
																									|en = 'Consignment notification'; fa = 'اعلان امانی';
																									|it = 'Отчет комитенту';
																									|pl = 'Raport dla komitenta';
																									|tr = 'Konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("WriteOffReportFromCommissionAgent",            NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																							|ru = 'Отчет комитенту';
																							|en = 'Consignment notification'; fa = 'اعلان امانی';
																							|it = 'Отчет комитенту';
																							|pl = 'Raport dla komitenta';
																							|tr = 'Konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("ConsignmentReportToVendor",                        NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																								|ru = 'Отчет комитенту';
																								|en = 'Consignment notification'; fa = 'اعلان امانی';
																								|it = 'Отчет комитенту';
																								|pl = 'Raport dla komitenta';
																								|tr = 'Konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("PurchasingReportToConsignorPrincipal",               NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																									|ru = 'Отчет комитенту';
																									|en = 'Consignment notification'; fa = 'اعلان امانی';
																									|it = 'Отчет комитенту';
																									|pl = 'Raport dla komitenta';
																									|tr = 'Konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("PurchaseInvoiceConsignmentStockLost",               NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																									|ru = 'Отчет комитенту';
																									|en = 'Consignment notification'; fa = 'اعلان امانی';
																									|it = 'Отчет комитенту';
																									|pl = 'Raport dla komitenta';
																									|tr = 'Konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("CommissionReportIntercompany",     NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																				|ru = 'Отчет комитенту';
																				|en = 'Consignment notification'; fa = 'اعلان امانی';
																				|it = 'Отчет комитенту';
																				|pl = 'Raport dla komitenta';
																				|tr = 'Konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("CommissionWriteOffReportIntercompany",NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																					|ru = 'Отчет комитенту';
																					|en = 'Consignment notification'; fa = 'اعلان امانی';
																					|it = 'Отчет комитенту';
																					|pl = 'Raport dla komitenta';
																					|tr = 'Konsinye bildirimi'"));
	TypesOfCounterpartyDocuments.Insert("CustomerInvoiceIntercompany",     NStr("vi = 'Chuyển giao hàng hóa';
																				|ru = 'Передача товаров';
																				|en = 'Goods transfer'; fa = 'انتقال کالا';
																				|it = 'Передача товаров';
																				|pl = 'Transfer towarów';
																				|tr = 'Ürünlerin transferi'"));
	TypesOfCounterpartyDocuments.Insert("BankAccountReceiptNote", NStr("vi = 'Ủy nhiệm chi';
																		|ru = 'Платежное поручение';
																		|en = 'Payment order'; fa = 'دستور پرداخت';
																		|it = 'Платежное поручение';
																		|pl = 'Zlecenie płatnicze';
																		|tr = 'Ödeme emri'"));
	TypesOfCounterpartyDocuments.Insert("VendorInvoice",              NStr("vi = 'Mua';
																			|ru = 'Приобретение';
																			|en = 'Purchase'; fa = 'خرید';
																			|it = 'Приобретение';
																			|pl = 'Purchase';
																			|tr = 'Satın alma'"));
	TypesOfCounterpartyDocuments.Insert("VendorInvoiceServicesAndAssets",        NStr("vi = 'Mua';
																						|ru = 'Приобретение';
																						|en = 'Purchase'; fa = 'خرید';
																						|it = 'Приобретение';
																						|pl = 'Purchase';
																						|tr = 'Satın alma'"));
	TypesOfCounterpartyDocuments.Insert("CashAccountReceiptNote",                NStr("vi = 'Phiếu thu 01-TT';
																						|ru = 'Приходный кассовый ордер';
																						|en = 'Incoming payment — Cash account'; fa = 'دریافت — صندوق';
																						|it = 'Приходный кассовый ордер';
																						|pl = 'Asygnata kasowa przychodowa';
																						|tr = 'Gelen ödeme - kasa hesabı'"));
	TypesOfCounterpartyDocuments.Insert("CashVoucher",                NStr("vi = 'Phiếu chi';
																			|ru = 'Расходный кассовый ордер';
																			|en = 'Outgoing payment — Cash account'; fa = 'پرداخت خروجی — صندوق';
																			|it = 'Расходный кассовый ордер';
																			|pl = 'Asygnata kasowa rozchodowa';
																			|tr = 'Giden ödeme - kasa hesabı'"));
	TypesOfCounterpartyDocuments.Insert("ExchangeDifferenceCalculation",                  NStr("vi = 'Chênh lệch tỷ giá';
																								|ru = 'Курсовые разницы';
																								|en = 'Exchange differences'; fa = 'تفاوت‌های ارزی';
																								|it = 'Курсовые разницы';
																								|pl = 'Różnice kursowe';
																								|tr = 'Döviz kuru farkları'"));
	TypesOfCounterpartyDocuments.Insert("CustomerInvoice",                NStr("vi = 'Bán hàng';
																				|ru = 'Реализация';
																				|en = 'Sales'; fa = 'فروش';
																				|it = 'Реализация';
																				|pl = 'Sales';
																				|tr = 'Satış'"));
	TypesOfCounterpartyDocuments.Insert("CustomerInvoiceServicesAndAssets",          NStr("vi = 'Bán hàng';
																							|ru = 'Реализация';
																							|en = 'Sales'; fa = 'فروش';
																							|it = 'Реализация';
																							|pl = 'Sales';
																							|tr = 'Satış'"));
	TypesOfCounterpartyDocuments.Insert("BankAccountIssue",    NStr("vi = 'Ủy nhiệm chi';
																	|ru = 'Платежное поручение';
																	|en = 'Payment order'; fa = 'دستور پرداخت';
																	|it = 'Платежное поручение';
																	|pl = 'Zlecenie płatnicze';
																	|tr = 'Ödeme emri'"));
	TypesOfCounterpartyDocuments.Insert("ReversingEntry",                                NStr("vi = 'Đảo ngược';
																								|ru = 'Сторно';
																								|en = 'Storno'; fa = 'استورنو';
																								|it = 'Сторно';
																								|pl = 'Storno';
																								|tr = 'İptal'"));
	TypesOfCounterpartyDocuments.Insert("InvoiceIssued",                   NStr("vi = 'Hóa đơn GTGT';
																				|ru = 'Счет-фактура';
																				|en = 'Tax invoice'; fa = 'فاکتور مالیاتی';
																				|it = 'Счет-фактура';
																				|pl = 'Tax invoice';
																				|tr = 'Vergi faturası'"));
	TypesOfCounterpartyDocuments.Insert("VendorInvoiceReceived",                 NStr("vi = 'Hóa đơn GTGT';
																						|ru = 'Счет-фактура';
																						|en = 'Tax invoice'; fa = 'فاکتور مالیاتی';
																						|it = 'Счет-фактура';
																						|pl = 'Tax invoice';
																						|tr = 'Vergi faturası'"));
	TypesOfCounterpartyDocuments.Insert("InvoiceReceivedByTaxAgent",   NStr("vi = 'Hóa đơn GTGT';
																			|ru = 'Счет-фактура';
																			|en = 'Tax invoice'; fa = 'فاکتور مالیاتی';
																			|it = 'Счет-фактура';
																			|pl = 'Tax invoice';
																			|tr = 'Vergi faturası'"));
	TypesOfCounterpartyDocuments.Insert("CCDImport",            NStr("vi = 'Tờ khai hải quan';
																	|ru = 'Таможенная декларация';
																	|en = 'Customs declaration'; fa = 'اظهارنامه گمرکی';
																	|it = 'Таможенная декларация';
																	|pl = 'Deklaracja celna';
																	|tr = 'Gümrük beyannamesi'"));
	
	TypesOfCounterpartyDocuments.Insert("VendorInvoiceLeasedAssets",                   NStr("vi = 'Mua lại TSCĐ đã thuê';
																							|ru = 'Выкуп арендованных ОС';
																							|en = 'Vendor invoice — Leased assets'; fa = 'فاکتور تأمین‌کننده — دارایی‌های اجاره‌ای';
																							|it = 'Выкуп арендованных ОС';
																							|pl = 'Wykup wynajmowanych środków trwałych';
																							|tr = 'Kiralanan sabit kıymetlerin itfası'"));
	TypesOfCounterpartyDocuments.Insert("SubcontractorReport2_5",                 NStr("vi = 'Bảng kê hàng hóa của bên nhận gia công';
																						|ru = 'Отчет переработчика';
																						|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
																						|it = 'Отчет переработчика';
																						|pl = 'Raport przetwórcy';
																						|tr = 'Fason  üretici raporu'"));
	TypesOfCounterpartyDocuments.Insert("SigningOfLeaseContract",              NStr("vi = 'Thu tiền';
																					|ru = 'Поступление';
																					|en = 'Receipt'; fa = 'دریافت';
																					|it = 'Поступление';
																					|pl = 'Receipt';
																					|tr = 'Giriş'"));
	TypesOfCounterpartyDocuments.Insert("ReceivingLeaseServices",              NStr("vi = 'In biên bản / hóa đơn GTGT';
																					|ru = 'Акт';
																					|en = 'Statement'; fa = 'صورتحساب';
																					|it = 'Акт';
																					|pl = 'Statement';
																					|tr = 'Tutanak'"));

	TypesOfCounterpartyDocuments.Insert("ReportToMaterialProvider2_5",                      NStr("vi = 'Báo cáo dành cho người đặt gia công';
																								|ru = 'Отчет давальцу';
																								|en = 'Consumption report — Subcontracting services delivered'; fa = 'گزارش مصرف — خدمات پیمانکاری فرعی ارائه‌شده';
																								|it = 'Отчет давальцу';
																								|pl = 'Raport dla właściciela surowców';
																								|tr = 'Tüketim raporu-Verilen fason hizmetleri'"));
	TypesOfCounterpartyDocuments.Insert("ConsumptionReportSubcontractingServicesDeliveredIntercompany",       NStr("vi = 'Báo cáo dành cho người đặt gia công';
																													|ru = 'Отчет давальцу';
																													|en = 'Consumption report — Subcontracting services delivered'; fa = 'گزارش مصرف — خدمات پیمانکاری فرعی ارائه‌شده';
																													|it = 'Отчет давальцу';
																													|pl = 'Raport dla właściciela surowców';
																													|tr = 'Tüketim raporu-Verilen fason hizmetleri'"));
	Return TypesOfCounterpartyDocuments;
	
EndFunction

Function AbbreviationsOfPrintedForms(NameOfPrintForm)
	
	AbbreviationsOfPrintedForms = New Map;
	
	AbbreviationsOfPrintedForms.Insert(
		NStr("vi = 'Chứng từ chuyển giao đa năng';
			|ru = 'Универсальный передаточный документ';
			|en = 'Universal transfer document'; fa = 'Universal transfer document';
			|it = 'Universal transfer document';
			|pl = 'Universal transfer document';
			|tr = 'Evrensel Transfer Belgesi'"),
		NStr("vi = 'Chứng từ chuyển giao đa năng';
			|ru = 'УПД';
			|en = 'UTD'; fa = 'UTD';
			|it = 'UTD';
			|pl = 'UTD';
			|tr = 'Evrensel Transfer Belgesi'"));
	AbbreviationsOfPrintedForms.Insert(
		NStr("vi = 'Chứng từ điều chỉnh đa năng';
			|ru = 'Универсальный корректировочный документ';
			|en = 'Universal adjustment document'; fa = 'Universal adjustment document';
			|it = 'Universal adjustment document';
			|pl = 'Universal adjustment document';
			|tr = 'Evrensel Transfer Belgesi'"),
		NStr("vi = 'Chứng từ điều chỉnh đa năng';
			|ru = 'УКД';
			|en = 'UAD'; fa = 'UAD';
			|it = 'UAD';
			|pl = 'UAD';
			|tr = 'Evrensel Transfer Belgesi'"));
		
	Abbr = AbbreviationsOfPrintedForms[NameOfPrintForm];
	If Abbr = Undefined Then
		Abbr = NameOfPrintForm;
	EndIf;
	
	Return Abbr;
	
EndFunction

// Returns:
//  Structure - Presentations Of Documents:
//    * Key - String - The name of the document metadata.
//    * Value - String - The value is not filled in.
// 
Function IncomingInvoices() Export
	
	TypesOfCounterpartyDocuments = New Structure;
	
	TypesOfCounterpartyDocuments.Insert("IntercompanyGoodsReturn");
	TypesOfCounterpartyDocuments.Insert("ReturnOfGoodsFromCustomer");
	TypesOfCounterpartyDocuments.Insert("RedemptionOfReturnablePackagingFromVendor");
	TypesOfCounterpartyDocuments.Insert("RedemptionOfGoodsFromStorage");
	TypesOfCounterpartyDocuments.Insert("PurchaseAdjustment");
	TypesOfCounterpartyDocuments.Insert("ElectronicTicketTransaction");
	TypesOfCounterpartyDocuments.Insert("ConsignmentReportFromCustomer");
	TypesOfCounterpartyDocuments.Insert("WriteOffReportFromCommissionAgent");
	TypesOfCounterpartyDocuments.Insert("PlatonSystemOperatorSReport");
	TypesOfCounterpartyDocuments.Insert("CommissionReportIntercompany");
	TypesOfCounterpartyDocuments.Insert("CommissionWriteOffReportIntercompany");
	TypesOfCounterpartyDocuments.Insert("VendorInvoice");
	TypesOfCounterpartyDocuments.Insert("VendorInvoiceServicesAndAssets");
	TypesOfCounterpartyDocuments.Insert("VendorInvoiceReceived");
	TypesOfCounterpartyDocuments.Insert("InvoiceReceivedByTaxAgent");
	TypesOfCounterpartyDocuments.Insert("SubcontractorReport2_5");
	TypesOfCounterpartyDocuments.Insert("SigningOfLeaseContract");
	TypesOfCounterpartyDocuments.Insert("ReceivingLeaseServices");
	TypesOfCounterpartyDocuments.Insert("LeaseTermination");

	Return TypesOfCounterpartyDocuments;
	
EndFunction

// Returns:
//  Structure - Presentations Of Documents:
//    * Key - String - The name of the document metadata.
//    * Value - String - The value is not filled in.
//
Function OutgoingInvoices() Export
	
	TypesOfCounterpartyDocuments = New Structure;
	
	TypesOfCounterpartyDocuments.Insert("CustomerInvoiceServices");
	TypesOfCounterpartyDocuments.Insert("IntercompanyGoodsReturn");
	TypesOfCounterpartyDocuments.Insert("ReturnOfGoodsToVendor");
	TypesOfCounterpartyDocuments.Insert("ReturnablePackagingRedemptionByCustomer");
	TypesOfCounterpartyDocuments.Insert("RedemptionOfGoodsByCustodian");
	TypesOfCounterpartyDocuments.Insert("SalesBookEntry");
	TypesOfCounterpartyDocuments.Insert("SaleAdjustment");
	TypesOfCounterpartyDocuments.Insert("SourceDocument");
	TypesOfCounterpartyDocuments.Insert("CustomerInvoiceIntercompany");
	TypesOfCounterpartyDocuments.Insert("CustomerInvoice");
	TypesOfCounterpartyDocuments.Insert("CustomerInvoiceServicesAndAssets");
	
	Return TypesOfCounterpartyDocuments;
	
EndFunction

Function RemoveLeadingZeros(String)
	
	Result = TrimAll(String);
	While Left(Result, 1) = "0" Or Left(Result, 1) = "-" Do 
		Result = Mid(Result, 2);
	EndDo;
	Return Result;
	
EndFunction

Function PrintingDocuments(ObjectsArray)
	
	QueryText = 
	"SELECT DISTINCT
	|	NestedQuery.Ref AS Ref,
	| 	NestedQuery.PointInTime AS PointInTime
	|FROM
	|	(SELECT DISTINCT
	|		CalculationsForDocument.Ref AS Ref,
	|		CalculationsForDocument.Ref.PointInTime AS PointInTime
	|	FROM
	|		Document.ARAPReconciliation2_5_11.SummaryRecords AS CalculationsForDocument
	|	WHERE
	|		CalculationsForDocument.Ref IN (&ReconciliationDocuments)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Reconciliation.Ref,
	|		Reconciliation.Ref.PointInTime AS PointInTime
	|	FROM
	|		Document.ARAPReconciliation2_5_11 AS Reconciliation
	|		LEFT JOIN Document.ARAPReconciliation2_5_11.SummaryRecords AS TSSummaryRecords
	|			ON Reconciliation.Ref = TSSummaryRecords.Ref
	|	WHERE
	|		Reconciliation.Ref IN (&ReconciliationDocuments)
	|		AND TSSummaryRecords.Ref IS NULL) AS NestedQuery
	|
	|ORDER BY
	| 	NestedQuery.PointInTime";
	Query = New Query(QueryText);
	
	Query.SetParameter("ReconciliationDocuments", ObjectsArray);
	
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return Result;
	
EndFunction

#EndRegion

// Returns data for the formation of the printed form of the UPD
//
// Parameters:
//	PrintParameters - Structure - parameters.
//	ObjectsArray - Array of DocumentRef.ARAPReconciliation2_5_11 - links to documents for which you need
//																		to get data.
//
// Returns:
//	Structure - a collection of data used when printing the UPD, containing the following properties:
//		* HeaderResults - QueryResult - general data of the invoice.
//		* ResultForTabularPart - QueryResult - data of the tabular part of the invoice.
//
Function GetDataForPrintedFormOfUPD(PrintParameters, ObjectsArray) Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	///////////////////////////////////////////////////////////
	// General Attributes.
	|	DocumentsData.Ref AS Ref,
	|	DocumentsData.Date AS DocumentDate,
	|	DocumentsData.ModeOfARAPTotalsReconciliation AS ModeOfARAPTotalsReconciliation,
	|	DocumentsData.Status AS Status,
	|	"""" AS SpecialCircumstanceCode,
	|
	///////////////////////////////////////////////////////////
	// Reconciliation report of mutual settlements, sender's information (Document).
	//
	// The start date of the reconciliation period for mutual settlements. Datanachalaperiodesverks = datanachper.
	|	DocumentsData.BeginOfPeriod AS StartDateOfReconciliationPeriod,
	// The end date of the reconciliation period for mutual settlements. The End date of the Reconciliation period = DateOcPer.
	|	DocumentsData.EndOfPeriod AS EndDateOfReconciliationPeriod,
	// Number of the reconciliation report. Number documents = A terrorist attack.
	|	DocumentsData.Number AS DocumentNumber,
	///////////////////////////////////////////////////////////
	// Information of the document, except for the information in the table of the reconciliation report of mutual settlements (SvDokKrAct).
	// Currency code. Code currencies = Codoq
	|	DocumentsData.Currency.Code AS CurrencyCode_,
	// Information about the sender. Sender = SvOtpr.
	|	DocumentsData.Organization AS Sender,
	// Information about the recipient. Recipient = SvPol.
	|	DocumentsData.Counterparty AS Recipient,
	|
	///////////////////////////////////////////////////////////
	// Information of the table of the act of reconciliation of mutual settlements (TablAkt).
	// The amount of the balance at the beginning of the debit reconciliation period. SaldonAnAchaloPeriodaDebet = SaldonAchDeb.
	|	SUM(ISNULL(FinalDocumentEntries.OpeningBalanceDr, 0)) AS BalanceAtBeginningOfDebitPeriod,
	// The amount of the balance at the beginning of the reconciliation period is credit. SaldonAnAchaloPeriodaCredit = SaldonAchKr.
	|	SUM(ISNULL(FinalDocumentEntries.OpeningBalanceCr, 0)) AS BalanceAtBeginningOfLoanPeriod,
	// Debit turnover. Werewolf Twitter = Werewolf Deb.
	|	SUM(ISNULL(FinalDocumentEntries.TurnoverDr, 0)) AS DebitTurnover,
	// Loan turnover. Werewolf Credit = Werewolf.
	|	SUM(ISNULL(FinalDocumentEntries.TurnoverCr, 0)) AS LoanTurnover,
	// Loan turnover. SaldonAkOnetsPeriodaDebet = Saldokondeb.
	|	SUM(ISNULL(FinalDocumentEntries.ClosingBalanceDr, 0)) AS BalanceAtEndOfDebitPeriod,
	// The amount of the balance at the end of the reconciliation period is credit. SaldonAkOnetsPeriodaCredit = Saldokonkr.
	|	SUM(ISNULL(FinalDocumentEntries.ClosingBalanceCr, 0)) AS BalanceAtEndOfLoanPeriod
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS DocumentsData
	|		LEFT JOIN Document.ARAPReconciliation2_5_11.SummaryRecords AS FinalDocumentEntries
	|		ON DocumentsData.Ref = FinalDocumentEntries.Ref
	|WHERE
	|	DocumentsData.Ref IN (&ObjectsArray)
	|
	|GROUP BY
	|	DocumentsData.Ref,
	|	DocumentsData.Currency,
	|	DocumentsData.Organization,
	|	DocumentsData.Counterparty,
	|	DocumentsData.BeginOfPeriod,
	|	DocumentsData.EndOfPeriod,
	|	DocumentsData.Number
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	// Information of the table of the act of reconciliation of mutual settlements (TablAkt).
	|SELECT
	// The amount of the balance at the beginning of the debit reconciliation period. SaldonAnAchaloPeriodaDebet = SaldonAchDeb.
	|	SUM(SummaryRecords.OpeningBalanceDr) AS BalanceAtBeginningOfDebitPeriod,
	// The amount of the balance at the beginning of the reconciliation period is credit. SaldonAnAchaloPeriodaCredit = SaldonAchKr.
	|	SUM(SummaryRecords.OpeningBalanceCr) AS BalanceAtBeginningOfLoanPeriod,
	// Debit turnover. Werewolf Twitter = Werewolf Deb.
	|	SUM(SummaryRecords.TurnoverDr) AS DebitTurnover,
	// Loan turnover. Werewolf Credit = Werewolf.
	|	SUM(SummaryRecords.TurnoverCr) AS LoanTurnover,
	// Loan turnover. SaldonAkOnetsPeriodaDebet = Saldokondeb.
	|	SUM(SummaryRecords.ClosingBalanceDr) AS BalanceAtEndOfDebitPeriod,
	// The amount of the balance at the end of the reconciliation period is credit. SaldonAkOnetsPeriodaCredit = Saldokonkr.
	|	SUM(SummaryRecords.ClosingBalanceCr) AS BalanceAtEndOfLoanPeriod,
	|
	///////////////////////////////////////////////////////////
	// information about the Contract (dogsv).
	// id of the Contract in the sender's accounting system. Contract ID = IdDog.
	|	SummaryRecords.Contract AS ContractId,
	// description of the Contract in the sender's accounting system. Description of the agreement = Opistipdog.
	|	SummaryRecords.ContractName AS ContractDescription,
	// Contract number. Number of the contract = NomDog.
	|	SummaryRecords.ContractNumber AS ContractNumber,
	// date of the Contract (date of acceptance of the offer Contract). Contract Datadog = DataDog.
	|	SummaryRecords.ContractDate_ AS ContractDate_,
	|
	///////////////////////////////////////////////////////////
	// Information about the document.
	// Name of the document.
	|	CASE
	|		WHEN DetailedRecords.DocumentName3 IS NULL
	|			THEN """"
	|		WHEN DetailedRecords.DocumentName3 = """"
	|			THEN DetailedRecords.DocumentNameCounterparty
	|		ELSE
	|			DetailedRecords.DocumentName3
	|	END AS DocumentName3,
	// Document number. Nomerdocument = NomDoc.
	|	CASE
	|		WHEN DetailedRecords.DocumentNumber IS NULL
	|			THEN UNDEFINED
	|		WHEN DetailedRecords.DocumentNumber = """"
	|			THEN DetailedRecords.IncomingNumberCounterparty
	|		ELSE
	|			DetailedRecords.DocumentNumber
	|	END AS DocumentNumber,
	// Date of the document. Document datadocument = DataDoc.
	|	CASE
	|		WHEN DetailedRecords.DocumentDate IS NULL
	|			THEN UNDEFINED
	|		WHEN DetailedRecords.DocumentDate = DATETIME(1,1,1)
	|			THEN DetailedRecords.DocumentDateCounterparty
	|		ELSE
	|			DetailedRecords.DocumentDate
	|	END AS DocumentDate,
	// ID of the document in the sender's account system. Document ID = IdDoc.
	|	ISNULL(DetailedRecords.ARAPDocument, UNDEFINED) AS DocumentID,
	// Additional information. Dopinformation = DopInf.
	|	"""" AS AdditionalInformation_3,
	|
	///////////////////////////////////////////////////////////
	// Information about the operation (SwAper)
	// Row number of the table "Operation information". Ordinal number = NomStr.
	|	ISNULL(DetailedRecords.LineNumber, 0) AS SequenceNumber,
	// Date of the operation. Dataoperations = Dataoperator.
	|	CASE
	|		WHEN DetailedRecords.DocumentDate IS NULL
	|			THEN UNDEFINED
	|		WHEN DetailedRecords.DocumentDate = DATETIME(1,1,1)
	|			THEN DetailedRecords.DocumentDateCounterparty
	|		ELSE
	|			DetailedRecords.DocumentDate
	|	END AS DateOfTransaction,
	// Name of the operation. Operation Name = Nameper.
	|	CASE
	|		WHEN DetailedRecords.DocumentName3 IS NULL
	|			THEN """"
	|		WHEN DetailedRecords.DocumentName3 = """"
	|			THEN DetailedRecords.DocumentNameCounterparty
	|		ELSE
	|			DetailedRecords.DocumentName3
	|	END AS NameOfTheOperation,
	// The debit amount of the transaction. SummaDebet = SumDebet.
	|	SUM(ISNULL(DetailedRecords.DebitAmount, 0)) AS DebitAmount,
	// The amount of the operation credit. SummaCredit = SumCredit.
	|	SUM(ISNULL(DetailedRecords.LoanAmount_, 0)) AS LoanAmount_
	|FROM
	|	Document.ARAPReconciliation2_5_11.SummaryRecords AS SummaryRecords
	|		LEFT JOIN Document.ARAPReconciliation2_5_11.DetailedRecords AS DetailedRecords
	|		ON SummaryRecords.Ref = DetailedRecords.Ref
	|		AND SummaryRecords.PaymentType_ = DetailedRecords.PaymentType_
	|		AND SummaryRecords.Partner = DetailedRecords.Partner
	|		AND SummaryRecords.Contract = DetailedRecords.Contract
	|		AND SummaryRecords.ARAPObject = DetailedRecords.ARAPObject
	|WHERE
	|	SummaryRecords.Ref IN (&ObjectsArray)
	|
	|GROUP BY
	|	SummaryRecords.Ref,
	|	SummaryRecords.Contract,
	|	DocumentNumber,
	|	DetailedRecords.LineNumber,
	|	CAST(SummaryRecords.Contract AS Catalog.CounterpartyContracts),
	|	SummaryRecords.ContractNumber,
	|	SummaryRecords.ContractDate_,
	|	SummaryRecords.ContractName,
	|	CASE
	|		WHEN DetailedRecords.DocumentNumber IS NULL
	|			THEN UNDEFINED
	|		WHEN DetailedRecords.DocumentNumber = """"
	|			THEN DetailedRecords.IncomingNumberCounterparty
	|		ELSE
	|			DetailedRecords.DocumentNumber
	|	END,
	|	CASE
	|		WHEN DetailedRecords.DocumentDate IS NULL
	|			THEN UNDEFINED
	|		WHEN DetailedRecords.DocumentDate = DATETIME(1,1,1)
	|			THEN DetailedRecords.DocumentDateCounterparty
	|		ELSE
	|			DetailedRecords.DocumentDate
	|	END,
	|	CASE
	|		WHEN DetailedRecords.DocumentName3 IS NULL
	|			THEN """"
	|		WHEN DetailedRecords.DocumentName3 = """"
	|			THEN DetailedRecords.DocumentNameCounterparty
	|		ELSE
	|			DetailedRecords.DocumentName3
	|	END,
	|	DetailedRecords.ARAPDocument
	|
	|ORDER BY
	|	DateOfTransaction,
	|	DocumentDate,
	|	DocumentName3,
	|	DocumentNumber,
	|	SummaryRecords.Contract,
	|	DetailedRecords.ARAPDocument,
	|	SequenceNumber
	|;";
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Execute();
	
	ResultsArray			= Query.ExecuteBatch();
	HeaderResults			= ResultsArray[0];
	ResultForTabularPart	= ResultsArray[1];
	
	DataForPrint = New Structure;
	DataForPrint.Insert("HeaderResults",			HeaderResults);
	DataForPrint.Insert("ResultForTabularPart",	ResultForTabularPart);
	
	Return DataForPrint;
	
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region FormOfReconciliationWizard

#Region CreatingDocuments

Procedure CreateDocuments(Parameters, StorageAddress = "") Export
	
	CurrentDate  = CurrentSessionDate();
	CurrentTime = Hour(CurrentDate) * 3600 + Minute(CurrentDate) * 60 + Second(CurrentDate);
	
	DateOfDocuments = Parameters.DateOfDocuments;
	CalculationTable = Parameters.CalculationTable;
	SpentDocuments = New Array;
	
	FillingData = New Structure;
	FillingData.Insert("ReconciliationPeriod", Parameters.ReconciliationPeriod);
	FillingData.Insert("ContractsWithoutTurnover", Parameters.ContractsWithoutTurnover);
	FillingData.Insert("SplitByARAPTypes", Parameters.SplitByARAPTypes);
	FillingData.Insert("SplitByPartners", Parameters.SplitByPartners);
	FillingData.Insert("SplitByContracts", Parameters.SplitByContracts);
	FillingData.Insert("ModeOfARAPTotalsReconciliation", Parameters.ModeOfARAPTotalsReconciliation);
	FillingData.Insert("ReconciliationInCurrency", Parameters.ReconciliationInCurrency);
	FillingData.Insert("SetNewNumber_", False);
	
	LinkerSelection = New DataCompositionSettingsComposer;
	InitializeSettingsComposer(LinkerSelection,,Parameters.Filter_Settings);
	ArrayOfAllReconciliationDocuments = New Array;
	For Each TableRow In CalculationTable Do

		FillingData.Insert("DocumentData", TableRow);
		FillingData.Insert("Filter_Settings", LinkerSelection.GetSettings());
		FillingData.Insert("DescriptionOfOutgoingDocuments", TableRow.DescriptionOfOutgoingDocuments);
		
		If TableRow.CreateADocument Or TableRow.ChangeDocument = "DeleteCreateNew" Then
			
			DocumentObject = CreateDocument();
			
			DocumentObject.Date = DateOfDocuments + CurrentTime;
			
			FillingData.SetNewNumber_ = True;
			FillingData.Insert("DocumentData", TableRow);
			FillOutThisDocument(DocumentObject, FillingData);
			
			AddToExecutionProtocol(DocumentObject.Ref, "Creating", SpentDocuments); 
			ArrayOfAllReconciliationDocuments.Add(DocumentObject.Ref);
			
		EndIf;
		
		If TableRow.ThereAreDocuments Then

			DocumentObject = TableRow.ReconciliationDocument.GetObject();
			
			If TableRow.ChangeDocument = "DeleteCreateNew" Then
				
				Try
					DocumentObject.SetDeletionMark(True);
					AddToExecutionProtocol(DocumentObject.Ref, "MarkForDeletion_", SpentDocuments);
				Except
					ErrorText    = NStr("vi = 'Không thể đặt dấu xóa %Document%. %ErrorDescription%';
										|ru = 'Не удалось пометить на удаление %Document%. %ErrorDescription%';
										|en = 'Cannot mark %Document% for deletion. %ErrorDescription%'; fa = 'Cannot mark %Document% for deletion. %ErrorDescription%';
										|it = 'Не удалось пометить на удаление %Document%. %ErrorDescription%';
										|pl = 'Nie udało się zaznaczyć do usunięcia %Document%. %ErrorDescription%';
										|tr = '%Document% belgesi silme için işaretlenemedi.%ErrorDescription%'");
					ErrorText    = StrReplace(ErrorText, "%Document%",	DocumentObject);
					ErrorText    = StrReplace(ErrorText, "%ErrorDescription%", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
					
					Common.MessageToUser(ErrorText, DocumentObject.Ref);
				EndTry;
				
			ElsIf TableRow.ChangeDocument = "ReFill_" Then
				
				ArrayOfAllReconciliationDocuments.Add(TableRow.ReconciliationDocument);
				FillingData.SetNewNumber_ = False;
				FillOutThisDocument(DocumentObject, FillingData);
				
				AddToExecutionProtocol(DocumentObject.Ref, "Refilling", SpentDocuments);
				
			ElsIf TableRow.ChangeDocument = "DontChange" Then
				
				ArrayOfAllReconciliationDocuments.Add(TableRow.ReconciliationDocument);
				AddToExecutionProtocol(DocumentObject.Ref, "DontChange", SpentDocuments);
				
			EndIf;

		EndIf;

	EndDo;
	
	Result = New Structure;
	Result.Insert("ArrayOfAllReconciliationDocuments", ArrayOfAllReconciliationDocuments);
	Result.Insert("SpentDocuments", SpentDocuments);
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	DocumentObject - DocumentObject.ARAPReconciliation2_5_11 - The reconciliation object to fill in.
// 	FillingData - Structure - Structure of key reconciliation Attributes:
//     * DocumentData - Structure - Reconciliation header data:
//       * Organization - CatalogRef.Companies - Organization of the header.
//       * PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of calculations.
//       * Partner - CatalogRef.Partners - Partner of the cap.
//       * Counterparty - CatalogRef.Counterparties - Counterparty of the header.
//       * Contract - CatalogRef.CounterpartyContracts - The header agreement.
//     * ReconciliationPeriod - Structure - Structure of the reconciliation period:
//       * StartDate - Date - Start of the reconciliation period.
//       * EndDate - Date - End of the reconciliation period.
//
Procedure FillOutThisDocument(DocumentObject, FillingData)
	
	DocumentData = New Structure;
	DocumentData.Insert("Organization",              FillingData.DocumentData.Organization);
	DocumentData.Insert("PaymentType_",              FillingData.DocumentData.PaymentType_);
	DocumentData.Insert("Partner",                  FillingData.DocumentData.Partner);
	DocumentData.Insert("Counterparty",               FillingData.DocumentData.Counterparty);
	DocumentData.Insert("Contract",                  FillingData.DocumentData.Contract);
	DocumentData.Insert("Currency",                   FillingData.DocumentData.ReconciliationCurrency);
	DocumentData.Insert("BeginOfPeriod",            FillingData.ReconciliationPeriod.StartDate);
	DocumentData.Insert("EndOfPeriod",             FillingData.ReconciliationPeriod.EndDate);
	DocumentData.Insert("Status",                   Enums.StatusesOfARAPReconciliation.CreatedOn_);
	DocumentData.Insert("Filter_Settings",          FillingData.Filter_Settings);
	DocumentData.Insert("ContractsWithoutTurnover",      FillingData.ContractsWithoutTurnover);
	DocumentData.Insert("SplitByARAPTypes", FillingData.SplitByARAPTypes);
	DocumentData.Insert("SplitByPartners",     FillingData.SplitByPartners);
	DocumentData.Insert("SplitByContracts",     FillingData.SplitByContracts);
	DocumentData.Insert("ReconciliationInCurrency",            FillingData.ReconciliationInCurrency);
	DocumentData.Insert("ModeOfARAPTotalsReconciliation", FillingData.ModeOfARAPTotalsReconciliation);
	DocumentData.Insert("DescriptionOfOutgoingDocuments", FillingData.DescriptionOfOutgoingDocuments);
	
	SetPrivilegedMode(True);
	DocumentObject.Fill(DocumentData);
	SetPrivilegedMode(False);
	
	If FillingData.SetNewNumber_ Then
		DocumentObject.SetNewNumber();
	EndIf;
	
	If DocumentObject.CheckFilling() Then
		Try
			DocumentObject.Write(DocumentWriteMode.Posting);
		Except
			DocumentObject.Write(DocumentWriteMode.Write);
			ErrorText = NStr("vi = 'Không thể kết chuyển %Document%. %ErrorDescription%';
							|ru = 'Не удалось провести %Document%. %ErrorDescription%';
							|en = 'Cannot post %Document%. %ErrorDescription%'; fa = 'Cannot post %Document%. %ErrorDescription%';
							|it = 'Не удалось провести %Document%. %ErrorDescription%';
							|pl = 'Cannot post %Document%. %ErrorDescription%';
							|tr = '%Document% kaydedilemedi.%ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Document%",       DocumentObject);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Common.MessageToUser(ErrorText, DocumentObject.Ref);
		EndTry;
	Else
		DocumentObject.Write(DocumentWriteMode.Write);
		ErrorText = NStr("vi = 'Không thể kết chuyển %Document%.';
						|ru = 'Не удалось провести %Document%.';
						|en = 'Cannot post %Document%.'; fa = 'Cannot post %Document%.';
						|it = 'Не удалось провести %Document%.';
						|pl = 'Cannot post %Document%.';
						|tr = '%Document% kaydedilemedi.'");
		ErrorText = StrReplace(ErrorText, "%Document%", DocumentObject);
		Common.MessageToUser(ErrorText, DocumentObject.Ref);
	EndIf;

EndProcedure

// LongDesc
// 
// Parameters:
// 	ReconciliationDocument - DocumentRef.ARAPReconciliation2_5_11 - LongDesc
// 	Action - String - LongDesc
// 	SpentDocuments - Array of See ProtocolString -
//
Procedure AddToExecutionProtocol(ReconciliationDocument, Action, SpentDocuments)
	
	ProtocolString = ProtocolString();
	ProtocolString.ReconciliationDocument = ReconciliationDocument;
	ProtocolString.Action = Action;
	
	SpentDocuments.Add(ProtocolString);
	
EndProcedure

// The protocol line.
// 
// Returns:
//  Structure - LongDesc:
// * Action - String -
// * ReconciliationDocument - DocumentRef.ARAPReconciliation2_5_11 -
Function ProtocolString() Export
	
	Result = New Structure();
	Result.Insert("ReconciliationDocument", EmptyRef());
	Result.Insert("Action","");
	Return Result;
	
EndFunction

#EndRegion

#Region MarkForDeletion_

Procedure SetDeletionMark_(Parameters, StorageAddress = "") Export
	
	For Each Ref In Parameters.SelectedDocuments_ Do
		Object = Ref.GetObject();
		Object.SetDeletionMark(Not Object.DeletionMark);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region DocumentForm

Procedure DistributionOfCalculationsByDocuments(Parameters, StorageAddress = "") Export
	
	ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob(
		Parameters.EndOfPeriod,
		Parameters.CalculationAnalysts);
	
EndProcedure

#EndRegion

#Region Other

#Region FillInReconciliationDataForCalculations

// Parameters:
// 	DocumentData - DocumentObject.ARAPReconciliation2_5_11 - 
Procedure FillInCalculationData(DocumentData) Export
	
	CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(DocumentData.Organization, DocumentData.Date);
	RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(CompanyInformation, "FullDescr");
	CounterpartyInformation_  = PrintFormGeneration.InformationAboutLegalEntity(DocumentData.Counterparty, DocumentData.Date);
	CounterpartyName_ = PrintFormGeneration.OrganizationDescription(CounterpartyInformation_, "FullDescr");
	
	StructureOfParticipantsPresentations = New Structure;
	StructureOfParticipantsPresentations.Insert("RepresentationOfTheOrganization", RepresentationOfTheOrganization);
	StructureOfParticipantsPresentations.Insert("CounterpartyName_", CounterpartyName_);
	
	LinkerSelection = New DataCompositionSettingsComposer;
	InitializeSettingsComposer(LinkerSelection);
	If DocumentData.Filter_Settings <> Undefined Then
		Filter_Settings = DocumentData.Filter_Settings.Get();
		If Filter_Settings <> Undefined Then
			DataCompositionClientServer.CopyElements(LinkerSelection.Settings.Filter, Filter_Settings.Filter);
		EndIf;
	EndIf;
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BeginOfPeriod", DocumentData.BeginOfPeriod);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "EndOfPeriod", EndOfDay(DocumentData.EndOfPeriod));
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "Period", DocumentData.BeginOfPeriod);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ReceiveReconciliationDocuments", False);
	
	ContractReconciliationMode = DocumentData.ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByContracts;
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ContractReconciliationMode", ContractReconciliationMode);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByARAPTypes", DocumentData.SplitByARAPTypes);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByPartners", DocumentData.SplitByPartners);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByContracts", DocumentData.SplitByContracts);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ReconciliationInCurrency", DocumentData.ReconciliationInCurrency);
	
	DataCompositionClientServer.AddFilter(LinkerSelection.Settings, "Organization", DocumentData.Organization);
	If DocumentData.ReconciliationInCurrency Then
		DataCompositionClientServer.AddFilter(LinkerSelection.Settings, "Currency", DocumentData.Currency);
	EndIf;
	If GetFunctionalOption("UsePartnersAsCounterparties")
		And TypeOf(DocumentData.Counterparty) = Type("CatalogRef.Counterparties") Then
		Partner = Common.ObjectAttributeValue(DocumentData.Counterparty, "Partner");
		DataCompositionClientServer.AddFilter(LinkerSelection.Settings, "Partner", Partner);
	Else
		DataCompositionClientServer.AddFilter(LinkerSelection.Settings, "Counterparty", DocumentData.Counterparty);
	EndIf;
	
	If DocumentData.AdditionalProperties.Property("ForDebugging") Then
		ForDebugging = DocumentData.AdditionalProperties.ForDebugging;
		LinkerSelection.Settings.AdditionalProperties.Insert("ForDebugging", ForDebugging);
	EndIf;
	
	DCSResultTable = GetSettlements(LinkerSelection);
	
	CollapseCalculationsByDimensions(DocumentData, DCSResultTable);
	
	If LinkerSelection.Settings.AdditionalProperties.Property("ForDebugging") Then
		ForDebugging = LinkerSelection.Settings.AdditionalProperties.ForDebugging;
		DocumentData.AdditionalProperties.Insert("ForDebugging", ForDebugging);
		LinkerSelection.Settings.AdditionalProperties.Delete("ForDebugging");
	EndIf;
	
EndProcedure

Procedure CollapseCalculationsByDimensions(DocumentData, TableOfSettlements)
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentData.Organization);
	ReconciliationInLocalCurrency = ComplCurrency = DocumentData.Currency;
	ReconciliationUnderContracts = DocumentData.ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByContracts;
	Groups = "PaymentType_, Partner, Contract, ContractNumber, ContractDate_, ContractName";
	FieldOfCalculationObject = ?(ReconciliationUnderContracts,"",", ARAPObject");
	GroupFields = Groups + FieldOfCalculationObject;
	GroupingDetailedRecords = "DateOfTransaction, PaymentType_" + FieldOfCalculationObject + ", Partner, Contract, ARAPDocument, DocumentCurrency, DocumentAmount, DocumentNumber, DocumentDate";
	SummationFields = "OpeningBalanceDr, OpeningBalanceCr, TurnoverDr, TurnoverCr, ClosingBalanceDr, ClosingBalanceCr";
	SummationFieldsForDetailedRecords = "DebtAmount_, AmountPrepayment, DebitAmount, LoanAmount_";
	CorrectedDocumentsData = CorrectedDocumentsData(TableOfSettlements);
	
	Resources = New Map;
	Resources.Insert("OpeningBalanceDr", "OpeningBalanceDr");
	Resources.Insert("OpeningBalanceCr", "OpeningBalanceCr");
	Resources.Insert("TurnoverDr", "TurnoverDr");
	Resources.Insert("TurnoverCr", "TurnoverCr");
	Resources.Insert("ClosingBalanceDr", "ClosingBalanceDr");
	Resources.Insert("ClosingBalanceCr", "ClosingBalanceCr");
	Resources.Insert("DebtAmount_", "DebtAmount_");
	Resources.Insert("AmountPrepayment", "AmountPrepayment");
	Resources.Insert("DebitAmount", "DebitAmount");
	Resources.Insert("LoanAmount_", "LoanAmount_");
	Resources.Insert("DocumentAmount", "DocumentAmount");
	
	LocalResources = New Map;
	LocalResources.Insert("OpeningBalanceDr", "DrLocalOpeningBalance");
	LocalResources.Insert("OpeningBalanceCr", "InitialBalanceOfCrLocal");
	LocalResources.Insert("TurnoverDr", "DrLocalTurnover");
	LocalResources.Insert("TurnoverCr", "CrLocalTurnover");
	LocalResources.Insert("ClosingBalanceDr", "FinalBalanceOfDrLocal");
	LocalResources.Insert("ClosingBalanceCr", "FinalBalanceOfCrLocal");
	LocalResources.Insert("DebtAmount_", "DebtAmountLocal");
	LocalResources.Insert("AmountPrepayment", "PrepaymentAmountLocal_");
	LocalResources.Insert("DebitAmount", "LocalDebitAmount");
	LocalResources.Insert("LoanAmount_", "LocalCreditAmount");
	LocalResources.Insert("DocumentAmount", "DocumentAmount");
	
	DocumentData.SummaryRecords.Clear();
	DocumentData.DetailedRecords.Clear();
	SettlementDocuments_ = TableOfSettlements.UnloadColumn("ARAPDocument");
	If CorrectedDocumentsData.Count() > 0 Then
		CommonClientServer.SupplementArray(SettlementDocuments_,
			CorrectedDocumentsData.UnloadColumn("ARAPDocument"));
	EndIf;
	NamesOfPrintingDocuments = TMCommonUse.NamesOfElectronicDocumentsOrBasicPrintedForms(
		SettlementDocuments_);
	
	For Each CalculationLine_ In TableOfSettlements Do
		
		TSGroups = DocumentData.SummaryRecords; // TabularSection
		TSDetailedRecords = DocumentData.DetailedRecords; // TabularSection
		
		SumData = ResourcesValues(CalculationLine_, ?(ReconciliationInLocalCurrency,LocalResources,Resources));
		
		NewRow = TSGroups.Add();
		FillPropertyValues(NewRow, CalculationLine_, GroupFields + ", " + SummationFields);
		FillPropertyValues(NewRow, SumData);
		If Not ValueIsFilled(NewRow.Contract) Then
			NewRow.Contract = Undefined;
		EndIf;
		
		If CalculationLine_.OpeningBalance = 0 And SumData.ThereAreFilled Then
			If TypeOf(CalculationLine_.ARAPDocument) = Type("DocumentRef.ExchangeDifferenceCalculation") Then
				If Not ReconciliationInLocalCurrency Then
					Continue;
				EndIf;
				CalculationLine_.DocumentCurrency = ComplCurrency;
			EndIf;
			NewRow = TSDetailedRecords.Add();
			FillPropertyValues(NewRow, CalculationLine_, GroupingDetailedRecords + ", " + SummationFieldsForDetailedRecords);
			FillPropertyValues(NewRow, SumData);
			If Not ValueIsFilled(NewRow.Contract) Then
				NewRow.Contract = Undefined;
			EndIf;
			If NewRow.DocumentAmount < 0 Then
				NewRow.DocumentAmount = -NewRow.DocumentAmount;
			EndIf;
			If CalculationLine_.ReverseTransactionCorrection Then
				CorrectedDocument = CorrectedDocumentsData.Find(CalculationLine_.ARAPDocument, "DocumentStornoCorrections");
				DataForPrint = DataForPrint(CorrectedDocument, NamesOfPrintingDocuments, DocumentData.DescriptionOfOutgoingDocuments);
				If TypeOf(CalculationLine_.ARAPDocument) = Type("DocumentRef.ReversingEntry") Then
					NewRow.DocumentName3 = DocumentNameIsStorno();
				Else
					NewRow.DocumentName3 = NameOfCorrectionDocument();
					NewRow.DocumentAmount = CorrectedDocument.DocumentAmount;
				EndIf;
				NewRow.RelatedDocuments = StrTemplate(NStr("vi = '%1 số %2 ngày %3';
															|ru = '%1 №%2 от %3';
															|en = '%1 #%2, %3'; fa = '%1 #%2, %3';
															|it = '%1 №%2 del %3';
															|pl = '%1 nr %2 z dnia %3.';
															|tr = '%1 sayılı %2 tarihli %3'"), 
					DataForPrint.DocumentName3,
					DataForPrint.DocumentNumber,
					Format(DataForPrint.DocumentDate, "DLF=D"));
			Else
				DataForPrint = DataForPrint(CalculationLine_, NamesOfPrintingDocuments, DocumentData.DescriptionOfOutgoingDocuments);
				NewRow.DocumentNumber = DataForPrint.DocumentNumber;
				NewRow.DocumentDate = DataForPrint.DocumentDate;
				NewRow.DocumentName3 = DataForPrint.DocumentName3;
			EndIf;
		EndIf;
		
	EndDo;
	
	#Region FillingInTSCalculations
	GroupRecords = DocumentData.SummaryRecords.Unload();
	If GroupRecords.Count() > 0 Then
		GroupRecords.GroupBy(GroupFields, SummationFields);
	EndIf;
	DocumentData.SummaryRecords.Clear();
	
	DetailedRecords = DocumentData.DetailedRecords.Unload();
	If DetailedRecords.Count() > 0 Then
		DetailedRecords.GroupBy(GroupingDetailedRecords + ",RelatedDocuments,DocumentName3", SummationFieldsForDetailedRecords);
		OffsettingAdvance = New Array;
		For Each Record In DetailedRecords Do
			If TypeOf(Record.ARAPDocument) = Type("DocumentRef.ARAPSettlement")
				And Record.DebitAmount - Record.LoanAmount_ = 0 Then
				OffsettingAdvance.Add(Record);
			EndIf;
		EndDo;
		For Each Record In OffsettingAdvance Do
			DetailedRecords.Delete(Record);
		EndDo;
	EndIf;
	DocumentData.DetailedRecords.Load(DetailedRecords);
	
	For Each Group In GroupRecords Do
		
		ARAPAccountingClientServer.CalculateFinalBalanceOfDrCr(Group, DetailedRecords, ReconciliationUnderContracts);
		
		If Group.OpeningBalanceDr = 0 And Group.OpeningBalanceCr = 0
			And Group.TurnoverDr = 0 And Group.TurnoverCr = 0
			And Group.ClosingBalanceDr = 0 And Group.ClosingBalanceCr Then
			Continue;
		EndIf;
		
		NewRow = DocumentData.SummaryRecords.Add();
		FillPropertyValues(NewRow, Group);
		
	EndDo;
	
	DocumentData.SummaryRecords.Sort("PaymentType_, Partner, Contract, ARAPObject, Currency");
	#EndRegion
	
EndProcedure

Function ResourcesValues(FillingData, ResourceNames)
	
	ResourceData = New Structure;
	
	ThereAreFilled = False;
	For Each Resource In ResourceNames Do
		
		ResourceData.Insert(Resource.Key,FillingData[Resource.Value]);
		If ResourceData[Resource.Key] <> 0 And Not ThereAreFilled Then
			ThereAreFilled = True;
		EndIf;
		
	EndDo; 
	
	ResourceData.Insert("ThereAreFilled", ThereAreFilled);
	
	Return ResourceData;
	
EndFunction

Function CorrectedDocumentsData(TableOfSettlements)
	
	If Not GetFunctionalOption("UseDocumentCorrection") Then
		TableOfSettlements.Columns.Add("ReverseTransactionCorrection", New TypeDescription("Boolean"));
		Return TableOfSettlements.CopyColumns();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReconciliationData.ARAPDocument AS DocumentCorrections,
	|	ReconciliationData.DocumentAmount AS DocumentAmount,
	|	ReconciliationData.CorrectedDocument AS Ref,
	|	ReconciliationData.ReversedDocument AS ReversedDocument,
	|	ReconciliationData.ReverseTransactionCorrection AS ReverseTransactionCorrection
	|INTO TTDocumentsToBeCorrected
	|FROM
	|	&ReconciliationData AS ReconciliationData
	|WHERE
	|	ReconciliationData.ReverseTransactionCorrection
	|	AND ReconciliationData.ARAPDocument <> UNDEFINED
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	CorrectedDocuments.DocumentCorrections AS DocumentStornoCorrections,
	|	DocumentsRegistry.Ref AS ARAPDocument,
	//the logic of choosing a datadocument and a number document should be as in the SPARK_ACCOUNTS2_5_11.Templates.Selecting accounts
	|	CASE
	|		WHEN VALUETYPE(CorrectedDocuments.Ref) IN 
	|					(TYPE(Document.BankAccountReceiptNote),
	|					TYPE(Document.BankAccountIssue))
	|			THEN CASE WHEN DocumentsRegistry.SourceDocumentDate = DATETIME(1,1,1)
	|							THEN DocumentsRegistry.RecordingInAccountingDate
	|							ELSE DocumentsRegistry.SourceDocumentDate
	|					END
	|		ELSE
	|			CASE WHEN DocumentsRegistry.SourceDocumentDate = DATETIME(1,1,1)
	|					THEN DocumentsRegistry.IBDocumentDate
	|					ELSE DocumentsRegistry.SourceDocumentDate
	|			END
	|	END AS DocumentDate,
	|	CASE WHEN DocumentsRegistry.SourceDocumentNumber = """"
	|		THEN DocumentsRegistry.IBDocumentNumber
	|		ELSE DocumentsRegistry.SourceDocumentNumber
	|	END AS DocumentNumber,
	|	DocumentsRegistry.IBDocumentDate AS IBDocumentDate,
	|	DocumentsRegistry.IBDocumentNumber AS IBDocumentNumber,
	|	DocumentsRegistry.SourceDocumentName AS SourceDocumentName,
	|	DocumentsRegistry.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentsRegistry.SourceDocumentDate AS SourceDocumentDate,
	|	CorrectedDocuments.DocumentAmount AS DocumentAmount,
	|	DocumentsRegistry.Sum AS OldDocumentAmount,
	|	ISNULL(SaleAdjustment.AdjustmentKind, UNDEFINED) 
	|		= VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties) AS ThisIsUAD
	|FROM
	|	TTDocumentsToBeCorrected AS CorrectedDocuments
	|	INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON CorrectedDocuments.Ref = DocumentsRegistry.Ref
	|	LEFT JOIN Document.SaleAdjustment AS SaleAdjustment
	|		ON CorrectedDocuments.Ref = SaleAdjustment.Ref";
	
	Query.SetParameter("ReconciliationData", TableOfSettlements);
	
	Result = Query.Execute().Unload();
	Result.Indexes.Add("DocumentStornoCorrections");
	
	Return Result;
	
EndFunction

Function DocumentNameIsStorno()
	
	Return NStr("vi = 'Đảo ngược';
				|ru = 'Сторно';
				|en = 'Storno'; fa = 'استورنو';
				|it = 'Storno';
				|pl = 'Storno';
				|tr = 'İptal'");
	
EndFunction

Function NameOfCorrectionDocument()
	
	Return NStr("vi = 'Chỉnh sửa';
				|ru = 'Исправление';
				|en = 'Correction'; fa = 'اصلاح';
				|it = 'Correction';
				|pl = 'Correction';
				|tr = 'Düzeltme'");
	
EndFunction

#EndRegion

// Get mutual settlements.
// 
// Parameters:
//  LinkerSelection - DataCompositionSettingsComposer - Composer selection
//  FragmentsOfServiceRequest - Structure of KeyAndValue
// 
// Returns:
//  ValueTable, ValueTree - Get Settlements
Function GetSettlements(LinkerSelection, FragmentsOfServiceRequest = Undefined) Export
	
	DataCompositionSchema = GetTemplate("FilterCalculations");
	
	AddAvailableTables(DataCompositionSchema.DataSets.BalanceAndTurnovers.Query);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(LinkerSelection);
	
	DataCompositionSettings = LinkerSelection.Settings;
	IncludeContractsWithoutTurnover = DataCompositionClientServer.SelectionIsUsed_(DataCompositionSettings.Filter.Items, "ContractsWithoutTurnover", True);
	
	BeginOfPeriod = DataCompositionClientServer.GetParameter(LinkerSelection.Settings, "BeginOfPeriod");
	If Not ValueIsFilled(BeginOfPeriod.Value) Then
		DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BeginOfPeriod", Date('19800101'));
	EndIf;
	
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ContractsWithoutTurnover", IncludeContractsWithoutTurnover);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	
	TypesOfRentalAmounts = TypesOfRentalAmountsToBeReconciled();
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "TypesOfRentalAmounts", TypesOfRentalAmounts,,True);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings,,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,,,True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	DCSResultTable = OutputProcessor.Output(DataCompositionProcessor);
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		DCSResultTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
		DCSResultTable.FillValues(Organization, "Organization");
	EndIf;
	
	ThereIsInputOfResidues(DCSResultTable);
	
	FilterScheme = New Structure;
	FilterScheme.Insert("DCS", DataCompositionSchema);
	FilterScheme.Insert("Settings", DataCompositionSettings);
	FilterScheme.Insert("Result", DCSResultTable);
	
	If LinkerSelection.Settings.AdditionalProperties.Property("ForDebugging") Then
		LinkerSelection.Settings.AdditionalProperties.ForDebugging.Insert("FilterScheme", FilterScheme);
	EndIf;
	
	Return DCSResultTable;
	
EndFunction

// Checks the availability of documents for entering Balances in the selection of DCS and .
// 
// Parameters:
//  DCSResultTable - ValueTable - DCS results table for data selection for reconciliation
// 
// Returns:
//  Boolean -  There Is An Input Of Residues
//
Function ThereIsInputOfResidues(DCSResultTable) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
	"SELECT DISTINCT
	|	T.ARAPDocument AS Ref,
	|	T.DocumentDate AS Period
	|INTO TTDocumentInputBalances
	|FROM
	|	&Table AS T
	|WHERE
	|	VALUETYPE(T.ARAPDocument) = TYPE(Document.OBEntry)
	|	OR VALUETYPE(T.ARAPDocument) = TYPE(Document.OBEntryARAP)
	|	OR VALUETYPE(T.ARAPDocument) = TYPE(Document.OBEntryFinancialInstruments)
	|	OR VALUETYPE(T.ARAPDocument) = TYPE(Document.OBEntryOfLeaseSettlements)
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OBEntry.Period AS Period,
	|	OBEntry.Ref AS Ref
	|FROM
	|	TTDocumentInputBalances AS OBEntry
	|";
	
	Query.SetParameter("Table", DCSResultTable);
	
	OBEntry = Query.Execute().Unload();
	If OBEntry.Count() > 0 Then
		NewBeginningOfPeriod = EndOfDay(OBEntry[0].Period)+1;
		Template = NStr("vi = 'Trong kỳ đối chiếu cụ thể đã tìm thấy chứng từ nhập số dư.
		|Đối chiếu trong kỳ như vậy chưa chính xác. Bắt đầu kỳ đối chiếu cần sau khi nhập số dư.
		|Chứng từ bị xóa khỏi phần bảng chứng từ. Hãy thiết lập bắt đầu kỳ đối chiếu vào ngày %1.';
		|ru = 'В заданном периоде сверки обнаружен документ ввода остатков.
		|Сверка за такой период некорректна. Начало периода сверки должно быть после ввода остатков. 
		|Документы были удалены из табличной части документа. Установите начало периода сверки на дату %1.';
		|en = 'In the specified reconciliation period, a balance entry document is found.
		|Reconciliation for such period is incorrect. The reconciliation period start must be after entering the balance. 
		|The documents were deleted from the document table. Set the start of the reconciliation period to %1.'; fa = 'In the specified reconciliation period, a balance entry document is found.
		|Reconciliation for such period is incorrect. The reconciliation period start must be after entering the balance. 
		|The documents were deleted from the document table. Set the start of the reconciliation period to %1.';
		|it = 'В заданном периоде сверки обнаружен документ ввода остатков.
		|Сверка за такой период некорректна. Начало периода сверки должно быть после ввода остатков. 
		|Документы были удалены из табличной части документа. Установите начало периода сверки на дату %1.';
		|pl = 'In the specified reconciliation period, a balance entry document is found.
		|Reconciliation for such period is incorrect. The reconciliation period start must be after entering the balance. 
		|The documents were deleted from the document table. Set the start of the reconciliation period to %1.';
		|tr = 'Belirli bir mutabakat döneminde kalan giriş belgesi bulundu.
		|Böyle bir dönemde mutabakat geçersizdir. Mutabakat döneminin başlangıcı, bakiyelerin girişinden sonra olmalıdır. 
		|Mutabakat döneminin başlangıcını %1 tarihine ayarlayın.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(Template, Format(NewBeginningOfPeriod, "DLF=D"));
		Common.MessageToUser(MessageText);
	EndIf;
	
	For Each Document In OBEntry Do
		Filter = New Structure("ARAPDocument",Document.Ref);
		LinesToDelete = DCSResultTable.FindRows(Filter);
		For Each DeleteLine In LinesToDelete Do
			DCSResultTable.Delete(DeleteLine);
		EndDo;
	EndDo;
	
	Return OBEntry.Count() > 0;
	
EndFunction

// Data of the settlement document.
// 
// Parameters:
//  SettlementDocuments_ - Array of DocumentRef
// 
// Returns:
//  Structure - Settlement Document Data:
// * Ref - DocumentRef
// * Number - String
// * Date - Date
// * SourceDocumentName - String 
// * Currency - CatalogRef.Currencies
// * Sum - Number
Function SettlementDocumentData(SettlementDocuments_) Export
	
	QueryText = 
	"SELECT TOP 1
	|	DocumentsRegistry.Ref AS Ref,
	|	DocumentsRegistry.SourceDocumentDate AS Date,
	|	DocumentsRegistry.SourceDocumentNumber AS Number,
	|	DocumentsRegistry.SourceDocumentName AS SourceDocumentName,
	|	DocumentsRegistry.Currency AS Currency,
	|	DocumentsRegistry.Sum AS Sum
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.Date AS Date,
	|	DocumentAmounts_.Number AS Number,
	|	"""" AS SourceDocumentName,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.IncomingDocumentDate AS Date,
	|	DocumentAmounts_.IncomingDocumentNumber AS Number,
	|	DocumentAmounts_.ExternalDocumentName AS SourceDocumentName,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Document.RedemptionOfReturnablePackagingFromVendor AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.IncomingDocumentDate AS Date,
	|	DocumentAmounts_.IncomingDocumentNumber AS Number,
	|	DocumentAmounts_.ExternalDocumentName AS SourceDocumentName,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.IncomingDocumentDate AS Date,
	|	DocumentAmounts_.IncomingDocumentNumber AS Number,
	|	DocumentAmounts_.ExternalDocumentName AS SourceDocumentName,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Document.WriteOffReportFromCommissionAgent AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.Date AS Date,
	|	DocumentAmounts_.Number AS Number,
	|	"""" AS SourceDocumentName,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.Date AS Date,
	|	DocumentAmounts_.Number AS Number,
	|	"""" AS SourceDocumentName,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.IncomingDocumentDate AS Date,
	|	DocumentAmounts_.IncomingDocumentNumber AS Number,
	|	DocumentAmounts_.ExternalDocumentName AS SourceDocumentName,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Document.SourceDocument AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentAmounts_.Ref AS Ref,
	|	DocumentAmounts_.Ref.Date AS Date,
	|	DocumentAmounts_.Ref.Number AS Number,
	|	"""" AS SourceDocumentName,
	|	DocumentAmounts_.ARAPCurrency AS Currency,
	|	SUM(DocumentAmounts_.Sum) AS Sum
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS DocumentAmounts_
	|WHERE
	|	DocumentAmounts_.Ref IN (&DocumentsArray)
	|		
	|GROUP BY
	|	DocumentAmounts_.Ref,
	|	DocumentAmounts_.ARAPCurrency";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", SettlementDocuments_);
	
	Selection = Query.Execute().Select();
	DocumentData = New Structure("Ref,Number,Date, SourceDocumentName, Currency,Sum");
	While Selection.Next() Do
		FillPropertyValues(DocumentData, Selection);
	EndDo;
	
	Return DocumentData;
	
EndFunction

Procedure InitializeSettingsComposer(LinkerSelection, FormUniqueID = Undefined, Filter_Settings = Undefined) Export
	
	DataCompositionSchema = GetTemplate("FilterCalculations");
	
	AddAvailableTables(DataCompositionSchema.DataSets.BalanceAndTurnovers.Query);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	If UsePartnersAsCounterparties Then
		Field = DataCompositionSchema.DataSets.BalanceAndTurnovers.Fields.Find("Counterparty"); // DataCompositionSchemaDataSetField 
		If Field <> Undefined Then
			Field.UseRestriction.Condition = True;
			Field.AttributeUseRestriction.Condition = True;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.HeaderOfSKDFieldDependingOnFOUsePartnersAsCounterparties(
		DataCompositionSchema.DataSets.BalanceAndTurnovers, "Partner", NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Контрагент';
																			|pl = 'Counterparty';
																			|tr = 'Cari hesap'"));
		
	PrivilegedMode = PrivilegedMode();
	AvailableTypesOfCalculations_ = New ValueList;
	AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	If AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts) Or PrivilegedMode Then
		AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
		AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
	EndIf;
	If AccessRight("View", Metadata.Catalogs.LeaseContract) Or PrivilegedMode Then
		AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
	EndIf;
	CalculationTypeField = DataCompositionSchema.DataSets.BalanceAndTurnovers.Fields.Find("PaymentType_");
	CalculationTypeField.SetAvailableValues(AvailableTypesOfCalculations_);
		
	If FormUniqueID = Undefined Then
		AddressInStorage = PutToTempStorage(Undefined, New UUID());
	EndIf;
	AddressInStorage = PutToTempStorage(DataCompositionSchema, FormUniqueID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressInStorage);
	
	LinkerSelection.Initialize(SettingsSource);
	
	LinkerSelection.LoadSettings(DataCompositionSchema.DefaultSettings);
	If Filter_Settings <> Undefined Then
		DataCompositionClientServer.CopyElements(LinkerSelection.Settings.Filter, Filter_Settings.Filter);
	EndIf;
	If UsePartnersAsCounterparties Then
		DataCompositionClientServer.DeleteSelection(LinkerSelection.Settings.Filter, "Counterparty");
	Else
		DataCompositionClientServer.DeleteSelection(LinkerSelection.Settings.Filter, "CompanyCounterparty");
	EndIf;
	LinkerSelection.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	If FormUniqueID = Undefined Then
		DeleteFromTempStorage(AddressInStorage);
	EndIf;
	
EndProcedure

Procedure CompletePartnerSelectionByCounterparty(Filter, Counterparty) Export
	
	If Not ValueIsFilled(Counterparty) Then
		Return;
	EndIf;
	
	If TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
		FilterElement = FinancialReportingServer.FindSelectionElement(Filter,"CompanyCounterparty");
		If FilterElement = Undefined Then
			FilterElement = DataCompositionClientServer.AddFilter(Filter, "CompanyCounterparty");
		EndIf;
		FilterElement.Use = True;
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = Counterparty;
	Else
		FilterElement = FinancialReportingServer.FindSelectionElement(Filter,"Partner");
		If FilterElement <> Undefined Then
			FilterElement.Use = True;
			If TypeOf(Counterparty) = Type("CatalogRef.Counterparties") Then
				FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
				FilterElement.RightValue = Common.ObjectAttributeValue(Counterparty, "Partner");
			ElsIf TypeOf(Counterparty) = Type("Array") Or TypeOf(Counterparty) = Type("ValueList") Then
				FilterElement.Use = True;
				FilterElement.ComparisonType = DataCompositionComparisonType.InList;
				If TypeOf(Counterparty) = Type("ValueList") Then
					If Counterparty.Count() > 0 And TypeOf(Counterparty[0].Value) = Type("CatalogRef.Counterparties") Then
						Partners = Common.ObjectsAttributeValue(Counterparty.UnloadValues(), "Partner");
					ElsIf Counterparty.Count() > 0 And TypeOf(Counterparty[0].Value) = Type("CatalogRef.Companies") Then
						FilterElement.Use = False;
						FilterElement = FinancialReportingServer.FindSelectionElement(Filter,"CompanyCounterparty");
						If FilterElement = Undefined Then
							FilterElement = DataCompositionClientServer.AddFilter(Filter, "CompanyCounterparty");
						EndIf;
						FilterElement.Use = True;
						FilterElement.ComparisonType = DataCompositionComparisonType.InList;
						FilterElement.RightValue = Counterparty;
					EndIf;
				Else
					Partners = Common.ObjectsAttributeValue(Counterparty, "Partner");
				EndIf;
				If Partners <> Undefined Then
					FilterElement.RightValue = New ValueList;
					For Each Partner In Partners Do
						FilterElement.RightValue.Add(Partner.Value);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure AddAvailableTables(QueryText)
	
	QueriesTexts = QueryTextsForAvailableTables();
	For Each Text In QueriesTexts Do
		QueryText = StrReplace(QueryText, "//"+Text.Key, Text.Value);
	EndDo;
	
EndProcedure

// Prohibited types of calculations.
// 
// Returns:
//  Array of EnumList.PartnersARAPAccountingTypes- Prohibited types of calculations
Function ProhibitedPaymentTypes() Export
	
	Result = New Array;
	If PrivilegedMode() Then
		Return Result;
	EndIf;
	
	If AccessRight("View", Metadata.AccumulationRegisters.FinancialInstrumentsARAP) Then
		If Not AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts) Then
			Result.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
			Result.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
		EndIf;
		If Not AccessRight("View", Metadata.Catalogs.LeaseContract) Then
			Result.Add(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
		EndIf;
	Else
		Result.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
		Result.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
		Result.Add(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
	EndIf;
	
	Return Result;
	
EndFunction

Function QueryTextsForAvailableTables()
	
	PrivilegedMode = PrivilegedMode();
	Result = New Map;
	If AccessRight("View", Metadata.AccumulationRegisters.FinancialInstrumentsARAP)
		Or PrivilegedMode Then
		Result.Insert("#0", QueryTextSettlementsOnFinancialInstrumentsBalancesAtEndOfPeriod()); //AccumulationRegisterFinancialInstrumentsARAP
		Result.Insert("#1", QueryTextFinancialInstrumentsARAP()); //AccumulationRegisterFinancialInstrumentsARAP
	EndIf;
	If AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts)
		Or PrivilegedMode Then
		Result.Insert("#2", TextOfRequestForLoanAgreementsDepositsLoans()); //CatalogLoanAndDepositContracts
	EndIf;
	If AccessRight("View", Metadata.Catalogs.LeaseContract)
		Or PrivilegedMode Then
		Result.Insert("#3", QueryTextOfLeaseContracts()); //CatalogLeaseContract
	EndIf;
	If AccessRight("View", Metadata.Documents.SourceDocument)
		Or PrivilegedMode Then
		Result.Insert("#4", QueryTextSourceDocument()); //DocumentSourceDocument
	EndIf;
	If AccessRight("View", Metadata.Documents.ARAPAdjustment)
		Or PrivilegedMode Then
		Result.Insert("#5", QueryTextARAPAdjustment()); //DocumentARAPAdjustment
	EndIf;
	
	Return Result;
	
EndFunction

Function QueryTextSettlementsOnFinancialInstrumentsBalancesAtEndOfPeriod()
	
	Return 
	"///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	NestedQuery.PaymentType_ AS PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.ParentCompany AS ParentCompany,
	|	NestedQuery.Partner AS Partner,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ContractNumber AS ContractNumber,
	|	NestedQuery.ContractDate_ AS ContractDate_,
	|	NestedQuery.ContractName AS ContractName,
	|	NestedQuery.Currency AS Currency,
	|	UNDEFINED AS AmountType,
	|	TRUE AS ContractsWithoutTurnover, //We always include contracts with turnover
	|	
	|	SUM(NestedQuery.ClosingBalance) AS ClosingBalance,
	|	SUM(NestedQuery.ClosingBalanceLocal) AS ClosingBalanceLocal,
	|	SUM(NestedQuery.ClosingBalanceDr) AS ClosingBalanceDr,
	|	SUM(NestedQuery.ClosingBalanceCr) AS ClosingBalanceCr,
	|	SUM(NestedQuery.FinalBalanceOfDrLocal) AS FinalBalanceOfDrLocal,
	|	SUM(NestedQuery.FinalBalanceOfCrLocal) AS FinalBalanceOfCrLocal,
	|	
	|	NestedQuery.PaymentTypeOrder AS PaymentTypeOrder
	|INTO TTBalanceAtEndOfPeriodFinInstruments
	|FROM
	|	(SELECT
	|	&EndOfPeriod AS Period,
	|	CASE 
	|		WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|		WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|	END AS PaymentType_,
	|	CalculationsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Dimension.Organization AS Organization,
	|	Dimension.ParentCompany AS ParentCompany,
	|	Dimension.Partner AS Partner,
	|	Dimension.Counterparty AS Counterparty,
	|	CalculationsBalance.Contract AS Contract,
	|	CalculationsBalance.Contract.LineOfBusiness AS LineOfBusiness,
	|	CalculationsBalance.Contract.Number AS ContractNumber,
	|	CalculationsBalance.Contract.Date AS ContractDate_,
	|	CalculationsBalance.Contract.NameForPrinting AS ContractName,
	|	UNDEFINED AS ARAPDocument,
	|	CalculationsBalance.Currency AS Currency,
	|	UNDEFINED AS AmountType,
	|	TRUE AS ContractsWithoutTurnover, //We always include contracts with turnover
	|	
	|	CalculationsBalance.SumBalance AS ClosingBalance,
	|	CalculationsBalance.SumComplBalance AS ClosingBalanceLocal,
	|	
	|	CASE WHEN CalculationsBalance.SumBalance > 0
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS ClosingBalanceDr,
	|	CASE WHEN CalculationsBalance.SumBalance < 0
	|		THEN -CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS ClosingBalanceCr,
	|	CASE WHEN CalculationsBalance.SumComplBalance > 0
	|		THEN CalculationsBalance.SumComplBalance
	|		ELSE 0
	|	END AS FinalBalanceOfDrLocal,
	|	CASE WHEN CalculationsBalance.SumComplBalance < 0
	|		THEN -CalculationsBalance.SumComplBalance
	|		ELSE 0
	|	END AS FinalBalanceOfCrLocal,
	|	
	|	CASE 
	|		WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN 31
	|		WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN 32
	|		WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|			THEN 33
	|	END AS PaymentTypeOrder
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|		{&EndOfPeriod},
	|		{AccountingDimensionByPartners.Organization.* AS Organization,
	|		AccountingDimensionByPartners.Partner.* AS Partner,
	|		AccountingDimensionByPartners.Partner.MainManager.* AS MainManager,
	|		AccountingDimensionByPartners.Counterparty.* AS Counterparty,
	|		AccountingDimensionByPartners.Organization IN (&Companies),
	|		AccountingDimensionByPartners.Counterparty IN (&Counterparties)}
	|	) AS CalculationsBalance
	|	INNER JOIN DimensionByPartners AS Dimension
	|	ON CalculationsBalance.AccountingDimensionByPartners = Dimension.DimensionKey
	|) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Organization,
	|	NestedQuery.ParentCompany,
	|	NestedQuery.Partner,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ContractNumber,
	|	NestedQuery.ContractDate_,
	|	NestedQuery.ContractName,
	|	NestedQuery.Currency,
	|	NestedQuery.PaymentTypeOrder
	|	
	|{WHERE
	|	NestedQuery.PaymentType_ AS PaymentType_}
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	Contract,
	|	Currency
	|;";
	
EndFunction

Function QueryTextFinancialInstrumentsARAP()
	
	Return "
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	NestedQuery.PaymentType_ AS PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.ParentCompany AS ParentCompany,
	|	NestedQuery.Partner AS Partner,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ContractNumber AS ContractNumber,
	|	NestedQuery.ContractDate_ AS ContractDate_,
	|	NestedQuery.ContractName AS ContractName,
	|	NestedQuery.Contract AS ARAPObject,
	|	NestedQuery.Recorder AS ARAPDocument,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.AmountType AS AmountType,
	|	TRUE AS ContractsWithoutTurnover, //We always include contracts with turnover
	|	
	|	SUM(NestedQuery.OpeningBalance) AS OpeningBalance,
	|	SUM(NestedQuery.OpeningBalanceLocal) AS OpeningBalanceLocal,
	|	SUM(NestedQuery.OpeningBalanceDr) AS OpeningBalanceDr,
	|	SUM(NestedQuery.DrLocalOpeningBalance) AS DrLocalOpeningBalance,
	|	SUM(NestedQuery.OpeningBalanceCr) AS OpeningBalanceCr,
	|	SUM(NestedQuery.InitialBalanceOfCrLocal) AS InitialBalanceOfCrLocal,
	|	
	|	0 AS TurnoverDr,
	|	0 AS DrLocalTurnover,
	|	0 AS TurnoverCr,
	|	0 AS CrLocalTurnover,
	|	
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	SUM(NestedQuery.ClosingBalance) AS ClosingBalance,
	|	SUM(NestedQuery.ClosingBalanceLocal) AS ClosingBalanceLocal,
	|	SUM(NestedQuery.ClosingBalanceDr) AS ClosingBalanceDr,
	|	SUM(NestedQuery.ClosingBalanceCr) AS ClosingBalanceCr,
	|	SUM(NestedQuery.FinalBalanceOfDrLocal) AS FinalBalanceOfDrLocal,
	|	SUM(NestedQuery.FinalBalanceOfCrLocal) AS FinalBalanceOfCrLocal,
	|	
	|	NestedQuery.PaymentTypeOrder AS PaymentTypeOrder
	|FROM
	|	(SELECT
	|		&BeginOfPeriod AS Period,
	|		CASE 
	|			WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|			WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|		END AS PaymentType_,
	|		CalculationsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Dimension.Organization AS Organization,
	|		Dimension.ParentCompany AS ParentCompany,
	|		Dimension.Partner AS Partner,
	|		Dimension.Counterparty AS Counterparty,
	|		CalculationsBalance.Contract AS Contract,
	|		CalculationsBalance.Contract.LineOfBusiness AS LineOfBusiness,
	|		CalculationsBalance.Contract.Number AS ContractNumber,
	|		CalculationsBalance.Contract.Date AS ContractDate_,
	|		CalculationsBalance.Contract.NameForPrinting AS ContractName,
	|		UNDEFINED AS Recorder,
	|		CalculationsBalance.Currency AS Currency,
	|		UNDEFINED AS AmountType,
	|	
	|		CalculationsBalance.SumBalance AS OpeningBalance,
	|		CalculationsBalance.SumComplBalance AS OpeningBalanceLocal,
	|		CASE WHEN CalculationsBalance.SumBalance > 0
	|			THEN CalculationsBalance.SumBalance
	|			ELSE 0
	|		END AS OpeningBalanceDr,
	|		CASE WHEN CalculationsBalance.SumBalance < 0
	|			THEN -CalculationsBalance.SumBalance
	|			ELSE 0
	|		END AS OpeningBalanceCr,
	|		CASE WHEN CalculationsBalance.SumComplBalance > 0
	|			THEN CalculationsBalance.SumComplBalance
	|			ELSE 0
	|		END AS DrLocalOpeningBalance,
	|		CASE WHEN CalculationsBalance.SumComplBalance < 0
	|			THEN -CalculationsBalance.SumComplBalance
	|			ELSE 0
	|		END AS InitialBalanceOfCrLocal,
	|	
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalance, 0) AS ClosingBalance,
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalanceLocal, 0) AS ClosingBalanceLocal,
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalanceDr, 0) AS ClosingBalanceDr,
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalanceCr, 0) AS ClosingBalanceCr,
	|		ISNULL(BalancesAtEndOfPeriod.FinalBalanceOfDrLocal, 0) AS FinalBalanceOfDrLocal,
	|		ISNULL(BalancesAtEndOfPeriod.FinalBalanceOfCrLocal, 0) AS FinalBalanceOfCrLocal,
	|
	|		CASE 
	|			WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN 31
	|			WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN 32
	|			WHEN CalculationsBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|				THEN 33
	|		END AS PaymentTypeOrder
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			{&BeginOfPeriod},
	|			AmountType IN (&TypesOfRentalAmounts) OR VALUETYPE(Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|			{AccountingDimensionByPartners.Partner.* AS Partner,
	|			AccountingDimensionByPartners.Partner.MainManager.* AS MainManager,
	|			AccountingDimensionByPartners.Counterparty.* AS Counterparty,
	|			AccountingDimensionByPartners.Organization IN (&Companies),
	|			AccountingDimensionByPartners.Counterparty IN (&Counterparties),
	|			AccountingDimensionByPartners.Partner IN (&Partners)}
	|		) AS CalculationsBalance
	|		INNER JOIN DimensionByPartners AS Dimension
	|		ON CalculationsBalance.AccountingDimensionByPartners = Dimension.DimensionKey
	|		LEFT JOIN TTBalanceAtEndOfPeriodFinInstruments AS BalancesAtEndOfPeriod
	|		ON CalculationsBalance.AccountingDimensionByPartners = BalancesAtEndOfPeriod.AccountingDimensionByPartners
	|			AND CalculationsBalance.Contract = BalancesAtEndOfPeriod.Contract
	|			AND CalculationsBalance.Currency = BalancesAtEndOfPeriod.Currency
	|	WHERE
	|		CalculationsBalance.SumBalance <> 0) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Organization,
	|	NestedQuery.ParentCompany,
	|	NestedQuery.Partner,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ContractNumber,
	|	NestedQuery.ContractDate_,
	|	NestedQuery.ContractName,
	|	NestedQuery.Recorder,
	|	NestedQuery.Currency,
	|	NestedQuery.AmountType,
	|	NestedQuery.PaymentTypeOrder
	|	
	|{WHERE
	|	NestedQuery.PaymentType_ AS PaymentType_}
	|
	|UNION ALL 
	|
	|SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.PaymentType_ AS PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.ParentCompany AS ParentCompany,
	|	NestedQuery.Partner AS Partner,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ContractNumber AS ContractNumber,
	|	NestedQuery.ContractDate_ AS ContractDate_,
	|	NestedQuery.ContractName AS ContractName,
	|	NestedQuery.Contract AS ARAPObject,
	|	NestedQuery.Recorder AS ARAPDocument,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.AmountType AS AmountType,
	|	TRUE AS ContractsWithoutTurnover, //We always include contracts with turnover
	|	
	|	0 AS OpeningBalance,
	|	0 AS OpeningBalanceLocal,
	|	0 AS OpeningBalanceDr,
	|	0 AS DrLocalOpeningBalance,
	|	0 AS OpeningBalanceCr,
	|	0 AS InitialBalanceOfCrLocal,
	|	
	|	SUM(NestedQuery.TurnoverDr) AS TurnoverDr,
	|	SUM(NestedQuery.DrLocalTurnover) AS DrLocalTurnover,
	|	SUM(NestedQuery.TurnoverCr) AS TurnoverCr,
	|	SUM(NestedQuery.CrLocalTurnover) AS CrLocalTurnover,
	|	
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	SUM(NestedQuery.ClosingBalance) AS ClosingBalance,
	|	SUM(NestedQuery.ClosingBalanceLocal) AS ClosingBalanceLocal,
	|	SUM(NestedQuery.ClosingBalanceDr) AS ClosingBalanceDr,
	|	SUM(NestedQuery.ClosingBalanceCr) AS ClosingBalanceCr,
	|	SUM(NestedQuery.FinalBalanceOfDrLocal) AS FinalBalanceOfDrLocal,
	|	SUM(NestedQuery.FinalBalanceOfCrLocal) AS FinalBalanceOfCrLocal,
	|	
	|	NestedQuery.PaymentTypeOrder AS PaymentTypeOrder
	|FROM
	|	(SELECT
	|		CalculationsRevolutions.Period AS Period,
	|		CASE 
	|			WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|			WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|		END AS PaymentType_,
	|		CalculationsRevolutions.AccountingDimensionByPartners   AS AccountingDimensionByPartners,
	|		Dimension.Organization AS Organization,
	|		Dimension.ParentCompany AS ParentCompany,
	|		Dimension.Partner AS Partner,
	|		Dimension.Counterparty AS Counterparty,
	|		CalculationsRevolutions.Contract AS Contract,
	|		CalculationsRevolutions.Contract.LineOfBusiness AS LineOfBusiness,
	|		CalculationsRevolutions.Contract.Number AS ContractNumber,
	|		CalculationsRevolutions.Contract.Date AS ContractDate_,
	|		CalculationsRevolutions.Contract.NameForPrinting AS ContractName,
	|		CalculationsRevolutions.Recorder AS Recorder,
	|		CalculationsRevolutions.Currency AS Currency,
	|		UNDEFINED AS AmountType,
	|	
	|		0 AS OpeningBalance,
	|		0 AS OpeningBalanceLocal,
	|		0 AS OpeningBalanceDr,
	|		0 AS DrLocalOpeningBalance,
	|		0 AS OpeningBalanceCr,
	|		0 AS InitialBalanceOfCrLocal,
	|	
	|		CalculationsRevolutions.SumReceipt AS TurnoverDr,
	|		CalculationsRevolutions.SumComplReceipt AS DrLocalTurnover,
	|		CalculationsRevolutions.SumExpense AS TurnoverCr,
	|		CalculationsRevolutions.SumComplExpense AS CrLocalTurnover,
	|	
	|		0 AS Debt,
	|		0 AS DebtLocal,
	|		0 AS Prepayment,
	|		0 AS PrepaymentLocal,
	|	
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalance, 0) AS ClosingBalance,
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalanceLocal, 0) AS ClosingBalanceLocal,
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalanceDr, 0) AS ClosingBalanceDr,
	|		ISNULL(BalancesAtEndOfPeriod.ClosingBalanceCr, 0) AS ClosingBalanceCr,
	|		ISNULL(BalancesAtEndOfPeriod.FinalBalanceOfDrLocal, 0) AS FinalBalanceOfDrLocal,
	|		ISNULL(BalancesAtEndOfPeriod.FinalBalanceOfCrLocal, 0) AS FinalBalanceOfCrLocal,
	|	
	|		CASE 
	|			WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN 31
	|			WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN 32
	|			WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|				THEN 33
	|		END AS PaymentTypeOrder
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP.Turnovers(
	|			{&BeginOfPeriod}, {&EndOfPeriod}, Recorder,
	|			AmountType IN (&TypesOfRentalAmounts) OR VALUETYPE(Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|			{AccountingDimensionByPartners.Partner.* AS Partner,
	|			AccountingDimensionByPartners.Counterparty.* AS Counterparty,
	|			AccountingDimensionByPartners.Organization IN (&Companies),
	|			AccountingDimensionByPartners.Counterparty IN (&Counterparties),
	|			AccountingDimensionByPartners.Partner IN (&Partners)}
	|		) AS CalculationsRevolutions
	|		INNER JOIN DimensionByPartners AS Dimension
	|		ON CalculationsRevolutions.AccountingDimensionByPartners = Dimension.DimensionKey
	|		LEFT JOIN TTBalanceAtEndOfPeriodFinInstruments AS BalancesAtEndOfPeriod
	|		ON CalculationsRevolutions.AccountingDimensionByPartners = BalancesAtEndOfPeriod.AccountingDimensionByPartners
	|			AND CalculationsRevolutions.Contract = BalancesAtEndOfPeriod.Contract
	|			AND CalculationsRevolutions.Currency = BalancesAtEndOfPeriod.Currency
	|	WHERE
	|		CalculationsRevolutions.SumComplTurnover <> 0) AS NestedQuery
	|	
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Organization,
	|	NestedQuery.ParentCompany,
	|	NestedQuery.Partner,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ContractNumber,
	|	NestedQuery.ContractDate_,
	|	NestedQuery.ContractName,
	|	NestedQuery.Recorder,
	|	NestedQuery.Currency,
	|	NestedQuery.AmountType,
	|	NestedQuery.PaymentTypeOrder
	|	
	|HAVING
	|	SUM(NestedQuery.TurnoverDr) <> 0 OR SUM(NestedQuery.DrLocalTurnover) <> 0
	|	OR SUM(NestedQuery.TurnoverCr) <> 0 OR SUM(NestedQuery.CrLocalTurnover) <> 0
	|	
	|{WHERE
	|	NestedQuery.PaymentType_ AS PaymentType_}";
	
EndFunction

Function TextOfRequestForLoanAgreementsDepositsLoans()
	
	Return "
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	CASE 
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|	END AS PaymentType_,
	|	UNDEFINED AS AccountingDimensionByPartners,
	|	Contracts.Organization AS Organization,
	|	Contracts.Organization.ParentCompany AS ParentCompany,
	|	Contracts.Partner AS Partner,
	|	Contracts.Counterparty AS Counterparty,
	|	Contracts.Ref AS Contract,
	|	Contracts.LineOfBusiness AS LineOfBusiness,
	|	Contracts.Number AS ContractNumber,
	|	Contracts.Date AS ContractDate_,
	|	Contracts.NameForPrinting AS ContractName,
	|	Contracts.Ref AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	Contracts.ARAPCurrency AS Currency,
	|	UNDEFINED AS AmountType,
	|	TRUE AS ContractsWithoutTurnover,
	|		
	|	0 AS OpeningBalance,
	|	0 AS OpeningBalanceLocal,
	|	0 AS OpeningBalanceDr,
	|	0 AS DrLocalOpeningBalance,
	|	0 AS OpeningBalanceCr,
	|	0 AS InitialBalanceOfCrLocal,
	|	
	|	0 AS TurnoverDr,
	|	0 AS DrLocalTurnover,
	|	0 AS TurnoverCr,
	|	0 AS CrLocalTurnover,
	|	
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	0 AS ClosingBalance,
	|	0 AS ClosingBalanceLocal,
	|	0 AS ClosingBalanceDr,
	|	0 AS ClosingBalanceCr,
	|	0 AS FinalBalanceOfDrLocal,
	|	0 AS FinalBalanceOfCrLocal,
	|	
	|	CASE 
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN 31
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN 32
	|	END AS PaymentTypeOrder
	|FROM
	|	Catalog.LoanAndDepositContracts AS Contracts
	|WHERE
	|	NOT Contracts.DeletionMark
	|	AND &ContractsWithoutTurnover
	|{WHERE
	|	CASE 
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|	END AS PaymentType_,
	|	TRUE AS ContractsWithoutTurnover}";
	
EndFunction
Function QueryTextOfLeaseContracts()
	
	Return "
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) AS PaymentType_,
	|	UNDEFINED AS AccountingDimensionByPartners,
	|	Contracts.Organization AS Organization,
	|	Contracts.Organization.ParentCompany AS ParentCompany,
	|	Contracts.Partner AS Partner,
	|	Contracts.Counterparty AS Counterparty,
	|	Contracts.Ref AS Contract,
	|	Contracts.LineOfBusiness AS LineOfBusiness,
	|	Contracts.Number AS ContractNumber,
	|	Contracts.Date AS ContractDate_,
	|	Contracts.NameForPrinting AS ContractName,
	|	Contracts.Ref AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	Contracts.ARAPCurrency AS Currency,
	|	UNDEFINED AS AmountType,
	|	TRUE AS ContractsWithoutTurnover,
	|		
	|	0 AS OpeningBalance,
	|	0 AS OpeningBalanceLocal,
	|	0 AS OpeningBalanceDr,
	|	0 AS DrLocalOpeningBalance,
	|	0 AS OpeningBalanceCr,
	|	0 AS InitialBalanceOfCrLocal,
	|	
	|	0 AS TurnoverDr,
	|	0 AS DrLocalTurnover,
	|	0 AS TurnoverCr,
	|	0 AS CrLocalTurnover,
	|	
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	0 AS ClosingBalance,
	|	0 AS ClosingBalanceLocal,
	|	0 AS ClosingBalanceDr,
	|	0 AS ClosingBalanceCr,
	|	0 AS FinalBalanceOfDrLocal,
	|	0 AS FinalBalanceOfCrLocal,
	|	
	|	33 AS PaymentTypeOrder
	|FROM
	|	Catalog.LeaseContract AS Contracts
	|WHERE
	|	NOT Contracts.DeletionMark
	|	AND &ContractsWithoutTurnover
	|{WHERE
	|	CASE 
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|	END AS PaymentType_,
	|	TRUE AS ContractsWithoutTurnover}";
	
EndFunction
Function QueryTextSourceDocument()
	
	Return "
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentAmounts_.Ref AS Recorder,
	|	Turnovers.Organization AS Organization,
	|	Turnovers.ParentCompany AS ParentCompany,
	|	Turnovers.PaymentType_ AS PaymentType_,
	|	DocumentAmounts_.IncomingDocumentDate AS DocumentDate,
	|	DocumentAmounts_.IncomingDocumentNumber AS DocumentNumber,
	|	DocumentAmounts_.Date AS IBDocumentDate,
	|	DocumentAmounts_.Number AS IBDocumentNumber,
	|	DocumentAmounts_.ExternalDocumentName AS SourceDocumentName,
	|	DocumentAmounts_.IncomingDocumentNumber AS SourceDocumentNumber,
	|	DocumentAmounts_.IncomingDocumentDate AS SourceDocumentDate,
	|	UNDEFINED AS CorrectedDocument,
	|	UNDEFINED AS ReversedDocument,
	|	FALSE AS ReverseTransactionCorrection,
	|	DocumentAmounts_.Currency AS Currency,
	|	DocumentAmounts_.DocumentAmount AS Sum
	|FROM
	|	Turnovers AS Turnovers
	|	INNER JOIN Document.SourceDocument AS DocumentAmounts_
	|	ON Turnovers.ARAPDocument = DocumentAmounts_.Ref
	|		AND Turnovers.ARAPDocument <> UNDEFINED";
	
EndFunction

Function QueryTextARAPAdjustment()
	
	Return "
	|UNION ALL
	|
	|SELECT
	|	DocumentAmounts_.Ref AS Recorder,
	|	Turnovers.Organization AS Organization,
	|	Turnovers.ParentCompany AS ParentCompany,
	|	Turnovers.PaymentType_ AS PaymentType_,
	|	DocumentAmounts_.Ref.Date AS DocumentDate,
	|	DocumentAmounts_.Ref.Number AS DocumentNumber,
	|	DocumentAmounts_.Ref.Date AS IBDocumentDate,
	|	DocumentAmounts_.Ref.Number AS IBDocumentNumber,
	|	"""" AS SourceDocumentName,
	|	"""" AS SourceDocumentNumber,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS CorrectedDocument,
	|	UNDEFINED AS ReversedDocument,
	|	FALSE AS ReverseTransactionCorrection,
	|	DocumentAmounts_.ARAPCurrency AS Currency,
	|	SUM(DocumentAmounts_.Sum) AS Sum
	|FROM
	|	Turnovers AS Turnovers
	|	INNER JOIN Document.ARAPAdjustment.Debt_ AS DocumentAmounts_
	|	ON Turnovers.ARAPDocument = DocumentAmounts_.Ref
	|		AND Turnovers.ARAPDocument <> UNDEFINED
	|		AND Turnovers.PaymentType_ = DocumentAmounts_.PaymentType_
	|		AND Turnovers.ARAPObject = DocumentAmounts_.ARAPObject
	|		AND Turnovers.Partner = DocumentAmounts_.Partner
	|		
	|GROUP BY
	|	DocumentAmounts_.Ref,
	|	Turnovers.PaymentType_,
	|	Turnovers.Organization,
	|	Turnovers.ParentCompany,
	|	DocumentAmounts_.ARAPCurrency";
	
EndFunction

// Attributes of the last document.
// 
// Parameters:
//  Counterparty - CatalogRef.Counterparties
// 
// Returns:
//  Structure - Details Of The Last Document:
// * Partner - CatalogRef.Partners
// * Contract - CatalogRef.CounterpartyContracts
// * DrillDownByOrders - Boolean
// * DrillDownByPartners - Boolean
// * DrillDownByContracts - Boolean
// * FullNameOfCounterpartyExecutive - String
// * JobTitleOfCounterpartyExecutive - String
// * ContactPerson - String
Function DetailsOfLastDocument(Counterparty) Export

	AttributesStructure1 = New Structure("Partner,
										  |Contract,
										  |DrillDownByOrders,
										  |DrillDownByPartners,
										  |DrillDownByContracts,
										  |FullNameOfCounterpartyExecutive,
										  |JobTitleOfCounterpartyExecutive,
										  |ContactPerson");
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED TOP 1
		|	ARAPReconciliation.Partner AS Partner,
		|	ARAPReconciliation.Contract AS Contract,
		|	TRUE AS DrillDownByOrders,
		|	ARAPReconciliation.SplitByPartners AS DrillDownByPartners,
		|	ARAPReconciliation.SplitByContracts AS DrillDownByContracts,
		|	ARAPReconciliation.FullNameOfCounterpartyExecutive AS FullNameOfCounterpartyExecutive,
		|	ARAPReconciliation.JobTitleOfCounterpartyExecutive AS JobTitleOfCounterpartyExecutive,
		|	ARAPReconciliation.ContactPerson AS ContactPerson
		|FROM
		|	Document.ARAPReconciliation2_5_11 AS ARAPReconciliation
		|WHERE
		|	ARAPReconciliation.Counterparty = &Counterparty
		|	AND NOT ARAPReconciliation.DeletionMark
		|
		|ORDER BY
		|	ARAPReconciliation.PointInTime DESC";
	
	Query.SetParameter("Counterparty", Counterparty);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(AttributesStructure1, Selection);
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

Function StructureAttributesResponsiblePersons() Export
	
	DocumentAttributes = Metadata.Documents.ARAPReconciliation2_5_11.Attributes;
	Result = New Structure();
	Result.Insert(
		DocumentAttributes.Director.Name, 
		Enums.PersonsResponsibleAndCompanies.Director);
	Result.Insert(
		DocumentAttributes.ChiefAccountant.Name, 
		Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	Return Result;
	
EndFunction

Function StructureAttributesResponsiblePersonsOfCounterpartyOrganization() Export
	
	DocumentAttributes = Metadata.Documents.ARAPReconciliation2_5_11.Attributes;
	Result = New Structure();
	Result.Insert(
		DocumentAttributes.CounterpartyCompanyManager.Name, 
		Enums.PersonsResponsibleAndCompanies.Director);
	Result.Insert(
		DocumentAttributes.ChiefAccountantOfCounterpartyCompany.Name, 
		Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	Return Result;
	
EndFunction

// Types of rental amounts to be reconciled. There is an empty array in the TM.
// 
// Returns:
//  Array of EnumRef.TypesOfLeasePayments 
//
Function TypesOfRentalAmountsToBeReconciled() Export
	
	TypesOfRentalAmounts = New Array;
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.DepositPayment);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.RentalService);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.BuyoutValue);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	Return TypesOfRentalAmounts;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
