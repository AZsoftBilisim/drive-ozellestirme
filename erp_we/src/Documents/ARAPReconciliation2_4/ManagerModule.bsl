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
	If AccessRight("Insert", Metadata.Documents.ARAPReconciliation2_4) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ARAPReconciliation2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ARAPReconciliation2_4);
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
//	ArrayOfAllProps - Array - Array of all the names of banking details that depend on the business operation.
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(ParametersStructure, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("GroupingsARAP.PaymentType_");
	ArrayOfAllProps.Add("GroupingsARAP.Partner");
	ArrayOfAllProps.Add("GroupingsARAP.Contract");
	ArrayOfAllProps.Add("GroupingsFinancialInstruments.PaymentType_");
	ArrayOfAllProps.Add("GroupingsFinancialInstruments.Partner");
	ArrayOfAllProps.Add("GroupingsFinancialInstruments.Contract");
	ArrayOfAllProps.Add("DetailedRecordsARAPAccounting.DocumentAmountCounterparty");
	ArrayOfAllProps.Add("DetailedRecordsSettlementsSettlementsCounterparty");
	
	ArrayOfAllProps.Add("DetailedRecordsLoansAmountCounterparty");
	ArrayOfAllProps.Add("DetailedRecordsLoansAmountInterestCounterparty");
	ArrayOfAllProps.Add("DetailedRecordsLoansAmountCommissionCounterparty");
	ArrayOfAllProps.Add("DetailedRecordsLeasingLeaseObligationsCounterparty");
	ArrayOfAllProps.Add("DetailedRecordsLeasingSecurityPaymentCounterparty");
	ArrayOfAllProps.Add("DetailedRecordsLeasingRentalServiceCounterparty");
	ArrayOfAllProps.Add("DetailedRecordsLeasingPurchasePriceCounterparty");
	
	ArrayOfAllProps.Add("DetailedRecordsLoansGroupCommission");
	ArrayOfAllProps.Add("DetailedRecordsLeasingGroupBuyout");
	
	
	ArrayOfOperationDetails = New Array;
	If ParametersStructure.ShowCalculationType Then
		ArrayOfOperationDetails.Add("GroupingsARAP.PaymentType_");
		ArrayOfOperationDetails.Add("GroupingsFinancialInstruments.PaymentType_");
	EndIf;
	If ParametersStructure.ShowPartner Then
		ArrayOfOperationDetails.Add("GroupingsARAP.Partner");
		ArrayOfOperationDetails.Add("GroupingsFinancialInstruments.Partner");
	EndIf;
	If ParametersStructure.ShowContract Then
		ArrayOfOperationDetails.Add("GroupingsARAP.Contract");
		ArrayOfOperationDetails.Add("GroupingsFinancialInstruments.Contract");
	EndIf;
	If ParametersStructure.ThereAreDiscrepancies Then
		ArrayOfOperationDetails.Add("DetailedRecordsARAPAccounting.DocumentAmountCounterparty");
		ArrayOfOperationDetails.Add("DetailedRecordsSettlementsSettlementsCounterparty");
		ArrayOfOperationDetails.Add("DetailedRecordsLoansAmountCounterparty");
		ArrayOfOperationDetails.Add("DetailedRecordsLoansAmountInterestCounterparty");
		ArrayOfOperationDetails.Add("DetailedRecordsLeasingLeaseObligationsCounterparty");
		ArrayOfOperationDetails.Add("DetailedRecordsLeasingSecurityPaymentCounterparty");
		ArrayOfOperationDetails.Add("DetailedRecordsLeasingRentalServiceCounterparty");
	EndIf;
	If ParametersStructure.ThereIsACommission Then
		ArrayOfOperationDetails.Add("DetailedRecordsLoansGroupCommission");
	EndIf;
	If ParametersStructure.ThereIsBuyoutOfLeasedAssets Then
		ArrayOfOperationDetails.Add("DetailedRecordsLeasingGroupBuyout");
	EndIf;
	If ParametersStructure.ThereAreDiscrepancies And ParametersStructure.ThereIsACommission Then
		ArrayOfOperationDetails.Add("DetailedRecordsLoansAmountCommissionCounterparty");
	EndIf;
	If ParametersStructure.ThereAreDiscrepancies And ParametersStructure.ThereIsBuyoutOfLeasedAssets Then
		ArrayOfOperationDetails.Add("DetailedRecordsLeasingPurchasePriceCounterparty");
	EndIf;
	
EndProcedure

// Specifies the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef.ARAPReconciliation2_4 - link to the document.
//
// Returns:
//	Structure - details of the selected document.
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
	|	Document.ARAPReconciliation2_4 AS DocumentData
	|		LEFT JOIN Document.ARAPReconciliation2_4.GroupingsARAP AS ARAPReconciliationOfFinalRecords
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
//	DocumentsArray - Array - Array of links to documents to check.
//	NewStatus - String - Name of the new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfARAPReconciliation[NewStatus];
	
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
	|	Document.ARAPReconciliation2_4 AS DocumentsTable
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
	
	Return "Document.ARAPReconciliation2_4";
	
EndFunction

Function MessageTextIsOutdatedDocument() Export
	
	Return NStr("vi = 'Chứng từ ""Biên bản đối chiếu công nợ (với các công cụ tài chính)"" đã cũ và sẽ bị xóa.
				|Nên sử dụng chứng từ ""Biên bản đối chiếu công nợ (2.5.11)""';
				|ru = 'Документ ""Сверка взаиморасчетов (с фин.инструментами)"" устарел и будет удален.
				|Рекомендуется использовать документ ""Сверка взаиморасчетов (2.5.11)""';
				|en = 'The ""AR/AP reconciliation (with financial instruments)"" document is outdated and will be deleted.
				|We recommend that you use the ""AR/AP reconciliation (2.5.11)"" document'; fa = 'The ""AR/AP reconciliation (with financial instruments)"" document is outdated and will be deleted.
				|We recommend that you use the ""AR/AP reconciliation (2.5.11)"" document';
				|it = 'Документ ""Сверка взаиморасчетов (с фин.инструментами)"" устарел и будет удален.
				|Рекомендуется использовать документ ""Сверка взаиморасчетов (2.5.11)""';
				|pl = 'The ""AR/AP reconciliation (with financial instruments)"" document is outdated and will be deleted.
				|We recommend that you use the ""AR/AP reconciliation (2.5.11)"" document';
				|tr = '""Alacak/ borç mutabakatı (finansal araçlarla)"" belgesi güncelliğini kaybetmiş ve silinecek.
				|""Alacak/ borç mutabakatı (2.5.11)"" belgesinin kullanılması tavsiye edilir.'");
	
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
	|	AND ValueAllowed(Counterparty.Partner)";

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

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "APARAccountsReconciliationStatement") Then
		
		PrintingDocuments = PrintingDocuments(ObjectsArray);
		
		PrintTemplate_ = New SpreadsheetDocument;
		DocumentsArray = New Array;
		If PrintingDocuments.New_Items.Count() > 0 Then
			PrintTemplate_ = GeneratePrintedFormOfReconciliationReport(PrintingDocuments.New_Items, PrintObjects);
			DocumentsArray = PrintingDocuments.New_Items;
			
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
			
		PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, DocumentsArray, PrintFormsCollection);
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfReconciliationOfMutualSettlementsWithDataOfCounterparty") Then
		
		PrintingDocuments = PrintingDocuments(ObjectsArray);
		
		PrintTemplate_ = New SpreadsheetDocument;
		DocumentsArray = New Array;
		
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
			"ActOfReconciliationOfMutualSettlementsWithDataOfCounterparty",
			NStr("vi = 'Biên bản đối chiếu công nợ (với dữ liệu công nợ của đối tác)';
				|ru = 'Акт сверки взаимных расчетов (с задолженностью по данными контрагента)';
				|en = 'AR/AP reconciliation statement (with debt amount according to the counterparty data)'; fa = 'AR/AP reconciliation statement (with debt amount according to the counterparty data)';
				|it = 'Акт сверки взаимных расчетов (с задолженностью по данными контрагента)';
				|pl = 'Protokół uzgadniania rozliczeń wzajemnych (z zadłużeniem według danych kontrahenta)';
				|tr = 'Mutabakat raporu (gecikmeli cari hesap verileriyle)'"),
			PrintTemplate_);
			
		PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, DocumentsArray, PrintFormsCollection);
		
	EndIf;
	
EndProcedure

// To form a printed form of the reconciliation report of mutual settlements
//
// Parameters:
//   ObjectsArray  - Array of DocumentRef.ARAPReconciliation2_4 - Array of references to objects to be printed.
//   Print Parameters - Structure - Structure of additional printing parameters.
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
	
	SpreadsheetDocument = New SpreadsheetDocument;
	FirstDocument = True;
	ReconciliationData = QueryResult.Unload(QueryResultIteration.ByGroups);
	For Each DocumentData In ReconciliationData.Rows Do
		
		Template = PrintManagement.PrintFormTemplate("Document.ARAPReconciliation2_4.PF_MXL_APARAccountsReconciliationStatement"); // SpreadsheetDocument - 
		
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
														|tr = 'dönem içerisinde: %1'", Common.DefaultLanguageCode()), PeriodPresentation);
				
			Else
				PeriodPresentation = StrTemplate(NStr("vi = 'trong %1';
														|ru = 'за %1';
														|en = '%1 before'; fa = '%1 before';
														|it = 'за %1';
														|pl = 'za %1';
														|tr = 'dönemin: %1'", Common.DefaultLanguageCode()), PeriodPresentation);
				
			EndIf;
			
			SettlementPeriodTemplate = NStr("vi = 'Trong kỳ từ %1 đến %2, đã thực hiện các phép tính sau';
											|ru = 'В период с %1 по %2 были осуществлены следующие расчеты';
											|en = 'In the period from %1 to %2 the following settlements were made'; fa = 'In the period from %1 to %2 the following settlements were made';
											|it = 'В период с %1 по %2 были осуществлены следующие расчеты';
											|pl = 'W okresie od %1 do %2 następujących wykonano obliczenia';
											|tr = 'Dönem %1 ila %2''de aşağıdaki hesaplamalar yapılmıştır'", Common.DefaultLanguageCode())+":";
			If Not ThereAreTurnoverBalancesForPeriod Then
				SettlementPeriodTemplate = NStr("vi = 'Trong kỳ từ %1 đến %2, không có giao dịch hạch toán nào được thực hiện.';
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
		If ValueIsFilled(DocumentData.Contract) Then
			TemplateArea.Parameters.PresentationOfContract = NStr("vi = 'theo hợp đồng';
																	|ru = 'по договору';
																	|en = 'by contract'; fa = 'بر اساس قرارداد';
																	|it = 'по договору';
																	|pl = 'wg kontraktu';
																	|tr = 'sözleşme kapsamında'", Common.DefaultLanguageCode()) + ": " + DocumentData.PresentationOfContract;
		EndIf;
		TemplateArea.Parameters.Fill(StructureOfParticipantsPresentations);
		TemplateArea.Parameters.TemplateTitleText         = TitleText;
		TemplateArea.Parameters.FullNameOfCounterpartyExecutive   = TrimAll(DocumentData.FullNameOfCounterpartyExecutive);
		TemplateArea.Parameters.PeriodPresentation         = PeriodPresentation;
		TemplateArea.Parameters.PresentationOfTheSettlementPeriod = PresentationOfTheSettlementPeriod;
		
		SpreadsheetDocument.Put(TemplateArea);
		#EndRegion
		
		#Region DetailedRecords
		NumberType = TMCommonUse.MoneyFieldTypeDescription();
		TotalDebt_ = New ValueTable;
		TotalDebt_.Columns.Add("Currency");
		TotalDebt_.Columns.Add("SumDr", NumberType);
		TotalDebt_.Columns.Add("SumCr", NumberType);
		PrintSettings.Insert("PresentationsOfParticipants", StructureOfParticipantsPresentations);
		For Each DataByTypeOfCalculations In DocumentData.Rows Do
			For Each CurrencyData_ In DataByTypeOfCalculations.Rows Do
				CurrencyData_.Rows.Sort("GroupingObject,PresentationTypeOfCalculations");
				For Each DataForGroupingItem In CurrencyData_.Rows Do
					ThereIsGroupingData = DataForGroupingItem.OpeningBalanceDr <> 0
												Or DataForGroupingItem.OpeningBalanceCr <> 0
												Or DataForGroupingItem.ThereAreRevolutions;
					If ThereIsGroupingData Then
						SpreadsheetDocument.Put(OutputDetailedRecords(DataForGroupingItem, DocumentData, Template, TotalDebt_, PrintSettings));
					EndIf;
				EndDo; // by detailed records
			EndDo; // by detailed records
		EndDo; // by types of settlements Mutual settlements/Financial tools
		#EndRegion
		
		#Region Debt_
		If TotalDebt_.Count() > 0 Then
			
			HeaderTemplateArea	= Template.GetArea("TitleArrears");
			AreaOfResponsibility				= Template.GetArea("RowArrears");
			AreaOfDebtRegl			= Template.GetArea("RowDebtLocalCurrency");
			EmptyStringArea		= Template.GetArea("IsBlankString");
			
			HeaderTemplateArea.Parameters.ReconciliationPeriodEnd = Format(DocumentData.EndOfPeriod, "DLF=DD");
			SpreadsheetDocument.Put(HeaderTemplateArea);
			
			CurrencyArrears = TotalDebt_.Copy(); // ValueTable
			CurrencyArrears.GroupBy("Currency", "SumDr,SumCr");
			For Each DebtInForeignCurrency In CurrencyArrears Do
				
				OutputBlankRow = True;
				PartnerPresentation_ = DocumentData.PartnerPresentation_;
				If Not ValueIsFilled(DocumentData.Partner) Then
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
	
	Return SpreadsheetDocument;
	
EndFunction

Function OutputDetailedRecords(
	DataForGroupingItem,
	DocumentData,
	Template,
	TotalDebt_,
	PrintSettings)
	
	StructureOfParticipantsPresentations = PrintSettings.PresentationsOfParticipants;
	
	TheseAreFinancialInstruments = DataForGroupingItem.FinancialInstruments;
	WithdrawDebtInAdvance = Not TheseAreFinancialInstruments And Not PrintSettings.DebtAsDebit;
	SpreadsheetDocument = New SpreadsheetDocument;
	
	#Region PrintAreas
	DimensionTemplateArea = Template.GetArea("GroupingObjectContractCurrency");
	If TheseAreFinancialInstruments Then
		HeaderTemplateArea_		= Template.GetArea("HeaderOfFinToolsTable");
		InitialTemplateArea	= Template.GetArea("TableRowInitialFinTools");
		LayoutAreaString 		= Template.GetArea("RowOfFinToolsTable");
		RevolutionsTemplateArea 		= Template.GetArea("TurnoverForPeriodFinInstruments");
		ConeTemplateArea	= Template.GetArea("TableRowConBalanceFinTools");
		If PrintSettings.DoNotFillInTheCounterpartySData Then
			InitialTemplateArea.Area("AmountCounterpartyInitialBalanceFin").Format = "NFD=2";
			LayoutAreaString.Area("AmountCounterpartyFin").Format = "NFD=2";
			RevolutionsTemplateArea.Area("AmountCounterpartyTurnoverFin").Format = "NFD=2";
			ConeTemplateArea.Area("AmountCounterpartyConBalanceFin").Format = "NFD=2";
		EndIf;
	Else
		HeaderTemplateArea_	 = Template.GetArea("TableHeader");
		InitialTemplateArea  = Template.GetArea("RowOfInitialBalanceTable");
		LayoutAreaString 	 = Template.GetArea("TableRow");
		RevolutionsTemplateArea 	 = Template.GetArea("TurnoverForAPeriod");
		ConeTemplateArea  = Template.GetArea("TableRowConRemainder");
		If PrintSettings.DoNotFillInTheCounterpartySData Then
			InitialTemplateArea.Area("AmountCounterpartyBalance").Format = "NFD=2";
			LayoutAreaString.Area("AmountCounterparty").Format = "NFD=2";
			RevolutionsTemplateArea.Area("AmountCounterpartyTurnover").Format = "NFD=2";
			ConeTemplateArea.Area("AmountCounterpartyConBalance").Format = "NFD=2";
		EndIf;
	EndIf;
	#EndRegion
	
	#Region DisplayingNameOfDimension
	Currency = StrTemplate(NStr("vi = 'theo tiền tệ';
								|ru = 'в валюте';
								|en = 'in currency'; fa = 'به ارز';
								|it = 'в валюте';
								|pl = 'w walucie';
								|tr = 'para biriminde'", Common.DefaultLanguageCode()) + " %1", DataForGroupingItem.Currency);
	TitleTemplate1 = DataForGroupingItem.PresentationTypeOfCalculations;
	If PrintSettings.MutualSettlementsDetails = "ARAPObject"
		And (DataForGroupingItem.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting
			Or DataForGroupingItem.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting) Then
		TitleTemplate1 = ?(TitleTemplate1 = Undefined, "", TitleTemplate1 + " ") + NStr("vi = 'theo đối tượng hạch toán';
																						|ru = 'по объекту расчетов';
																						|en = 'by AR/AP object'; fa = 'by AR/AP object';
																						|it = 'по объекту расчетов';
																						|pl = 'na temat obliczeń';
																						|tr = 'alacak/borç nesnesi kapsamında'", Common.DefaultLanguageCode()) + " %1 ";
	ElsIf PrintSettings.MutualSettlementsDetails = "Contract" And Not TheseAreFinancialInstruments
	 		Or PrintSettings.DetailingFinancialInstruments = "Contract" And TheseAreFinancialInstruments Then
		TitleTemplate1 = ?(TitleTemplate1 = Undefined, "", TitleTemplate1 + " ") + NStr("vi = 'theo hợp đồng';
																						|ru = 'по договору';
																						|en = 'by contract'; fa = 'بر اساس قرارداد';
																						|it = 'по договору';
																						|pl = 'wg kontraktu';
																						|tr = 'sözleşme kapsamında'", Common.DefaultLanguageCode()) + " %1 ";
	EndIf;
	
	TextOfDimensionObject = "<" + NStr("vi = 'chưa chỉ định';
										|ru = 'не указан';
										|en = 'not specified'; fa = 'مشخص نشده';
										|it = 'не указан';
										|pl = 'nie określony';
										|tr = 'belirtilmedi'", Common.DefaultLanguageCode()) + ">";
	If ValueIsFilled(DataForGroupingItem.DimensionObjectPresentation) Then
		TextOfDimensionObject = DataForGroupingItem.DimensionObjectPresentation;
	EndIf;
	
	GroupHeader = ?(TitleTemplate1 = Undefined, "", TitleTemplate1 + " ") + Currency;
	If PrintSettings.MutualSettlementsDetails <> "Currency" And Not TheseAreFinancialInstruments
		Or PrintSettings.DetailingFinancialInstruments <> "Currency" And TheseAreFinancialInstruments Then
		TitleTemplate1 = ?(TitleTemplate1 = Undefined, "%1 ", TitleTemplate1);
		GroupHeader = StrTemplate(TitleTemplate1, TextOfDimensionObject) + Currency;
	EndIf;
	DimensionTemplateArea.Parameters.GroupHeader = GroupHeader;
	SpreadsheetDocument.Put(DimensionTemplateArea);
	#EndRegion
	
	#Region TableHeaderOutput
	HeaderTemplateArea_.Parameters.Fill(StructureOfParticipantsPresentations);
	HeaderTemplateArea_.Parameters.Debit = NStr("vi = 'Công nợ';
												|ru = 'Долг';
												|en = 'Debt'; fa = 'بدهی';
												|it = 'Долг';
												|pl = 'Debt';
												|tr = 'Borç'", Common.DefaultLanguageCode());
	HeaderTemplateArea_.Parameters.Credit = NStr("vi = 'Ứng trước';
												|ru = 'Аванс';
												|en = 'Advance'; fa = 'پیش‌پرداخت';
												|it = 'Аванс';
												|pl = 'Advance';
												|tr = 'Avans'", Common.DefaultLanguageCode());
	InitialTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư đầu';
														|ru = 'Сальдо начальное';
														|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
														|it = 'Сальдо начальное';
														|pl = 'Saldo początkowe';
														|tr = 'Açılış bakiyesi'", Common.DefaultLanguageCode());
	ConeTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư cuối';
													|ru = 'Сальдо конечное';
													|en = 'Closing balance'; fa = 'مانده پایان دوره';
													|it = 'Сальдо конечное';
													|pl = 'Saldo końcowe';
													|tr = 'Kapanış bakiyesi'", Common.DefaultLanguageCode());
	If PrintSettings.DebtAsDebit Or TheseAreFinancialInstruments Then
		HeaderTemplateArea_.Parameters.Debit = NStr("vi = 'Nợ';
													|ru = 'Дебет';
													|en = 'Debit'; fa = 'بدهکار';
													|it = 'Дебет';
													|pl = 'Debet';
													|tr = 'Borç'", Common.DefaultLanguageCode());
		HeaderTemplateArea_.Parameters.Credit = NStr("vi = 'Có';
													|ru = 'Кредит';
													|en = 'Credit'; fa = 'بستانکار';
													|it = 'Кредит';
													|pl = 'Ma';
													|tr = 'Alacak'", Common.DefaultLanguageCode());
		InitialTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư đầu';
															|ru = 'Сальдо начальное';
															|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
															|it = 'Сальдо начальное';
															|pl = 'Saldo początkowe';
															|tr = 'Açılış bakiyesi'", Common.DefaultLanguageCode());
		ConeTemplateArea.Parameters.RemainderName = NStr("vi = 'Dư cuối';
														|ru = 'Сальдо конечное';
														|en = 'Closing balance'; fa = 'مانده پایان دوره';
														|it = 'Сальдо конечное';
														|pl = 'Saldo końcowe';
														|tr = 'Kapanış bakiyesi'", Common.DefaultLanguageCode());
	EndIf;
	SpreadsheetDocument.Put(HeaderTemplateArea_);
	#EndRegion
	
	#Region OutputOfInitialRemainder
	InitialTemplateArea.Parameters.DebitAmount = DataForGroupingItem.OpeningBalanceDr;
	InitialTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.OpeningBalanceCr;
	
	InitialTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.OpeningBalanceCr;
	InitialTemplateArea.Parameters.AmountCreditCounterparty = DataForGroupingItem.OpeningBalanceDr;
	If WithdrawDebtInAdvance Then
		ClearDebitCredit(InitialTemplateArea);
		If DataForGroupingItem.OpeningBalance > 0 Then
			InitialTemplateArea.Parameters.DebitAmount = DataForGroupingItem.OpeningBalance;
			InitialTemplateArea.Parameters.AmountDebitCounterparty = DataForGroupingItem.OpeningBalance;
		Else
			InitialTemplateArea.Parameters.LoanAmount_ = -DataForGroupingItem.OpeningBalance;
			InitialTemplateArea.Parameters.AmountCreditCounterparty = -DataForGroupingItem.OpeningBalance;
		EndIf;
	EndIf;
	If PrintSettings.DoNotFillInTheCounterpartySData Then
		InitialTemplateArea.Parameters.AmountDebitCounterparty = 0;
		InitialTemplateArea.Parameters.AmountCreditCounterparty = 0;
	EndIf;
	SpreadsheetDocument.Put(InitialTemplateArea);
	#EndRegion
	
	TurnoverAssetCounterparty = New Structure("AmountDebitCounterparty, AmountCreditCounterparty", 0, 0);
	TurnoverLiabilityCounterparty = New Structure("AmountDebitCounterparty, AmountCreditCounterparty", 0, 0);
	SettlementDocumentsOfPeriod = New Array;
	Turnovers = New Structure("Debt,Prepayment_,Debit,Credit",0,0,0,0);
	If DataForGroupingItem.ThereAreRevolutions Then
		For Each DetailedRecords In DataForGroupingItem.Rows Do
			
			If TypeOf(DetailedRecords.ARAPDocument) = Type("DocumentRef.ARAPSettlement")
				And DetailedRecords.DebitAmount - DetailedRecords.LoanAmount_ = 0 Then
				Continue;
			EndIf;
			
			SettlementDocumentsOfPeriod.Add(DetailedRecords.ARAPDocument);
			
			If TheseAreFinancialInstruments Then
				LayoutAreaString = Template.GetArea("RowOfFinToolsTable");
				If PrintSettings.DoNotFillInTheCounterpartySData Then
					LayoutAreaString.Area("AmountCounterpartyFin").Format = "NFD=2";
				EndIf;
			Else
				LayoutAreaString = Template.GetArea("TableRow");
				If PrintSettings.DoNotFillInTheCounterpartySData Then
					LayoutAreaString.Area("AmountCounterparty").Format = "NFD=2";
				EndIf;
			EndIf;
			
			FillPropertyValues(LayoutAreaString.Parameters, DetailedRecords);
			LayoutAreaString.Parameters.Date = Format(DetailedRecords.DocumentDate, "DLF=D");
			Turnovers.Debit = Turnovers.Debit + DetailedRecords.DebitAmount;
			Turnovers.Credit = Turnovers.Credit + DetailedRecords.LoanAmount_;
			If WithdrawDebtInAdvance Then
				ClearDebitCredit(LayoutAreaString);
				LayoutAreaString.Parameters.DebitAmount = DetailedRecords.DebtAmount_;
				LayoutAreaString.Parameters.LoanAmount_ = DetailedRecords.AmountPrepayment;
				LayoutAreaString.Parameters.AmountDebitCounterparty = DetailedRecords.DebtAmountCounterparty;
				LayoutAreaString.Parameters.AmountCreditCounterparty = DetailedRecords.AmountPrepaymentCounterparty;
				Turnovers.Debt = Turnovers.Debt + DetailedRecords.DebtAmount_;
				Turnovers.Prepayment_ = Turnovers.Prepayment_ + DetailedRecords.AmountPrepayment;
			EndIf;
			If PrintSettings.DoNotFillInTheCounterpartySData Then
				If Not TheseAreFinancialInstruments Then
					LayoutAreaString.Parameters.DocumentAmountCounterparty = 0;
				EndIf;
				LayoutAreaString.Parameters.AmountDebitCounterparty = 0;
				LayoutAreaString.Parameters.AmountCreditCounterparty = 0;
			EndIf;
			SpreadsheetDocument.Put(LayoutAreaString);
				
			If DetailedRecords.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting
				Or DetailedRecords.PaymentType_ = Undefined
				Or DetailedRecords.AmountType = Enums.TypesOfLeasePayments.LeaseObligations
				Or DetailedRecords.AmountType = Enums.TypesOfLeasePayments.RentalService
				Or DetailedRecords.AmountType = Enums.TypesOfLeasePayments.RentalServicePrepayment
				Or DetailedRecords.AmountType = Enums.TypesOfLeasePayments.BuyoutValue
				Or DetailedRecords.PaymentType_ = Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting Then
				AddCounterpartyTurnover(TurnoverAssetCounterparty, DetailedRecords, WithdrawDebtInAdvance);
				
			ElsIf DetailedRecords.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting
				Or DetailedRecords.AmountType = Enums.TypesOfLeasePayments.DepositPayment
				Or DetailedRecords.PaymentType_ = Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting Then
				AddCounterpartyTurnover(TurnoverLiabilityCounterparty, DetailedRecords, WithdrawDebtInAdvance);
				
			EndIf;
		
		EndDo; 
	EndIf;
	
	#Region OutputOfRevolutionsForPeriod
	FillPropertyValues(RevolutionsTemplateArea.Parameters, DataForGroupingItem);
	RevolutionsTemplateArea.Parameters.DebitAmount = Turnovers.Debit;
	RevolutionsTemplateArea.Parameters.LoanAmount_ = Turnovers.Credit;
	If WithdrawDebtInAdvance Then
		ClearDebitCredit(RevolutionsTemplateArea);
		RevolutionsTemplateArea.Parameters.DebitAmount = Turnovers.Debt;
		RevolutionsTemplateArea.Parameters.LoanAmount_ = Turnovers.Prepayment_;
	EndIf;
	If DataForGroupingItem.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting
			Or DataForGroupingItem.PaymentType_ = Undefined Then
		RevolutionsTemplateArea.Parameters.AmountDebitCounterparty = TurnoverAssetCounterparty.AmountDebitCounterparty;
		RevolutionsTemplateArea.Parameters.AmountCreditCounterparty = TurnoverAssetCounterparty.AmountCreditCounterparty;
	ElsIf DataForGroupingItem.PaymentType_ = Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor
		Or DataForGroupingItem.PaymentType_ = Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting Then
		RevolutionsTemplateArea.Parameters.AmountDebitCounterparty = TurnoverAssetCounterparty.AmountDebitCounterparty + TurnoverLiabilityCounterparty.AmountDebitCounterparty;
		RevolutionsTemplateArea.Parameters.AmountCreditCounterparty = TurnoverAssetCounterparty.AmountCreditCounterparty + TurnoverLiabilityCounterparty.AmountCreditCounterparty;
	Else
		RevolutionsTemplateArea.Parameters.AmountDebitCounterparty = TurnoverLiabilityCounterparty.AmountDebitCounterparty;
		RevolutionsTemplateArea.Parameters.AmountCreditCounterparty = TurnoverLiabilityCounterparty.AmountCreditCounterparty;
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
	FillPropertyValues(ConeTemplateArea.Parameters, DataForGroupingItem);
	If DataForGroupingItem.PaymentType_ = Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor Then
		If DataForGroupingItem.ClosingBalanceDr > 0 And DataForGroupingItem.ClosingBalanceCr > 0 Then
			ClosingBalance(DataForGroupingItem.ClosingBalanceDr, DataForGroupingItem.ClosingBalanceCr);
		EndIf;
	EndIf;
	ConeTemplateArea.Parameters.DebitAmount = DataForGroupingItem.ClosingBalanceDr;
	ConeTemplateArea.Parameters.LoanAmount_ = DataForGroupingItem.ClosingBalanceCr;
	
	ConeTemplateArea.Parameters.AmountDebitCounterparty = 0;
	ConeTemplateArea.Parameters.AmountCreditCounterparty = 0;
	
	InitialBalanceCounterpartyDr = DataForGroupingItem.OpeningBalanceCr;
	InitialBalanceCounterpartyCr = DataForGroupingItem.OpeningBalanceDr;
	FinalBalanceCounterpartyDr = InitialBalanceCounterpartyDr + TurnoverAssetCounterparty.AmountDebitCounterparty - TurnoverAssetCounterparty.AmountCreditCounterparty;
	FinalBalanceCounterpartyCr = InitialBalanceCounterpartyCr - TurnoverLiabilityCounterparty.AmountDebitCounterparty + TurnoverLiabilityCounterparty.AmountCreditCounterparty;
	
	If DataForGroupingItem.PaymentType_ = Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor Then
		If FinalBalanceCounterpartyDr < 0 Then
			FinalBalanceCounterpartyCr = FinalBalanceCounterpartyCr - FinalBalanceCounterpartyDr;
			FinalBalanceCounterpartyDr = 0;
		EndIf;
		If FinalBalanceCounterpartyCr < 0 Then
			FinalBalanceCounterpartyDr = FinalBalanceCounterpartyDr - FinalBalanceCounterpartyCr;
			FinalBalanceCounterpartyCr = 0;
		EndIf;
		If FinalBalanceCounterpartyDr > 0 And FinalBalanceCounterpartyCr > 0 Then
			ClosingBalance(FinalBalanceCounterpartyDr, FinalBalanceCounterpartyCr);
		EndIf;
	Else
		ClosingBalance(FinalBalanceCounterpartyDr, FinalBalanceCounterpartyCr);
	EndIf;
	
	ConeTemplateArea.Parameters.AmountDebitCounterparty = FinalBalanceCounterpartyDr;
	ConeTemplateArea.Parameters.AmountCreditCounterparty = FinalBalanceCounterpartyCr;
	If WithdrawDebtInAdvance Then
		ClearDebitCredit(ConeTemplateArea);
		If DataForGroupingItem.ClosingBalance > 0 Then
			ConeTemplateArea.Parameters.DebitAmount = DataForGroupingItem.ClosingBalance;
		Else
			ConeTemplateArea.Parameters.LoanAmount_ = -DataForGroupingItem.ClosingBalance;
		EndIf;
		
		FinalBalanceCounterparty = DataForGroupingItem.OpeningBalance
								+ DataForGroupingItem.DebtAmountCounterparty
								- DataForGroupingItem.AmountPrepaymentCounterparty;
		
		If FinalBalanceCounterparty > 0 Then
			ConeTemplateArea.Parameters.AmountDebitCounterparty = FinalBalanceCounterparty;
		Else
			ConeTemplateArea.Parameters.AmountCreditCounterparty = -FinalBalanceCounterparty;
		EndIf;
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

Procedure ClosingBalance(ClosingBalanceDr, ClosingBalanceCr)
	
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
//  Structure:
//   * WithdrawInTheReglCurrency - Boolean - 
//   * MutualSettlementsDetails - Number - 
//   * DetailingFinancialInstruments - Number -    
//   * DebtAsDebit - Boolean - 
//   * DoNotFillInTheCounterpartySData - Boolean - 
//   * MergeCustomersSuppliers - Boolean - 
//
Function DefaultPrintSettings() Export
	
	Result = New Structure;
	Result.Insert("WithdrawInTheReglCurrency", True);
	Result.Insert("MutualSettlementsDetails", 0);
	Result.Insert("DetailingFinancialInstruments", 0);
	Result.Insert("DebtAsDebit", True);
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
//  ObjectsArray - Array of DocumentRef.ARAPReconciliation2_5_11 - Array of objects
//  PrintSettings - Structure - Print Settings:
// * WithdrawInTheReglCurrency - Boolean - 
// * MutualSettlementsDetails - Number - 
// * DetailingFinancialInstruments - Number - 
// * DebtAsDebit - Boolean - 
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
	
	RequestDocumentData.SetParameter("ObjectsArray", ObjectsArray);
	RequestDocumentData.SetParameter("DebtAsDebit", PrintSettings.DebtAsDebit);
	RequestDocumentData.SetParameter("WithdrawInTheReglCurrency", PrintSettings.WithdrawInTheReglCurrency);
	RequestDocumentData.SetParameter("MergeCustomersSuppliers", PrintSettings.MergeCustomersSuppliers);
	
	RequestDocumentData.SetParameter("LeaseObligations", Undefined);
	RequestDocumentData.SetParameter("DepositPayment", Undefined);
	RequestDocumentData.SetParameter("RentalService", Undefined);
	RequestDocumentData.SetParameter("BuyoutValue", Undefined);
	RequestDocumentData.SetParameter("LeaseObligations", Enums.TypesOfLeasePayments.LeaseObligations);
	RequestDocumentData.SetParameter("DepositPayment", Enums.TypesOfLeasePayments.DepositPayment);
	RequestDocumentData.SetParameter("RentalService", Enums.TypesOfLeasePayments.RentalService);
	RequestDocumentData.SetParameter("BuyoutValue", Enums.TypesOfLeasePayments.BuyoutValue);
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
		ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(Documents.ARAPReconciliation2_4.EmptyRef(), TempTablesManager, ParametersOfResponsiblePersons);
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
			Documents.ARAPReconciliation2_4.EmptyRef(),
			TempTablesManager,
			ParametersOfResponsiblePersons);
	EndIf;
	
	Return TempTablesManager;
	
EndFunction

Function QueryTextDocumentData(PrintSettings)
	
	#Region QueryText
	QueryText = 
	"SELECT
	|	TsForCalculations.Ref AS Ref,
	|	TsForCalculations.PaymentType_ AS PaymentType_,
	|	TsForCalculations.ARAPObject AS ARAPObject,
	|	TsForCalculations.Contract AS Contract,
	|	CASE WHEN &WithdrawInTheReglCurrency THEN TsForCalculations.Ref.Organization.LocalAccountingCurrency ELSE TsForCalculations.Currency END AS Currency,
	|	SUM(CASE WHEN &WithdrawInTheReglCurrency THEN TsForCalculations.OpeningBalanceLocal ELSE TsForCalculations.OpeningBalance END) AS OpeningBalance,
	|	SUM(CASE WHEN &WithdrawInTheReglCurrency THEN TsForCalculations.TurnoverDebitLocal ELSE TsForCalculations.TurnoverReceipt END) AS TurnoverReceipt,
	|	SUM(CASE WHEN &WithdrawInTheReglCurrency THEN TsForCalculations.TurnoverCreditLocal ELSE TsForCalculations.TurnoverExpense END) AS TurnoverExpense,
	|	SUM(CASE WHEN &WithdrawInTheReglCurrency THEN TsForCalculations.ClosingBalanceLocal ELSE TsForCalculations.ClosingBalance END) AS ClosingBalance
	|INTO TsForCalculations
	|FROM
	|	Document.ARAPReconciliation2_4.GroupingsARAP AS TsForCalculations
	|WHERE
	|	TsForCalculations.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	TsForCalculations.Ref,
	|	TsForCalculations.PaymentType_,
	|	TsForCalculations.ARAPObject,
	|	TsForCalculations.Contract,
	|	CASE WHEN &WithdrawInTheReglCurrency THEN TsForCalculations.Ref.Organization.LocalAccountingCurrency ELSE TsForCalculations.Currency END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TsForCalculations.Ref AS Ref,
	|	UNDEFINED AS PaymentType_,
	|	TsForCalculations.ARAPObject AS ARAPObject,
	|	TsForCalculations.Contract AS Contract,
	|	TsForCalculations.Currency AS Currency,
	|	SUM(CASE WHEN TsForCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		THEN
	|			-TsForCalculations.OpeningBalance
	|		ELSE
	|			TsForCalculations.OpeningBalance
	|	END) AS OpeningBalance,
	|	SUM(TsForCalculations.TurnoverReceipt) AS TurnoverReceipt,
	|	SUM(TsForCalculations.TurnoverExpense) AS TurnoverExpense,
	|	SUM(CASE WHEN TsForCalculations.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		THEN
	|			-TsForCalculations.ClosingBalance
	|		ELSE
	|			TsForCalculations.ClosingBalance
	|	END) AS ClosingBalance
	|INTO TSDimensionsForAllTypesOfCalculations
	|FROM
	|	TsForCalculations AS TsForCalculations
	|
	|GROUP BY
	|	TsForCalculations.Ref,
	|	TsForCalculations.ARAPObject,
	|	TsForCalculations.Contract,
	|	TsForCalculations.Currency
	|	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSGroupingsARAP.Ref AS DocumentRef,
	|	TSGroupingsARAP.Ref.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	TSGroupingsARAP.PaymentType_ AS PaymentType_,
	|	TSGroupingsARAP.Contract AS Contract,
	|	TSDetailedRecordsARAPAccounting.ARAPObject AS ARAPObject,
	|	TSDetailedRecordsARAPAccounting.ARAPDocument AS ARAPDocument,
	|	TSDetailedRecordsARAPAccounting.DocumentDetails AS DocumentDetails,
	|	TSGroupingsARAP.Currency AS Currency,
	|	TSDetailedRecordsARAPAccounting.DocumentCurrency AS DocumentCurrency,
	|	
	|	TSDetailedRecordsARAPAccounting.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN TSDetailedRecordsARAPAccounting.Ref.ThereAreDiscrepancies
	|			THEN 
	|				TSDetailedRecordsARAPAccounting.DocumentAmountCounterparty
	|		ELSE 
	|			TSDetailedRecordsARAPAccounting.DocumentAmount
	|	END AS DocumentAmountCounterparty,
	|	CASE WHEN &WithdrawInTheReglCurrency THEN TSDetailedRecordsARAPAccounting.DebtAmountLocal ELSE TSDetailedRecordsARAPAccounting.DebtAmount_ END AS DebtAmount_,
	|	CASE WHEN &WithdrawInTheReglCurrency THEN TSDetailedRecordsARAPAccounting.PrepaymentAmountLocal_ ELSE TSDetailedRecordsARAPAccounting.AmountPrepayment END AS AmountPrepayment,
	|	TSDetailedRecordsARAPAccounting.AmountARAP AS AmountARAP,
	|	CASE
	|		WHEN TSDetailedRecordsARAPAccounting.Ref.ThereAreDiscrepancies
	|			THEN 
	|				TSDetailedRecordsARAPAccounting.DebtAmountCounterparty
	|		ELSE 
	|			CASE WHEN &WithdrawInTheReglCurrency THEN TSDetailedRecordsARAPAccounting.DebtAmountLocal ELSE TSDetailedRecordsARAPAccounting.DebtAmount_ END
	|	END AS DebtAmountCounterparty,
	|	CASE
	| 		WHEN TSDetailedRecordsARAPAccounting.Ref.ThereAreDiscrepancies
	|			THEN 
	|				TSDetailedRecordsARAPAccounting.AmountPrepaymentCounterparty
	|		ELSE 
	|			CASE WHEN &WithdrawInTheReglCurrency THEN TSDetailedRecordsARAPAccounting.PrepaymentAmountLocal_ ELSE TSDetailedRecordsARAPAccounting.AmountPrepayment END
	|	END AS AmountPrepaymentCounterparty,
	|	CASE
	|		WHEN TSDetailedRecordsARAPAccounting.Ref.ThereAreDiscrepancies
	|			THEN 
	|				TSDetailedRecordsARAPAccounting.AmountARAPCounterparty
	|		ELSE 
	|			TSDetailedRecordsARAPAccounting.AmountARAP
	|	END  AS AmountARAPCounterparty
	|
	|INTO DetailedCalculationRecords
	|FROM
	|	TsForCalculations AS TSGroupingsARAP
	|		LEFT JOIN Document.ARAPReconciliation2_4.DetailedRecordsARAPAccounting AS TSDetailedRecordsARAPAccounting
	|		ON TSGroupingsARAP.Ref = TSDetailedRecordsARAPAccounting.Ref
	|			AND TSGroupingsARAP.ARAPObject = TSDetailedRecordsARAPAccounting.ARAPObject
	|			AND TSGroupingsARAP.Contract = TSDetailedRecordsARAPAccounting.Contract
	|WHERE
	|	TSDetailedRecordsARAPAccounting.Ref IN(&ObjectsArray)
	|	AND (&WithdrawInTheReglCurrency
	|		OR NOT &WithdrawInTheReglCurrency AND (VALUETYPE(TSDetailedRecordsARAPAccounting.ARAPDocument) <> TYPE(Document.ExchangeDifferenceCalculation)))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupingCalculations.Ref AS DocumentRef,
	|	GroupingCalculations.PaymentType_ AS PaymentType_,
	|	GroupingCalculations.Contract AS GroupingObject,
	|	GroupingCalculations.Currency AS Currency,
	|	SUM(GroupingCalculations.OpeningBalance) AS OpeningBalance,
	|	SUM(GroupingCalculations.TurnoverReceipt) AS TurnoverReceipt,
	|	SUM(GroupingCalculations.TurnoverExpense) AS TurnoverExpense,
	|	SUM(GroupingCalculations.ClosingBalance) AS ClosingBalance
	|INTO TTCalculationGrouping
	|FROM
	|	TsForCalculations AS GroupingCalculations
	|WHERE
	|	NOT &MergeCustomersSuppliers
	|
	|GROUP BY
	|	GroupingCalculations.Ref,
	|	GroupingCalculations.PaymentType_,
	|	GroupingCalculations.Contract,
	|	GroupingCalculations.Currency
	|
	|UNION ALL
	|
	|SELECT
	|	GroupingCalculations.Ref AS DocumentRef,
	|	GroupingCalculations.PaymentType_ AS PaymentType_,
	|	GroupingCalculations.Contract AS GroupingObject,
	|	GroupingCalculations.Currency AS Currency,
	|	SUM(GroupingCalculations.OpeningBalance) AS OpeningBalance,
	|	SUM(GroupingCalculations.TurnoverReceipt) AS TurnoverReceipt,
	|	SUM(GroupingCalculations.TurnoverExpense) AS TurnoverExpense,
	|	SUM(GroupingCalculations.ClosingBalance) AS ClosingBalance
	|FROM
	|	TSDimensionsForAllTypesOfCalculations AS GroupingCalculations
	|WHERE
	|	&MergeCustomersSuppliers
	|
	|GROUP BY
	|	GroupingCalculations.Ref,
	|	GroupingCalculations.PaymentType_,
	|	GroupingCalculations.Contract,
	|	GroupingCalculations.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Groups.DocumentRef AS DocumentRef,
	|	Groups.PaymentType_ AS PaymentType_,
	|	DetailedCalculationRecords.PaymentType_ AS PaymentType_2,
	|	Groups.GroupingObject AS GroupingObject,
	|	REFPRESENTATION(Groups.GroupingObject) AS DimensionObjectPresentation,
	|	
	|	Groups.OpeningBalance AS OpeningBalance,
	|	CASE
	|		WHEN (Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					OR Groups.PaymentType_ = UNDEFINED)
	|				AND Groups.OpeningBalance > 0
	|			THEN 
	|				Groups.OpeningBalance
	|			
	|		WHEN Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND Groups.OpeningBalance < 0
	|			THEN 
	|				-Groups.OpeningBalance
	|		ELSE
	|			0
	|	END AS OpeningBalanceDr,
	|	CASE
	|		WHEN (Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					OR Groups.PaymentType_ = UNDEFINED)
	|				AND Groups.OpeningBalance < 0
	|			THEN 
	|				-Groups.OpeningBalance
	|			
	|		WHEN Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND Groups.OpeningBalance > 0
	|			THEN 
	|				Groups.OpeningBalance
	|		ELSE
	|			0
	|	END AS OpeningBalanceCr,
	|	Groups.TurnoverReceipt AS TurnoverReceipt,
	|	Groups.TurnoverExpense AS TurnoverExpense,
	|	Groups.ClosingBalance AS ClosingBalance,
	|	CASE
	|		WHEN (Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					OR Groups.PaymentType_ = UNDEFINED)
	|				AND Groups.ClosingBalance > 0
	|			THEN 
	|				Groups.ClosingBalance
	|			
	|		WHEN Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND Groups.ClosingBalance < 0
	|			THEN 
	|				-Groups.ClosingBalance
	|		ELSE
	|			0
	|	END AS ClosingBalanceDr,
	|	CASE
	|		WHEN (Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					OR Groups.PaymentType_ = UNDEFINED)
	|				AND Groups.ClosingBalance < 0
	|			THEN 
	|				-Groups.ClosingBalance
	|			
	|		WHEN Groups.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND Groups.ClosingBalance > 0
	|			THEN 
	|				Groups.ClosingBalance
	|		ELSE
	|			0
	|	END AS ClosingBalanceCr,
	|	
	|	NOT DetailedCalculationRecords.ARAPDocument IS NULL AS ThereAreRevolutions,
	|	DetailedCalculationRecords.ARAPDocument AS ARAPDocument,
	|	DetailedCalculationRecords.DocumentDetails AS DocumentDetails,
	|	CASE WHEN VALUETYPE(DetailedCalculationRecords.ARAPDocument) = TYPE(Document.ExchangeDifferenceCalculation)
	|		THEN Groups.DocumentRef.Organization.LocalAccountingCurrency
	|		ELSE Groups.Currency
	|	END AS Currency,
	|	CASE WHEN VALUETYPE(DetailedCalculationRecords.ARAPDocument) = TYPE(Document.ExchangeDifferenceCalculation)
	|		THEN Groups.DocumentRef.Organization.LocalAccountingCurrency
	|		ELSE DetailedCalculationRecords.DocumentCurrency
	|	END AS DocumentCurrency,
	|
	|	CASE
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmount_, 0) > 0 THEN ISNULL(DetailedCalculationRecords.DebtAmount_, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) ELSE 0 END
	|		
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				OR DetailedCalculationRecords.PaymentType_ = UNDEFINED
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmount_, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.DebtAmount_, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) > 0 THEN ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) ELSE 0 END
	|
	|		ELSE 0
	|	END AS DebitAmount,
	| 	CASE
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmount_, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.DebtAmount_, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) > 0 THEN ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) ELSE 0 END
	|		
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				OR DetailedCalculationRecords.PaymentType_ = UNDEFINED
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmount_, 0) > 0 THEN ISNULL(DetailedCalculationRecords.DebtAmount_, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) ELSE 0 END
	|				
	|		ELSE 0
	|	END AS LoanAmount_,
	|
	|	// The counterparty's Debit is our Credit, and the Credit is our Debit
	|	CASE
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) > 0 THEN ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) ELSE 0 END
	|		
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				OR DetailedCalculationRecords.PaymentType_ = UNDEFINED
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) > 0 THEN ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) ELSE 0 END
	|				
	|		ELSE 0
	|	END AS AmountDebitCounterparty,
	|	CASE
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) > 0 THEN ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) ELSE 0 END
	|		
	|		WHEN DetailedCalculationRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				OR DetailedCalculationRecords.PaymentType_ = UNDEFINED
	|			THEN
	|				CASE WHEN ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) < 0 THEN -ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) ELSE 0 END
	|				+ CASE WHEN ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) > 0 THEN ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) ELSE 0 END
	|
	|		ELSE 0
	|	END AS AmountCreditCounterparty,
	|
	|	ISNULL(DetailedCalculationRecords.DocumentAmount, 0) AS DocumentAmount,
	|	ISNULL(DetailedCalculationRecords.DocumentAmountCounterparty, 0) AS DocumentAmountCounterparty,
	|	ISNULL(DetailedCalculationRecords.DebtAmount_, 0) AS DebtAmount_,
	|	ISNULL(DetailedCalculationRecords.AmountPrepayment, 0) AS AmountPrepayment,
	|	ISNULL(DetailedCalculationRecords.AmountARAP, 0) AS AmountARAP,
	|	ISNULL(DetailedCalculationRecords.DebtAmountCounterparty, 0) AS DebtAmountCounterparty,
	|	ISNULL(DetailedCalculationRecords.AmountPrepaymentCounterparty, 0) AS AmountPrepaymentCounterparty,
	|	ISNULL(DetailedCalculationRecords.AmountARAPCounterparty, 0) AS AmountARAPCounterparty
	|	
	|INTO DetailsOfCalculation
	|FROM
	|	TTCalculationGrouping AS Groups
	|		LEFT JOIN DetailedCalculationRecords AS DetailedCalculationRecords
	|		ON Groups.DocumentRef = DetailedCalculationRecords.DocumentRef
	|			AND (Groups.PaymentType_ = DetailedCalculationRecords.PaymentType_ OR &MergeCustomersSuppliers)
	|			AND Groups.Currency = DetailedCalculationRecords.Currency
	|			AND Groups.GroupingObject = DetailedCalculationRecords.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSAndFinTools.Ref AS DocumentRef,
	|	TSAndFinTools.PaymentType_ AS PaymentType_,
	|	TSDetailedRecordsFinTools.ARAPDocument AS ARAPDocument,
	|	TSDetailedRecordsFinTools.DocumentDetails AS DocumentDetails,
	|	TSAndFinTools.Currency AS Currency,
	|	TSDetailedRecordsFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	TSDetailedRecordsFinTools.Contract AS Contract,
	|	TSDetailedRecordsFinTools.Contract.ContractKind AS ContractKind,
	|	
	|	TSDetailedRecordsFinTools.PrincipalDebt AS PrincipalDebt,
	|	CASE 
	|		WHEN TSDetailedRecordsFinTools.Ref.ThereAreDiscrepancies
	|			THEN 
	|				TSDetailedRecordsFinTools.PrincipalDebtCounterparty
	|		ELSE
	|			TSDetailedRecordsFinTools.PrincipalDebt
	|	END AS PrincipalDebtCounterparty,
	|	TSDetailedRecordsFinTools.Interests AS Interests,
	|	CASE
	|		WHEN TSDetailedRecordsFinTools.Ref.ThereAreDiscrepancies
	|		THEN 
	|			TSDetailedRecordsFinTools.InterestCounterparty
	|		ELSE
	|			TSDetailedRecordsFinTools.Interests
	|	END AS InterestCounterparty,
	|	TSDetailedRecordsFinTools.Fee AS Fee,
	|	CASE
	|		WHEN TSDetailedRecordsFinTools.Ref.ThereAreDiscrepancies
	|		THEN
	|			TSDetailedRecordsFinTools.FeeCounterparty
	|		ELSE
	|			TSDetailedRecordsFinTools.Fee
	|	END AS FeeCounterparty,
	|	
	|	TSDetailedRecordsFinTools.LeaseObligations AS LeaseObligations,
	|	CASE
	|		WHEN TSDetailedRecordsFinTools.Ref.ThereAreDiscrepancies
	|		THEN 
	|			TSDetailedRecordsFinTools.LeaseObligationsCounterparty
	|		ELSE
	|			TSDetailedRecordsFinTools.LeaseObligations
	|	END AS LeaseObligationsCounterparty,
	|	TSDetailedRecordsFinTools.DepositPayment AS DepositPayment,
	|	CASE
	|		WHEN TSDetailedRecordsFinTools.Ref.ThereAreDiscrepancies
	|		THEN 
	|			TSDetailedRecordsFinTools.DepositPaymentCounterparty
	|		ELSE
	|			TSDetailedRecordsFinTools.DepositPayment
	|	END AS DepositPaymentCounterparty,
	|	TSDetailedRecordsFinTools.RentalService AS RentalService,
	|	CASE
	|		WHEN TSDetailedRecordsFinTools.Ref.ThereAreDiscrepancies
	|		THEN 
	|			TSDetailedRecordsFinTools.RentalServiceCounterparty
	|		ELSE
	|			TSDetailedRecordsFinTools.RentalService
	|	END AS RentalServiceCounterparty,
	|	TSDetailedRecordsFinTools.BuyoutValue AS BuyoutValue,
	|	CASE
	|		WHEN TSDetailedRecordsFinTools.Ref.ThereAreDiscrepancies
	|		THEN 
	|			TSDetailedRecordsFinTools.BuyoutValueCounterparty
	|		ELSE
	|			TSDetailedRecordsFinTools.BuyoutValue
	|	END AS BuyoutValueCounterparty
	|	
	|INTO DetailedRecordsFinancialInstruments
	|FROM
	|	Document.ARAPReconciliation2_4.GroupingsFinancialInstruments AS TSAndFinTools
	|		LEFT JOIN Document.ARAPReconciliation2_4.DetailedRecordsFinancialInstruments AS TSDetailedRecordsFinTools
	|		ON TSAndFinTools.Ref = TSDetailedRecordsFinTools.Ref
	|			AND TSAndFinTools.Contract = TSDetailedRecordsFinTools.Contract
	|WHERE
	|	TSAndFinTools.Ref IN(&ObjectsArray)
	|	AND TSDetailedRecordsFinTools.Ref IN(&ObjectsArray)
	|	AND (&WithdrawInTheReglCurrency 
	|			AND TSDetailedRecordsFinTools.DocumentCurrency = TSAndFinTools.Ref.Organization.LocalAccountingCurrency 
	|			AND TSAndFinTools.Currency = TSAndFinTools.Ref.Organization.LocalAccountingCurrency 
	|		OR NOT &WithdrawInTheReglCurrency
	|	)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupingFinTools.Ref AS DocumentRef,
	|	GroupingFinTools.PaymentType_ AS PaymentType_,
	|	GroupingFinTools.Contract AS GroupingObject,
	|	GroupingFinTools.Currency AS Currency,
	|	SUM(GroupingFinTools.OpeningBalanceDr) AS OpeningBalanceDr,
	|	SUM(GroupingFinTools.OpeningBalanceCr) AS OpeningBalanceCr,
	|	SUM(GroupingFinTools.TurnoverReceipt) AS TurnoverReceipt,
	|	SUM(GroupingFinTools.TurnoverExpense) AS TurnoverExpense,
	|	SUM(GroupingFinTools.ClosingBalanceDr) AS ClosingBalanceDr,
	|	SUM(GroupingFinTools.ClosingBalanceCr) AS ClosingBalanceCr
	|INTO TTFinTools
	|FROM
	|	Document.ARAPReconciliation2_4.GroupingsFinancialInstruments AS GroupingFinTools
	|WHERE
	|	GroupingFinTools.Ref IN(&ObjectsArray)
	|	AND (&WithdrawInTheReglCurrency AND GroupingFinTools.Currency = GroupingFinTools.Ref.Organization.LocalAccountingCurrency
	|		OR NOT &WithdrawInTheReglCurrency
	|	)
	|
	|GROUP BY
	|	GroupingFinTools.Ref,
	|	GroupingFinTools.PaymentType_,
	|	GroupingFinTools.Contract,
	|	GroupingFinTools.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Groups.DocumentRef AS DocumentRef,
	|	Groups.PaymentType_ AS PaymentType_,
	|	Groups.GroupingObject AS GroupingObject,
	|	REFPRESENTATION(Groups.GroupingObject) AS DimensionObjectPresentation,
	|	
	|	Groups.OpeningBalanceDr AS OpeningBalanceDr,
	|	Groups.OpeningBalanceCr AS OpeningBalanceCr,
	|	Groups.TurnoverReceipt AS TurnoverReceipt,
	|	Groups.TurnoverExpense AS TurnoverExpense,
	|	Groups.ClosingBalanceDr AS ClosingBalanceDr,
	|	Groups.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	ISNULL(DetailsOfFinTools.Contract, UNDEFINED) AS Contract,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	Groups.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	ISNULL(DetailsOfFinTools.PrincipalDebt, 0) AS PrincipalDebt,
	|	ISNULL(DetailsOfFinTools.PrincipalDebtCounterparty, 0) AS PrincipalDebtCounterparty,
	|	ISNULL(DetailsOfFinTools.Interests, 0) AS Interests,
	|	ISNULL(DetailsOfFinTools.InterestCounterparty, 0) AS InterestCounterparty,
	|	ISNULL(DetailsOfFinTools.Fee, 0) AS Fee,
	|	ISNULL(DetailsOfFinTools.FeeCounterparty, 0) AS FeeCounterparty,
	|	
	|	ISNULL(DetailsOfFinTools.LeaseObligations, 0) AS LeaseObligations,
	|	ISNULL(DetailsOfFinTools.LeaseObligationsCounterparty, 0) AS LeaseObligationsCounterparty,
	|	ISNULL(DetailsOfFinTools.DepositPayment, 0) AS DepositPayment,
	|	ISNULL(DetailsOfFinTools.DepositPaymentCounterparty, 0) AS DepositPaymentCounterparty,
	|	ISNULL(DetailsOfFinTools.RentalService, 0) AS RentalService,
	|	ISNULL(DetailsOfFinTools.RentalServiceCounterparty, 0) AS RentalServiceCounterparty,
	|	ISNULL(DetailsOfFinTools.BuyoutValue, 0) AS BuyoutValue,
	|	ISNULL(DetailsOfFinTools.BuyoutValueCounterparty, 0) AS BuyoutValueCounterparty
	|	
	|INTO DetailsOfFinInstrumentsWithoutTypeAmounts
	|FROM
	|	TTFinTools AS Groups
	|		LEFT JOIN DetailedRecordsFinancialInstruments AS DetailsOfFinTools
	|		ON Groups.DocumentRef = DetailsOfFinTools.DocumentRef
	|			AND Groups.PaymentType_ = DetailsOfFinTools.PaymentType_
	|			AND Groups.GroupingObject = DetailsOfFinTools.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	FALSE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.EmptyRef) AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	0 AS DebitAmount,
	|	0 AS LoanAmount_,
	|
	|	0 AS AmountDebitCounterparty,
	|	0 AS AmountCreditCounterparty,
	|	
	|	DetailsOfFinTools.PrincipalDebt AS PrincipalDebt,
	|	DetailsOfFinTools.PrincipalDebtCounterparty AS PrincipalDebtCounterparty,
	|	DetailsOfFinTools.Interests AS Interests,
	|	DetailsOfFinTools.InterestCounterparty AS InterestCounterparty,
	|	DetailsOfFinTools.Fee AS Fee,
	|	DetailsOfFinTools.FeeCounterparty AS FeeCounterparty,
	|	
	|	DetailsOfFinTools.LeaseObligations AS LeaseObligations,
	|	DetailsOfFinTools.LeaseObligationsCounterparty AS LeaseObligationsCounterparty,
	|	DetailsOfFinTools.DepositPayment AS DepositPayment,
	|	DetailsOfFinTools.DepositPaymentCounterparty AS DepositPaymentCounterparty,
	|	DetailsOfFinTools.RentalService AS RentalService,
	|	DetailsOfFinTools.RentalServiceCounterparty AS RentalServiceCounterparty,
	|	DetailsOfFinTools.BuyoutValue AS BuyoutValue,
	|	DetailsOfFinTools.BuyoutValueCounterparty AS BuyoutValueCounterparty
	|	
	|INTO DetailsOfFinTools
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.Contract = UNDEFINED //there are no detailed records of the contract
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	CASE
	|		WHEN DetailsOfFinTools.PrincipalDebt > 0
	|			THEN
	|				DetailsOfFinTools.PrincipalDebt
	|		ELSE
	|			0
	|	END AS DebitAmount,
	|	CASE
	|		WHEN DetailsOfFinTools.PrincipalDebt < 0
	|			THEN
	|				-DetailsOfFinTools.PrincipalDebt
	|		ELSE
	|			0
	|	END AS LoanAmount_,
	|
	|	CASE
	|		WHEN DetailsOfFinTools.PrincipalDebtCounterparty < 0
	|			THEN 
	|				-DetailsOfFinTools.PrincipalDebtCounterparty
	|		ELSE
	|			0
	|	END AS AmountDebitCounterparty,
	|	CASE
	|		WHEN DetailsOfFinTools.PrincipalDebtCounterparty > 0
	|			THEN 
	|				DetailsOfFinTools.PrincipalDebtCounterparty
	|		ELSE
	|			0
	|	END AS AmountCreditCounterparty,
	|	
	|	DetailsOfFinTools.PrincipalDebt AS PrincipalDebt,
	|	DetailsOfFinTools.PrincipalDebtCounterparty AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.PrincipalDebt <> 0
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests) AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	CASE
	|		WHEN DetailsOfFinTools.Interests > 0
	|			THEN 
	|				DetailsOfFinTools.Interests
	|		ELSE
	|			0
	|	END AS DebitAmount,
	|	CASE
	|		WHEN DetailsOfFinTools.Interests < 0
	|			THEN 
	|				-DetailsOfFinTools.Interests
	|		ELSE
	|			0
	|	END AS LoanAmount_,
	|
	|	CASE
	|		WHEN DetailsOfFinTools.InterestCounterparty < 0
	|			THEN 
	|				-DetailsOfFinTools.InterestCounterparty
	|		ELSE
	|			0
	|	END AS AmountDebitCounterparty,
	|	CASE
	|		WHEN DetailsOfFinTools.InterestCounterparty > 0
	|			THEN 
	|				DetailsOfFinTools.InterestCounterparty
	|		ELSE
	|			0
	|	END AS AmountCreditCounterparty,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	DetailsOfFinTools.Interests AS Interests,
	|	DetailsOfFinTools.InterestCounterparty AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.Interests <> 0
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee) AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	CASE
	|		WHEN DetailsOfFinTools.Fee > 0
	|			THEN 
	|				DetailsOfFinTools.Fee
	|		ELSE
	|			0
	|	END AS DebitAmount,
	|	CASE
	|		WHEN DetailsOfFinTools.Fee < 0
	|			THEN 
	|				-DetailsOfFinTools.Fee
	|		ELSE
	|			0
	|	END AS LoanAmount_,
	|
	|	CASE
	|		WHEN DetailsOfFinTools.FeeCounterparty < 0
	|			THEN 
	|				-DetailsOfFinTools.FeeCounterparty
	|		ELSE
	|			0
	|	END AS AmountDebitCounterparty,
	|	CASE
	|		WHEN DetailsOfFinTools.FeeCounterparty > 0
	|			THEN 
	|				DetailsOfFinTools.FeeCounterparty
	|		ELSE
	|			0
	|	END AS AmountCreditCounterparty,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	DetailsOfFinTools.Fee AS Fee,
	|	DetailsOfFinTools.FeeCounterparty AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.Fee <> 0
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	&LeaseObligations AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	0 AS DebitAmount,
	|	0 AS LoanAmount_,
	|
	|	0 AS AmountDebitCounterparty,
	|	0 AS AmountCreditCounterparty,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|	AND DetailsOfFinTools.LeaseObligations = 0
	|	AND DetailsOfFinTools.DepositPayment = 0
	|	AND DetailsOfFinTools.RentalService = 0
	|	AND DetailsOfFinTools.BuyoutValue = 0
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	&LeaseObligations AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	CASE 
	|		WHEN DetailsOfFinTools.LeaseObligations > 0
	|			THEN
	|				DetailsOfFinTools.LeaseObligations
	|		ELSE
	|			0
	|	END AS DebitAmount,
	|	CASE 
	|		WHEN DetailsOfFinTools.LeaseObligations < 0
	|			THEN
	|				-DetailsOfFinTools.LeaseObligations
	|		ELSE
	|			0
	|	END AS LoanAmount_,
	|
	|	CASE 
	|		WHEN DetailsOfFinTools.LeaseObligationsCounterparty < 0
	|			THEN
	|				-DetailsOfFinTools.LeaseObligationsCounterparty
	|		ELSE
	|			0
	|	END AS AmountDebitCounterparty,
	|	CASE 
	|		WHEN DetailsOfFinTools.LeaseObligationsCounterparty > 0
	|			THEN
	|				DetailsOfFinTools.LeaseObligationsCounterparty
	|		ELSE
	|			0
	|	END AS AmountCreditCounterparty,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	DetailsOfFinTools.LeaseObligations AS LeaseObligations,
	|	DetailsOfFinTools.LeaseObligationsCounterparty AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.LeaseObligations <> 0
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	&DepositPayment AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	CASE 
	|		WHEN DetailsOfFinTools.DepositPayment > 0
	|			THEN
	|				DetailsOfFinTools.DepositPayment
	|		ELSE
	|			0
	|	END AS DebitAmount,
	|	CASE 
	|		WHEN DetailsOfFinTools.DepositPayment < 0
	|			THEN
	|				-DetailsOfFinTools.DepositPayment
	|		ELSE
	|			0
	|	END AS LoanAmount_,
	|
	|	CASE 
	|		WHEN DetailsOfFinTools.DepositPaymentCounterparty < 0
	|			THEN
	|				-DetailsOfFinTools.DepositPaymentCounterparty
	|		ELSE
	|			0
	|	END AS AmountDebitCounterparty,
	|	CASE 
	|		WHEN DetailsOfFinTools.DepositPaymentCounterparty > 0
	|			THEN
	|				DetailsOfFinTools.DepositPaymentCounterparty
	|		ELSE
	|			0
	|	END AS AmountCreditCounterparty,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	DetailsOfFinTools.DepositPayment AS DepositPayment,
	|	DetailsOfFinTools.DepositPaymentCounterparty AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.DepositPayment <> 0
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	&RentalService AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	CASE 
	|		WHEN DetailsOfFinTools.RentalService > 0
	|			THEN
	|				DetailsOfFinTools.RentalService
	|		ELSE
	|			0
	|	END AS DebitAmount,
	|	CASE 
	|		WHEN DetailsOfFinTools.RentalService < 0
	|			THEN
	|				-DetailsOfFinTools.RentalService
	|		ELSE
	|			0
	|	END AS LoanAmount_,
	|
	|	CASE 
	|		WHEN DetailsOfFinTools.RentalServiceCounterparty < 0
	|			THEN
	|				-DetailsOfFinTools.RentalServiceCounterparty
	|		ELSE
	|			0
	|	END AS AmountDebitCounterparty,
	|	CASE 
	|		WHEN DetailsOfFinTools.RentalServiceCounterparty > 0
	|			THEN
	|				DetailsOfFinTools.RentalServiceCounterparty
	|		ELSE
	|			0
	|	END AS AmountCreditCounterparty,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	DetailsOfFinTools.RentalService AS RentalService,
	|	DetailsOfFinTools.RentalServiceCounterparty AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.RentalService <> 0
	|	
	|UNION ALL
	|
	|SELECT
	|	DetailsOfFinTools.DocumentRef AS DocumentRef,
	|	DetailsOfFinTools.PaymentType_ AS PaymentType_,
	|	DetailsOfFinTools.GroupingObject AS GroupingObject,
	|	DetailsOfFinTools.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfFinTools.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfFinTools.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfFinTools.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfFinTools.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfFinTools.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfFinTools.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	TRUE AS ThereAreRevolutions,
	|	DetailsOfFinTools.ARAPDocument AS ARAPDocument,
	|	DetailsOfFinTools.DocumentDetails AS DocumentDetails,
	|	DetailsOfFinTools.ContractKind AS ContractKind,
	|	&BuyoutValue AS AmountType,
	|	DetailsOfFinTools.Currency AS Currency,
	|	DetailsOfFinTools.DocumentCurrency AS DocumentCurrency,
	|	
	|	CASE 
	|		WHEN DetailsOfFinTools.BuyoutValue > 0
	|			THEN
	|				DetailsOfFinTools.BuyoutValue
	|		ELSE
	|			0
	|	END AS DebitAmount,
	|	CASE 
	|		WHEN DetailsOfFinTools.BuyoutValue < 0
	|			THEN
	|				-DetailsOfFinTools.BuyoutValue
	|		ELSE
	|			0
	|	END AS LoanAmount_,
	|
	|	CASE 
	|		WHEN DetailsOfFinTools.BuyoutValueCounterparty < 0
	|			THEN
	|				-DetailsOfFinTools.BuyoutValueCounterparty
	|		ELSE
	|			0
	|	END AS AmountDebitCounterparty,
	|	CASE 
	|		WHEN DetailsOfFinTools.BuyoutValueCounterparty > 0
	|			THEN
	|				DetailsOfFinTools.BuyoutValueCounterparty
	|		ELSE
	|			0
	|	END AS AmountCreditCounterparty,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	DetailsOfFinTools.BuyoutValue AS BuyoutValue,
	|	DetailsOfFinTools.BuyoutValueCounterparty AS BuyoutValueCounterparty
	|FROM
	|	DetailsOfFinInstrumentsWithoutTypeAmounts AS DetailsOfFinTools
	|WHERE
	|	DetailsOfFinTools.BuyoutValue <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailsOfCalculation.DocumentRef AS DocumentRef,
	|	DetailsOfCalculation.PaymentType_ AS PaymentType_,
	|	FALSE AS FinancialInstruments,
	|	DetailsOfCalculation.GroupingObject AS GroupingObject,
	|	DetailsOfCalculation.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailsOfCalculation.ThereAreRevolutions AS ThereAreRevolutions,
	|	DetailsOfCalculation.ARAPDocument AS ARAPDocument,
	|	DetailsOfCalculation.DocumentDetails AS DocumentDetails,
	|	DetailsOfCalculation.Currency AS Currency,
	|	DetailsOfCalculation.DocumentCurrency AS DocumentCurrency,
	|	
	|	DetailsOfCalculation.OpeningBalance AS OpeningBalance,
	|	DetailsOfCalculation.OpeningBalanceDr AS OpeningBalanceDr,
	|	DetailsOfCalculation.OpeningBalanceCr AS OpeningBalanceCr,
	|	DetailsOfCalculation.TurnoverReceipt AS TurnoverReceipt,
	|	DetailsOfCalculation.TurnoverExpense AS TurnoverExpense,
	|	DetailsOfCalculation.ClosingBalance AS ClosingBalance,
	|	DetailsOfCalculation.ClosingBalanceDr AS ClosingBalanceDr,
	|	DetailsOfCalculation.ClosingBalanceCr AS ClosingBalanceCr,
	|	
	|	SUM(DetailsOfCalculation.DebitAmount) AS DebitAmount,
	|	SUM(DetailsOfCalculation.LoanAmount_) AS LoanAmount_,
	|
	|	SUM(DetailsOfCalculation.AmountDebitCounterparty) AS AmountDebitCounterparty,
	|	SUM(DetailsOfCalculation.AmountCreditCounterparty) AS AmountCreditCounterparty,
	|	
	|	DetailsOfCalculation.DocumentAmount AS DocumentAmount,
	|	DetailsOfCalculation.DocumentAmountCounterparty AS DocumentAmountCounterparty,
	|	SUM(DetailsOfCalculation.DebtAmount_) AS DebtAmount_,
	|	SUM(DetailsOfCalculation.AmountPrepayment) AS AmountPrepayment,
	|	SUM(DetailsOfCalculation.AmountARAP) AS AmountARAP,
	|	SUM(DetailsOfCalculation.DebtAmountCounterparty) AS DebtAmountCounterparty,
	|	SUM(DetailsOfCalculation.AmountPrepaymentCounterparty) AS AmountPrepaymentCounterparty,
	|	SUM(DetailsOfCalculation.AmountARAPCounterparty) AS AmountARAPCounterparty,
	|	
	|	UNDEFINED AS AmountType,
	|	0 AS PrincipalDebt,
	|	0 AS PrincipalDebtCounterparty,
	|	0 AS Interests,
	|	0 AS InterestCounterparty,
	|	0 AS Fee,
	|	0 AS FeeCounterparty,
	|	
	|	0 AS LeaseObligations,
	|	0 AS LeaseObligationsCounterparty,
	|	0 AS DepositPayment,
	|	0 AS DepositPaymentCounterparty,
	|	0 AS RentalService,
	|	0 AS RentalServiceCounterparty,
	|	0 AS BuyoutValue,
	|	0 AS BuyoutValueCounterparty,
	|	
	|	CASE 
	|		WHEN DetailsOfCalculation.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN 10
	|		WHEN DetailsOfCalculation.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN 20
	|		ELSE
	|			0
	|	END AS ARAPObjectSettings,
	|	
	|	0 AS OrderOfAmountType
	|	
	|INTO DetailedDocumentEntries
	|FROM
	|	DetailsOfCalculation AS DetailsOfCalculation
	|
	|GROUP BY
	|	DetailsOfCalculation.DocumentRef,
	|	DetailsOfCalculation.PaymentType_,
	|	DetailsOfCalculation.GroupingObject,
	|	DetailsOfCalculation.DimensionObjectPresentation,
	|	
	|	DetailsOfCalculation.ThereAreRevolutions,
	|	DetailsOfCalculation.ARAPDocument,
	|	DetailsOfCalculation.DocumentDetails,
	|	DetailsOfCalculation.Currency,
	|	DetailsOfCalculation.DocumentCurrency,
	|	
	|	DetailsOfCalculation.OpeningBalance,
	|	DetailsOfCalculation.OpeningBalanceDr,
	|	DetailsOfCalculation.OpeningBalanceCr,
	|	DetailsOfCalculation.TurnoverReceipt,
	|	DetailsOfCalculation.TurnoverExpense,
	|	DetailsOfCalculation.ClosingBalance,
	|	DetailsOfCalculation.ClosingBalanceDr,
	|	DetailsOfCalculation.ClosingBalanceCr,
	|	
	|	DetailsOfCalculation.DocumentAmount,
	|	DetailsOfCalculation.DocumentAmountCounterparty,
	|	
	|	CASE 
	|		WHEN DetailsOfCalculation.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN 10
	|		WHEN DetailsOfCalculation.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN 20
	|		ELSE
	|			0
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	DetailedRecords.DocumentRef AS DocumentRef,
	|	DetailedRecords.PaymentType_ AS PaymentType_,
	|	TRUE AS FinancialInstruments,
	|	DetailedRecords.GroupingObject AS GroupingObject,
	|	DetailedRecords.DimensionObjectPresentation AS DimensionObjectPresentation,
	|	
	|	DetailedRecords.ThereAreRevolutions AS ThereAreRevolutions,
	|	DetailedRecords.ARAPDocument AS ARAPDocument,
	|	DetailedRecords.DocumentDetails AS DocumentDetails,
	|	DetailedRecords.Currency AS Currency,
	|	DetailedRecords.DocumentCurrency AS DocumentCurrency,
	|	
	|	0 AS OpeningBalance,
	|	DetailedRecords.OpeningBalanceDr,
	|	DetailedRecords.OpeningBalanceCr,
	|	DetailedRecords.TurnoverReceipt,
	|	DetailedRecords.TurnoverExpense,
	|	0 AS ClosingBalance,
	|	DetailedRecords.ClosingBalanceDr,
	|	DetailedRecords.ClosingBalanceCr,
	|	
	|	SUM(DetailedRecords.DebitAmount) AS DebitAmount,
	|	SUM(DetailedRecords.LoanAmount_) AS LoanAmount_,
	|
	|	SUM(DetailedRecords.AmountDebitCounterparty) AS AmountDebitCounterparty,
	|	SUM(DetailedRecords.AmountCreditCounterparty) AS AmountCreditCounterparty,
	|	
	|	0 AS DocumentAmount,
	|	0 AS DocumentAmountCounterparty,
	|	0 AS DebtAmount_,
	|	0 AS AmountPrepayment,
	|	0 AS AmountARAP,
	|	0 AS DebtAmountCounterparty,
	|	0 AS AmountPrepaymentCounterparty,
	|	0 AS AmountARAPCounterparty,
	|	
	|	DetailedRecords.AmountType AS AmountType,
	|	SUM(DetailedRecords.PrincipalDebt) AS PrincipalDebt,
	|	SUM(DetailedRecords.PrincipalDebtCounterparty) AS PrincipalDebtCounterparty,
	|	SUM(DetailedRecords.Interests) AS Interests,
	|	SUM(DetailedRecords.InterestCounterparty) AS InterestCounterparty,
	|	SUM(DetailedRecords.Fee) AS Fee,
	|	SUM(DetailedRecords.FeeCounterparty) AS FeeCounterparty,
	|	
	|	SUM(DetailedRecords.LeaseObligations) AS LeaseObligations,
	|	SUM(DetailedRecords.LeaseObligationsCounterparty) AS LeaseObligationsCounterparty,
	|	SUM(DetailedRecords.DepositPayment) AS DepositPayment,
	|	SUM(DetailedRecords.DepositPaymentCounterparty) AS DepositPaymentCounterparty,
	|	SUM(DetailedRecords.RentalService) AS RentalService,
	|	SUM(DetailedRecords.RentalServiceCounterparty) AS RentalServiceCounterparty,
	|	SUM(DetailedRecords.BuyoutValue) AS BuyoutValue,
	|	SUM(DetailedRecords.BuyoutValueCounterparty) AS BuyoutValueCounterparty,
	|	
	|	CASE 
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			THEN 30
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|			THEN 40
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|			THEN 50
	|		ELSE
	|			0
	|	END AS ARAPObjectSettings,
	|	
	|	CASE 
	|		WHEN DetailedRecords.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN 10
	|		WHEN DetailedRecords.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN 20
	|		WHEN DetailedRecords.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN 30
	|		WHEN DetailedRecords.AmountType = &LeaseObligations 
	|			THEN 40
	|		WHEN DetailedRecords.AmountType = &DepositPayment 
	|			THEN 50
	|		WHEN DetailedRecords.AmountType = &RentalService 
	|			THEN 60
	|		WHEN DetailedRecords.AmountType = &BuyoutValue 
	|			THEN 70
	|		ELSE
	|			0
	|	END AS OrderOfAmountType
	|FROM
	|	DetailsOfFinTools AS DetailedRecords
	|
	|GROUP BY
	|	DetailedRecords.DocumentRef,
	|	DetailedRecords.PaymentType_,
	|	DetailedRecords.GroupingObject,
	|	DetailedRecords.DimensionObjectPresentation,
	|	
	|	DetailedRecords.ThereAreRevolutions,
	|	DetailedRecords.ARAPDocument,
	|	DetailedRecords.DocumentDetails,
	|	DetailedRecords.Currency,
	|	DetailedRecords.DocumentCurrency,
	|	
	|	DetailedRecords.OpeningBalanceDr,
	|	DetailedRecords.OpeningBalanceCr,
	|	DetailedRecords.TurnoverReceipt,
	|	DetailedRecords.TurnoverExpense,
	|	DetailedRecords.ClosingBalanceDr,
	|	DetailedRecords.ClosingBalanceCr,
	|	
	|	DetailedRecords.AmountType,
	|	
	|	CASE 
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			THEN 30
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|			THEN 40
	|		WHEN DetailedRecords.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|			THEN 50
	|		ELSE
	|			0
	|	END,
	|	
	|	CASE 
	|		WHEN DetailedRecords.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN 10
	|		WHEN DetailedRecords.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN 20
	|		WHEN DetailedRecords.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN 30
	|		WHEN DetailedRecords.AmountType = &LeaseObligations 
	|			THEN 40
	|		WHEN DetailedRecords.AmountType = &DepositPayment 
	|			THEN 50
	|		WHEN DetailedRecords.AmountType = &RentalService
	|			THEN 60
	|		WHEN DetailedRecords.AmountType = &BuyoutValue 
	|			THEN 70
	|		ELSE
	|			0
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Document_Details.ARAPDocument AS ARAPDocument,
	|	ReconciliationDocument.Organization AS Organization,
	|	CASE 
	|		WHEN VALUETYPE(Document_Details.ARAPDocument) = TYPE(Document.RegisterAdjustment)
	|			THEN RegisterAdjustment.Date
	|		WHEN VALUETYPE(Document_Details.ARAPDocument) IN 
	|				(TYPE(Document.BankAccountReceiptNote),
	|				TYPE(Document.BankAccountIssue))
	|			THEN CASE WHEN DocumentsRegistry.RecordingInAccountingDate = DATETIME(1,1,1)
	|						THEN DocumentsRegistry.SourceDocumentDate
	|						ELSE DocumentsRegistry.RecordingInAccountingDate
	|				END
	|		ELSE
	|			DocumentsData.RecorderDate
	|	END AS DocumentDate,
	|	CASE 
	|		WHEN VALUETYPE(Document_Details.ARAPDocument) = TYPE(Document.RegisterAdjustment)
	|			THEN RegisterAdjustment.Number
	|		ELSE
	|			ISNULL(CASE WHEN DocumentsRegistry.SourceDocumentNumber = """" 
	|								THEN DocumentsData.RecorderNumber
	|								ELSE DocumentsRegistry.SourceDocumentNumber
	|					END,
	|				DocumentsData.RecorderNumber)
	|	END AS DocumentNumber
	|INTO TTDocumentData
	|FROM
	|	DetailedDocumentEntries AS Document_Details
	|		LEFT JOIN Document.ARAPReconciliation2_4 AS ReconciliationDocument
	|		ON Document_Details.DocumentRef = ReconciliationDocument.Ref
	|		
	|		LEFT JOIN InformationRegister.SourceDocumentsData AS DocumentsData
	|		ON Document_Details.ARAPDocument = DocumentsData.Document
	|			AND ReconciliationDocument.Organization = DocumentsData.Organization
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Document_Details.ARAPDocument = DocumentsRegistry.Ref
	|			AND ReconciliationDocument.Organization = DocumentsRegistry.Organization
	|		
	|		LEFT JOIN Document.RegisterAdjustment AS RegisterAdjustment
	|		ON Document_Details.ARAPDocument = RegisterAdjustment.Ref
	|WHERE
	|	ReconciliationDocument.Ref IN(&ObjectsArray)
	|	
	|INDEX BY
	|	ARAPDocument,
	|	Organization
	|	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReconciliationDocument.Ref AS DocumentRef,
	|	ISNULL(Document_Details.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) AS PaymentType_,
	|	REFPRESENTATION(ISNULL(Document_Details.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef))) AS PresentationTypeOfCalculations,
	|	ReconciliationDocument.Number AS Number,
	|	ReconciliationDocument.Date AS Date,
	|	ReconciliationDocument.Organization AS Organization,
	|	ReconciliationDocument.Counterparty AS Counterparty,
	|	ReconciliationDocument.Partner AS Partner,
	|	ISNULL(ReconciliationDocument.Partner.DescriptionFull, """") AS PartnerPresentation_,
	|	ReconciliationDocument.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	ReconciliationDocument.Contract AS Contract,
	|	&PresentationOfContractForPrinting AS PresentationOfContract,
	|	ReconciliationDocument.BeginOfPeriod AS BeginOfPeriod,
	|	ReconciliationDocument.EndOfPeriod AS EndOfPeriod,
	|	CASE WHEN ReconciliationDocument.EmployeeInCharge_ = VALUE(Enum.PersonsResponsibleAndCompanies.ChiefAccountant)
	|		THEN ISNULL(ChiefAccountantsOfOrganizations.Description, TableResponsiblePersons.ChiefAccountantDescription)
	|		ELSE ISNULL(HeadsOfCompanies.Description, TableResponsiblePersons.DirectorDescription)
	|	END AS NameOfResponsiblePerson,
	|	CASE WHEN ReconciliationDocument.EmployeeInCharge_ = VALUE(Enum.PersonsResponsibleAndCompanies.ChiefAccountant)
	|		THEN ISNULL(ChiefAccountantsOfOrganizations.JobTitle, TableResponsiblePersons.ChiefAccountantJobTitle)
	|		ELSE ISNULL(HeadsOfCompanies.JobTitle, TableResponsiblePersons.DirectorJobTitle)
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
	|	ISNULL(Document_Details.GroupingObject, UNDEFINED) AS GroupingObject,
	|	CASE 
	|		WHEN VALUETYPE(Document_Details.GroupingObject) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CounterpartyContracts.NameForPrinting
	|		WHEN VALUETYPE(Document_Details.GroupingObject) = TYPE(Catalog.IntercompanyContracts)
	|			THEN IntercompanyContracts.NameForPrinting
	|		WHEN VALUETYPE(Document_Details.GroupingObject) = TYPE(Catalog.LoanAndDepositContracts)
	|			THEN LoanDepositAgreements_.NameForPrinting
	|		WHEN VALUETYPE(Document_Details.GroupingObject) = TYPE(Catalog.LeaseContract)
	|			THEN LeaseContract.NameForPrinting
	|		ELSE ISNULL(Document_Details.DimensionObjectPresentation, """")
	|	END AS DimensionObjectPresentation,
	|	ISNULL(Document_Details.ARAPDocument, UNDEFINED) AS ARAPDocument,
	|	ISNULL(Document_Details.DocumentDetails, """") AS DocumentDetails,
	|	DocumentsData.DocumentDate AS DocumentDate,
	|	DocumentsData.DocumentNumber AS DocumentNumber,
	|	ISNULL(Document_Details.Currency, ReconciliationDocument.Organization.LocalAccountingCurrency) AS Currency,
	|	REFPRESENTATION(ISNULL(Document_Details.Currency, ReconciliationDocument.Organization.LocalAccountingCurrency)) AS PresentationCurrency_,
	|	ISNULL(Document_Details.DocumentCurrency, ReconciliationDocument.Organization.LocalAccountingCurrency) AS DocumentCurrency,
	|	REFPRESENTATION(ISNULL(Document_Details.DocumentCurrency, ReconciliationDocument.Organization.LocalAccountingCurrency)) AS PresentationCurrencyOfDocument,
	|	ISNULL(Document_Details.AmountType, VALUE(Enum.LoanAndDepositScheduleAmountTypes.EmptyRef)) AS AmountType,
	|	
	|	ISNULL(Document_Details.OpeningBalance, 0) AS OpeningBalance,
	|	ISNULL(Document_Details.OpeningBalanceDr, 0) AS OpeningBalanceDr,
	|	ISNULL(Document_Details.OpeningBalanceCr, 0) AS OpeningBalanceCr,
	|	ISNULL(Document_Details.TurnoverReceipt, 0) AS TurnoverReceipt,
	|	ISNULL(Document_Details.TurnoverExpense, 0) AS TurnoverExpense,
	|	ISNULL(Document_Details.ClosingBalance, 0) AS ClosingBalance,
	|	ISNULL(Document_Details.ClosingBalanceDr, 0) AS ClosingBalanceDr,
	|	ISNULL(Document_Details.ClosingBalanceCr, 0) AS ClosingBalanceCr,
	|	
	|	ISNULL(Document_Details.DebitAmount, 0) AS DebitAmount,
	|	ISNULL(Document_Details.LoanAmount_, 0) AS LoanAmount_,
	|	
	|	ISNULL(Document_Details.AmountDebitCounterparty, 0) AS AmountDebitCounterparty,
	|	ISNULL(Document_Details.AmountCreditCounterparty, 0) AS AmountCreditCounterparty,
	|	
	|	ISNULL(Document_Details.DocumentAmount, 0) AS DocumentAmount,
	|	ISNULL(Document_Details.DocumentAmountCounterparty, 0) AS DocumentAmountCounterparty,
	|	ISNULL(Document_Details.DebtAmount_, 0) AS DebtAmount_,
	|	ISNULL(Document_Details.AmountPrepayment, 0) AS AmountPrepayment,
	|	ISNULL(Document_Details.AmountARAP, 0) AS AmountARAP,
	|	ISNULL(Document_Details.DebtAmountCounterparty, 0) AS DebtAmountCounterparty,
	|	ISNULL(Document_Details.AmountPrepaymentCounterparty, 0) AS AmountPrepaymentCounterparty,
	|	ISNULL(Document_Details.AmountARAPCounterparty, 0) AS AmountARAPCounterparty,
	|	
	|	ISNULL(Document_Details.PrincipalDebt, 0) AS PrincipalDebt,
	|	ISNULL(Document_Details.PrincipalDebtCounterparty, 0) AS PrincipalDebtCounterparty,
	|	ISNULL(Document_Details.Interests, 0) AS Interests,
	|	ISNULL(Document_Details.InterestCounterparty, 0) AS InterestCounterparty,
	|	ISNULL(Document_Details.Fee, 0) AS Fee,
	|	ISNULL(Document_Details.FeeCounterparty, 0) AS FeeCounterparty,
	|	
	|	ISNULL(Document_Details.LeaseObligations, 0) AS LeaseObligations,
	|	ISNULL(Document_Details.LeaseObligationsCounterparty, 0) AS LeaseObligationsCounterparty,
	|	ISNULL(Document_Details.DepositPayment, 0) AS DepositPayment,
	|	ISNULL(Document_Details.DepositPaymentCounterparty, 0) AS DepositPaymentCounterparty,
	|	ISNULL(Document_Details.RentalService, 0) AS RentalService,
	|	ISNULL(Document_Details.RentalServiceCounterparty, 0) AS RentalServiceCounterparty,
	|	ISNULL(Document_Details.BuyoutValue, 0) AS BuyoutValue,
	|	ISNULL(Document_Details.BuyoutValueCounterparty, 0) AS BuyoutValueCounterparty,
	|	
	|	ISNULL(Document_Details.ARAPObjectSettings, 0) AS ARAPObjectSettings
	|FROM
	|	Document.ARAPReconciliation2_4 AS ReconciliationDocument
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON ReconciliationDocument.Ref = TableResponsiblePersons.Ref
	|		
	|		LEFT JOIN TableResponsiblePersonsOfCounterpartyOrganization AS TableResponsiblePersonsOfCounterpartyOrganization
	|		ON ReconciliationDocument.Ref = TableResponsiblePersonsOfCounterpartyOrganization.Ref
	|
	|		LEFT JOIN Catalog.PersonsResponsibleAndCompanies AS HeadsOfCompanies
	|		ON ReconciliationDocument.Director = HeadsOfCompanies.Ref
	|		
	|		LEFT JOIN Catalog.PersonsResponsibleAndCompanies AS ChiefAccountantsOfOrganizations
	|		ON ReconciliationDocument.ChiefAccountant = ChiefAccountantsOfOrganizations.Ref
	|		
	|		LEFT JOIN DetailedDocumentEntries AS Document_Details
	|		ON ReconciliationDocument.Ref = Document_Details.DocumentRef
	|		
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON Document_Details.GroupingObject = CounterpartyContracts.Ref
	|		
	|		LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
	|		ON Document_Details.GroupingObject = IntercompanyContracts.Ref
	|		
	|		LEFT JOIN Catalog.LoanAndDepositContracts AS LoanDepositAgreements_
	|		ON Document_Details.GroupingObject = LoanDepositAgreements_.Ref
	|		LEFT JOIN Catalog.LeaseContract AS LeaseContract
	|		ON Document_Details.GroupingObject = LeaseContract.Ref
	|		
	|		LEFT JOIN TTDocumentData AS DocumentsData
	|		ON Document_Details.ARAPDocument = DocumentsData.ARAPDocument
	|			AND ReconciliationDocument.Organization = DocumentsData.Organization
	|WHERE
	|	ReconciliationDocument.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	PaymentType_,
	|	Currency,
	|	DocumentDate,
	|	DocumentDetails,
	|	OrderOfAmountType,
	|	GroupingObject
	|
	|TOTALS
	|	MAX(OpeningBalance),
	|	MAX(OpeningBalanceDr),
	|	MAX(OpeningBalanceCr),
	|	MAX(TurnoverReceipt),
	|	MAX(TurnoverExpense),
	|	MAX(ClosingBalance),
	|	MAX(ClosingBalanceDr),
	|	MAX(ClosingBalanceCr),
	|	
	|	MAX(NameOfResponsiblePerson),
	|	MAX(PositionOfResponsiblePerson),
	|	MAX(FullNameOfCounterpartyExecutive),
	|	MAX(JobTitleOfCounterpartyExecutive),
	|	MAX(PresentationCurrency_),
	|	MAX(DocumentCurrency),
	|	MAX(PresentationCurrencyOfDocument),
	|	MAX(DimensionObjectPresentation),
	|	MAX(FinancialInstruments),
	|	MAX(ThereAreRevolutions),
	|	MAX(ThereAreDiscrepancies),
	|
	|	SUM(DebitAmount),
	|	SUM(LoanAmount_),
	|	
	|	SUM(AmountDebitCounterparty),
	|	SUM(AmountCreditCounterparty),
	|	
	|	SUM(DocumentAmount),
	|	SUM(DocumentAmountCounterparty),
	|	SUM(DebtAmount_),
	|	SUM(AmountPrepayment),
	|	SUM(AmountARAP),
	|	SUM(DebtAmountCounterparty),
	|	SUM(AmountPrepaymentCounterparty),
	|	SUM(AmountARAPCounterparty),
	|	
	|	SUM(PrincipalDebt),
	|	SUM(PrincipalDebtCounterparty),
	|	SUM(Interests),
	|	SUM(InterestCounterparty),
	|	SUM(Fee),
	|	SUM(FeeCounterparty),
	|	
	|	SUM(LeaseObligations),
	|	SUM(LeaseObligationsCounterparty),
	|	SUM(DepositPayment),
	|	SUM(DepositPaymentCounterparty),
	|	SUM(RentalService),
	|	SUM(DepositPaymentCounterparty),
	|	SUM(RentalService),
	|	SUM(RentalServiceCounterparty),
	|	SUM(BuyoutValue),
	|	SUM(BuyoutValueCounterparty)
	|BY
	|	DocumentRef,
	|	PaymentType_,
	|	Currency,
	|	GroupingObject";
	#EndRegion

	QueryText = StrReplace(QueryText,
						"GroupingCalculations.Contract",
						"GroupingCalculations." + PrintSettings.MutualSettlementsDetails);
	QueryText = StrReplace(QueryText,
						"DetailedCalculationRecords.Contract",
						"DetailedCalculationRecords." + PrintSettings.MutualSettlementsDetails);
	
	QueryText = StrReplace(QueryText,
						"GroupingFinTools.Contract",
						"GroupingFinTools." + PrintSettings.DetailingFinancialInstruments);
	QueryText = StrReplace(QueryText,
						"= DetailsOfFinTools.Contract",
						"= DetailsOfFinTools." + PrintSettings.DetailingFinancialInstruments);
	
	PresentationOfContractForPrinting = "ISNULL(ReconciliationDocument.Contract.NameForPrinting, """")";
	QueryText = StrReplace(QueryText, "&PresentationOfContractForPrinting", PresentationOfContractForPrinting);
	
	Return QueryText;
	
EndFunction

Procedure DecipherDetailSetting(PrintSettings)
	
	GroupingCalculations = New Array;
	GroupingCalculations.Add("Currency");
	GroupingCalculations.Add("Contract");
	GroupingCalculations.Add("ARAPObject");
	
	GroupingFinTools = New Array;
	GroupingFinTools.Add("Currency");
	GroupingFinTools.Add("Contract");
	
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

Procedure AddCounterpartyTurnover(Turnovers, Source, WithdrawDebtInAdvance)
	
	If WithdrawDebtInAdvance Then
		Turnovers.AmountDebitCounterparty = Turnovers.AmountDebitCounterparty + Source.DebtAmountCounterparty;
		Turnovers.AmountCreditCounterparty = Turnovers.AmountCreditCounterparty + Source.AmountPrepaymentCounterparty;
	Else
		Turnovers.AmountDebitCounterparty = Turnovers.AmountDebitCounterparty + Source.AmountDebitCounterparty;
		Turnovers.AmountCreditCounterparty = Turnovers.AmountCreditCounterparty + Source.AmountCreditCounterparty;
	EndIf;
	
EndProcedure

// Fills in the structure with data about recipients of printed forms.
// 
// Parameters:
// 	Documentlink - Documentlink is the document whose description is being prepared.
// 	Line Number - Incoming document number.
// 	Date - Date is the incoming date of the document.
// 	Document View - String - Presentation of the incoming document.
// 
// Returns:
// 	String - Document description
// 
Function DescriptionOfSettlementDocument(CalculationLine_) Export
	
	DocumentRef = CalculationLine_.ARAPDocument;
	Number = CalculationLine_.DocumentNumber;
	Date = CalculationLine_.DocumentDate;
	
	PresentationsOfDocuments = Documents.ARAPReconciliation2_5_11.PresentationsOfDocuments();
	IncomingDocuments = Documents.ARAPReconciliation2_5_11.IncomingInvoices();
	

	DocumentDetails = "№ __________ " + NStr("vi = 'ngày';
											|ru = 'от';
											|en = 'dated'; fa = 'مورخ';
											|it = 'от';
											|pl = 'dated';
											|tr = 'itibaren'") + " __________";
	If TypeOf(DocumentRef) = Type("CatalogRef.CounterpartyContracts")
		Or TypeOf(DocumentRef) = Type("CatalogRef.LeaseContract")
		Or  TypeOf(DocumentRef) = Type("CatalogRef.LoanAndDepositContracts") Then
		
		DocumentDetails = DocumentRef;
		
	ElsIf DocumentRef <> Undefined And Not DocumentRef.IsEmpty() Then

		DocumentName = DocumentRef.Metadata().Name;
		PresentationOfDocument = "";
		If ValueIsFilled(CalculationLine_.SourceDocumentName) Then //filled in only at incoming
			PresentationOfDocument = CalculationLine_.SourceDocumentName;
		Else
			PresentationsOfDocuments.Property(DocumentName, PresentationOfDocument);
		EndIf;
		
		If DocumentName = "BankAccountIssue" Then
			NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(Number,, True);
		ElsIf IncomingDocuments.Property(DocumentName) Then
			NumberForPrinting = RemoveLeadingZeros(Number);
		Else
			NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(Number);
		EndIf;
		
		DocumentDetails = StrTemplate(
			NStr("vi = '%1 Số%2 ngày %3';
				|ru = '%1 №%2 от %3';
				|en = '%1 No%2 dated %3'; fa = '%1 No%2 dated %3';
				|it = '%1 №%2 от %3';
				|pl = '%1 nr %2 z dnia %3.';
				|tr = '%1№%2 %3 ten'"),
			?(PresentationOfDocument <> Undefined, PresentationOfDocument, ""),
			?(ValueIsFilled(Number), NumberForPrinting, "_______"),
			?(ValueIsFilled(Date), Format(Date, "DLF=D"), "  .  .    "));
		
	EndIf;

	Return DocumentDetails;

EndFunction

Function RemoveLeadingZeros(String)
	
	Rez = TrimAll(String);
	While Left(Rez, 1) = "0" Or Left(Rez, 1) = "-" Do 
		Rez = Mid(Rez, 2);
	EndDo;
	Return Rez;
	
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
	|		Document.ARAPReconciliation2_4.GroupingsARAP AS CalculationsForDocument
	|	WHERE
	|		CalculationsForDocument.Ref IN (&ReconciliationDocuments)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		CalculationsForDocument.Ref,
	|		CalculationsForDocument.Ref.PointInTime AS PointInTime
	|	FROM
	|		Document.ARAPReconciliation2_4.GroupingsFinancialInstruments AS CalculationsForDocument
	|	WHERE
	|		CalculationsForDocument.Ref IN (&ReconciliationDocuments)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Reconciliation.Ref,
	|		Reconciliation.Ref.PointInTime AS PointInTime
	|	FROM
	|		Document.ARAPReconciliation2_4 AS Reconciliation
	|		LEFT JOIN Document.ARAPReconciliation2_4.CounterpartyData AS TSCounterpartyData
	|			ON Reconciliation.Ref = TSCounterpartyData.Ref
	|		LEFT JOIN Document.ARAPReconciliation2_4.GroupingsARAP AS Calculations
	|			ON Reconciliation.Ref = Calculations.Ref
	|		LEFT JOIN Document.ARAPReconciliation2_4.GroupingsFinancialInstruments AS FinTools
	|			ON Reconciliation.Ref = FinTools.Ref
	|	WHERE
	|		Reconciliation.Ref IN (&ReconciliationDocuments)
	|		AND TSCounterpartyData.Ref IS NULL
	|		AND Calculations.Ref IS NULL
	|		AND FinTools.Ref IS NULL) AS NestedQuery
	|
	|ORDER BY
	| 	NestedQuery.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CounterpartyData.Ref AS Ref
	|FROM
	|	Document.ARAPReconciliation2_4.CounterpartyData AS CounterpartyData
	|WHERE
	|	CounterpartyData.Ref IN (&ReconciliationDocuments)
	|
	|ORDER BY
	| CounterpartyData.Ref.PointInTime";
	Query = New Query(QueryText);
	
	Query.SetParameter("ReconciliationDocuments", ObjectsArray);
	
	QueryResult = Query.ExecuteBatch();
	
	Result = New Structure;
	Result.Insert("New_Items", QueryResult[0].Unload().UnloadColumn("Ref"));
	Result.Insert("OldOnes", QueryResult[1].Unload().UnloadColumn("Ref"));
	
	Return Result;
	
EndFunction

#EndRegion

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
	FillingData.Insert("SetNewNumber_", False);
	
	LinkerSelection = New DataCompositionSettingsComposer;
	InitializeSettingsComposer(LinkerSelection,,Parameters.Filter_Settings);
	ArrayOfAllReconciliationDocuments = New Array;
	For Each TableRow In CalculationTable Do

		FillingData.Insert("DocumentData", TableRow);
		FillingData.Insert("Filter_Settings", LinkerSelection.GetSettings());
		FillingData.Insert("DescriptionOfOutgoingDocuments", TableRow.DescriptionOfOutgoingDocuments);
		
		If TableRow.CreateADocument Or TableRow.ChangeDocument = "DeleteCreateNew" Then
			
			DocumentObject = Documents.ARAPReconciliation2_4.CreateDocument();
			
			DocumentObject.Date = DateOfDocuments + CurrentTime;
			
			FillingData.SetNewNumber_ = True;
			FillingData.Insert("DocumentData", TableRow);
			FillOutThisDocument(DocumentObject, FillingData);
			
			If DocumentObject.Posted Then
				AddToExecutionProtocol(DocumentObject.Ref, "Creating", SpentDocuments); 
				ArrayOfAllReconciliationDocuments.Add(DocumentObject.Ref);
			EndIf;

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
										|tr = '%Document% silinmek üzere işaretlenemedi. %DescriptionErrors%'");
					ErrorText    = StrReplace(ErrorText, "%Document%",	DocumentObject);
					ErrorText    = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
					
					Common.MessageToUser(ErrorText, DocumentObject.Ref);
				EndTry;
				
			ElsIf TableRow.ChangeDocument = "ReFill_" Then
				
				ArrayOfAllReconciliationDocuments.Add(TableRow.ReconciliationDocument);
				FillingData.SetNewNumber_ = False;
				FillOutThisDocument(DocumentObject, FillingData);
				
				If DocumentObject.Posted Then
					AddToExecutionProtocol(DocumentObject.Ref, "Refilling", SpentDocuments);
				EndIf;
				
			ElsIf TableRow.ChangeDocument = "DontChange" Then
				
				If DocumentObject.Posted Then
					ArrayOfAllReconciliationDocuments.Add(TableRow.ReconciliationDocument);
					AddToExecutionProtocol(DocumentObject.Ref, "DontChange", SpentDocuments);
				EndIf;
				
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
// 	DocumentObject - DocumentObject.ARAPReconciliation2_4 - Reconciliation object to fill in.
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
	DocumentData.Insert("Organization",	 		FillingData.DocumentData.Organization);
	DocumentData.Insert("PaymentType_",	 		FillingData.DocumentData.PaymentType_);
	DocumentData.Insert("Partner",				FillingData.DocumentData.Partner);
	DocumentData.Insert("Counterparty",			FillingData.DocumentData.Counterparty);
	DocumentData.Insert("Contract"	,			FillingData.DocumentData.Contract);
	DocumentData.Insert("BeginOfPeriod",		FillingData.ReconciliationPeriod.StartDate);
	DocumentData.Insert("EndOfPeriod",		FillingData.ReconciliationPeriod.EndDate);
	DocumentData.Insert("Status",		 		Enums.StatusesOfARAPReconciliation.CreatedOn_);
	DocumentData.Insert("Filter_Settings", 	FillingData.Filter_Settings);
	DocumentData.Insert("ContractsWithoutTurnover", FillingData.ContractsWithoutTurnover);
	DocumentData.Insert("SplitByARAPTypes", FillingData.SplitByARAPTypes);
	DocumentData.Insert("SplitByPartners", FillingData.SplitByPartners);
	DocumentData.Insert("SplitByContracts", FillingData.SplitByContracts);
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
			ErrorText = NStr("vi = 'Không thể ghi lại %Document%. %ErrorDescription%';
							|ru = 'Не удалось записать %Document%. %ErrorDescription%';
							|en = 'Cannot save %Document%. %ErrorDescription%'; fa = 'Cannot save %Document%. %ErrorDescription%';
							|it = 'Не удалось записать %Document%. %ErrorDescription%';
							|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
							|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Document%",       DocumentObject);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(ErrorText, DocumentObject.Ref);
		EndTry;
		
	Else
		
		ErrorText = NStr("vi = 'Không thể ghi lại %Document%.';
						|ru = 'Не удалось записать %Document%.';
						|en = 'Cannot save %Document%.'; fa = 'Cannot save %Document%.';
						|it = 'Не удалось записать %Document%.';
						|pl = 'Nie udało się zapisać %Document%.';
						|tr = '%Document% kaydedilemedi.'");
		ErrorText = StrReplace(ErrorText, "%Document%", DocumentObject);
		
		Common.MessageToUser(ErrorText, DocumentObject.Ref);
		
	EndIf;

EndProcedure

// LongDesc
// 
// Parameters:
// 	ReconciliationDocument - DocumentRef.ARAPReconciliation2_4 - LongDesc
// 	Action - String - LongDesc
// 	SpentDocuments - Array of See ProtocolString -
//
Procedure AddToExecutionProtocol(ReconciliationDocument, Action, SpentDocuments)
	
	ProtocolString = ProtocolString();
	ProtocolString.ReconciliationDocument = ReconciliationDocument;
	ProtocolString.Action = Action;
	
	SpentDocuments.Add(ProtocolString);
	
EndProcedure

// Returns:
// 	Structure of KeyAndValue - LongDesc:
// * Action - String -
// * ReconciliationDocument - DocumentRef.ARAPReconciliation2_4 -
Function ProtocolString() Export
	
	Result = New Structure();
	Result.Insert("ReconciliationDocument", Documents.ARAPReconciliation2_4.EmptyRef());
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
// 	DocumentData - DocumentObject.ARAPReconciliation2_4 - 
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
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ReceiveReconciliationDocuments", False);
	
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByARAPTypes", DocumentData.SplitByARAPTypes);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByPartners", DocumentData.SplitByPartners);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByContracts", DocumentData.SplitByContracts);
	
	DataCompositionClientServer.AddFilter(LinkerSelection.Settings, "Organization", DocumentData.Organization);
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
	
	Groups = "PaymentType_, Partner, Contract, ";
	
	DocumentData.GroupingsARAP.Clear();
	DocumentData.DetailedRecordsARAPAccounting.Clear();
	
	DocumentData.GroupingsFinancialInstruments.Clear();
	DocumentData.DetailedRecordsFinancialInstruments.Clear();
	For Each CalculationLine_ In TableOfSettlements Do
		
		AmountARAP = Undefined;
		If CalculationLine_.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting
			Or CalculationLine_.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
			GroupFields = Groups + "ARAPObject, Currency";
			GroupingDetailedRecords = "PaymentType_, ARAPObject, Partner, Contract, ARAPDocument, DocumentCurrency";
			SummationFields = "OpeningBalance, OpeningBalanceLocal";
			SummationFieldsForDetailedRecords = "DocumentAmount, DebtAmount_, DebtAmountLocal, AmountPrepayment, PrepaymentAmountLocal_";
			TSGroups = DocumentData.GroupingsARAP;
			TSDetailedRecords = DocumentData.DetailedRecordsARAPAccounting;
			AmountARAP = Max(-CalculationLine_.DebtAmount_, CalculationLine_.DebtAmount_) + Max(-CalculationLine_.AmountPrepayment, CalculationLine_.AmountPrepayment);
		Else
			GroupFields = Groups + "Currency";
			GroupingDetailedRecords = "Contract, ARAPDocument, DocumentCurrency";
			SummationFields = "OpeningBalanceDr,OpeningBalanceCr";
			SummationFieldsForDetailedRecords = "PrincipalDebt, Interests, Fee, LeaseObligations, DepositPayment, RentalService, BuyoutValue";
			TSGroups = DocumentData.GroupingsFinancialInstruments;
			TSDetailedRecords = DocumentData.DetailedRecordsFinancialInstruments;
			
		EndIf;
		
		SumData = ResourcesValues(CalculationLine_, SummationFieldsForDetailedRecords);
		
		NewRow = TSGroups.Add();
		FillPropertyValues(NewRow, CalculationLine_, GroupFields + ", " + SummationFields);
		
		If CalculationLine_.OpeningBalance = 0 And SumData.ThereAreFilled Then
			NewRow = TSDetailedRecords.Add();
			FillPropertyValues(NewRow, CalculationLine_, GroupingDetailedRecords + ", " + SummationFieldsForDetailedRecords);
			NewRow.DocumentDetails = DescriptionOfSettlementDocument(CalculationLine_);
			If AmountARAP <> Undefined Then
				NewRow.AmountARAP = AmountARAP;
			EndIf;
		EndIf;
		
	EndDo;
	
	#Region FillingInTSCalculations
	GroupRecords = DocumentData.GroupingsARAP.Unload();
	GroupRecords.GroupBy(Groups + "ARAPObject, Currency", "OpeningBalance, OpeningBalanceLocal, TurnoverReceipt, TurnoverDebitLocal, TurnoverExpense, TurnoverCreditLocal, ClosingBalance, ClosingBalanceLocal");
	DocumentData.GroupingsARAP.Clear();
	
	DetailedRecords = DocumentData.DetailedRecordsARAPAccounting.Unload();
	DetailedRecords.GroupBy("PaymentType_, ARAPObject, Partner, Contract, ARAPDocument, DocumentDetails, DocumentCurrency", "DocumentAmount, DebtAmount_, DebtAmountLocal, AmountPrepayment, PrepaymentAmountLocal_");
	
	For Each Group In GroupRecords Do
		
		ARAPAccountingClientServer.CalculateFinalBalanceOnMutualSettlements(Group, DetailedRecords);
		ARAPAccountingClientServer.CalculateFinalBalanceOnMutualSettlements(Group, DetailedRecords, True);
		
		If Group.OpeningBalance = 0 And Group.TurnoverReceipt = 0 And Group.TurnoverExpense = 0 And Group.ClosingBalance = 0
			And Group.OpeningBalanceLocal = 0 And Group.TurnoverDebitLocal = 0 And Group.TurnoverCreditLocal = 0 And Group.ClosingBalanceLocal = 0 Then
			Continue;
		EndIf;
		
		If Group.ClosingBalance = 0 Then
			Group.ClosingBalanceLocal = 0;
		EndIf;
		
		NewRow = DocumentData.GroupingsARAP.Add();
		FillPropertyValues(NewRow, Group);
		
	EndDo;
	DeleteHungSubdividedLines(DocumentData, "GroupingsARAP", "DetailedRecordsARAPAccounting", "ARAPObject");
	DocumentData.GroupingsARAP.Sort("PaymentType_, Partner, Contract, ARAPObject, Currency");
	#EndRegion
	
	#Region FillingTSFinTools
	GroupRecords = DocumentData.GroupingsFinancialInstruments.Unload();
	GroupRecords.GroupBy(Groups + "Currency", "OpeningBalanceDr, OpeningBalanceCr, TurnoverReceipt, TurnoverExpense, ClosingBalanceDr, ClosingBalanceCr");
	
	DetailedRecords = DocumentData.DetailedRecordsFinancialInstruments.Unload();
	DetailedRecords.GroupBy("Contract, ARAPDocument, DocumentDetails, DocumentCurrency", "PrincipalDebt, Interests, Fee, LeaseObligations, DepositPayment, RentalService, BuyoutValue");
	
	For Each Group In GroupRecords Do
		
		ARAPAccountingClientServer.CalculateFinalBalanceOnFinancialInstruments(Group, DetailedRecords);
		If Group.PaymentType_ = Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor Then
			If Group.ClosingBalanceDr > 0 And Group.ClosingBalanceCr > 0 Then
				ClosingBalance(Group.ClosingBalanceDr, Group.ClosingBalanceCr);
			EndIf;
		EndIf;
		
	EndDo;
	GroupRecords.Sort("PaymentType_, Partner, Contract, Currency");
	DocumentData.GroupingsFinancialInstruments.Load(GroupRecords);
	DocumentData.DetailedRecordsFinancialInstruments.Load(DetailedRecords);
	#EndRegion
	
EndProcedure

Function ResourcesValues(FillingData, FieldsNames)
	
	ResourceData = New Structure(FieldsNames);
	
	ThereAreFilled = False;
	For Each Resource In ResourceData Do
		
		ResourceData[Resource.Key] = FillingData[Resource.Key];
		If ResourceData[Resource.Key] <> 0 And Not ThereAreFilled Then
			ThereAreFilled = True;
		EndIf;
		
	EndDo; 
	
	ResourceData.Insert("ThereAreFilled", ThereAreFilled);
	
	Return ResourceData;
	
EndFunction

#EndRegion

Function GetSettlements(LinkerSelection) Export
	
	DataCompositionSchema = Documents.ARAPReconciliation2_4.GetTemplate("FilterCalculations");
	
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
	
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "LeaseObligations", Undefined);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "DepositPayment", Undefined);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "RentalService", Undefined);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "RentalServicePrepayment", Undefined);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BuyoutValue", Undefined);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BuyoutValuePrepayment", Undefined);
	TypesOfRentalAmounts = New Array;
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "TypesOfRentalAmounts", TypesOfRentalAmounts,,True);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "LeaseObligations", Enums.TypesOfLeasePayments.LeaseObligations,,True);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "DepositPayment", Enums.TypesOfLeasePayments.DepositPayment,,True);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "RentalService", Enums.TypesOfLeasePayments.RentalService,,True);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "RentalServicePrepayment", Enums.TypesOfLeasePayments.RentalServicePrepayment,,True);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BuyoutValue", Enums.TypesOfLeasePayments.BuyoutValue,,True);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BuyoutValuePrepayment", Enums.TypesOfLeasePayments.BuyoutValuePrepayment,,True);
	TypesOfRentalAmounts = New Array;
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.DepositPayment);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.RentalService);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.BuyoutValue);
	TypesOfRentalAmounts.Add(Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
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
	
	Documents.ARAPReconciliation2_5_11.ThereIsInputOfResidues(DCSResultTable);
	
	FilterScheme = New Structure;
	FilterScheme.Insert("DCS", DataCompositionSchema);
	FilterScheme.Insert("Settings", DataCompositionSettings);
	FilterScheme.Insert("Result", DCSResultTable);
	
	If LinkerSelection.Settings.AdditionalProperties.Property("ForDebugging") Then
		LinkerSelection.Settings.AdditionalProperties.ForDebugging.Insert("FilterScheme", FilterScheme);
	EndIf;
	
	Return DCSResultTable;
	
EndFunction

// Returns:
//  Structure - Document data:
// * Ref - Undefined - 
// * DocumentNumber - Undefined - 
// * DocumentDate - Undefined - 
// * SourceDocumentName - Undefined - 
// * Currency - Undefined - 
// * Sum - Undefined -
// 
Function DocumentData() Export
	
	Result = New Structure;
	Result.Insert("ARAPDocument", Undefined);
	Result.Insert("DocumentNumber", Undefined);
	Result.Insert("DocumentDate", Undefined);
	Result.Insert("SourceDocumentName", Undefined);
	Result.Insert("Currency", Undefined);
	Result.Insert("Sum", Undefined);
	
	Return Result;
	
EndFunction

Function SettlementDocumentData(SettlementDocuments_) Export
	
	QueryText = 
	"SELECT TOP 1
	|	DocumentsRegistry.Ref AS Ref,
	|	DocumentsRegistry.SourceDocumentDate AS DocumentDate,
	|	DocumentsRegistry.SourceDocumentNumber AS DocumentNumber,
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
	|	DocumentAmounts_.Date AS DocumentDate,
	|	DocumentAmounts_.Number AS DocumentNumber,
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
	|	DocumentAmounts_.IncomingDocumentDate AS DocumentDate,
	|	DocumentAmounts_.IncomingDocumentNumber AS DocumentNumber,
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
	|	DocumentAmounts_.IncomingDocumentDate AS DocumentDate,
	|	DocumentAmounts_.IncomingDocumentNumber AS DocumentNumber,
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
	|	DocumentAmounts_.IncomingDocumentDate AS DocumentDate,
	|	DocumentAmounts_.IncomingDocumentNumber AS DocumentNumber,
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
	|	DocumentAmounts_.Date AS DocumentDate,
	|	DocumentAmounts_.Number AS DocumentNumber,
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
	|	DocumentAmounts_.Date AS DocumentDate,
	|	DocumentAmounts_.Number AS DocumentNumber,
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
	|	DocumentAmounts_.IncomingDocumentDate AS DocumentDate,
	|	DocumentAmounts_.IncomingDocumentNumber AS DocumentNumber,
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
	|	DocumentAmounts_.Ref.Date AS DocumentDate,
	|	DocumentAmounts_.Ref.Number AS DocumentNumber,
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
	DocumentData = DocumentData();
	While Selection.Next() Do
		FillPropertyValues(DocumentData, Selection);
		DocumentData.ARAPDocument = Selection.Ref;
	EndDo;
	
	Return DocumentData;
	
EndFunction

Procedure InitializeSettingsComposer(LinkerSelection, FormUniqueID = Undefined, Filter_Settings = Undefined) Export
	
	DataCompositionSchema = Documents.ARAPReconciliation2_4.GetTemplate("FilterCalculations");
	
	If GetFunctionalOption("BaseVersion") Then
		Field = DataCompositionSchema.DataSets.BalanceAndTurnovers.Fields.Find("Counterparty"); // DataCompositionSchemaDataSetField
		Field.ValueType = New TypeDescription("CatalogRef.Counterparties");
	EndIf;
	
	AddAvailableTables(DataCompositionSchema.DataSets.BalanceAndTurnovers.Query);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	If UsePartnersAsCounterparties Then
		Field = DataCompositionSchema.DataSets.BalanceAndTurnovers.Fields.Find("Counterparty"); // DataCompositionSchemaDataSetField 
		If Field <> Undefined Then
			Field.UseRestriction.Condition = True;
			Field.AttributeUseRestriction.Condition = True;
		EndIf;
	Else
		Field = DataCompositionSchema.DataSets.BalanceAndTurnovers.Fields.Find("CompanyCounterparty"); // DataCompositionSchemaDataSetField 
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
	
	AvailableTypesOfCalculations_ = New ValueList;
	AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	If GetFunctionalOption("UseLoanAndDepositContracts") Then
		AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
		AvailableTypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
	EndIf;
	If NonCurrentAssets.VNAManagementIsUsed() Then
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

Procedure CompletePartnerSelectionByCounterparty(Filter) Export
	
	FilterElement = FinancialReportingServer.FindSelectionElement(Filter,"Counterparty");
	If FilterElement <> Undefined Then
		PartnerField = New DataCompositionField("Partner");
		FilterElement.LeftValue = PartnerField;
		If ValueIsFilled(FilterElement.RightValue) Then
			If TypeOf(FilterElement.RightValue) = Type("CatalogRef.Counterparties") Then
				FilterElement.RightValue = Common.ObjectAttributeValue(FilterElement.RightValue, "Partner");
			ElsIf TypeOf(FilterElement.RightValue) = Type("Array") Then
				Partners = Common.ObjectsAttributeValue(FilterElement.RightValue, "Partner");
				FilterElement.RightValue.Clear();
				For Each Partner In Partners Do
					FilterElement.RightValue.Add(Partner);
				EndDo;
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

Function ProhibitedPaymentTypes() Export
	
	Result = New Array;
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

Procedure DeleteHungSubdividedLines(DocumentObject_, TSGroups, TSDetailedRecords, LinksField) Export
	
	GroupingObjects_ = DocumentObject_[TSGroups].Unload(); //ValueTable
	GroupingObjects_.GroupBy(LinksField);
	GroupingObjects_.Indexes.Add(LinksField);
	
	ObjectsDetailedRecords = DocumentObject_[TSDetailedRecords].Unload(); //ValueTable
	ObjectsDetailedRecords.GroupBy(LinksField);
	
	For Each Record In ObjectsDetailedRecords Do
		Owner = GroupingObjects_.Find(Record[LinksField], LinksField);
		If Owner = Undefined Then
			Filter = New Structure(LinksField, Record[LinksField]);
			FoundRows = DocumentObject_[TSDetailedRecords].FindRows(Filter);
			For Each String In FoundRows Do
				DocumentObject_[TSDetailedRecords].Delete(String);
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Function QueryTextsForAvailableTables()
	
	//Result = New Array;
	Result = New Map;
	If AccessRight("View", Metadata.AccumulationRegisters.FinancialInstrumentsARAP) Then
		Result.Insert("#0", QueryTextFinancialInstrumentsARAP()); //AccumulationRegisterFinancialInstrumentsARAP
	EndIf;
	If AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts) Then
		Result.Insert("#1", TextOfRequestForLoanAgreementsDepositsLoans()); //CatalogLoanAndDepositContracts
	EndIf;
	If AccessRight("View", Metadata.Catalogs.LeaseContract) Then
		Result.Insert("#2", TextOfRequestForLeasingAgreements()); //CatalogLeaseContract
	EndIf;
	If AccessRight("View", Metadata.Documents.SourceDocument) Then
		Result.Insert("#3", QueryTextSourceDocument()); //DocumentSourceDocument
	EndIf;
	If AccessRight("View", Metadata.Documents.ARAPAdjustment) Then
		Result.Insert("#4", QueryTextARAPAdjustment()); //DocumentARAPAdjustment
	EndIf;
	
	Return Result;
	
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
	|	NestedQuery.Partner AS Partner,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	NestedQuery.Currency AS Currency,
	|	UNDEFINED AS AmountType,
	|	TRUE AS ContractsWithoutTurnover, //We always include contracts with turnover
	|	
	|	SUM(NestedQuery.OpeningBalance) AS OpeningBalance,
	|	SUM(NestedQuery.OpeningBalanceLocal) AS OpeningBalanceLocal,
	|	SUM(NestedQuery.OpeningBalanceDr) AS OpeningBalanceDr,
	|	SUM(NestedQuery.OpeningBalanceCr) AS OpeningBalanceCr,
	|	
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	0 AS ClosingBalance,
	|	0 AS ClosingBalanceLocal,
	|	
	|	SUM(NestedQuery.PrincipalDebt) AS PrincipalDebt,
	|	SUM(NestedQuery.Interests) AS Interests,
	|	SUM(NestedQuery.Fee) AS Fee,
	|	
	|	SUM(NestedQuery.LeaseObligations) AS LeaseObligations,
	|	SUM(NestedQuery.DepositPayment) AS DepositPayment,
	|	SUM(NestedQuery.RentalService) AS RentalService,
	|	SUM(NestedQuery.BuyoutValue) AS BuyoutValue,
	|	
	|	NestedQuery.PaymentTypeOrder AS PaymentTypeOrder
	|FROM
	|	(SELECT
	|	&BeginOfPeriod AS Period,
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
	|	Dimension.Partner AS Partner,
	|	Dimension.Counterparty AS Counterparty,
	|	CalculationsBalance.Contract AS Contract,
	|	CalculationsBalance.Contract.LineOfBusiness AS LineOfBusiness,
	|	CalculationsBalance.Currency AS Currency,
	|	
	|	CalculationsBalance.SumBalance AS OpeningBalance,
	|	CalculationsBalance.SumComplBalance AS OpeningBalanceLocal,
	|	CASE WHEN CalculationsBalance.SumBalance > 0
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS OpeningBalanceDr,
	|	CASE WHEN CalculationsBalance.SumBalance < 0
	|		THEN -CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS OpeningBalanceCr,
	|	
	|	CASE WHEN CalculationsBalance.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS PrincipalDebt,
	|	CASE WHEN CalculationsBalance.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS Interests,
	|	CASE WHEN CalculationsBalance.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS Fee,
	|	
	|	CASE WHEN CalculationsBalance.AmountType = &LeaseObligations
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS LeaseObligations,
	|	CASE WHEN CalculationsBalance.AmountType = &DepositPayment
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS DepositPayment,
	|	CASE WHEN CalculationsBalance.AmountType = &RentalService
	|				OR CalculationsBalance.AmountType = &RentalServicePrepayment
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS RentalService,
	|	CASE WHEN CalculationsBalance.AmountType = &BuyoutValue
	|				OR CalculationsBalance.AmountType = &BuyoutValuePrepayment
	|		THEN CalculationsBalance.SumBalance
	|		ELSE 0
	|	END AS BuyoutValue,
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
	|		{&BeginOfPeriod},
	|		AmountType IN (&TypesOfRentalAmounts) OR VALUETYPE(Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|		{AccountingDimensionByPartners.Partner.* AS Partner,
	|		AccountingDimensionByPartners.Partner.MainManager.* AS MainManager,
	|		AccountingDimensionByPartners.Counterparty.* AS Counterparty,
	|		AccountingDimensionByPartners.Contract.LineOfBusiness.* AS LineOfBusiness}
	|	) AS CalculationsBalance
	|	INNER JOIN DimensionByPartners AS Dimension
	|	ON CalculationsBalance.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	CalculationsBalance.SumBalance <> 0) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Organization,
	|	NestedQuery.Partner,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.Currency,
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
	|	NestedQuery.AccountingDimensionByPartners   AS AccountingDimensionByPartners,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Partner AS Partner,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ARAPObject,
	|	NestedQuery.Recorder AS ARAPDocument,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.AmountType AS AmountType,
	|	TRUE AS ContractsWithoutTurnover, //We always include contracts with turnover
	|	
	|	0 AS OpeningBalance,
	|	0 AS OpeningBalanceLocal,
	|	0 AS OpeningBalanceDr,
	|	0 AS OpeningBalanceCr,
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	0 AS ClosingBalance,
	|	0 AS ClosingBalanceLocal,
	|	
	|	SUM(NestedQuery.PrincipalDebt) AS PrincipalDebt,
	|	SUM(NestedQuery.Interests) AS Interests,
	|	SUM(NestedQuery.Fee) AS Fee,
	|	
	|	SUM(NestedQuery.LeaseObligations) AS LeaseObligations,
	|	SUM(NestedQuery.DepositPayment) AS DepositPayment,
	|	SUM(NestedQuery.RentalService) AS RentalService,
	|	SUM(NestedQuery.BuyoutValue) AS BuyoutValue,
	|	
	|	NestedQuery.PaymentTypeOrder AS PaymentTypeOrder
	|FROM
	|	(SELECT
	|	CalculationsRevolutions.Period AS Period,
	|	CASE 
	|		WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|		WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|	END AS PaymentType_,
	|	CalculationsRevolutions.AccountingDimensionByPartners   AS AccountingDimensionByPartners,
	|	Dimension.Organization AS Organization,
	|	Dimension.Partner AS Partner,
	|	Dimension.Counterparty AS Counterparty,
	|	CalculationsRevolutions.Contract AS Contract,
	|	CalculationsRevolutions.Contract.LineOfBusiness AS LineOfBusiness,
	|	CalculationsRevolutions.Recorder AS Recorder,
	|	CalculationsRevolutions.Currency AS Currency,
	|	UNDEFINED AS AmountType,
	|	
	|	0 AS OpeningBalance,
	|	0 AS OpeningBalanceLocal,
	|	0 AS Debt,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	CASE WHEN CalculationsRevolutions.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|		THEN CalculationsRevolutions.SumTurnover
	|		ELSE 0
	|	END AS PrincipalDebt,
	|	CASE WHEN CalculationsRevolutions.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|		THEN CalculationsRevolutions.SumTurnover
	|		ELSE 0
	|	END AS Interests,
	|	CASE WHEN CalculationsRevolutions.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|		THEN CalculationsRevolutions.SumTurnover
	|		ELSE 0
	|	END AS Fee,
	|	
	|	CASE WHEN CalculationsRevolutions.AmountType = &LeaseObligations
	|		THEN CalculationsRevolutions.SumTurnover
	|		ELSE 0
	|	END AS LeaseObligations,
	|	CASE WHEN CalculationsRevolutions.AmountType = &DepositPayment
	|		THEN CalculationsRevolutions.SumTurnover
	|		ELSE 0
	|	END AS DepositPayment,
	|	CASE WHEN CalculationsRevolutions.AmountType = &RentalService
	|				OR CalculationsRevolutions.AmountType = &RentalServicePrepayment
	|		THEN CalculationsRevolutions.SumTurnover
	|		ELSE 0
	|	END AS RentalService,
	|	CASE WHEN CalculationsRevolutions.AmountType = &BuyoutValue
	|				OR CalculationsRevolutions.AmountType = &BuyoutValuePrepayment
	|		THEN CalculationsRevolutions.SumTurnover
	|		ELSE 0
	|	END AS BuyoutValue,
	|	
	|	CASE 
	|		WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN 31
	|		WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|				OR CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN 32
	|		WHEN CalculationsRevolutions.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Lease)
	|			THEN 33
	|	END AS PaymentTypeOrder
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(
	|		{&BeginOfPeriod}, {&EndOfPeriod}, Recorder,
	|		AmountType IN (&TypesOfRentalAmounts) OR VALUETYPE(Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|		{AccountingDimensionByPartners.Partner.* AS Partner,
	|		AccountingDimensionByPartners.Counterparty.* AS Counterparty,
	|		AccountingDimensionByPartners.Contract.LineOfBusiness.* AS LineOfBusiness}
	|	) AS CalculationsRevolutions
	|	INNER JOIN DimensionByPartners AS Dimension
	|	ON CalculationsRevolutions.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	CalculationsRevolutions.SumTurnover <> 0) AS NestedQuery
	|	
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Organization,
	|	NestedQuery.Partner,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.Recorder,
	|	NestedQuery.Currency,
	|	NestedQuery.AmountType,
	|	NestedQuery.PaymentTypeOrder
	|	
	|HAVING
	|	SUM(NestedQuery.PrincipalDebt) <> 0 OR SUM(NestedQuery.Interests) <> 0 OR SUM(NestedQuery.Fee) <> 0
	|	OR SUM(NestedQuery.LeaseObligations) <> 0 OR SUM(NestedQuery.DepositPayment) <> 0
	|	OR SUM(NestedQuery.RentalService) <> 0 OR SUM(NestedQuery.BuyoutValue) <> 0
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
	|	Contracts.Partner AS Partner,
	|	Contracts.Counterparty AS Counterparty,
	|	Contracts.Ref AS Contract,
	|	Contracts.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	Contracts.ARAPCurrency AS Currency,
	|	UNDEFINED AS AmountType,
	|	TRUE AS ContractsWithoutTurnover,
	|		
	|	0 AS OpeningBalance,
	|	0 AS OpeningBalanceLocal,
	|	0 AS OpeningBalanceDr,
	|	0 AS OpeningBalanceCr,
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	0 AS ClosingBalance,
	|	0 AS ClosingBalanceLocal,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS Interests,
	|	0 AS Fee,
	|	
	|	0 AS LeaseObligations,
	|	0 AS DepositPayment,
	|	0 AS RentalService,
	|	0 AS BuyoutValue,
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

Function QueryTextSourceDocument()
	
	Return "
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentAmounts_.Ref AS Recorder,
	|	Turnovers.Organization AS Organization,
	|	Turnovers.PaymentType_ AS PaymentType_,
	|	DocumentAmounts_.IncomingDocumentDate AS DocumentDate,
	|	DocumentAmounts_.IncomingDocumentNumber AS DocumentNumber,
	|	DocumentAmounts_.Date AS IBDocumentDate,
	|	DocumentAmounts_.Number AS IBDocumentNumber,
	|	DocumentAmounts_.ExternalDocumentName AS SourceDocumentName,
	|	DocumentAmounts_.IncomingDocumentDate AS SourceDocumentDate,
	|	DocumentAmounts_.IncomingDocumentNumber AS SourceDocumentNumber,
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
	|	Turnovers.PaymentType_ AS PaymentType_,
	|	DocumentAmounts_.Ref.Date AS DocumentDate,
	|	DocumentAmounts_.Ref.Number AS DocumentNumber,
	|	DocumentAmounts_.Ref.Date AS IBDocumentDate,
	|	DocumentAmounts_.Ref.Number AS IBDocumentNumber,
	|	"""" AS SourceDocumentName,
	|	"""" AS SourceDocumentDate,
	|	"""" AS SourceDocumentNumber,
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
	|	DocumentAmounts_.ARAPCurrency";
	
EndFunction
Function TextOfRequestForLeasingAgreements()
	
	Return "
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) AS PaymentType_,
	|	UNDEFINED AS AccountingDimensionByPartners,
	|	Contracts.Organization AS Organization,
	|	Contracts.Partner AS Partner,
	|	Contracts.Counterparty AS Counterparty,
	|	Contracts.Ref AS Contract,
	|	Contracts.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	Contracts.ARAPCurrency AS Currency,
	|	UNDEFINED AS AmountType,
	|	TRUE AS ContractsWithoutTurnover,
	|		
	|	0 AS OpeningBalance,
	|	0 AS OpeningBalanceLocal,
	|	0 AS OpeningBalanceDr,
	|	0 AS OpeningBalanceCr,
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	
	|	0 AS ClosingBalance,
	|	0 AS ClosingBalanceLocal,
	|	
	|	0 AS PrincipalDebt,
	|	0 AS Interests,
	|	0 AS Fee,
	|	
	|	0 AS LeaseObligations,
	|	0 AS DepositPayment,
	|	0 AS RentalService,
	|	0 AS BuyoutValue,
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
	Query.Text = "
	|SELECT ALLOWED TOP 1
	|	ARAPReconciliation.Partner						  AS Partner,
	|	ARAPReconciliation.Contract						  AS Contract,
	|	ARAPReconciliation.DrillDownByOrders			  AS DrillDownByOrders,
	|	ARAPReconciliation.DrillDownByPartners			  AS DrillDownByPartners,
	|	ARAPReconciliation.DrillDownByContracts			  AS DrillDownByContracts,
	|	ARAPReconciliation.FullNameOfCounterpartyExecutive       AS FullNameOfCounterpartyExecutive,
	|	ARAPReconciliation.JobTitleOfCounterpartyExecutive AS JobTitleOfCounterpartyExecutive,
	|	ARAPReconciliation.ContactPerson                   AS ContactPerson
	|FROM
	|	Document.ARAPReconciliation2_4 AS ARAPReconciliation
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

Function DimensionToCalculation(Organization, Counterparty, PaymentType_, EndOfPeriod) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	DimensionByPartners.DimensionKey AS DimensionKey
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		INNER JOIN InformationRegister.JobsForAllocatingCustomersARAP AS Jobs
	|			ON Jobs.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|WHERE
	|	(DimensionByPartners.Organization IN (&Organization) OR (&ByAllCompanies))
	|		AND (DimensionByPartners.Counterparty IN (&Counterparty) OR (&ForAllCounterparties))
	|		AND (VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) IN (&PaymentType_)  OR &ForAllTypes)
	|	AND Jobs.Month <= &EndOfPeriod
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DimensionByPartners.DimensionKey AS DimensionKey
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		INNER JOIN InformationRegister.JobsForAllocatingVendorsARAP AS Jobs
	|			ON Jobs.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|WHERE
	|	(DimensionByPartners.Organization IN (&Organization) OR (&ByAllCompanies))
	|		AND (DimensionByPartners.Counterparty IN (&Counterparty) OR (&ForAllCounterparties))
	|		AND (VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) IN (&PaymentType_) OR &ForAllTypes)
	|	AND Jobs.Month <= &EndOfPeriod";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Counterparty",  Counterparty);
	Query.SetParameter("PaymentType_", PaymentType_);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Organization));
	Query.SetParameter("ForAllCounterparties", Not ValueIsFilled(Counterparty));
	Query.SetParameter("ForAllTypes", Not ValueIsFilled(PaymentType_));
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	
	DimensionToCalculation = Query.Execute().Unload().UnloadColumn("DimensionKey");
	
	Return DimensionToCalculation;
	
EndFunction

Function StructureAttributesResponsiblePersons() Export
	
	DocumentAttributes = Metadata.Documents.ARAPReconciliation2_4.Attributes;
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
	
	DocumentAttributes = Metadata.Documents.ARAPReconciliation2_4.Attributes;
	Result = New Structure();
	Result.Insert(
		DocumentAttributes.CounterpartyCompanyManager.Name, 
		Enums.PersonsResponsibleAndCompanies.Director);
	Result.Insert(
		DocumentAttributes.ChiefAccountantOfCounterpartyCompany.Name, 
		Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	Return Result;
	
EndFunction


#EndRegion

#EndRegion

#EndIf
