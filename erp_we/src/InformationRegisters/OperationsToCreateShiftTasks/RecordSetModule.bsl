
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	MonitoringDisabled = InformationRegisters.OperationsToCreateShiftTasks.KeyIsNotToControlDataWhenWriting();
	
	If Count() > 0
		And Not AdditionalProperties.Property(MonitoringDisabled) Then
		
		ControlOfAssignmentOfOperations(Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure ControlOfAssignmentOfOperations(Cancel)
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.AttributesOfContractorOfOperation = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("(Queue.Stage, Queue.Operation, Queue.OperationID) IN (&SelectionTextOfOperationStage)");
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	NULL                     AS Stage,
		|	NULL                     AS Operation,
		|	NULL                     AS OperationID,
		|	NULL                     AS NameOfTheOperation,
		|	Operations.ShiftTask  AS ShiftTask,
		|	NULL                     AS Performer,
		|	CASE
		|		WHEN NOT Jobs.Posted
		|			THEN ""TaskFailed""
		|		ELSE ""TaskStatusIsNotGenerated""
		|	END                    AS ErrorCode
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		LEFT JOIN Document.ShiftTask AS Jobs
		|		ON Operations.ShiftTask = Jobs.Ref
		|WHERE
		|	Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|	AND &SetRecords
		|	AND (NOT Jobs.Posted
		|			OR Jobs.Status <> VALUE(Enum.ShiftTaskStatuses.BeingGenerated))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	NULL                           AS Stage,
		|	Operations.Operation              AS Operation,
		|	Operations.OperationID AS OperationID,
		|	Queue.Description           AS NameOfTheOperation,
		|	NULL                           AS ShiftTask,
		|	NULL                           AS Performer,
		|	""IncorrectRCView""          AS ErrorCode
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		LEFT JOIN TTQueue AS Queue
		|		ON Operations.Stage = Queue.Stage
		|			AND Operations.Operation = Queue.Operation
		|			AND Operations.OperationID = Queue.OperationID
		|WHERE
		|	Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|	AND &SetRecords
		|	AND Operations.WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|	AND Queue.WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|	AND Operations.WorkCenterType <> Queue.WorkCenterType
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Operations.Stage                  AS Stage,
		|	Operations.Operation              AS Operation,
		|	Operations.OperationID AS OperationID,
		|	Queue.Description           AS NameOfTheOperation,
		|	NULL                           AS ShiftTask,
		|	NULL                           AS Performer,
		|	""ExceedingPlanQuantity""   AS ErrorCode
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		LEFT JOIN TTQueue AS Queue
		|		ON Operations.Stage = Queue.Stage
		|			AND Operations.Operation = Queue.Operation
		|			AND Operations.OperationID = Queue.OperationID
		|WHERE
		|	(Operations.Stage, Operations.Operation, Operations.OperationID) IN (&SelectionTextOfOperationStage)
		|	AND Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|
	 	|GROUP BY
	 	|	Operations.Stage,
	 	|	Operations.Operation,
	 	|	Operations.OperationID,
	 	|	Queue.Description
		|
		|HAVING
		|	SUM(Operations.Count) > (MAX(Queue.Scheduled) - MAX(Queue.CreatedOn))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	NULL                          AS Stage,
		|	Operations.Operation             AS Operation,
		|	NULL                          AS OperationID,
		|	Queue.Description          AS NameOfTheOperation,
		|	NULL                          AS ShiftTask,
		|	Teams.Ref                AS Performer,
		|	""OrganizationMismatch"" AS ErrorCode
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		LEFT JOIN TTQueue AS Queue
		|		ON Operations.Stage = Queue.Stage
		|			AND Operations.Operation = Queue.Operation
		|			AND Operations.OperationID = Queue.OperationID
		|		LEFT JOIN Catalog.Teams AS Teams
		|		ON Operations.Performer = Teams.Ref
		|		LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
		|		ON Operations.Stage = ProductionStage2_2.Ref
		|WHERE
		|	Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|	AND &SetRecords
		|	AND Operations.Performer REFS Catalog.Teams
		|	AND Operations.Performer <> VALUE(Catalog.Teams.EmptyRef)
		|	AND Teams.Organization <> ProductionStage2_2.Organization";
	
	Query = New Query;
	
	ConditionText = "";
	For Each Item In Filter Do
		If Not Item.Use Then
			Continue;
		EndIf;
		ConditionText = ConditionText	+ " AND Operations." + Item.Name + " = &" + Item.Name;
		Query.SetParameter(Item.Name, Item.Value);
	EndDo;
	
	SelectionTextOfOperationStage = "
		|	SELECT
		|		Operations.Stage,
		|		Operations.Operation,
		|		Operations.OperationID
		|	 FROM
		|		InformationRegister.OperationsToCreateShiftTasks AS Operations
		|	 WHERE
		|		Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|		AND &SetRecords";
	
	QueryText = StrReplace(QueryText, "&SelectionTextOfOperationStage", SelectionTextOfOperationStage);
	QueryText = StrReplace(QueryText, "AND &SetRecords",          ConditionText);
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageText = "";
		DataKey = Undefined;
		
		If Selection.ErrorCode = "TaskFailed" Then
			
			MessageText = StrTemplate(NStr("vi = 'Chưa kết chuyển chứng từ %1.';
											|ru = 'Документ %1 не проведен.';
											|en = 'Document %1 is not posted.'; fa = 'Document %1 is not posted.';
											|it = 'Documento%1 non registrato.';
											|pl = 'Dokument %1 nie zaksięgowany.';
											|tr = '%1 belgesi kaydedilmedi.'"), Selection.ShiftTask);
			DataKey = Selection.ShiftTask;
			
		ElsIf Selection.ErrorCode = "TaskStatusIsNotGenerated" Then
			
			MessageText = StrTemplate(NStr("vi = 'Chứng từ %1 không ở trạng thái ""Đã tạo"".';
											|ru = 'Документ %1 не находится в статусе ""Формируется"".';
											|en = 'Document %1 is not in the ""Generating"" status.'; fa = 'Document %1 is not in the ""Generating"" status.';
											|it = 'Il documento %1 non è nello stato ""In formazione"".';
											|pl = 'Dokument %1 nie posiada statusu ""Utworzony"".';
											|tr = '%1 belgesi ""Düzenleniyor"" durumunda değildir.'"), Selection.ShiftTask);
			DataKey = Selection.ShiftTask;
			
		ElsIf Selection.ErrorCode = "IncorrectRCView" Then
			
			MessageText = StrTemplate(NStr("vi = 'Thao tác %1 không được chỉ định cho nguồn lực sản xuất (dạng nguồn lực sản xuất) đã đặt.';
											|ru = 'Операция %1 не может быть назначена заданному РЦ (виду РЦ).';
											|en = 'The %1 operation cannot be assigned to the specified work center (work center type).'; fa = 'The %1 operation cannot be assigned to the specified work center (work center type).';
											|it = 'L''operazione %1 non può essere assegnat al centro di compensazione specificato';
											|pl = 'Operacji nie %1 można przypisać do określonego centrum pracy (typ CP).';
											|tr = '%1 işlemi, belirtilen iş merkezine (İM türüne) atanamaz.'"), Selection.NameOfTheOperation);
			
		ElsIf Selection.ErrorCode = "ExceedingPlanQuantity" Then
			
			MessageText = StrTemplate(NStr("vi = 'Giao dịch%1 %2 đã được chỉ định vượt quá số tiền dự kiến.';
											|ru = 'Операция %1 %2 назначена в количестве, превышающем запланированное.';
											|en = 'The %1 %2 operation is assigned in the quantity exceeding the planned one.'; fa = 'The %1 %2 operation is assigned in the quantity exceeding the planned one.';
											|it = 'L''operazione %1 %2 viene assegnata per una quantità superiore a quella pianificata.';
											|pl = 'Operacja %1 %2 przypisana w ilościach przekraczających planowane.';
											|tr = '%2 %1 işlemi, planlanandan daha büyük miktarda atandı.'"),
				Selection.NameOfTheOperation, Selection.Stage);
			
		ElsIf Selection.ErrorCode = "OrganizationMismatch" Then
			
			MessageText = StrTemplate(NStr("vi = 'Giao dịch %1 và nhóm %2 thuộc về các doanh nghiệp khác nhau.';
											|ru = 'Операция %1 и бригада %2 относятся к различным организациям.';
											|en = 'Operation %1 and work team %2 belong to different companies.'; fa = 'Operation %1 and work team %2 belong to different companies.';
											|it = 'L''operazione %1 e il team %2 appartengono a diverse organizzazioni.';
											|pl = 'Operacja %1 i zespół %2 należą do różnych firm.';
											|tr = '%1 işlemi ve %2 çalışma ekibi farklı iş yerlerine aittir.'"),
				Selection.NameOfTheOperation, Selection.Performer);
				
		EndIf;
		
		Common.MessageToUser(
				MessageText,
				DataKey,
				,
				, 
				Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
