#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a line with the reviewer's approval result in the PM result of the Agreement.
//
// Parameters:
//   RoutePoint         - BusinessProcessRoutePointRef.PurchaseApproval - the point where the business process is located.
//   Reviewer             - CatalogRef.Users                         - performer of the task by agreement.
//   ApprovalResult - EnumRef.ApprovalResults             - the result of the negotiation.
//   Comment           - String                                                - reviewer's comment.
//   CompletionDate        - Date                                                  - date of completion of the task as
//                                                                                   agreed by the reviewer.
//
Procedure AddApprovalResult(Val RoutePoint,
	                                    Val Reviewer,
	                                    Val ApprovalResult,
	                                    Val Comment,
	                                    Val CompletionDate) Export
	
	NewRow                       = ApprovalResults.Add();
	NewRow.RoutePoint         = RoutePoint;
	NewRow.Reviewer             = Reviewer;
	NewRow.ApprovalResult = ApprovalResult;
	NewRow.Comment           = Comment;
	NewRow.ApprovalDate      = CompletionDate;
	
	If BusinessProcesses.PurchaseApproval.VersioningOfItemIsUsed(SubjectOf.Metadata().FullName()) Then
		NewRow.VersionNumber = BusinessProcesses.PurchaseApproval.LastVersionNumberOfItem(Ref);
	EndIf;
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement
// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export
	
	// Constraint logic:
	// Read: Unlimited.
	// Change: Not used.
	
	// Reading, Changing: Set No. 0.
	String = Table.Add();
	String.AccessValue = Enums.AdditionalAccessValues.AccessAllowed;
	
EndProcedure 

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.PurchaseOrder") Then
		CompleteBusinessProcessBasedOnOrderToSupplier(FillingData);
	EndIf;
	
	InitializeBusinessProcess();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// The date of approval must be at least the date of the document
	If ValueIsFilled(ApprovalDate) And ApprovalDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày thống nhất không được nhỏ hơn ngày của quy trình nghiệp vụ %Date%';
						|ru = 'Дата согласования должна быть не меньше даты бизнес-процесса %Date%';
						|en = 'Approval date must not be earlier than the business process date %Date%'; fa = 'Approval date must not be earlier than the business process date %Date%';
						|it = 'La data di definizione non deve essere inferiore alla data del processo aziendale %Date%';
						|pl = 'Data uzgodnienia nie może być wcześniejsza od daty procesu biznesowego %Date%';
						|tr = 'Onay tarihi %Date% iş süreci tarihinden az olamaz '");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"ApprovalDate",
			,
			Cancel);
		
	EndIf;
	
	If ValueIsFilled(SubjectOf) Then
		
		Query = New Query(
		"SELECT
		|	CASE
		|		WHEN DocumentSubjectOf.Posted
		|				AND DocumentSubjectOf.Approved
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreErrorsConsistent,
		|	CASE
		|		WHEN (NOT DocumentSubjectOf.Posted)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreErrorsPosted,
		|	DocumentSubjectOf.Status AS Status,
		|	DocumentSubjectOf.Ref AS SubjectOf
		|FROM
		|	Document.PurchaseOrder AS DocumentSubjectOf
		|WHERE
		|	DocumentSubjectOf.Ref = &SubjectOf");
			
		Query.SetParameter("SubjectOf", SubjectOf);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		// The document has not been carried out - there is no point in starting approval
		If Selection.ThereAreErrorsPosted Then
			
			ErrorText = NStr("vi = 'Không thể bắt đầu điều chỉnh, vì chứng từ %DocumentSubjectOf% chưa kết chuyển';
							|ru = 'Согласование не может быть начато, т.к. документ %DocumentSubjectOf% не проведен';
							|en = 'Cannot start approval because document %DocumentSubjectOf% is not posted'; fa = 'Cannot start approval because document %DocumentSubjectOf% is not posted';
							|it = 'Non è possibile avviare il concordamento perché il documento %DocumentSubjectOf% non è stato messo in lavorazione';
							|pl = 'Uzgadnianie nie może zostać rozpoczęte, ponieważ dokument %DocumentSubjectOf% nie jest zatwierdzony';
							|tr = '%DocumentSubjectOf% belgesi kaydedilmediğinden onay başlatılamaz'");
			ErrorText = StrReplace(ErrorText, "%DocumentSubjectOf%", Selection.SubjectOf);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"SubjectOf",
				,
				Cancel);
				
			Return;
			
		// The document has already been agreed - there is no point in starting approval
		ElsIf Selection.ThereAreErrorsConsistent Then
			
			ErrorText = NStr("vi = '%SubjectOf% ở trạng thái ""%Status%"" không cần thống nhất';
							|ru = '%SubjectOf% в статусе ""%Status%"" не нуждается в согласовании';
							|en = '%SubjectOf% with the ""%Status%"" status does not require approval'; fa = '%SubjectOf% with the ""%Status%"" status does not require approval';
							|it = '%SubjectOf% nello stato ""%Status%"" non necessita di essere concordato';
							|pl = '%SubjectOf% o statusie ""%Status%"" nie wymaga uzgodnienia';
							|tr = '""%Status%"" durumunda %SubjectOf% onaya ihtiyacı yok'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", Selection.SubjectOf);
			ErrorText = StrReplace(ErrorText, "%Status%",  Selection.Status);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"SubjectOf",
				,
				Cancel);
				
			Return;
				
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	StartDate            = Date(1,1,1);
	EndDate         = Date(1,1,1);
	ApprovalResult = Enums.ApprovalResults.EmptyRef();
	ThereAreVariancesFromLogisticConditions = False;
	ThereAreVariancesFromFinancialConditions    = False;
	ThereAreVariancesFromLogisticConditions = False;
	
	ApprovalResults.Clear();
	
	InitializeBusinessProcess();
	
EndProcedure

Procedure StartBeforeStart(BusinessProcessRoutePoint, Cancel)
	
	StartDate = CurrentSessionDate();
	MessagesTemplate = NStr("vi = 'Không chỉ định %RoleOfConciliator%. Bạn có thể chỉ định trong phần Danh mục và Quản trị - Mua hàng';
							|ru = 'Не указан %RoleOfConciliator%. Указать можно в разделе НСИ и Администрирование - Закупки';
							|en = '%RoleOfConciliator% is not specified. You can specify it in the ""Master data and settings — Purchases"" section'; fa = '%RoleOfConciliator% is not specified. You can specify it in the ""Master data and settings — Purchases"" section';
							|it = '%RoleOfConciliator% non è specificato. È possibile specificarlo nella sezione Dati Principali e Amministrazione - Acquisti';
							|pl = 'Nie określono %RoleOfConciliator%. Można określić w rozdziale Informacja normatywno-pomocnicza i Administrowanie - Zakupy';
							|tr = '%RoleOfConciliator% belirtilmedi. Master veri ve yönetim - Satın alma bölümünde belirtilebilir'");
	
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverPurchaseCommercialTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverPurchaseCommercialTerms);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverPurchaseLogisticsTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverPurchaseLogisticsTerms);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverPurchaseFinancialTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverPurchaseFinancialTerms);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverPurchasePriceTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverPurchasePriceTerms);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;

EndProcedure

Procedure EndOnComplete(BusinessProcessRoutePoint, Cancel)
	
	CompletedOn = CurrentSessionDate();
	
EndProcedure

Procedure CheckForVarianceFromAgreementTermsProcessing(BusinessProcessRoutePoint)
	
	PurchasesServer.CheckNeedToAgreeOnTermsOfPurchase(
		SubjectOf,
		ThereAreVariancesFromPriceConditions,
		ThereAreVariancesFromFinancialConditions,
		ThereAreVariancesFromLogisticConditions);
	
	Write();
	
EndProcedure

Procedure ApprovalResultProcessingProcessing(BusinessProcessRoutePoint)
	
	SetPrivilegedMode(True);
	
	SubjectObject = SubjectOf.GetObject();
	
	NeedToAgree = (Not SubjectObject.DeletionMark And Not (SubjectObject.Posted And SubjectObject.Approved));
	
	// If the document has already been agreed, nothing needs to be done.
	If NeedToAgree Then
		
		Try
			LockDataForEdit(SubjectOf);
		Except
			
			ErrorText = NStr("vi = 'Trong tiến trình xử lý kết quả điều chỉnh không thể phong tỏa %SubjectOf%. %ErrorDescription%';
							|ru = 'В ходе обработки результатов согласования не удалось заблокировать %SubjectOf%. %ErrorDescription%';
							|en = 'Cannot lock %SubjectOf% while processing approval results. %ErrorDescription%'; fa = 'Cannot lock %SubjectOf% while processing approval results. %ErrorDescription%';
							|it = 'Nel corso dell''elaborazione degli esiti del concordamento non è stato possibile bloccare %SubjectOf%. %ErrorDescription%';
							|pl = 'W trakcie przetwarzania wyników uzgadniania nie udało się zablokować %SubjectOf%. %ErrorDescription%';
							|tr = 'Sonuçların işlenmesi sürecinde onay %SubjectOf%engellenemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%",        SubjectOf);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			Raise ErrorText;
				
		EndTry;
		
		Try
			SubjectObject.Approved = True;
			
			If SubjectObject.Status = Enums.PurchaseOrderStatuses.NotApproved Then
				If Not SubjectObject.SetStatus("Confirmed_", ) Then
					ErrorTextStatus = NStr("vi = 'Không thể thay đổi trạng thái';
											|ru = 'Невозможно изменить статус';
											|en = 'Cannot change status'; fa = 'Cannot change status';
											|it = 'È impossibile modificare lo status';
											|pl = 'Zmiana statusu nie jest możliwa';
											|tr = 'Durumun değiştirilmesi imkansız'");
					Raise ErrorTextStatus;
				EndIf;
				SubjectObject.ApprovalDate = CurrentSessionDate();
			EndIf;
			
			SubjectObject.Write(DocumentWriteMode.Posting);
			
			UnlockDataForEdit(SubjectOf);
			
		Except
			
			UnlockDataForEdit(SubjectOf);
			
			ErrorText = NStr("vi = 'Không thể ghi lại %SubjectOf%. %ErrorDescription%';
							|ru = 'Не удалось записать %SubjectOf%. %ErrorDescription%';
							|en = 'Cannot save %SubjectOf%. %ErrorDescription%'; fa = 'Cannot save %SubjectOf%. %ErrorDescription%';
							|it = 'Non è stato possibile registrare %SubjectOf%. %ErrorDescription%';
							|pl = 'Zapisywanie %SubjectOf% nie powiodło się. %ErrorDescription%';
							|tr = '%SubjectOf% kaydedilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%",        SubjectOf);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			Raise ErrorText;
			
		EndTry
		
	EndIf;
		
	SetPrivilegedMode(False);
	
EndProcedure

Procedure ThereIsADeviationFromPriceConditionConditionCheck(BusinessProcessRoutePoint, Result)
	
	Result = ThereAreVariancesFromPriceConditions;
	
EndProcedure

Procedure ThereIsADeviationFromFinancialConditionConditionCheck(BusinessProcessRoutePoint, Result)
	
	Result = ThereAreVariancesFromFinancialConditions;
	
EndProcedure

Procedure ThereIsDeviationFromLogisticConditionsCheckCondition(BusinessProcessRoutePoint, Result)
	
	Result = ThereAreVariancesFromLogisticConditions;
	
EndProcedure

Procedure DocumentApprovedConditionCheck(BusinessProcessRoutePoint, Result)
	
	Result = (ApprovalResult = Enums.ApprovalResults.Approved);
	
EndProcedure

Procedure ReadTheResultsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	Task.Performer = Author;
	TasksBeingFormed.Add(Task)
	
EndProcedure

Procedure ReadTheResultsOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	Result = True;
	
EndProcedure

Procedure ApprovePriceConditionsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	AgreeOnDocumentBeforeCreatingTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing);
	
EndProcedure

Procedure ApprovePriceConditionsOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	AgreeOnDocumentProcessingExecutionCheck(BusinessProcessRoutePoint, Task, Result);
	
EndProcedure

Procedure ApproveFinancialConditionsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	AgreeOnDocumentBeforeCreatingTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing);
	
EndProcedure

Procedure ApproveFinancialConditionsOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	AgreeOnDocumentProcessingExecutionCheck(BusinessProcessRoutePoint, Task, Result);
	
EndProcedure

Procedure ApproveLogisticConditionsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	AgreeOnDocumentBeforeCreatingTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing);
	
EndProcedure

Procedure ApproveLogisticConditionsOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	AgreeOnDocumentProcessingExecutionCheck(BusinessProcessRoutePoint, Task, Result);
	
EndProcedure

Procedure SummarizeApprovalBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure SummarizeApprovalOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	Result = True;
	
EndProcedure

Procedure AgreeOnDocumentBeforeCreatingTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure AgreeOnDocumentProcessingExecutionCheck(BusinessProcessRoutePoint, Task, Result)
	
	Result = True;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure CompleteBusinessProcessBasedOnOrderToSupplier(DocumentBasis)
	
	Query = New Query(
	"SELECT
	|	PurchaseOrder.Ref AS SubjectOf,
	|	PurchaseOrder.ApprovalDate AS ApprovalDate,
	|	CASE
	|		WHEN PurchaseOrder.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN VALUE(Enum.TaskImportanceOptions.High)
	|		WHEN PurchaseOrder.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN VALUE(Enum.TaskImportanceOptions.Low)
	|		ELSE VALUE(Enum.TaskImportanceOptions.Ordinary)
	|	END AS Importance,
	|	PurchaseOrder.Status AS Status,
	|	(NOT PurchaseOrder.Posted) AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.NotApproved)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref = &DocumentBasis");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.NotApproved);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.SubjectOf,
		Selection.Status,
		Selection.ThereAreErrorsPosted,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, Selection);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("SubjectOf") Then
		
		SubjectType = TypeOf(FillingData.SubjectOf);
		
		If SubjectType = Type("DocumentRef.PurchaseOrder") Then
			CompleteBusinessProcessBasedOnOrderToSupplier(FillingData.SubjectOf);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitializeBusinessProcess()
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Other

Function CreateTask(Val BusinessProcessRoutePoint)
	
	Task = Tasks.PerformerTask.CreateTask();
	
	Attributes = "TaskDescription, PerformerRole, MainAddressingObject, AdditionalAddressingObject";
	AttributesValues = New Structure(Attributes);
	FillPropertyValues(AttributesValues, BusinessProcessRoutePoint, Attributes);
	
	Task.Date                          = CurrentSessionDate();
	Task.Author                         = Author;
	Task.Description                  = AttributesValues.TaskDescription;
	Task.LongDesc                      = Description;
	Task.SubjectOf                       = SubjectOf;
	Task.Importance                      = Importance;
	Task.PerformerRole               = AttributesValues.PerformerRole;
	Task.MainAddressingObject       = AttributesValues.MainAddressingObject;
	Task.AdditionalAddressingObject = AttributesValues.AdditionalAddressingObject;
	Task.BusinessProcess                 = Ref;
	Task.TaskDueDate                = ApprovalDate;
	Task.RoutePoint                 = BusinessProcessRoutePoint;
	
	Return Task;

EndFunction

#EndRegion

#EndRegion

#EndIf
