#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a line with the reviewer's approval result in the PM result of the Agreement.
//
// Parameters:
//	RoutePoint         - BusinessProcessRoutePointRef.ApprovalOfInventoryConsumptionOrder - 
//	Reviewer             - CatalogRef.Users - performer of the task by agreement
//	ApprovalResult - EnumRef.ApprovalResults - 
//	Comment           - String - reviewer's comment
//	CompletionDate        - Date - date of completion of the task as agreed by the reviewer.
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
	
	If BusinessProcesses.ApprovalOfInventoryConsumptionOrder.VersioningOfItemIsUsed(SubjectOf.Metadata().FullName()) Then
		NewRow.VersionNumber = BusinessProcesses.ApprovalOfInventoryConsumptionOrder.LastVersionNumberOfItem(Ref);
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
		
		Common.MessageToUser(
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
			|			DocumentSubjectOf.Posted AND DocumentSubjectOf.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval)
			|		THEN
			|			FALSE
			|		ELSE
			|			TRUE
			|	END AS ThereAreErrorsConsistent,
			|	CASE
			|		WHEN (NOT DocumentSubjectOf.Posted)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ThereAreErrorsPosted,
			|	DocumentSubjectOf.DeletionMark AS DeletionMark,
			|	DocumentSubjectOf.Ref AS SubjectOf
			|FROM
			|	Document.InventoryConsumptionOrder AS DocumentSubjectOf
			|WHERE
			|	DocumentSubjectOf.Ref = &SubjectOf
			|");
			
		Query.SetParameter("SubjectOf", SubjectOf);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		// The document has not been carried out - there is no point in starting approval
		If Selection.ThereAreErrorsPosted Then
			
			ErrorText = NStr("vi = 'Không thể bắt đầu thống nhất, bởi vì chưa kết chuyển chứng từ %SubjectOf%';
							|ru = 'Согласование не может быть начато, т.к. документ %SubjectOf% не проведен';
							|en = 'Cannot start the approval process as the %SubjectOf% document is not posted'; fa = 'Cannot start the approval process as the %SubjectOf% document is not posted';
							|it = 'Согласование не может быть начато, т.к. документ %SubjectOf% не проведен';
							|pl = 'Cannot start the approval process as the %SubjectOf% document is not posted';
							|tr = '%SubjectOf% belgesi kaydedilmediğinden onay başlatılamaz'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", Selection.SubjectOf);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				"SubjectOf",
				,
				Cancel);
				
			Return;
			
		// The document has already been approved or marked for deletion - there is no point in starting approval.
		ElsIf Selection.ThereAreErrorsConsistent Then
			
			ErrorText = NStr("vi = 'Chứng từ %SubjectOf% không cần thống nhất';
							|ru = 'Документ %SubjectOf% не нуждается в согласовании';
							|en = 'Document %SubjectOf% does not require approval'; fa = 'Document %SubjectOf% does not require approval';
							|it = 'Il documento %SubjectOf% non necessita di essere concordato';
							|pl = 'Dokument %SubjectOf% nie wymaga uzgodnienia';
							|tr = '%SubjectOf% belgesinin onaya ihtiyacı yok'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", Selection.SubjectOf);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				"SubjectOf",
				,
				Cancel);
				
			Return;
			
		ElsIf Selection.DeletionMark Then
			
			ErrorText = NStr("vi = 'Không thể thống nhất chứng từ %SubjectOf%, vì đã bị đánh dấu xóa';
							|ru = 'Документ %SubjectOf% не может быть согласован, т.к. помечен на удаление';
							|en = 'Document %SubjectOf% cannot be approved because it is marked for deletion'; fa = 'Document %SubjectOf% cannot be approved because it is marked for deletion';
							|it = 'Il documento %SubjectOf% non può essere concordato poiché è stato contrassegnato come documento da eliminare';
							|pl = 'Dokument %SubjectOf% nie może zostać uzgodniony, ponieważ jest zaznaczony do usunięcia';
							|tr = '%SubjectOf% belgesi silinmesi için işaretlendiğinden onaylanamaz'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", Selection.SubjectOf);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				"SubjectOf",
				,
				Cancel);
				
			Return;
			
		EndIf;
		
		Query = New Query("
		|SELECT TOP 1
		|	TRUE AS NegotiationStarted
		|FROM
		|	BusinessProcess.ApprovalOfInventoryConsumptionOrder AS ApprovalOfInventoryConsumptionOrder
		|WHERE
		|	ApprovalOfInventoryConsumptionOrder.SubjectOf = &SubjectOf
		|	AND ApprovalOfInventoryConsumptionOrder.Started
		|	AND NOT ApprovalOfInventoryConsumptionOrder.Completed
		|	AND NOT ApprovalOfInventoryConsumptionOrder.DeletionMark");
			
		Query.SetParameter("SubjectOf", SubjectOf);
		
		If Not Query.Execute().IsEmpty() Then
			
			ErrorText = NStr("vi = 'Không thể bắt đầu thống nhất, bởi vì theo chứng từ %SubjectOf% đã khởi động quá trình thống nhất';
							|ru = 'Согласование не может быть начато, т.к. по документу %SubjectOf% уже запущен процесс согласования';
							|en = 'Cannot start the approval process as it has already been started for the %SubjectOf% document'; fa = 'Cannot start the approval process as it has already been started for the %SubjectOf% document';
							|it = 'Согласование не может быть начато, т.к. по документу %SubjectOf% уже запущен процесс согласования';
							|pl = 'Cannot start the approval process as it has already been started for the %SubjectOf% document';
							|tr = '%SubjectOf% belgesi için onay süreci başlatıldığından, onay başlatılamaz'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", SubjectOf);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				"SubjectOf",
				,
				Cancel);
				
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.InventoryConsumptionOrder") Then
		CompleteBusinessProcessBasedOnOrderForDOMESTICCONSUMPTION(FillingData);
	EndIf;
	
	InitializeBusinessProcess();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	StartDate            = Date(1,1,1);
	CompletedOn        = Date(1,1,1);
	ApprovalResult = Enums.ApprovalResults.EmptyRef();
	
	ApprovalResults.Clear();
	
	InitializeBusinessProcess();
	
EndProcedure

Procedure StartBeforeStart(BusinessProcessRoutePoint, Cancel)
	
	StartDate = CurrentSessionDate();
	
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverInventoryConsumptionOrder) Then
		MessageText = NStr("vi = 'Chưa chỉ ra %RoleOfConciliator%';
							|ru = 'Не указан %RoleOfConciliator%';
							|en = '%RoleOfConciliator% is not specified'; fa = '%RoleOfConciliator% is not specified';
							|it = '%RoleOfConciliator% non è specificato';
							|pl = 'Nie określono %RoleOfConciliator%';
							|tr = '%RoleOfConciliator% belirtilmedi'");
		MessageText = StrReplace(MessageText, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverInventoryConsumptionOrder);
		Common.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure EndOnComplete(BusinessProcessRoutePoint, Cancel)
	
	CompletedOn = CurrentSessionDate();
	
EndProcedure

Procedure ApprovalResultProcessingProcessing(BusinessProcessRoutePoint)
	
	SetPrivilegedMode(True);
	
	SubjectObject = SubjectOf.GetObject();
	
	// The document has already been agreed - nothing needs to be done
	If Not SubjectObject.DeletionMark And Not (SubjectObject.Posted And SubjectObject.Status <> Enums.InternalOrderStatuses.AwaitingApproval) Then
		
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
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			Raise ErrorText;
			
		EndTry;
		
		SubjectObject.Approved = True;
		SubjectObject.Status = Enums.InternalOrderStatuses.ForCompletion;
		
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
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			Raise ErrorText;
			
		EndTry
		
	EndIf;
		
	SetPrivilegedMode(False);
	
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

Procedure CoordinateOrderForInternalConsumptionBeforeCreatingTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure ReadTheResultsOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	Result = True;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Function CreateTask(Val BusinessProcessRoutePoint)
	
	Attributes = "TaskDescription, PerformerRole, MainAddressingObject, AdditionalAddressingObject";
	AttributesValues = New Structure(Attributes);
	FillPropertyValues(AttributesValues, BusinessProcessRoutePoint, Attributes);
	
	Task = Tasks.PerformerTask.CreateTask();
	
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

Procedure CompleteBusinessProcessBasedOnOrderForDOMESTICCONSUMPTION(DocumentBasis)
	
	Query = New Query("
		|SELECT
		|	InventoryConsumptionOrder.Ref           AS SubjectOf,
		|	InventoryConsumptionOrder.Status           AS Status,
		|	CASE
		|		WHEN
		|			InventoryConsumptionOrder.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus
		|FROM
		|	Document.InventoryConsumptionOrder AS InventoryConsumptionOrder
		|WHERE
		|	InventoryConsumptionOrder.Ref = &DocumentBasis
		|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.InternalOrderStatuses.AwaitingApproval);
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Selection.Status;
	CheckParameters.ThereAreErrorsPosted = False;
	CheckParameters.ThereAreErrorsStatus = Selection.ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(Selection.SubjectOf, CheckParameters);
	
	FillPropertyValues(ThisObject, Selection);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("SubjectOf") Then
		
		SubjectType = TypeOf(FillingData.SubjectOf);
		
		If SubjectType = Type("DocumentRef.InventoryConsumptionOrder") Then
			CompleteBusinessProcessBasedOnOrderForDOMESTICCONSUMPTION(FillingData.SubjectOf);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitializeBusinessProcess()
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
