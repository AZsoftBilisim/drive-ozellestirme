#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Date = CurrentSessionDate();
	
	If TypeOf(FillingData) = Type("CatalogRef.BudgetingSteps") Then
		Attributes = New Structure();
		Attributes.Insert("BudgetingModel", "Owner");
		Attributes.Insert("Action", "Action");
		Attributes.Insert("Description", "Description");
		Attributes.Insert("SettingOfAction", "SettingOfAction");
		Attributes.Insert("MonitoringReportSettings", "MonitoringReportSettings");
		Attributes.Insert("TaskDetails1", "TaskDetails1");
		Attributes.Insert("BudgetingStep", "Ref");
		Attributes.Insert("Performer", "EmployeeResponsible");
		Attributes.Insert("Periodicity", "Parent.Periodicity");
		ValueOfBankingDetails = Common.ObjectAttributesValues(FillingData, Attributes);
		FillPropertyValues(ThisObject, ValueOfBankingDetails);
		Tasks.BudgetTask.SetTaskDuration(ThisObject, FillingData);
		If Not ValueIsFilled(Period) Then
			Period = WorkingWithClientServerPeriods.BeginningDateOfPeriod(CurrentSessionDate(), ValueOfBankingDetails.Periodicity);
		EndIf;
		AdditionalProperties.Insert("SettingOfAction", ValueOfBankingDetails.SettingOfAction.Get());
		AdditionalProperties.Insert("MonitoringReportSettings",
			ValueOfBankingDetails.MonitoringReportSettings.Get());
	EndIf;
	
	If Not ValueIsFilled(BudgetingModel) 
		And (TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BudgetingModel")) Then
		BudgetingModel = Catalogs.BudgetingModels.DefaultBudgetingModel();
	EndIf;
	
	TableOfApprovedDocuments =
		Tasks.BudgetTask.ApprovedDocumentsForProcessStep(Action, SettingOfAction.Get(), Period);
		
	ApprovedDocuments.Load(TableOfApprovedDocuments);
	
	Author = Users.AuthorizedUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var Errors;
	
	If EndOfDay(TaskDueDate) < Date Then
		ErrorText = NStr("vi = 'Thời hạn không thể ít hơn ngày hẹn';
						|ru = 'Срок не может быть меньше даты назначения';
						|en = 'Deadline cannot be earlier than the assignment date'; fa = 'Deadline cannot be earlier than the assignment date';
						|it = 'Il periodo non può essere antecedente alla data di assegnazione';
						|pl = 'Termin nie może być mniejszy niż data przeznaczenia';
						|tr = 'Bitiş tarihi atama tarihinden daha az olamaz'");
		CommonClientServer.AddUserError(
			Errors, "Object.TaskDueDate", ErrorText, "");
	EndIf;
	
	VerificationStage = ?(ValueIsFilled(BudgetingStepBasis), BudgetingStepBasis, BudgetingStep);
	If Common.ObjectAttributeValue(VerificationStage, "ExecuteAutomatically") = False Then
		CheckedAttributes.Add("Performer");
	EndIf;
	
	If Executed Then
		
		If ValueIsFilled(CompletionDate) And CompletionDate < Date Then
			ErrorText = NStr("vi = 'Ngày thực hiện không thể ít hơn ngày hẹn';
							|ru = 'Дата исполнения не может быть меньше даты назначения';
							|en = 'Completion date cannot be earlier than the assignment date'; fa = 'Completion date cannot be earlier than the assignment date';
							|it = 'La data di esecuzione non può essere antecedente alla data di assegnazione';
							|pl = 'Data wykonania nie może być mniejsza niż data przeznaczenia';
							|tr = 'Tamamlama tarihi atama tarihinde daha az olabilir'");
			CommonClientServer.AddUserError(
				Errors, "Object.CompletionDate", ErrorText, "");
		EndIf;
		
		OptionParameters_ = New Structure("BudgetingModel", BudgetingModel);
		UseBudgetConfirmation = GetFunctionalOption("UseBudgetConfirmation", OptionParameters_); 
		
		ThisIsRelatedTask = ValueIsFilled(MainTask_);
		SetPrivilegedMode(True);
		MainTaskIsAction = Common.ObjectAttributeValue(MainTask_, "Action");
		SetPrivilegedMode(False);
		
		If UseBudgetConfirmation And (Not ThisIsRelatedTask 
			Or MainTaskIsAction = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets) Then
			
			If DocumentsList.Count()
				And (Action = Enums.TypesOfBudgetingStepActions.PlanEntry
					Or Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
					Or Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules) Then
				DocumentsArray = DocumentsList.UnloadColumn("Document");
				DetailsOfDocuments = Common.ObjectsAttributesValues(DocumentsArray, "Status, Posted");
				For Each DocumentAttributes In DetailsOfDocuments Do
					If DocumentAttributes.Value.Status = Enums.PlanStatuses.UnderPreparation
						Or Not DocumentAttributes.Value.Posted Then
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr(
							"vi = 'Để thực hiện nhiệm vụ, cần kết chuyển chứng từ %1 ở trạng thái ""Cần phê duyệt"" hoặc ""Đã duyệt""';
							|ru = 'Для выполнения задачи документ %1 должен быть проведен в статусе ""На утверждении"" или ""Утвержден""';
							|en = 'To complete the task, the %1 document must be posted in the ""Pending confirmation"" or ""Confirmed"" status'; fa = 'To complete the task, the %1 document must be posted in the ""Pending confirmation"" or ""Confirmed"" status';
							|it = 'Для выполнения задачи документ %1 должен быть проведен в статусе ""На утверждении"" или ""Утвержден""';
							|pl = 'To complete the task, the %1 document must be posted in the ""Pending confirmation"" or ""Confirmed"" status';
							|tr = 'Görevi gerçekleştirmek için %1 belgesi ""Onay bekliyor"" durumunda yürütülmesi gerekmektedir'"),
							DocumentAttributes.Key);
						CommonClientServer.AddUserError(
							Errors, "",
							ErrorText, "");
					EndIf;
				EndDo;
				
			ElsIf Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets Then
				
				Query = New Query;
				Query.Text = 
				"SELECT
				|	ApprovedDocuments.LineNumber,
				|	ApprovedDocuments.Document,
				|	ApprovedDocuments.BudgetingStep
				|INTO ApprovedDocuments
				|FROM
				|	&ApprovedDocuments AS ApprovedDocuments
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ApprovedDocuments.LineNumber AS LineNumber,
				|	ApprovedDocuments.Document,
				|	CASE
				|		WHEN NOT BudgetEntryForm.Ref IS NULL 
				|			THEN BudgetEntryForm.Status
				|		WHEN NOT RegistrarOfBudgetTurnover.Ref IS NULL 
				|			THEN RegistrarOfBudgetTurnover.Status
				|		WHEN NOT PurchasePlan.Ref IS NULL 
				|			THEN PurchasePlan.Status
				|		WHEN NOT SalesPlan.Ref IS NULL 
				|			THEN SalesPlan.Status
				|		WHEN NOT ProductionPlan.Ref IS NULL 
				|			THEN ProductionPlan.Status
				|		WHEN NOT AssemblyDisassemblyPlan.Ref IS NULL 
				|			THEN AssemblyDisassemblyPlan.Status
				|		WHEN NOT InventoryConsumptionPlan.Ref IS NULL 
				|			THEN InventoryConsumptionPlan.Status
				|		WHEN NOT PlanOfGoodsStock.Ref IS NULL 
				|			THEN PlanOfGoodsStock.Status
				|	END AS Status,
				|	CASE
				|		WHEN NOT BudgetEntryForm.Ref IS NULL 
				|			THEN BudgetEntryForm.Posted
				|		WHEN NOT RegistrarOfBudgetTurnover.Ref IS NULL 
				|			THEN RegistrarOfBudgetTurnover.Posted
				|		WHEN NOT PurchasePlan.Ref IS NULL 
				|			THEN PurchasePlan.Posted
				|		WHEN NOT SalesPlan.Ref IS NULL 
				|			THEN SalesPlan.Posted
				|		WHEN NOT ProductionPlan.Ref IS NULL 
				|			THEN ProductionPlan.Posted
				|		WHEN NOT AssemblyDisassemblyPlan.Ref IS NULL 
				|			THEN AssemblyDisassemblyPlan.Posted
				|		WHEN NOT InventoryConsumptionPlan.Ref IS NULL 
				|			THEN InventoryConsumptionPlan.Posted
				|		WHEN NOT PlanOfGoodsStock.Ref IS NULL 
				|			THEN PlanOfGoodsStock.Posted
				|	END AS Posted
				|FROM
				|	ApprovedDocuments AS ApprovedDocuments
				|		LEFT JOIN Catalog.BudgetingSteps AS BudgetingSteps
				|		ON ApprovedDocuments.BudgetingStep = BudgetingSteps.Ref
				|		LEFT JOIN Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
				|		ON ApprovedDocuments.Document = RegistrarOfBudgetTurnover.Ref
				|		LEFT JOIN Document.BudgetEntryForm AS BudgetEntryForm
				|		ON ApprovedDocuments.Document = BudgetEntryForm.Ref
				|		LEFT JOIN Document.PurchasePlan AS PurchasePlan
				|		ON ApprovedDocuments.Document = PurchasePlan.Ref
				|		LEFT JOIN Document.SalesPlan AS SalesPlan
				|		ON ApprovedDocuments.Document = SalesPlan.Ref
				|		LEFT JOIN Document.ProductionPlan AS ProductionPlan
				|		ON ApprovedDocuments.Document = ProductionPlan.Ref
				|		LEFT JOIN Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyPlan
				|		ON ApprovedDocuments.Document = AssemblyDisassemblyPlan.Ref
				|		LEFT JOIN Document.InventoryConsumptionPlan AS InventoryConsumptionPlan
				|		ON ApprovedDocuments.Document = InventoryConsumptionPlan.Ref
				|		LEFT JOIN Document.PlanOfGoodsStock AS PlanOfGoodsStock
				|		ON ApprovedDocuments.Document = PlanOfGoodsStock.Ref
				|WHERE
				|	(NOT CASE
				|					WHEN NOT BudgetEntryForm.Ref IS NULL 
				|						THEN BudgetEntryForm.Status
				|					WHEN NOT RegistrarOfBudgetTurnover.Ref IS NULL 
				|						THEN RegistrarOfBudgetTurnover.Status
				|					WHEN NOT PurchasePlan.Ref IS NULL 
				|						THEN PurchasePlan.Status
				|					WHEN NOT SalesPlan.Ref IS NULL 
				|						THEN SalesPlan.Status
				|					WHEN NOT ProductionPlan.Ref IS NULL 
				|						THEN ProductionPlan.Status
				|					WHEN NOT AssemblyDisassemblyPlan.Ref IS NULL 
				|						THEN AssemblyDisassemblyPlan.Status
				|					WHEN NOT InventoryConsumptionPlan.Ref IS NULL 
				|						THEN InventoryConsumptionPlan.Status
				|					WHEN NOT PlanOfGoodsStock.Ref IS NULL 
				|						THEN PlanOfGoodsStock.Status
				|				END IN (VALUE(Enum.PlanStatuses.Upholded), VALUE(Enum.PlanStatuses.RolledBack_))
				|			OR CASE
				|				WHEN NOT BudgetEntryForm.Ref IS NULL 
				|					THEN BudgetEntryForm.Posted
				|				WHEN NOT PurchasePlan.Ref IS NULL 
				|					THEN PurchasePlan.Posted
				|				WHEN NOT RegistrarOfBudgetTurnover.Ref IS NULL 
				|					THEN RegistrarOfBudgetTurnover.Posted
				|				WHEN NOT SalesPlan.Ref IS NULL 
				|					THEN SalesPlan.Posted
				|				WHEN NOT ProductionPlan.Ref IS NULL 
				|					THEN ProductionPlan.Posted
				|				WHEN NOT AssemblyDisassemblyPlan.Ref IS NULL 
				|					THEN AssemblyDisassemblyPlan.Posted
				|				WHEN NOT InventoryConsumptionPlan.Ref IS NULL 
				|					THEN InventoryConsumptionPlan.Posted
				|				WHEN NOT PlanOfGoodsStock.Ref IS NULL 
				|					THEN PlanOfGoodsStock.Posted
				|			END = FALSE)
				|
				|ORDER BY
				|	LineNumber";
				Query.SetParameter("ApprovedDocuments", ApprovedDocuments.Unload());
				Query.SetParameter("StatusConfirmed", Enums.PlanStatuses.Upholded);
				
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Để thực hiện nhiệm vụ, chứng từ %1 phải kết chuyển với trạng thái ""Đã duyệt"" hoặc ""Đã hủy bỏ""';
							|ru = 'Для выполнения задачи необходимо документ %1 провести в статусах ""Утвержден"" или ""Отклонен""';
							|en = 'To complete the task, the %1 document should be posted in the ""Confirmed"" or ""Rejected"" statuses'; fa = 'To complete the task, the %1 document should be posted in the ""Confirmed"" or ""Rejected"" statuses';
							|it = 'Per effettuare l''obiettivo è necessario pubblicare il documento %1 con gli stati ""Approvato"" oppure ""Respinto""';
							|pl = 'Aby ukończyć zadania, należy dokument %1 zaksięgować w statusach ""Zatwierdzony"" lub ""Odrzucony""';
							|tr = 'Görevi gerçekleştirmek için belge%1 ""Onaylandı"" veya ""İptal edildi"" durumunda kaydetmek şart'"),
						Selection.Document);
						
					ErrorField = "Object." 
						+ CommonClientServer.PathToTabularSection(
						"ApprovedDocuments", Selection.LineNumber, "Document");
					
					CommonClientServer.AddUserError(Errors, ErrorField, MessageText, "");
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CompletionDate) And Executed Then
		CompletionDate = CurrentSessionDate();
	EndIf;
	
	If ForDocumentCreation And Not DocumentsList.Count() = 0 Then
		If Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
			Or Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
			Or Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
			Attributes = New Structure("Periodicity", "Parent.Periodicity");
			Attributes = Common.ObjectAttributesValues(BudgetingStep, Attributes);
			Periodicity = Attributes.Periodicity;
			
			BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(Period, Periodicity);
			EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(Period, Periodicity);
			Setting = SettingOfAction.Get();
			Document = DocumentsList.UnloadColumn("Document");
			BudgetEntryTree = Tasks.BudgetTask.ParametersForEnteringBudgetsByActionSettings(Setting, Action,
				BeginOfPeriod,
				EndOfPeriod,
				Periodicity,
				Document,
				False);
			
			ThereAreDocumentsNotCreated = False;
			For Each BudgetViewLine_ In BudgetEntryTree.Rows Do
				For Each PeriodString_ In BudgetViewLine_.Rows Do
					For Each AnalyticsLine_ In PeriodString_.Rows Do
						If Not ValueIsFilled(AnalyticsLine_.Document) Then
							ThereAreDocumentsNotCreated = True;
							Break;
						EndIf;
					EndDo;
					If ThereAreDocumentsNotCreated Then
						Break;
					EndIf;
				EndDo;
				If ThereAreDocumentsNotCreated Then
					Break;
				EndIf;
			EndDo; 
			
			ForDocumentCreation = ThereAreDocumentsNotCreated;
		Else 
			ForDocumentCreation = DocumentsList.Count()=0;
		EndIf;
	EndIf;
	If ForDocumentCreation And Executed And ValueIsFilled(BudgetingProcess) Then
		Status = Common.ObjectAttributeValue(BudgetingProcess, "Status");
		If Status = Enums.StatusesOfBudgetingProcess.RolledBack_ Then
			ForDocumentCreation = False;
		EndIf;
	EndIf;
	If ForDocumentCreation And DeletionMark Then
		ForDocumentCreation = False;
	EndIf;
	If Not ForDocumentCreation And Not Executed Then
		VerificationStage = ?(ValueIsFilled(BudgetingStepBasis), BudgetingStepBasis, BudgetingStep);
		ExecuteAutomatically = Common.ObjectAttributeValue(VerificationStage, "ExecuteAutomatically");
		If ExecuteAutomatically Then
			Executed = True;
		EndIf;
		
	EndIf;
	
	If GetFunctionalOption("UseNotificationsForBudgetingTasks")
		And Ref.IsEmpty() Then
		AdditionalProperties.Insert("CreateAlertWhenTaskArrives", True);
	EndIf;
	
	If Not AdditionalProperties.Property("TaskGenerationMode") Then
		
		EditingBudgetTasksOutsideProcesses = Users.RolesAvailable("EditingBudgetTasksOutsideProcesses")
			Or Users.IsFullUser(, , True);
		
		If Not EditingBudgetTasksOutsideProcesses Then
			ErrorText = "";
			If Not ValueIsFilled(MainTask_) And (Not ValueIsFilled(Ref) Or Performer <> Users.CurrentUser()  
				Or Performer <> Common.ObjectAttributeValue(Ref, "Performer") ) Then
				ErrorText = NStr("vi = 'Là một phần của quy trình ngân sách, cho phép tạo/thay đổi chỉ nhiệm vụ liên quan.';
								|ru = 'В рамках бюджетного процесса разрешено создавать/изменять только связанные задачи.';
								|en = 'You can create/change only linked tasks within the budget process.'; fa = 'You can create/change only linked tasks within the budget process.';
								|it = 'Nel processo di budget è consentito creare/modificare solo gli obiettivi correlati.';
								|pl = 'W ramach procesu budżetowego dozwolone jest utworzenie/zmiana tylko powiązanych zadań.';
								|tr = 'Bütçe süreci sınırları içinde sadece ilgili görevleri oluşturmaya/değiştirmeye izin veriliyor.'");
			ElsIf ValueIsFilled(MainTask_) And Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm 
				And (Not ValueIsFilled(Ref) Or Performer <> Users.CurrentUser()  
					Or Performer <> Common.ObjectAttributeValue(Ref, "Performer") ) Then
				ErrorText = NStr("vi = 'Là một phần của quy trình ngân sách, không được phép tạo / sửa đổi các nhiệm vụ để nhập ngân sách.';
								|ru = 'В рамках бюджетного процесса запрещено создавать/изменять задачи на ввод бюджета.';
								|en = 'You cannot create/change budget input tasks within the budget process.'; fa = 'You cannot create/change budget input tasks within the budget process.';
								|it = 'Nel processo di budget non è consentito creare/modificare solo gli obiettivi di inserimento del budget.';
								|pl = 'W ramach procesu budżetowego zabrania się utworzenia/zmiany zadań dla wprowadzenia budżetowego.';
								|tr = 'Bütçe süreci sınırlarında görevi bütçe girişine oluşturmak/değiştirmek yasaktır.'");
			EndIf;
			If ValueIsFilled(ErrorText) Then
				CommonClientServer.MessageToUser(ErrorText, ThisObject, , , Cancel);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Executed And Not DeletionMark
		And Not AdditionalProperties.Property("IgnoreFormationOfBudgetTasks") Then
		JobParameters = New Array();
		JobParameters.Add(BudgetingModel);
		JobParameters.Add(BudgetingProcess);
		BackgroundJobs.Execute("BudgetingServer.BudgetTasksGeneration",JobParameters);
	EndIf;
	
	If AdditionalProperties.Property("CreateAlertWhenTaskArrives") Then
		BackgroundJobs.Execute(Metadata.ScheduledJobs.GenerateNotificationsForBudgetTasks.MethodName);
	ElsIf Executed Or DeletionMark Then
		RecordSet = InformationRegisters.NotificationsSentByBudgetTasks.CreateRecordSet();
		RecordSet.Filter.BudgetTask.Set(Ref);
		RecordSet.Write();
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	CompletionDate = Undefined;
	
EndProcedure

#EndRegion

#EndIf