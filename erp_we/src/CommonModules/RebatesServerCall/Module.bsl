//@strict-types

#Region Public

// Document title.
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates, DocumentRef.AccrualOfCustomerRebates, DocumentRef.AccrualOfVendorRebates, DocumentRef.DebitCustomerRebates, DocumentRef.WriteOffVendorRebates - document being processed
//  DocumentNumber - String - document number
//  DocumentDate - Date - Document date
//  Patch - Boolean, Undefined - A sign of a corrective document
// 
// Returns:
//  String - presentation of the document
//
Function DocumentTitle(Val Document, Val DocumentNumber, Val DocumentDate, Val Patch = Undefined) Export
	
	Return RebatesServer.DocumentTitle(Document, DocumentNumber, DocumentDate, Patch);
	
EndFunction

#EndRegion

#Region Internal

// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
// 
// Returns:
//	- Undefined -
//	- See TimeConsumingOperations.ExecuteProcedure
//
Function LongTermOperationOfFixingCompositionOfDocumentConditions(Val Document) Export
	
	KeyTemplate = "FixingComposition_%1";
	DocumentID = String(Document.UUID());
	Var_Key = StrTemplate(KeyTemplate, DocumentID);
	
	Filter = New Structure;
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	
	BackgroundTasksForDocument = BackgroundJobs.GetBackgroundJobs(Filter);
	DocumentFixationIsPerformed = (BackgroundTasksForDocument.Count() > 0);
	
	SetPrivilegedMode(False);
	
	TimeConsumingOperation = Undefined;
	
	If Not DocumentFixationIsPerformed Then
		
		ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
		ExecutionParameters.BackgroundJobKey = Var_Key;
		ExecutionParameters.RefinementErrors = NStr("vi = 'Không thể ghi nhận thành phần:';
													|ru = 'Не удалось зафиксировать состав:';
													|en = 'Cannot record the content:'; fa = 'Cannot record the content:';
													|it = 'Cannot record the content:';
													|pl = 'Cannot record the content:';
													|tr = 'İçerik sabitlenemedi:'");
		
		If TypeOf(Document) = Type("DocumentRef.ConditionsOfCustomerRebates") Then
			
			ProcedureName = "RebatesServer.RecordCompositionOfURBClients";
			
		Else
			
			ProcedureName = "RebatesServer.FixCompositionOfSuppliersURB";
			
		EndIf;
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, ProcedureName, Document);
		
	EndIf;
	
	Return TimeConsumingOperation;
	
EndFunction

// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
// 
// Returns:
//	- Undefined -
//	- See TimeConsumingOperations.ExecuteProcedure 
//
Function LongTermOperationToCancelFixingCompositionOfDocumentConditions(Val Document) Export
	
	KeyTemplate = "FixingComposition_%1";
	DocumentID = String(Document.UUID());
	Var_Key = StrTemplate(KeyTemplate, DocumentID);
	
	Filter = New Structure;
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	
	BackgroundTasksForDocument = BackgroundJobs.GetBackgroundJobs(Filter);
	DocumentFixationIsCanceled = (BackgroundTasksForDocument.Count() > 0);
	
	SetPrivilegedMode(False);
	
	TimeConsumingOperation = Undefined;
	
	If Not DocumentFixationIsCanceled Then
		
		ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
		ExecutionParameters.BackgroundJobKey = Var_Key;
		ExecutionParameters.RefinementErrors = NStr("vi = 'Không thể hủy ghi nhận thành phần:';
													|ru = 'Не удалось отменить фиксацию состава:';
													|en = 'Cannot cancel document recording:'; fa = 'Cannot cancel document recording:';
													|it = 'Cannot cancel document recording:';
													|pl = 'Cannot cancel document recording:';
													|tr = 'İçeriğin sabitlenmesi iptal edilemedi:'");
		
		If TypeOf(Document) = Type("DocumentRef.ConditionsOfCustomerRebates") Then
			
			ProcedureName = "RebatesServer.CancelFixingCompositionOfURBClients";
			
		Else
			
			ProcedureName = "RebatesServer.CancelFixingListOfSuppliersURBS";
			
		EndIf;
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, ProcedureName, Document);
		
	EndIf;
	
	Return TimeConsumingOperation;
	
EndFunction

// Parameters:
//  CalculationParameters - See Reports.CalculateCustomerRebates.RebatesCalculationParameters
//  FormIdentifier - See TimeConsumingOperations.FunctionExecutionParameters.FormIdentifier
// 
// Returns:
//	See TimeConsumingOperations.ExecuteFunction 
//
Function LongTermOperationOfReceivingRebatesAccordingToSalesDocuments(CalculationParameters, FormIdentifier) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(FormIdentifier);
	ExecutionParameters.RefinementErrors = NStr("vi = 'Không thể nhận dữ liệu thưởng khấu hao theo chứng từ bán hàng:';
												|ru = 'Не удалось получить данные ретро-бонусов по документам продажи:';
												|en = 'Cannot get rebate data by sales documents:'; fa = 'Cannot get rebate data by sales documents:';
												|it = 'Не удалось получить данные ретро-бонусов по документам продажи:';
												|pl = 'Cannot get rebate data by sales documents:';
												|tr = 'Satış belgelerinden retro bonus verilerini elde etmek mümkün olmamıştır:'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"Reports.CalculateCustomerRebates.RebatesForPeriodAccordingToSalesDocuments",
		CalculationParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

// Parameters:
//  CalculationParameters - See Reports.CalculateVendorRebates.RebatesCalculationParameters
//  FormIdentifier - See TimeConsumingOperations.FunctionExecutionParameters.FormIdentifier
// 
// Returns:
//	See TimeConsumingOperations.ExecuteFunction 
//
Function LongTermOperationOfObtainingRebateOnPurchaseDocuments(CalculationParameters, FormIdentifier) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(FormIdentifier);
	ExecutionParameters.RefinementErrors = NStr("vi = 'Không thể nhận dữ liệu thưởng khấu hao theo chứng từ tiếp nhận:';
												|ru = 'Не удалось получить данные ретро-бонусов по документам поступления:';
												|en = 'Cannot get rebate data by receipt documents:'; fa = 'Cannot get rebate data by receipt documents:';
												|it = 'Не удалось получить данные ретро-бонусов по документам поступления:';
												|pl = 'Cannot get rebate data by receipt documents:';
												|tr = 'Kabul belgelerinden retro bonusu verileri alınamadı:'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"Reports.CalculateVendorRebates.CalculationOfRebatesForPeriod",
		CalculationParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

// Parameters:
//  AddressOfDataToGenerate - String
//  CalculationParameters - See Reports.CalculateCustomerRebates.RebatesCalculationParameters
//  GenerationParameters - See DataProcessors.BulkAccrualOfCustomerRebates.DocumentGenerationParameters
//  FormIdentifier - See TimeConsumingOperations.FunctionExecutionParameters.FormIdentifier
// 
// Returns:
//  See TimeConsumingOperations.ExecuteFunction
//
Function LongTermOperationOfGeneratingAccrualDocuments(AddressOfDataToGenerate, CalculationParameters, GenerationParameters, FormIdentifier) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(FormIdentifier);
	ExecutionParameters.RefinementErrors = NStr("vi = 'Không thể lập chứng từ tính:';
												|ru = 'Не удалось сформировать документы начисления:';
												|en = 'Cannot generate the accrual documents:'; fa = 'Cannot generate the accrual documents:';
												|it = 'Не удалось сформировать документы начисления:';
												|pl = 'Cannot generate the accrual documents:';
												|tr = 'Tahakkuk belgeleri oluşturulamadı:'");
	DataToGenerate_ = GetFromTempStorage(AddressOfDataToGenerate); // See newedanufactuationdocumentsreferences
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"DataProcessors.BulkAccrualOfCustomerRebates.GenerateAccrualDocuments",
		DataToGenerate_,
		CalculationParameters,
		GenerationParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

// Parameters:
//  AreasWithTranscripts - Structure:
//   * ArrayOfDecryptionIds - Array of DataCompositionDetailsID
//   * Decryption_Area - Map of KeyAndValue:
//     ** Key - DataCompositionDetailsID
//     ** Value - String - Area name
//  DetailsDataAddress - String
//  DecryptionFields - Array of String
//  CloseCalculations - Boolean
// 
// Returns:
//  Structure:
//   * ResultOfAnalysisOfAreas - Structure:
//	   ** ArrayOfConditionDocuments - Array of DocumentRef.ConditionsOfVendorRebates
//	   ** ArrayOfAreaNames - Array of String
//	   ** TermsAndConditionsDocumentsWithAddresses - Map of KeyAndValue:
//		 *** Key - String 
//		 *** Value - DocumentRef.ConditionsOfVendorRebates
//   * ResultOfStatusChange - Structure:
//	   ** HasErrors - Boolean 
//	   ** ErrorInfo - String 
//
Function CloseResumeBonusCalculationsFromReportForm(AreasWithTranscripts, DetailsDataAddress, DecryptionFields, CloseCalculations) Export
	
	ResultOfStatusChange = New Structure;
	ResultOfStatusChange.Insert("HasErrors", False);
	ResultOfStatusChange.Insert("ErrorInfo", "");
	
	ResultOfAnalysisOfAreas = Reports.VendorRebateStatement.DocumentsConditionsOfSelectedAreas(
		AreasWithTranscripts,
		DetailsDataAddress,
		DecryptionFields);
		
	TermsDocuments = ResultOfAnalysisOfAreas.ArrayOfConditionDocuments;
	
	If TermsDocuments.Count() > 0 Then
		
		ResultOfStatusChange = InformationRegisters.CompletedConditionsOfVendorRebates.ChangeStatusOfCalculations(
			TermsDocuments,
			CloseCalculations);
			
	EndIf;
	
	Result = New Structure;
	Result.Insert("ResultOfAnalysisOfAreas", ResultOfAnalysisOfAreas);
	Result.Insert("ResultOfStatusChange", ResultOfStatusChange);
	
	Return Result;
	
EndFunction

#EndRegion