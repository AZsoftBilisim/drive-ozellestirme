
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InitializeServiceParametersOfForm();
	
	Query = New Query(FormServiceParameters.QueryText);
	Query.SetParameter("DocumentsList", Parameters.DocumentsList);
	
	DataForCalculation.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DetermineNextMonthOfCalculation();
	StartCalculatingDepreciation();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CalculationIsRunning Then
		Return;
	EndIf;
	
	Cancel = True;

	If Not Exit Then
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Tiếp tục tính toán';
													|ru = 'Продолжить расчет';
													|en = 'Continue calculation'; fa = 'Continue calculation';
													|it = 'Continuare il calcolo';
													|pl = 'Kontynuuj rozliczenie';
													|tr = 'Hesaplamaya devam et'"));
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Hủy bỏ tính toán';
													|ru = 'Отменить расчет';
													|en = 'Cancel calculation'; fa = 'لغو محاسبه';
													|it = 'Annullare il calcolo';
													|pl = 'Anuluj rozliczenie';
													|tr = 'Hesaplamayı iptal etme'"));
		
		QueryText = NStr("vi = 'Chưa kết thúc tính khấu hao. 
		|Hủy tính toán và đóng biểu mẫu?';
		|ru = 'Расчет амортизации не завершен. 
		|Отменить расчет и закрыть форму?';
		|en = 'Depreciation calculation is not completed.
		|Cancel calculation and close the form?'; fa = 'Depreciation calculation is not completed.
		|Cancel calculation and close the form?';
		|it = 'Il calcolo dell''ammortamento non è terminato. 
		|Annullare il calcolo e chiudere il modulo?';
		|pl = 'Nie zakończono rozliczenia amortyzacji. 
		|Anulować rozliczenie i zamknąć formularz?';
		|tr = 'Amortisman hesaplaması tamamlanmadı. 
		| Hesaplama iptal edilsin ve form kapatılsın mı?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	Else
		WarningText = NStr("vi = 'Tính toán khấu hao không được hoàn thành. Kết quả tính toán sẽ không được ghi lại.';
							|ru = 'Расчет амортизации не завершен. Результаты расчета не будут записаны.';
							|en = 'Depreciation calculation is not completed. Calculation results will not be saved.'; fa = 'Depreciation calculation is not completed. Calculation results will not be saved.';
							|it = 'Il calcolo dell''ammortamento non è terminato. I risultati del calcolo non saranno registrati.';
							|pl = 'Nie zakończono rozliczenia amortyzacji. Rezultaty rozliczenia nie będą zapisane.';
							|tr = 'Amortisman hesaplaması tamamlanmamıştır. Hesaplama sonuçları kaydedilmeyecektir.'");
	EndIf; 
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartCalculatingDepreciation()

	CalculationIsRunning = True;
	
	If CurrentMonth = '000101010000' Then
		CompleteCalculationAndCloseForm(Undefined);
		Return;
	EndIf;
	
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(CurrentMonth);
	Items.CalculationTitleInTheBackground.Title = StrTemplate(NStr("vi = 'Tính khấu hao cho %1';
																	|ru = 'Выполняется расчет амортизации за %1';
																	|en = 'Depreciation is being calculated for %1'; fa = 'Depreciation is being calculated for %1';
																	|it = 'Выполняется расчет амортизации за %1';
																	|pl = 'Depreciation is being calculated for %1';
																	|tr = '%1 için amortisman hesaplaması gerçekleştiriliyor'"), PeriodPresentation);
	
	AttachIdleHandler("Attachable_StartCalculatingDepreciation", 1, True);
	
EndProcedure

&AtServer
Function CalculateDepreciationOnServer()
	
	CompaniesList.Clear();
	
	If NonCurrentAssets.VNAManagementIsUsed_2_4(CurrentMonth) Then
		
		CalculationParameters = FixedAssetDepreciationCalculation.ExecutionParameters();
		CalculationParameters.Period = CurrentMonth;
		CalculationParameters.RegisterErrors = False;
		
		TheStructureOfTheSearch = New Structure("Date", CurrentMonth);
		StringsList = DataForCalculation.FindRows(TheStructureOfTheSearch);
		For Each CurCalculationParameters In StringsList Do
			NewPackage = CalculationParameters.DepreciationPackages.Add();
			NewPackage.Organization = CurCalculationParameters.Organization;
			NewPackage.PackageNumber = CurCalculationParameters.PackageNumber;
			CalculationParameters.CompaniesList.Add(CurCalculationParameters.Organization);
			CompaniesList.Add(CurCalculationParameters.Organization);
		EndDo; 
		
		TimeConsumingOperation = FixedAssetDepreciationCalculation.RunDepreciationCalculationInBackground(CalculationParameters, UUID);
		
	Else
		
		DocumentsList = New Array;
		TheStructureOfTheSearch = New Structure("Date", CurrentMonth);
		StringsList = DataForCalculation.FindRows(TheStructureOfTheSearch);
		For Each CurCalculationParameters In StringsList Do
			DocumentsList.Add(CurCalculationParameters.Ref);
		EndDo;
		 
		ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính khấu hao TSCĐ hữu hình';
															|ru = 'Расчет амортизации ОС';
															|en = 'Fixed asset depreciation calculation'; fa = 'محاسبه استهلاک دارایی ثابت';
															|it = 'Calcolo ammortamento di immobilizzazioni materiali';
															|pl = 'Rozliczenie amortyzacji środków trwałych';
															|tr = 'SV amortismanının hesaplanması'");
		ExecutionParameters.WaitCompletion = 0;
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
			ExecutionParameters, "NonCurrentAssets.NavigateDocumentsInBackground", DocumentsList);
		 
	EndIf; 
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure AfterCalculatingDepreciation(Result, AdditionalParameters) Export

	CalculationIsRunning = False;
	CalculationResult2 = Undefined;
	
	If Result <> Undefined Then
		CalculationResult2 = GetCalculationResult(Result.ResultAddress);
	EndIf;
	
	DetermineNextMonthOfCalculation();
	
	For Each EventName In FormServiceParameters.RecordingEvents Do
		Notify(EventName);
	EndDo; 
	For Each DocumentTypeName In FormServiceParameters.DocumentTypes Do
		NotifyChanged(Type(DocumentTypeName));
	EndDo; 
	
	If CurrentMonth <> '000101010000' Then
		
		StartCalculatingDepreciation();
		
	Else
		
		CompleteCalculationAndCloseForm(CalculationResult2);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteCalculationAndCloseForm(CalculationResult2)

	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	NonCurrentAssetsClient.NotifyAboutDepreciationCalculation(CalculationResult2);
	
	If IsOpen() Then
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_StartCalculatingDepreciation()

	CalculationIsRunning = True;
	
	TimeConsumingOperation = CalculateDepreciationOnServer();
	
	CallbackOnCompletion = New CallbackDescription("AfterCalculatingDepreciation", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtClient
Procedure DetermineNextMonthOfCalculation()

	For Each CollectionItem In DataForCalculation Do
		If CollectionItem.Date > CurrentMonth Then
			CurrentMonth = CollectionItem.Date;
			Return;
		EndIf; 
	EndDo; 

	CurrentMonth = '000101010000';
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		CancelBackgroundDepreciationCalculation();
		
		If IsOpen() Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelBackgroundDepreciationCalculation()

	CalculationIsRunning = False;
	TimeConsumingOperations.CancelJobExecution(JobID);

EndProcedure

&AtServerNoContext
Function GetCalculationResult(Val StorageAddress)

	CalculationResult2 = GetFromTempStorage(StorageAddress);
		
	Return CalculationResult2;
	
EndFunction

&AtServer
Procedure InitializeServiceParametersOfForm()

	InternalParameters = New Structure;
	
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge2_4.Ref AS Ref,
	|	FixedAssetsDepreciationCharge2_4.Organization AS Organization,
	|	FixedAssetsDepreciationCharge2_4.PackageNumber,
	|	FixedAssetsDepreciationCharge2_4.Date AS Date
	|FROM
	|	Document.FixedAssetsDepreciationCharge2_4 AS FixedAssetsDepreciationCharge2_4
	|WHERE
	|	FixedAssetsDepreciationCharge2_4.Ref IN(&DocumentsList)
	|	AND NOT FixedAssetsDepreciationCharge2_4.DeletionMark
	|
	|ORDER BY
	|	Date,
	|	Organization";
	InternalParameters.Insert("QueryText", QueryText);
	
	InternalParameters.Insert("RecordingEvents", New Array);
	InternalParameters.RecordingEvents.Add("Write_FixedAssetsDepreciationCharge2_4");
	
	InternalParameters.Insert("DocumentTypes", New Array);
	InternalParameters.DocumentTypes.Add("DocumentRef.FixedAssetsDepreciationCharge2_4");
	
	FixedAssetsDepreciationChargeLocalization.AddServiceParametersOfDepreciationCalculationForm(InternalParameters);
	
	FormServiceParameters = New FixedStructure(InternalParameters);

EndProcedure

#EndRegion
