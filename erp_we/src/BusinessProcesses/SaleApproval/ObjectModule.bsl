#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a line with the reviewer's approval result in the PM result of the Agreement.
//
// Parameters:
//	RoutePoint         - BusinessProcessRoutePointRef.SaleApproval - the current point of the approval route.
//	Reviewer             - CatalogRef.Users - performer of the task by agreement.
//	ApprovalResult - EnumRef.ApprovalResults - the result of the negotiation.
//	Comment           - String - reviewer's comment.
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
	
	If BusinessProcesses.SaleApproval.VersioningOfItemIsUsed(SubjectOf.Metadata().FullName()) Then
		NewRow.VersionNumber = BusinessProcesses.SaleApproval.LastVersionNumberOfItem(Ref);
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
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"ApprovalDate",
			,
			Cancel);
		
	EndIf;
	
	If ValueIsFilled(SubjectOf) Then
		
		TableName = SubjectOf.Metadata().FullName();
		
		Query = New Query("
			|SELECT
			|&FieldsByTable,
			|	DocumentSubjectOf.Status AS Status,
			|	DocumentSubjectOf.Ref AS SubjectOf
			|FROM
			|	&TableName AS DocumentSubjectOf
			|WHERE
			|	DocumentSubjectOf.Ref = &SubjectOf
			|");
		
		If TableName = "Catalog.TermsOfSale" Then
			FieldsByTable = "
			|	CASE
			|		WHEN
			|			DocumentSubjectOf.Approved
			|		THEN
			|			TRUE
			|		ELSE
			|			FALSE
			|	END AS ThereAreErrorsConsistent,
			|	FALSE AS ThereAreErrorsPosted,
			|
			|";
		Else	
			FieldsByTable = "
			|	CASE
			|		WHEN
			|			DocumentSubjectOf.Posted AND DocumentSubjectOf.Approved
			|		THEN
			|			TRUE
			|		ELSE
			|			FALSE
			|	END AS ThereAreErrorsConsistent,
			|	CASE
			|		WHEN
			|			NOT DocumentSubjectOf.Posted
			|		THEN
			|			TRUE
			|		ELSE
			|			FALSE
			|	END AS ThereAreErrorsPosted,
			|
			|";
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&FieldsByTable,", FieldsByTable);
		Query.Text = StrReplace(Query.Text, "&TableName", TableName);
			
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

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Then
		CompleteBusinessProcessBasedOnCustomerOrder(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then
		CompleteBusinessProcessBasedOnAgreementWithClient(FillingData);
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
	MessagesTemplate = NStr("vi = 'Không chỉ ra %RoleOfConciliator%. Bạn có thể chỉ ra trong phân hệ Danh mục và quản trị - Bán hàng - Thống nhất';
							|ru = 'Не указан %RoleOfConciliator%. Указать можно в разделе НСИ и Администрирование - Продажи - Согласование';
							|en = '%RoleOfConciliator% is not specified. You can specify it in the ""Master data and settings — Sales – Approval"" section'; fa = '%RoleOfConciliator% is not specified. You can specify it in the ""Master data and settings — Sales – Approval"" section';
							|it = '%RoleOfConciliator% non è specificato. È possibile specificarlo nella sezione Dati Principali e Amministrazione - Acquisti - Coordinamento';
							|pl = 'Nie określono %RoleOfConciliator%. Można określić w rozdziale Informacja normatywno-pomocnicza i Administrowanie - Sprzedaże - Uzgodnienie';
							|tr = '%RoleOfConciliator% belirtilmedi. Master veri ve yönetim - Satışlar - Onay bölümünde belirtilebilir'");
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverSalesCommercialTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverSalesCommercialTerms);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverSalesLogisticsTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverSalesLogisticsTerms);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverSalesFinancialTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator%", Catalogs.PerformerRoles.ApproverSalesFinancialTerms);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	If Not TMCommonUse.CheckReconcilingBusinessProcess(Catalogs.PerformerRoles.ApproverSalesPriceTerms) Then
		MessageText = StrReplace(MessagesTemplate, "%RoleOfConciliator", Catalogs.PerformerRoles.ApproverSalesPriceTerms);
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
	
	NeedToAgree = False;
	SubjectType = TypeOf(SubjectOf);
	If SubjectType = Type("CatalogRef.TermsOfSale") Then
		If Not SubjectObject.DeletionMark And Not SubjectObject.Approved Then
			NeedToAgree = True;
		EndIf;
	Else
		If Not SubjectObject.DeletionMark And Not (SubjectObject.Posted And SubjectObject.Approved) Then
			NeedToAgree = True;
		EndIf;
	EndIf;
	
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
		
		SubjectObject.Approved = True;
		
		SubjectType = TypeOf(SubjectOf);
			
		If SubjectType = Type("DocumentRef.SalesOrder") Then
			
			If SubjectObject.Status = Enums.SalesOrderStatuses.NotApproved Then
				
				SubjectObject.Status = Enums.SalesOrderStatuses.ToSupply;
				SubjectObject.ApprovalDate = CurrentSessionDate();
				
				ThisIsOrderFromWarehouse = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
					And Not GetFunctionalOption("UseShipmentByRowsInSalesOrder");
				
				If ThisIsOrderFromWarehouse Then
					ProvisionInDocumentsServer.FillInDefaultSecurityOption(SubjectObject.Goods, False, SubjectObject.Status);
				EndIf;
				
			EndIf;
			
		ElsIf SubjectType = Type("CatalogRef.TermsOfSale") Then
			
			If SubjectObject.Status = Enums.StatusesOfTermsOfSales.NotApproved Then
				SubjectObject.Status = Enums.StatusesOfTermsOfSales.Valid;
			EndIf;
			
		EndIf;
		
		Try
			
			If SubjectType = Type("CatalogRef.TermsOfSale") Then
				SubjectObject.Write();
			Else
				SubjectObject.Write(DocumentWriteMode.Posting);
			EndIf;
			
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

Procedure CompleteBusinessProcessBasedOnCustomerOrder(DocumentBasis)
	
	Query = New Query("
		|SELECT
		|	SalesOrder.Ref           AS SubjectOf,
		|	SalesOrder.ApprovalDate AS ApprovalDate,
		|	CASE
		|		WHEN SalesOrder.Priority IN
		|				(SELECT TOP 1
		|					Priorities.Ref AS Priority
		|				FROM
		|					Catalog.Priorities AS Priorities
		|				ORDER BY
		|					Priorities.AddlOrderingAttribute)
		|			THEN VALUE(Enum.TaskImportanceOptions.High)
		|		WHEN SalesOrder.Priority IN
		|				(SELECT TOP 1
		|					Priorities.Ref AS Priority
		|				FROM
		|					Catalog.Priorities AS Priorities
		|				ORDER BY
		|					Priorities.AddlOrderingAttribute DESC)
		|			THEN VALUE(Enum.TaskImportanceOptions.Low)
		|		ELSE VALUE(Enum.TaskImportanceOptions.Ordinary)
		|	END                         AS Importance,
		|	SalesOrder.Status           AS Status,
		|	NOT SalesOrder.Posted      AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN
		|			SalesOrder.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &DocumentBasis
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

Procedure CompleteBusinessProcessBasedOnAgreementWithClient(DocumentBasis)
	
	Query = New Query("
		|SELECT
		|	CustomerTermsOfSales.Ref           AS SubjectOf,
		|	CustomerTermsOfSales.Status           AS Status,
		|	CASE
		|		WHEN
		|			CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.NotApproved)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus
		|FROM
		|	Catalog.TermsOfSale AS CustomerTermsOfSales
		|WHERE
		|	CustomerTermsOfSales.Ref = &DocumentBasis
		|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfSales.NotApproved);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.SubjectOf,
		Selection.Status,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, Selection);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("SubjectOf") Then
		
		SubjectType = TypeOf(FillingData.SubjectOf);
		
		If SubjectType = Type("DocumentRef.SalesOrder") Then
			CompleteBusinessProcessBasedOnCustomerOrder(FillingData.SubjectOf);
		ElsIf SubjectType = Type("CatalogRef.TermsOfSale") Then
			CompleteBusinessProcessBasedOnAgreementWithClient(FillingData.SubjectOf);
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
