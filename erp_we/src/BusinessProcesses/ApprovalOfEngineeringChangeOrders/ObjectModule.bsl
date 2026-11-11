#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a line with the reviewer's approval result in the PM result of the Agreement.
//
// Parameters:
//	RoutePoint         - BusinessProcessRoutePointRef.ApprovalOfEngineeringChangeOrders - 
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
	
	If BusinessProcesses.ApprovalOfEngineeringChangeOrders.VersioningOfItemIsUsed(SubjectOf.Metadata().FullName()) Then
		NewRow.VersionNumber = BusinessProcesses.ApprovalOfEngineeringChangeOrders.LastVersionNumberOfItem(Ref);
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
						|tr = 'Onay tarihi %Date% iş süreci tarihinden az olamaz'");
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
			|			DocumentSubjectOf.Posted AND DocumentSubjectOf.Status = VALUE(Enum.StatusesOfEngineeringChangeOrders.Confirmed)
			|		THEN
			|			TRUE
			|		ELSE
			|			FALSE
			|	END AS ThereAreErrorsConsistent,
			|	DocumentSubjectOf.DeletionMark AS DeletionMark,
			|	DocumentSubjectOf.Ref AS SubjectOf
			|FROM
			|	Document.EngineeringChangeOrder AS DocumentSubjectOf
			|WHERE
			|	DocumentSubjectOf.Ref = &SubjectOf
			|");
			
		Query.SetParameter("SubjectOf", SubjectOf);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		// The document has already been approved or marked for deletion - there is no point in starting approval.
		If Selection.ThereAreErrorsConsistent Then
			
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
			
		EndIf;
		
	EndIf;	
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.EngineeringChangeOrder") Then
		CompleteBusinessProcessBasedOnEngineeringChangeOrderPermission(FillingData);
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

Procedure ToAgreeOnEngineeringChangeOrderPermitForReplacementOfMaterialsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure DocumentApprovedConditionCheck(BusinessProcessRoutePoint, Result)
	
	Result = (ApprovalResult = Enums.ApprovalResults.Approved);
	
EndProcedure

Procedure ApprovalResultProcessingProcessing(BusinessProcessRoutePoint)
	
	SetPrivilegedMode(True);
	
	SubjectObject = SubjectOf.GetObject();
	
	// The document has already been agreed - nothing needs to be done
	If Not SubjectObject.DeletionMark 
	   And Not (SubjectObject.Posted And SubjectObject.Status = Enums.StatusesOfEngineeringChangeOrders.Confirmed) Then
		
		Try
			LockDataForEdit(SubjectOf);
		Except
			
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			ErrorText = NStr("vi = 'Trong tiến trình xử lý kết quả điều chỉnh không thể phong tỏa %SubjectOf%. %ErrorDescription%';
							|ru = 'В ходе обработки результатов согласования не удалось заблокировать %SubjectOf%. %ErrorDescription%';
							|en = 'Cannot lock %SubjectOf% while processing approval results. %ErrorDescription%'; fa = 'Cannot lock %SubjectOf% while processing approval results. %ErrorDescription%';
							|it = 'Nel corso dell''elaborazione degli esiti del concordamento non è stato possibile bloccare %SubjectOf%. %ErrorDescription%';
							|pl = 'W trakcie przetwarzania wyników uzgadniania nie udało się zablokować %SubjectOf%. %ErrorDescription%';
							|tr = 'Sonuçların işlenmesi sürecinde onay %SubjectOf%engellenemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%",        SubjectOf);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ErrorDescription);
			
			Raise ErrorText;
			
		EndTry;
		
		SubjectObject.Status = Enums.StatusesOfEngineeringChangeOrders.Confirmed;
		
		Try
		
			SubjectObject.Write(DocumentWriteMode.Posting);
			UnlockDataForEdit(SubjectOf);
			
		Except
			
			UnlockDataForEdit(SubjectOf);
			
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			ErrorText = NStr("vi = 'Không thể ghi lại %SubjectOf%. %ErrorDescription%';
							|ru = 'Не удалось записать %SubjectOf%. %ErrorDescription%';
							|en = 'Cannot save %SubjectOf%. %ErrorDescription%'; fa = 'Cannot save %SubjectOf%. %ErrorDescription%';
							|it = 'Non è stato possibile registrare %SubjectOf%. %ErrorDescription%';
							|pl = 'Zapisywanie %SubjectOf% nie powiodło się. %ErrorDescription%';
							|tr = '%SubjectOf% kaydedilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%",        SubjectOf);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ErrorDescription);
			
			Raise ErrorText;
			
		EndTry
		
	EndIf;
		
	SetPrivilegedMode(False);
	
EndProcedure

Procedure ReadTheResultsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)
	
	StandardProcessing = False;
	
	Task = CreateTask(BusinessProcessRoutePoint);
	Task.Performer = Author;
	TasksBeingFormed.Add(Task);
	
EndProcedure

Procedure ReadTheResultsOnCheckExecuteProcessing(BusinessProcessRoutePoint, Task, Result)
	
	Result = True;
	
EndProcedure

Procedure EndOnComplete(BusinessProcessRoutePoint, Cancel)
	
	CompletedOn = CurrentSessionDate();
	
EndProcedure

Procedure StartBeforeStart(BusinessProcessRoutePoint, Cancel)
	
	StartDate = CurrentSessionDate();
	
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApprovingPermitsForReplacementOfMaterials) Then
		MessageText = NStr("vi = 'Chưa chỉ ra %RoleOfConciliator%';
							|ru = 'Не указан %RoleOfConciliator%';
							|en = '%RoleOfConciliator% is not specified'; fa = '%RoleOfConciliator% is not specified';
							|it = '%RoleOfConciliator% non è specificato';
							|pl = 'Nie określono %RoleOfConciliator%';
							|tr = '%RoleOfConciliator% belirtilmedi'");
		MessageText = StrReplace(MessageText, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApprovingPermitsForReplacementOfMaterials);
		Common.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

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

Procedure CompleteBusinessProcessBasedOnEngineeringChangeOrderPermission(DocumentBasis)
	
	Query = New Query("SELECT
	|	EngineeringChangeOrder.Ref AS SubjectOf,
	|	CASE
	|		WHEN EngineeringChangeOrder.Posted
	|				AND EngineeringChangeOrder.Status = VALUE(Enum.StatusesOfEngineeringChangeOrders.Confirmed)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsConsistent,
	|	EngineeringChangeOrder.DeletionMark AS DeletionMark
	|FROM
	|	Document.EngineeringChangeOrder AS EngineeringChangeOrder
	|WHERE
	|	EngineeringChangeOrder.Ref = &DocumentBasis");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Selection = Query.Execute().Select();
	Selection.Next();
	
		// The document has already been approved or marked for deletion - there is no point in starting approval.
		If Selection.ThereAreErrorsConsistent Then
			
			ErrorText = NStr("vi = 'Chứng từ %SubjectOf% không cần thống nhất';
							|ru = 'Документ %SubjectOf% не нуждается в согласовании';
							|en = 'Document %SubjectOf% does not require approval'; fa = 'Document %SubjectOf% does not require approval';
							|it = 'Il documento %SubjectOf% non necessita di essere concordato';
							|pl = 'Dokument %SubjectOf% nie wymaga uzgodnienia';
							|tr = '%SubjectOf% belgesinin onaya ihtiyacı yok'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", Selection.SubjectOf);
			
			Raise ErrorText;
			
		ElsIf Selection.DeletionMark Then
			
			ErrorText = NStr("vi = 'Không thể thống nhất chứng từ %SubjectOf%, vì đã bị đánh dấu xóa';
							|ru = 'Документ %SubjectOf% не может быть согласован, т.к. помечен на удаление';
							|en = 'Document %SubjectOf% cannot be approved because it is marked for deletion'; fa = 'Document %SubjectOf% cannot be approved because it is marked for deletion';
							|it = 'Il documento %SubjectOf% non può essere concordato poiché è stato contrassegnato come documento da eliminare';
							|pl = 'Dokument %SubjectOf% nie może zostać uzgodniony, ponieważ jest zaznaczony do usunięcia';
							|tr = '%SubjectOf% belgesi silinmesi için işaretlendiğinden onaylanamaz'");
			ErrorText = StrReplace(ErrorText, "%SubjectOf%", Selection.SubjectOf);
			
			Raise ErrorText;
			
		EndIf;
	
	FillPropertyValues(ThisObject, Selection);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	If CommonClientServer.HasAttributeOrObjectProperty(FillingData, "SubjectOf") Then
		
		SubjectType = TypeOf(FillingData.SubjectOf);
		
		If SubjectType = Type("DocumentRef.EngineeringChangeOrder") Then
			CompleteBusinessProcessBasedOnEngineeringChangeOrderPermission(FillingData.SubjectOf);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitializeBusinessProcess()
	
	Author = Users.AuthorizedUser();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf	
