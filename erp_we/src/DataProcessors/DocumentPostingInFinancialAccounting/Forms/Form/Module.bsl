#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("EndingDateOfPeriod") Then
		EndingDateOfPeriod = Parameters.EndingDateOfPeriod;
	EndIf;
	
	If Parameters.Property("Organization") Then
		Organization = Parameters.Organization;
		ManagingFormElementsWhenOrganizationChanges();
	EndIf;
	
	If Parameters.Property("ChartOfAccounts") Then
		ChartOfAccounts = Parameters.ChartOfAccounts;
	EndIf;
	
	FOData = New Structure;
	FOData.Insert("DocumentVerification", GetFunctionalOption("UseFinancialDocumentVerification"));
	
	Items.GroupStatusOfDocumentVerificationForReVerification.Visible = FOData.DocumentVerification;
	
	AdditionalParameters = New Structure;
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	GetStateOfRoutineTask();
	ManagingFormElementsWhenChangingAutomaticReflectionInAccounting();
	
	UpdateDataOnStateOfDocumentsAndTransactionGenerationSettings();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshSchedulePresentation();
	UpdateDataOnStateOfDocumentVerification();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	ExternalEvents = New Array;
	ExternalEvents.Add("Write_DocumentPostingInFinancialAccounting");
	ExternalEvents.Add("CompletedConfigurationOfInternationalAccountingTransactionTemplates");
	ExternalEvents.Add("FormForSettingUpRequiredAccountingRulesIsClosed");
	ExternalEvents.Add("ChangedDateWhenTransactionsWereBanned");
	
	If ExternalEvents.Find(EventName) <> Undefined Then
		NotificationProcessingServer(EventName);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("EndingDateOfPeriod") Then
		EndingDateOfPeriod = Parameters.EndingDateOfPeriod;
	EndIf;
	
	If Parameters.Property("Organization") Then
		Organization = Parameters.Organization;
	Else
		ManagingFormElementsWhenOrganizationChanges();
	EndIf;

	If Parameters.Property("ChartOfAccounts") Then
		ChartOfAccounts = Parameters.ChartOfAccounts;
	EndIf;
	
	UpdateDataOnStateOfDocumentsAndTransactionGenerationSettings();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	UpdateDataOnStateOfDocumentVerification();
	
EndProcedure

&AtClient
Procedure EndingDateOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EndDateOfPeriodOnChangeAtServer();
	UpdateDataOnStateOfDocumentVerification();
	
EndProcedure

&AtClient
Procedure StatusForRecordingInAccountingClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusThereAreNoAccountingRecordingRulesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure TheStatusIsExpectedToBeReflectedInReglAccountingClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusBrokenDoubleEntryFinancialRegistersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure ConfigureRulesOfRecordingInAccountingClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Organization);
	FormParameters.Insert("AddressValidationResult", AddressValidationResult);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.RequiredRecordingRules", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusRecordedInAccountingClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusForRecordingInTheClosedPeriodClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	FormParameters.Insert("PeriodEndClosingDate", PeriodEndClosingDate);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusForManualRecordingInAccountingClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusRecordedInAccountingManuallyClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting");
	FormParameters = InitializeDocumentListFormParameters(ReflectionStatus);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure UseAutomaticReflectionInAccountingOnChange(Item)
	
	SaveDetailsOfRoutineTask();
	
EndProcedure

&AtClient
Procedure SchedulePresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	EditScheduledJobSchedule();
	
EndProcedure

&AtClient
Procedure StatusOfVerifiedDocumentsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = InitializeDocumentListFormParameters();
	CheckStatus = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified");
	FormParameters.Filter.Insert("CheckStatus", CheckStatus);
	
	OpenForm("InformationRegister.StatusOfDocumentVerification.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusOfUnverifiedDocumentsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = InitializeDocumentListFormParameters();
	CheckStatus = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified");
	FormParameters.Filter.Insert("CheckStatus", CheckStatus);
	
	OpenForm("InformationRegister.StatusOfDocumentVerification.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure StatusOfDocumentsToBeCheckedClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = InitializeDocumentListFormParameters();
	CheckStatus = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck");
	FormParameters.Filter.Insert("CheckStatus", CheckStatus);
	
	OpenForm("InformationRegister.StatusOfDocumentVerification.Form.DocumentJournal", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	ChartOfAccountsWhenChangedOnServer();
	UpdateDataOnStateOfDocumentVerification();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RefreshStatus(Command)
	
	UpdateDataOnStateOfDocumentsAndTransactionGenerationSettings();
	UpdateDataOnStateOfDocumentVerification();
	
EndProcedure

&AtClient
Procedure RecordTheDocumentsInInternationalAccounting(Command)
	
	TimeConsumingOperation = StartReflectingDocumentsInInternationalAccounting(Organization, EndingDateOfPeriod, UUID);
	
	CallbackOnCompletion = New CallbackDescription("ProcessResultOfDocumentsReflection", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.Title = NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
								|ru = 'Отражение документов в международном учете';
								|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
								|it = 'Visualizzazione dei documenti in contabilità internazionale';
								|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
								|tr = 'Finansal muhasebede belge kaydı'");
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
 
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
 
EndProcedure

&AtClient
Procedure SetClosingDate(Command)
	
	OpenForm("InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration.Form.ClosingDatesOfAccountingPostingGeneration", , ThisForm);
	
EndProcedure


&AtClient
Procedure SetUpTransactionTemplates(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.Organization = Organization;
	FormParameters.ChartOfAccounts = ChartOfAccounts;
	FinancialAccountingUponOperationalAccountingDataClient.OpenSettingsForTransactionTemplates(FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ConfiguringInvoicesForAccountingObjects(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.Organization = Organization;
	FormParameters.ChartOfAccounts = ChartOfAccounts;
	FinancialAccountingByFinancialRegisterDataClient.OpenInvoiceSettingsForAccountingObjects(FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure SetUpCorrespondenceBetweenAccountsAndTurnovers(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.Organization = Organization;
	FormParameters.ChartOfAccounts = ChartOfAccounts;
	FinancialAccountingUponLocalAccountingClient.OpenAccountsAndTurnoverMatchingSettings(FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region Private

#Region Overall

&AtServerNoContext
Function StartReflectingDocumentsInInternationalAccounting(Organization, EndDate, FormIdentifier)
	
	ReflectionParameters = FinancialAccountingPostingServer.ReflectionParametersInInternationalAccounting();
	ReflectionParameters.Companies = Organization;
	ReflectionParameters.EndDate = EndDate;
	
	Return FinancialAccountingPostingServer.StartReflectionInInternationalAccounting(ReflectionParameters, FormIdentifier);
	
EndFunction

&AtClient
Procedure ProcessResultOfDocumentsReflection(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result.Status = "Error" Then
		MessageText = NStr("vi = 'Khi phản ánh chứng từ vào kế toán quốc tế, đã xảy ra lỗi:
			|%1';
			|ru = 'При отражении документов в международном учете произошла ошибка:
			|%1';
			|en = 'An error occurred when recording documents in financial accounting:
			|%1'; fa = 'An error occurred when recording documents in financial accounting:
			|%1';
			|it = 'При отражении документов в международном учете произошла ошибка:
			|%1';
			|pl = 'An error occurred when recording documents in financial accounting:
			|%1';
			|tr = 'Uluslararası muhasebeye belgeler yansıtılırken bir hata oluştu:
			|%1'");
		
		If Result = Undefined Then
			DecryptionText = NStr("vi = 'Không tìm thấy nhiệm vụ đang thực hiện.';
									|ru = 'Не найдено выполняемое задание.';
									|en = 'Job in progress is not found.'; fa = 'Job in progress is not found.';
									|it = 'Не найдено выполняемое задание.';
									|pl = 'Job in progress is not found.';
									|tr = 'Yürütülmekte olan görev bulunamadı.'");
		ElsIf ValueIsFilled(Result.BriefErrorDescription) Then
			DecryptionText = Result.BriefErrorDescription;
		Else
			DecryptionText = NStr("vi = 'Chi tiết xem trong Nhật ký sự kiện.';
									|ru = 'Подробности см. в Журнале регистрации.';
									|en = 'For more information, see the event log.'; fa = 'For more information, see the event log.';
									|it = 'Подробности см. в Журнале регистрации.';
									|pl = 'For more information, see the event log.';
									|tr = 'Ayrıntılar için Olay günlüğüne bakın.'");
		EndIf;
		
		MessageText = StrTemplate(MessageText, DecryptionText);

		Raise MessageText;
	EndIf;
	
	ProcessResultOfDocumentReflectionOnServer();
	
EndProcedure

&AtServer
Procedure ProcessResultOfDocumentReflectionOnServer()
	
	GetDocumentReflectionState();
	
	GetOperationsThatRequireTemplateConfiguration();
	
EndProcedure

&AtServer
Procedure GetDocumentReflectionState()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentReflection.DateRecord AS DateRecord,
	|	DocumentReflection.Recorder AS Recorder,
	|	DocumentReflection.Status AS Status
	|INTO DocumentReflection
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|WHERE
	|	(&AnyOrganization OR DocumentReflection.Organization = &Organization)
	|	AND (&AnyChartOfAccounts OR DocumentReflection.ChartOfAccounts = &ChartOfAccounts)
	|	AND DocumentReflection.DateRecord <= &EndDate
	|	AND VALUETYPE(DocumentReflection.Recorder) IN (&ListOfDocumentTypes)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentReflection.DateRecord) AS StartDate
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting)
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DocumentReflection.DateRecord) AS StartDate
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting)
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting)
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting)
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined)
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting)
	|	AND DocumentReflection.DateRecord <= &PeriodEndClosingDate
	|HAVING
	|	COUNT(DISTINCT DocumentReflection.Recorder) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken)
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("AnyOrganization", Not ValueIsFilled(Organization));
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("AnyChartOfAccounts", Not ValueIsFilled(ChartOfAccounts));
	Query.SetParameter("EndDate", ?(ValueIsFilled(EndingDateOfPeriod), EndingDateOfPeriod, Date(2399, 1, 1)));
	Query.SetParameter("PeriodEndClosingDate", PeriodEndClosingDate);
	Query.SetParameter("ListOfDocumentTypes", DataProcessors.DocumentPostingInFinancialAccounting.TypesOfDocumentsForSelection());
	ResultsArray = Query.ExecuteBatch();
	
	Selection = ResultsArray[1].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'Chứng từ thủ công, %Date%';
							|ru = 'Документы, отраженные в учете вручную, по %Date%';
							|en = 'Documents posted in financial accounting manually, up to %Date%'; fa = 'Documents posted in financial accounting manually, up to %Date%';
							|it = 'Documenti rilevati nella contabilità manualmente %Date%';
							|pl = 'Dokumenty, odzwierciedlone w ewidencji ręcznie, do %Date%';
							|tr = '%Date% tarihine göre muhasebeye manuel yansıtılan belgeler'");
		StatusRecordedInAccountingManually = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
		Items.StatusRecordedInAccountingManually.TextColor = StyleColors.HyperlinkColor;
		Items.StatusRecordedInAccountingManually.Hyperlink = True;
	Else
		StatusRecordedInAccountingManually = NStr("vi = 'Không có chứng từ phản ánh thủ công trong kế toán quốc tế.';
													|ru = 'Нет документов, отраженных в международном учете вручную.';
													|en = 'No documents which are manually recorded in financial accounting.'; fa = 'No documents which are manually recorded in financial accounting.';
													|it = 'Non ci sono documenti rilevati nella contabilità manuale internazionale.';
													|pl = 'Brak dokumentów, odzwierciedlonych w międzynarodowej ewidencji ręcznie.';
													|tr = 'Uluslararası muhasebeye manuel olarak yansıyan herhangi bir belge bulunmamaktadır.'");
		Items.StatusRecordedInAccountingManually.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
		Items.StatusRecordedInAccountingManually.Hyperlink = False;
	EndIf;
	
	Selection = ResultsArray[2].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'Chứng từ đang chờ phản ánh thủ công trong kế toán quốc tế (%Count%), với %Date%';
							|ru = 'Документы, ожидающие ручного отражения в международном учете (%Count%), с %Date%';
							|en = 'Documents awaiting manual financial accounting recording (%Count%), from %Date%'; fa = 'Documents awaiting manual financial accounting recording (%Count%), from %Date%';
							|it = 'Documenti in attesa di rilevazione manuale nella contabilità internazionale (%Count%), с %Date%';
							|pl = 'Dokumenty oczekujące ręcznego odzwierciedlenia w międzynarodowej ewidencji (%Count%), od %Date%';
							|tr = 'Uluslararası muhasebede manüel olarak yansıtılmayı bekleyen belgeler %Count%), başlangıç ​​%Date%'");
		StatusText = StrReplace(StatusText, "%Count%", Selection.Count);
		StatusForManualRecordingInAccounting = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
		Items.StatusForManualRecordingInAccounting.TextColor = StyleColors.HyperlinkColor;
		Items.StatusForManualRecordingInAccounting.Hyperlink = True;
	Else
		StatusForManualRecordingInAccounting = NStr("vi = 'Không có chứng từ chờ phản ánh thủ công trong kế toán quốc tế.';
													|ru = 'Нет документов, ожидающих ручного отражения в международном учете.';
													|en = 'No documents awaiting manual financial accounting recording.'; fa = 'No documents awaiting manual financial accounting recording.';
													|it = 'Non ci sono documenti in attesa di rilevazione manuale nella contabilità internazionale.';
													|pl = 'Brak dokumentów, oczekujących ręcznego odzwierciedlenia w międzynarodowej ewidencji.';
													|tr = 'Uluslararası muhasebeye manuel yansıtılmayı bekleyen herhangi bir belge bulunmamaktadır.'");
		Items.StatusForManualRecordingInAccounting.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
		Items.StatusForManualRecordingInAccounting.Hyperlink = False;
	EndIf;
	
	Selection = ResultsArray[3].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'Chứng từ phản ánh, %Date%';
							|ru = 'Отраженные в учете документы, по %Date%';
							|en = 'Documents recorded in accounting, up to %Date%'; fa = 'Documents recorded in accounting, up to %Date%';
							|it = 'Documenti rilevati nella contabilità manualmente, per %Date%';
							|pl = 'Odzwierciedlone w ewidencji dokumenty, do %Date%';
							|tr = '%Date% tarihine kadar muhasebeye kaydedilen belgeler'");
		StatusRecordedInAccounting = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
		Items.StatusRecordedInAccounting.TextColor = StyleColors.HyperlinkColor;
		Items.StatusRecordedInAccounting.Hyperlink = True;
		
		TransactionsMayChange = "";
		TasksNotCompleted = FinancialAccountingOfMonthEndClosing.OutstandingDeferredTasks(
			Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting, Selection.StartDate, Organization, Undefined, True);
		If TasksNotCompleted.Count() > 0 Then
			TasksNotCompleted.Add(NStr("vi = 'Có thể thay đổi bút toán của chứng từ đã phản ánh vào kế toán.';
										|ru = 'Проводки отраженных в учете документов могут измениться.';
										|en = 'Entries of the documents recorded in accounting might change.'; fa = 'Entries of the documents recorded in accounting might change.';
										|it = 'Проводки отраженных в учете документов могут измениться.';
										|pl = 'Entries of the documents recorded in accounting might change.';
										|tr = 'Muhasebe belgelerine yansıyan girişler değişebilir.'"));
			TransactionsMayChange = New FormattedString(
				StrConcat(TasksNotCompleted, " "),,
				StyleColors.HelpText);
		EndIf;
		Items.TransactionGroupMayChange.Visible = ValueIsFilled(TransactionsMayChange);
	Else
		StatusRecordedInAccounting = NStr("vi = 'Không có chứng từ phản ánh trong kế toán quốc tế.';
											|ru = 'Нет документов, отраженных в международном учете.';
											|en = 'No documents recorded in financial accounting.'; fa = 'No documents recorded in financial accounting.';
											|it = 'Non ci sono documenti rilevati nella contabilità internazionale.';
											|pl = 'Brak dokumentów, odzwierciedlonych w międzynarodowej ewidencji.';
											|tr = 'Uluslararası muhasebeye yansıyan herhangi bir belge bulunmamaktadır.'");
		Items.StatusRecordedInAccounting.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
		Items.StatusRecordedInAccounting.Hyperlink = False;
		Items.TransactionGroupMayChange.Visible = False;
	EndIf;
	
	Selection = ResultsArray[4].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'Chứng từ đang chờ phản ánh tự động trong kế toán quốc tế (%Count%), với %Date%';
							|ru = 'Документы, ожидающие автоматического отражения в международном учете (%Count%), с %Date%';
							|en = 'Documents awaiting automatic financial accounting recording (%Count%), from %Date%'; fa = 'Documents awaiting automatic financial accounting recording (%Count%), from %Date%';
							|it = 'Documenti in attesa di rilevazione manuale nella contabilità internazionale (%Count%), dal %Date%';
							|pl = 'Dokumenty oczekujące na automatyczne odzwierciedlenie w międzynarodowej ewidencji. (%Count%), od %Date%';
							|tr = 'Uluslararası muhasebede otomatik olarak yansıtılmayı bekleyen belgeler %Count%), başlangıç ​​%Date%'");
		StatusText = StrReplace(StatusText, "%Count%", Selection.Count);
		StatusForRecordingInAccounting = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
		Items.StatusForRecordingInAccounting.TextColor = StyleColors.HyperlinkColor;
		Items.StatusForRecordingInAccounting.Hyperlink = True;
	Else
		StatusForRecordingInAccounting = NStr("vi = 'Không có chứng từ chờ phản ánh tự động trong kế toán quốc tế.';
												|ru = 'Нет документов, ожидающих автоматического отражения в международном учете.';
												|en = 'No documents awaiting automatic financial accounting recording.'; fa = 'No documents awaiting automatic financial accounting recording.';
												|it = 'Non ci sono documenti in attesa di rilevazione manuale nella contabilità internazionale.';
												|pl = 'Brak dokumentów, oczekujących na automatyczne odzwierciedlenie w międzynarodowej ewidencji.';
												|tr = 'Uluslararası muhasebeye otomatik yansıtılmayı bekleyen herhangi bir belge bulunmamaktadır.'");
		Items.StatusForRecordingInAccounting.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
		Items.StatusForRecordingInAccounting.Hyperlink = False;
	EndIf;
	
	Selection = ResultsArray[5].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'Chứng từ không được phản ánh trong kế toán vì kỳ vọng phản ánh trong regl. kế toán ( %Count%), s %Date%';
							|ru = 'Документы не отраженные в учете из-за ожидания отражения в регл. учете (%Count%), с %Date%';
							|en = 'Documents not recorded awaiting recording in local accounting (%Count%), from %Date%'; fa = 'Documents not recorded awaiting recording in local accounting (%Count%), from %Date%';
							|it = 'Documenti non rilevati nella contabilità a causa dell''attesa di una rilevazione in contabilità regolatoria (%Count%), с %Date%';
							|pl = 'Dokumenty nie odzwierciedlone w ewidencji z powodu oczekiwania na odzwierciedlenie w regl. ewidencji (%Count%), od%Date%';
							|tr = 'Yerel muhasebede yansıtılmayı beklediği için muhasebeye yansıtılmayan belgeler (%Count%), %Date% itibaren'");
		StatusText = StrReplace(StatusText, "%Count%", Selection.Count);
		TheStatusIsExpectedToBeReflectedInReglAccounting = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
		Items.TheStatusIsExpectedToBeReflectedInReglAccounting.TextColor = StyleColors.HyperlinkColor;
		Items.TheStatusIsExpectedToBeReflectedInReglAccounting.Hyperlink = True;
		Items.TheStatusIsExpectedToBeReflectedInReglAccounting.Visible = True;
	Else
		Items.TheStatusIsExpectedToBeReflectedInReglAccounting.Visible = False;
	EndIf;
	
	Selection = ResultsArray[6].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'Chứng từ không được phản ánh do lỗi (%Count%), với %Date%';
							|ru = 'Документы не отраженные в учете из-за ошибок (%Count%), с %Date%';
							|en = 'Documents not recorded in accounting due to errors (%Count%), from %Date%'; fa = 'Documents not recorded in accounting due to errors (%Count%), from %Date%';
							|it = 'Documenti non rilevati nell''account a causa di errori (%Count%), dal %Date%';
							|pl = 'Dokumenty nie odzwierciedlone w ewidencji z powodu błędów (%Count%), od %Date%';
							|tr = 'Hata nedeniyle muhasebeye yansımayan belgeler (%Count%), %Date% itibaren'");
		StatusText = StrReplace(StatusText, "%Count%", Selection.Count);
		StatusThereAreNoAccountingRecordingRules = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
		Items.StatusThereAreNoAccountingRecordingRules.TextColor = StyleColors.OverdueDataColor;
		Items.StatusThereAreNoAccountingRecordingRules.Hyperlink = True;
		Items.StatusThereAreNoAccountingRecordingRules.Visible = True;
	Else
		Items.StatusThereAreNoAccountingRecordingRules.Visible = False;
	EndIf;

	Selection = ResultsArray[7].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'bao gồm trong giai đoạn đóng (%Count%)';
							|ru = 'в том числе в закрытом периоде (%Count%)';
							|en = 'including in the closed period (%Count%)'; fa = 'including in the closed period (%Count%)';
							|it = 'compreso nel periodo chiuso  (%Count%)';
							|pl = 'w tym, w okresie zamkniętym (%Count%)';
							|tr = 'kapalı dönem dahil (%Count%)'");
		StatusText = StrReplace(StatusText, "%Count%", Selection.Count);
		StatusText = StrReplace(StatusText, "%Date%", Format(PeriodEndClosingDate, "DLF=D"));
		StatusForRecordingInTheClosedPeriod = StatusText;
		Items.StatusForRecordingInTheClosedPeriod.TextColor = StyleColors.OverdueDataColor;
		Items.TheGroupClosedPeriod.Visible = True;
	Else
		Items.TheGroupClosedPeriod.Visible = False;
	EndIf;
	
	Selection = ResultsArray[8].Select();
	If Selection.Next() Then
		StatusText = NStr("vi = 'Chứng từ không được phản ánh trong kế toán do vi phạm ghi trùng trong biểu ghi tài chính (%Count%), từ %Date%';
							|ru = 'Документы не отраженные в учете из-за нарушения двойной записи в финансовых регистрах (%Count%), с %Date%';
							|en = 'Documents not recorded in accounting due to violation of double entry in financial registers (%Count%), from %Date%'; fa = 'Documents not recorded in accounting due to violation of double entry in financial registers (%Count%), from %Date%';
							|it = 'Documenti non registrati in contabilità a causa di una violazione del metodo di partita doppia nei registri finanziari (%Count%), con %Date%';
							|pl = 'Dokumenty nie uwzględnione w ewidencji z powodu naruszenia podwójnego wpisu w rejestrach finansowych (%Count%), od %Date%';
							|tr = 'Mali kayıtlarda çift kayıt ihlali nedeniyle muhasebeye yansımayan belgeler (%Count%), ,%Date% itibaren'");
		StatusText = StrReplace(StatusText, "%Count%", Selection.Count);
		StatusBrokenDoubleEntryFinancialRegisters = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
		Items.StatusBrokenDoubleEntryFinancialRegisters.TextColor = StyleColors.OverdueDataColor;
		Items.StatusBrokenDoubleEntryFinancialRegisters.Hyperlink = True;
		Items.StatusBrokenDoubleEntryFinancialRegisters.Visible = True;
	Else
		Items.StatusBrokenDoubleEntryFinancialRegisters.Visible = False;
	EndIf;
	
	SetPrivilegedMode(False);

EndProcedure

&AtServer
Procedure GetOperationsThatRequireTemplateConfiguration()
	
	CheckParameters = DataProcessors.DocumentPostingInFinancialAccounting.ParametersForCheckingReflectionRules();
	If ValueIsFilled(Organization) Then
		CheckParameters.Organization = Organization;
	EndIf;
	Result = DataProcessors.DocumentPostingInFinancialAccounting.CheckAccountingRulesSettings(CheckParameters);
	
	AddressValidationResult = PutToTempStorage(Result, UUID);
	
	ErrorsCount = 
		Result.BusinessTransactionsWithoutRecordingRules.Count() + Result.AccountsWithoutRecordingRules.Count();
	
	If ErrorsCount > 0 Then
		StatusText = NStr("vi = 'Cần phải cài đặt quy tắc kế toán (%Count%)';
							|ru = 'Требуется настроить правила отражения в учете (%Count%)';
							|en = 'Configure rules of posting in accounting (%Count%)'; fa = 'Configure rules of posting in accounting (%Count%)';
							|it = 'È necessario configurare le regole di visualizzazione in contabilità (%Count%)';
							|pl = 'Należy skonfigurować zasady odzwierciedlenia w ewidencji (%Count%)';
							|tr = '(%Count%) muhasebede yansıma kurallarını ayarlamak gerekiyor'");
		StatusText = StrReplace(StatusText, "%Count%", ErrorsCount);
		ConfigureRulesOfRecordingInAccounting = StatusText;
		Items.ConfigureRulesOfRecordingInAccounting.Visible = True;
		Items.ConfigureRulesOfRecordingInAccounting.TextColor = StyleColors.OverdueDataColor;
	Else
		Items.ConfigureRulesOfRecordingInAccounting.Visible = False;
	EndIf;

EndProcedure

&AtServer
Procedure UpdateDataOnStateOfDocumentsAndTransactionGenerationSettings()
	
	UpdateServerReflectionBanDate();
	GetDocumentReflectionState();
	GetOperationsThatRequireTemplateConfiguration();
	GetStateOfRoutineTask();
	CreatePresentationOfTransactionGenerationSettings();
	RunTasksToUpdateDocumentVerificationStatusData();
	
EndProcedure

&AtClient
Procedure UpdateDataOnStateOfDocumentVerification()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	For Each KeyAndValue In MatchingUpdatesToReflectionStates Do
		
		If KeyAndValue.Key = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified") Then
			
			NotificationOfCompletionOfDocumentVerificationStatusUpdate = New CallbackDescription("ProcessResultOfUpdatingDocumentVerificationStatus_Verified", ThisObject);
			
		ElsIf KeyAndValue.Key = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified") Then
			
			NotificationOfCompletionOfDocumentVerificationStatusUpdate = New CallbackDescription("ProcessResultOfUpdatingDocumentVerificationStatus_NotVerified", ThisObject);
			
		ElsIf KeyAndValue.Key = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck") Then
			
			NotificationOfCompletionOfDocumentVerificationStatusUpdate = New CallbackDescription("ProcessResultOfUpdatingStatusOfDocumentVerification_CReVerification", ThisObject);
			
		Else
			
			Continue;
			
		EndIf;
		
		TimeConsumingOperationsClient.WaitCompletion(KeyAndValue.Value, NotificationOfCompletionOfDocumentVerificationStatusUpdate, IdleParameters);
		
	EndDo;
	
EndProcedure

&AtClient
Function InitializeDocumentListFormParameters(ReflectionStatus=Undefined)

	FormParameters = New Structure();
	
	Filter = New Structure();
	If ValueIsFilled(Organization) Then
		Filter.Insert("Organization", Organization);
	EndIf;
	If ValueIsFilled(ChartOfAccounts) Then
		Filter.Insert("ChartOfAccounts", ChartOfAccounts);
	EndIf;
	If ValueIsFilled(ReflectionStatus) Then
		Filter.Insert("ReflectionStatus", ReflectionStatus);
	EndIf;
	FormParameters.Insert("Filter", Filter);
	
	FormParameters.Insert("EndingDateOfPeriod", ?(ValueIsFilled(EndingDateOfPeriod), EndingDateOfPeriod, '39991231'));
	
	Return FormParameters;

EndFunction

&AtServer
Procedure NotificationProcessingServer(EventName)

	If EventName = "Write_DocumentPostingInFinancialAccounting" Then
		GetDocumentReflectionState();
		GetOperationsThatRequireTemplateConfiguration();
	ElsIf EventName = "CompletedConfigurationOfInternationalAccountingTransactionTemplates"
		Or EventName = "FormForSettingUpRequiredAccountingRulesIsClosed" Then
		GetOperationsThatRequireTemplateConfiguration();
	ElsIf EventName = "ChangedDateWhenTransactionsWereBanned" Then
		UpdateClosedPeriodData();
	EndIf;

EndProcedure

&AtServerNoContext
Function ArrayOfAvailableOrganizations(Organization)
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	CatalogData.Ref AS Organization
	|FROM
	|	Catalog.Companies AS CatalogData
	|WHERE
	|	CatalogData.Ref = &Organization
	|	OR &Organization = VALUE(Catalog.Companies.EmptyRef)
	|	AND NOT CatalogData.Predefined";
	Query.SetParameter("Organization", Organization);
	CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
	
	Return CompanyArray;
	
EndFunction

#EndRegion

#Region AutomaticReflectionInAccounting

&AtClient
Procedure RefreshSchedulePresentation()
	
	If JobSchedule = Undefined
	 Or JobSchedule = New JobSchedule Then
		SchedulePresentation = NStr("vi = 'Lịch biểu chưa được chỉ ra';
									|ru = 'Расписание не задано';
									|en = 'Schedule is not set'; fa = 'Schedule is not set';
									|it = 'Orario non è impostato';
									|pl = 'Harmonogram nie jest zadany';
									|tr = 'Plan ayarlanmadı'");
	Else
		SchedulePresentation = String(JobSchedule);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetStateOfRoutineTask()

	SetPrivilegedMode(True);
	
	Job = ScheduledJobsServer.Job(Metadata.ScheduledJobs.DocumentPostingInFinancialAccounting);
	If Common.DataSeparationEnabled() And ValueIsFilled(Job.Template) Then
		Schedule = Common.ObjectAttributeValue(Job.Template, "Schedule"); //ValueStorage
		JobSchedule = Schedule.Get();
	Else
		JobSchedule	= Job.Schedule;
	EndIf;
	UseAutomaticReflectionInAccounting = Job.Use;
	
	LastBackgroundJobProperties = TMCommonUse.GetStateOfLastJob(Job);
	If LastBackgroundJobProperties = Undefined
		Or Not ValueIsFilled(LastBackgroundJobProperties.CompletedOn) Then
		StateOfAutomaticRecordingInAccounting = NStr("vi = 'Chưa thực hiện';
													|ru = 'Не выполнялось';
													|en = 'Not run'; fa = 'Not run';
													|it = 'Non è stato effettuato';
													|pl = 'Nie było wykonywane';
													|tr = 'Gerçekleştirilmiyordu'");
	Else
		StateOfAutomaticRecordingInAccounting = String(LastBackgroundJobProperties.State) + ": "
			+ String(LastBackgroundJobProperties.CompletedOn);
	EndIf;
	
	Items.UseAutomaticReflectionInAccounting.Visible = Not Common.DataSeparationEnabled();
	Items.SchedulePresentation.Hyperlink = Not Common.DataSeparationEnabled();
	
	SetPrivilegedMode(False);

EndProcedure

&AtClient
Procedure EditScheduledJobSchedule()
	
	If JobSchedule = Undefined Then
		JobSchedule = New JobSchedule;
	EndIf;
	
	Dialog = New ScheduledJobDialog(JobSchedule);
	Dialog.Show(New CallbackDescription("ProcessingScheduleSelection", ThisObject, New Structure("Dialog", Dialog)));
	
EndProcedure

&AtClient
Procedure ProcessingScheduleSelection(Schedule, AdditionalParameters) Export
	
	If Schedule <> Undefined Then
		JobSchedule = Schedule;
		SaveDetailsOfRoutineTask();
	EndIf;
	RefreshSchedulePresentation();
	
EndProcedure

&AtServer
Procedure SaveDetailsOfRoutineTask()

	SetPrivilegedMode(True);
	
	Job = ScheduledJobsServer.Job(Metadata.ScheduledJobs.DocumentPostingInFinancialAccounting);
	JobParameters = New Structure;
	JobParameters.Insert("Use", UseAutomaticReflectionInAccounting);
	JobParameters.Insert("Schedule", JobSchedule);
	ScheduledJobsServer.ChangeJob(Job, JobParameters);
	
	SetPrivilegedMode(False);
	
	ManagingFormElementsWhenChangingAutomaticReflectionInAccounting();
	
EndProcedure

#EndRegion

#Region TransactionGenerationSettings

&AtServer
Procedure CreatePresentationOfTransactionGenerationSettings()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SUM(1) AS Count
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(
	|		&EndingDateOfPeriod,
	|		Organization = &Organization OR &AllCompanies) AS FinancialAccountingChartsOfAccounts
	|WHERE
	|	FinancialAccountingChartsOfAccounts.PostingGenerationSetting <> VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)
	|";
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("EndingDateOfPeriod", EndingDateOfPeriod);
	Query.SetParameter("AllCompanies", Not ValueIsFilled(Organization));
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count <> Null Then
		RecordsCount = Selection.Count;
	Else
		RecordsCount = 0;
	EndIf;
	
	StateText = "";
	TextColor = Undefined;
	If GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
		If RecordsCount > 0 Then
			StateText = StrTemplate(NStr("vi = 'Sử dụng hệ thống tài khoản (%1)';
										|ru = 'Использование планов счетов (%1)';
										|en = 'Use charts of accounts (%1)'; fa = 'Use charts of accounts (%1)';
										|it = 'Utilizzo dei piani dei conti (%1)';
										|pl = 'Używanie planów kont (%1)';
										|tr = '(%1) hesap planının kullanılması'"), RecordsCount);
			TextColor = StyleColors.HyperlinkColor;
		Else
			StateText = StrTemplate(NStr("vi = 'Không có tùy chỉnh sử dụng hệ thống tài khoản';
										|ru = 'Нет настроек использования планов счетов';
										|en = 'No settings for using charts of accounts'; fa = 'No settings for using charts of accounts';
										|it = 'Non ci sono impostazioni di utilizzo dei piani dei conti';
										|pl = 'Brak ustawień używania planów kont';
										|tr = 'Hesap planı kullanımının ayarları yok'"));
			TextColor = StyleColors.OverdueDataColor;
		EndIf;
		URL = "OpenPlansOfAccountsForInternationalAccountingOfOrganizations";
	Else
		If RecordsCount > 0 Then
			StateText = StrTemplate(NStr("vi = 'Sử dụng kế toán quốc tế (%1)';
										|ru = 'Использование международного учета (%1)';
										|en = 'Use of financial accounting (%1)'; fa = 'Use of financial accounting (%1)';
										|it = 'Utilizzo della contabilità internazionale (%1)';
										|pl = 'Używanie ewidencji międzynarodowej (%1)';
										|tr = 'Uluslararası muhasebe kullanım (%1)'"), RecordsCount);
			TextColor = StyleColors.HyperlinkColor;
		Else
			StateText = StrTemplate(NStr("vi = 'Không có tùy chỉnh sử dụng kế toán quốc tế';
										|ru = 'Нет настроек использования международного учета';
										|en = 'No financial accounting use settings'; fa = 'No financial accounting use settings';
										|it = 'Non ci sono impostazione di utilizzo della contabilità internazionale';
										|pl = 'Brak ustawień używania ewidencji międzynarodowej';
										|tr = 'Uluslararası muhasebe kullanım ayarları yok'"));
			TextColor = StyleColors.OverdueDataColor;
		EndIf;
		URL = "OpenPlansOfAccountsForInternationalAccountingOfOrganizations";
	EndIf;
	StatusOfTheTransactionGenerationSetup = New FormattedString(StateText, , TextColor, , URL);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "OpenPlansOfAccountsForInternationalAccountingOfOrganizations" Then
		StandardProcessing = False;
		
		OpenForm("InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.Form.Workplace",
			New Structure("Organization", Organization));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	ManagingFormElementsWhenOrganizationChanges();
	UpdateDataOnStateOfDocumentsAndTransactionGenerationSettings();
	
EndProcedure

&AtServer
Procedure EndDateOfPeriodOnChangeAtServer()
	
	If ValueIsFilled(EndingDateOfPeriod) Then
		EndingDateOfPeriod = EndOfDay(EndingDateOfPeriod);
	EndIf;
	
	UpdateDataOnStateOfDocumentsAndTransactionGenerationSettings();
	
EndProcedure

&AtServer
Procedure ChartOfAccountsWhenChangedOnServer()
	
	UpdateDataOnStateOfDocumentsAndTransactionGenerationSettings();
	
EndProcedure

&AtServer
Procedure ManagingFormElementsWhenOrganizationChanges()

	If Not ValueIsFilled(Organization) Then
		
		Items.TheGroupClosedPeriod.Visible = False;
		UpdateServerReflectionBanDate();
		
	EndIf;

EndProcedure

&AtServer
Procedure ManagingFormElementsWhenChangingAutomaticReflectionInAccounting()

	Items.SchedulePresentation.Enabled = UseAutomaticReflectionInAccounting;
	Items.SchedulePresentation.Hyperlink = Not Common.DataSeparationEnabled();
	Items.StateOfAutomaticRecordingInAccounting.Enabled = UseAutomaticReflectionInAccounting;

EndProcedure

&AtServer
Procedure UpdateClosedPeriodData()
	
	UpdateServerReflectionBanDate();
	If ValueIsFilled(Organization) Then
		GetDocumentReflectionState();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateServerReflectionBanDate()
	
	PeriodEndClosingDate = FinancialAccountingOfGeneralPurpose.ClosingDateOfPostingGeneration(Organization);
	Items.SetClosingDate.Title = FinancialAccountingOfGeneralPurpose.PresentationOfCommandToSetBanDate(PeriodEndClosingDate);
	
EndProcedure

&AtServer
Procedure UpdateDataOnReflectionAndVerificationOfDocumentsInAccounting(BackgroundJobExecutionResult, OperationKind)
	
	#Region SettingTextOfMessagesAboutAvailabilityOfDocuments
	CorrespondenceOfDocumentAvailabilityMessageToTypeOfOperation = New Map;
	CorrespondenceOfDocumentAvailabilityMessageToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified") ,
		NStr("vi = 'Chứng từ đã kiểm tra (%Count%), đến %Date%';
			|ru = 'Проверенные документы (%Count%), по %Date%';
			|en = 'Checked documents (%Count%), till %Date%'; fa = 'Checked documents (%Count%), till %Date%';
			|it = 'Documenti verificati (%Count%) il %Date%';
			|pl = 'Sprawdzone dokumenty (%Count%), do %Date%';
			|tr = 'Denetlenen belgeler (%Count%), %Date% itibaren'"));
	CorrespondenceOfDocumentAvailabilityMessageToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified"),
		NStr("vi = 'Các chứng từ cần kiểm tra (%Count%), từ %Date%';
			|ru = 'Документы, требующие проверки (%Count%), с %Date%';
			|en = 'Documents requiring check (%Count%), from %Date%'; fa = 'Documents requiring check (%Count%), from %Date%';
			|it = 'Documenti da verificare (%Count%), da %Date%';
			|pl = 'Dokumenty, wymagające sprawdzenia (%Count%), do %Date%';
			|tr = 'Denetlemeyi gerektiren belgeler (%Count%), %Date% itibaren'"));
	CorrespondenceOfDocumentAvailabilityMessageToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck"),
		NStr("vi = 'Các chứng từ cần kiểm tra lại (%Count%), từ %Date%';
			|ru = 'Документы, требующие повторной проверки (%Count%), с %Date%';
			|en = 'Documents requiring recheck (%Count%), from %Date%'; fa = 'Documents requiring recheck (%Count%), from %Date%';
			|it = 'Documenti da verificare nuovamente (%Count%), da %Date%';
			|pl = 'Dokumenty, wymagające ponownego sprawdzenia (%Count%), do %Date%';
			|tr = 'Yeniden denetlemeyi gerektiren belgeler (%Count%), %Date% itibaren'"));
	#EndRegion
	
	#Region SettingTextOfMessagesAboutAbsenceOfDocuments
	CorrespondenceOfMessageAboutAbsenceOfDocumentsToTypeOfOperation = New Map;
	CorrespondenceOfMessageAboutAbsenceOfDocumentsToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified") ,
		NStr("vi = 'Không có chứng từ đã kiểm tra.';
			|ru = 'Нет проверенных документов.';
			|en = 'No checked documents.'; fa = 'No checked documents.';
			|it = 'Non ci sono documenti verificati.';
			|pl = 'Brak sprawdzonych dokumentów.';
			|tr = 'Denetlenen belgeler bulunmuyor'"));
	CorrespondenceOfMessageAboutAbsenceOfDocumentsToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified"),
		NStr("vi = 'Không có chứng từ cần kiểm tra.';
			|ru = 'Нет документов, требующих проверки.';
			|en = 'No documents requiring check.'; fa = 'No documents requiring check.';
			|it = 'Non ci sono documenti che richiedono verifica.';
			|pl = 'Brak dokumentów, wymagających sprawdzenia.';
			|tr = 'Denetlemeyi gerektiren belge bulunmuyor'"));
	CorrespondenceOfMessageAboutAbsenceOfDocumentsToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck"),
		NStr("vi = 'Không có chứng từ cần kiểm tra lại.';
			|ru = 'Нет документов, требующих повторной проверки.';
			|en = 'No documents requiring recheck.'; fa = 'No documents requiring recheck.';
			|it = 'Non ci sono documenti che richiedono nuova verifica.';
			|pl = 'Brak dokumentów, wymagających ponownego sprawdzenia.';
			|tr = 'Yeniden denetlemeyi gerektiren belge bulunmuyor'"));
	#EndRegion
	
	#Region SettingTextOfErrorMessagesWhenExecuting
	MatchingErrorMessageWhenPerformingTypeOfOperation = New Map;
	MatchingErrorMessageWhenPerformingTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified") ,
		NStr("vi = 'Đã kết thúc nhận bị lỗi dữ liệu về các chứng từ chưa kiểm tra.';
			|ru = 'Получение данных о непроверенных документах завершилось с ошибкой.';
			|en = 'An error occurred when receiving unchecked document data.'; fa = 'An error occurred when receiving unchecked document data.';
			|it = 'Ricezione dati sui documenti non verificati eseguita con errori.';
			|pl = 'Otrzymanie danych o niesprzawdzonych dokumentach zostało zakończone z błędem.';
			|tr = 'Denetlenmemiş belgelerle ilgili verilerin alınması hatayla sonuçlandı.'"));
	MatchingErrorMessageWhenPerformingTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified"),
		NStr("vi = 'Đã kết thúc nhận bị lỗi dữ liệu về các chứng từ cần kiểm tra.';
			|ru = 'Получение данных о документах, требующих проверки, завершилось с ошибкой.';
			|en = 'An error occurred when receiving data of documents requiring check.'; fa = 'An error occurred when receiving data of documents requiring check.';
			|it = 'Ricezione dati sui documenti da verificare eseguita con errori.';
			|pl = 'Otrzymanie danych o dokumentach, wymagających sprawdzenia, zostało zakończone z błędem.';
			|tr = 'Denetleme gerektiren belgelerle ilgili verilerin alınması hatayla sonuçlandı.'"));
	MatchingErrorMessageWhenPerformingTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck"),
		NStr("vi = 'Đã kết thúc nhận bị lỗi dữ liệu về các chứng từ cần kiểm tra lại.';
			|ru = 'Получение данных о документах, требующих повторной проверки, завершилось с ошибкой.';
			|en = 'An error occurred when receiving data of the documents requiring recheck.'; fa = 'An error occurred when receiving data of the documents requiring recheck.';
			|it = 'Ricezione dati sui documenti da verificare nuovamente eseguita con errori.';
			|pl = 'Otrzymanie danych o dokumentach, wymagających ponownego sprawdzenia zostało zakończone z błędem.';
			|tr = 'Yeniden denetleme gerektiren belgelerle ilgili verilerin alınması hatayla sonuçlandı.'"));
	#EndRegion
	
	#Region SettingTextOfDataUpdateMessages
	CorrespondenceOfDataUpdateMessageToTypeOfOperation = New Map;
	CorrespondenceOfDataUpdateMessageToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified") ,
		NStr("vi = 'Nhận chứng từ đã kiểm tra...';
			|ru = 'Получение проверенных документов...';
			|en = 'Receiving checked documents...'; fa = 'Receiving checked documents...';
			|it = 'Ricezione documenti verificati...';
			|pl = 'Otrzymanie sprawdzonych dokumentów...';
			|tr = 'Denetlenen belgelerin alınması...'"));
	CorrespondenceOfDataUpdateMessageToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified"),
		NStr("vi = 'Nhận chứng từ cần kiểm tra...';
			|ru = 'Получение документов, требующих проверки...';
			|en = 'Receiving documents requiring check...'; fa = 'Receiving documents requiring check...';
			|it = 'Ricezione documenti da verificare...';
			|pl = 'Otrzymanie dokumentów, wymagających sprawdzenia...';
			|tr = 'Denetlemeyi gerektiren belgelerin alınması...'"));
	CorrespondenceOfDataUpdateMessageToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck"),
		NStr("vi = 'Nhận chứng từ cần kiểm tra lại...';
			|ru = 'Получение документов, требующих повторной проверки...';
			|en = 'Receiving documents requiring recheck...'; fa = 'Receiving documents requiring recheck...';
			|it = 'Ricezione documenti da verificare nuovamente...';
			|pl = 'Otrzymanie dokumentów, wymagających ponownego sprawdzenia...';
			|tr = 'Yeniden denetlemeyi gerektiren belgelerin alınması...'"));
	#EndRegion
	
	#Region SettingNamesOfDetails
	MatchingNamesOfDetailsToTypeOfOperation = New Map;
	MatchingNamesOfDetailsToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified") , "StatusOfVerifiedDocuments");
	MatchingNamesOfDetailsToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified"), "StatusOfUnverifiedDocuments");
	MatchingNamesOfDetailsToTypeOfOperation.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck"), "StatusOfDocumentsToBeChecked");
	#EndRegion
	
	AttributeName = MatchingNamesOfDetailsToTypeOfOperation.Get(OperationKind);
		
	If BackgroundJobExecutionResult.Status = "Completed2" Then
	
		Result = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress); // QueryResult -
		
		Selection = Result.Select();
		If Selection.Next() And Selection.Count <> 0 Then
			StatusText = CorrespondenceOfDocumentAvailabilityMessageToTypeOfOperation.Get(OperationKind);
			StatusText = StrReplace(StatusText, "%Count%", Selection.Count);
			ThisObject[AttributeName] = StrReplace(StatusText, "%Date%", Format(Selection.StartDate, "DLF=D"));
			Items[AttributeName].TextColor = ?(OperationKind = "NoAccountingAccountsAreSpecified", StyleColors.OverdueDataColor, StyleColors.HyperlinkColor);
			Items[AttributeName].Hyperlink = True;
		Else
			ThisObject[AttributeName] = CorrespondenceOfMessageAboutAbsenceOfDocumentsToTypeOfOperation.Get(OperationKind);
			Items[AttributeName].TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
			Items[AttributeName].Hyperlink = False;
		EndIf;
		
	ElsIf BackgroundJobExecutionResult.Status = "Error" Then
		ThisObject[AttributeName] = MatchingErrorMessageWhenPerformingTypeOfOperation.Get(OperationKind) + 
			" " + NStr("vi = 'Chi tiết xem trong nhật ký sự kiện.';
						|ru = 'Подробнее см. в журнале регистрации.';
						|en = 'For more information, see the event log.'; fa = 'For more information, see the event log.';
						|it = 'Per maggiori informazioni visualizzare il registro.';
						|pl = 'Więcej zob. w dzienniku rejestracji.';
						|tr = 'Daha fazla bilgi için olay günlüğüne bakın'");
		Items[AttributeName].TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items[AttributeName].Hyperlink = False;
	Else
		ThisObject[AttributeName] = CorrespondenceOfDataUpdateMessageToTypeOfOperation.Get(OperationKind);
		Items[AttributeName].TextColor = StyleColors.InformationLabelText;
		Items[AttributeName].Hyperlink = False;
	EndIf;
	
	If OperationKind = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified") Then
		
		Items.PictureUpdateStatusChecked.Visible = Not (BackgroundJobExecutionResult.Status = "Completed2"
																	Or BackgroundJobExecutionResult.Status = "Error");
		
	ElsIf OperationKind = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified") Then
		
		Items.PictureUpdateStatusNotVerified.Visible = Not (BackgroundJobExecutionResult.Status = "Completed2"
																	Or BackgroundJobExecutionResult.Status = "Error");
		
	ElsIf OperationKind = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck") Then
		
		Items.PictureUpdateStatusToReCheck.Visible = Not (BackgroundJobExecutionResult.Status = "Completed2"
																	Or BackgroundJobExecutionResult.Status = "Error");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region BackgroundDataUpdateTasks

&AtClient
Procedure ProcessResultOfUpdatingDocumentVerificationStatus_Verified(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		UpdateData1(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified"), Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessResultOfUpdatingDocumentVerificationStatus_NotVerified(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		UpdateData1(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified"), Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessResultOfUpdatingStatusOfDocumentVerification_CReVerification(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		UpdateData1(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck"), Result);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function InitializeMatchingStatusForDocumentVerification(DataOfFunctionalOptions)
	
	StatusesMap = New Map;
	If DataOfFunctionalOptions.DocumentVerification Then
		
		StatusesMap.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified"));
		StatusesMap.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified"));
		StatusesMap.Insert(PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck"));
		
	EndIf;
	
	Return StatusesMap;
	
EndFunction

&AtServer
Procedure RunTasksToUpdateDocumentVerificationStatusData()
	
	TasksToLaunch = InitializeMatchingStatusForDocumentVerification(FOData);
	BackgroundJobParameters = DataProcessors.DocumentPostingInFinancialAccounting.ParametersForCountingNumberOfDocuments();
	
	If ValueIsFilled(Organization) Then
		
		BackgroundJobParameters.CompanyArray = Organization;
		
	Else
		
		BackgroundJobParameters.CompanyArray = ArrayOfAvailableOrganizations(Organization);
		
	EndIf;

	BackgroundJobParameters.EndingDateOfPeriod = EndingDateOfPeriod;
	BackgroundJobParameters.ChartOfAccounts = ChartOfAccounts;
	
	Tasks_Completed = New Array;
	
	For Each Job In TasksToLaunch Do
		
		BackgroundJobParameters.JobKind = Job.Key;
		
		ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
		ExecutionResult = TimeConsumingOperations.ExecuteFunction(ExecutionParameters, 
			"DataProcessors.DocumentPostingInFinancialAccounting.DocumentVerificationStatus",
			BackgroundJobParameters);
			
		UpdateData1(Job.Key, ExecutionResult);
		
		If ExecutionResult.Status = "Completed2" 
			Or ExecutionResult.Status = "Error" Then
			Tasks_Completed.Add(Job.Key);
		Else
			TasksToLaunch.Insert(Job.Key, ExecutionResult);
		EndIf;
		
	EndDo;
	
	For Each CompletedTask In Tasks_Completed Do
		TasksToLaunch.Delete(CompletedTask);
	EndDo;
	
	MatchingUpdatesToReflectionStates = New FixedMap(TasksToLaunch);
	
EndProcedure

&AtServer
Procedure UpdateData1(OperationName, ExecutionResult)
	
	UpdateDataOnReflectionAndVerificationOfDocumentsInAccounting(ExecutionResult, OperationName);
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_EndingDateOfPeriod" Then
		EndingDateOfPeriodOnChange(Items.EndingDateOfPeriod);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
