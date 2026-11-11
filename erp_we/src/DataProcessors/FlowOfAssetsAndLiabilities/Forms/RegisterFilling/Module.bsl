#Region Variables

&AtClient
Var IdleHandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("NotRecordRegisteredRecords_") Then
		DataProcessors.FlowOfAssetsAndLiabilities.BalanceRegisters();
		NotRecordRegisteredRecords_ = Parameters.NotRecordRegisteredRecords_;
		Items.TheLabelIsBeingFilledIn.Title = NStr("vi = 'Đang kiểm tra';
													|ru = 'Выполняется тестирование';
													|en = 'Testing'; fa = 'آزمون';
													|it = 'Test in corso';
													|pl = 'Trwa testowanie';
													|tr = 'Test yapılıyor'") + "...";
	EndIf;
	
	Items.FormPages.CurrentPage = Items.FillInRegisters;
	UpdateCompleted_ = Constants.DeferredUpdateCompletedSuccessfully.Get();
	If Not UpdateCompleted_ Then
		Items.FormPages.CurrentPage = Items.CannotFillIn;
	EndIf;
	
	InformationRecords = Constants.IBUpdateInfo.Get().Get();
	If TypeOf(InformationRecords) = Type("Structure") And InformationRecords.Property("FillingInAssetsLiabilities") Then
		Process_ = InformationRecords.FillingInAssetsLiabilities;
		If Users.CurrentUser() <> Process_.User Then
			Items.FormPages.CurrentPage = Items.CannotFillIn;
			Items.Decoration1.Picture = PictureLib.Warning32;
			Template = NStr("vi = 'Đang tạo biến động trong bảng cân đối kế toán.
					|Bắt đầu tạo %1 %2.';
					|ru = 'Выполняется формирование движений управленческого баланса.
					|Формирование запустил %1 %2.';
					|en = 'Generating balance sheet statement movements. 
					|%1 %2 started generation.'; fa = 'Generating balance sheet statement movements. 
					|%1 %2 started generation.';
					|it = 'In corso la generazione dei movimenti di bilancio gestionale.
					|La generazione è stata avviata da %1 %2.';
					|pl = 'Odbywa się kształtowanie ruchów zarządczej równowagi.
					|Kształtowanie uruchomił %1 %2.';
					|tr = 'Yönetim muhasebesi bakiyesi hareketlerinin oluşumu gerçekleştirilir.
					|Oluşturma başlatıldı %1 %2.'");
			Items.ReasonForRefusalToFillInTheForm.Title = StrTemplate(Template, Process_.User, Process_.StartTime);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetInterfaceChanges();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	If Items.FormPages.CurrentPage = Items.ResultPage Then
		
		Close(True);
		
	Else
		
		Items.FormPages.CurrentPage = Items.FillingOut;
		AttachIdleHandler("CompleteTheJob", 1, True);
		
	EndIf;
	
	SetInterfaceChanges();

EndProcedure

&AtClient
Procedure Cancel(Command)
	
	If ValueIsFilled(JobID) Then
		CompleteBackgroundTask(JobID);
	EndIf;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetDataOnServer(Var_Parameters)
	
	JobDescription = NStr("vi = 'Điền biểu ghi tài sản và nguồn vốn';
							|ru = 'Заполнение регистра активов и пассивов';
							|en = 'Populate the asset and liability register'; fa = 'Populate the asset and liability register';
							|it = 'Compilazione del registro di attivi e passivi';
							|pl = 'Wypełnianie rejestru aktywów i pasywów';
							|tr = 'Varlık ve yükümlülük kayıt defterinin doldurulması'");
	Result = TimeConsumingOperations.StartBackgroundExecution(
		UUID,
		"DataProcessors.FlowOfAssetsAndLiabilities.GenerateRegisteredRecordsByCase",
		Var_Parameters, 
		JobDescription);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ImportResult()
	
	ImportParameters = GetFromTempStorage(StorageAddress);
	Source = "";
	
	Indicator = Items.Indicator.MaxValue;
	Items.LabelProcessed.Title = "";

	Items.FormPages.CurrentPage = Items.ResultPage;
		
	SetInterfaceChanges();
	
EndProcedure

// The unified checking procedure of a background job
&AtClient
Procedure Attachable_CheckTaskCompletion()
	
	TaskData_ = GetFromTempStorage(StorageAddress);
	RefreshProgressBar(TaskData_);
	
	If JobCompleted(JobID) Then 
		ImportResult();
	Else
		TimeConsumingOperationsClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		AttachIdleHandler(
			"Attachable_CheckTaskCompletion", 
			IdleHandlerParameters.CurrentInterval, 
			True);
	EndIf;

EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

// Depending on the current page, it sets the availability of certain fields for the user.
//
&AtServer
Procedure SetInterfaceChanges()
	
	If Items.FormPages.CurrentPage = Items.FillInRegisters Then
		Items.FormNextButton.Title    = NStr("vi = 'Bắt đầu thực hiện>>';
											|ru = 'Начать проведение >>';
											|en = 'Start posting >>'; fa = 'Start posting >>';
											|it = 'Cominciare la registrazione >>';
											|pl = 'Rozpocząć prowadzenie >>';
											|tr = 'Kaydetmeyi başlat >>'");
		Items.FormCancelButton.Enabled = True;
		Items.FormNextButton.Enabled  = True;
	ElsIf Items.FormPages.CurrentPage = Items.FillingOut
		Or Items.FormPages.CurrentPage = Items.CannotFillIn Then
		Items.FormNextButton.Visible  = False;
		Items.FormCancelButton.Enabled = True;
	Else
		Items.FormCancelButton.Visible   = False;
		Items.FormNextButton.Title    = NStr("vi = 'Đồng ý';
											|ru = 'Готово';
											|en = 'Finish'; fa = 'پایان';
											|it = 'Fine';
											|pl = 'Finish';
											|tr = 'Bitiş'");
		Items.FormNextButton.Visible    = True;
		Items.FormNextButton.Enabled  = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure CompleteBackgroundTask(JobID)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	If BackgroundJob <> Undefined Then
		BackgroundJob.Cancel();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteTheJob()
	
	ImportParameters = New Structure;
	ImportParameters.Insert("MessageText", "");
	ImportParameters.Insert("ImportIsCompleted", False);
	ImportParameters.Insert("NotRecordRegisteredRecords_", NotRecordRegisteredRecords_);
	
	Result = GetDataOnServer(ImportParameters);
	
	StorageAddress = Result.StorageAddress;
	If Not Result.JobCompleted Then
		JobID = Result.JobID;
		TimeConsumingOperationsClient.InitIdleHandlerParameters(IdleHandlerParameters);
		AttachIdleHandler("Attachable_CheckTaskCompletion", 1, True);
	Else
		ImportResult();
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshProgressBar(TaskData_)

	InformationRecords = Constants.IBUpdateInfo.Get().Get();
	If TypeOf(InformationRecords) = Type("Structure") And InformationRecords.Property("FillingInAssetsLiabilities") Then
		Process_ = InformationRecords.FillingInAssetsLiabilities; // See DataProcessors.FlowOfAssetsAndLiabilities.InitializeInformationAboutFilling
		Items.Indicator.MaxValue = Process_.TotalDocuments;
		Indicator = Process_.ProcessedDocuments_1;
		Items.LabelProcessed.Title = Process_.LongDesc;
	EndIf;

EndProcedure

#EndRegion
