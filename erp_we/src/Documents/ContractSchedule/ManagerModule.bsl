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
	
	DocumentMechanisms.Add("ARAPAccounting");
	
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
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ContractSchedule") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Generates a representation of the document
//
// Parameters:
// 		Ref - DocumentRef.ContractSchedule - the document that the view is generated for.
//
// Returns:
// 		FormattedString - Representation of the graph.
//
Function GraphView(Ref) Export
	
	SetPrivilegedMode(True);
	
	RowsArray = New Array;
	
	Query = New Query("
	|SELECT
	|	Schedule.PaymentDate AS Date
	|FROM
	|	Document.ContractSchedule.PaymentScheduleSteps AS Schedule
	|
	|WHERE
	|	Schedule.Ref.Posted
	|	AND Schedule.Ref = &Ref
	|	AND Schedule.PaymentAmount <> 0
	|;
	|///////////////////////////////////////////////////
	|
	|SELECT
	|	Schedule.DateAccordingToSchedule AS Date
	|FROM
	|	Document.ContractSchedule.ContractScheduleSteps AS Schedule
	|
	|WHERE
	|	Schedule.Ref.Posted
	|	AND Schedule.Ref = &Ref
	|	AND Schedule.ActualAmount <> 0
	|;
	|///////////////////////////////////////////////////
	|");
	
	Query.SetParameter("Ref", Ref);
	
	Result = Query.ExecuteBatch();
	
	If Result[0].IsEmpty() And Result[1].IsEmpty() Then
		
		RowsArray.Add(New FormattedString(NStr("vi = 'Chưa đặt';
												|ru = 'Не задан';
												|en = 'Not specified'; fa = 'مشخص نشده';
												|it = 'Non impostato';
												|pl = 'Nie określono';
												|tr = 'Ayarlanmadı'"),, WebColors.FireBrick));
		
	Else
		
		StringExecution = ""; StringExecutionNotSpecified = "";
		ContractType = Common.ObjectAttributeValue(Ref, "Contract.ContractType");
		If ContractType = Enums.ContractTypes.WithCustomer
			Or ContractType = Enums.ContractTypes.ReceiptForTolling2_5 Then
			
			StringExecution = NStr("vi = 'Xuất kho';
									|ru = 'Отгрузка';
									|en = 'Shipment'; fa = 'ارسال';
									|it = 'Spedizione';
									|pl = 'Wysyłka';
									|tr = 'Sevkiyat'");
			StringExecutionNotSpecified = NStr("vi = 'Chưa xác định giao hàng';
												|ru = 'Отгрузка не задана';
												|en = 'Shipment is not specified'; fa = 'Shipment is not specified';
												|it = 'Non è indicata la spedizione';
												|pl = 'Nie zadano wysyłki';
												|tr = 'Sevkiyat belirtilmedi'");
			
		ElsIf ContractType = Enums.ContractTypes.WithVendor
			Or ContractType = Enums.ContractTypes.Import
			Or ContractType = Enums.ContractTypes.TransferToTolling2_5 
			Or ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries Then
			
			StringExecution = NStr("vi = 'Thu';
									|ru = 'Поступление';
									|en = 'Receipt'; fa = 'دریافت';
									|it = 'Arrivo';
									|pl = 'Wpływ';
									|tr = 'Tahsilat'");
			StringExecutionNotSpecified = NStr("vi = 'Chưa chỉ ra tiếp nhận';
												|ru = 'Поступление не задано';
												|en = 'Receipt is not set'; fa = 'Receipt is not set';
												|it = 'Non è indicato il ricevimento';
												|pl = 'Nie zadano wpłaty';
												|tr = 'Tahsilat belirtilmedi'");
		EndIf;
		
		Selection = Result[0].Select();
		NumberOfPayments = Selection.Count();
		If NumberOfPayments = 0 Then
			RowsArray.Add(NStr("vi = 'Chưa xác định thanh toán';
								|ru = 'Оплата не задана';
								|en = 'Payment is not specified'; fa = 'Payment is not specified';
								|it = 'Non è indicato il pagamento';
								|pl = 'Nie ustawiono płatności';
								|tr = 'Ödeme belirtilmedi'"));
		ElsIf NumberOfPayments = 1 Then
			Selection.Next();
			RowsArray.Add(StrTemplate(NStr("vi = 'Thanh toán %1';
											|ru = 'Оплата %1';
											|en = 'Payment %1'; fa = 'Payment %1';
											|it = 'Pagamento %1';
											|pl = 'Płatność %1';
											|tr = 'Ödeme %1'"), Format(Selection.Date, "DLF=D") ));
		Else
			StageText = TMCommonUseClientServer.DeclensionOfWord(
				NumberOfPayments,
				NStr("vi = 'giai đoạn, giai đoạn, giai đoạn, m';
					|ru = 'этапы, этапа, этапов, м';
					|en = 'stage, stages'; fa = 'stage, stages';
					|it = 'этапы, этапа, этапов, м';
					|pl = 'stage, stages';
					|tr = 'aşama, aşama, aşamalar, m'"));
			RowsArray.Add(StrTemplate(NStr("vi = 'Thanh toán theo %1';
											|ru = 'Оплата в %1';
											|en = 'Payment to %1'; fa = 'Payment to %1';
											|it = 'Pagamento in %1';
											|pl = 'Płatność do %1';
											|tr = '%1''da ödeme'"), Format(NumberOfPayments, "NZ=0")) + " " + StageText);
		EndIf;
		
		RowsArray.Add("; ");
		
		Selection = Result[1].Select();
		NumberOfExecutions = Selection.Count();
		If NumberOfExecutions = 0 Then
			RowsArray.Add(StringExecutionNotSpecified);
		ElsIf NumberOfExecutions = 1 Then
			Selection.Next();
			RowsArray.Add(StrTemplate(NStr("vi = '%1 %2';
											|ru = '%1 %2';
											|en = '%1 %2'; fa = '%1 %2';
											|it = '%1 %2';
											|pl = '%1 %2';
											|tr = '%1 %2'"), StringExecution, Format(Selection.Date, "DLF=D")));
		Else
			StageText = TMCommonUseClientServer.DeclensionOfWord(
				NumberOfExecutions,
				NStr("vi = 'giai đoạn, giai đoạn, giai đoạn, m';
					|ru = 'этапы, этапа, этапов, м';
					|en = 'stage, stages'; fa = 'stage, stages';
					|it = 'этапы, этапа, этапов, м';
					|pl = 'stage, stages';
					|tr = 'aşama, aşama, aşamalar, m'"));
			RowsArray.Add(StrTemplate(NStr("vi = '%1 trong %2';
											|ru = '%1 в %2';
											|en = '%1 in %2'; fa = '%1 in %2';
											|it = '%1 in %2';
											|pl = '%1 do %2';
											|tr = '%2''de %1'"), StringExecution, Format(NumberOfExecutions, "NZ=0")) + " " + StageText);
		EndIf;
	EndIf;
	
	Return New FormattedString(RowsArray);
	
EndFunction

// The procedure sets a mark for deletion for the found document
//
// Parameters:
//    Contract - CatalogRef.CounterpartyContracts - An agreement whose schedule should be marked for deletion.
//    DeletionMark - Boolean - Indicates whether the tag is set for deletion.
//
Procedure SetDeletionMark(Contract, DeletionMark) Export
	
	SetPrivilegedMode(True);
	
	Ref = Common.ObjectAttributeValue(Contract, "ContractSchedule");
	
	If ValueIsFilled(Ref) Then
		Ref.GetObject().SetDeletionMark(DeletionMark);
	EndIf;
	
EndProcedure

// Initializes the structure state of execution of the contract
//
// Returns:
// 		Structure - The structure of the state.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithCustomersTable", 1);
	StructureState.Insert("DisplayCalculationsWithSuppliersTable", 2);
	StructureState.Insert("ThisIsContract", True);
	
	Return StructureState;
	
EndFunction

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

// Creates, fills in the schedules of the document with regular payments and conducts it. The Attributes of the Contract are the source of the calculation.
//
// Parameters:
//  ScheduleRef - DocumentRef.ContractSchedule
//  ContractLink - CatalogRef.CounterpartyContracts
//
Procedure CreateFillInRegularPayments(ScheduleRef, ContractLink = Undefined) Export
	
	DocumentSchedule = ScheduleRef.GetObject();
	
	If DocumentSchedule = Undefined Then
		DocumentSchedule = Documents.ContractSchedule.CreateDocument();
		DocumentSchedule.SetNewObjectRef(ScheduleRef);
		DocumentSchedule.Fill(Undefined);
		DocumentSchedule.Date = CurrentSessionDate();
		DocumentSchedule.Contract = ContractLink;
	EndIf;
	
	ContractDetails_ = Common.ObjectAttributesValues(DocumentSchedule.Contract,
		"Date, ValidityStartDate, ValidityEndDate, RegularPaymentTimeFence, DayOfRegularPayment,
		|RegularPaymentAmount");
	
	CurrentDate = BegOfDay(CurrentSessionDate());
	StartDateOfPayments = Max(CurrentDate, ContractDetails_.Date, ContractDetails_.ValidityStartDate);
	EndDateOfPayments = ?(ValueIsFilled(ContractDetails_.ValidityEndDate),
		ContractDetails_.ValidityEndDate, AddMonth(StartDateOfPayments, 12));
	
	DatesOfRegularPayments = Catalogs.CounterpartyContracts.DatesOfRegularPayments(StartDateOfPayments,
		EndDateOfPayments, ContractDetails_.RegularPaymentTimeFence, ContractDetails_.DayOfRegularPayment);
	
	LinesToDelete = New Array;
		
	For Each RowData In DocumentSchedule.PaymentScheduleSteps Do
		If RowData.PaymentDate >= CurrentDate
			Or RowData.PaymentDate <= ContractDetails_.ValidityStartDate Then
			LinesToDelete.Add(RowData);
		EndIf;
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		DocumentSchedule.PaymentScheduleSteps.Delete(RowToDelete);
	EndDo;
	
	LinesToDelete.Clear();
	
	For Each RowData In DocumentSchedule.ContractScheduleSteps Do
		If RowData.DateAccordingToSchedule >= CurrentDate
			Or RowData.DateAccordingToSchedule <= ContractDetails_.ValidityStartDate Then
			LinesToDelete.Add(RowData);
		EndIf;
	EndDo;
		
	For Each RowToDelete In LinesToDelete Do
		DocumentSchedule.ContractScheduleSteps.Delete(RowToDelete);
	EndDo;
		
	For Each PaymentDate In DatesOfRegularPayments Do
		
		NewRow = DocumentSchedule.PaymentScheduleSteps.Add();
		NewRow.PaymentDate = PaymentDate;
		NewRow.PaymentAmount = ContractDetails_.RegularPaymentAmount;
		NewRow.CalculateFrom = Enums.PaymentDateCalculationOptions.FromShipmentDate;
		NewRow.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt;
		
		NewRow = DocumentSchedule.ContractScheduleSteps.Add();
		NewRow.DateAccordingToSchedule = PaymentDate;
		NewRow.DateOfShipment = PaymentDate;
		NewRow.ActualAmount = ContractDetails_.RegularPaymentAmount;
	EndDo;
	
	DocumentSchedule.PaymentScheduleSteps.Sort("PaymentDate");
	DocumentSchedule.ContractScheduleSteps.Sort("DateAccordingToSchedule");
		
	DocumentSchedule.AdditionalProperties.Insert("SkipScheduleUpdate", True);
	
	If DocumentSchedule.CheckFilling() Then
		DocumentSchedule.Write(DocumentWriteMode.Posting);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Contract");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = NStr("vi = 'Lịch thực hiện hợp đồng';
						|ru = 'График исполнения договора';
						|en = 'Contract schedule'; fa = 'برنامه قرارداد';
						|it = 'Grafico di esecuzione del contratto';
						|pl = 'Harmonogram wykonania kontraktu';
						|tr = 'Sözleşmenin yürütülmesi için zaman çizelgesi'") + " " + Data.Contract;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                                     AS Period,
	|	DocumentData.Number                                    AS Number,
	|	DocumentData.Contract                                  AS Contract,
	|	DocumentData.Contract.Organization                      AS Organization,
	|	DocumentData.Contract.Counterparty                       AS Counterparty,
	|	DocumentData.Contract.Partner                          AS Partner,
	|	DocumentData.Contract.LineOfBusiness          AS LineOfBusiness,
	|	DocumentData.Contract.ARAPCurrency             AS Currency,
	|	DocumentData.Contract.ContractType                      AS ContractType
	|FROM
	|	Document.ContractSchedule AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	ContractSchedulePaymentScheduleSteps.Ref                        AS Ref,
	|	ContractSchedulePaymentScheduleSteps.Ref.ScheduleIsPartiallyFulfilled AS ScheduleIsPartiallyFulfilled,
	|	ContractSchedulePaymentScheduleSteps.LineNumber                   AS LineNumber,
	|	ContractSchedulePaymentScheduleSteps.PaymentOption                 AS PaymentOption,
	|	ContractSchedulePaymentScheduleSteps.PaymentDate                   AS PaymentDate,
	|	ContractSchedulePaymentScheduleSteps.DateOfShipment                  AS DateOfShipment,
	|	ContractSchedulePaymentScheduleSteps.PaymentPercentage                AS PaymentPercentage,
	|	ContractSchedulePaymentScheduleSteps.PaymentAmount                  AS PaymentAmount,
	|	ContractSchedulePaymentScheduleSteps.CalculateFrom                AS CalculateFrom,
	|	ContractSchedulePaymentScheduleSteps.Move                         AS Move,
	|	ContractSchedulePaymentScheduleSteps.AlreadyPaid                   AS AlreadyPaid
	|FROM
	|	Document.ContractSchedule.PaymentScheduleSteps AS ContractSchedulePaymentScheduleSteps
	|WHERE
	|	ContractSchedulePaymentScheduleSteps.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(ContractScheduleContractScheduleSteps.ActualAmount), 0) AS Sum
	|FROM
	|	Document.ContractSchedule.ContractScheduleSteps AS
	|		ContractScheduleContractScheduleSteps
	|WHERE
	|	ContractScheduleContractScheduleSteps.Ref = &Ref
	|	AND NOT ContractScheduleContractScheduleSteps.AlreadyShipped";
	
	Result = Query.ExecuteBatch();
	PaymentSchedule = Result[0].Unload();
	SampleShipmentAmount = Result[1].Select();
	AmountToPay = 0;
	If SampleShipmentAmount.Next() Then
		AmountToPay = SampleShipmentAmount.Sum;
	EndIf;
	
	If AmountToPay < PaymentSchedule.Total("PaymentAmount") Then
		IndexOf = PaymentSchedule.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			If Not PaymentSchedule[IndexOf].ScheduleIsPartiallyFulfilled Then
				Break;
			EndIf;
			PaymentSchedule[IndexOf].PaymentAmount = Min(PaymentSchedule[IndexOf].PaymentAmount, AmountToPay);
			AmountToPay = AmountToPay - PaymentSchedule[IndexOf].PaymentAmount;
		EndDo;
	EndIf;
	
	Query.SetParameter("TablePaymentSchedule", PaymentSchedule);
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = "
		|SELECT
		|	PaymentSchedule.Ref,
		|	PaymentSchedule.LineNumber,
		|	PaymentSchedule.PaymentOption,
		|	PaymentSchedule.PaymentDate,
		|	PaymentSchedule.DateOfShipment,
		|	PaymentSchedule.PaymentPercentage,
		|	PaymentSchedule.PaymentAmount,
		|	PaymentSchedule.CalculateFrom,
		|	PaymentSchedule.Move,
		|	PaymentSchedule.AlreadyPaid
		|INTO DocumentDataTableStagesOfPaymentSchedule
		|FROM
		|	&TablePaymentSchedule AS PaymentSchedule
		|WHERE
		|	PaymentSchedule.PaymentAmount > 0";
		
	Query.Execute();
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness = 
		"SELECT
		|	DocumentDataHeader.ARAPObject AS ARAPObject
		|FROM
		|	Document.ContractSchedule AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)";
		
	QueryTextLinesOfBusiness = ARAPAccountingPosting.GetTableOfLinesOfBusiness(QueryTextLinesOfBusiness);

	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	#Region CustomersARAPAccounting
	
	TextPaymentPlans =
		"SELECT
		|	Table.Ref                                                           AS Ref,
		|	Contracts.Organization                                                     AS Organization,
		|	Contracts.Partner                                                         AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Contracts.ARAPCurrency                                            AS ARAPCurrency,
		|	Contracts.ARAPCurrency                                            AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
		|	
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	Table.DateOfShipment                                                     AS DateOfShipment,
		|	Table.PaymentOption                                                    AS PaymentOption,
		|	Table.PaymentAmount                                                     AS AmountDue,
		|		
		|	CASE
		|		WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|			THEN FALSE
		|		ELSE TRUE
		|	END                                                                    AS ExcludeDuringControl
		|	
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON Contracts.Ref = Table.Ref.Contract
		|			AND Contracts.ContractType IN (VALUE(Enum.ContractTypes.WithCustomer),
		|									VALUE(Enum.ContractTypes.ReceiptForTolling2_5))
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	TextShipmentPlans =
		"SELECT
		|	Table.Ref                                                           AS Ref,
		|	Contracts.Organization                                                     AS Organization,
		|	Contracts.Partner                                                         AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Contracts.ARAPObjectSettings                                                 AS ARAPObjectSettings,
		|	Contracts.ARAPCurrency                                            AS ARAPCurrency,
		|	Contracts.ARAPCurrency                                            AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
		|	
		|	ENDOFPERIOD(Table.DateAccordingToSchedule, DAY)                                AS DateOfShipment,
		|	Table.ActualAmount                                                  AS IncreaseToBeSHIPPED
		|	
		|FROM
		|	Document.ContractSchedule.ContractScheduleSteps AS Table
		|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
		|			ON Contracts.Ref = Table.Ref.Contract
		|				AND Contracts.ContractType IN (VALUE(Enum.ContractTypes.WithCustomer),
		|											VALUE(Enum.ContractTypes.ReceiptForTolling2_5))
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.AlreadyShipped";
	
	ARAPAccountingPostingCustomers.CarryingOutScheduleOfExecutionOfContractWithClient(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans, True);
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	TextPaymentPlans =
		"SELECT
		|	Table.Ref                                                              AS Ref,
		|	
		|	Contracts.Organization                                                        AS Organization,
		|	Contracts.Partner                                                            AS Partner,
		|	Contracts.Counterparty                                                         AS Counterparty,
		|	Contracts.Ref                                                             AS Contract,
		|	Contracts.LineOfBusiness                                            AS LineOfBusiness,
		|	
		|	Table.Ref.ARAPObject                                               AS ARAPObject,
		|	Table.Ref.Date                                                         AS RecorderDate,
		|	Table.Ref.Number                                                        AS RecorderNumber,
		|	Contracts.ARAPCurrency                                               AS ARAPCurrency,
		|	Contracts.ARAPCurrency                                               AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfPurchaseOrder) AS BusinessOperation,
		|	
		|	Table.PaymentDate                                                         AS PaymentDate,
		|	Table.DateOfShipment                                                        AS DateOfShipment,
		|	Table.PaymentOption                                                       AS PaymentOption,
		|	Table.PaymentAmount                                                        AS AmountDue
		|	
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON Contracts.Ref = Table.Ref.Contract
		|			AND Contracts.ContractType IN (VALUE(Enum.ContractTypes.WithVendor),
		|										VALUE(Enum.ContractTypes.Import),
		|										VALUE(Enum.ContractTypes.TransferToTolling2_5),
		|										VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	TextDeliveryPlans = 
		"SELECT
		|	Table.Ref                                                              AS Ref,
		|	Contracts.Organization                                                        AS Organization,
		|	Contracts.Partner                                                            AS Partner,
		|	
		|	Table.Ref.ARAPObject                                               AS ARAPObject,
		|	Table.Ref.Date                                                         AS RecorderDate,
		|	Table.Ref.Number                                                        AS RecorderNumber,
		|	Contracts.ARAPObjectSettings                                                 AS ARAPObjectSettings,
		|	Contracts.ARAPCurrency                                               AS ARAPCurrency,
		|	Contracts.ARAPCurrency                                               AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfPurchaseOrder) AS BusinessOperation,
		|	
		|	Table.DateAccordingToSchedule                                                       AS DateOfReceipt,
		|	Table.ActualAmount                                                     AS IncreaseToAdmission
		|FROM
		|	Document.ContractSchedule.ContractScheduleSteps AS Table
		|		INNER JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON Contracts.Ref = Table.Ref.Contract
		|			AND Contracts.ContractType IN (VALUE(Enum.ContractTypes.WithVendor),
		|										VALUE(Enum.ContractTypes.Import),
		|										VALUE(Enum.ContractTypes.TransferToTolling2_5),
		|										VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.AlreadyShipped";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutScheduleOfExecutionOfContractWithSupplier(Query, QueryTexts, Registers, TextPaymentPlans, TextDeliveryPlans);
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersDeliveryPlan(Query, QueryTexts, Registers, TextDeliveryPlans, True);
	
	#EndRegion
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
