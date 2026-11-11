
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Ref = Parameters.Ref;
	
	Query = New Query(
		"SELECT
		|	SUM(ISNULL(CASE
		|			WHEN ProductionOperation2_2.Status = VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
		|				THEN 1
		|			ELSE 0
		|		END, 0)) AS CreatedOn_,
		|	SUM(ISNULL(CASE
		|			WHEN ProductionOperation2_2.Status = VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
		|				THEN 0
		|			ELSE 1
		|		END, 0)) AS Running
		|FROM
		|	Document.ProductionOperation2_2 AS ProductionOperation2_2
		|WHERE
		|	ProductionOperation2_2.Posted
		|	AND ProductionOperation2_2.ShiftTask = &ShiftTask
		|	AND ProductionOperation2_2.Status IN (VALUE(Enum.ProductionOperationStatuses.CreatedOn_), VALUE(Enum.ProductionOperationStatuses.Running))");
	Query.SetParameter("ShiftTask", Ref);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If Selection.CreatedOn_ > 0 Then
			Items.InTheCreatedStatus.Title = StrTemplate(
				NStr("vi = 'Giao dịch trong Trạng thái đã tạo: %1';
					|ru = 'Операций в статусе ""Создана"": %1';
					|en = 'Operations in the Created status: %1'; fa = 'Operations in the Created status: %1';
					|it = 'Operazioni nello stato ""Creata"": %1';
					|pl = 'Operacji ze statusem ""Utworzona"": %1';
					|tr = '""Oluşturuldu"" durumundaki işlemler: %1'"),
				Selection.CreatedOn_);
			CreatedSetStatus = 1;
		Else
			Items.InTheCreatedStatus.Visible = False;
			Items.GroupStatusCreated.Visible = False;
		EndIf;
		
		If Selection.Running > 0 Then
			Items.InTheStatusInProgress.Title = StrTemplate(
				NStr("vi = 'Giao dịch trong trạng thái ""Đang thực hiện"": %1';
					|ru = 'Операций в статусе ""Выполняется"": %1';
					|en = 'Operations in the ""In progress"" status: %1'; fa = 'Operations in the ""In progress"" status: %1';
					|it = 'Operazioni nello stato ""In esecuzione"": %1';
					|pl = 'Operacji ze statusem ""Trwa wykonanie"": %1';
					|tr = '""Gerçekleştiriliyor"" durumundaki işlemler: %1'"),
				Selection.Running);
		Else
			Items.InTheStatusInProgress.Visible = False;
			Items.GroupStatusInProgress.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Cancel = False;
	
	Try
		
		SetStatusOnServer(Cancel);
		
	Except
		
		Cancel = True;
		
	    ShowMessageBox(,
			NStr("vi = 'Các hoạt động không thể được hoàn thành do:';
				|ru = 'Операция не может быть выполнена по причине:';
				|en = 'Cannot execute the operation. Reason:'; fa = 'Cannot execute the operation. Reason:';
				|it = 'L''operazione non può essere eseguita a causa di:';
				|pl = 'Operacja nie może być wykonana z powodu:';
				|tr = 'İşlem şu nedenden dolayı gerçekleştirilemez:'")
			+ Chars.LF
			+ BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
	If Not Cancel Then
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetStatusOnServer(Cancel)
	
	BeginTransaction();
	Try
		
		Query = New Query(
			"SELECT
			|	ProductionOperation2_2.Ref AS Ref
			|FROM
			|	Document.ProductionOperation2_2 AS ProductionOperation2_2
			|WHERE
			|	ProductionOperation2_2.Posted
			|	AND ProductionOperation2_2.ShiftTask = &ShiftTask
			|	AND ProductionOperation2_2.Status = VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ProductionOperation2_2.Ref AS Ref
			|FROM
			|	Document.ProductionOperation2_2 AS ProductionOperation2_2
			|WHERE
			|	ProductionOperation2_2.Posted
			|	AND ProductionOperation2_2.ShiftTask = &ShiftTask
			|	AND ProductionOperation2_2.Status = VALUE(Enum.ProductionOperationStatuses.Running)");
		Query.SetParameter("ShiftTask", Ref);
		
		ResultsArray = Query.ExecuteBatch();
		
		If Not ResultsArray[0].IsEmpty() Then
			
			References = ResultsArray[0].Unload().UnloadColumn("Ref");
			
			ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
				References,
				?(CreatedSetStatus = 0, "Executed", "NotExecuted"));
			
			If ProcessedItemsCount <> References.Count() Then
				Cancel = True;
			EndIf;
			
		EndIf;
		
		If Not ResultsArray[1].IsEmpty() Then
			
			References = ResultsArray[1].Unload().UnloadColumn("Ref");
			
			ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
				References,
				?(HowToSetStatus = 0, "Executed", "NotExecuted"));
			
			If ProcessedItemsCount <> References.Count() Then
				Cancel = True;
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Ca làm việc';
				|ru = 'Сменные задания';
				|en = 'Shift tasks'; fa = 'وظایف شیفتی';
				|it = 'Task del turno';
				|pl = 'Zadania zmiany';
				|tr = 'Vardiyalı görevler'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
			
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion
