#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a line with the reviewer's approval result in the PM result of the Agreement.
//
// Parameters:
//   RoutePoint         - BusinessProcessRoutePointRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - the point
//       where the business process is located.
//   Reviewer             - CatalogRef.Users - performer of the task by agreement.
//   ApprovalResult - EnumRef.ApprovalResults - The result of coordination at the point of the route.
//   Comment           - String - reviewer's comment.
//   CompletionDate        - Date  - date of completion of the task as agreed by the reviewer.
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
	
	If BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.VersioningOfItemIsUsed(SubjectOf.Metadata().FullName()) Then
		NewRow.VersionNumber = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.LastVersionNumberOfItem(Ref);
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
	
		Query = New Query("
			|SELECT
			|	CASE
			|		WHEN
			|			DocumentSubjectOf.Posted AND DocumentSubjectOf.Approved
			|		THEN
			|			TRUE
			|		ELSE
			|			FALSE
			|	END AS ThereAreErrorsConsistent,
			|	DocumentSubjectOf.Ref AS SubjectOf
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentSubjectOf
			|WHERE
			|	DocumentSubjectOf.Ref = &SubjectOf
			|");
			
		Query.SetParameter("SubjectOf", SubjectOf);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		// The document has already been agreed - there is no point in starting approval
		If Selection.ThereAreErrorsConsistent Then
			
			ErrorText = NStr("vi = '%SubjectOf% không cần thống nhất';
							|ru = '%SubjectOf% не нуждается в согласовании';
							|en = '%SubjectOf% does not require approval'; fa = '%SubjectOf% does not require approval';
							|it = '%SubjectOf% non necessita di essere concordato';
							|pl = '%SubjectOf% nie wymaga uzgodnienia';
							|tr = '%SubjectOf% onaya ihtiyacı yok'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", Selection.SubjectOf);
			
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

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		CompleteBusinessProcessBasedOnRequestForReturnOfGoodsFromClient(FillingData);
	EndIf;
	
	InitializeBusinessProcess();
	
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
	MessagesTemplate = NStr("vi = 'Không chỉ ra %RoleOfConciliator%. Bạn có thể chỉ định trong phân hệ Danh mục và quản trị - Bán hàng - Thống nhất';
							|ru = 'Не указан %RoleOfConciliator%. Указать можно в разделе НСИ и Администрирование - Продажи - Согласование';
							|en = '%RoleOfConciliator% is not specified. You can specify it in the ""Master data and settings — Sales – Approval"" section'; fa = '%RoleOfConciliator% is not specified. You can specify it in the ""Master data and settings — Sales – Approval"" section';
							|it = '%RoleOfConciliator% non è specificato. È possibile specificarlo nella sezione Dati Principali e Amministrazione - Acquisti - Coordinamento';
							|pl = 'Nie określono %RoleOfConciliator%. Można określić w rozdziale Informacja normatywno-pomocnicza i Administrowanie - Sprzedaże - Uzgodnienie';
							|tr = '%RoleOfConciliator% belirtilmedi. Master veri ve yönetim - Satışlar - Onay bölümünde belirtilebilir'");
	
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverOfRequestsForReturnOfGoodsFromCustomers) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverOfRequestsForReturnOfGoodsFromCustomers);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf; 
	
EndProcedure

Procedure EndOnComplete(BusinessProcessRoutePoint, Cancel)
	
	CompletedOn = CurrentSessionDate();
	
EndProcedure

Procedure CheckForVarianceFromAgreementTermsProcessing(BusinessProcessRoutePoint)
	
	SalesServer.CheckNeedToAgreeOnTermsOfSale(
		SubjectOf,
		ThereAreVariancesFromPriceConditions,
		ThereAreVariancesFromFinancialConditions,
		ThereAreVariancesFromLogisticConditions);
	
	Write();
	
EndProcedure

Procedure ApprovalResultProcessingProcessing(BusinessProcessRoutePoint)
	
	SetPrivilegedMode(True);
	
	SubjectObject = SubjectOf.GetObject();
	
	// The document has already been agreed - nothing needs to be done
	If Not SubjectObject.DeletionMark And Not (SubjectObject.Posted And SubjectObject.Approved) Then
		
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
		
		SubjectObject.Approved = True;
		If SubjectObject.Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon Then
			SubjectObject.Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply;
			SubjectObject.ApprovalDate = CurrentSessionDate();
			Documents.RequestForReturnOfGoodsFromCustomer.FillIn_BlankReceiptDates(SubjectObject);
		EndIf;
		
		Try
		
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

Procedure ReplacingCheckingConditions(BusinessProcessRoutePoint, Result)
	
	Query = New Query("
		|SELECT TOP 1
		|	RequestForReturnOfReplacementGoods.Ref AS Ref
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfReplacementGoods
		|WHERE
		|	RequestForReturnOfReplacementGoods.Ref = &Ref
		|");
	
	Query.SetParameter("Ref", SubjectOf);
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Result = True;
	Else
		Result = False;
	EndIf;
	
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
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure ApproveRequestForGoodsReturnFromTheCustomerBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure ReadTheResultsOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
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

Procedure SummarizeApprovalBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure SummarizeApprovalOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	Result = True;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

// Fills in the approval based on the price setting of the item.
//
// Parameters:
//	DocumentBasis - DocumentRef.SalesOrder - Link to the customer's order.
//
Procedure CompleteBusinessProcessBasedOnRequestForReturnOfGoodsFromClient(DocumentBasis)
	
	Query = New Query("
		|SELECT
		|	RequestForReturnOfGoodsFromCustomer.Ref      AS SubjectOf,
		|	RequestForReturnOfGoodsFromCustomer.Status      AS Status,
		|	NOT RequestForReturnOfGoodsFromCustomer.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN
		|			RequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
		|WHERE
		|	RequestForReturnOfGoodsFromCustomer.Ref = &DocumentBasis
		|");
	
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

// Fills in the approval of the customer's order in accordance with the selection.
//
// Parameters:
//	FillingData - Structure - Structure with selection values.
//
Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("SubjectOf") Then
		
		SubjectType = TypeOf(FillingData.SubjectOf);
		
		If SubjectType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			CompleteBusinessProcessBasedOnRequestForReturnOfGoodsFromClient(FillingData.SubjectOf);
		EndIf;
		
	EndIf;
	
EndProcedure

// Initialisere negotiation of installation prices.
//
Procedure InitializeBusinessProcess()
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Other

// Creates and fills in the performer's task
//
// Parameters:
//    BusinessProcessRoutePoint - BusinessProcessRoutePointRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - 
//
// Returns:
//    TaskObject.PerformerTask - The created task.
//
Function CreateTask(Val BusinessProcessRoutePoint)
	
	Task = Tasks.PerformerTask.CreateTask();
	
	Attributes = "TaskDescription, PerformerRole, MainAddressingObject, AdditionalAddressingObject";
	ObjectData = New Structure(Attributes);
	FillPropertyValues(ObjectData, BusinessProcessRoutePoint, Attributes);
	
	Task.Date                          = CurrentSessionDate();
	Task.Author                         = Author;
	Task.Description                  = ObjectData.TaskDescription;
	Task.LongDesc                      = Description;
	Task.SubjectOf                       = SubjectOf;
	Task.Importance                      = Importance;
	Task.PerformerRole               = ObjectData.PerformerRole;
	Task.MainAddressingObject       = ObjectData.MainAddressingObject;
	Task.AdditionalAddressingObject = ObjectData.AdditionalAddressingObject;
	Task.BusinessProcess                 = Ref;
	Task.TaskDueDate                = ApprovalDate;
	Task.RoutePoint                 = BusinessProcessRoutePoint;
	
	Return Task;

EndFunction

#EndRegion

#EndRegion

#EndIf
