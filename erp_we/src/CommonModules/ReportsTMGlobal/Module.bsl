
#Region Private

Procedure CheckBackgroundJobs() Export
	ParametersForCheckingBackgroundTasks = ReportsTMClientOverridable.ParametersForCheckingBackgroundTasks();
	If ParametersForCheckingBackgroundTasks.Interval < 15 Then
		ParametersForCheckingBackgroundTasks.Interval = ParametersForCheckingBackgroundTasks.Interval + 2;
	EndIf;
	
	KeysToRemoval = New Array;
	DetachIdleHandler("CheckBackgroundJobs");
	
	NameOfCustomerSettlementTask = ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob();
	NameOfSupplierTask = ARAPAllocationServerCall.NameOfBackgroundTaskForSettlementsWithSuppliers();
	
	For Each Job In ParametersForCheckingBackgroundTasks.Jobs Do 
		Result = ReportsTMServerCallOverridable.CheckBackgroundTask(Job.Key);
		If Result.CompletedSuccessfully1 Then
			If Job.Key = "BatchAccounting" Then
				FormsList = Job.Value;
				NotificationForms_ = NotificationForms_(Job.Key, FormsList);
				HandlerParameters = New Structure;
				HandlerParameters.Insert("Forms", NotificationForms_);
				FormsForProcessing = FormsForProcessing(NotificationForms_, FormsList);
				If FormsForProcessing.Count() > 0 Then
					HandlerParameters.Insert("RawForms", FormsForProcessing);
				EndIf;
				QueryText = NStr("vi = 'Tính toán của các lô. Thay đổi báo cáo?';
								|ru = 'Выполнен расчет партий. Переформировать отчет?';
								|en = 'Lots are calculated. Rebuild the report?'; fa = 'Lots are calculated. Rebuild the report?';
								|it = 'Eseguito il calcolo dei lotti. Riformare il report?';
								|pl = 'Zostało wykonane obliczenie partii. Sporządzić ponownie raport?';
								|tr = 'Lot mutabakatı gerçekleştirildi. Raporu yeniden oluştur?'");
				ShowQuestionToUser(QueryText, HandlerParameters);
			ElsIf Job.Key = NameOfCustomerSettlementTask Or Job.Key = NameOfSupplierTask
				Or Job.Key = "ARAPAccounting" Then
				FormsList = Job.Value;
				NotificationForms_ = NotificationForms_(Job.Key, Job.Value);
				HandlerParameters = New Structure;
				HandlerParameters.Insert("Forms", NotificationForms_);
				FormsForProcessing = FormsForProcessing(NotificationForms_, FormsList);
				If FormsForProcessing.Count() > 0 Then
					HandlerParameters.Insert("RawForms", FormsForProcessing);
				EndIf;
				QueryText = NStr("vi = 'Phân bổ các tính toán đã được hoàn thành. Thay đổi báo cáo?';
								|ru = 'Выполнено распределение расчетов. Переформировать отчет?';
								|en = 'The settlements are allocated. Rebuild the report?'; fa = 'The settlements are allocated. Rebuild the report?';
								|it = 'I calcoli sono distribuiti. Riformare il report?';
								|pl = 'Został wykonany podział obliczeń. Sporządzić ponownie raport?';
								|tr = 'Mutabakatların dağıtımı tamamlandı. Raporu yeniden oluştur?'");
				ShowQuestionToUser(QueryText, HandlerParameters);
			ElsIf Job.Key = "DocumentPostingInBudgeting" Then
				NotificationForms_ = NotificationForms_(Job.Key, Job.Value);
				HandlerParameters = New Structure;
				HandlerParameters.Insert("Forms", NotificationForms_);
				If NotificationForms_.Count() <> Job.Value.Forms.Count() Then
					RawForms = New Map;
					For Each KeyAndValue In Job.Value.Forms Do
						If Not KeyAndValue.Key.IsOpen() Then
							Continue;
						EndIf;
						If NotificationForms_.Find(KeyAndValue.Key) = Undefined Then
							RawForms.Insert(KeyAndValue.Key, KeyAndValue.Value);
						EndIf;
					EndDo;
					If RawForms.Count() Then
						HandlerParameters.Insert("RawForms", RawForms);
					EndIf;
				EndIf;
				If NotificationForms_.Count() Then
					QueryText = NStr("vi = 'Việc phản ánh các chứng từ trong ngân sách được hoàn thành. Lập lại báo cáo?';
									|ru = 'Выполнено отражение документов в бюджетировании. Переформировать отчет?';
									|en = 'Document has been recorded in budgeting. Rebuild the report?'; fa = 'Document has been recorded in budgeting. Rebuild the report?';
									|it = 'Reso conto dei documenti nel bilancio. Riformare il report?';
									|pl = 'Zostało wykonane odzwierciedlenie dokumentów do budżetowania. Sporządzić ponownie raport?';
									|tr = 'Bütçelemeye belgeler yansıtıldı. Raporu yeniden oluştur?'");
					Handler = New CallbackDescription("ReportFormAfterConfirmationOfReformulation",
						ReportsERPClientOverridable, HandlerParameters);
					ListOfResponses = New ValueList;
					ListOfResponses.Add(DialogReturnCode.Yes, NStr("vi = 'Lập lại báo cáo';
																	|ru = 'Переформировать';
																	|en = 'Rebuild'; fa = 'Rebuild';
																	|it = 'Riformare';
																	|pl = 'Rebuild';
																	|tr = 'Yeniden oluştur'"));
					ListOfResponses.Add(DialogReturnCode.No, NStr("vi = 'Để lại như cũ';
																	|ru = 'Оставить как есть';
																	|en = 'Leave as it is.'; fa = 'Leave as it is.';
																	|it = 'Lasciare come è';
																	|pl = 'Zostaw jak jest';
																	|tr = 'Olduğu gibi bırak'"));
					ShowQueryBox(Handler, QueryText, ListOfResponses);
				EndIf;
			ElsIf Job.Key = "ControlFlow_TasksForReflectingLimitsBasedOnBudgetingData" Then
				NotificationForms_ = NotificationForms_(Job.Key, Job.Value);
				HandlerParameters = New Structure;
				HandlerParameters.Insert("Forms", NotificationForms_);
				If NotificationForms_.Count() Then
					QueryText = NStr("vi = 'Đã đảo ngược dự phòng theo hạn mức. Lập lại báo cáo?';
									|ru = 'Выполнено сторнирование резервов по лимитам. Переформировать отчет?';
									|en = 'Limit reserves are reversed. Rerun the report?'; fa = 'Limit reserves are reversed. Rerun the report?';
									|it = 'Выполнено сторнирование резервов по лимитам. Переформировать отчет?';
									|pl = 'Limit reserves are reversed. Rerun the report?';
									|tr = 'Limit rezervlerinin tersine kaydı gerçekleştirildi. Rapor yeniden biçimlendirilsin mi?'");
					Handler = New CallbackDescription("ReportFormAfterConfirmationOfReformulation",
						ReportsERPClientOverridable, HandlerParameters);
					ListOfResponses = New ValueList;
					ListOfResponses.Add(DialogReturnCode.Yes, NStr("vi = 'Lập lại báo cáo';
																	|ru = 'Переформировать';
																	|en = 'Rebuild'; fa = 'Rebuild';
																	|it = 'Riformare';
																	|pl = 'Rebuild';
																	|tr = 'Yeniden oluştur'"));
					ListOfResponses.Add(DialogReturnCode.No, NStr("vi = 'Để lại như cũ';
																	|ru = 'Оставить как есть';
																	|en = 'Leave as it is.'; fa = 'Leave as it is.';
																	|it = 'Lasciare come è';
																	|pl = 'Zostaw jak jest';
																	|tr = 'Olduğu gibi bırak'"));
					ShowQueryBox(Handler, QueryText, ListOfResponses);
				EndIf;
			EndIf;
			KeysToRemoval.Add(Job.Key);
		ElsIf Result.StillRunning Then
			AttachIdleHandler("CheckBackgroundJobs", ParametersForCheckingBackgroundTasks.Interval, True);
			ThereAreTasksInProgress = True;
		ElsIf Result.DoneWithErrors Then
			EventLogClient.AddMessageForEventLog(Job.Key, "Error", Result.ErrorText,,True);
		EndIf;
	EndDo;
	For Each Var_Key In KeysToRemoval Do
		ParametersForCheckingBackgroundTasks.Jobs.Delete(Var_Key);
	EndDo;
EndProcedure

Procedure ShowQuestionToUser(QueryText, HandlerParameters)
	Handler = New CallbackDescription("ReportFormAfterConfirmationOfReformulation", ReportsTMClientOverridable, HandlerParameters);
	ListOfResponses = New ValueList;
	ListOfResponses.Add(DialogReturnCode.Yes, NStr("vi = 'Lập lại báo cáo';
													|ru = 'Переформировать';
													|en = 'Rebuild'; fa = 'Rebuild';
													|it = 'Riformare';
													|pl = 'Rebuild';
													|tr = 'Yeniden oluştur'"));
	ListOfResponses.Add(DialogReturnCode.No, NStr("vi = 'Để lại như cũ';
													|ru = 'Оставить как есть';
													|en = 'Leave as it is.'; fa = 'Leave as it is.';
													|it = 'Lasciare come è';
													|pl = 'Zostaw jak jest';
													|tr = 'Olduğu gibi bırak'"));
	ShowQueryBox(Handler, QueryText, ListOfResponses);
EndProcedure

Function FormsForProcessing(NotificationForms_, FormsList)
	ToProcessing = New Map;
	If NotificationForms_.Count() <> FormsList.Count() Then
		For Each FormData1 In FormsList Do
			If Not FormData1.Key.IsOpen() Then
				Continue;
			EndIf;
			If NotificationForms_.Find(FormData1.Key) = Undefined Then
				ToProcessing.Insert(FormData1.Key, FormData1.Value);
			EndIf;
		EndDo;
	EndIf;
	Return ToProcessing;
EndFunction

Function NotificationForms_(JobName, FormsList)
	
	If JobName = "BatchAccounting" Then
		NotificationForms_ = FormsReadyForNotification(FormsList);
	ElsIf JobName = "ARAPAccounting"
	 Or JobName = "SettlementsWithClients"
	 Or JobName = "SettlementsWithSuppliers" Then
		NotificationForms_ = FormsOfMutualSettlementsForNotification(FormsList);
	ElsIf JobName = "DocumentPostingInBudgeting"
		Or JobName = "ControlFlow_TasksForReflectingLimitsBasedOnBudgetingData" Then
		NotificationForms_ = BudgetingFormsForNotification(FormsList, JobName);
	Else
		NotificationForms_ = New Array;
	EndIf;
	
	Return NotificationForms_;
	
EndFunction

Function FormsReadyForNotification(FormsList)
	
	NotificationForms_ = New Array;
	
	For Each Form In FormsList Do
		
		If Not Form.Key.IsOpen() Then
			Continue;
		EndIf;
		
		If ReportsTMServerCallOverridable.BatchesUpdatedForReports(Form.Value) Then
			
			CalculationParameters = Form.Key.Report.SettingsComposer.UserSettings.AdditionalProperties;
			CalculationParameters.Insert("LotsAndCostCalculation", False);
			
			NotificationForms_.Add(Form.Key);
			
		EndIf;
		
	EndDo;
	
	Return NotificationForms_;
	
EndFunction

Function FormsOfMutualSettlementsForNotification(FormsList)
	NotificationForms_ = New Array();
	For Each Form In FormsList Do
		FormParameters = Form.Value;
		If TypeOf(FormParameters.ReadyForCalculation) = Type("Array") Then
			Analysts = FormParameters.ReadyForCalculation;
		Else
			Analysts = FormParameters.ReadyForCalculation.AccountingAnalyticsForPartners;
		EndIf;
		
		CalculationStart = ReportsTMServerCallOverridable.BeginningOfDistributionOfMutualSettlements(FormParameters.BorderOfMutualSettlements, 
			Analysts,
			FormParameters.CalculationName,
			FormParameters.JobNumber);
		If Not ValueIsFilled(CalculationStart) Then
			NotificationForms_.Add(Form.Key);
		EndIf;
	EndDo;
	Return NotificationForms_;
EndFunction


// Returns an array of forms for the notification.
// 
// Parameters:
// 	JobParameters - Structure -:
// 	 *Forms - Array of ClientApplicationForm - 
// 	 *Parameters - Structure -:
// 	  **BeginOfPeriod - Date -
// 	  **EndOfPeriod - Date -
// Returns:
// 	Array - LongDesc
Function BudgetingFormsForNotification(JobParameters, JobName)
	
	FormsList = JobParameters.Forms;
	NotificationForms_ = New Array();
	
	For Each Form In FormsList Do
		If Not Form.Key.IsOpen() Then
			Continue;
		EndIf;
		If JobName = "DocumentPostingInBudgeting" Then
			FormEntersInterval = False;
			If JobParameters.Parameters.BeginOfPeriod >= Form.Value.BeginOfPeriod
				And JobParameters.Parameters.BeginOfPeriod <= Form.Value.EndOfPeriod Then
				FormEntersInterval = True;
			EndIf;
			If JobParameters.Parameters.EndOfPeriod >= Form.Value.BeginOfPeriod
				And JobParameters.Parameters.EndOfPeriod <= Form.Value.EndOfPeriod Then
				FormEntersInterval = True;
			EndIf;
			If JobParameters.Parameters.BeginOfPeriod <= Form.Value.BeginOfPeriod
				And JobParameters.Parameters.EndOfPeriod >= Form.Value.EndOfPeriod Then
				FormEntersInterval = True;
			EndIf;
		Else
			FormEntersInterval = True;
		EndIf;
		If FormEntersInterval Then
			NotificationForms_.Add(Form.Key);
		EndIf;
	EndDo;
	
	Return NotificationForms_;
	
EndFunction

#EndRegion
