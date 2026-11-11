#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Partner)
	|	AND ValueAllowed(Scenario)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.CashFlowPlansVendors.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.5";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("6e992fe7-e6ff-4926-8079-be1f25b642b8");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.CashFlowPlansVendors.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền số đo ""Số tiền trả trước"" và ""Số tiền trả sau"".';
							|ru = 'Заполняет ресурсы ""Сумма предоплаты"" и ""Сумма постоплаты"".';
							|en = 'Fills in the ""Prepayment amount"" and ""Postpayment amount"" resources.'; fa = 'Fills in the ""Prepayment amount"" and ""Postpayment amount"" resources.';
							|it = 'Fills in the ""Prepayment amount"" and ""Postpayment amount"" resources.';
							|pl = 'Fills in the ""Prepayment amount"" and ""Postpayment amount"" resources.';
							|tr = '""Ön Ödeme Tutarı"" ve ""Faturalı Ödeme Tutarı"" kaynaklarını doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CashFlowPlansVendors.FullName());
	ItemsToRead.Add(Metadata.Documents.PurchasePlan.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.CashFlowPlansVendors.FullName());
	ToLock.Add(Metadata.Documents.PurchasePlan.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.CashFlowPlansVendors.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ObjectsToLock = "";

EndProcedure

// The procedure for registering data for the update handler is to process the data for the transition Version.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName  = Metadata.AccumulationRegisters.CashFlowPlansVendors.FullName();

	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	CashFlowPlansVendors.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CashFlowPlansVendors AS CashFlowPlansVendors
	|WHERE
	|	CashFlowPlansVendors.Recorder REFS Document.PurchasePlan
	|	AND CashFlowPlansVendors.PrepaymentAmountMan = 0
	|	AND CashFlowPlansVendors.PostpaymentAmount = 0";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(
		Parameters, 
		Recorders,
		FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = Metadata.AccumulationRegisters.CashFlowPlansVendors.FullName();

	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	For Each DataDetails In UpdatedData Do
		
		RegistrarIsReadyForProcessing = DataDetails.Recorder;
		If TypeOf(RegistrarIsReadyForProcessing) <> Type("DocumentRef.PurchasePlan") Then
			Continue;
		EndIf;
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.CashFlowPlansVendors.RecordSet");
			LockItem.SetValue("Recorder", RegistrarIsReadyForProcessing);
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add("Document.PurchasePlan");
			LockItem.SetValue("Ref", RegistrarIsReadyForProcessing);
			LockItem.Mode = DataLockMode.Shared;
			
			Block.Lock();
			
			ExceptionReason = "BadData";
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Recorder.Set(RegistrarIsReadyForProcessing);
			RecordSet.Read();
			
			DocumentObject = RegistrarIsReadyForProcessing.GetObject();
			CashFlowPlan = DocumentObject.CashFlowPlan;
			
			For Each Record In RecordSet Do
				PaymentPlanLine = CashFlowPlan[Record.LineNumber-1];
				If PaymentPlanLine.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation
					Or PaymentPlanLine.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt Then
					Record.PrepaymentAmountMan = Record.Sum;
				ElsIf PaymentPlanLine.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt
					Or PaymentPlanLine.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment Then
					Record.PostpaymentAmount = Record.Sum;
				EndIf;
			EndDo;
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			If ExceptionReason = "BadData" Then
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), RegistrarIsReadyForProcessing);
				If ValueIsFilled(RegistrarIsReadyForProcessing) Then
					InfobaseUpdate.MarkProcessingCompletion(RecordSet);
					MessageText = NStr("vi = 'Không thể cập nhật bản ghi kết chuyển của chứng từ %1 theo biểu ghi %2 do: %3';
										|ru = 'Не удалось обновить движения документа %1 по регистру %2 по причине: %3';
										|en = 'Cannot update the %2 register records of the %1 document. Reason: %3'; fa = 'Cannot update the %2 register records of the %1 document. Reason: %3';
										|it = 'Cannot update the %2 register records of the %1 document. Reason: %3';
										|pl = 'Cannot update the %2 register records of the %1 document. Reason: %3';
										|tr = '%2 kaydı kapsamında %1 belgesinin hareketleri şu nedenden dolayı güncellenemedi: %3'");
					
					InfobaseUpdate.FileIssueWithData(
						RegistrarIsReadyForProcessing,
						StringFunctionsClientServer.SubstituteParametersToString(MessageText, RegistrarIsReadyForProcessing, FullObjectName,
							ErrorProcessing.DetailErrorDescription(ErrorInfo())));
				EndIf;
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf