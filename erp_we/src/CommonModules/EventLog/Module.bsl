///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Handles bunch message writing to the event log.
// The EventsForEventLog variable is cleared after writing.
//
// Parameters:
//  EventsForEventLog - Array of Structure:
//   * EventName           - String - Name of an event in the event log.
//   * LevelPresentation  - String - Name of the EventLogLevel collection value 
//                                     : Information, Error, Warning, Note.
//   * Comment          - String - Event comment for the Event Log.
//   * EventDate          - Date   - Event date inserted at the beginning of comment
//                                     (if not specified, the current session date is used).
//
Procedure WriteEventsToEventLog(EventsForEventLog) Export
	
	If TypeOf(EventsForEventLog) <> Type("Array")
	   And TypeOf(EventsForEventLog) <> Type("ValueList") Then
		Return;
	EndIf;
	
	If EventsForEventLog.Count() = 0 Then
		Return;
	EndIf;
	
	EventForEventLog = ?(TypeOf(EventsForEventLog) = Type("Array"),
		EventsForEventLog, EventsForEventLog.UnloadValues());
	
	For Each MessageValue In EventForEventLog Do
		EventName = MessageValue.EventName;
		EventLevel = EventLevelByPresentation(MessageValue.LevelPresentation);
		EventDate = Undefined;
		If MessageValue.Property("EventDate") And ValueIsFilled(MessageValue.EventDate) Then
			EventDate = MessageValue.EventDate;
		EndIf;
		If TypeOf(EventDate) <> Type("Date") Then
			EventDate = CurrentSessionDate();
		EndIf;
		Comment = Format(EventDate, "DLF=DT") + " " + MessageValue.Comment;
		WriteLogEvent(EventName, EventLevel,,, Comment);
	EndDo;
	EventsForEventLog.Clear();
	
EndProcedure

#EndRegion

#Region Internal

// Write the message to the event log.
//
//  Parameters: 
//   EventName       - String - an event name for the event log.
//   Level          - EventLogLevel - events importance level of the log event.
//   MetadataObject - MetadataObject - metadata object that the event refers to.
//   Data           - AnyRef
//                    - Number
//                    - String
//                    - Date
//                    - Boolean
//                    - Undefined
//                    - Type - data that the event is related to.
//                      It is recommended to specify references to the data objects (catalog items, documents that the event
//                      refers to).
//   Comment      - String - the comment to the log event.
//
Procedure AddMessageForEventLog(Val EventName, Val Level,
		Val MetadataObject = Undefined, Val Data = Undefined, Val Comment = "") Export
		
	If IsBlankString(EventName) Then
		EventName = "Event"; // not localized to prevent startup from stopping in a partially translated configuration
	EndIf;

	WriteLogEvent(EventName, Level, MetadataObject, Data, Comment, EventLogEntryTransactionMode.Independent);
	
EndProcedure

// Reads event log message texts taking into account the filter settings.
//
// Parameters:
//
//     ReportParameters - Structure - contains parameters for reading events from the event log. Contains fields:
//      *  Log                  - ValueTable         - contains records of the event log.
//      *  EventLogFilter   - Structure             - filter settings used to read the event log records:
//          ** StartDate - Date - start date of events (optional).
//          ** EndDate - Date - end date of events (optional).
//      *  EventCount1       - Number                   - maximum number of records that can be read from the event log.
//      *  UUID - UUID - a form UUID.
//      *  OwnerManager       - Arbitrary            - event
//                                                             log is displayed in the form of this object. The manager is used to call back appearance
//                                                             functions.
//      *  AddAdditionalColumns - Boolean           - determines whether callback is needed to add
//                                                             additional columns.
//     StorageAddress - String
//                    - UUID - Address of the temporary storage that stores the result.
//
// Result is a structure with the following fields::
//     LogEvents - ValueTable - Selected events.
//
Procedure ReadEventLogEvents(ReportParameters, StorageAddress) Export
	
	EventLogFilterAtClient          = ReportParameters.EventLogFilter;
	EventCount1              = ReportParameters.EventsCountLimit;
	OwnerManager              = ReportParameters.OwnerManager;
	AddAdditionalColumns = ReportParameters.AddAdditionalColumns;
	
	// Verifying the parameters.
	StartDate    = Undefined;
	EndDate = Undefined;
	FilterDatesSpecified = EventLogFilterAtClient.Property("StartDate", StartDate) And EventLogFilterAtClient.Property("EndDate", EndDate)
		And ValueIsFilled(StartDate) And ValueIsFilled(EventLogFilterAtClient.EndDate);
		
	If FilterDatesSpecified And StartDate > EndDate Then
		Raise NStr("vi = 'Điền sai điều kiện lọc của nhật ký sự kiện. Ngày bắt đầu lớn hơn ngày kết thúc.';
					|ru = 'Некорректно заданы условия отбора журнала регистрации. Дата начала больше даты окончания.';
					|en = 'Invalid event log filter settings. The start date is later than the end date.'; fa = 'Invalid event log filter settings. The start date is later than the end date.';
					|it = 'Condizioni impostate in modo errato per la selezione del registro. La data di inizio è maggiore della data di fine.';
					|pl = 'Niepoprawnie ustawione warunki selekcji dziennika rejestracji. Data rozpoczęcią jest póżniejsza niż data zakończenia.';
					|tr = 'Olay günlüğünün filtre ayarları yanlış. Başlangıç tarihi bitiş tarihinden ileri.'");
	EndIf;
	ServerTimeOffset = ServerTimeOffset();
	
	// Prepare the filter.
	Filter = New Structure;
	For Each FilterElement In EventLogFilterAtClient Do
		Filter.Insert(FilterElement.Key, FilterElement.Value);
	EndDo;
	
	FilterTransformation(Filter, ServerTimeOffset);
	
	// Exporting the selected events and generating the table structure.
	LogEvents = New ValueTable;
	UnloadEventLog(LogEvents, Filter, , , EventCount1);
	
	LogEvents.Columns.Date.Name = "DateAtServer";
	LogEvents.Columns.Add("Date", New TypeDescription("Date"));
	
	LogEvents.Columns.Add("PicNumber", New TypeDescription("Number"));
	LogEvents.Columns.Add("DataAsStr", New TypeDescription("String"));
	LogEvents.Columns.Add("EventKey", New TypeDescription("String"));
	
	If Common.SeparatedDataUsageAvailable() Then
		LogEvents.Columns.Add("SessionDataSeparation", New TypeDescription("ValueList"));
		LogEvents.Columns.Add("SessionDataSeparationPresentation", New TypeDescription("String"));
	EndIf;
	LogEvents.Columns.Add("DataArea", New TypeDescription("String"));
	
	If AddAdditionalColumns Then
		OwnerManager.AddAdditionalEventColumns(LogEvents);
	EndIf;
	
	LogEvents.Columns.Add("MetadataList", New TypeDescription("ValueList"));
	LogEvents.Columns.Add("IsDataStringMatchesDataPresentation", New TypeDescription("Boolean"));
	
	If Common.DataSeparationEnabled()
	   And Common.SeparatedDataUsageAvailable()
	   And Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		UserAliases    = New Map();
	Else
		ModuleSaaSOperations = Undefined;
		UserAliases    = Undefined;
	EndIf;
	
	KeyStructure1 = New Structure;
	For Each Column In LogEvents.Columns Do
		KeyStructure1.Insert(Column.Name);
	EndDo;
	
	KeysPresentation = StructuresKeysPresentation();
	
	For Each LogEvent In LogEvents Do
		LogEvent.Date = LogEvent.DateAtServer - ServerTimeOffset;
		
		// Filling numbers of row pictures.
		OwnerManager.SetPictureNumber(LogEvent);
		
		If AddAdditionalColumns Then
			// Filling additional fields that are defined for the owner only.
			OwnerManager.FillInAdditionalEventColumns(LogEvent);
		EndIf;
		
		// Converting the array of metadata into a value list.
		If TypeOf(LogEvent.Metadata) = Type("Array") Then
			AddPresentation = TypeOf(LogEvent.MetadataPresentation) = Type("Array")
			   And LogEvent.MetadataPresentation.Count() = LogEvent.Metadata.Count();
			IndexOf = 0;
			For Each FullName In LogEvent.Metadata Do
				LogEvent.MetadataList.Add(FullName,
					?(AddPresentation, LogEvent.MetadataPresentation[IndexOf], ""));
				IndexOf = IndexOf + 1;
			EndDo;
		Else
			LogEvent.MetadataList.Add(LogEvent.Metadata,
				LogEvent.MetadataPresentation);
		EndIf;
		
		// Convert an array of metadata presentations into a string.
		If TypeOf(LogEvent.MetadataPresentation) = Type("Array") Then
			LogEvent.MetadataPresentation = StrConcat(LogEvent.MetadataPresentation, ", ");
		Else
			LogEvent.MetadataPresentation = String(LogEvent.MetadataPresentation);
		EndIf;
		
		// Convert the "SessionDataSeparation" array into a value list.
		If Not Common.SeparatedDataUsageAvailable() Then
			FullSessionDataSeparationPresentation = "";
			SessionDataSeparation = LogEvent.SessionDataSeparation;
			SeparatedDataAttributeList = New ValueList;
			For Each SessionSeparator In SessionDataSeparation Do
				SeparatorPresentation = Metadata.CommonAttributes.Find(SessionSeparator.Key).Presentation();
				SeparatorPresentation = SeparatorPresentation + " = " + SessionSeparator.Value;
				SeparatorValue = SessionSeparator.Key + "=" + SessionSeparator.Value;
				SeparatedDataAttributeList.Add(SeparatorValue, SeparatorPresentation);
				FullSessionDataSeparationPresentation = ?(Not IsBlankString(FullSessionDataSeparationPresentation),
				                                            FullSessionDataSeparationPresentation + "; ", "")
				                                            + SeparatorPresentation;
			EndDo;
			If Not ValueIsFilled(SessionDataSeparation) Then
				LogEvent.DataArea = "-";
				For Each CommonAttribute In Metadata.CommonAttributes Do
					If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse Then
						Continue;
					EndIf;
					SeparatorPresentation = CommonAttribute.Presentation() + " = " + NStr("vi = '<Chưa đặt>';
																							|ru = '<Не задано>';
																							|en = '<Not specified>'; fa = '<مشخص نشده>';
																							|it = '<Non impostato>';
																							|pl = '<Nie określono>';
																							|tr = '<Belirlenmedi>'");
					SeparatorValue = CommonAttribute.Name + "=";
					SeparatedDataAttributeList.Add(SeparatorValue, SeparatorPresentation);
				EndDo;
			ElsIf Not SessionDataSeparation.Property("DataAreaMainData") Then
				LogEvent.DataArea = "?";
			Else
				LogEvent.DataArea = Format(SessionDataSeparation.DataAreaMainData, "NZ=0; NG=");
			EndIf;
			LogEvent.SessionDataSeparation = SeparatedDataAttributeList;
			LogEvent.SessionDataSeparationPresentation = FullSessionDataSeparationPresentation;
		EndIf;
		
		// Processing special event data.
		If LogEvent.Event = "_$Access$_.Access" Then
			SetDataString(LogEvent);
			
			If LogEvent.Data <> Undefined Then
				LogEvent.Data = TableDataPresentation(LogEvent.Data);
			EndIf;
			
		ElsIf LogEvent.Event = "_$Access$_.AccessDenied" Then
			SetDataString(LogEvent);
			
			If LogEvent.Data <> Undefined Then
				If LogEvent.Data.Property("Right") Then
					LogEvent.Data = StructureDataPresentation(LogEvent.Data,
						KeysPresentation);
				Else
					LogEvent.Data = StructureDataPresentation(LogEvent.Data,
						KeysPresentation, True) + "
						|" + TableDataPresentation(LogEvent.Data);
				EndIf;
			EndIf;
			
		ElsIf TypeOf(LogEvent.Data) = Type("Structure")
		      Or TypeOf(LogEvent.Data) = Type("FixedStructure") Then
			
			SetDataString(LogEvent);
			LogEvent.Data = StructureDataPresentation(LogEvent.Data,
				KeysPresentation);
			
		ElsIf TypeOf(LogEvent.Data) = Type("String") Then
			Data = DataFromXMLString(LogEvent.Data);
			If Data <> Undefined Then
				SetDataString(LogEvent);
				LogEvent.Data = StructureDataPresentation(Data, KeysPresentation);
			EndIf;
		EndIf;
		
		SetPrivilegedMode(True);
		// Refine the user name.
		If LogEvent.User = New UUID("00000000-0000-0000-0000-000000000000") Then
			LogEvent.UserName = NStr("vi = '<Không xác định>';
									|ru = '<Неопределен>';
									|en = '<Undefined>'; fa = '<Undefined>';
									|it = '<Non definito>';
									|pl = '<Undefined>';
									|tr = '<Belirlenmedi>'");
			
		ElsIf LogEvent.UserName = "" Then
			LogEvent.UserName = Users.UnspecifiedUserFullName();
			
		ElsIf InfoBaseUsers.FindByUUID(LogEvent.User) = Undefined Then
			LogEvent.UserName = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 <Đã xóa>';
																								|ru = '%1 <Удален>';
																								|en = '%1 <Deleted>'; fa = '%1 <Deleted>';
																								|it = '%1 <Cancellato>';
																								|pl = '%1 <Usunięty>';
																								|tr = '%1<Silindi>'"), LogEvent.UserName);
		EndIf;
		
		If ModuleSaaSOperations <> Undefined Then
			If UserAliases.Get(LogEvent.User) = Undefined Then
				UserAlias = ModuleSaaSOperations.AliasOfUserOfInformationBase(LogEvent.User);
				UserAliases.Insert(LogEvent.User, UserAlias);
			Else
				UserAlias = UserAliases.Get(LogEvent.User);
			EndIf;
			
			If ValueIsFilled(UserAlias) Then
				LogEvent.UserName = UserAlias;
			EndIf;
		EndIf;
		
		If String(LogEvent.DataPresentation) = String(LogEvent.Data) Then
			LogEvent.IsDataStringMatchesDataPresentation = True;
		EndIf;
		
		LogEvent.Comment = CommonClientServer.ReplaceProhibitedXMLChars(
			LogEvent.Comment);
		
		FillPropertyValues(KeyStructure1, LogEvent);
		Hashing = New DataHashing(HashFunction.SHA256);
		Hashing.Append(ValueToStringInternal(KeyStructure1));
		LogEvent.EventKey = Base64String(Hashing.HashSum);
		
		SetPrivilegedMode(False);
	EndDo;
	
	LogEvents.Columns.Delete("Metadata");
	LogEvents.Columns.MetadataList.Name = "Metadata";
	
	// Completed successfully.
	Result = New Structure;
	Result.Insert("LogEvents", LogEvents);
	
	PutToTempStorage(Result, StorageAddress);
EndProcedure

// Creates a custom event log presentation.
//
// Parameters:
//  FilterPresentation - String - the string that contains custom presentation of the filter.
//  EventLogFilter - Structure - values of the event log filter.
//  DefaultEventLogFilter - Structure - default values of the event log filter 
//     (not included in the user presentation).
//
Procedure GenerateFilterPresentation(FilterPresentation, EventLogFilter, 
		DefaultEventLogFilter = Undefined) Export
	
	FilterPresentation = "";
	// Interval.
	PeriodStartDate    = Undefined;
	PeriodEndDate = Undefined;
	If Not EventLogFilter.Property("StartDate", PeriodStartDate)
		Or PeriodStartDate = Undefined Then
		PeriodStartDate    = '00010101000000';
	EndIf;
	
	If Not EventLogFilter.Property("EndDate", PeriodEndDate)
		Or PeriodEndDate = Undefined Then
		PeriodEndDate = '00010101000000';
	EndIf;
	
	If Not (PeriodStartDate = '00010101000000' And PeriodEndDate = '00010101000000') Then
		FilterPresentation = PeriodPresentation(PeriodStartDate, PeriodEndDate);
	EndIf;
	
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "User");
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation,
		"Event", DefaultEventLogFilter);
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation,
		"ApplicationName", DefaultEventLogFilter);
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "Session");
	AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, "Level");
	
	// All other restrictions are specified by presentations without values.
	For Each FilterElement In EventLogFilter Do
		RestrictionName = FilterElement.Key;
		If Upper(RestrictionName) = Upper("StartDate")
			Or Upper(RestrictionName) = Upper("EndDate")
			Or Upper(RestrictionName) = Upper("Event")
			Or Upper(RestrictionName) = Upper("ApplicationName")
			Or Upper(RestrictionName) = Upper("User")
			Or Upper(RestrictionName) = Upper("Session")
			Or Upper(RestrictionName) = Upper("Level") Then
			Continue; // Interval and special restrictions are already displayed.
		EndIf;
		
		// Changing restrictions for some of presentations.
		If Upper(RestrictionName) = Upper("ApplicationName") Then
			RestrictionName = NStr("vi = 'Ứng dụng';
									|ru = 'Приложение';
									|en = 'Application'; fa = 'برنامه';
									|it = 'Applicazione';
									|pl = 'Załącznik';
									|tr = 'Uygulama'");
		ElsIf Upper(RestrictionName) = Upper("TransactionStatus") Then
			RestrictionName = NStr("vi = 'Trạng thái giao tác';
									|ru = 'Статус транзакции';
									|en = 'Transaction status'; fa = 'وضعیت تراکنش';
									|it = 'Stato della transazione';
									|pl = 'Status transakcji';
									|tr = 'İşlem durumu'");
		ElsIf Upper(RestrictionName) = Upper("DataPresentation") Then
			RestrictionName = NStr("vi = 'Trình bày dữ liệu';
									|ru = 'Представление данных';
									|en = 'Data presentation'; fa = 'نمایش داده';
									|it = 'Presentazione dei dati';
									|pl = 'Prezentacja danych';
									|tr = 'Veri sunumu'");
		ElsIf Upper(RestrictionName) = Upper("ServerName") Then
			RestrictionName = NStr("vi = 'Server làm việc';
									|ru = 'Рабочий сервер';
									|en = 'Working server'; fa = 'Working server';
									|it = 'Server di lavoro';
									|pl = 'Serwer działający';
									|tr = 'Çalışan sunucu'");
		ElsIf Upper(RestrictionName) = Upper("PrimaryIPPort") Then
			RestrictionName = NStr("vi = 'Cổng IP chính';
									|ru = 'Основной IP порт';
									|en = 'IP port'; fa = 'IP port';
									|it = 'Porta IP principale';
									|pl = 'Główny port IP';
									|tr = 'Ana IP portu'");
		ElsIf Upper(RestrictionName) = Upper("SyncPort") Then
			RestrictionName = NStr("vi = 'Cổng IP phụ trợ';
									|ru = 'Вспомогательный IP порт';
									|en = 'Auxiliary IP port'; fa = 'Auxiliary IP port';
									|it = 'Porta IP ausiliaria';
									|pl = 'Dodatkowy port IP';
									|tr = 'Yardımcı IP port'");
		ElsIf Upper(RestrictionName) = Upper("SessionDataSeparation") Then
			If StandardSeparatorsOnly() Then
				RestrictionName = NStr("vi = 'Vùng dữ liệu';
										|ru = 'Область данных';
										|en = 'Data area'; fa = 'ناحیه داده';
										|it = 'Area dati';
										|pl = 'Obszar danych';
										|tr = 'Veri alanı'");
			Else
				RestrictionName = NStr("vi = 'Phân chia dữ liệu của phiên làm việc';
										|ru = 'Разделение данных сеанса';
										|en = 'Session data separation'; fa = 'تفکیک داده‌های جلسه';
										|it = 'Separazione dei dati della sessione';
										|pl = 'Podział danych sesji';
										|tr = 'Oturum veri ayırma'");
			EndIf;
		EndIf;
		
		If Not IsBlankString(FilterPresentation) Then 
			FilterPresentation = FilterPresentation + "; ";
		EndIf;
		FilterPresentation = FilterPresentation + RestrictionName;
		
	EndDo;
	
	If IsBlankString(FilterPresentation) Then
		FilterPresentation = NStr("vi = 'Chưa thiết lập';
									|ru = 'Не установлен';
									|en = 'Not set'; fa = 'تنظیم نشده';
									|it = 'Non impostato';
									|pl = 'Nie ustawiono';
									|tr = 'Gönderilmedi'");
	EndIf;
	
EndProcedure

// Determines the server time offset relative to the application time.
//
// Returns:
//   Number - time offset, in seconds.
//       Can be used to convert log filters to the server date
//       and also to convert dates obtained from the log to the application dates.
//
Function ServerTimeOffset() Export
	
	ServerTimeOffset = CurrentDate() - CurrentSessionDate(); // ACC:143 - Computer data is required
	If ServerTimeOffset >= -1 And ServerTimeOffset <= 1 Then
		ServerTimeOffset = 0;
	EndIf;
	Return ServerTimeOffset;
	
EndFunction

// Returns the address of the XML file containing the Event log intended for the support.
// Filtered log records in the EventLogFilter parameter align with the UnloadEventLog method.
// If a filter property is missing or set to Undefined, the filter won't apply.
// 
// Parameters:
//  EventLogFilter - Structure:
//   * StartDate - Date
//   * EndDate - Date
//   * Level - EventLogLevel
//   * ApplicationName - String
//                   - Array of String
//                   - ValueList
//   * User - InfoBaseUser
//                  - String
//                  - Array of InfoBaseUser
//                  - ValueList
//   * Computer - String
//               - Array of String
//                - ValueList
//   * Event - String
//             - ValueList
//             - Array of String - See Syntax Assistant for the names of system events.
//   * Metadata - MetadataObject 
//                - Array of MetadataObject
//                - ValueList
//   * Data - AnyRef
//   * DataPresentation - String
//   * Comment - String
//   * TransactionStatus - EventLogEntryTransactionStatus
//   * Transaction - String 
//   * Session - Number
//           - Array of Number
//           - ValueList
//   * ServerName - String
//                   - Array of String
//                   - ValueList
//   * PrimaryIPPort - Number
//                    - Array of Number
//                    - ValueList
//   * SyncPort - Number
//                    - Array of Number
//                    - ValueList
//   * SessionDataSeparation - ValueList - Property names align with common attribute names. 
//                            - Structure
//  EventCount1 - Number
//  UUID - UUID - Intended for creating a temporary storage.
// 
// Returns:
//  String 
//
Function TechnicalSupportLog(EventLogFilter, EventCount1, UUID = Undefined) Export
	
	Filter = New Structure;
	For Each FilterElement In EventLogFilter Do
		Filter.Insert(FilterElement.Key, FilterElement.Value);
	EndDo;
	ServerTimeOffset = ServerTimeOffset();
	FilterTransformation(Filter, ServerTimeOffset);
	
	TempFile = GetTempFileName("xml");
	UnloadEventLog(TempFile, Filter, , , EventCount1);
	BinaryData = New BinaryData(TempFile);
	DeleteFiles(TempFile);
	
	Return PutToTempStorage(BinaryData, UUID);
	
EndFunction

// Returns an infobase user to be passed to the "User" property
// of the Event Log filter.
//
// Parameters:
//  Id - UUID - Infobase user id.
//
// Returns:
//  InfoBaseUser
//  Undefined
//
Function InfobaseUserForFilter(Id) Export
	
	IBUser = InfoBaseUsers.FindByUUID(Id);
	
	If IBUser <> Undefined Then
		Return IBUser;
	EndIf;
	
	Try
		IsEmpty = InfoBaseUsers.FindByName("");
		InfobaseUserString = ValueToStringInternal(IsEmpty);
		InfobaseUserString = StrReplace(InfobaseUserString,
			Lower(IsEmpty.UUID), Lower(Id));
		IBUser = ValueFromStringInternal(InfobaseUserString);
	Except
		IBUser = Undefined;
	EndTry;
	
	Return IBUser;
	
EndFunction

#EndRegion

#Region Private

// Parameters:
//  DataAsStr - String
//
// Returns:
//  Arbitrary
//
Function EventData(DataAsStr) Export
	
	If Not ValueIsFilled(DataAsStr) Then
		Return Undefined;
	EndIf;
	
	Try
		Result = ValueFromStringInternal(DataAsStr);
	Except
		Result = Undefined;
	EndTry;
	
	Return Result;
	
EndFunction

// Parameters:
//  EventData - String
//
// Returns:
//  Structure - If the conversion is successful.
//  Undefined - If the conversion failed.
//
Function DataFromXMLString(EventData) Export
	
	If TypeOf(EventData) <> Type("String")
	 Or Not StrStartsWith(EventData, "<")
	 Or Not StrEndsWith(EventData, ">") Then
		Return Undefined;
	EndIf;
	
	Try
		Data = Common.ValueFromXMLString(EventData);
	Except
		Data = Undefined;
	EndTry;
	
	If TypeOf(Data) = Type("Structure") Then
		Return Data;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function TableDataPresentation(EventData)
	
	If TypeOf(EventData) <> Type("Structure")
	   And TypeOf(EventData) <> Type("FixedStructure")
	 Or Not EventData.Property("Data")
	 Or TypeOf(EventData.Data) <> Type("ValueTable") Then
		Return "";
	EndIf;
	
	Data = EventData.Data; // ValueTable
	
	RowsCount = Data.Count();
	If RowsCount = 0 Then
		Return "";
	EndIf;
	
	Table = New ValueTable;
	For Each Column In Data.Columns Do
		NewColumn = Table.Columns.Add(Column.Name,
			New TypeDescription("String"), Column.Title);
		If Not ValueIsFilled(NewColumn.Title) Then
			NewColumn.Title = NewColumn.Name;
		EndIf;
	EndDo;
	For Each TableRow In Data Do
		FillPropertyValues(Table.Add(), TableRow);
	EndDo;
	
	Copy = Table.Copy();
	For Each Column In Table.Columns Do
		Copy.Sort(Column.Name);
		Width = StrLen(Copy.Get(RowsCount - 1)[Column.Name]);
		TitleWidth = StrLen(Column.Title);
		Column.Width = ?(Width > TitleWidth, Width, TitleWidth);
	EndDo;
	
	IndentChars = "                                                             ";
	
	Rows = New Array;
	StringParts1 = New Array;
	For Each Column In Table.Columns Do
		StringParts1.Add(Mid(Column.Title + IndentChars, 1, Column.Width));
	EndDo;
	Rows.Add("| " + StrConcat(StringParts1, " | ") + " |");
	
	For Each TableRow In Table Do
		StringParts1 = New Array;
		For Each Column In Table.Columns Do
			StringParts1.Add(Mid(TableRow[Column.Name] + IndentChars, 1, Column.Width));
		EndDo;
		Rows.Add("| " + StrConcat(StringParts1, " | ") + " |");
	EndDo;
	
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

Function StructureDataPresentation(EventData, KeysPresentation, IsDataPropertyExcluded = False)
	
	If TypeOf(EventData) <> Type("Structure")
	   And TypeOf(EventData) <> Type("FixedStructure") Then
		Return "";
	EndIf;
	
	PropertiesToExclude = New Map;
	If IsDataPropertyExcluded Then
		PropertiesToExclude.Insert(Lower("Data"), True);
	EndIf;
	
	EndingPresentation = "";
	
	If EventData.Property("Roles") Then
		PropertyNameAtEnd = Lower("Roles");
	ElsIf EventData.Property("Message") Then
		PropertyNameAtEnd = Lower("Message");
	Else
		PropertyNameAtEnd = "";
	EndIf;
	
	If ValueIsFilled(PropertyNameAtEnd) Then
		PropertiesToExclude.Insert(PropertyNameAtEnd, True);
		
		ValuePresentation = ValuePresentation(PropertyNameAtEnd,
			EventData[PropertyNameAtEnd]);
		
		If ValueIsFilled(ValuePresentation) Then
			KeyPresentation = KeysPresentation.Get(Lower(PropertyNameAtEnd));
			IsKeyPresentationFilled = ValueIsFilled(KeyPresentation);
			If Not IsKeyPresentationFilled Then
				KeyPresentation = PropertyNameAtEnd;
			EndIf;
			
			If StrFind(ValuePresentation, Chars.LF) > 0 Then
				EndingPresentation = KeyPresentation + ":
				|" + ValuePresentation;
			Else
				EndingPresentation = KeyPresentation + ": " + ValuePresentation;
			EndIf;
		EndIf;
	EndIf;
	
	Tree = TreeWithStructureData(EventData,
		KeysPresentation, True, PropertiesToExclude);
	
	Rows = New Array;
	AddTreeRowsPresentations(Rows, Tree.Rows);
	
	If ValueIsFilled(EndingPresentation) Then
		Rows.Add(EndingPresentation);
	EndIf;
	
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

// Intended for function "StructureDataPresentation".
Procedure AddTreeRowsPresentations(Rows, TreeRows, Indent = "")
	
	For Each TreeRow In TreeRows Do
		If TreeRow.ThereIsValue Then
			Rows.Add(Indent + TreeRow.Property + ": " + TreeRow.Value);
		Else
			Rows.Add(Indent + TreeRow.Property);
			AddTreeRowsPresentations(Rows, TreeRow.Rows, Indent + "    ");
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//  EventData - Structure, FixedStructure
//  KeysPresentation - See StructuresKeysPresentation
//                      - Undefined - get it automatically
//  OnlyFilledValues - Boolean
//  PropertiesToExclude - Map
//                      - Undefined
//
// Returns:
//  ValueTree:
//   * Property - String
//   * Value - String
//   * ThereIsValue - Boolean
//
Function TreeWithStructureData(EventData, KeysPresentation = Undefined,
			OnlyFilledValues = False, PropertiesToExclude = Undefined) Export
	
	If KeysPresentation = Undefined Then
		KeysPresentation = StructuresKeysPresentation();
	EndIf;
	
	Tree = New ValueTree;
	Tree.Columns.Add("Property", New TypeDescription("String"), NStr("vi = 'Thuộc tính';
																	|ru = 'Свойство';
																	|en = 'Property'; fa = 'خاصیت';
																	|it = 'Свойство';
																	|pl = 'Property';
																	|tr = 'Özellik'"));
	Tree.Columns.Add("Value", New TypeDescription("String"), NStr("vi = 'Giá trị';
																	|ru = 'Значение';
																	|en = 'Value'; fa = 'مقدار';
																	|it = 'Значение';
																	|pl = 'Value';
																	|tr = 'Değer'"));
	Tree.Columns.Add("IsPropertyWithoutPresentation", New TypeDescription("Boolean"));
	Tree.Columns.Add("ThereIsValue", New TypeDescription("Boolean"));
	
	AddPropertiesToTree(Tree.Rows, EventData, KeysPresentation,
		OnlyFilledValues, PropertiesToExclude);
	
	Tree.Columns.Delete("IsPropertyWithoutPresentation");
	
	Return Tree;
	
EndFunction

Procedure AddPropertiesToTree(TreeRows, PropertiesDetails, KeysPresentation,
			OnlyFilledValues, PropertiesToExclude, Val ParentKey = "")
	
	If ParentKey <> "" Then
		ParentKey = ParentKey + ".";
	EndIf;
	
	For Each KeyAndValue In PropertiesDetails Do
		FullKey = ParentKey + KeyAndValue.Key;
		Value = KeyAndValue.Value;
		
		If PropertiesToExclude <> Undefined
		   And PropertiesToExclude.Get(Lower(FullKey)) <> Undefined
		 Or OnlyFilledValues
		   And Not ValueIsFilled(Value)
		   And TypeOf(Value) <> Type("Boolean")
		   And TypeOf(Value) <> Type("Number")
		   And TypeOf(Value) <> Type("Date") Then
			Continue;
		EndIf;
		
		NewRow = TreeRows.Add();
		
		If TypeOf(PropertiesDetails) = Type("Map")
		 Or TypeOf(PropertiesDetails) = Type("FixedMap") Then
			
			NewRow.Property = ValuePresentation("", KeyAndValue.Key);
		Else
			NewRow.Property = KeysPresentation.Get(Lower(KeyAndValue.Key));
			If Not ValueIsFilled(NewRow.Property) Then
				NewRow.Property = KeyAndValue.Key;
				NewRow.IsPropertyWithoutPresentation = True;
			EndIf;
		EndIf;
		
		If TypeOf(Value) = Type("Structure")
		 Or TypeOf(Value) = Type("FixedStructure")
		 Or TypeOf(Value) = Type("Map")
		 Or TypeOf(Value) = Type("FixedMap") Then
			
			AddPropertiesToTree(NewRow.Rows, Value, KeysPresentation,
				OnlyFilledValues, PropertiesToExclude, FullKey);
			
		ElsIf (    TypeOf(Value) = Type("Array")
		           Or TypeOf(Value) = Type("FixedArray"))
		        And Value.Count() > 0
		        And (    TypeOf(Value[0]) = Type("Structure")
		           Or TypeOf(Value[0]) = Type("FixedStructure")
		           Or TypeOf(Value[0]) = Type("Map")
		           Or TypeOf(Value[0]) = Type("FixedMap")) Then
			
			CountOfCharacters = StrLen(XMLString(Value.Count()));
			Number = 1;
			For Each ArrayElement In Value Do
				NewSubstring = NewRow.Rows.Add();
				NewSubstring.Property = Right("         " + XMLString(Number), CountOfCharacters);
				AddPropertiesToTree(NewSubstring.Rows, ArrayElement, KeysPresentation,
					OnlyFilledValues, PropertiesToExclude, FullKey);
				Number = Number + 1;
			EndDo;
		Else
			ValuePresentation = ValuePresentation(FullKey, Value);
			NewRow.Value = ValuePresentation;
			NewRow.ThereIsValue = True;
		EndIf;
		
		If Not OnlyFilledValues Then
			Continue;
		EndIf;
		
		If NewRow.ThereIsValue
		   And Not ValueIsFilled(ValuePresentation)
		 Or Not NewRow.ThereIsValue
		   And Not ValueIsFilled(NewRow.Rows) Then
			
			TreeRows.Delete(NewRow);
		EndIf;
	EndDo;
	
	TreeRows.Sort("IsPropertyWithoutPresentation, Property");
	
EndProcedure

// Parameters:
//   Var_Key - String - Property name
//   Value - Arbitrary
//
// Returns:
//  String
//
Function ValuePresentation(Var_Key, Value)
	
	FormatString = NStr("vi = 'NZ=0; DLF=DT; DE=''01.01.0001 00:00:00''';
						|ru = 'ЧН=0; ДЛФ=DT; ДП=''01.01.0001 00:00:00''';
						|en = 'NZ=0; DLF=DT; DE=''01.01.0001 00:00:00'''; fa = 'NZ=0; DLF=DT; DE=''01.01.0001 00:00:00''';
						|it = 'ЧН=0; ДЛФ=DT; ДП=''01.01.0001 00:00:00''';
						|pl = 'NZ=0; DLF=DT; DE=''01.01.0001 00:00:00''';
						|tr = 'NZ=0; DLF=DT; DE=''01.01.0001 00:00:00'''");
	
	If TypeOf(Value) <> Type("Array") Then
		If Upper(Var_Key) = Upper("EventName") And StrStartsWith(Value, "_$") Then
			EventPresentation = EventLogEventPresentation(Value);
			If ValueIsFilled(EventPresentation) Then
				Return EventPresentation;
			EndIf;
		EndIf;
		Return CommonClientServer.ReplaceProhibitedXMLChars(
			Format(Value, FormatString));
	EndIf;
	
	If Upper(Var_Key) = Upper("Roles") Then
		Table = RoleTable(Value);
		Rows = Table.UnloadColumn("Presentation");
		Connector = Chars.LF;
	Else
		Rows = New Array;
		For Each CurrentValue In Value Do
			Rows.Add(CommonClientServer.ReplaceProhibitedXMLChars(
				Format(CurrentValue, FormatString)));
		EndDo;
		Connector = ", ";
	EndIf;
	
	If Rows.Count() = 1 Then
		Return Rows[0];
	EndIf;
	
	Return StrConcat(Rows, Connector);
	
EndFunction

// Parameters:
//  Roles - Array of String
//
// Returns:
//  ValueTable:
//   * Presentation - String
//
Function RoleTable(Roles) Export
	
	IBUserRoles1 = New ValueTable;
	IBUserRoles1.Columns.Add("Exists");
	IBUserRoles1.Columns.Add("Presentation",, NStr("vi = 'Trình bày';
													|ru = 'Представление';
													|en = 'Presentation'; fa = 'نمایش';
													|it = 'Представление';
													|pl = 'Presentation';
													|tr = 'Sunum'"));
	
	For Each FullNameOfTheRole In Roles Do
		NameParts = StrSplit(FullNameOfTheRole, ".", False);
		If NameParts.Count() = 2 Then
			NameOfRole = NameParts[1];
			RoleMetadata = Metadata.Roles.Find(NameOfRole);
		Else
			NameOfRole = FullNameOfTheRole;
		EndIf;
		NewRow = IBUserRoles1.Add();
		NewRow.Exists = RoleMetadata <> Undefined;
		NewRow.Presentation = ?(RoleMetadata = Undefined,
			NameOfRole, RoleMetadata.Presentation());
	EndDo;
	
	IBUserRoles1.Sort("Exists DESC, Presentation");
	IBUserRoles1.Columns.Delete("Exists");
	
	Return IBUserRoles1;
	
EndFunction

// Returns:
//  Map of KeyAndValue:
//   * Key - String - Lower-case name of a structure key.
//   * Value - String - Key presentation.
//
Function StructuresKeysPresentation()
	
	Result = New Map;
	
	// _$Access$_.*
	Result.Insert(Lower("Right"),
		NStr("vi = 'Bên phải';
			|ru = 'Право';
			|en = 'Access right'; fa = 'حق دسترسی';
			|it = 'Право';
			|pl = 'Access right';
			|tr = 'Sağ'"));
	
	Result.Insert(Lower("Action"),
		NStr("vi = 'Thao tác';
			|ru = 'Действие';
			|en = 'Action'; fa = 'Action';
			|it = 'Действие';
			|pl = 'Action';
			|tr = 'Eylem'"));
	
	// _$Debug$_.*
	Result.Insert(Lower("DebuggingServerUser"),
		NStr("vi = 'Người sử dụng của server gỡ rối';
			|ru = 'Пользователь сервера отладки';
			|en = 'Debug server user'; fa = 'Debug server user';
			|it = 'Пользователь сервера отладки';
			|pl = 'Debug server user';
			|tr = 'Hata ayıklama sunucusu kullanıcısı'"));
	
	Result.Insert(Lower("DebugItemType"),
		NStr("vi = 'Kiểu chủ đề gỡ rối';
			|ru = 'Тип предмета отладки';
			|en = 'Debug item type'; fa = 'Debug item type';
			|it = 'Тип предмета отладки';
			|pl = 'Debug item type';
			|tr = 'Hata Ayıklama Öğe Türü'"));
	
	Result.Insert(Lower("Expression"),
		NStr("vi = 'Biểu thức';
			|ru = 'Выражение';
			|en = 'Expression'; fa = 'عبارت';
			|it = 'Выражение';
			|pl = 'Expression';
			|tr = 'İfade'"));
	
	// _$InfoBase$_.AdditionalAuthenticationSettingsUpdate
	Result.Insert(Lower("PasswordRecoveryMethod"),
		NStr("vi = 'Phương thức khôi phục mật khẩu';
			|ru = 'Способ восстановления пароля';
			|en = 'Password recovery method'; fa = 'Password recovery method';
			|it = 'Способ восстановления пароля';
			|pl = 'Password recovery method';
			|tr = 'Şifre kurtarma seçeneği'"));
	
	Result.Insert(Lower("PasswordRecoveryURL"),
		NStr("vi = 'Tham chiếu dẫn hướng khôi phục mật khẩu';
			|ru = 'Навигационная ссылка восстановления пароля';
			|en = 'Password recovery URL'; fa = 'URL بازیابی رمز عبور';
			|it = 'Link di navigazione di recupero password';
			|pl = 'Odnośnik nawigacyjny odzyskiwania hasła';
			|tr = 'Şifre kurtarma gezinme bağlantısı'"));
	
	Result.Insert(Lower("HelpURL"),
		NStr("vi = 'Liên kết trợ giúp điều hướng';
			|ru = 'Навигационная ссылка помощи';
			|en = 'Help URL'; fa = 'URL راهنما';
			|it = 'Link di navigazione di assistenza';
			|pl = 'Odnośnik nawigacyjny pomocy';
			|tr = 'Yardım gezinme bağlantısı'"));
	
	Result.Insert(Lower("ShowHelpHyperlink"),
		NStr("vi = 'Hiển thị siêu liên kết trợ giúp';
			|ru = 'Отображать гиперссылку помощи';
			|en = 'Show Help URL'; fa = 'Show Help URL';
			|it = 'Отображать гиперссылку помощи';
			|pl = 'Show Help URL';
			|tr = 'Yardım bağlantısını görüntüle'"));
	
	Result.Insert(Lower("VerificationCodeLength"),
		NStr("vi = 'Chiều dài mã xác nhận';
			|ru = 'Длина кода подтверждения';
			|en = 'Confirmation code length'; fa = 'Confirmation code length';
			|it = 'Длина кода подтверждения';
			|pl = 'Confirmation code length';
			|tr = 'Doğrulama kodu uzunluğu'"));
	
	Result.Insert(Lower("MaxUnsuccessfulVerificationCodeValidationAttemptsCount"),
		NStr("vi = 'Số lần tối đa thử mã xác minh không thành công';
			|ru = 'Максимальное количество неуспешных попыток проверки кода подтверждения';
			|en = 'Limit for unsuccessful code entries'; fa = 'Limit for unsuccessful code entries';
			|it = 'Максимальное количество неуспешных попыток проверки кода подтверждения';
			|pl = 'Limit for unsuccessful code entries';
			|tr = 'Maksimum başarısız doğrulama kodu denemesi sayısı'"));
	
	Result.Insert(Lower("VerificationCodeRefreshRequestLockDuration"),
		NStr("vi = 'Thời gian phong tỏa yêu cầu cập nhật mã xác nhận';
			|ru = 'Длительность блокировки запроса обновления кода подтверждения';
			|en = 'Confirmation code cooldown time'; fa = 'Confirmation code cooldown time';
			|it = 'Длительность блокировки запроса обновления кода подтверждения';
			|pl = 'Confirmation code cooldown time';
			|tr = 'Doğrulama kodu güncelleme isteği engelleme süresi'"));
	
	Result.Insert(Lower("SMTPServerAddress"),
		NStr("vi = 'Địa chỉ server SMTP';
			|ru = 'Адрес сервера SMTP';
			|en = 'SMTP server address'; fa = 'SMTP server address';
			|it = 'Адрес сервера SMTP';
			|pl = 'SMTP server address';
			|tr = 'SMTP sunucu adresi'"));
	
	Result.Insert(Lower("SMTPUser"),
		NStr("vi = 'Người sử dụng SMTP';
			|ru = 'Пользователь SMTP';
			|en = 'SMTP user'; fa = 'کاربر SMTP';
			|it = 'Utente SMTP';
			|pl = 'Użytkownik SMTP';
			|tr = 'SMTP kullanıcısı'"));
	
	Result.Insert(Lower("SMTPPasswordChanged"),
		NStr("vi = 'Đã thay đổi mật khẩu SMTP';
			|ru = 'Пароль SMTP изменен';
			|en = 'SMTP password changed'; fa = 'SMTP password changed';
			|it = 'Пароль SMTP изменен';
			|pl = 'SMTP password changed';
			|tr = 'SMTP parolası değiştirildi'"));
	
	Result.Insert(Lower("SMTPPort"),
		NStr("vi = 'Cổng SMTP';
			|ru = 'Порт SMTP';
			|en = 'SMTP port'; fa = 'SMTP port';
			|it = 'Порт SMTP';
			|pl = 'SMTP port';
			|tr = 'SMTP'"));
	
	Result.Insert(Lower("SenderName"),
		NStr("vi = 'Tên người gửi';
			|ru = 'Имя отправителя';
			|en = 'Sender''s name'; fa = 'نام فرستنده';
			|it = 'Nome del mittente';
			|pl = 'Nazwa nadawcy';
			|tr = 'Gönderen adı'"));
	
	Result.Insert(Lower("Title"),
		NStr("vi = 'Tiêu đề';
			|ru = 'Заголовок';
			|en = 'Header'; fa = 'سرصفحه';
			|it = 'Заголовок';
			|pl = 'Header';
			|tr = 'Başlık'"));
	
	Result.Insert(Lower("HTMLMessageText"),
		NStr("vi = 'Nội dung thông báo HTML';
			|ru = 'Текст сообщения HTML';
			|en = 'HTML message body'; fa = 'HTML message body';
			|it = 'Текст сообщения HTML';
			|pl = 'HTML message body';
			|tr = 'HTML metni'"));
	
	Result.Insert(Lower("UseSSL"),
		NStr("vi = 'Sử dụng SSL';
			|ru = 'Использовать SSL';
			|en = 'SSL user'; fa = 'SSL user';
			|it = 'Использовать SSL';
			|pl = 'SSL user';
			|tr = 'SSL kullan'"));
	
	Result.Insert(Lower("AllowSaveCredentialsForReAuthentication"),
		NStr("vi = 'Cho phép lưu đăng nhập để đăng nhập lại';
			|ru = 'Разрешить сохранение аутентификации для повторной аутентификации';
			|en = 'Allow save credentials for auto-login'; fa = 'Allow save credentials for auto-login';
			|it = 'Разрешить сохранение аутентификации для повторной аутентификации';
			|pl = 'Allow save credentials for auto-login';
			|tr = 'Yeniden kimlik doğrulama için kimlik doğrulamanın kaydedilmesine izin ver'"));
	
	Result.Insert(Lower("SaveCredentialsForReAuthenticationByDefault"),
		NStr("vi = 'Lưu đăng nhập để đăng nhập lại theo mặc định';
			|ru = 'Сохранять аутентификацию для повторной аутентификации по умолчанию';
			|en = 'Save credentials for auto-login by default'; fa = 'Save credentials for auto-login by default';
			|it = 'Сохранять аутентификацию для повторной аутентификации по умолчанию';
			|pl = 'Save credentials for auto-login by default';
			|tr = 'Varsayılan olarak yeniden kimlik doğrulama için kimlik doğrulamayı kaydet'"));
	
	Result.Insert(Lower("SavedAuthenticationLifeTime"),
		NStr("vi = 'Thời gian tồn tại của đăng nhập đã lưu';
			|ru = 'Время жизни сохраненной аутентификации';
			|en = 'Credentials lifetime'; fa = 'Credentials lifetime';
			|it = 'Время жизни сохраненной аутентификации';
			|pl = 'Credentials lifetime';
			|tr = 'Kayıtlı kimlik doğrulamanın süresi'"));
	
	// _$InfoBase$_.AdministrationParametersChange
	Result.Insert(Lower("LockScheduledJobs"),
		NStr("vi = 'Phong tỏa nhiệm vụ thường kỳ';
			|ru = 'Блокировка регламентных заданий';
			|en = 'Scheduled job lock'; fa = 'Scheduled job lock';
			|it = 'Блокировка регламентных заданий';
			|pl = 'Scheduled job lock';
			|tr = 'Zamanlanmış görevleri engelleme'"));
	
	Result.Insert(Lower("SessionsLockEnabled"),
		NStr("vi = 'Đã bật sử dụng phong tỏa bắt đầu phiên làm việc';
			|ru = 'Включена блокировка начала сеансов';
			|en = 'Session startup lock enabled'; fa = 'Session startup lock enabled';
			|it = 'Включена блокировка начала сеансов';
			|pl = 'Session startup lock enabled';
			|tr = 'Oturum başlatma engelleme etkin'"));
	
	Result.Insert(Lower("LockBeginTime"),
		NStr("vi = 'Thời gian bắt đầu phong tỏa';
			|ru = 'Время начала блокировки';
			|en = 'Lock start time'; fa = 'زمان شروع قفل';
			|it = 'Время начала блокировки';
			|pl = 'Lock start time';
			|tr = 'Engelleme başlama zamanı'"));
	
	Result.Insert(Lower("LockEndTime"),
		NStr("vi = 'Thời gian kết thúc phong tỏa';
			|ru = 'Время окончания блокировки';
			|en = 'Lock end time'; fa = 'زمان پایان قفل';
			|it = 'Время окончания блокировки';
			|pl = 'Lock end time';
			|tr = 'Engellemenin sonlandığı zaman'"));
	
	Result.Insert(Lower("ConfigurationUnloadDelayByWorkingProcessWithoutActiveUsers"),
		NStr("vi = 'Trì hoãn kết xuất cấu hình bởi quy trình làm việc không có người sử dụng đang làm việc';
			|ru = 'Задержка выгрузки конфигурации рабочим процессом без активных пользователей';
			|en = 'Delay for importing configuration by an idle process'; fa = 'Delay for importing configuration by an idle process';
			|it = 'Задержка выгрузки конфигурации рабочим процессом без активных пользователей';
			|pl = 'Delay for importing configuration by an idle process';
			|tr = 'Etkin kullanıcıları olmayan bir alt süreç tarafından yapılandırmanın yüklenmesinde gecikme'"));
	
	Result.Insert(Lower("DisableLocalSpeechToText"),
		NStr("vi = 'Cấm nhận dạng giọng nói cục bộ';
			|ru = 'Запретить локальное распознавание речи';
			|en = 'Restrict local speech recognition'; fa = 'Restrict local speech recognition';
			|it = 'Запретить локальное распознавание речи';
			|pl = 'Restrict local speech recognition';
			|tr = 'Yerel konuşma tanımayı devre dışı bırak'"));
	
	Result.Insert(Lower("InfoBaseID"),
		NStr("vi = 'Tên cơ sở thông tin';
			|ru = 'Идентификатор информационной базы';
			|en = 'Infobase ID'; fa = 'شناسه پایگاه اطلاعات';
			|it = 'Identificatore del database';
			|pl = 'Identyfikator bazy informacyjnej';
			|tr = 'Infobase tanımlayıcısı'"));
	
	Result.Insert(Lower("DataBaseName"),
		NStr("vi = 'Tên cơ sở dữ liệu';
			|ru = 'Имя базы данных';
			|en = 'Database name'; fa = 'نام پایگاه داده';
			|it = 'Nome del database';
			|pl = 'Nazwa bazy danych';
			|tr = 'Veritabanı adı'"));
	
	Result.Insert(Lower("SessionStartPermissionCode"),
		NStr("vi = 'Mã cho phép bắt đầu phiên làm việc';
			|ru = 'Код разрешения начала сеансов';
			|en = 'Access code for session startup'; fa = 'Access code for session startup';
			|it = 'Код разрешения начала сеансов';
			|pl = 'Access code for session startup';
			|tr = 'Oturum izin kodu'"));
	
	Result.Insert(Lower("MaxScheduledJobsStartShiftWithoutActiveUsers"),
		NStr("vi = 'Dịch chuyển khởi động tối đa nhiệm vụ thường kỳ mà không có người sử dụng đang làm việc';
			|ru = 'Максимальный сдвиг запуска регламентных заданий без активных пользователей';
			|en = 'Maximum startup offset for idle scheduled jobs'; fa = 'Maximum startup offset for idle scheduled jobs';
			|it = 'Максимальный сдвиг запуска регламентных заданий без активных пользователей';
			|pl = 'Maximum startup offset for idle scheduled jobs';
			|tr = 'Aktif kullanıcılar olmadan zamanlanmış görevlerin başlatılmasında maksimum değişim'"));
	
	Result.Insert(Lower("MinScheduledJobsStartPeriodWithoutActiveUsers"),
		NStr("vi = 'Thời gian khởi động tối thiểu nhiệm vụ thường kỳ mà không có người sử dụng đang làm việc';
			|ru = 'Минимальный период запуска регламентных заданий без активных пользователей';
			|en = 'Minimal startup period for idle scheduled jobs'; fa = 'Minimal startup period for idle scheduled jobs';
			|it = 'Минимальный период запуска регламентных заданий без активных пользователей';
			|pl = 'Minimal startup period for idle scheduled jobs';
			|tr = 'Aktif kullanıcılar olmadan zamanlanmış görevlerin başlatılması için minimum süre'"));
	
	Result.Insert(Lower("ExternalSessionManagementRequired"),
		NStr("vi = 'Bắt buộc sử dụng quản lý ngoài các phiên làm việc';
			|ru = 'Обязательное использование внешнего управления сеансами';
			|en = 'Mandatory external session management'; fa = 'Mandatory external session management';
			|it = 'Обязательное использование внешнего управления сеансами';
			|pl = 'Mandatory external session management';
			|tr = 'Harici oturum yönetiminin zorunlu kullanımı'"));
	
	Result.Insert(Lower("LongDesc"),
		NStr("vi = 'Mô tả';
			|ru = 'Описание';
			|en = 'Details'; fa = 'جزئیات';
			|it = 'Описание';
			|pl = 'Details';
			|tr = 'Ayrıntılar'"));
	
	Result.Insert(Lower("LockParameter"),
		NStr("vi = 'Tham số phong tỏa';
			|ru = 'Параметр блокировки';
			|en = 'Lock parameter'; fa = 'Lock parameter';
			|it = 'Параметр блокировки';
			|pl = 'Lock parameter';
			|tr = 'Engelleme parametreleri'"));
	
	Result.Insert(Lower("DatabaseUserPassword"),
		NStr("vi = 'Mật khẩu của người sử dụng cơ sở dữ liệu';
			|ru = 'Пароль пользователя базы данных';
			|en = 'Database user password'; fa = 'Database user password';
			|it = 'Пароль пользователя базы данных';
			|pl = 'Database user password';
			|tr = 'Infobase kullanıcı şifresi'"));
	
	Result.Insert(Lower("DatabaseUser"),
		NStr("vi = 'Người sử dụng cơ sở dữ liệu';
			|ru = 'Пользователь базы данных';
			|en = 'Database user'; fa = 'کاربر پایگاه داده';
			|it = 'Utente del database';
			|pl = 'Użytkownik bazy danych';
			|tr = 'Veritabanı kullanıcısı'"));
	
	Result.Insert(Lower("SafeModeSecurityProfile"),
		NStr("vi = 'Hồ sơ bảo mật của chế độ bảo mật';
			|ru = 'Профиль безопасности безопасного режима';
			|en = 'Safe mode security profile'; fa = 'Safe mode security profile';
			|it = 'Профиль безопасности безопасного режима';
			|pl = 'Safe mode security profile';
			|tr = 'Güvenli mod güvenlik profili'"));
	
	Result.Insert(Lower("AllowLicenseDistribution"),
		NStr("vi = 'Cho phép cấp giấy phép';
			|ru = 'Разрешить выдачу лицензий';
			|en = 'Allow issuing licenses'; fa = 'Allow issuing licenses';
			|it = 'Разрешить выдачу лицензий';
			|pl = 'Allow issuing licenses';
			|tr = 'Lisansların verilmesine izin ver'"));
	
	Result.Insert(Lower("ReserveWorkingProcesses"),
		NStr("vi = 'Dự phòng các quy trình làm việc';
			|ru = 'Резервирование рабочих процессов';
			|en = 'Working process reservation'; fa = 'Working process reservation';
			|it = 'Резервирование рабочих процессов';
			|pl = 'Working process reservation';
			|tr = 'İş Akışı Rezervasyonu'"));
	
	Result.Insert(Lower("DataBaseServer"),
		NStr("vi = 'Server cơ sở dữ liệu';
			|ru = 'Сервер баз данных';
			|en = 'Database server'; fa = 'سرور پایگاه داده';
			|it = 'Сервер баз данных';
			|pl = 'Database server';
			|tr = 'Veritabanı sunucusu'"));
	
	Result.Insert(Lower("DateOffset"),
		NStr("vi = 'Chuyển dịch ngày';
			|ru = 'Смещение дат';
			|en = 'Dates offset'; fa = 'جابه‌جایی تاریخ‌ها';
			|it = 'Spostamento dei dati';
			|pl = 'Przesunięcie dat';
			|tr = 'Tarih birleşimi'"));
	
	Result.Insert(Lower("CreateDatabase"),
		NStr("vi = 'Tạo cơ sở dữ liệu';
			|ru = 'Создать базу данных';
			|en = 'Create database'; fa = 'Create database';
			|it = 'Создать базу данных';
			|pl = 'Create database';
			|tr = 'Veritabanı oluştur'"));
	
	Result.Insert(Lower("LockMessage"),
		NStr("vi = 'Thông báo phong tỏa';
			|ru = 'Сообщение блокировки';
			|en = 'Lock message'; fa = 'پیام قفل';
			|it = 'Messaggio di blocco';
			|pl = 'Wiadomość blokowania';
			|tr = 'Kilit mesajı'"));
	
	Result.Insert(Lower("ExternalSessionManagementConnectionString"),
		NStr("vi = 'Xâu ký tự tham số quản lý ngoài các phiên làm việc';
			|ru = 'Строка параметров внешнего управления сеансами';
			|en = 'String of external session management parameters'; fa = 'String of external session management parameters';
			|it = 'Строка параметров внешнего управления сеансами';
			|pl = 'String of external session management parameters';
			|tr = 'Harici oturum yönetimi parametre dizisi'"));
	
	Result.Insert(Lower("DBMS"),
		NStr("vi = 'Hệ thống quản trị CSDL';
			|ru = 'СУБД';
			|en = 'DBMS'; fa = 'DBMS';
			|it = 'СУБД';
			|pl = 'DBMS';
			|tr = 'Veritabanı Yönetim Sistemi'"));
	
	Result.Insert(Lower("ConnectionsSecurityLevel"),
		NStr("vi = 'Mức bảo mật kết nối';
			|ru = 'Уровень безопасности соединений';
			|en = 'Connection security level'; fa = 'Connection security level';
			|it = 'Уровень безопасности соединений';
			|pl = 'Connection security level';
			|tr = 'Bağlantı güvenlik düzeyi'"));
	
	// _$InfoBase$_.ConfigUpdate*
	Result.Insert(Lower("Vendor"),
		NStr("vi = 'Nhà cung cấp';
			|ru = 'Поставщик';
			|en = 'Vendor'; fa = 'تأمین‌کننده';
			|it = 'Поставщик';
			|pl = 'Vendor';
			|tr = 'Tedarikçi'"));
	
	// _$InfoBase$_.ConfigExtensionUpdate
	Result.Insert(Lower("Version"),
		NStr("vi = 'Phiên bản';
			|ru = 'Версия';
			|en = 'Version'; fa = 'نسخه';
			|it = 'Версия';
			|pl = 'Version';
			|tr = 'Sürüm'"));
	
	// _$InfoBase$_.DBConfigUpdate
	Result.Insert(Lower("ExclusiveMode"),
		NStr("vi = 'Chế độ độc quyền';
			|ru = 'Монопольный режим';
			|en = 'Exclusive mode'; fa = 'حالت انحصاری';
			|it = 'Regime Multithread';
			|pl = 'Tryb wyłączności';
			|tr = 'Tekel mod'"));
	
	// _$InfoBase$_.DBConfigExtension*
	Result.Insert(Lower("Active"),
		NStr("vi = 'Hoạt động';
			|ru = 'Активно';
			|en = 'Active'; fa = 'فعال';
			|it = 'Активно';
			|pl = 'Active';
			|tr = 'Aktif'"));
	
	Result.Insert(Lower("SafeMode"),
		NStr("vi = 'Chế độ an toàn';
			|ru = 'Безопасный режим';
			|en = 'Safe mode'; fa = 'حالت امن';
			|it = 'Modalità sicura';
			|pl = 'Tryb bezpieczny';
			|tr = 'Güvenli mod'"));
	
	Result.Insert(Lower("SecurityProfile"),
		NStr("vi = 'Hồ sơ bảo mật';
			|ru = 'Профиль безопасности';
			|en = 'Security profile'; fa = 'Security profile';
			|it = 'Профиль безопасности';
			|pl = 'Security profile';
			|tr = 'Güvenlik profilleri'"));
	
	Result.Insert(Lower("UseDefaultRolesForAllUsers"),
		NStr("vi = 'Sử dụng vai trò chính đối với tất cả người sử dụng';
			|ru = 'Использовать основные роли для всех пользователей';
			|en = 'Use main roles for all users'; fa = 'Use main roles for all users';
			|it = 'Использовать основные роли для всех пользователей';
			|pl = 'Use main roles for all users';
			|tr = 'Tüm kullanıcılar için birincil rolleri kullanın'"));
	
	Result.Insert(Lower("UsedInDistributedInfoBase"),
		NStr("vi = 'Được sử dụng trong cơ sở thông tin phân tán';
			|ru = 'Используется в распределенной информационной базе';
			|en = 'Used in a distributed infobase'; fa = 'Used in a distributed infobase';
			|it = 'Используется в распределенной информационной базе';
			|pl = 'Used in a distributed infobase';
			|tr = 'Dağıtılmış bir bilgi tabanında kullanılır'"));
	
	Result.Insert(Lower("Purpose"),
		NStr("vi = 'Ấn định';
			|ru = 'Назначение';
			|en = 'Used on'; fa = 'Used on';
			|it = 'Назначение';
			|pl = 'Used on';
			|tr = 'Atama'"));
	
	Result.Insert(Lower("Scope"),
		NStr("vi = 'Vùng thao tác';
			|ru = 'Область действия';
			|en = 'Scope'; fa = 'محدوده';
			|it = 'Campo di applicazione';
			|pl = 'Obszar działania';
			|tr = 'İşlem alanı'"));
	
	Result.Insert(Lower("DefaultRoles"),
		NStr("vi = 'Vai trò chính';
			|ru = 'Основные роли';
			|en = 'Default roles'; fa = 'Default roles';
			|it = 'Основные роли';
			|pl = 'Default roles';
			|tr = 'Ana roller'"));
	
	Result.Insert(Lower("Synonym"),
		NStr("vi = 'Đồng nghĩa';
			|ru = 'Синоним';
			|en = 'Synonym'; fa = 'مترادف';
			|it = 'Синоним';
			|pl = 'Synonym';
			|tr = 'Eş anlamlı'"));
	
	Result.Insert(Lower("UUID"),
		NStr("vi = 'Tên định danh duy nhất';
			|ru = 'Уникальный идентификатор';
			|en = 'UUID'; fa = 'UUID';
			|it = 'Identificatore univoco';
			|pl = 'Unikalny identyfikator';
			|tr = 'Benzersiz kimlik'"));
	
	Result.Insert(Lower("HashSum"),
		NStr("vi = 'Hash số tiền';
			|ru = 'Хеш-сумма';
			|en = 'Hash'; fa = 'هش';
			|it = 'Хеш-сумма';
			|pl = 'Hash';
			|tr = 'Karma toplamı'"));
	
	// _$InfoBase$_.EventLogReduce
	Result.Insert(Lower("Date"),
		NStr("vi = 'Ngày';
			|ru = 'Дата';
			|en = 'Date'; fa = 'تاریخ';
			|it = 'Дата';
			|pl = 'Date';
			|tr = 'Tarih'"));
	
	// _$InfoBase$_.EventLogSettingsUpdateError
	Result.Insert(Lower("Levels"),
		NStr("vi = 'Cấp độ';
			|ru = 'Уровни';
			|en = 'Levels'; fa = 'Levels';
			|it = 'Уровни';
			|pl = 'Levels';
			|tr = 'Seviyeler'"));
	
	Result.Insert(Lower("SeparationPeriod"),
		NStr("vi = 'Kỳ phân bổ';
			|ru = 'Период разделения';
			|en = 'Separation period'; fa = 'Separation period';
			|it = 'Период разделения';
			|pl = 'Separation period';
			|tr = 'Ayırma süresi'"));
	
	Result.Insert(Lower("EventLogFormat"),
		NStr("vi = 'Định dạng nhật ký sự kiện';
			|ru = 'Формат журнала регистрации';
			|en = 'Event log format'; fa = 'Event log format';
			|it = 'Формат журнала регистрации';
			|pl = 'Event log format';
			|tr = 'Kayıt defteri formatı'"));
	
	Result.Insert(Lower("EventName"),
		NStr("vi = 'Tên sự kiện';
			|ru = 'Имя события';
			|en = 'Event name'; fa = 'نام رویداد';
			|it = 'Denominazione dell''evento';
			|pl = 'Nazwa wydarzenia';
			|tr = 'Olay adı'"));
	
	Result.Insert(Lower("RegistrableEvent"),
		NStr("vi = 'Sự kiện được ghi nhận';
			|ru = 'Событие регистрируется';
			|en = 'Event loggable'; fa = 'Event loggable';
			|it = 'Событие регистрируется';
			|pl = 'Event loggable';
			|tr = 'Etkinlik kaydedilir'"));
	
	// _$InfoBase$_.ExclusiveModeChange
	Result.Insert(Lower("AllowTerminationAtSessionStart"),
		NStr("vi = 'Cho phép kết thúc khi bắt đầu phiên làm việc';
			|ru = 'Разрешить завершать при начале сеанса';
			|en = 'Allow exit on startup'; fa = 'Allow exit on startup';
			|it = 'Разрешить завершать при начале сеанса';
			|pl = 'Allow exit on startup';
			|tr = 'Oturum başında sonlandıemaya izin ver'"));
	
	// _$InfoBase$_.ParametersUpdate
	Result.Insert(Lower("DataLockTimeout"),
		NStr("vi = 'Thời gian chờ phong tỏa dữ liệu';
			|ru = 'Время ожидания блокировки данных';
			|en = 'Data lock wait time'; fa = 'Data lock wait time';
			|it = 'Время ожидания блокировки данных';
			|pl = 'Data lock wait time';
			|tr = 'Veri kilitleme zaman aşımı'"));
	
	Result.Insert(Lower("UserPasswordsMaxLifetime"),
		NStr("vi = 'Thời hạn hiệu lực tối đa của mật khẩu người sử dụng';
			|ru = 'Максимальный срок действия паролей пользователей';
			|en = 'Maximum user password lifetime'; fa = 'Maximum user password lifetime';
			|it = 'Максимальный срок действия паролей пользователей';
			|pl = 'Maximum user password lifetime';
			|tr = 'Kullanıcı parolalırın maksimum geçerlilik süresi'"));
	
	Result.Insert(Lower("UserPasswordsMinLifetime"),
		NStr("vi = 'Thời hạn hiệu lực tối thiểu của mật khẩu người sử dụng';
			|ru = 'Минимальный срок действия паролей пользователей';
			|en = 'Minimum user password lifetime'; fa = 'Minimum user password lifetime';
			|it = 'Минимальный срок действия паролей пользователей';
			|pl = 'Minimum user password lifetime';
			|tr = 'Kullanıcı parolalırın minimum geçerlilik süresi'"));
	
	Result.Insert(Lower("UserPasswordsMinLength"),
		NStr("vi = 'Chiều dài tối thiểu của mật khẩu người sử dụng';
			|ru = 'Минимальная длина паролей пользователей';
			|en = 'Minimum user password length'; fa = 'Minimum user password length';
			|it = 'Минимальная длина паролей пользователей';
			|pl = 'Minimum user password length';
			|tr = 'Kullanıcı şifrelerinin minimum uzunluğu'"));
	
	Result.Insert(Lower("UserPasswordReuseLimit"),
		NStr("vi = 'Hạn chế việc lặp lại mật khẩu người dùng trong số các mật khẩu gần đây';
			|ru = 'Ограничение повторения паролей пользователей среди последних';
			|en = 'Prevent re-use of recent user passwords'; fa = 'Prevent re-use of recent user passwords';
			|it = 'Ограничение повторения паролей пользователей среди последних';
			|pl = 'Prevent re-use of recent user passwords';
			|tr = 'Son kullanıcılar arasında kullanıcı şifrelerinin tekrarının sınırlandırılması'"));
	
	Result.Insert(Lower("UserPasswordComplexityCheck"),
		NStr("vi = 'Kiểm tra mức độ phức tạp của mật khẩu người sử dụng';
			|ru = 'Проверка сложности паролей пользователей';
			|en = 'User password complexity check'; fa = 'User password complexity check';
			|it = 'Проверка сложности паролей пользователей';
			|pl = 'User password complexity check';
			|tr = 'Kullanıcı şifrelerinin karmaşıklığını kontrol etme'"));
	
	Result.Insert(Lower("UserPasswordExpirationNotificationPeriod"),
		NStr("vi = 'Thời gian cảnh báo hết hạn mật khẩu người dùng';
			|ru = 'Срок предупреждения об истечении срока действия паролей пользователей';
			|en = 'User password expiration notification lead'; fa = 'User password expiration notification lead';
			|it = 'Срок предупреждения об истечении срока действия паролей пользователей';
			|pl = 'User password expiration notification lead';
			|tr = 'Kullanıcı şifresinin süresinin dolması için uyarı süresi'"));
	
	Result.Insert(Lower("PassiveSessionHibernateTime"),
		NStr("vi = 'Thời gian ngủ của phiên thụ động';
			|ru = 'Время засыпания пассивного сеанса';
			|en = 'Idle session sleep timeout'; fa = 'Idle session sleep timeout';
			|it = 'Время засыпания пассивного сеанса';
			|pl = 'Idle session sleep timeout';
			|tr = 'Pasif seans uyku moduna geçme süresi'"));
	
	Result.Insert(Lower("HibernateSessionTerminateTime"),
		NStr("vi = 'Thời gian kết thúc của phiên đang ngủ';
			|ru = 'Время завершения спящего сеанса';
			|en = 'Sleeping session termination timeout'; fa = 'Sleeping session termination timeout';
			|it = 'Время завершения спящего сеанса';
			|pl = 'Sleeping session termination timeout';
			|tr = 'Uyku modu bitiş zamanı'"));
	
	Result.Insert(Lower("InactiveSessionTerminationTime"),
		NStr("vi = 'Thời gian kết thúc phiên khi không hoạt động';
			|ru = 'Время завершения сеанса при бездействии';
			|en = 'Inactive session termination timeout'; fa = 'Inactive session termination timeout';
			|it = 'Время завершения сеанса при бездействии';
			|pl = 'Inactive session termination timeout';
			|tr = 'Etkin olmadığında oturum bitiş zamanı'"));
	
	Result.Insert(Lower("NotificationLeadTimeBeforeInactiveSessionTermination"),
		NStr("vi = 'Thời gian cảnh báo về kết thúc phiên khi không hoạt động';
			|ru = 'Время предупреждения о завершении сеанса при бездействии';
			|en = 'Lead time for inactive session termination notification'; fa = 'Lead time for inactive session termination notification';
			|it = 'Время предупреждения о завершении сеанса при бездействии';
			|pl = 'Lead time for inactive session termination notification';
			|tr = 'Etkin olmaması nedeniyle oturumun sona ermesi için uyarı zamanı'"));
	
	Result.Insert(Lower("TotalRecalcJobCount"),
		NStr("vi = 'Số lượng nhiệm vụ tính lại phần tổng kết';
			|ru = 'Количество заданий пересчета итогов';
			|en = 'Number of totals recalculation tasks'; fa = 'Number of totals recalculation tasks';
			|it = 'Количество заданий пересчета итогов';
			|pl = 'Number of totals recalculation tasks';
			|tr = 'Toplam yeniden hesaplama görevlerinin sayısı'"));
	
	Result.Insert(Lower("MaxUnsuccessfulAttemptsCount"),
		NStr("vi = 'Số lượng tối đa lần thử không thành công';
			|ru = 'Максимальное количество неуспешных попыток';
			|en = 'Limit of unsuccessful attempts'; fa = 'Limit of unsuccessful attempts';
			|it = 'Максимальное количество неуспешных попыток';
			|pl = 'Limit of unsuccessful attempts';
			|tr = 'Maksimum başarısız deneme sayısı'"));
	
	Result.Insert(Lower("LockDuration"),
		NStr("vi = 'Thời gian phong tỏa';
			|ru = 'Длительность блокировки';
			|en = 'Lock duration'; fa = 'Lock duration';
			|it = 'Длительность блокировки';
			|pl = 'Lock duration';
			|tr = 'Engelleme süresi'"));
	
	Result.Insert(Lower("UserNameAdditionCodes"),
		NStr("vi = 'Mã bổ sung tên người sử dụng';
			|ru = 'Коды дополнения имени пользователя';
			|en = 'Username addition codes'; fa = 'Username addition codes';
			|it = 'Коды дополнения имени пользователя';
			|pl = 'Username addition codes';
			|tr = 'Kullanıcı adı tamamlama kodları'"));
	
	// _$InfoBase$_.RegionalSettingsChange
	Result.Insert(Lower("UseCurrentSessionSettings"),
		NStr("vi = 'Sử dụng tùy chỉnh phiên hiện tại';
			|ru = 'Использовать настройки текущего сеанса';
			|en = 'Use current session settings'; fa = 'Use current session settings';
			|it = 'Использовать настройки текущего сеанса';
			|pl = 'Use current session settings';
			|tr = 'Geçerli oturum ayarlarını kullan'"));
	
	Result.Insert(Lower("LocaleCode"),
		NStr("vi = 'Mã bản địa hóa';
			|ru = 'Код локализации';
			|en = 'Localization code'; fa = 'کد محلی‌سازی';
			|it = 'Codice di localizzazione';
			|pl = 'Kod lokalizacji';
			|tr = 'Yerelleştirme kodu'"));
	
	Result.Insert(Lower("FirstDayOfWeek"),
		NStr("vi = 'Ngày đầu tiên trong tuần';
			|ru = 'Первый день недели';
			|en = 'First day of the week'; fa = 'First day of the week';
			|it = 'Первый день недели';
			|pl = 'First day of the week';
			|tr = 'Haftanın ilk günü'"));
	
	Result.Insert(Lower("BooleanTruePresentation"),
		NStr("vi = 'Trình bày giá trị lô-gic True';
			|ru = 'Представление логического значения Истина';
			|en = 'Logical ""True"" presentation'; fa = 'Logical ""True"" presentation';
			|it = 'Представление логического значения Истина';
			|pl = 'Logical ""True"" presentation';
			|tr = 'Boolean Değer Gösterimi TRUE'"));
	
	Result.Insert(Lower("BooleanFalsePresentation"),
		NStr("vi = 'Trình bày giá trị lô-gic False';
			|ru = 'Представление логического значения Ложь';
			|en = 'Logical ""False"" presentation'; fa = 'Logical ""False"" presentation';
			|it = 'Представление логического значения Ложь';
			|pl = 'Logical ""False"" presentation';
			|tr = 'Boolean Değer Gösterimi FALSE'"));
	
	Result.Insert(Lower("NegativeNumberPresentation"),
		NStr("vi = 'Trình bày số âm';
			|ru = 'Представление отрицательных чисел';
			|en = 'Negative numbers presentation'; fa = 'Negative numbers presentation';
			|it = 'Представление отрицательных чисел';
			|pl = 'Negative numbers presentation';
			|tr = 'Negatif sayıların gösterimi'"));
	
	Result.Insert(Lower("NumbersDigitGroupSeparator"),
		NStr("vi = 'Đường chia tách nhóm chữ số của con số';
			|ru = 'Разделитель групп цифр чисел';
			|en = 'Digit grouping separator'; fa = 'Digit grouping separator';
			|it = 'Разделитель групп цифр чисел';
			|pl = 'Digit grouping separator';
			|tr = 'Sayıların rakam grubu ayırıcısı'"));
	
	Result.Insert(Lower("NumbersDecimalSeparator"),
		NStr("vi = 'Đường chia tách phần thập phân của con số';
			|ru = 'Разделитель дробной части чисел';
			|en = 'Decimal separator'; fa = 'Decimal separator';
			|it = 'Разделитель дробной части чисел';
			|pl = 'Decimal separator';
			|tr = 'Sayıların kesir ayırıcısı'"));
	
	Result.Insert(Lower("NumbersDigitGroupFormat"),
		NStr("vi = 'Định dạng gom nhóm chữ số của con số';
			|ru = 'Формат группировки цифр чисел';
			|en = 'Digit grouping format'; fa = 'Digit grouping format';
			|it = 'Формат группировки цифр чисел';
			|pl = 'Digit grouping format';
			|tr = 'Sayıların rakam gruplama biçimi'"));
	
	Result.Insert(Lower("TimePresentationFormat"),
		NStr("vi = 'Định dạng trình bày thời gian';
			|ru = 'Формат представления времени';
			|en = 'Time format'; fa = 'Time format';
			|it = 'Формат представления времени';
			|pl = 'Time format';
			|tr = 'Zaman gösterim biçimi'"));
	
	Result.Insert(Lower("DatePresentationFormat"),
		NStr("vi = 'Định dạng trình bày ngày';
			|ru = 'Формат представления даты';
			|en = 'Date format'; fa = 'Date format';
			|it = 'Формат представления даты';
			|pl = 'Date format';
			|tr = 'Tarih gösterim biçimi'"));
	
	// _$InfoBase$_.RoleUpdate
	Result.Insert(Lower("Rights"),
		NStr("vi = 'Quyền';
			|ru = 'Права';
			|en = 'Access rights'; fa = 'حقوق دسترسی';
			|it = 'Права';
			|pl = 'Access rights';
			|tr = 'Yetkiler'"));
	
	Result.Insert(Lower("AccessEnabled"),
		NStr("vi = 'Đã bật sử dụng truy cập';
			|ru = 'Доступ включен';
			|en = 'Access granted'; fa = 'Access granted';
			|it = 'Доступ включен';
			|pl = 'Access granted';
			|tr = 'Erişim etkinleştirildi'"));
	
	Result.Insert(Lower("AccessDisabled"),
		NStr("vi = 'Đã tắt sử dụng truy cập';
			|ru = 'Доступ выключен';
			|en = 'Access denied'; fa = 'دسترسی رد شد';
			|it = 'Доступ выключен';
			|pl = 'Access denied';
			|tr = 'Erişim devre dışı'"));
	
	Result.Insert(Lower("Restrictions"),
		NStr("vi = 'Hạn chế';
			|ru = 'Ограничения';
			|en = 'Restrictions'; fa = 'محدودیت‌ها';
			|it = 'Ограничения';
			|pl = 'Restrictions';
			|tr = 'Kısıtlamalar'"));
	
	Result.Insert(Lower("RestrictionTemplates"),
		NStr("vi = 'Khuôn mẫu hạn chế';
			|ru = 'Шаблоны ограничений';
			|en = 'Restriction templates'; fa = 'Restriction templates';
			|it = 'Шаблоны ограничений';
			|pl = 'Restriction templates';
			|tr = 'Sınırlandırma şablonu'"));
	
	Result.Insert(Lower("ItemsAdded"),
		NStr("vi = 'Đã thêm';
			|ru = 'Добавлены';
			|en = 'Added'; fa = 'اضافه‌شده';
			|it = 'Добавлены';
			|pl = 'Added';
			|tr = 'Eklendi'"));
	
	Result.Insert(Lower("ItemsChanged"),
		NStr("vi = 'Thay đổi';
			|ru = 'Изменены';
			|en = 'Modified'; fa = 'تغییریافته';
			|it = 'Изменены';
			|pl = 'Modified';
			|tr = 'Değiştirildi'"));
	
	Result.Insert(Lower("ItemsDeleted"),
		NStr("vi = 'Đã xóa';
			|ru = 'Удалены';
			|en = 'Deleted'; fa = 'حذف‌شده';
			|it = 'Удалены';
			|pl = 'Deleted';
			|tr = 'Silindi'"));
	
	Result.Insert(Lower("Description"),
		NStr("vi = 'Tên gọi';
			|ru = 'Наименование';
			|en = 'Description'; fa = 'شرح';
			|it = 'Наименование';
			|pl = 'Description';
			|tr = 'Tanım'"));
	
	Result.Insert(Lower("TemplateText"),
		NStr("vi = 'Nội dung khuôn mẫu';
			|ru = 'Текст шаблона';
			|en = 'Template text'; fa = 'Template text';
			|it = 'Текст шаблона';
			|pl = 'Template text';
			|tr = 'Şablon metni'"));
	
	// _$InfoBase$_.SecurityProfileChange
	Result.Insert(Lower("ClusterAdmin"),
		NStr("vi = 'Người quản trị cluster';
			|ru = 'Администратор кластера';
			|en = 'Cluster administrator'; fa = 'Cluster administrator';
			|it = 'Администратор кластера';
			|pl = 'Cluster administrator';
			|tr = 'Küme yöneticisi'"));
	
	Result.Insert(Lower("CryptoAvailable"),
		NStr("vi = 'Truy cập đến mã hóa';
			|ru = 'Доступ к криптографии';
			|en = 'Access to cryptography'; fa = 'Access to cryptography';
			|it = 'Доступ к криптографии';
			|pl = 'Access to cryptography';
			|tr = 'Kriptografiye erişim'"));
	
	Result.Insert(Lower("ModulesAvailableForExtension"),
		NStr("vi = 'Mô-đun được phép đối với phần mở rộng';
			|ru = 'Доступные для расширения модули';
			|en = 'Extensible modules'; fa = 'Extensible modules';
			|it = 'Доступные для расширения модули';
			|pl = 'Extensible modules';
			|tr = 'Genişletilebilir modüller'"));
	
	Result.Insert(Lower("ModulesNotAvailableForExtension"),
		NStr("vi = 'Mô-đun không được phép đối với phần mở rộng';
			|ru = 'Недоступные для расширения модули';
			|en = 'Non-extensible modules'; fa = 'Non-extensible modules';
			|it = 'Недоступные для расширения модули';
			|pl = 'Non-extensible modules';
			|tr = 'Genişletilemeyen modüller'"));
	
	Result.Insert(Lower("COMObjectFullAccess"),
		NStr("vi = 'Truy cập đầy đủ đến đối tượng COM';
			|ru = 'Полный доступ к COM-объектам';
			|en = 'Full access to COM objects'; fa = 'Full access to COM objects';
			|it = 'Полный доступ к COM-объектам';
			|pl = 'Full access to COM objects';
			|tr = 'COM nesnelerine tam erişim'"));
	
	Result.Insert(Lower("AddInFullAccess"),
		NStr("vi = 'Truy cập đầy đủ đến cấu phần ngoài';
			|ru = 'Полный доступ к внешним компонентам';
			|en = 'Full access to add-ins'; fa = 'Full access to add-ins';
			|it = 'Полный доступ к внешним компонентам';
			|pl = 'Full access to add-ins';
			|tr = 'Harici bileşenlere tam erişim'"));
	
	Result.Insert(Lower("ExternalModuleFullAccess"),
		NStr("vi = 'Truy cập đầy đủ đến mô-đun ngoài';
			|ru = 'Полный доступ к внешним модулям';
			|en = 'Full access to external modules'; fa = 'Full access to external modules';
			|it = 'Полный доступ к внешним модулям';
			|pl = 'Full access to external modules';
			|tr = 'Harici bileşenlere tam erişim'"));
	
	Result.Insert(Lower("ExternalApplicationsFullAccess"),
		NStr("vi = 'Truy cập đầy đủ đến ứng dụng ngoài';
			|ru = 'Полный доступ к внешним приложениям';
			|en = 'Unlimited access to external apps'; fa = 'Unlimited access to external apps';
			|it = 'Полный доступ к внешним приложениям';
			|pl = 'Unlimited access to external apps';
			|tr = 'Harici uygulamalara tam erişim'"));
	
	Result.Insert(Lower("InternetResourcesFullAccess"),
		NStr("vi = 'Truy cập đầy đủ đến nguồn internet';
			|ru = 'Полный доступ к интернет ресурсам';
			|en = 'Full access to online resources'; fa = 'Full access to online resources';
			|it = 'Полный доступ к интернет ресурсам';
			|pl = 'Full access to online resources';
			|tr = 'Harici uygulamalara tam erişim'"));
	
	Result.Insert(Lower("FileSystemFullAccess"),
		NStr("vi = 'Truy cập đầy đủ đến hệ thống file-server';
			|ru = 'Полный доступ к файловой системе';
			|en = 'Full access to file system'; fa = 'Full access to file system';
			|it = 'Полный доступ к файловой системе';
			|pl = 'Full access to file system';
			|tr = 'Tam dosya sistemine erişim'"));
	
	Result.Insert(Lower("FullPrivilegedMode"),
		NStr("vi = 'Có một chế độ đặc quyền đầy đủ';
			|ru = 'Полный привилегированный режим';
			|en = 'Unlimited privileged mode'; fa = 'Unlimited privileged mode';
			|it = 'Полный привилегированный режим';
			|pl = 'Unlimited privileged mode';
			|tr = 'Tam ayrıcalıklı mod'"));
	
	Result.Insert(Lower("SafeModeProfile"),
		NStr("vi = 'Hồ sơ của chế độ bảo mật';
			|ru = 'Профиль безопасного режима';
			|en = 'Security mode profile'; fa = 'Security mode profile';
			|it = 'Профиль безопасного режима';
			|pl = 'Security mode profile';
			|tr = 'Güvenli mod güvenlik profili'"));
	
	Result.Insert(Lower("AllowExternalCodeExecutionInUnsafeMode"),
		NStr("vi = 'Cho phép thực hiện mã ngoài trong chế độ không an toàn';
			|ru = 'Разрешить выполнение внешнего кода в небезопасном режиме';
			|en = 'Allow executing external code in unsafe mode'; fa = 'Allow executing external code in unsafe mode';
			|it = 'Разрешить выполнение внешнего кода в небезопасном режиме';
			|pl = 'Allow executing external code in unsafe mode';
			|tr = 'Harici kodun güvenli olmayan modda çalışmasına izin ver'"));
	
	Result.Insert(Lower("AllowAccessRightsExtension"),
		NStr("vi = 'Cho phép mở rộng quyền';
			|ru = 'Разрешить расширение прав доступа';
			|en = 'Allow extension of access rights'; fa = 'Allow extension of access rights';
			|it = 'Разрешить расширение прав доступа';
			|pl = 'Allow extension of access rights';
			|tr = 'İzinlerin genişletilmesine izin ver'"));
	
	Result.Insert(Lower("AccessRightsExtensionLimitingRoles"),
		NStr("vi = 'Vai trò hạn chế mở rộng quyền truy cập';
			|ru = 'Роли ограничивающие расширение прав доступа';
			|en = 'Roles preventing extension of access rights'; fa = 'Roles preventing extension of access rights';
			|it = 'Роли ограничивающие расширение прав доступа';
			|pl = 'Roles preventing extension of access rights';
			|tr = 'Erişim haklarının genişletilmesini sınırlayan roller'"));
	
	Result.Insert(Lower("PrivilegedModeRoles"),
		NStr("vi = 'Vai trò chế độ đặc quyền';
			|ru = 'Роли привилегированного режима';
			|en = 'Privileged mode roles'; fa = 'Privileged mode roles';
			|it = 'Роли привилегированного режима';
			|pl = 'Privileged mode roles';
			|tr = 'Ayrıcalıklı Mod Rolleri'"));
	
	Result.Insert(Lower("AllowedCOMClasses"),
		NStr("vi = 'Lớp COM được phép';
			|ru = 'Разрешенные COM-классы';
			|en = 'Allowed COM classes.'; fa = 'Allowed COM classes.';
			|it = 'Разрешенные COM-классы';
			|pl = 'Allowed COM classes.';
			|tr = 'İzin verilen COM sınıfları'"));
	
	Result.Insert(Lower("AllowedVirtualDirs"),
		NStr("vi = 'Thư mục ảo được phép';
			|ru = 'Разрешенные виртуальные каталоги';
			|en = 'Allowed virtual directories'; fa = 'Allowed virtual directories';
			|it = 'Разрешенные виртуальные каталоги';
			|pl = 'Allowed virtual directories';
			|tr = 'İzin verilen sanal dizinler'"));
	
	Result.Insert(Lower("WritingAllowed"),
		NStr("vi = 'Đã cho phép ghi';
			|ru = 'Запись разрешена';
			|en = 'Writing is allowed'; fa = 'Writing is allowed';
			|it = 'Запись разрешена';
			|pl = 'Writing is allowed';
			|tr = 'Kayıt yapılmasına izin veriliyor'"));
	
	Result.Insert(Lower("Alias"),
		NStr("vi = 'Tên ảo';
			|ru = 'Псевдоним';
			|en = 'Alias'; fa = 'نام مستعار';
			|it = 'Псевдоним';
			|pl = 'Alias';
			|tr = 'Kullanıcı adı'"));
	
	Result.Insert(Lower("ReadingAllowed"),
		NStr("vi = 'Đã cho phép đọc';
			|ru = 'Чтение разрешено';
			|en = 'Reading is allowed'; fa = 'Reading is allowed';
			|it = 'Чтение разрешено';
			|pl = 'Reading is allowed';
			|tr = 'Okumaya izin verildi'"));
	
	Result.Insert(Lower("AllowedAddIns"),
		NStr("vi = 'Cấu phần ngoài được phép';
			|ru = 'Разрешенные внешние компоненты';
			|en = 'Allowed add-ins'; fa = 'Allowed add-ins';
			|it = 'Разрешенные внешние компоненты';
			|pl = 'Allowed add-ins';
			|tr = 'İzin verilen dış eklentiler'"));
	
	Result.Insert(Lower("AllowedExternalModules"),
		NStr("vi = 'Mô-đun ngoài được phép';
			|ru = 'Разрешенные внешние модули';
			|en = 'Allowed external modules'; fa = 'Allowed external modules';
			|it = 'Разрешенные внешние модули';
			|pl = 'Allowed external modules';
			|tr = 'İzin verilen dış moduller'"));
	
	Result.Insert(Lower("AllowedExternalApps"),
		NStr("vi = 'Ứng dụng ngoài được phép';
			|ru = 'Разрешенные внешние приложения';
			|en = 'Allowed external apps'; fa = 'Allowed external apps';
			|it = 'Разрешенные внешние приложения';
			|pl = 'Allowed external apps';
			|tr = 'İzin verilen dış uygulamalar'"));
	
	Result.Insert(Lower("AllowedInternetResources"),
		NStr("vi = 'Nguồn internet được phép';
			|ru = 'Разрешенные интернет-ресурсы';
			|en = 'Allowed internet resources'; fa = 'Allowed internet resources';
			|it = 'Разрешенные интернет-ресурсы';
			|pl = 'Allowed internet resources';
			|tr = 'İzin verilen internet kaynaklar'"));
	
	Result.Insert(Lower("Address"),
		NStr("vi = 'Địa chỉ';
			|ru = 'Адрес';
			|en = 'Address'; fa = 'آدرس';
			|it = 'Адрес';
			|pl = 'Address';
			|tr = 'Adres'"));
	
	Result.Insert(Lower("Port"),
		NStr("vi = 'Cổng';
			|ru = 'Порт';
			|en = 'Port'; fa = 'پورت';
			|it = 'Порт';
			|pl = 'Port';
			|tr = 'Port'"));
	
	Result.Insert(Lower("Protocol"),
		NStr("vi = 'Biên bản';
			|ru = 'Протокол';
			|en = 'Protocol'; fa = 'پروتکل';
			|it = 'Протокол';
			|pl = 'Protocol';
			|tr = 'Protokol'"));
	
	Result.Insert(Lower("PrivilegedModeAllowed"),
		NStr("vi = 'Cho phép cài đặt chế độ đặc quyền';
			|ru = 'Разрешить установку привилегированного режима';
			|en = 'Allow setting privileged mode'; fa = 'Allow setting privileged mode';
			|it = 'Разрешить установку привилегированного режима';
			|pl = 'Allow setting privileged mode';
			|tr = 'Ayrıcalıklı mod kurulumuna izin ver'"));
	
	// _$InfoBase$_.SessionLockChange*
	Result.Insert(Lower("KeyCode"),
		NStr("vi = 'Mã cho phép';
			|ru = 'Код разрешения';
			|en = 'Access code'; fa = 'Access code';
			|it = 'Код разрешения';
			|pl = 'Access code';
			|tr = 'İzin kodu'"));
	
	Result.Insert(Lower("End"),
		NStr("vi = 'Kết thúc';
			|ru = 'Конец';
			|en = 'End'; fa = 'پایان';
			|it = 'Конец';
			|pl = 'End';
			|tr = 'Bitiş'"));
	
	Result.Insert(Lower("Parameter"),
		NStr("vi = 'Tham số';
			|ru = 'Параметр';
			|en = 'Parameter'; fa = 'پارامتر';
			|it = 'Параметр';
			|pl = 'Parameter';
			|tr = 'Parametre'"));
	
	Result.Insert(Lower("Message"),
		NStr("vi = 'Tin nhắn';
			|ru = 'Сообщение';
			|en = 'Message'; fa = 'پیام';
			|it = 'Сообщение';
			|pl = 'Message';
			|tr = 'Mesaj'"));
	
	Result.Insert(Lower("Use"),
		NStr("vi = 'Đã cài đặt';
			|ru = 'Установлена';
			|en = 'Set'; fa = 'مجموعه';
			|it = 'Установлена';
			|pl = 'Set';
			|tr = 'Ayarlandı'"));
	
	// _$InfoBase$_.UserPasswordPolicy*
	Result.Insert(Lower("PasswordMaxEffectivePeriod"),
		NStr("vi = 'Thời hạn hiệu lực tối đa của mật khẩu';
			|ru = 'Максимальный срок действия паролей';
			|en = 'Maximum password lifetime'; fa = 'حداکثر مدت اعتبار رمز عبور';
			|it = 'Максимальный срок действия паролей';
			|pl = 'Maximum password lifetime';
			|tr = 'Parolanın maksimum geçerlilik süresi'"));
	
	Result.Insert(Lower("PasswordMinEffectivePeriod"),
		NStr("vi = 'Thời hạn hiệu lực tối thiểu của mật khẩu';
			|ru = 'Минимальный срок действия паролей';
			|en = 'Minimum password lifetime'; fa = 'حداقل مدت اعتبار رمز عبور';
			|it = 'Минимальный срок действия паролей';
			|pl = 'Minimum password lifetime';
			|tr = 'Parolanın minimum geçerlilik süresi'"));
	
	Result.Insert(Lower("PasswordMinLength"),
		NStr("vi = 'Độ dài tối thiểu của mật khẩu';
			|ru = 'Минимальная длина паролей';
			|en = 'Minimum password length'; fa = 'حداقل طول رمز عبور';
			|it = 'Минимальная длина паролей';
			|pl = 'Minimum password length';
			|tr = 'Parolanın minimum uzunluğu'"));
	
	Result.Insert(Lower("PasswordReuseLimit"),
		NStr("vi = 'Hạn chế việc lặp lại mật khẩu trong số các mật khẩu gần đây';
			|ru = 'Ограничение повторения паролей среди последних';
			|en = 'Prevent re-use of recent passwords'; fa = 'Prevent re-use of recent passwords';
			|it = 'Ограничение повторения паролей среди последних';
			|pl = 'Prevent re-use of recent passwords';
			|tr = 'Son kullanılanlar arasında şifre tekrarının sınırlandırılması'"));
	
	Result.Insert(Lower("PasswordStrengthCheck"),
		NStr("vi = 'Kiểm tra mức độ phức tạp của mật khẩu';
			|ru = 'Проверка сложности паролей';
			|en = 'Password complexity check'; fa = 'Password complexity check';
			|it = 'Проверка сложности паролей';
			|pl = 'Password complexity check';
			|tr = 'Kullanıcı şifrelerinin karmaşıklığını kontrol etme'"));
	
	Result.Insert(Lower("PasswordExpirationNotificationPeriod"),
		NStr("vi = 'Thời gian cảnh báo hết hạn mật khẩu';
			|ru = 'Срок предупреждения об истечении срока действия паролей';
			|en = 'Password expiration notification lead'; fa = 'Password expiration notification lead';
			|it = 'Срок предупреждения об истечении срока действия паролей';
			|pl = 'Password expiration notification lead';
			|tr = 'Şifre süresinin dolması için uyarı süresi'"));
	
	Result.Insert(Lower("ActionOnPasswordRequirementsViolationOnAuthentication"),
		NStr("vi = 'Hành động khi mật khẩu không đáp ứng yêu cầu xác thực';
			|ru = 'Действие при несоответствии паролей требованиям при аутентификации';
			|en = 'Action if password doesn''t meet requirements'; fa = 'Action if password doesn''t meet requirements';
			|it = 'Действие при несоответствии паролей требованиям при аутентификации';
			|pl = 'Action if password doesn''t meet requirements';
			|tr = 'Parolalar kimlik doğrulama gereksinimlerini karşılamadığında yapılacak işlem'"));
	
	Result.Insert(Lower("PasswordCompromiseCheck"),
		NStr("vi = 'Kiểm tra mở ra mật khẩu';
			|ru = 'Проверка раскрытия паролей';
			|en = 'Leaked password check'; fa = 'Leaked password check';
			|it = 'Проверка раскрытия паролей';
			|pl = 'Leaked password check';
			|tr = 'Şifre gösterim kontrolü'"));
	
	// _$OpenIDProvider$_.*
	Result.Insert(Lower("RelyingPartyURL"),
		NStr("vi = 'URL của bên tin cậy';
			|ru = 'URL доверяющей стороны';
			|en = 'Relying party URL'; fa = 'Relying party URL';
			|it = 'URL доверяющей стороны';
			|pl = 'Relying party URL';
			|tr = 'Güvenen tarafın URL''si'"));
	
	// _$Session$_.Authentication*
	Result.Insert(Lower("CurrentOSUser"),
		NStr("vi = 'Người sử dụng hiện tại Hệ điều hành';
			|ru = 'Текущий пользователь ОС';
			|en = 'Current OS user'; fa = 'Current OS user';
			|it = 'Utente corrente SO';
			|pl = 'Bieżący użytkownik systemu operacyjnego';
			|tr = 'Mevcut İşletim Sistemi kullanıcısı'"));
	
	Result.Insert(Lower("AuthenticationMethod"),
		NStr("vi = 'Phương thức xác thực';
			|ru = 'Способ аутентификации';
			|en = 'Authentication method'; fa = 'روش احراز هویت';
			|it = 'Metodo di autenticazione';
			|pl = 'Sposób uwierzytelnienia';
			|tr = 'Kimlik doğrulama yöntemi'"));
	
	Result.Insert(Lower("UsernameAdditionCode"),
		NStr("vi = 'Mã bổ sung tên người sử dụng';
			|ru = 'Код дополнения имени пользователя';
			|en = 'Username addition code'; fa = 'Username addition code';
			|it = 'Код дополнения имени пользователя';
			|pl = 'Username addition code';
			|tr = 'Kullanıcı adı tamamlama kodu'"));
	
	Result.Insert(Lower("UserIDAtOpenIDProvider"),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tên người sử dụng của nhà cung cấp %1';
				|ru = 'Идентификатор пользователя провайдера %1';
				|en = '%1 provider user ID'; fa = '%1 provider user ID';
				|it = 'Идентификатор пользователя провайдера %1';
				|pl = '%1 provider user ID';
				|tr = 'Sağlayıcı kullanıcı kimliği %1'"), "OpenID"));
	
	Result.Insert(Lower("IssuerOfAccessToken"),
		NStr("vi = 'Nhà phát hành token truy cập';
			|ru = 'Эмитент токена доступа';
			|en = 'Access token emitter'; fa = 'Access token emitter';
			|it = 'Эмитент токена доступа';
			|pl = 'Access token emitter';
			|tr = 'Erişim token''ı veren kuruluş'"));
	
	Result.Insert(Lower("AccessTokenID"),
		NStr("vi = 'Tên token truy cập';
			|ru = 'Идентификатор токена доступа';
			|en = 'Access token ID'; fa = 'Access token ID';
			|it = 'Идентификатор токена доступа';
			|pl = 'Access token ID';
			|tr = 'Erişim token''ı kimliği'"));
	
	Result.Insert(Lower("OpenIDProviderURL"),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'URL nhà cung cấp %1';
				|ru = 'URL провайдера %1';
				|en = '%1 provider URL'; fa = '%1 provider URL';
				|it = 'URL провайдера %1';
				|pl = '%1 provider URL';
				|tr = 'Sağlayıcı URS''si %1'"), "OpenID"));
	
	// _$Session$_.ExternalDataProcessorConnect*
	Result.Insert(Lower("Path"),
		NStr("vi = 'Đường dẫn';
			|ru = 'Путь';
			|en = 'Path'; fa = 'مسیر';
			|it = 'Путь';
			|pl = 'Path';
			|tr = 'Yol'"));
	
	Result.Insert(Lower("LanguageCode"),
		NStr("vi = 'Mã ngôn ngữ';
			|ru = 'Код языка';
			|en = 'Language code'; fa = 'کد زبان';
			|it = 'Codice del linguaggio';
			|pl = 'Kod języka';
			|tr = 'Dil kodu'"));
	
	// _$Session$_.AddInAttach*
	Result.Insert(Lower("Location"),
		NStr("vi = 'Vị trí';
			|ru = 'Местоположение';
			|en = 'Location'; fa = 'مکان';
			|it = 'Местоположение';
			|pl = 'Location';
			|tr = 'Konum'"));
	
	Result.Insert(Lower("Type"),
		NStr("vi = 'Kiểu';
			|ru = 'Тип';
			|en = 'Type'; fa = 'نوع';
			|it = 'Тип';
			|pl = 'Type';
			|tr = 'Tür'"));
	
	Result.Insert(Lower("AttachmentType"),
		NStr("vi = 'Kiểu kết nối';
			|ru = 'Тип подключения';
			|en = 'Connection type'; fa = 'نوع اتصال';
			|it = 'Tipo di connessione';
			|pl = 'Typ połączenia';
			|tr = 'Bağlantı türü'"));
	
	// _$User$_.*
	Result.Insert(Lower("Email"),
		NStr("vi = 'Địa chỉ email';
			|ru = 'Адрес электронной почты';
			|en = 'Email address'; fa = 'آدرس ایمیل';
			|it = 'Indirizzo di posta elettronica';
			|pl = 'Adres poczty elektronicznej';
			|tr = 'E-posta adresi'"));
	
	Result.Insert(Lower("OpenIDAuthentication"),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đăng nhập %1';
				|ru = 'Аутентификация %1';
				|en = '%1 authentication'; fa = '%1 authentication';
				|it = 'Аутентификация %1';
				|pl = '%1 authentication';
				|tr = 'Doğrulama %1'"), "OpenID"));
	
	Result.Insert(Lower("OpenIDConnectAuthentication"),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đăng nhập %1';
				|ru = 'Аутентификация %1';
				|en = '%1 authentication'; fa = '%1 authentication';
				|it = 'Аутентификация %1';
				|pl = '%1 authentication';
				|tr = 'Doğrulama %1'"), "OpenID-Connect"));
	
	Result.Insert(Lower("QRCodeAuthentication"),
		NStr("vi = 'Đăng nhập bằng mã QR';
			|ru = 'Аутентификация QR кодом';
			|en = 'QR code authentication'; fa = 'QR code authentication';
			|it = 'Аутентификация QR кодом';
			|pl = 'QR code authentication';
			|tr = 'QR kodla doğrulama'"));
	
	Result.Insert(Lower("OSAuthentication"),
		NStr("vi = 'Đăng nhập hệ điều hành';
			|ru = 'Аутентификация ОС';
			|en = 'OS authentication'; fa = 'احراز هویت سیستم‌عامل';
			|it = 'Autentificazione SO';
			|pl = 'Uwierzytelnianie systemu operacyjnego';
			|tr = 'OS (İşletim sistemi) doğrulama'"));
	
	Result.Insert(Lower("StandardAuthentication"),
		NStr("vi = 'Đăng nhập 1C:Enterprise';
			|ru = 'Аутентификация 1С:Предприятия';
			|en = '1C:Enterprise authentication'; fa = 'احراز هویت 1C:Enterprise';
			|it = 'Autenticazione 1C:Enterprise';
			|pl = 'Uwierzytelnianie 1C:Enterprise';
			|tr = '1C:Enterprise doğrulama'"));
	
	Result.Insert(Lower("AccessTokenAuthentication"),
		NStr("vi = 'Đăng nhập bằng token truy cập';
			|ru = 'Аутентификация токеном доступа';
			|en = 'Access token authentication'; fa = 'احراز هویت با توکن دسترسی';
			|it = 'Аутентификация токеном доступа';
			|pl = 'Access token authentication';
			|tr = 'Erişim token''ı doğrulaması'"));
	
	Result.Insert(Lower("PasswordSettingDate"),
		NStr("vi = 'Ngày cài đặt mật khẩu';
			|ru = 'Дата установки пароля';
			|en = 'Password set date'; fa = 'تاریخ تعیین رمز عبور';
			|it = 'Дата установки пароля';
			|pl = 'Password set date';
			|tr = 'Parola ayarlama tarihi'"));
	
	Result.Insert(Lower("CannotRecoveryPassword"),
		NStr("vi = 'Đã cấm khôi phục mật khẩu';
			|ru = 'Запрещено восстанавливать пароль';
			|en = 'User cannot recover password'; fa = 'کاربر نمی‌تواند رمز عبور را بازیابی کند';
			|it = 'Запрещено восстанавливать пароль';
			|pl = 'User cannot recover password';
			|tr = 'Şifreyi kurtarmak yasaktır'"));
	
	Result.Insert(Lower("CannotChangePassword"),
		NStr("vi = 'Cấm thay đổi mật khẩu';
			|ru = 'Запрещено изменять пароль';
			|en = 'User cannot change password'; fa = 'کاربر نمی‌تواند رمز عبور را تغییر دهد';
			|it = 'Non è consentito modificare la password';
			|pl = 'Nie wolno zmieniać hasła';
			|tr = 'Şifreyi değiştirmek yasaktır'"));
	
	Result.Insert(Lower("UnsafeActionProtection"),
		NStr("vi = 'Bảo vệ khỏi các thao tác nguy hiểm';
			|ru = 'Защита от опасных действий';
			|en = 'Unsafe action protection'; fa = 'حفاظت در برابر اقدامات ناامن';
			|it = 'Защита от опасных действий';
			|pl = 'Unsafe action protection';
			|tr = 'Tehlikeli eylemlerden koruma'"));
	
	Result.Insert(Lower("Name"),
		NStr("vi = 'Tên';
			|ru = 'Имя';
			|en = 'Name'; fa = 'نام';
			|it = 'Имя';
			|pl = 'Name';
			|tr = 'Ad'"));
	
	Result.Insert(Lower("PasswordPolicyName"),
		NStr("vi = 'Tên chính sách mật khẩu';
			|ru = 'Имя политики паролей';
			|en = 'Password policy name'; fa = 'نام سیاست رمز عبور';
			|it = 'Имя политики паролей';
			|pl = 'Password policy name';
			|tr = 'Parola politikası adı'"));
	
	Result.Insert(Lower("UserMatchingKeys"),
		NStr("vi = 'Khóa so sánh người sử dụng';
			|ru = 'Ключи сопоставления пользователя';
			|en = 'User map keys'; fa = 'User map keys';
			|it = 'Ключи сопоставления пользователя';
			|pl = 'User map keys';
			|tr = 'Kullanıcı eşleştirme anahtarı'"));
	
	Result.Insert(Lower("SecondAuthenticationFactorSettings"),
		NStr("vi = 'Cài đặt yếu tố xác thực thứ hai';
			|ru = 'Настройки второго фактора аутентификации';
			|en = 'Second authentication factor settings'; fa = 'تنظیمات عامل دوم احراز هویت';
			|it = 'Настройки второго фактора аутентификации';
			|pl = 'Second authentication factor settings';
			|tr = 'İkinci faktör kimlik doğrulama ayarları'"));
	
	Result.Insert(Lower("SecondAuthenticationFactorSettingsProcessing"),
		NStr("vi = 'Xử lý cài đặt yếu tố xác thực thứ hai';
			|ru = 'Обработка настроек второго фактора аутентификации';
			|en = 'Second authentication factor settings processing'; fa = 'پردازش تنظیمات عامل دوم احراز هویت';
			|it = 'Обработка настроек второго фактора аутентификации';
			|pl = 'Second authentication factor settings processing';
			|tr = 'İkinci faktör kimlik doğrulama ayarları işleniyor'"));
	
	Result.Insert(Lower("PasswordChanged"),
		NStr("vi = 'Đã thay đổi mật khẩu';
			|ru = 'Пароль изменен';
			|en = 'Password is changed'; fa = 'رمز عبور تغییر کرده است';
			|it = 'Password modificata';
			|pl = 'Hasło zmieniono';
			|tr = 'Şifre değiştirildi'"));
	
	Result.Insert(Lower("PasswordDoesNotSatisfyRequirements"),
		NStr("vi = 'Mật khẩu không tương ứng với yêu cầu';
			|ru = 'Пароль не соответствует требованиям';
			|en = 'Password does not meet requirements'; fa = 'Password does not meet requirements';
			|it = 'Пароль не соответствует требованиям';
			|pl = 'Password does not meet requirements';
			|tr = 'Şifre şartları karşılamıyor'"));
	
	Result.Insert(Lower("PasswordIsSet"),
		NStr("vi = 'Đã đặt mật khẩu';
			|ru = 'Пароль установлен';
			|en = 'Password is set'; fa = 'رمز عبور تعیین شده است';
			|it = 'Password impostata';
			|pl = 'Hasło ustawione';
			|tr = 'Şifre belirlendi'"));
	
	Result.Insert(Lower("ShowInList"),
		NStr("vi = 'Hiển thị trong danh sách chọn';
			|ru = 'Показывать в списке выбора';
			|en = 'Show in list'; fa = 'نمایش در فهرست';
			|it = 'Visualizza nell''elenco di selezione';
			|pl = 'Pokaż na liście wyboru';
			|tr = 'Seçim listesinde göster'"));
	
	Result.Insert(Lower("FullName"),
		NStr("vi = 'Tên đầy đủ';
			|ru = 'Полное имя';
			|en = 'Full name'; fa = 'نام کامل';
			|it = 'Nome completo';
			|pl = 'Pełna nazwa';
			|tr = 'Tam adı'"));
	
	Result.Insert(Lower("OSUser"),
		NStr("vi = 'Người sử dụng hệ điều hành';
			|ru = 'Пользователь ОС';
			|en = 'OS user'; fa = 'کاربر سیستم‌عامل';
			|it = 'Utente SO';
			|pl = 'Użytkownik systemu operacyjnego';
			|tr = 'İşletim sistemi kullanıcısı'"));
	
	Result.Insert(Lower("RunMode"),
		NStr("vi = 'Chế độ khởi động';
			|ru = 'Режим запуска';
			|en = 'Run mode'; fa = 'حالت اجرا';
			|it = 'Modalità di avvio';
			|pl = 'Tryb uruchomienia';
			|tr = 'Çalışma modu'"));
	
	Result.Insert(Lower("DefaultInterface"),
		NStr("vi = 'Giao diện chính';
			|ru = 'Основной интерфейс';
			|en = 'Main interface'; fa = 'Main interface';
			|it = 'Основной интерфейс';
			|pl = 'Main interface';
			|tr = 'Ana arayüz'"));
	
	Result.Insert(Lower("Roles"),
		NStr("vi = 'Vai trò';
			|ru = 'Роли';
			|en = 'Roles'; fa = 'نقش‌ها';
			|it = 'Роли';
			|pl = 'Roles';
			|tr = 'Roller'"));
	
	Result.Insert(Lower("PasswordHashAlgorithmType"),
		NStr("vi = 'Kiểu thuật toán băm (hash) mật khẩu';
			|ru = 'Тип алгоритма хеширования пароля';
			|en = 'Password hashing algorithm type'; fa = 'Password hashing algorithm type';
			|it = 'Тип алгоритма хеширования пароля';
			|pl = 'Password hashing algorithm type';
			|tr = 'Parola karma algoritma tipi'"));
	
	Result.Insert(Lower("Language"),
		NStr("vi = 'Ngôn ngữ';
			|ru = 'Язык';
			|en = 'Language'; fa = 'زبان';
			|it = 'Язык';
			|pl = 'Language';
			|tr = 'Dil'"));
	
	Result.Insert(Lower("Users"),
		NStr("vi = 'Người sử dụng';
			|ru = 'Пользователи';
			|en = 'Users'; fa = 'کاربران';
			|it = 'Пользователи';
			|pl = 'Users';
			|tr = 'Kullanıcılar'"));
	
	Result.Insert(Lower("DataSeparation"),
		NStr("vi = 'Phân chia dữ liệu';
			|ru = 'Разделение данных';
			|en = 'Data separation'; fa = 'تفکیک داده';
			|it = 'Divisione dei dati';
			|pl = 'Podział danych';
			|tr = 'Veri ayırma'"));
	
	Return Result;
	
EndFunction

// Returns:
//  Boolean
//
Function StandardSeparatorsOnly() Export
	
	If Not Common.SubsystemExists(
			"StandardSubsystems.SaaSOperations.CoreSaaS") Then
		Return False;
	EndIf;
	
	ModuleSaaSSSL = Common.CommonModule("SaaSOperationsSSL");
	
	Return ModuleSaaSSSL.StandardSeparatorsOnly();
	
EndFunction

Function StringDelimitersList(SeparatorLine) Export
	
	List = New ValueList;
	Values = StrSplit(SeparatorLine, ",");
	List.LoadValues(Values);
	
	ListItem = List.FindByValue("");
	If ListItem <> Undefined Then
		ListItem.Presentation = NStr("vi = '<Chưa đặt>';
									|ru = '<Не задано>';
									|en = '<Not specified>'; fa = '<مشخص نشده>';
									|it = '<Non impostato>';
									|pl = '<Nie określono>';
									|tr = '<Belirlenmedi>'");
	EndIf;
	
	Return List;
	
EndFunction

// Filter transformation.
//
// Parameters:
//  Filter - Filter - the filter to be passed.
//
Procedure FilterTransformation(Filter, ServerTimeOffset)
	
	For Each FilterElement In Filter Do
		If TypeOf(FilterElement.Value) = Type("ValueList") Then
			FilterItemTransform(Filter, FilterElement);
		ElsIf Upper(FilterElement.Key) = Upper("Transaction") Then
			If StrFind(FilterElement.Value, "(") = 0 Then
				Filter.Insert(FilterElement.Key, "(" + FilterElement.Value);
			EndIf;
		ElsIf ServerTimeOffset <> 0
			And (Upper(FilterElement.Key) = Upper("StartDate") Or Upper(FilterElement.Key) = Upper("EndDate")) Then
			Filter.Insert(FilterElement.Key, FilterElement.Value + ServerTimeOffset);
		EndIf;
	EndDo;
	
EndProcedure

// Filter item transformation.
//
// Parameters:
//  Filter - Filter - the filter to be passed.
//  Filter - FilterElement - an item of the filter to be passed.
//
Procedure FilterItemTransform(Filter, FilterElement)
	
	FilterStructureKey = FilterElement.Key;
	// The procedure is called when the filter item is a value list
	// (the filter should take an array). Convert the list into an array.
	If Upper(FilterStructureKey) = Upper("SessionDataSeparation") Then
		NewValue = New Structure;
	Else
		NewValue = New Array;
	EndIf;
	
	FilterStructureKey = FilterElement.Key;
	
	For Each ValueFromList In FilterElement.Value Do
		If Upper(FilterStructureKey) = Upper("Level") Then
			// Message text level is a string, it must be converted into an enumeration.
			NewValue.Add(DataProcessors.EventLog.EventLogLevelValueByName(ValueFromList.Value));
		ElsIf Upper(FilterStructureKey) = Upper("TransactionStatus") Then
			// Transaction status is a string, it must be converted into an enumeration.
			NewValue.Add(DataProcessors.EventLog.EventLogEntryTransactionStatusValueByName(ValueFromList.Value));
		ElsIf Upper(FilterStructureKey) = Upper("SessionDataSeparation") Then
			SeparatorValueArray = New Array;
			FilterStructureKey = "SessionDataSeparation";
			DataSeparationArray = StrSplit(ValueFromList.Value, "=", True);
			
			SeparatorValues = StrSplit(DataSeparationArray[1], ",", True);
			For Each SeparatorValue In SeparatorValues Do
				If Not ValueIsFilled(SeparatorValue) Then
					SeparatorValue = Undefined;
				Else
					SeparatorValue = Number(SeparatorValue);
				EndIf;
				SeparatorFilterItem = New Structure("Value, Use",
					SeparatorValue, SeparatorValue <> Undefined);
				SeparatorValueArray.Add(SeparatorFilterItem);
			EndDo;
			
			NewValue.Insert(DataSeparationArray[0], SeparatorValueArray);
			
		ElsIf Upper(FilterStructureKey) = Upper("User") Then
			If StringFunctionsClientServer.IsUUID(ValueFromList.Value) Then
				IBUserID = New UUID(ValueFromList.Value);
				SetPrivilegedMode(True);
				IBUser = InfobaseUserForFilter(IBUserID);
				SetPrivilegedMode(False);
			Else
				IBUser = Undefined;
			EndIf;
			If IBUser = Undefined Then
				NewValue.Add(ValueFromList.Presentation);
			Else
				NewValue.Add(IBUser);
			EndIf;
			
		ElsIf Upper(FilterStructureKey) = Upper("Data") Then
			Value = ValueFromList.Value;
			If Common.IsReference(TypeOf(Value)) Then
				NewValue.Add(ValueToStringInternal(Value));
			ElsIf ValueIsFilled(ValueFromList.Presentation) Then
				EventData = EventData(ValueFromList.Value);
				If EventData <> Undefined Then
					Value = EventData;
				EndIf;
			EndIf;
			NewValue.Add(Value);
		Else
			NewValue.Add(ValueFromList.Value);
		EndIf;
	EndDo;
	
	If TypeOf(NewValue) = Type("Array") And NewValue.Count() = 1 Then
		NewValue = NewValue[0];
	EndIf;
	
	Filter.Insert(FilterElement.Key, NewValue);
	
EndProcedure

// Adds a restriction to the filter presentation.
//
// Parameters:
//  EventLogFilter - Filter - the event log filter.
//  FilterPresentation - String - filter presentation.
//  RestrictionName - String - the name of the restriction.
//  DefaultEventLogFilter - Filter - the default event log filter.
//
Procedure AddRestrictionToFilterPresentation(EventLogFilter, FilterPresentation, RestrictionName,
	DefaultEventLogFilter = Undefined)
	
	If Not EventLogFilter.Property(RestrictionName) Then
		Return;
	EndIf;
	
	RestrictionList = EventLogFilter[RestrictionName];
	Restriction       = "";
	
	// If filter value is a default value there is no need to get a presentation of it.
	If DefaultEventLogFilter <> Undefined Then
		DefaultRestrictionList = "";
		If DefaultEventLogFilter.Property(RestrictionName, DefaultRestrictionList) Then
			If ValueToStringInternal(DefaultRestrictionList) = ValueToStringInternal(RestrictionList) Then
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	If RestrictionName = "Event" And RestrictionList.Count() > 5 Then
		
		Restriction = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sự kiện (%1)';
																					|ru = 'События (%1)';
																					|en = 'Events (%1)'; fa = 'Events (%1)';
																					|it = 'Eventi (%1)';
																					|pl = 'Wydarzenia (%1)';
																					|tr = 'Olaylar (%1)'"), RestrictionList.Count());
		
	ElsIf RestrictionName = "Session" And RestrictionList.Count() > 3 Then
		
		Restriction = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Phiên làm việc (%1)';
																					|ru = 'Сеансы (%1)';
																					|en = 'Sessions (%1)'; fa = 'Sessions (%1)';
																					|it = 'Sessioni (%1)';
																					|pl = 'Sesje (%1)';
																					|tr = 'Oturumlar (%1)'"), RestrictionList.Count());
		
	Else
		
		For Each ListItem In RestrictionList Do
			If Not IsBlankString(Restriction) Then
				Restriction = Restriction + ", ";
			EndIf;
			
			If Not ValueIsFilled(ListItem.Presentation) Then
				RestrictionValue = ListItem.Value;
			Else
				RestrictionValue = ListItem.Presentation;
			EndIf;
			
			If (Upper(RestrictionName) = Upper("Session")
				Or Upper(RestrictionName) = Upper("Level"))
				And IsBlankString(Restriction) Then
				
				If RestrictionName = "Session" Then
					RestrictionPresentation = NStr("vi = 'Phiên làm việc';
													|ru = 'Сеанс';
													|en = 'Session'; fa = 'جلسه';
													|it = 'Sessione';
													|pl = 'Seans';
													|tr = 'Oturum'");
				Else
					RestrictionPresentation = NStr("vi = 'Mức độ';
													|ru = 'Уровень';
													|en = 'Level'; fa = 'سطح';
													|it = 'Livello';
													|pl = 'Poziom';
													|tr = 'Seviye'");
				EndIf;
				
				Restriction = NStr("vi = '%1: %2';
									|ru = '%1: %2';
									|en = '%1: %2'; fa = '%1: %2';
									|it = '%1: %2';
									|pl = '%1: %2';
									|tr = '%1: %2'");
				Restriction = StringFunctionsClientServer.SubstituteParametersToString(Restriction, RestrictionPresentation, RestrictionValue);
			Else
				Restriction = Restriction + RestrictionValue;
			EndIf;
		EndDo;
		
	EndIf;
	
	If Not IsBlankString(FilterPresentation) Then 
		FilterPresentation = FilterPresentation + "; ";
	EndIf;
	
	FilterPresentation = FilterPresentation + Restriction;
	
EndProcedure

#Region AuxiliaryProceduresAndFunctions

// For internal use only.
//
Procedure SetDataString(LogEvent)
	
	DataAsStr = ValueToStringInternal(LogEvent.Data);
	RefinedString = CommonClientServer.ReplaceProhibitedXMLChars(DataAsStr);
	
	If DataAsStr <> RefinedString Then
		Try
			ValueFromStringInternal(RefinedString);
			DataAsStr = RefinedString;
		Except
			DataAsStr = "";
		EndTry;
	EndIf;
	
	LogEvent.DataAsStr = DataAsStr;
	
EndProcedure

Function EventLevelByPresentation(LevelPresentation)
	If LevelPresentation = "Information" Then
		Return EventLogLevel.Information;
	ElsIf LevelPresentation = "Error" Then
		Return EventLogLevel.Error;
	ElsIf LevelPresentation = "Warning" Then
		Return EventLogLevel.Warning; 
	ElsIf LevelPresentation = "Note" Then
		Return EventLogLevel.Note;
	EndIf;	
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ReadEventLogEvents", True);
	
EndProcedure

#EndRegion