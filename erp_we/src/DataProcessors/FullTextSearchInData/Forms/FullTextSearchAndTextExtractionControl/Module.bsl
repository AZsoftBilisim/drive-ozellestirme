///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseFullTextSearch = FullTextSearchServer.UseSearchFlagValue();
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations")
	   And Users.IsFullUser() Then
		
		// Visibility settings at startup.
		Items.AutomaticTextsExtractionGroup.Visible =
			  Users.IsFullUser(, True)
			And Not Common.DataSeparationEnabled()
			And Not Common.IsMobileClient();
		
	Else
		Items.AutomaticTextsExtractionGroup.Visible = False;
	EndIf;
	
	If Items.AutomaticTextsExtractionGroup.Visible Then
		
		If Common.FileInfobase() Then
			ChoiceList = Items.ExtractFilesTextsAtWindowsServer.ChoiceList;
			ChoiceList[0].Presentation = NStr("vi = 'Tất cả các điểm làm việc chạy hệ điều hành Windows';
												|ru = 'Все рабочие станции работают под управлением ОС Windows';
												|en = 'All workstations run on Windows.'; fa = 'All workstations run on Windows.';
												|it = 'Tutte le postazioni di lavoro funzionano con il SO Windows';
												|pl = 'Wszystkie stacje robocze pracują pod kontrolą SO Windows';
												|tr = 'Tüm iş istasyonları Windows işletim sistemi altında çalışır'");
			
			ChoiceList = Items.ExtractFilesTextsAtLinuxServer.ChoiceList;
			ChoiceList[0].Presentation = NStr("vi = 'Một hoặc nhiều máy trạm chạy hệ điều hành Linux';
												|ru = 'Одна или несколько рабочих станций работают под управлением ОС Linux';
												|en = 'One or more workstations run on Linux.'; fa = 'One or more workstations run on Linux.';
												|it = 'Una o più postazioni di lavoro funzionano con il SO Linux';
												|pl = 'Jedna lub kilka stacji roboczych pracują pod kontrolą SO Linux';
												|tr = 'Bir ya da birkaç iş istasyonu Linux OS altında çalışır'");
		EndIf;
		
		// Form attributes values.
		ExtractTextFilesOnServer = ?(ConstantsSet.ExtractTextFilesOnServer, 1, 0);
	
		ScheduledJobsInfo = New Structure;
		FillScheduledJobInfo("TextExtraction");
	Else
		AutoTitle = False;
		Title = NStr("vi = 'Quản lý tìm kiếm toàn văn';
					|ru = 'Управление полнотекстовым поиском';
					|en = 'Manage full-text search'; fa = 'مدیریت جستجوی تمام‌متن';
					|it = 'Gestione della ricerca full-text';
					|pl = 'Zarządzanie wyszukiwaniem pełnotekstowym';
					|tr = 'Tam metin aramayı yönetme'");
		Items.SectionDetails.Title =
			NStr("vi = 'Bật và tắt tìm kiếm toàn văn, cập nhật chỉ số tìm kiếm toàn văn.';
				|ru = 'Включение и отключение полнотекстового поиска, обновление индекса полнотекстового поиска.';
				|en = 'Full-text search toggle, search index update.'; fa = 'Full-text search toggle, search index update.';
				|it = 'Attivazione e disattivazione della ricerca full-text, aggiornamento dell''indice di ricerca full-text.';
				|pl = 'Włączanie i wyłączanie wyszukiwania pełnotekstowego, aktualizacja indeksu pełnotekstowego wyszukiwania.';
				|tr = 'Tam metin aramanın etkinleştirilmesi ve devre dışı bırakılması, tam metin arama dizininin güncellenmesi.'");
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FullTextSearchClient.UseSearchFlagChangeNotificationProcessing(
		EventName, 
		UseFullTextSearch);
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFullTextSearchOnChange(Item)
	
	FullTextSearchClient.OnChangeUseSearchFlag(UseFullTextSearch);
	
EndProcedure

&AtClient
Procedure ExtractFilesTextsAtServerOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure IndexedDataMaxSizeOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure LimitMaxIndexedDataSizeOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateIndex(Command)
	UpdateIndexServer();
	ShowUserNotification(NStr("vi = 'Tìm kiếm trong dữ liệu';
								|ru = 'Полнотекстовый поиск';
								|en = 'Full-text search'; fa = 'جستجوی تمام‌متن';
								|it = 'Ricerca full-text';
								|pl = 'Wyszukiwanie pełnotekstowe';
								|tr = 'Tam metin arama'"),, NStr("vi = 'Đã cập nhật thành công chỉ mục';
																|ru = 'Индекс успешно обновлен';
																|en = 'Index has been updated'; fa = 'Index has been updated';
																|it = 'L''indice è aggiornato con successo';
																|pl = 'Indeks został pomyślnie zaktualizowany';
																|tr = 'Dizin başarı ile güncellendi'"));
EndProcedure

&AtClient
Procedure ClearIndex(Command)
	QueryText = NStr("vi = 'Chỉ mục tìm kiếm sẽ bị xóa, việc này dẫn đến không thể
		|tìm kiếm toàn văn trong ứng dụng.
		|Để bật tìm kiếm toàn văn, cần cập nhật chỉ mục.
		|
		|Tiếp tục?';
		|ru = 'Индекс поиска будет очищен, что приведет к невозможности
		|полнотекстового поиска в приложении.
		|Для включения полнотекстового поиска потребуется выполнить обновление индекса.
		|
		|Продолжить?';
		|en = 'The search index will be cleared, and you
		|will not be able to use the full-text search.
		|To enable the full-text search, you must update the index.
		|
		|Continue?'; fa = 'The search index will be cleared, and you
		|will not be able to use the full-text search.
		|To enable the full-text search, you must update the index.
		|
		|Continue?';
		|it = 'Индекс поиска будет очищен, что приведет к невозможности
		|полнотекстового поиска в приложении.
		|Для включения полнотекстового поиска потребуется выполнить обновление индекса.
		|
		|Продолжить?';
		|pl = 'The search index will be cleared, and you
		|will not be able to use the full-text search.
		|To enable the full-text search, you must update the index.
		|
		|Continue?';
		|tr = 'Arama endeksi silinecek ve bu, 
		|uygulama içinde tam metin aramanın yapılamamasına yol açacaktır. 
		|Tam metin aramasının etkinleştirilmesi için endeks güncellenmelidir.
		|
		|Devam etmek istiyor musunuz?'");
	
	Handler = New CallbackDescription("ClearTheIndexAfterAnsweringTheQuestion", ThisObject);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure CheckIndex(Command)
	ClearMessages();
	CheckIndexServer();
	ShowUserNotification(NStr("vi = 'Tìm kiếm trong dữ liệu';
								|ru = 'Полнотекстовый поиск';
								|en = 'Full-text search'; fa = 'جستجوی تمام‌متن';
								|it = 'Ricerca full-text';
								|pl = 'Wyszukiwanie pełnotekstowe';
								|tr = 'Tam metin arama'"),, NStr("vi = 'Chỉ mục có dữ liệu chính xác';
																|ru = 'Индекс содержит корректные данные';
																|en = 'Index is up to date'; fa = 'Index is up to date';
																|it = 'L''indice contiene i dati corretti';
																|pl = 'Indeks zawiera prawidłowe dane';
																|tr = 'Dizin doğru veri içermektedir'"));
EndProcedure

&AtClient
Procedure EditScheduledJob(Command)
	ScheduledJobsHyperlinkClick("TextExtraction");
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	Result = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If Result.Property("CannotEnableFullTextSearchMode") Then
		// Display a warning message.
		QueryText = NStr("vi = 'Để thay đổi chế độ tìm kiếm toàn văn, cần hoàn tất phiên làm việc của tất cả người sử dụng, ngoại trừ người sử dụng hiện tại.';
						|ru = 'Для изменения режима полнотекстового поиска требуется завершение сеансов всех пользователей, кроме текущего.';
						|en = 'To change the full-text search mode, close all sessions, except for the current user session.'; fa = 'To change the full-text search mode, close all sessions, except for the current user session.';
						|it = 'Per cambiare la modalità di ricerca full-text, è necessario terminare le sessioni di tutti gli utenti, tranne quella corrente.';
						|pl = 'Aby zmienić tryb wyszukiwania pełnotekstowego, musisz zakończyć wszystkie sesje użytkownika z wyjątkiem sesji bieżącej.';
						|tr = 'Tam metin arama modunu değiştirmek için mevcut kullanıcı dışındaki tüm kullanıcı oturumlarını kapatın.'");
		
		Buttons = New ValueList;
		Buttons.Add("ActiveUsers", NStr("vi = 'Người sử dụng đang làm việc';
										|ru = 'Активные пользователи';
										|en = 'Active users'; fa = 'کاربران فعال';
										|it = 'Utenti attivi';
										|pl = 'Aktywni użytkownicy';
										|tr = 'Aktif kullanıcılar'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New CallbackDescription("OnChangeAttributeAfterAnswerToQuestion", ThisObject);
		ShowQueryBox(Handler, QueryText, Buttons, , "ActiveUsers");
		Return;
	EndIf;
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If Result.ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, Result.ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsHyperlinkClick(PredefinedItemName)
	InformationRecords = ScheduledJobInfoClient(PredefinedItemName);
	If InformationRecords.Id = Undefined Then
		Return;
	EndIf;
	Context = New Structure;
	Context.Insert("PredefinedItemName", PredefinedItemName);
	Context.Insert("FlagChanged", False);
	Handler = New CallbackDescription("ScheduledJobsAfterChangeSchedule", ThisObject, Context);
	Dialog = New ScheduledJobDialog(InformationRecords.Schedule);
	Dialog.Show(Handler);
EndProcedure

&AtClient
Procedure ScheduledJobsAfterChangeSchedule(Schedule, Context) Export
	If Schedule = Undefined Then
		If Context.FlagChanged Then
			ThisObject[Context.CheckBoxName] = False;
		EndIf;
		Return;
	EndIf;
	
	Changes = New Structure("Schedule", Schedule);
	If Context.FlagChanged Then
		ThisObject[Context.CheckBoxName] = True;
		Changes.Insert("Use", True);
	EndIf;
	ScheduledJobsSave(Context.PredefinedItemName, Changes, True);
EndProcedure

&AtClient
Procedure OnChangeAttributeAfterAnswerToQuestion(Response, ExecutionParameters) Export
	If Response = "ActiveUsers" Then
		StandardSubsystemsClient.OpenActiveUserList();
	EndIf;
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearTheIndexAfterAnsweringTheQuestion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ClearIndexServer();
		ShowUserNotification(NStr("vi = 'Tìm kiếm toàn văn';
									|ru = 'Полнотекстовый поиск';
									|en = 'Full-text search'; fa = 'جستجوی تمام‌متن';
									|it = 'Ricerca full-text';
									|pl = 'Wyszukiwanie pełnotekstowe';
									|tr = 'Tam metin arama'"),, NStr("vi = 'Đã xóa thành công chỉ mục';
																	|ru = 'Индекс успешно очищен';
																	|en = 'Index has been cleaned up'; fa = 'Index has been cleaned up';
																	|it = 'L''indice è cancellato con successo';
																	|pl = 'Indeks został pomyślnie oczyszczony';
																	|tr = 'Dizin başarı ile temizlendi'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region ServerCall

&AtServer
Procedure UpdateIndexServer()
	FullTextSearch.UpdateIndex(False, False);
	SetAvailability("Command.UpdateIndex");
EndProcedure

&AtServer
Procedure ClearIndexServer()
	FullTextSearch.ClearIndex();
	SetAvailability("Command.ClearIndex");
EndProcedure

&AtServer
Procedure CheckIndexServer()
	Try
		IndexContainsCorrectData = FullTextSearch.CheckIndex();
	Except
		ErrorMessageText = 
			NStr("vi = 'Hiện tại, không thể kiểm tra chỉ số, bởi vì đang thực hiện xóa hoặc cập nhật.';
				|ru = 'В настоящее время проверка индекса невозможна, так как выполняется его очистка или обновление.';
				|en = 'Cannot check index status. The index is being updated or cleaned up.'; fa = 'Cannot check index status. The index is being updated or cleaned up.';
				|it = 'Al momento non è possibile effettuare il controllo dell''indice perché la cancellazione o aggiornamento di esso è in corso.';
				|pl = 'Obecnie weryfikacja indeksu nie jest możliwa, ponieważ wykonuje się jego czyszczenie lub aktualizacja.';
				|tr = 'Dizin doğrulama şu anda mümkün değildir, çünkü temizleme veya güncelleme yapılır.'");
		Common.MessageToUser(ErrorMessageText);
		FullTextSearchServer.LogRecord(EventLogLevel.Warning, 
			"", ErrorInfo());
	EndTry;
	SetAvailability("Command.CheckIndex", True);
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	Result = SaveAttributeValue(DataPathAttribute);
	SetAvailability(DataPathAttribute);
	If Result.Property("CannotEnableFullTextSearchMode") Then
		Return Result;
	EndIf;
	RefreshReusableValues();
	Return Result;
	
EndFunction

&AtServer
Procedure ScheduledJobsSave(PredefinedItemName, Changes, SetVisibilityAvailability)
	InformationRecords = ScheduledJobInfo(PredefinedItemName);
	If InformationRecords.Id = Undefined Then
		Return;
	EndIf;
	ScheduledJobsServer.ChangeJob(InformationRecords.Id, Changes);
	FillPropertyValues(InformationRecords, Changes);
	ScheduledJobsInfo.Insert(PredefinedItemName, InformationRecords);
	If SetVisibilityAvailability Then
		SetAvailability("ScheduledJob." + PredefinedItemName);
	EndIf;
EndProcedure

#EndRegion

#Region Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	Result = New Structure("ConstantName", "");
	
	// Saving values of attributes not directly related to constants (in ratio one to one).
	If DataPathAttribute = "" Then
		Return Result;
	EndIf;
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		If DataPathAttribute = "ExtractTextFilesOnServer" Then
			ConstantName = "ExtractTextFilesOnServer";
			ConstantsSet.ExtractTextFilesOnServer = ExtractTextFilesOnServer;
			Changes = New Structure("Use", ConstantsSet.ExtractTextFilesOnServer);
			ScheduledJobsSave("TextExtraction", Changes, False);
		ElsIf DataPathAttribute = "IndexedDataMaxSize"
			Or DataPathAttribute = "LimitMaxIndexedDataSize" Then
			Try
				If LimitMaxIndexedDataSize Then
					// When you enable the restriction for the first time, the default value of the platform 1 MB is set.
					If IndexedDataMaxSize = 0 Then
						IndexedDataMaxSize = 1;
					EndIf;
					If FullTextSearch.GetMaxIndexedDataSize() <> IndexedDataMaxSize * 1048576 Then
						FullTextSearch.SetMaxIndexedDataSize(IndexedDataMaxSize * 1048576);
					EndIf;
				Else
					FullTextSearch.SetMaxIndexedDataSize(0);
				EndIf;
			Except
				WriteLogEvent(
					NStr("vi = 'Tìm kiếm trong dữ liệu';
						|ru = 'Полнотекстовый поиск';
						|en = 'Full-text search'; fa = 'جستجوی تمام‌متن';
						|it = 'Ricerca full-text';
						|pl = 'Wyszukiwanie pełnotekstowe';
						|tr = 'Tam metin arama'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Result.Insert("CannotEnableFullTextSearchMode", True);
				Return Result;
			EndTry;
		EndIf;
	Else
		ConstantName = NameParts[1];
	EndIf;
	
	If IsBlankString(ConstantName) Then
		Return Result;
	EndIf;

	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Result.ConstantName = ConstantName;
	Return Result;
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "", IndexChecked = False)
	
	State = FullTextSearchServer.FullTextSearchStatus();
	
	Items.FullTextSearchManagementGroup.Enabled = (UseFullTextSearch = 1);
	Items.AutomaticTextsExtractionGroup.Enabled = (UseFullTextSearch = 1);
	
	If DataPathAttribute = ""
		Or DataPathAttribute = "LimitMaxIndexedDataSize"
		Or DataPathAttribute = "IndexedDataMaxSize"
		Or DataPathAttribute = "UseFullTextSearch"
		Or DataPathAttribute = "Command.UpdateIndex"
		Or DataPathAttribute = "Command.ClearIndex"
		Or DataPathAttribute = "Command.CheckIndex" Then
		
		If UseFullTextSearch = 1 Then
			IndexUpdateDate = FullTextSearch.UpdateDate();
			IndexTrue = (State = "SearchAllowed");
			If IndexChecked And Not IndexContainsCorrectData Then
				IndexStatus = NStr("vi = 'Cần xóa và cập nhật';
									|ru = 'Требуется очистка и обновление';
									|en = 'Cleanup and update required'; fa = 'Cleanup and update required';
									|it = 'Sono richiesti cancellazione e aggiornamento';
									|pl = 'Wymagane jest czyszczenie i aktualizacja';
									|tr = 'Temizleme ve güncelleme gerekir'");
			ElsIf IndexTrue Then
				IndexStatus = NStr("vi = 'Không cần cập nhật';
									|ru = 'Обновление не требуется';
									|en = 'No update required'; fa = 'به‌روزرسانی لازم نیست';
									|it = 'L''aggiornamento non è richiesto';
									|pl = 'Aktualizacja nie jest konieczna';
									|tr = 'Güncelleme gerekmiyor'");
			Else
				IndexStatus = NStr("vi = 'Cần cập nhật';
									|ru = 'Требуется обновление';
									|en = 'Update required'; fa = 'Update required';
									|it = 'È richiesto l''aggiornamento.';
									|pl = 'Jest konieczna aktualizacja';
									|tr = 'Güncelleme gerekiyor'");
			EndIf;
		Else
			IndexUpdateDate = '00010101';
			IndexTrue = False;
			IndexStatus = NStr("vi = 'Đã tắt bỏ tính năng tìm kiếm toàn văn';
								|ru = 'Полнотекстовый поиск отключен';
								|en = 'Full-text search is disabled'; fa = 'Full-text search is disabled';
								|it = 'Ricerca full-text è disabilitata';
								|pl = 'Wyszukiwanie pełnotekstowe jest wyłączone';
								|tr = 'Tam metin araması devre dışı'");
		EndIf;
		IndexedDataMaxSize = FullTextSearch.GetMaxIndexedDataSize() / 1048576;
		LimitMaxIndexedDataSize = IndexedDataMaxSize <> 0;
		
		Items.IndexedDataMaxSize.Enabled = LimitMaxIndexedDataSize;
		Items.MBDecoration.Enabled = LimitMaxIndexedDataSize;
		
		Items.UpdateIndex.Enabled = Not IndexTrue;
		
	EndIf;
	
	If Items.AutomaticTextsExtractionGroup.Visible
		And (DataPathAttribute = ""
		Or DataPathAttribute = "ExtractTextFilesOnServer"
		Or DataPathAttribute = "ScheduledJob.TextExtraction") Then
		Items.EditScheduledJob.Enabled = ConstantsSet.ExtractTextFilesOnServer;
		Items.StartTextExtraction.Enabled       = Not ConstantsSet.ExtractTextFilesOnServer;
		If ConstantsSet.ExtractTextFilesOnServer Then
			InformationRecords = ScheduledJobInfo("TextExtraction");
			SchedulePresentation = String(InformationRecords.Schedule);
			SchedulePresentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			SchedulePresentation = NStr("vi = 'Chưa thực hiện tự động lấy nội dung.';
										|ru = 'Автоматическое извлечение текстов не выполняется.';
										|en = 'Automatic text extraction is not scheduled.'; fa = 'Automatic text extraction is not scheduled.';
										|it = 'L''estrazione automatica del testo non viene eseguita.';
										|pl = 'Automatyczne pobieranie tekstów nie jest wykonywane.';
										|tr = 'Metinlerin otomatik olarak alınması başarısız.'");
		EndIf;
		Items.EditScheduledJob.ExtendedTooltip.Title = SchedulePresentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillScheduledJobInfo(PredefinedItemName)
	InformationRecords = NewInformationAboutTheRoutineTask();
	ScheduledJobsInfo.Insert(PredefinedItemName, InformationRecords);
	Job = ScheduledJobsFindPredefinedItem(PredefinedItemName);
	If Job = Undefined Then
		Return;
	EndIf;
	InformationRecords.Id = Job.UUID;
	InformationRecords.Use = Job.Use;
	InformationRecords.Schedule    = Job.Schedule;
EndProcedure

// Returns:
//  Structure:
//   * Id - UUID 
//   * Use - Boolean
//   * Schedule - JobSchedule
// 
&AtServer
Function NewInformationAboutTheRoutineTask()
	Return New Structure("Id, Use, Schedule");
EndFunction

// Returns:
//   See NewInformationAboutTheRoutineTask
// 
&AtServer
Function ScheduledJobInfo(PredefinedItemName)
	Return ScheduledJobsInfo[PredefinedItemName];
EndFunction

// Returns:
//   See NewInformationAboutTheRoutineTask
// 
&AtClient
Function ScheduledJobInfoClient(PredefinedItemName)
	Return ScheduledJobsInfo[PredefinedItemName];
EndFunction

&AtServer
Function ScheduledJobsFindPredefinedItem(PredefinedItemName)
	Filter = New Structure("Metadata", PredefinedItemName);
	FoundItems = ScheduledJobsServer.FindJobs(Filter);
	Return ?(FoundItems.Count() = 0, Undefined, FoundItems[0]);
EndFunction

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
