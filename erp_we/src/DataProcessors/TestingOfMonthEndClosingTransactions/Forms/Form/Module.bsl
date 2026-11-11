#Region Variables

&AtClient
Var IdleHandlerParameters;
&AtClient
Var FormClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not TMDataExchange.MonthClosingOperationsAreAvailableInThisNode(Cancel) Then
		Return;
	EndIf;
	
	TestingParameters = DataProcessors.TestingOfMonthEndClosingTransactions.TestStartupParameters();
	FillPropertyValues(ThisObject, TestingParameters);
	TestSections = DataProcessors.TestingOfMonthEndClosingTransactions.TestSections();
	ControlRegisters.LoadValues(DataProcessors.TestingOfMonthEndClosingTransactions.ControlRegisters());
	ControlRegisters.FillChecks(True);
	
	NewTestingTree = FormAttributeToValue("TestingTree", Type("ValueTree"));
	For Each TestingPhase In TestingStages Do
		StageString_ = NewTestingTree.Rows.Add();
		StageString_.NodeName = TestingPhase.Value;
		StageString_.Use = TestingPhase.Check;
		StageString_.StorageAddressOfDiscrepancy = PutToTempStorage(Undefined, New UUID);
		For Each TestingSection In TestSections Do
			SectionRow = StageString_.Rows.Add();
			SectionRow.NodeName = TestingSection.Value;
			SectionRow.Use = TestingSection.Check;
			SectionRow.StorageAddressOfDiscrepancy = PutToTempStorage(Undefined, New UUID);
			ArrayOfSelectedPartition = CommonClientServer.ValueInArray(SectionRow.NodeName);
			For Each TestingRegister In DataProcessors.TestingOfMonthEndClosingTransactions.ControlRegisters(ArrayOfSelectedPartition) Do
				RegisterLine = SectionRow.Rows.Add();
				RegisterLine.NodeName = TestingRegister;
				RegisterLine.Use = True;
				RegisterLine.StorageAddressOfDiscrepancy = PutToTempStorage(Undefined, New UUID);
			EndDo;
		EndDo;
	EndDo;
	ValueToFormAttribute(NewTestingTree, "TestingTree");
	
	ErrorsDirectory = ?(ValueIsFilled(ErrorsDirectory), ErrorsDirectory, TempFilesDir());
	WorkingDirectory = ?(ValueIsFilled(WorkingDirectory), WorkingDirectory, TempFilesDir());
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AutoTesting = ValueIsFilled(LaunchParameter);
	AutoTesting = False;
	
	If AutoTesting Then // This is an automatic startup
		
		StartTesting();
		
	Else
		
		CalculationStartLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(CalculationStart);
		CalculationEndLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(CalculationEnd);
		PresentationOfSectionsForTesting = ListPresentation(TestSections);
		PresentationOfRegistersForTesting = ListPresentation(ControlRegisters);
		PresentationOfTestStages = ListPresentation(TestingStages);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CalculationStartClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure CalculationStartStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("SelectPeriodCompletion", ThisObject, "CalculationStart");
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", CalculationStart, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculationStartTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	CalculationStart = AddMonth(CalculationStart, Direction);
	CalculationStartLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(CalculationStart);
	
EndProcedure

&AtClient
Procedure CalculationEndClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure CalculationEndStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("SelectPeriodCompletion", ThisObject, "CalculationEnd");
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", CalculationEnd, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculationEndTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	CalculationEnd = AddMonth(CalculationEnd, Direction);
	CalculationEndLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(CalculationEnd);
	
EndProcedure

&AtClient
Procedure WorkingDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	
	Dialog.Title = NStr("vi = 'Chọn một thư mục để lưu kết quả';
						|ru = 'Выберите каталог для сохранения результатов';
						|en = 'Select a directory to save results'; fa = 'Select a directory to save results';
						|it = 'Selezionate una directory per salvare i risultati';
						|pl = 'Wybierz katalog do zapisywania wyników';
						|tr = 'Sonuçları kaydetmek için klasör seç'");
	Dialog.Directory = WorkingDirectory;
	Dialog.Multiselect = False;
	
	Notification = New CallbackDescription("SelectDirectoryCompletion", ThisObject, "WorkingDirectory");
	Dialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure WorkingDirectoryOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	RunApp("explorer " + WorkingDirectory);
	
EndProcedure

&AtClient
Procedure ErrorsDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Title = NStr("vi = 'Hãy chọn thư mục để lưu tệp lỗi';
						|ru = 'Выберите каталог для сохранения файлов ошибок';
						|en = 'Select a directory to save error files'; fa = 'Select a directory to save error files';
						|it = 'Выберите каталог для сохранения файлов ошибок';
						|pl = 'Select a directory to save error files';
						|tr = 'Hata dosyalarının kaydedileceği klasör seç'");
	Dialog.Directory = ErrorsDirectory;
	Dialog.Multiselect = False;
	
	Notification = New CallbackDescription("SelectDirectoryCompletion", ThisObject, "ErrorsDirectory");
	Dialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure ErrorsDirectoryOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	RunApp("explorer " + ErrorsDirectory);
	
EndProcedure

&AtClient
Procedure PresentationOfSectionsForTestingClick(Item, StandardProcessing)
	StandardProcessing = False;
	ListSelection = New CallbackDescription("ListViewPressing_Select", ThisObject, Item.Name);
	TestSections.ShowCheckItems(ListSelection, NStr("vi = 'Hãy chọn phân hệ để kiểm thử';
													|ru = 'Выберите разделы для тестирования';
													|en = 'Select sections to test'; fa = 'Select sections to test';
													|it = 'Выберите разделы для тестирования';
													|pl = 'Select sections to test';
													|tr = 'Test edilecek bölümleri seç'"));
EndProcedure

&AtClient
Procedure PresentationOfRegistersForTestingClick(Item, StandardProcessing)
	StandardProcessing = False;
	ListSelection = New CallbackDescription("ListViewPressing_Select", ThisObject, Item.Name);
	ControlRegisters.ShowCheckItems(ListSelection, NStr("vi = 'Hãy chọn biểu ghi kiểm soát';
														|ru = 'Выберите контрольные регистры';
														|en = 'Select control registers'; fa = 'Select control registers';
														|it = 'Выберите контрольные регистры';
														|pl = 'Select control registers';
														|tr = 'Kontrol kayıtlarını seç'"));
EndProcedure

&AtClient
Procedure PresentationOfTestStagesClick(Item, StandardProcessing)
	StandardProcessing = False;
	ListSelection = New CallbackDescription("ListViewPressing_Select", ThisObject, Item.Name);
	TestingStages.ShowCheckItems(ListSelection, NStr("vi = 'Hãy chọn các giai đoạn kiểm thử';
													|ru = 'Выберите этапы тестирования';
													|en = 'Select testing steps'; fa = 'Select testing steps';
													|it = 'Выберите этапы тестирования';
													|pl = 'Select testing steps';
													|tr = 'Test aşamalarını seç'"));
EndProcedure

&AtClient
Procedure TestingTreeSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "TestingTreeURL" And ValueIsFilled(Items.TestingTree.CurrentData.PathToFile) Then
		StandardProcessing = False;
		TestData_ = New BinaryData(Items.TestingTree.CurrentData.PathToFile);
		StorageAddress = PutToTempStorage(TestData_, UUID);
		ReportParameters = New Structure("PathToFile, GenerateOnOpen", StorageAddress, True);
		OpenForm("Report.TestResults.Form.ReportForm", ReportParameters, ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure TestingTreeURLStartChoice(Item, ChoiceData, StandardProcessing)
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = NStr("vi = 'Hãy chọn tệp chênh lệch';
						|ru = 'Выберите файл с расхождениями';
						|en = 'Select a file with discrepancies'; fa = 'Select a file with discrepancies';
						|it = 'Выберите файл с расхождениями';
						|pl = 'Select a file with discrepancies';
						|tr = 'Tutarsızlıkların olduğu dosyayı seç'");
	Dialog.Directory = WorkingDirectory;
	Dialog.Multiselect = False;
	Dialog.Filter = "Table (*.xml;*.mxl)|*.xml;*.mxl|";
	
	Notification = New CallbackDescription("SelectFileCompletion", ThisObject);
	Dialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure TestingTreeReferenceDataStartChoice(Item, ChoiceData, StandardProcessing)
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = NStr("vi = 'Hãy chọn tệp có dữ liệu tham chiếu';
						|ru = 'Выберите файл с эталонными данными';
						|en = 'Select a file with reference data'; fa = 'Select a file with reference data';
						|it = 'Выберите файл с эталонными данными';
						|pl = 'Select a file with reference data';
						|tr = 'Referans veri dosyasını seç'");
	Dialog.Directory = WorkingDirectory;
	Dialog.Multiselect = False;
	Dialog.Filter = "Table (*.json;)|*.json;|";
	
	Notification = New CallbackDescription("SelectFileCompletion", ThisObject);
	Dialog.Show(Notification);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Run(Command)
	
	ErrorMessage.Clear();
	StartTesting();
	
EndProcedure

&AtClient
Procedure CancelJob(Command)
	JobCanceled = CancelMonthClosingBackgroundJob();
	If JobCanceled Then
		JobID = Undefined;
		ChangesInInterfaceWhenWorkingInBackground();
		DetachIdleHandler("ContinueTesting");
		DetachIdleHandler("Attachable_CheckTaskCompletion");
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExecuteActionsCompletion()
	
	DetachIdleHandler("ExecuteActionsCompletion");
	
	UploadErrorsToServer();
	SaveErrorsAndShutDown();
	
EndProcedure

&AtClient
Procedure SaveErrorsAndShutDown()
	
	If Errors.Count() > 0 And ValueIsFilled(ErrorsDirectory) Then
		
		File = New File(ErrorsDirectory);
		
		If Not File.Exists() Then
			CreateDirectory(ErrorsDirectory);
		ElsIf Not File.IsDirectory() Then
			DeleteFiles(ErrorsDirectory);
			CreateDirectory(ErrorsDirectory);
		EndIf; 
	
		For Each Error In Errors Do
			
			ErrorFileName = CommonClientServer.AddLastPathSeparator(ErrorsDirectory);
			ErrorFileName = ErrorFileName + StringFunctionsClientServer.SubstituteParametersToString(
			                 "%1_%2.xml", Format(CurrentDate(), NStr("vi = 'DF=''yyyyMMddHHmmss';
																	|ru = 'ДФ=''yyyyMMddHHmmss';
																	|en = 'DF=''yyyyMMddHHmmss'; fa = 'DF=''yyyyMMddHHmmss';
																	|it = 'ДФ=''yyyyMMddHHmmss';
																	|pl = 'DF=''yyyyMMddHHmmss';
																	|tr = 'DF=''yyyyMMddHHmmss'")), String(New UUID()));
			Result = New TextDocument;
			Result.SetText(Error.Value);
			Result.Write(ErrorFileName);
			
		EndDo;
		
	EndIf; 
	
	If AutoTesting Then
		Terminate(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartTesting()
	
	Errors.Clear();
	
	RunTestingOnServer(LaunchParameter);
	If AutoTesting Then
		ProcessTestResult();
	Else
		ChangesInInterfaceWhenWorkingInBackground();
		TimeConsumingOperationsClient.InitIdleHandlerParameters(IdleHandlerParameters);
		AttachIdleHandler("Attachable_CheckTaskCompletion", IdleHandlerParameters.CurrentInterval, True);
	EndIf;
	
	If Errors.Count() Then
		AttachIdleHandler("ExecuteActionsCompletion", 30, True); // we simulate a delay, since events are written to the log with a delay.
	Else
		SaveErrorsAndShutDown();
	EndIf;
	
EndProcedure

&AtServer
Function GetTestResult()
	TestResult_ = GetFromTempStorage(StorageAddress);
	If TestResult_.Property("ResultTree") Then
		ValueToFormAttribute(TestResult_.ResultTree, "TestingTree");
		TestResult_.Delete("ResultTree");
	EndIf;
	Return TestResult_;
EndFunction

&AtClient
Procedure ProcessTestResult()
	
	TestResult_ = GetTestResult();
	
	If TestResult_.Cancel Then // a critical error in the code, the calculation was not performed.
		Error = CreateErrorDescription();
		Error.ErrorType = NStr("vi = 'Lỗi thử nghiệm';
								|ru = 'Ошибка тестирования';
								|en = 'Test error'; fa = 'Test error';
								|it = 'Errore di test';
								|pl = 'Błąd testowania';
								|tr = 'Test hatası'");
		Error.PlaybackOrder = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra lỗi nghiêm trọng khi thử nghiệm.
			|Tháng bắt đầu tính toán: %1
			|Ngày khởi động: %2
			|Ngày kết thúc: %3';
			|ru = 'Возникла критичная ошибка при тестировании.
			|Месяц начала расчета: %1
			|Дата запуска: %2
			|Дата завершения: %3';
			|en = 'A critical error occurred when testing.
			|Calculation start month: %1
			|Start date: %2
			|End date: %3'; fa = 'A critical error occurred when testing.
			|Calculation start month: %1
			|Start date: %2
			|End date: %3';
			|it = 'Возникла критичная ошибка при тестировании.
			|Месяц начала расчета: %1
			|Дата запуска: %2
			|Дата завершения: %3';
			|pl = 'A critical error occurred when testing.
			|Calculation start month: %1
			|Start date: %2
			|End date: %3';
			|tr = 'Test sırasında kritik hata oluştu.
			|Başlangıç ayı: %1
			| Başlangıç tarihi: %2
			|Bitiş tarihi: %3'"),
			CalculationStart,
			StartDate,
			EndDate);
		Error.SourceInformation = TestResult_.SourceInformation;
		Error.MetadataObject = TestResult_.MetadataObject;
		Error.LocationClarification = TestResult_.LocationClarification;
		Errors.Add(XMLErrorText(Error));
		
		ReportError(Error);
	Else
		
		MatchingStagesAndFilesOfDiscrepancies = New Map;
		For Each Page1 In TestingTree.GetItems() Do
			If Not Page1.Use Or Page1.NumberOfDiscrepancies = 0 Then
				Continue;
			EndIf;
			For Each SectionStr In Page1.GetItems() Do
				If Not SectionStr.Use Or SectionStr.NumberOfDiscrepancies = 0 Then
					Continue;
				EndIf;
				For Each RegisterRow In SectionStr.GetItems() Do
					If Not RegisterRow.Use Or RegisterRow.NumberOfDiscrepancies = 0 Then
						Continue;
					EndIf;
					FileName = "%StageName__%SectionName_%RegisterName.xml";
					FileName = StrReplace(FileName, "%StageName_", StringFunctionsClientServer.LatinString(Page1.NodeName));
					FileName = StrReplace(FileName, "%SectionName", StringFunctionsClientServer.LatinString(SectionStr.NodeName));
					RegisterName = StrReplace(StringFunctionsClientServer.LatinString(RegisterRow.NodeName), ".", "_");
					FileName = StrReplace(FileName, "%RegisterName", RegisterName);
					PathToFile = CommonClientServer.AddLastPathSeparator(WorkingDirectory) + FileName;
					SaveFileToDisk(RegisterRow.StorageAddressOfDiscrepancy, PathToFile);
					RegisterRow.PathToFile = PathToFile;
					RegisterRow.URL = StrTemplate(NStr("vi = 'Xem %1 sai lệch';
														|ru = 'Посмотреть %1 расхождения';
														|en = 'View %1 discrepancies'; fa = 'View %1 discrepancies';
														|it = 'Посмотреть %1 расхождения';
														|pl = 'View %1 discrepancies';
														|tr = 'Tutarsızlıkları %1 görüntüle'"), RegisterRow.NumberOfDiscrepancies);
				EndDo;
				FileName = "%StageName__%SectionName.xml";
				FileName = StrReplace(FileName, "%StageName_", StringFunctionsClientServer.LatinString(Page1.NodeName));
				FileName = StrReplace(FileName, "%SectionName", StringFunctionsClientServer.LatinString(SectionStr.NodeName));
				PathToFile = CommonClientServer.AddLastPathSeparator(WorkingDirectory) + FileName;
				SaveFileToDisk(SectionStr.StorageAddressOfDiscrepancy, PathToFile);
				SectionStr.PathToFile = PathToFile;
				SectionStr.URL = StrTemplate(NStr("vi = 'Xem %1 sai lệch';
													|ru = 'Посмотреть %1 расхождения';
													|en = 'View %1 discrepancies'; fa = 'View %1 discrepancies';
													|it = 'Посмотреть %1 расхождения';
													|pl = 'View %1 discrepancies';
													|tr = 'Tutarsızlıkları %1 görüntüle'"), SectionStr.NumberOfDiscrepancies);
			EndDo;
			FileName = "%StageName_.xml";
			FileName = StrReplace(FileName, "%StageName_", StringFunctionsClientServer.LatinString(Page1.NodeName));
			PathToFile = CommonClientServer.AddLastPathSeparator(WorkingDirectory) + FileName;
			SaveFileToDisk(Page1.StorageAddressOfDiscrepancy, PathToFile);
			Page1.PathToFile = PathToFile;
			Page1.URL = StrTemplate(NStr("vi = 'Xem %1 sai lệch';
										|ru = 'Посмотреть %1 расхождения';
										|en = 'View %1 discrepancies'; fa = 'View %1 discrepancies';
										|it = 'Посмотреть %1 расхождения';
										|pl = 'View %1 discrepancies';
										|tr = 'Tutarsızlıkları %1 görüntüle'"), Page1.NumberOfDiscrepancies);
		EndDo;
		Return;
		
		OldVersionOfResult = True;
		
		For Each ResultProperty In TestResult_ Do
			
			If StrStartsWith(ResultProperty.Key, "DiscrepancyData") Then
				
				OldVersionOfResult = False;
				If ResultProperty.Key = "DiscrepancyData" Then
					TestingPhase = "ReOrderMonth";
				Else
					TestingPhase = StrReplace(ResultProperty.Key, "DiscrepancyData_", "");
				EndIf;
				
				MatchingStagesAndFilesOfDiscrepancies = New Map;
				For Each Discrepancy In ResultProperty.Value Do
					
					If Discrepancy.Key <> "NumberOfDiscrepancies" Then
							CreateFileAndError(TestingPhase, Discrepancy, MatchingStagesAndFilesOfDiscrepancies);
					EndIf;
					
				EndDo;
			
			EndIf;
			
		EndDo;
		
		// Old version of the result:
		If TestResult_.Property("ThereAreDiscrepancies") And OldVersionOfResult Then // the calculation has been made, but there are discrepancies.
				
			OldData = New Structure;
			OldData.Insert("StorageAddress", TestResult_.StorageAddress);
			OldData.Insert("MetadataObject", "AccumulationRegisters.InventoryCost");
			DiscrepancyData = New Structure("Cost_", OldData);
			For Each Discrepancy In DiscrepancyData Do
				CreateFileAndError("ReOrderMonth", Discrepancy);
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisableEditingBan()
	
	BlankBanDates = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	InfobaseUpdate.WriteData(BlankBanDates);
	
EndProcedure

&AtServer
Procedure RunTestingOnServer(StartupParameters)
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	TestParameters = DataProcessors.TestingOfMonthEndClosingTransactions.TestStartupParameters(StartupParameters);
	TestParameters.StorageAddress = StorageAddress;
	
	TransmittedTree = FormAttributeToValue("TestingTree", Type("ValueTree"));
	FileName = GetTempFileName();
	ValueToFile(FileName, TransmittedTree);
	TestParameters.Insert("TestPlanTree", FileName);
	
	DisableEditingBan();
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	
	If AutoTesting Then
		DataProcessors.TestingOfMonthEndClosingTransactions.Testing(TestParameters);
	Else
		If Not ThereIsAnActiveBackgroundTask(JobID) Then
			FillPropertyValues(TestParameters, ThisObject);
			TestParameters.Sections = CommonClientServer.MarkedItems(TestSections);
			TestParameters.ControlRegisters = CommonClientServer.MarkedItems(ControlRegisters);
			JobID = DataProcessors.TestingOfMonthEndClosingTransactions.RunTestingInBackground(TestParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThereIsAnActiveBackgroundTask(JobID)
	
	ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.CheckForActiveCalculations();
	
	If ActiveCalculations.ThereAreActiveCalculations Then
		If Not ValueIsFilled(JobID) Then
			Common.MessageToUser(ActiveCalculations.ErrorText);
		EndIf;
		Return True;
	EndIf;
	
	If ValueIsFilled(JobID) Then
		JobState = MonthEndTransactionsServer.CurStateOfBackgroundJob(JobID);
		Return JobState.Active;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure ContinueTesting()
	
	If ThereIsAnActiveBackgroundTask(JobID) Then
		Return;
	EndIf;
	
	DetachIdleHandler("ContinueTesting");
	// parse the calculation results
	//Durationms = The current Universal date in milliseconds() is the calculation of the monthly date;
	ProcessTestResult();
	JobID = Undefined;
	ChangesInInterfaceWhenWorkingInBackground();
	
EndProcedure

#Region ActionEndHandlers

&AtClient
Procedure SelectPeriodCompletion(SelectedPeriod, Var_AttributeName) Export 
	
	If SelectedPeriod <> Undefined Then
		ThisObject[Var_AttributeName] = SelectedPeriod;
		ThisObject[Var_AttributeName + "String"] = TMCommonUseClient.GetPresentationOfRegistrationPeriod(SelectedPeriod);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectDirectoryCompletion(Directory, Var_AttributeName) Export
	
	If Directory <> Undefined Then
		ThisObject[Var_AttributeName] = Directory[0];
	EndIf;
	
EndProcedure

&AtClient
Procedure ListViewPressing_Select(List, NameOfPresentation = Undefined) Export
	If List <> Undefined Then
		ThisObject[NameOfPresentation] = ListPresentation(List);
	EndIf;
EndProcedure

&AtClient
Procedure SelectFileCompletion(PathToFile, AdditionalParameters = Undefined) Export
	
	If PathToFile <> Undefined Then
		Items.TestingTree.CurrentData.PathToReferenceDataFile = PathToFile;
		UploadData_0 = New BinaryData(PathToFile);
		Items.TestingTree.CurrentData.ReferenceData = PutToTempStorage(UploadData_0, New UUID);
	EndIf;
	
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Function ListPresentation(List)
	
	ReturnString = "";
	For Each ListValue In List Do
		If ListValue.Check Then
			ReturnString = ReturnString + ?(ReturnString = "", "", ", ") +
				?(ValueIsFilled(ListValue.Presentation), Lower(ListValue.Presentation), Lower(ListValue.Value));
		EndIf;
	EndDo;
	
	ReturnString = ReturnString + ?(ReturnString = "", NStr("vi = '<không>';
															|ru = '< нет >';
															|en = '< no >'; fa = '< no >';
															|it = '< no >';
															|pl = '< nie >';
															|tr = '< hayır >'"), ".");
	
	Return ReturnString;
	
EndFunction

&AtClient
Procedure ChangesInInterfaceWhenWorkingInBackground()
	Items.FormRun.Enabled = Not ValueIsFilled(JobID);
	Items.FormClose.Enabled = Not ValueIsFilled(JobID);
	Items.GroupLongTermOperations.Visible = ValueIsFilled(JobID);
	If ValueIsFilled(JobID) Then
		Items.GroupPages.CurrentPage = Items.GroupLongTermOperations;
	ElsIf ValueIsFilled(StorageAddress) Then
		Items.GroupPages.CurrentPage = Items.ResultGroup;
	Else
		Items.GroupPages.CurrentPage = Items.GroupParameters;
	EndIf;
EndProcedure

#EndRegion

#Region ErrorLoggingProcedures

&AtClient
Procedure CreateFileAndError(TestingPhase, DiscrepancyData, MatchingSectionsAndFilesOfDiscrepancies = Undefined)
	
	SectionName = DiscrepancyData.Key;
	SectionData = DiscrepancyData.Value;
	
	FileName = "%StageName__%SectionName_%Date_%Id.xml";
	FileName = StrReplace(FileName, "%StageName_", StringFunctionsClientServer.LatinString(?(TestingPhase = "ReOrderMonth", "Complete", TestingPhase)));
	FileName = StrReplace(FileName, "%SectionName", StringFunctionsClientServer.LatinString(SectionName));
	FileName = StrReplace(FileName, "%Date", Format(CurrentDate(), NStr("vi = 'DF=''yyyyMMddHHmmss';
																		|ru = 'ДФ=''yyyyMMddHHmmss';
																		|en = 'DF=''yyyyMMddHHmmss'; fa = 'DF=''yyyyMMddHHmmss';
																		|it = 'ДФ=''yyyyMMddHHmmss';
																		|pl = 'DF=''yyyyMMddHHmmss';
																		|tr = 'DF=''yyyyMMddHHmmss'")));
	FileName = StrReplace(FileName, "%Id", String(New UUID()));
	PathToFile = CommonClientServer.AddLastPathSeparator(WorkingDirectory) + FileName;
	SaveFileToDisk(SectionData.StorageAddress, PathToFile);
	
	Error = CreateErrorDescription();
	Error.ErrorType = TypeOfErrorByStageName(SectionName, CommonClient.DefaultLanguageCode());
	Error.PlaybackOrder = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("vi = 'Sau khi thực hiện công đoạn ""%4"" dữ liệu tổng số khác với dữ liệu tiêu chuẩn.
		|Tháng bắt đầu tính: %1
		|Ngày bắt đầu: %2
		|Ngày hoàn thành: %3';
		|ru = 'После выполнения этапа ""%4"" итоговые данные отличаются от эталонных.
		|Месяц начала расчета: %1
		|Дата запуска: %2
		|Дата завершения: %3';
		|en = 'After performing the ""%4"" step, the resulting data differs from the reference data.
		|Calculation start month: %1
		|Start date: %2
		|End date: %3'; fa = 'After performing the ""%4"" step, the resulting data differs from the reference data.
		|Calculation start month: %1
		|Start date: %2
		|End date: %3';
		|it = 'После выполнения этапа ""%4"" итоговые данные отличаются от эталонных.
		|Месяц начала расчета: %1
		|Дата запуска: %2
		|Дата завершения: %3';
		|pl = 'After performing the ""%4"" step, the resulting data differs from the reference data.
		|Calculation start month: %1
		|Start date: %2
		|End date: %3';
		|tr = '""%4"" aşamanın gerçekleştirilmesinden sonra, toplamlar referans verilerden farklıdır.
		|Başlangıç ayı: %1
		|Başlangıç tarihi: %2
		|Bitiş tarihi: %3'"),
		CalculationStart,
		StartDate,
		EndDate,
		PresentationOfTestingStage(TestingPhase));
	Error.ExpectedBehavior = NStr("vi = 'Cần kiểm tra sai lệch có phải là lỗi hay không.';
									|ru = 'Необходимо проверить, являются ли расхождения ошибками.';
									|en = 'Check whether the discrepancies are errors.'; fa = 'Check whether the discrepancies are errors.';
									|it = 'Необходимо проверить, являются ли расхождения ошибками.';
									|pl = 'Check whether the discrepancies are errors.';
									|tr = 'Tutarsızlıkların hata olup olmadığını kontrol etmek gerekir.'");
	Error.FilesNames.Add(PathToFile);
	Error.MetadataObject      = SectionData.MetadataObject;
	Error.LocationClarification = StrTemplate(NStr("vi = 'Xem tệp có chênh lệch theo các biểu ghi kiểm soát: %1';
													|ru = 'См. файл с расхождениями по контрольным регистрам: %1';
													|en = 'See the file with discrepancies by control registers: %1'; fa = 'See the file with discrepancies by control registers: %1';
													|it = 'См. файл с расхождениями по контрольным регистрам: %1';
													|pl = 'See the file with discrepancies by control registers: %1';
													|tr = 'Kontrol kaydı tutarsızlıkları olan dosyaya bak: %1'"), FileName);
	
	If MatchingSectionsAndFilesOfDiscrepancies <> Undefined Then
		MatchingSectionsAndFilesOfDiscrepancies.Insert(SectionName, PathToFile);
		SupplementErrorWithDiscrepanciesOfInfluencingStages(SectionName, Error, MatchingSectionsAndFilesOfDiscrepancies);
	EndIf;
	
	Errors.Add(XMLErrorText(Error));
	ReportError(Error);
	
EndProcedure

&AtClient
Procedure SaveFileToDisk(StorageAddress, PathToFile)
	
	ReportFile = GetFromTempStorage(StorageAddress);
	ReportFile.Write(PathToFile);
	
EndProcedure

&AtClient
Procedure ReportError(Error)
	
	ErrorMessage.AddLine(Error.ErrorType);
	ErrorMessage.AddLine(Error.PlaybackOrder);
	ErrorMessage.AddLine(Error.SourceInformation);
	
EndProcedure

&AtServer
Procedure UploadErrorsToServer()
	
	LogTable = New ValueTable;
	Filter = New Structure;
	Filter.Insert("StartDate",    StartDate);
	Filter.Insert("EndDate", EndDate);
	Filter.Insert("Level",       EventLogLevel.Error);
	
	UnloadEventLog(LogTable, Filter,,, 200);
	
	For Each LogEvent In LogTable Do
		
		Error = CreateErrorDescription();
		Error.ErrorType = TypeOfErrorByStageName(LogEvent.Event, Common.DefaultLanguageCode());
		Error.PlaybackOrder = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi tính toán, đã xảy ra lỗi nghiêm trọng, chưa thực hiện thao tác thử nghiệm.
			|Tháng bắt đầu tính toán: %1
			|Ngày khởi động: %2
			|Ngày kết thúc: %3';
			|ru = 'При расчете возникла критичная ошибка, Операция тестирования не выполнена.
			|Месяц начала расчета: %1
			|Дата запуска: %2
			|Дата завершения: %3';
			|en = 'A critical error occurred when calculating. Testing is not completed.
			|Calculation start month: %1
			|Start date: %2
			|End date: %3'; fa = 'A critical error occurred when calculating. Testing is not completed.
			|Calculation start month: %1
			|Start date: %2
			|End date: %3';
			|it = 'При расчете возникла критичная ошибка, Операция тестирования не выполнена.
			|Месяц начала расчета: %1
			|Дата запуска: %2
			|Дата завершения: %3';
			|pl = 'A critical error occurred when calculating. Testing is not completed.
			|Calculation start month: %1
			|Start date: %2
			|End date: %3';
			|tr = 'Hesaplama sırasında kritik hata oluştu, Test işlemi başarısız oldu.
			|Hesaplama başlangıç ayı: %1
			|Başlangıç tarihi: %2
			|Bitiş tarihi: %3'"),
			CalculationStart,
			StartDate,
			EndDate);
		Error.SourceInformation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sự kiện trong nhật ký sự kiện: %1
			|Ngày: %2
			|Metadata: %3
			|Ghi chú:
			|%4';
			|ru = 'Событие журнала регистрации: %1
			|Дата: %2
			|Метаданные: %3
			|Комментарий:
			|%4';
			|en = 'Event log event: %1
			|Date: %2
			|Metadata: %3
			|Comment: 
			|%4'; fa = 'Event log event: %1
			|Date: %2
			|Metadata: %3
			|Comment: 
			|%4';
			|it = 'Событие журнала регистрации: %1
			|Дата: %2
			|Метаданные: %3
			|Комментарий:
			|%4';
			|pl = 'Event log event: %1
			|Date: %2
			|Metadata: %3
			|Comment: 
			|%4';
			|tr = 'Kayıt defteri etkinliği: %1
			|Tarih: %2
			|Metadata: %3
			|Yorum:
			|%4'"),
			LogEvent.Event,
			LogEvent.Date,
			LogEvent.Metadata,
			LogEvent.Comment);
		Error.MetadataObject = LogEvent.Metadata;
		Errors.Add(XMLErrorText(Error));
		ErrorMessage.AddLine(LogEvent.Comment);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function CreateErrorDescription() Export 

	Error = New Structure;
	
	Error.Insert("FormatVersion", "1.1");
	Error.Insert("UUID1", String(New UUID));
	Error.Insert("ErrorType", "");
	Error.Insert("SourceInformation", "");
	Error.Insert("PlaybackOrder", "");
	Error.Insert("ExpectedBehavior", "");
	
	#If Client Or ThickClientManagedApplication Or ThinClient Or WebClient Then
	
		SysInfo = New SystemInfo;
		Error.Insert("PlatformVersion", SysInfo.AppVersion);
		Error.Insert("ClientRAM", SysInfo.RAM);
		Error.Insert("ClientOSVersion", SysInfo.OSVersion);
		Error.Insert("ClientProcessor", SysInfo.Processor);
		Error.Insert("ClientPlatformType1", String(SysInfo.PlatformType));
		Error.Insert("ClientUserAgentInformation", SysInfo.UserAgentInformation);
		Error.Insert("ClientCurrentDate", CurrentDate());
	
	#EndIf
	
	
	Error.Insert("MetadataObjects", New Array); // The ability to add an array of metadata objects
	// Registration of one metadata object
	Error.Insert("MetadataObject", "");
	Error.Insert("LocationClarification", "");
	
	Error.Insert("FilesNames", New Array);
	
	Return Error;
	
EndFunction 

&AtServerNoContext
Procedure AddDescriptionOfErrorOnServer(Error) Export
	
	SysInfo = New SystemInfo;
	Error.Insert("PlatformVersion", SysInfo.AppVersion);
	Error.Insert("ServerRam", SysInfo.RAM);
	Error.Insert("ServerFAVersion", SysInfo.OSVersion);
	Error.Insert("ServerProcessor", SysInfo.Processor);
	Error.Insert("Server_PlatformType", String(SysInfo.PlatformType));
	Error.Insert("ServerViewerInformation", SysInfo.UserAgentInformation);
	
	Error.Insert("ConfigurationVersion", Metadata.Version);
	Error.Insert("ConfigurationName", Metadata.Name);
	Error.Insert("DetectionDate", CurrentSessionDate());

EndProcedure 

&AtServerNoContext
Function XMLErrorText(Error) Export
	
	AddDescriptionOfErrorOnServer(Error);
	
	If ValueIsFilled(Error.MetadataObject) Or ValueIsFilled(Error.LocationClarification) Then
	
		Error.MetadataObjects.Add(New Structure("MetadataObject, LocationClarification", Error.MetadataObject, Error.LocationClarification));
	
	EndIf; 
	
	Error.Delete("MetadataObject");
	Error.Delete("LocationClarification");
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	
	XDTOSerializer.WriteXML(XMLWriter, Error);
	
	Return XMLWriter.Close()
	
EndFunction

&AtClientAtServerNoContext
Function TypeOfErrorByStageName(SectionName = "Cost_", DefaultLanguageCode)
	
	MatchingErrorTypeToStageName = New Map;
	
	MatchingErrorTypeToStageName.Insert("MutualSettlementsWithPartners", NStr("vi = 'Sai lệch khi hạch toán công nợ với bạn hàng';
																				|ru = 'Расхождения при расчете взаиморасчетов с партнерами';
																				|en = 'Discrepancies when calculating AR/AP accounting with partners'; fa = 'Discrepancies when calculating AR/AP accounting with partners';
																				|it = 'Расхождения при расчете взаиморасчетов с партнерами';
																				|pl = 'Discrepancies when calculating AR/AP accounting with partners';
																				|tr = 'İş ortaklarıyla yapılan mutabakatlardaki tutarsızlıklar'", DefaultLanguageCode));
	MatchingErrorTypeToStageName.Insert("Cost_", NStr("vi = 'Sai lệch khi tính giá vốn';
														|ru = 'Расхождения при расчете себестоимости';
														|en = 'Discrepancies when calculating cost'; fa = 'Discrepancies when calculating cost';
														|it = 'Расхождения при расчете себестоимости';
														|pl = 'Discrepancies when calculating cost';
														|tr = 'Maliyet hesaplaması sırasında tutarsızlıklar'", DefaultLanguageCode));
	MatchingErrorTypeToStageName.Insert("FinancialAccounting", NStr("vi = 'Sai lệch khi phản ánh chứng từ vào kế toán quốc tế';
																	|ru = 'Расхождения при отражении документов в международном учете';
																	|en = 'Discrepancies when recording documents in financial accounting'; fa = 'Discrepancies when recording documents in financial accounting';
																	|it = 'Расхождения при отражении документов в международном учете';
																	|pl = 'Discrepancies when recording documents in financial accounting';
																	|tr = 'Finansal muhasebeye belge kaydetme sırasında tutarsızlıklar'", DefaultLanguageCode));
	
	// We will also add correspondences to the log events:
	
	RowsArray = New Array;
	RowsArray.Add(NStr("vi = 'Tính giá vốn.';
						|ru = 'Расчет себестоимости.';
						|en = 'Cost calculation.'; fa = 'Cost calculation.';
						|it = 'Расчет себестоимости.';
						|pl = 'Cost calculation.';
						|tr = 'Maliyet hesaplaması.'", DefaultLanguageCode));
	RowsArray.Add(NStr("vi = 'Lỗi';
						|ru = 'Ошибка';
						|en = 'Error'; fa = 'خطا';
						|it = 'Ошибка';
						|pl = 'Error';
						|tr = 'Hata'", DefaultLanguageCode));
	MatchingErrorTypeToStageName.Insert(StrConcat(RowsArray), NStr("vi = 'Lỗi khi tính giá vốn';
																	|ru = 'Ошибка при расчете себестоимости';
																	|en = 'An error occurred when calculating cost'; fa = 'An error occurred when calculating cost';
																	|it = 'Ошибка при расчете себестоимости';
																	|pl = 'An error occurred when calculating cost';
																	|tr = 'Maliyet hesaplama sırasında hata'", DefaultLanguageCode));
	
	RowsArray = New Array;
	RowsArray.Add(NStr("vi = 'Hạch toán lô hàng và giá vốn.';
						|ru = 'Расчет партий и себестоимости.';
						|en = 'Lot and cost calculation.'; fa = 'Lot and cost calculation.';
						|it = 'Расчет партий и себестоимости.';
						|pl = 'Lot and cost calculation.';
						|tr = 'Lot ve maliyet hesaplama.'", DefaultLanguageCode));
	RowsArray.Add(NStr("vi = 'Lỗi';
						|ru = 'Ошибка';
						|en = 'Error'; fa = 'خطا';
						|it = 'Ошибка';
						|pl = 'Error';
						|tr = 'Hata'", DefaultLanguageCode));
	MatchingErrorTypeToStageName.Insert(StrConcat(RowsArray), NStr("vi = 'Lỗi khi tính giá vốn';
																	|ru = 'Ошибка при расчете себестоимости';
																	|en = 'An error occurred when calculating cost'; fa = 'An error occurred when calculating cost';
																	|it = 'Ошибка при расчете себестоимости';
																	|pl = 'An error occurred when calculating cost';
																	|tr = 'Maliyet hesaplama sırasında hata'", DefaultLanguageCode));
	
	
	MatchingErrorTypeToStageName.Insert(NStr("vi = 'Phản ánh vào kế toán quốc tế';
											|ru = 'Отражение в международном учете';
											|en = 'General ledger posting'; fa = 'ثبت در دفتر کل';
											|it = 'Visualizzazione in contabilità internazionale';
											|pl = 'Odzwierciedlenie w ewidencji międzynarodowej';
											|tr = 'Uluslararası muhasebede geçerlilik'", DefaultLanguageCode),
		NStr("vi = 'Lỗi khi phản ánh chứng từ vào kế toán quốc tế';
			|ru = 'Ошибка при отражении документов в международном учете';
			|en = 'An error occurred when recording documents in financial accounting'; fa = 'An error occurred when recording documents in financial accounting';
			|it = 'Ошибка при отражении документов в международном учете';
			|pl = 'An error occurred when recording documents in financial accounting';
			|tr = 'Finansal muhasebeye belge kaydetme sırasında hata'", DefaultLanguageCode));
	ErrorType = MatchingErrorTypeToStageName.Get(SectionName);
	
	Return ?(ValueIsFilled(ErrorType), ErrorType, SectionName);
	
EndFunction

&AtClientAtServerNoContext
Function PresentationOfTestingStage(TestingPhase)
	
	MatchingPresentationToStage = New Map;
	
	MatchingPresentationToStage.Insert("ReOrderMonth", NStr("vi = 'Tính đóng tháng';
															|ru = 'Расчет закрытия месяца';
															|en = 'Month-end closing calculation'; fa = 'Month-end closing calculation';
															|it = 'Расчет закрытия месяца';
															|pl = 'Month-end closing calculation';
															|tr = 'Ay sonu kapanış hesaplaması'"));
	MatchingPresentationToStage.Insert("SwitchingToNewSettlements", NStr("vi = 'Chuyển sang cấu trúc hạch toán công nợ mới';
																		|ru = 'Переход на новую архитектура взаиморасчетов';
																		|en = 'Migrate to a new AR/AP configuration'; fa = 'Migrate to a new AR/AP configuration';
																		|it = 'Переход на новую архитектура взаиморасчетов';
																		|pl = 'Migrate to a new AR/AP configuration';
																		|tr = 'Yeni alacak/borç yapılandırmasına geçiş'"));
	MatchingPresentationToStage.Insert("ReFillInNewSettlements", NStr("vi = 'Điền lại hạch toán công nợ theo cấu trúc mới';
																		|ru = 'Перезаполнение взаиморасчетов по новой архитектуре';
																		|en = 'Refill AR/AP accounting based on the new configuration'; fa = 'Refill AR/AP accounting based on the new configuration';
																		|it = 'Перезаполнение взаиморасчетов по новой архитектуре';
																		|pl = 'Refill AR/AP accounting based on the new configuration';
																		|tr = 'Yeni yapılandırmaya göre alacak/borç muhasebesinin yeniden doldurulması'"));
	
	Presentation = MatchingPresentationToStage.Get(TestingPhase);
	
	Return ?(ValueIsFilled(Presentation), Presentation, MatchingPresentationToStage.Get("ReOrderMonth"));
	
EndFunction

&AtClient
Procedure SupplementErrorWithDiscrepanciesOfInfluencingStages(CurrentStep, Error, DiscrepancyData)
	
	AdditionalClarificationOfLocation = "";
	AdditionalPlaybackOrder = "";
	
	If CurrentStep = "VAT" Then
		DiscrepanciesSettlementsWithPartners = DiscrepancyData.Get("MutualSettlementsWithPartners");
		If DiscrepanciesSettlementsWithPartners <> Undefined Then
			Error.FilesNames.Add(DiscrepanciesSettlementsWithPartners);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Hạch toán công nợ với bạn hàng';
					|ru = 'Взаиморасчеты с партнерами';
					|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
					|it = 'Regolazioni con i partner';
					|pl = 'Rozliczenia wzajemne z partnerami';
					|tr = 'İş ortaklarıyla mutabakatlar'") + ": " + DiscrepanciesSettlementsWithPartners;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Hạch toán công nợ với bạn hàng';
																						|ru = 'Взаиморасчеты с партнерами';
																						|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
																						|it = 'Regolazioni con i partner';
																						|pl = 'Rozliczenia wzajemne z partnerami';
																						|tr = 'İş ortaklarıyla mutabakatlar'") + ";";
		EndIf;
		CostDiscrepancies = DiscrepancyData.Get("Cost_");
		If CostDiscrepancies <> Undefined Then
			Error.FilesNames.Add(CostDiscrepancies);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Giá vốn';
					|ru = 'Себестоимость';
					|en = 'Cost'; fa = 'بهای تمام‌شده';
					|it = 'Себестоимость';
					|pl = 'Cost';
					|tr = 'Maliyet'") + ": " + CostDiscrepancies;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Giá vốn';
																						|ru = 'Себестоимость';
																						|en = 'Cost'; fa = 'بهای تمام‌شده';
																						|it = 'Себестоимость';
																						|pl = 'Koszty własne';
																						|tr = 'Maliyet'") + ";";
		EndIf;
	EndIf;
	
	If CurrentStep = "USN" Then
		DiscrepanciesSettlementsWithPartners = DiscrepancyData.Get("MutualSettlementsWithPartners");
		If DiscrepanciesSettlementsWithPartners <> Undefined Then
			Error.FilesNames.Add(DiscrepanciesSettlementsWithPartners);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Hạch toán công nợ với bạn hàng';
					|ru = 'Взаиморасчеты с партнерами';
					|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
					|it = 'Regolazioni con i partner';
					|pl = 'Rozliczenia wzajemne z partnerami';
					|tr = 'İş ortaklarıyla mutabakatlar'") + ": " + DiscrepanciesSettlementsWithPartners;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Hạch toán công nợ với bạn hàng';
																						|ru = 'Взаиморасчеты с партнерами';
																						|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
																						|it = 'Regolazioni con i partner';
																						|pl = 'Rozliczenia wzajemne z partnerami';
																						|tr = 'İş ortaklarıyla mutabakatlar'") + ";";
		EndIf;
		CostDiscrepancies = DiscrepancyData.Get("Cost_");
		If CostDiscrepancies <> Undefined Then
			Error.FilesNames.Add(CostDiscrepancies);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Giá vốn';
					|ru = 'Себестоимость';
					|en = 'Cost'; fa = 'بهای تمام‌شده';
					|it = 'Себестоимость';
					|pl = 'Cost';
					|tr = 'Maliyet'") + ": " + CostDiscrepancies;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Giá vốn';
																						|ru = 'Себестоимость';
																						|en = 'Cost'; fa = 'بهای تمام‌شده';
																						|it = 'Себестоимость';
																						|pl = 'Koszty własne';
																						|tr = 'Maliyet'") + ";";
		EndIf;
	EndIf;
	
	If CurrentStep = "LocalAccnting" Then
		DiscrepanciesSettlementsWithPartners = DiscrepancyData.Get("MutualSettlementsWithPartners");
		If DiscrepanciesSettlementsWithPartners <> Undefined Then
			Error.FilesNames.Add(DiscrepanciesSettlementsWithPartners);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Hạch toán công nợ với bạn hàng';
					|ru = 'Взаиморасчеты с партнерами';
					|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
					|it = 'Regolazioni con i partner';
					|pl = 'Rozliczenia wzajemne z partnerami';
					|tr = 'İş ortaklarıyla mutabakatlar'") + ": " + DiscrepanciesSettlementsWithPartners;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Hạch toán công nợ với bạn hàng';
																						|ru = 'Взаиморасчеты с партнерами';
																						|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
																						|it = 'Regolazioni con i partner';
																						|pl = 'Rozliczenia wzajemne z partnerami';
																						|tr = 'İş ortaklarıyla mutabakatlar'") + ";";
		EndIf;
		CostDiscrepancies = DiscrepancyData.Get("Cost_");
		If CostDiscrepancies <> Undefined Then
			Error.FilesNames.Add(CostDiscrepancies);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Giá vốn';
					|ru = 'Себестоимость';
					|en = 'Cost'; fa = 'بهای تمام‌شده';
					|it = 'Себестоимость';
					|pl = 'Cost';
					|tr = 'Maliyet'") + ": " + CostDiscrepancies;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Giá vốn';
																						|ru = 'Себестоимость';
																						|en = 'Cost'; fa = 'بهای تمام‌شده';
																						|it = 'Себестоимость';
																						|pl = 'Koszty własne';
																						|tr = 'Maliyet'") + ";";
		EndIf;
		VATDiscrepancies = DiscrepancyData.Get("VAT");
		If VATDiscrepancies <> Undefined Then
			Error.FilesNames.Add(VATDiscrepancies);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Thuế GTGT';
					|ru = 'НДС';
					|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
					|it = 'НДС';
					|pl = 'VAT';
					|tr = 'KDV'") + ": " + VATDiscrepancies;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Thuế GTGT';
																						|ru = 'НДС';
																						|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
																						|it = 'НДС';
																						|pl = 'VAT';
																						|tr = 'KDV'") + ";";
		EndIf;
	EndIf;
	
	If CurrentStep = "FinancialAccounting" Then
		DiscrepanciesSettlementsWithPartners = DiscrepancyData.Get("MutualSettlementsWithPartners");
		If DiscrepanciesSettlementsWithPartners <> Undefined Then
			Error.FilesNames.Add(DiscrepanciesSettlementsWithPartners);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Hạch toán công nợ với bạn hàng';
					|ru = 'Взаиморасчеты с партнерами';
					|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
					|it = 'Regolazioni con i partner';
					|pl = 'Rozliczenia wzajemne z partnerami';
					|tr = 'İş ortaklarıyla mutabakatlar'") + ": " + DiscrepanciesSettlementsWithPartners;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Hạch toán công nợ với bạn hàng';
																						|ru = 'Взаиморасчеты с партнерами';
																						|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
																						|it = 'Regolazioni con i partner';
																						|pl = 'Rozliczenia wzajemne z partnerami';
																						|tr = 'İş ortaklarıyla mutabakatlar'") + ";";
		EndIf;
		CostDiscrepancies = DiscrepancyData.Get("Cost_");
		If CostDiscrepancies <> Undefined Then
			Error.FilesNames.Add(CostDiscrepancies);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Giá vốn';
					|ru = 'Себестоимость';
					|en = 'Cost'; fa = 'بهای تمام‌شده';
					|it = 'Себестоимость';
					|pl = 'Cost';
					|tr = 'Maliyet'") + ": " + CostDiscrepancies;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Giá vốn';
																						|ru = 'Себестоимость';
																						|en = 'Cost'; fa = 'بهای تمام‌شده';
																						|it = 'Себестоимость';
																						|pl = 'Koszty własne';
																						|tr = 'Maliyet'") + ";";
		EndIf;
		DiscrepanciesInLocalAccounting = DiscrepancyData.Get("LocalAccnting");
		If DiscrepanciesInLocalAccounting <> Undefined Then
			Error.FilesNames.Add(DiscrepanciesInLocalAccounting);
			AdditionalClarificationOfLocation = AdditionalClarificationOfLocation + Chars.LF + "- " +
				NStr("vi = 'Kế toán tài chính';
					|ru = 'Регл. учет';
					|en = 'Local accounting'; fa = 'حسابداری محلی';
					|it = 'Contabilità regolamentata';
					|pl = 'Ewidenc. regl.';
					|tr = 'Regl. kayıt'") + ": " + DiscrepanciesInLocalAccounting;
			AdditionalPlaybackOrder = AdditionalPlaybackOrder + Chars.LF + "- " + NStr("vi = 'Kế toán tài chính';
																						|ru = 'Регл. учет';
																						|en = 'Local accounting'; fa = 'حسابداری محلی';
																						|it = 'Contabilità regolamentata';
																						|pl = 'Ewidenc. regl.';
																						|tr = 'Regl. kayıt'") + ";";
		EndIf;
	EndIf;
	
	If ValueIsFilled(AdditionalClarificationOfLocation) Then
		Error.LocationClarification = Error.LocationClarification + Chars.LF +
			NStr("vi = 'Tệp sai lệch theo các biểu ghi bổ sung:';
				|ru = 'Файлы с расхождениями по дополнительным регистрам:';
				|en = 'Files with discrepancies by additional registers:'; fa = 'Files with discrepancies by additional registers:';
				|it = 'Файлы с расхождениями по дополнительным регистрам:';
				|pl = 'Files with discrepancies by additional registers:';
				|tr = 'Ek kayıtlarda tutarsızlık olan dosyalar:'") + AdditionalClarificationOfLocation;
	EndIf;
	If ValueIsFilled(AdditionalPlaybackOrder) Then
		Error.PlaybackOrder = Error.PlaybackOrder + Chars.LF +
			NStr("vi = 'Có khác biệt theo các công đoạn ảnh hưởng đến công đoạn hiện tại:';
				|ru = 'Так же есть отличия по этапам влияющим на текущий:';
				|en = 'There are also differences in steps affecting the current one:'; fa = 'There are also differences in steps affecting the current one:';
				|it = 'Так же есть отличия по этапам влияющим на текущий:';
				|pl = 'There are also differences in steps affecting the current one:';
				|tr = 'Mevcut olanı etkileyen aşamalarda da farklılıklar vardır:'") + AdditionalPlaybackOrder;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterPutFile(Result, Address, SelectedFileName, AdditionalParameters) Export  

	ReportParameters = New Structure("PathToFile, GenerateOnOpen", Address, True);
	OpenForm("Report.TestResults.Form.ReportForm", ReportParameters, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_CheckTaskCompletion()
	
	Job = CheckJobCompletion();
	Status = Job.Status;
	
	If Job.Progress <> Undefined Then
		ProgressAsString = ProgressAsString(Job.Progress);
		If Not IsBlankString(ProgressAsString) Then
			Items.CalculationTitleInTheBackground.Title = NStr("vi = 'Đang thực hiện giao dịch đóng tháng ...';
																|ru = 'Выполняются операции закрытия месяца ....';
																|en = 'Month-end closing operations are in progress...'; fa = 'عملیات بستن پایان ماه در حال انجام است...';
																|it = 'Le operazioni vengono eseguite chiusura di fine periodo...';
																|pl = 'Trwa wykonywanie operacji zamknięcia miesiąca ....';
																|tr = 'Ay sonu kapanış işlemleri gerçekleştiriliyor ....'") + " " + ProgressAsString;
		EndIf;
	EndIf;
	If Job.Messages <> Undefined Then
		If Job.Progress <> Undefined And Job.Messages.Count() Then
			ErrorMessage.AddLine(Job.Progress.Text + ":");
		EndIf;
		For Each UserMessage In Job.Messages Do
			ErrorMessage.AddLine(UserMessage.Text);
		EndDo;
	EndIf;
	
	If Status = "Completed2" Then
		
		ProcessTestResult();
		JobID = Undefined;
		ChangesInInterfaceWhenWorkingInBackground();
		
	ElsIf Status = "Error" Then
		
		Error = CreateErrorDescription();
		Error.ErrorType = "Error oftesting";
		Error.PlaybackOrder = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra lỗi nghiêm trọng khi thử nghiệm.
			|Tháng bắt đầu tính toán: %1
			|Ngày khởi động: %2
			|Ngày kết thúc: %3';
			|ru = 'Возникла критичная ошибка при тестировании.
			|Месяц начала расчета: %1
			|Дата запуска: %2
			|Дата завершения: %3';
			|en = 'A critical error occurred when testing. 
			|Calculation start month: %1
			|Start date: %2
			|End date: %3'; fa = 'A critical error occurred when testing. 
			|Calculation start month: %1
			|Start date: %2
			|End date: %3';
			|it = 'Возникла критичная ошибка при тестировании.
			|Месяц начала расчета: %1
			|Дата запуска: %2
			|Дата завершения: %3';
			|pl = 'A critical error occurred when testing. 
			|Calculation start month: %1
			|Start date: %2
			|End date: %3';
			|tr = 'Test sırasında kritik hata oluştu.
			|Başlangıç ayı: %1
			| Başlangıç tarihi: %2
			|Bitiş tarihi: %3'"),
			CalculationStart,
			StartDate,
			EndDate);
		Error.SourceInformation = Job.DetailErrorDescription;
		Error.MetadataObject = "";
		Error.LocationClarification = "";
		Errors.Add(XMLErrorText(Error));
		
		ReportError(Error);
		JobID = Undefined;
		ChangesInInterfaceWhenWorkingInBackground();
		
	EndIf;
	
	If Status = "Running" Then
		TimeConsumingOperationsClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		AttachIdleHandler("Attachable_CheckTaskCompletion", IdleHandlerParameters.CurrentInterval, True);
	EndIf;
	
EndProcedure

&AtClient
Function ProgressAsString(Progress)
	
	Result = "";
	If Progress = Undefined Then
		Return Result;
	EndIf;
	
	Percent = 0;
	If Progress.Property("Percent", Percent) Then
		Result = String(Percent) + "%";
	EndIf;
	Text = 0;
	If Progress.Property("Text", Text) Then
		If Not IsBlankString(Result) Then
			Result = Result + " (" + Text + ")";
		Else
			Result = Text;
		EndIf;
	EndIf;

	Return Result;
	
EndFunction

&AtServer
Function CheckJobCompletion()
	
	Job = TimeConsumingOperations.ActionCompleted(JobID);
	
	Return Job;
	
EndFunction

&AtServer
Function CancelMonthClosingBackgroundJob()
	
	If Not ValueIsFilled(JobID) Then
		Result = True;
	Else
		Result = MonthEndTransactionsServer.CancelBackgroundJob_(JobID);
		InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag();
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items["TestingTreeURL"].Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "TestingTree.NumberOfDiscrepancies", 0);
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không tìm thấy';
													|ru = 'Не найдено';
													|en = 'Not found'; fa = 'یافت نشد';
													|it = 'Non trovato';
													|pl = 'Nie znaleziono';
													|tr = 'Bulunamadı'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

#EndRegion

