
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	GenerateTextDescriptionOfSupport();
		
	CurrentVersion = DemoScenarios.PresentationCurVersionOfConfiguration();
	
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers 

&AtClient
Procedure PutOnSupport(Command)
	
	ClearMessages(); 
	
	Cancel = False;
	
	CheckAvailabilityOfApplicationForSupport(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	NotificationOfAnswerToQuestion = New CallbackDescription("AfterAnsweringQuestionStatementForSupport", ThisObject);
	QueryText = NStr("vi = 'Bạn có muốn hỗ trợ ""Mô tả quy trình"" từ phiên bản hiện tại không?';
					|ru = 'Хотите поставить ""Описания процессов""  на поддержку от текущей версии?';
					|en = 'Do you want to enable support of ""Process details"" since the current version?'; fa = 'Do you want to enable support of ""Process details"" since the current version?';
					|it = 'Хотите поставить ""Описания процессов""  на поддержку от текущей версии?';
					|pl = 'Do you want to enable support of ""Process details"" since the current version?';
					|tr = 'Mevcut sürümden desteğe ""Süreç ayrıntılarını"" yerleştirmek istiyor musunuz?'");
	
	ShowQueryBox(NotificationOfAnswerToQuestion, QueryText,
	              QuestionDialogMode.YesNo,,
	              , NStr("vi = 'Đặt hỗ trợ';
						|ru = 'Постановка на поддержку';
						|en = 'Enabling support'; fa = 'Enabling support';
						|it = 'Постановка на поддержку';
						|pl = 'Enabling support';
						|tr = 'Desteğe yerleştirme'"));
	
EndProcedure

#EndRegion 

#Region Private

&AtClient
Procedure CheckAvailabilityOfApplicationForSupport(Cancel)
	
	
	If IsBlankString(Vendor) Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Để đặt hỗ trợ từ phiên bản hiện tại, cần chỉ định giá trị ""Nhà cung cấp""';
				|ru = 'Для постановки на поддержку от текущей версии требуется указать значение ""Поставщик""';
				|en = 'To enable support since the current version, specify the Vendor value'; fa = 'To enable support since the current version, specify the Vendor value';
				|it = 'Для постановки на поддержку от текущей версии требуется указать значение ""Поставщик""';
				|pl = 'To enable support since the current version, specify the Vendor value';
				|tr = 'Mevcut sürümden desteğe yerleştirmek için ""Tedarikçi"" değerinin belirtilmesi gerekmektedir'"),
			, 
			"Vendor",
			,
			Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAnsweringQuestionStatementForSupport(UserAnswer, AdditionalParameters) Export

	If UserAnswer <> DialogReturnCode.Yes Then
		
		Return;
		
	EndIf;
	
	TimeConsumingOperation = PerformSupportStatementLongTermOperation(UUID);
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		CompleteStatementForSupportCompletion(TimeConsumingOperation, AdditionalParameters);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Đặt hỗ trợ mô tả quy trình';
									|ru = 'Постановка на поддержку описаний процессов';
									|en = 'Enabling support of process details'; fa = 'Enabling support of process details';
									|it = 'Постановка на поддержку описаний процессов';
									|pl = 'Enabling support of process details';
									|tr = 'Süreç ayrıntılarının desteğe yerleştirilmesi'");
		
		CallbackOnCompletion = New CallbackDescription("CompleteStatementForSupportCompletion", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;

EndProcedure

&AtServer
Function PerformSupportStatementLongTermOperation(Var_UUID)
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Vendor",  Vendor);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Đặt hỗ trợ từ phiên bản mô tả quy trình hiện tại';
														|ru = 'Постановка на поддержку от текущей версии описаний процессов';
														|en = 'Enabling support of process details since the current version'; fa = 'Enabling support of process details since the current version';
														|it = 'Постановка на поддержку от текущей версии описаний процессов';
														|pl = 'Enabling support of process details since the current version';
														|tr = 'Süreç ayrıntılarının mevcut sürümden desteğe yerleştirilmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DemoScenarios.PutProcessDescriptionsOnSupportFromCurVersion",
	                                                       GenerationParameters, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure CompleteStatementForSupportCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then
		NotifyAboutResultsOfApplicationForSupport(Result, AdditionalParameters);
	EndIf;

EndProcedure

&AtClient
Procedure NotifyAboutResultsOfApplicationForSupport(Result, AdditionalParameters)

	If Not IsTempStorageURL(Result.ResultAddress) Then 
		Return;
	EndIf;
	
	DataForExecution =  GetFromTempStorage(Result.ResultAddress);
	
	
	If DataForExecution.Success Then
		
		NotificationText1 = NStr("vi = 'Đã đặt mô tả hỗ trợ thành công';
								|ru = 'Постановка описаний на поддержку успешно завершена';
								|en = 'Enabling support of details is successful'; fa = 'Enabling support of details is successful';
								|it = 'Постановка описаний на поддержку успешно завершена';
								|pl = 'Enabling support of details is successful';
								|tr = 'Ayrıntıların desteğe yerleştirilmesi başarıyla tamamlandı'");
		GenerateTextDescriptionOfSupport();
		
	Else
		
		NotificationText1 = NStr("vi = 'Đã đặt mô tả hỗ trợ bị lỗi.';
								|ru = 'Постановка описаний на поддержку завершилась с ошибкой.';
								|en = 'Enabling support of details completed with an error.'; fa = 'Enabling support of details completed with an error.';
								|it = 'Постановка описаний на поддержку завершилась с ошибкой.';
								|pl = 'Enabling support of details completed with an error.';
								|tr = 'Ayrıntıların desteğe yerleştirilmesi hata ile sonuçlandı.'");
		
		MessageToUserText = StrTemplate(NStr("vi = 'Chưa thực hiện thao tác do nguyên nhân: %1';
											|ru = 'Операция не выполнена по причине: %1';
											|en = 'Operation is not executed. Reason: %1.'; fa = 'Operation is not executed. Reason: %1.';
											|it = 'Операция не выполнена по причине: %1';
											|pl = 'Operation is not executed. Reason: %1.';
											|tr = 'İşlem şu nedenden dolayı tamamlanmadı %1'"), DataForExecution.ErrorMessage);
		CommonClient.MessageToUser(MessageToUserText);
		
	EndIf;
		
	ShowUserNotification(NStr("vi = 'Đặt mô tả hỗ trợ';
								|ru = 'Постановка описаний на поддержку';
								|en = 'Enabling support of details'; fa = 'Enabling support of details';
								|it = 'Постановка описаний на поддержку';
								|pl = 'Enabling support of details';
								|tr = 'Ayrıntıların desteğe yerleştirilmesi'") ,, NotificationText1, PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure GenerateTextDescriptionOfSupport()
	
	ReadingResult = DemoScenarios.ResultOfReadingProcessDescriptionConstantsOnSupport(); 
	
	TitleText = "";
	
	If Not IsBlankString(ReadingResult.DataOfConfiguration) 
		And Not IsBlankString(ReadingResult.Vendor) Then
		
		TitleText = DemoScenariosClientServer.DeliveryDescriptionText(ReadingResult.DataOfConfiguration, ReadingResult.Vendor);
		
	EndIf;
	
	DetailsOfSupportProcesses = TitleText;
	
EndProcedure

#EndRegion


