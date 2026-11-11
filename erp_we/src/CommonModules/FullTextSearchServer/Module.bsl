///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Updates a full-text search index.
Procedure FullTextSearchIndexUpdate() Export
	
	UpdateIndex(NStr("vi = 'Cập nhật chỉ mục tìm kiếm toàn văn';
					|ru = 'Обновление индекса ППД';
					|en = 'Update full-text search index'; fa = 'به‌روزرسانی نمایه جستجوی تمام‌متن';
					|it = 'Aggiornamento dell''indice di ricerca full-text';
					|pl = 'Aktualizacja indeksu pełnotekstowego wyszukiwania danych (PWD)';
					|tr = 'Tam metin arama endeksini güncelle'"), False, True);
	
EndProcedure

// Merges full-text search indexes.
Procedure FullTextSearchMergeIndex() Export
	
	UpdateIndex(NStr("vi = 'Hợp nhất chỉ mục tìm kiếm toàn văn';
					|ru = 'Слияние индекса ППД';
					|en = 'Merge full-text search index'; fa = 'ادغام نمایه جستجوی تمام‌متن';
					|it = 'Unione dell''indice di ricerca full-text';
					|pl = 'Połączenie indeksu PWD';
					|tr = 'Tam metin arama endeksini birleştir'"), True);
	
EndProcedure

// Returns a flag showing whether full-text search index is up-to-date.
//   The UseFullTextSearch functional option is checked in the calling code.
//
// Returns: 
//   Boolean - True - full-text search contains relevant data.
//
Function SearchIndexIsRelevant() Export
	
	State = FullTextSearchStatus();
	Return State = "SearchAllowed";
	
EndFunction

// Check box state for the full-text search setup form.
//
// Returns: 
//   Number - 0 - disabled, 1 - enabled, 2 - settings error; settings are not synchronized.
//
// Example:
//	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") Then
//		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
//		UseFullTextSearch = ModuleFullTextSearchServer.UseSearchFlagValue();
//	Else 
//		Items.FullTextSearchManagementGroup.Visibility = False;
//	EndIf;
//
Function UseSearchFlagValue() Export
	
	State = FullTextSearchStatus();
	If State = "SearchProhibited" Then
		Result = 0;
	ElsIf State = "SearchSettingsError" Then
		Result = 2;
	Else
		Result = 1;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Returns the current full text search status depending on settings and relevance.
// Does not throw exceptions.
//
// Returns:
//  String - Valid values are:
//    "SearchAllowed"
//    "SearchProhibited"
//    "UpdatingIndex"
//    "IndexMergeInProgress"
//    "IndexUpdateRequired"
//    "SearchSettingsError"
//
Function FullTextSearchStatus() Export
	
	If GetFunctionalOption("UseFullTextSearch") Then 
		
		If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then 
			
			If CurrentDate() < (FullTextSearch.UpdateDate() + 300) Then 
				Return "SearchAllowed";
			Else
				If FullTextSearchIndexIsUpToDate() Then 
					Return "SearchAllowed";
				ElsIf IndexUpdateBackgroundJobInProgress() Then 
					Return "IndexUpdateInProgress";
				ElsIf MergeIndexBackgroundJobInProgress() Then 
					Return "IndexMergeInProgress";
				Else
					Return "IndexUpdateRequired";
				EndIf;
			EndIf;
			
		Else 
			// Desyncing of the "UseFullTextSearch" constant
			// and the full-text search mode set in the infobase.
			Return "SearchSettingsError";
		EndIf;
		
	Else
		If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then
			// Desyncing of the "UseFullTextSearch" constant
			// and the full-text search mode set in the infobase.
			Return "SearchSettingsError";
		Else 
			Return "SearchProhibited";
		EndIf;
	EndIf;
	
EndFunction

// Metadata object with functional option of full text search usage.
//
// Returns:
//   MetadataObjectFunctionalOption - a functional option metadata 
//
Function UseFullTextSearchFunctionalOption() Export
	
	Return Metadata.FunctionalOptions.UseFullTextSearch;
	
EndFunction

// Returns the state of functional option of full text search usage.
//
// Returns:
//   Boolean - — if True, full-text search is used.
//
Function UseFullTextSearch() Export
	
	Return GetFunctionalOption("UseFullTextSearch");
	
EndFunction


#Region ConfigurationSubsystemsEventHandlers

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not GetFunctionalOption("UseFullTextSearch")
		Or Not Users.IsFullUser(, True) Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled("FullTextSearchInData") Then
		Return;
	EndIf;
	
	State = FullTextSearchStatus();
	If State = "SearchProhibited" Then 
		Return;
	EndIf;
	
	Section = Metadata.Subsystems.Find("Administration");
	If Section = Undefined Then
		Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.FullTextSearchInData.FullName());
		If Sections.Count() = 0 Then 
			Return;
		Else 
			Section = Sections[0];
		EndIf;
	EndIf;
	
	// Search setup error.
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id = "FullTextSearchInDataSearchSettingsError";
	ToDoItem.HasToDoItems = (State = "SearchSettingsError");
	ToDoItem.Presentation = NStr("vi = 'Chưa tùy chỉnh tìm kiếm toàn văn';
								|ru = 'Полнотекстовый поиск не настроен';
								|en = 'Full-text search not set up'; fa = 'Full-text search not set up';
								|it = 'Ricerca full-text non impostata.';
								|pl = 'Wyszukiwanie pełnotekstowe nie jest ustawione';
								|tr = 'Tam metin araması ayarlanmadı'");
	ToDoItem.Form = "DataProcessor.FullTextSearchInData.Form.FullTextSearchAndTextExtractionControl";
	ToDoItem.ToolTip = 
		NStr("vi = 'Hãy thử tắt sử dụng tìm kiếm toàn văn và bật sử dụng lại.';
			|ru = 'Попробуйте выключить полнотекстовый поиск и снова включить.';
			|en = 'Try toggling the full-text search off and on.'; fa = 'Try toggling the full-text search off and on.';
			|it = 'Попробуйте выключить полнотекстовый поиск и снова включить.';
			|pl = 'Try toggling the full-text search off and on.';
			|tr = 'Tam Metin Aramasını kapatıp yeniden açabilirsiniz'");
	ToDoItem.Owner = Section;
	
	// Index update is required.
	
	If State = "IndexUpdateRequired" Then 
		IndexUpdateDate = FullTextSearch.UpdateDate();
		CurrentDate = CurrentDate(); // ACC:143 - CurrentDate() must be used.
		
		If IndexUpdateDate > CurrentDate Then
			Interval = NStr("vi = 'ít hơn một ngày trước';
							|ru = 'менее одного дня назад';
							|en = 'less than one day ago'; fa = 'less than one day ago';
							|it = 'meno di un giorno fa';
							|pl = 'mniej niż jeden dzień temu';
							|tr = 'bir günden az süre önce'");
		Else
			Interval = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 quay lại';
					|ru = '%1 назад';
					|en = '%1 ago'; fa = '%1 ago';
					|it = '%1 fa';
					|pl = '%1 do tyłu';
					|tr = '%1 önce'"),
				Common.TimeIntervalString(IndexUpdateDate, CurrentDate));
		EndIf;
		
		DaysFromLastUpdate = Int((CurrentDate - IndexUpdateDate) / 60 / 60 / 24);
		HasToDoItems = (DaysFromLastUpdate >= 1);
	Else 
		Interval = NStr("vi = 'Chưa bao giờ';
						|ru = 'Никогда';
						|en = 'never'; fa = 'never';
						|it = 'Mai';
						|pl = 'Nigdy';
						|tr = 'Hiçbir zaman'");
		HasToDoItems = False;
	EndIf;
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id = "FullTextSearchInDataIndexUpdateRequired";
	ToDoItem.HasToDoItems = HasToDoItems;
	ToDoItem.Presentation = NStr("vi = 'Chỉ mục tìm kiếm toàn văn đã cũ';
								|ru = 'Индекс полнотекстового поиска устарел';
								|en = 'Full-text search index is outdated'; fa = 'Full-text search index is outdated';
								|it = 'L''indice della ricerca full-text è obsoleto';
								|pl = 'Indeks wyszukiwania pełnotekstowego przestarzał';
								|tr = 'Tam metin arama dizini eskidi'");
	ToDoItem.Form = "DataProcessor.FullTextSearchInData.Form.FullTextSearchAndTextExtractionControl";
	ToDoItem.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Cập nhật lần cuối  %1';
			|ru = 'Последнее обновление %1';
			|en = 'Last update: %1.'; fa = 'Last update: %1.';
			|it = 'Ultimo aggiornamento %1';
			|pl = 'Ostatnia aktualizacja %1';
			|tr = 'Son güncelleme %1'"),
		Interval);
	ToDoItem.Owner = Section;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "FullTextSearchServer.InitializeFullTextSearchFunctionalOption";
	Handler.Version = "1.0.0.1";
	Handler.SharedData = True;
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Dependence = Settings.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.FullTextSearchIndexUpdate;
	Dependence.FunctionalOption = UseFullTextSearchFunctionalOption();
	
	Dependence = Settings.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.FullTextSearchMergeIndex;
	Dependence.FunctionalOption = UseFullTextSearchFunctionalOption();
	
EndProcedure

#EndRegion

// Sets a value to the UseFullTextSearch constant.
// Used to synchronize a value
// of the "UseFullTextSearch" functional option
// with the value of the "FullTextSearch.GetFullTextSearchMode" function.
//
Procedure InitializeFullTextSearchFunctionalOption() Export
	
	OperationsAllowed = (FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable);
	Constants.UseFullTextSearch.Set(OperationsAllowed);
	
EndProcedure

#EndRegion

#Region Private

#Region ScheduledJobsHandlers

// Handler of the FullTextSearchIndexUpdate scheduled job.
Procedure FullTextSearchUpdateIndexOnSchedule() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.FullTextSearchIndexUpdate);
	
	If MergeIndexBackgroundJobInProgress() Then
		Return;
	EndIf;
	
	FullTextSearchIndexUpdate();
	
EndProcedure

// Handler of the FullTextSearchMergeIndex scheduled job.
Procedure FullTextSearchMergeIndexOnSchedule() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.FullTextSearchMergeIndex);
	
	If IndexUpdateBackgroundJobInProgress() Then
		Return;
	EndIf;
	
	FullTextSearchMergeIndex();
	
EndProcedure

#EndRegion

#Region SearchBusinessLogic

#Region SearchState

Function IndexUpdateBackgroundJobInProgress()
	
	ScheduledJob = Metadata.ScheduledJobs.FullTextSearchIndexUpdate;
	
	Filter = New Structure;
	Filter.Insert("MethodName", ScheduledJob.MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return CurrentBackgroundJobs.Count() > 0;
	
EndFunction

Function MergeIndexBackgroundJobInProgress()
	
	ScheduledJob = Metadata.ScheduledJobs.FullTextSearchMergeIndex;
	
	Filter = New Structure;
	Filter.Insert("MethodName", ScheduledJob.MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return CurrentBackgroundJobs.Count() > 0;
	
EndFunction

Function FullTextSearchIndexIsUpToDate()
	
	UpToDate = False;
	
	Try
		UpToDate = FullTextSearch.IndexTrue();
	Except
		LogRecord(
			EventLogLevel.Warning, 
			NStr("vi = 'Không thể kiểm tra trạng thái chỉ mục tìm kiếm toàn văn';
				|ru = 'Не удалось проверить состояние индекса полнотекстового поиска';
				|en = 'Failed to check full-text search index status'; fa = 'Failed to check full-text search index status';
				|it = 'Impossibile verificare lo stato dell''indice di ricerca full-text';
				|pl = 'Nie można sprawdzić statusu indeksu wyszukiwania pełnotekstowego';
				|tr = 'Tam metin arama endeks durumu denetlemesi başarısız'"),
			ErrorInfo());
	EndTry;
	
	Return UpToDate;
	
EndFunction

#EndRegion

#Region Searching

Function SearchParameters() Export 
	
	Parameters = New Structure;
	Parameters.Insert("SearchString", "");
	Parameters.Insert("SearchDirection", "FirstPart");
	Parameters.Insert("CurrentPosition", 0);
	Parameters.Insert("SearchInSections", False);
	Parameters.Insert("SearchAreas", New Array);
	
	Return Parameters;
	
EndFunction

Function ExecuteFullTextSearch(SearchParameters) Export 
	
	SearchString = SearchParameters.SearchString;
	Direction = SearchParameters.SearchDirection;
	CurrentPosition = SearchParameters.CurrentPosition;
	SearchInSections = SearchParameters.SearchInSections;
	SearchAreas = SearchParameters.SearchAreas;
	
	PortionSize = 10;
	ErrorDescription = "";
	ErrorCode = "";
	
	SearchResultsList = FullTextSearch.CreateList(SearchString, PortionSize);
	
	If SearchInSections And SearchAreas.Count() > 0 Then
		SearchResultsList.MetadataUse = FullTextSearchMetadataUse.DontUse;
		
		For Each Area In SearchAreas Do
			MetadataObject = Common.MetadataObjectByID(Area.Value, False);
			If TypeOf(MetadataObject) = Type("MetadataObject") Then 
				SearchResultsList.SearchArea.Add(MetadataObject);
			EndIf;
		EndDo;
	EndIf;
	
	Try
		If Direction = "FirstPart" Then
			SearchResultsList.FirstPart();
		ElsIf Direction = "PreviousPart" Then
			SearchResultsList.PreviousPart(CurrentPosition);
		ElsIf Direction = "NextPart" Then
			SearchResultsList.NextPart(CurrentPosition);
		Else 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã đặt sai tham số %1. Dự kiến một trong các giá trị: ""%2"", ""%3"" hoặc ""%4"".';
					|ru = 'Параметр %1 задан неверно. Ожидалось одно из значений: ""%2"", ""%3"" или ""%4"".';
					|en = 'Invalid value in parameter ""%1"". Expected value is ""%2"", ""%3"", or ""%4"".'; fa = 'Invalid value in parameter ""%1"". Expected value is ""%2"", ""%3"", or ""%4"".';
					|it = 'Parametro %1 indicato in modo errato. Si attendeva uno dei valori: ""%2"", ""%3"" o ""%4""';
					|pl = 'Parametr %1 jest zadany nieprawidłowo. Była oczekiwana jedna z wartości: ""%2"", ""%3"" lub ""%4"".';
					|tr = '%1 parametresi yanlış ayarlandı. Beklenen değerler: ""%2"", ""%3"" veya ""%4"".'"),
				"SearchDirection", "FirstPart", "PreviousPart", "NextPart");
		EndIf;
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorCode = "SearchError";
	EndTry;
	
	If SearchResultsList.TooManyResults() Then 
		ErrorDescription = NStr("vi = 'Quá nhiều kết quả, hãy làm rõ yêu cầu';
								|ru = 'Слишком много результатов, уточните запрос';
								|en = 'Too many results. Please narrow your search.'; fa = 'Too many results. Please narrow your search.';
								|it = 'Troppi risultati, perfezionate la query';
								|pl = 'Zbyt dużo wyników, uściślij zapytanie';
								|tr = 'Çok fazla sonuç var, aramanızı netleştirin'");
		ErrorCode = "TooManyResults";
	EndIf;
	
	TotalCount = SearchResultsList.TotalCount();
	
	If TotalCount = 0 Then
		ErrorDescription = NStr("vi = 'Theo truy vấn không tìm thấy gì';
								|ru = 'По запросу ничего не найдено';
								|en = 'No results found'; fa = 'No results found';
								|it = 'Non è stato trovato nulla secondo la query';
								|pl = 'Na zapytanie nic nie wyszukano';
								|tr = 'Sonuç bulunamadı'");
		ErrorCode = "FoundNothing";
	EndIf;
	
	If IsBlankString(ErrorCode) Then 
		SearchResults = FullTextSearchResults(SearchResultsList);
	Else 
		SearchResults = New Array;
	EndIf;
	
	Result = New Structure;
	Result.Insert("CurrentPosition", SearchResultsList.StartPosition());
	Result.Insert("Count", SearchResultsList.Count());
	Result.Insert("TotalCount", TotalCount);
	Result.Insert("ErrorCode", ErrorCode);
	Result.Insert("ErrorDescription", ErrorDescription);
	Result.Insert("SearchResults", SearchResults);
	
	Return Result;
	
EndFunction

Function FullTextSearchResults(SearchResultsList)
	
	Result = New Array;

	HTMLSearchStrings = HTMLSearchResultStrings(SearchResultsList);
	For IndexOf = 0 To SearchResultsList.Count() - 1 Do
		
		HTMLDetails  = HTMLSearchStrings.HTMLDetails1.Get(IndexOf);
		Presentation = HTMLSearchStrings.Presentations.Get(IndexOf);
		SearchListString = SearchResultsList.Get(IndexOf);
		
		ObjectMetadata = SearchListString.Metadata;
		Value = SearchListString.Value;
		
		SSLSubsystemsIntegration.OnGetFullTextSearchResults(ObjectMetadata, Value, Presentation);
		
		Ref = "";
		Try
			Ref = GetURL(Value);
		Except
			Ref = "#"; // Unintended to be opened.
		EndTry;
		
		ResultString1 = New Structure;
		ResultString1.Insert("Ref",        Ref);
		ResultString1.Insert("HTMLDetails",  HTMLDetails);
		ResultString1.Insert("Presentation", Presentation);
		
		Result.Add(ResultString1);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function HTMLSearchResultStrings(SearchResultsList)
	
	HTMLListDisplay = SearchResultsList.GetRepresentation(FullTextSearchRepresentationType.HTMLText);
	
	// Get the DOM to display the list. NOTE: DOM getter cannot be implemented as a dedicated function:
	// 1C:Enterprise throws an error in the call stack of the DOM read stream.
	HTMLReader = New HTMLReader;
	HTMLReader.SetString(HTMLListDisplay);
	DOMBuilder = New DOMBuilder;
	DOMListDisplay = DOMBuilder.Read(HTMLReader);
	HTMLReader.Close();
	
	DivDOMItemsList = DOMListDisplay.GetElementByTagName("div");
	HTMLDetailsStrings = HTMLDetailsStrings(DivDOMItemsList);
	
	AnchorDOMItemsList = DOMListDisplay.GetElementByTagName("a");
	PresentationStrings = PresentationStrings(AnchorDOMItemsList);
	
	Result = New Structure;
	Result.Insert("HTMLDetails1", HTMLDetailsStrings);
	Result.Insert("Presentations", PresentationStrings);
	
	Return Result;
	
EndFunction

Function HTMLDetailsStrings(DivDOMItemsList)
	
	HTMLDetailsStrings = New Array;
	For Each DOMElement In DivDOMItemsList Do 
		
		If DOMElement.ClassName = "textPortion" Then 
			
			DOMWriter = New DOMWriter;
			HTMLWriter = New HTMLWriter;
			HTMLWriter.SetString();
			DOMWriter.Write(DOMElement, HTMLWriter);
			
			HTMLResultStringDetails = HTMLWriter.Close();
			
			HTMLDetailsStrings.Add(HTMLResultStringDetails);
			
		EndIf;
	EndDo;
	
	Return HTMLDetailsStrings;
	
EndFunction

Function PresentationStrings(AnchorDOMItemsList)
	
	PresentationStrings = New Array;
	For Each DOMElement In AnchorDOMItemsList Do
		
		Presentation = DOMElement.TextContent;
		PresentationStrings.Add(Presentation);
		
	EndDo;
	
	Return PresentationStrings;
	
EndFunction

#EndRegion

#Region SearchIndexUpdate

// Common procedure for updating and merging a full-text search index.
Procedure UpdateIndex(ProcedurePresentation, EnableJoining = False, InPortions = False)
	
	If (FullTextSearch.GetFullTextSearchMode() <> FullTextSearchMode.Enable) Then
		Return;
	EndIf;
	
	Common.OnStartExecuteScheduledJob();
	
	LogRecord(
		Undefined, 
		NStr("vi = 'Khởi động thủ tục ""%1"".';
			|ru = 'Запуск процедуры ""%1"".';
			|en = 'Starting %1.'; fa = 'Starting %1.';
			|it = 'Avvio della procedura ""%1"".';
			|pl = 'Uruchomienie procedury ""%1"".';
			|tr = '""%1"" Prosedürünü başlatın.'"),,
		ProcedurePresentation);
	
	Try
		FullTextSearch.UpdateIndex(EnableJoining, InPortions);
		LogRecord(
			Undefined, 
			NStr("vi = 'Hoàn tất thành công thủ tục ""%1"".';
				|ru = 'Успешное завершение процедуры ""%1"".';
				|en = '%1 is successfully completed.'; fa = '%1 is successfully completed.';
				|it = 'Terminazione riuscita della procedura ""%1"".';
				|pl = 'Pomyślnе zakończenie procedury ""%1"".';
				|tr = '""%1"" prosedürü başarı ile tamamlandı.'"),, 
			ProcedurePresentation);
	Except
		LogRecord(
			EventLogLevel.Warning, 
			NStr("vi = 'Không thể thực hiện thủ tục ""%1"":';
				|ru = 'Не удалось выполнить процедуру ""%1"":';
				|en = 'Failed to execute %1:'; fa = 'Failed to execute %1:';
				|it = 'Impossibile eseguire la procedura ""%1"":';
				|pl = 'Nie można wykonać procedury „%1”:';
				|tr = '""%1"" prosedürü yürütülemedi:'"),
			ErrorInfo(), 
			ProcedurePresentation);
	EndTry;
	
EndProcedure

// Parameters:
//   LogLevel - EventLogLevel - message importance for the administrator.
//   CommentWithParameters - String - a comment that can contain parameters %1.
//   ErrorInfo - ErrorInfo
//                      - String - error information placed after the comment.
//   Parameter - String - replaces %1 in CommentWithParameters.
//
Procedure LogRecord(LogLevel, CommentWithParameters, ErrorInfo = Undefined,
	Parameter = Undefined) Export
	
	If TypeOf(LogLevel) <> Type("EventLogLevel") Then
		If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
			LogLevel = EventLogLevel.Error;
		ElsIf TypeOf(ErrorInfo) = Type("String") Then
			LogLevel = EventLogLevel.Warning;
		Else
			LogLevel = EventLogLevel.Information;
		EndIf;
	EndIf;
	
	TextForLog = CommentWithParameters;
	If Parameter <> Undefined Then
		TextForLog = StringFunctionsClientServer.SubstituteParametersToString(TextForLog, Parameter);
	EndIf;
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		TextForLog = TextForLog + Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo);
	ElsIf TypeOf(ErrorInfo) = Type("String") Then
		TextForLog = TextForLog + Chars.LF + ErrorInfo;
	EndIf;
	TextForLog = TrimAll(TextForLog);
	
	WriteLogEvent(NStr("vi = 'Chỉ mục tìm kiếm toàn văn';
						|ru = 'Полнотекстовое индексирование';
						|en = 'Full-text indexing'; fa = 'Full-text indexing';
						|it = 'Indicizzazione full-text';
						|pl = 'Indeksowanie pełnotekstowe';
						|tr = 'Tam metin indeksleme'", Common.DefaultLanguageCode()), 
		LogLevel, , , TextForLog);
	
EndProcedure

#EndRegion

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("InitializeFullTextSearchFunctionalOption");
	
EndProcedure

#EndRegion
