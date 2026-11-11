
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.GroupPages.CurrentPage = Items.PageProcess;
	Interval = 1;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_StartTransition", 0.1, True);
	AttachIdleHandler("Attachable_CheckTaskCompletion", Interval, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LabelCompletionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "EventLog" Then
		DefaultLanguageCode = CommonClient.DefaultLanguageCode();
		LogEvents = New Array;
		LogEvents.Add(NStr("vi = 'Bao gồm các khoản thanh toán trực tuyến với các đối tác.';
							|ru = 'Включение онлайн взаиморасчетов с партнерами.';
							|en = 'Enable online mutual settlements with partners.'; fa = 'Enable online mutual settlements with partners.';
							|it = 'Attivazione online dei conti reciproci con i partner.';
							|pl = 'Włączenie online rozliczeń wzajemnych z partnerami.';
							|tr = 'İş ortakları ile çevrim içi mutabakatların etkinleştirilmesi.'", DefaultLanguageCode));
		LogEvents.Add(NStr("vi = 'Bao gồm các khoản thanh toán trực tuyến với các đối tác. Không thể điền đăng ký chuyển.';
							|ru = 'Включение онлайн взаиморасчетов с партнерами. Не удалось заполнить регистр перехода.';
							|en = 'Enabling online settlements with partners. Cannot fill in transfer register.'; fa = 'Enabling online settlements with partners. Cannot fill in transfer register.';
							|it = 'Attivazione di pagamenti reciproci online con i partner. Non è stato possibile compilare il registro di transizione.';
							|pl = 'Włączenie rozliczeń wzajemnych online z partnerami. Nie udało się wypełnić rejestr przejścia.';
							|tr = 'İş ortakları ile çevrim içi mutabakatların etkinleştirilmesi. Transfer kaydı doldurulamadı.'", DefaultLanguageCode));
		LogEvents.Add(NStr("vi = 'Bao gồm các khoản thanh toán trực tuyến với các đối tác. Công việc theo luồng.';
							|ru = 'Включение онлайн взаиморасчетов с партнерами. Работа потока.';
							|en = 'Enable online settlements with partners. Flow work.'; fa = 'Enable online settlements with partners. Flow work.';
							|it = 'Attivazione di pagamenti reciproci con i partner online. Lavoro del flusso.';
							|pl = 'Włączenie rozliczeń wzajemnych online z partnerami. Robota przepływu.';
							|tr = 'İş ortakları ile çevrim içi mutabakatların etkinleştirilmesi. Akış işi.'", DefaultLanguageCode));
		LogEvents.Add(NStr("vi = 'Bao gồm các khoản thanh toán trực tuyến với các đối tác. Giai đoạn 2.';
							|ru = 'Включение онлайн взаиморасчетов с партнерами. Этап 2.';
							|en = 'Enabling online settlements with partners. Stage 2.'; fa = 'Enabling online settlements with partners. Stage 2.';
							|it = 'Attivazione online di pagamenti reciproci con i partner. Fase 2.';
							|pl = 'Włączenie online rozliczeń wzajemnych z partnerami. Etap 2.';
							|tr = 'İş ortakları ile çevrim içi mutabakatların etkinleştirilmesi. Aşama 2.'", DefaultLanguageCode));
		Filter = New Structure;
		Filter.Insert("EventLogEvent", LogEvents);
		Filter.Insert("Level", "Error");
		Filter.Insert("StartDate", BegOfDay(CommonClient.SessionDate()));
		Filter.Insert("EndDate", CommonClient.SessionDate());
		OpenForm("DataProcessor.EventLog.Form", Filter);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CancelCommand(Command)
	
	CancelAndClose();
	
EndProcedure

&AtClient
Procedure ContactTechSupport(Command)
	
	Return; // no processing required
	
EndProcedure

#EndRegion

#Region Private 

&AtClient
Procedure Attachable_StartTransition()
	
	StartTransitionOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_CheckTaskCompletion()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	InformationRecords = RefreshProgressBar();
	If InformationRecords.Job.Status = "Running" Then
		Interval = Interval * 1.2;
		If Interval > 15 Then
			Interval = 15;
		EndIf;
		AttachIdleHandler("Attachable_CheckTaskCompletion", Interval, True);
	Else
		FillCompletionRegistersOnServer();
	EndIf;

EndProcedure

&AtServer
Procedure StartTransitionOnServer()
	
	ProcedureName = "OnlineARAPAccountingServer.FillRegistersWhenEnablingNewArchitecture";
	ProcedureParameters = New Array;
	ProcedureParameters.Add(New Structure);
	ProcedureParameters.Add(UUID);
	Description = NStr("vi = 'Tự động chuyển sang hạch toán công nợ trực tuyến';
						|ru = 'Автоматический переход на онлайн взаиморасчеты';
						|en = 'Automatic switching to online settlements'; fa = 'Automatic switching to online settlements';
						|it = 'Passaggio automatico a pagamenti reciproci online';
						|pl = 'Automatyczne przejście do rozliczeń wzajemnych online';
						|tr = 'Çevrim için mutabakatlara otomatik geçiş'");
	Var_Key = New UUID;
	Job = BackgroundJobs.Execute(ProcedureName, ProcedureParameters, Var_Key, Description);
	JobID = Job.UUID;
	
EndProcedure

&AtClient
Function RefreshProgressBar()
	
	ExecutionTime = UpdateProgressInformation(JobID);
	If ExecutionTime.Total > 0 Then
		Items.Indicator.MaxValue = ExecutionTime.Total;
		Indicator = ExecutionTime.Processed;
		Items.Indicator.Visible = True;
	EndIf;
	Return ExecutionTime;
	
EndFunction

&AtServerNoContext
Function UpdateProgressInformation(JobID)
	
	TotalToTransfer = 0;
	Filter = New Structure("ObjectKey,SettingsKey", "TransitionToNewSettlementArchitecture", "TotalToTransfer");
	Setting = CommonSettingsStorage.Select(Filter);
	If Setting.Next() Then
		TotalToTransfer = Setting.Settings;
	EndIf;
	
	QueryText = 
	"SELECT
	|	""NotProcessedItems"" AS Description,
	|	COUNT(JobsForAllocatingARAP.ARAPObject) AS Total
	|FROM
	|	InformationRegister.JobsForAllocatingARAP AS JobsForAllocatingARAP
	|
	|UNION ALL
	|
	|SELECT
	|	""AdditionalEntries"" AS Description,
	|	COUNT(JobsForAllocatingARAP.ARAPObject)
	|FROM
	|	InformationRegister.JobsForAllocatingARAP AS JobsForAllocatingARAP
	|WHERE
	|	JobsForAllocatingARAP.Document <> UNDEFINED";
	Query = New Query(QueryText);
	
	RegisterEntries = Query.Execute().Unload().UnloadColumn("Total");
	NotProcessedItems = RegisterEntries[0];
	AdditionalEntries = RegisterEntries[1];
	
	TotalToTransfer = TotalToTransfer + AdditionalEntries;
	Processed = ?(NotProcessedItems = 0, 0, TotalToTransfer - NotProcessedItems);
	Result = New Structure("Total,Processed", TotalToTransfer, Processed);
	
	Job = BackgroundJobs.FindByUUID(JobID);
	LongDesc = New Structure("Status");
	If Job <> Undefined Then
		LongDesc = New Structure;
		Status = "Running";
		If Job.State = BackgroundJobState.Failed Then
			Status = "Error";
		ElsIf Job.State = BackgroundJobState.Completed Then
			Status = "Completed2";
		EndIf;
		LongDesc.Insert("Status", Status);
		If Status = "Error" And Job.ErrorInfo <> Undefined Then
			LongDesc.BriefErrorDescription = BriefErrorDescription(Job.ErrorInfo);
			LongDesc.DetailErrorDescription = DetailErrorDescription(Job.ErrorInfo);
		EndIf;
	EndIf; 
	Result.Insert("Job", LongDesc);
	Return Result;
	
EndFunction

&AtClient
Procedure CancelAndClose()
	
	CancelJobExecution();
	Close();
	
EndProcedure

&AtServer
Procedure CancelJobExecution()
	
	If ValueIsFilled(JobID) Then
		Job = BackgroundJobs.FindByUUID(JobID);
		If Job = Undefined	Or Job.State <> BackgroundJobState.Active Then
			Return;
		EndIf;
		
		Try
			Job.Cancel();
		Except
			// Perhaps the task has just ended at this moment and there is no error.
			WriteLogEvent(NStr("vi = 'Giao dịch kéo dài. Đã hủy thực hiện nhiệm vụ nền';
								|ru = 'Длительные операции. Отмена выполнения фонового задания';
								|en = 'Long-running operations. Cancel background job'; fa = 'Long-running operations. Cancel background job';
								|it = 'Operazioni a lungo termine. Annullamento del compito in background';
								|pl = 'Operacje długotrwałe. Anulowanie wykonywania zadania w tle';
								|tr = 'Uzun işlemler. Arka plan işi gerçekleştirilmesinin iptali'", Common.DefaultLanguageCode()),
				EventLogLevel.Information, , , BriefErrorDescription(ErrorInfo()));
		EndTry;
		JobID = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCompletionRegistersOnServer()
	
	Items.FormCancel.Title = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Close';
									|tr = 'Kapat'");
	If Not Constants.NewOnlineARAPAccounting.Get() Then
		Items.InfoDecoration.Picture = PictureLib.Error32;
		
		RowsArray = New Array;
		RowsArray.Add(NStr("vi = 'Trong quá trình chuyển đổi đã xảy ra lỗi.
		|Để phân tích và khắc phục nguyên nhân lỗi
		|vui lòng liên hệ với bộ phận hỗ trợ kỹ thuật.';
		|ru = 'В процессе перехода возникли ошибки.
		|Для расследования и устранения причин возникновения ошибок
		|обратитесь пожалуйста в службу технической поддержки.';
		|en = 'Errors occurred during switching.
		|Contact support 
		|to investigate and troubleshoot errors.'; fa = 'Errors occurred during switching.
		|Contact support 
		|to investigate and troubleshoot errors.';
		|it = 'Durante il passaggio si sono verificati errori.
		| Per individuare ed eliminare le cause degli errori
		|rivolgersi all''assistenza tecnica.';
		|pl = 'W procesie przejścia powstali błędy.
		|W celu zbadania i usunięcia przyczyn powstania błędów
		|zwróć się do służby wsparcia technicznego.';
		|tr = 'Geçiş sürecinde hatalar meydana geldi.
		|Hataların nedenlerini araştırmak ve ortadan kaldırmak için
		|lütfen teknik destekle iletişime geçin.'") + Chars.LF);
		HyperlinkText = NStr("vi = 'xem nhật ký sự kiện';
							|ru = 'см. журнал регистрации';
							|en = 'see event log'; fa = 'see event log';
							|it = 'vedi il protocollo';
							|pl = 'zob. dziennik rejestracji';
							|tr = 'olay günlüğü bakın'");
		HyperlinkString = New FormattedString(
			HyperlinkText, 
	    	, 
			StyleColors.ButtonTextColor, ,
			"EventLog");
		RowsArray.Add(HyperlinkString);
		Items.LabelCompletion.Title = New FormattedString(RowsArray);
		Constants.DoNotAskAboutSwitchingToOnlineARAPAccounting.Set(True);
	EndIf;
	Items.GroupPages.CurrentPage = Items.PageCompletion;
	
EndProcedure

#EndRegion