///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure Initialize(ExchangeComponents, Analysis = False) Export

	ExchangeComponents.RunMeasurements = ExchangeComponents.IsExchangeViaExchangePlan 
		And Constants.UsePerformanceMonitoringOfDataSynchronization.Get();
		
	If Not ExchangeComponents.RunMeasurements Then
		Return;
	EndIf;
	
	ExchangeSession = Catalogs.DataExchangesSessions.CreateItem();
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	DescriptionTemplate = NStr("vi = '%1 trong %2 đối với ""%3"" (%4)';
								|ru = '%1 в %2 для ""%3"" (%4)';
								|en = '%1 on %2 for %3 (%4)'; fa = '%1 on %2 for %3 (%4)';
								|it = '%1 в %2 для ""%3"" (%4)';
								|pl = '%1 on %2 for %3 (%4)';
								|tr = '""%3"" için %2 kısmında %1 (%4)'", DefaultLanguageCode); // Sending at 07/18/2022 15:09 for "Enterprise Accounting 3.0"
	Description = StrTemplate(DescriptionTemplate,
		ExchangeComponents.ExchangeDirection,
		CurrentSessionDate(),
		ExchangeComponents.CorrespondentNode,
		ExchangeComponents.CorrespondentNode.Code);
				
	If Analysis Then
		Description = Description + " " + NStr("vi = '(Phân tích)';
												|ru = '(Анализ)';
												|en = '(Analysis)'; fa = '(Analysis)';
												|it = '(Анализ)';
												|pl = '(Analysis)';
												|tr = '(Analiz)'", DefaultLanguageCode);
	EndIf;
	
	ExchangeSession.Description = Description;
		
	ExchangeSession.InfobaseNode = ExchangeComponents.CorrespondentNode;
	ExchangeSession.Begin = CurrentSessionDate();
	
	If ExchangeComponents.ExchangeDirection = "Send" Then
		ExchangeSession.Send = True;
	ElsIf ExchangeComponents.ExchangeDirection = "Receive" Then
		ExchangeSession.Receive = True;
	EndIf;
	
	ExchangeSession.Write();
		
	ExchangeComponents.ExchangeSession = ExchangeSession;
	
	NameOfTemporaryMeasurementDirectory = 
		DataExchangeCached.TempFilesStorageDirectory() + String(New UUID);
		
	CreateDirectory(NameOfTemporaryMeasurementDirectory);
		
	NameOfTemporaryMeasurementFile = CommonClientServer.GetFullFileName(
		NameOfTemporaryMeasurementDirectory, "log.txt"); //ACC:441 - The temporary file will be deleted upon summing up
		
	ExchangeComponents.NameOfTemporaryMeasurementDirectory = NameOfTemporaryMeasurementDirectory;
	ExchangeComponents.NameOfTemporaryMeasurementFile = NameOfTemporaryMeasurementFile;
	ExchangeComponents.RecordingMeasurements = New TextWriter(NameOfTemporaryMeasurementFile, TextEncoding.UTF8);
	
	LogHeader = NStr("vi = 'Bắt đầu đo lường; Thời gian thực hiện; Kiểu sự kiện; Sự kiện; Ghi chú';
					|ru = 'Начало замера; Время выполнения; Тип события; Событие; Комментарий';
					|en = 'Sampling start; Runtime; Event type; Event; Comment'; fa = 'Sampling start; Runtime; Event type; Event; Comment';
					|it = 'Начало замера; Время выполнения; Тип события; Событие; Комментарий';
					|pl = 'Sampling start; Runtime; Event type; Event; Comment';
					|tr = 'Ölçüm başlangıcı; Yürütme süresi; Etkinlik türü; Etkinlik; Yorum'");
	ExchangeComponents.RecordingMeasurements.WriteLine(LogHeader, DefaultLanguageCode);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.DataExchangesSessions");
		LockItem.SetValue("InfobaseNode", ExchangeComponents.CorrespondentNode);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	DataExchangesSessions.Ref,
			|	DataExchangesSessions.Begin AS Begin
			|FROM
			|	Catalog.DataExchangesSessions AS DataExchangesSessions
			|WHERE
			|	DataExchangesSessions.InfobaseNode = &Node
			|	AND DataExchangesSessions.Send = &Send
			|	AND DataExchangesSessions.Receive = &Receive
			|
			|ORDER BY
			|	Begin";
			
		Query.SetParameter("Node", ExchangeComponents.CorrespondentNode);
		Query.SetParameter("Send", ExchangeSession.Send);
		Query.SetParameter("Receive", ExchangeSession.Receive);
		
		SessionTable = Query.Execute().Unload();
		
		For Cnt = 1 To SessionTable.Count() - 5 Do
			ExchangeSession = SessionTable[0].Ref.GetObject();
			ExchangeSession.Delete();
			SessionTable.Delete(0);
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
	
		MessageString = NStr("vi = 'Lỗi khi thử xóa phiên trao đổi: %1. Mô tả lỗi: %2';
							|ru = 'Ошибка при попытке удаления сеанса обмена: %1. Описание ошибки: %2';
							|en = 'An error occurred when deleting the exchange session: %1. Error details: %2'; fa = 'An error occurred when deleting the exchange session: %1. Error details: %2';
							|it = 'Ошибка при попытке удаления сеанса обмена: %1. Описание ошибки: %2';
							|pl = 'An error occurred when deleting the exchange session: %1. Error details: %2';
							|tr = 'Değişim oturumunun silinme denemesinde hata: %1. Hata ayrıntıları: %2'",
			Common.DefaultLanguageCode());
			
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
			ExchangeSession, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, MessageString);
			
	EndTry
	
EndProcedure

Procedure ExitApp(ExchangeComponents) Export
	
	If Not ExchangeComponents.RunMeasurements Then
		Return;
	EndIf;
		
	ExchangeSession = ExchangeComponents.ExchangeSession;
	NameOfTemporaryMeasurementFile = ExchangeComponents.NameOfTemporaryMeasurementFile;
	
	ExchangeComponents.RunMeasurements = False;
	ExchangeComponents.RecordingMeasurements.Close();
	
	BeginTime = ExchangeSession.Begin;
	EndTime = CurrentSessionDate();
	
	NameOfTemporaryMeasurementDirectory = ExchangeComponents.NameOfTemporaryMeasurementDirectory;
	NameOfTemporaryTotalsFile = CommonClientServer.GetFullFileName(NameOfTemporaryMeasurementDirectory, "total.txt");
	ArchiveTempFileName = CommonClientServer.GetFullFileName(NameOfTemporaryMeasurementDirectory, "archive.zip");
	
	RecordingResults = New TextWriter(NameOfTemporaryTotalsFile);
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	// The header
	RecordingResults.WriteLine(NStr("vi = '--- Phiên trao đổi ---';
									|ru = '--- Сеанс обмена ---';
									|en = '--- Exchange session ---'; fa = '--- Exchange session ---';
									|it = '--- Сеанс обмена ---';
									|pl = '--- Exchange session ---';
									|tr = '--- Değişim oturumu ---'", DefaultLanguageCode));
	RecordingResults.WriteLine(NStr("vi = 'Hướng trao đổi:';
									|ru = 'Направление обмена:';
									|en = 'Exchange direction:'; fa = 'Exchange direction:';
									|it = 'Направление обмена:';
									|pl = 'Exchange direction:';
									|tr = 'Değişim yönü:'", DefaultLanguageCode) + ExchangeComponents.ExchangeDirection);
	
	Template = NStr("vi = 'Nút: %1 (%2)';
					|ru = 'Узел: %1 (%2)';
					|en = 'Node: %1 (%2)'; fa = 'Node: %1 (%2)';
					|it = 'Узел: %1 (%2)';
					|pl = 'Node: %1 (%2)';
					|tr = 'Düğüm: %1 (%2)'", DefaultLanguageCode); 
	RecordingResults.WriteLine(StrTemplate(Template, 
		ExchangeComponents.CorrespondentNode,
		ExchangeComponents.CorrespondentNode.Code));
	
	RecordingResults.WriteLine(NStr("vi = 'Bắt đầu:';
									|ru = 'Начало:';
									|en = 'Start:'; fa = 'Start:';
									|it = 'Начало:';
									|pl = 'Start:';
									|tr = 'Başlangıç'", DefaultLanguageCode) + BeginTime);
	RecordingResults.WriteLine(NStr("vi = 'Kết thúc:';
									|ru = 'Окончание:';
									|en = 'End:'; fa = 'End:';
									|it = 'Окончание:';
									|pl = 'End:';
									|tr = 'Bitiş:'", DefaultLanguageCode) + EndTime);
	RecordingResults.WriteLine(NStr("vi = 'Thời gian thực hiện (giây):';
									|ru = 'Время выполнения (сек):';
									|en = 'Runtime (sec):'; fa = 'Runtime (sec):';
									|it = 'Время выполнения (сек):';
									|pl = 'Runtime (sec):';
									|tr = 'Yürütme süresi (sn):'", DefaultLanguageCode) + (EndTime - BeginTime));
	RecordingResults.WriteLine("");
	
	// Event type summary
	RecordingResults.WriteLine(NStr("vi = '--- Giá trị tổng số theo kiểu---';
									|ru = '--- Итоговые значения по типам ---';
									|en = '--- Totals by event type ---'; fa = '--- Totals by event type ---';
									|it = '--- Итоговые значения по типам ---';
									|pl = '--- Totals by event type ---';
									|tr = '--- Türe göre toplam değerler ---'", DefaultLanguageCode));
	RecordingResults.WriteLine(NStr("vi = 'Kiểu sự kiện; Thời gian thực hiện';
									|ru = 'Тип события; Время выполнения';
									|en = 'Event type; Runtime'; fa = 'Event type; Runtime';
									|it = 'Тип события; Время выполнения';
									|pl = 'Event type; Runtime';
									|tr = 'Etkinlik türü; Yürütme süresi'", DefaultLanguageCode));
	
	TableOfMeasurementsByEventType = ExchangeComponents.TableOfMeasurementsByEvents.Copy(, "EventType, RunTime");
	TableOfMeasurementsByEventType.GroupBy("EventType", "RunTime");
	
	Template = "%1; %2";
	For Each TableRow In TableOfMeasurementsByEventType Do
	
		String = StrTemplate(Template, 
			TableRow.EventType,
			TableRow.RunTime);
		
		RecordingResults.WriteLine(String);
			
	EndDo;
	
	RecordingResults.WriteLine("");
	
	// Event summary
	RecordingResults.WriteLine(NStr("vi = '--- Giá trị tổng số theo sự kiện ---';
									|ru = '--- Итоговые значения по событиям ---';
									|en = '--- Totals by event ---'; fa = '--- Totals by event ---';
									|it = '--- Итоговые значения по событиям ---';
									|pl = '--- Totals by event ---';
									|tr = '--- Etkinliklere göre toplam değerler ---'", DefaultLanguageCode));
	RecordingResults.WriteLine(NStr("vi = 'Tỷ lệ phần trăm; Thời gian trung bình; Thời gian; Số lượng sự kiện; Kiểu sự kiện; Sự kiện';
									|ru = 'Процент; Ср. время; Время; Кол-во событий; Тип события; Событие';
									|en = 'Percentage; Average time; Time; Number of events; Event type; Event'; fa = 'Percentage; Average time; Time; Number of events; Event type; Event';
									|it = 'Процент; Ср. время; Время; Кол-во событий; Тип события; Событие';
									|pl = 'Percentage; Average time; Time; Number of events; Event type; Event';
									|tr = 'Yüzde; Ort. süre; Zaman; Etkinlik sayısı; Etkinlik türü; Etkinlik'", DefaultLanguageCode));
	
	MeasurementsTable = ExchangeComponents.TableOfMeasurementsByEvents;
	MeasurementsTable.Sort("RunTime Desc");
	
	LeadTimeTotal = MeasurementsTable.Total("RunTime"); 
	
	Template = "%1; %2; %3; %4; %5; %6";
		
	For Each TableRow In MeasurementsTable Do
		
		If LeadTimeTotal > 0 Then
			Percent = Round(TableRow.RunTime / LeadTimeTotal * 100, 3);
		Else
			Percent = 0;
		EndIf;
		Percent = StringFunctionsClientServer.SupplementString(Percent, 7, " ", "Left");
				
		AverageLeadTime = Round(TableRow.RunTime / TableRow.Count, 3);
		AverageLeadTime = StringFunctionsClientServer.SupplementString(AverageLeadTime, 7, " ", "Left");
		
		RunTime = Round(TableRow.RunTime, 3);
		RunTime = Format(RunTime,"NG=;");
		RunTime = StringFunctionsClientServer.SupplementString(RunTime, 7, " ", "Left");
		
		Count = Format(TableRow.Count,"NG=;");
		Count = StringFunctionsClientServer.SupplementString(Count, 7, " ", "Left");
		EventType = StringFunctionsClientServer.SupplementString(TableRow.EventType, 11, " ", "Right");
		
		String = StrTemplate(Template,
			Percent,
			AverageLeadTime,
			RunTime,
			Count,
			EventType,
			TableRow.Event); 
			
		RecordingResults.WriteLine(String);
		
	EndDo;
	
	RecordingResults.Close();
	
	//	
	ExchangeSession.Ending = EndTime;
	ExchangeSession.RunTime = EndTime - BeginTime;
	
	Archive = New ZipFileWriter(ArchiveTempFileName);
	Archive.Add(NameOfTemporaryMeasurementFile);
	Archive.Add(NameOfTemporaryTotalsFile);
	Archive.Write();
		
	ExchangeSession.PerformanceMeasurements = New ValueStorage(New BinaryData(ArchiveTempFileName));
	ExchangeSession.Write();
	
	// Delete the temporary files
	DeleteFiles(NameOfTemporaryMeasurementDirectory);
	
EndProcedure

Function StartMeasurement() Export
		
	Return CurrentUniversalDateInMilliseconds();
	
EndFunction

Procedure FinishMeasurement(BeginTime, Event, Object, ExchangeComponents, EventType) Export

	If Event = "" Or Not ExchangeComponents.RunMeasurements Then
		Return;
	EndIf;
	
	Begin = Date(1,1,1) + BeginTime / 1000;
	
	EndTime = CurrentUniversalDateInMilliseconds();
	RunTime = Round((EndTime - BeginTime) / 1000, 3);
	
	ObjectPresentation = ObjectPresentation(Object);
	
	// Log
	StringPattern = "%1; %2; %3; %4; %5";
		
	String = StrTemplate(StringPattern,
		Begin,
		Format(RunTime,"NG=;"),
		EventType,
		Event,
		ObjectPresentation);
		
	RecordingMeasurements = ExchangeComponents.RecordingMeasurements;
	RecordingMeasurements.WriteLine(String);
	
	// Event summary data
	MeasurementsTable = ExchangeComponents.TableOfMeasurementsByEvents;
	Measurement = MeasurementsTable.Find(Event, "Event");
	
	If Measurement = Undefined Then
		NewMeasurement = MeasurementsTable.Add();
		NewMeasurement.Event = Event;
		NewMeasurement.EventType = EventType;
		NewMeasurement.Count = 1;
		NewMeasurement.RunTime = RunTime;
	Else 
		Measurement.Count = Measurement.Count + 1;
		Measurement.RunTime = Measurement.RunTime + RunTime;
	EndIf;
	
EndProcedure

Function TableOfMeasurementsByEvents() Export

	Table = New ValueTable;
	Table.Columns.Add("Event");
	Table.Columns.Add("EventType");
	Table.Columns.Add("Count");
	Table.Columns.Add("RunTime");

	Table.Indexes.Add("Event");
	
	Return Table;
	
EndFunction

Function EventTypeRule() Export

	Return NStr("vi = 'Quy tắc trao đổi';
				|ru = 'Правила обменов';
				|en = 'Exchange rules'; fa = 'Exchange rules';
				|it = 'Правила обменов';
				|pl = 'Exchange rules';
				|tr = 'Değişim kuralı'", Common.DefaultLanguageCode());
	
EndFunction

Function EventTypeLibrary() Export

	Return NStr("vi = 'Phân hệ trao đổi';
				|ru = 'Подсистема обменов';
				|en = 'Exchange subsystem'; fa = 'Exchange subsystem';
				|it = 'Подсистема обменов';
				|pl = 'Exchange subsystem';
				|tr = 'Değişim alt sistemi'", Common.DefaultLanguageCode());
	
EndFunction

Function EventTypeApplied() Export

	Return NStr("vi = 'Cấu hình còn lại';
				|ru = 'Остальная конфигурация';
				|en = 'Other configuration components'; fa = 'Other configuration components';
				|it = 'Остальная конфигурация';
				|pl = 'Other configuration components';
				|tr = 'Kalan konfigürasyon'", Common.DefaultLanguageCode());
	
EndFunction	

#EndRegion

#Region Private

Function ObjectPresentation(Object)

	If TypeOf(Object) = Type("Structure") Then
		
		ArrayOfKeysAndValues = New Array;
		Template = "%1 = ""%2""";
		
		If Object.Property("KeyProperties") Then
			
			For Each KeyAndValue In Object.KeyProperties Do
				
				If Not ValueIsFilled(KeyAndValue.Value) 
					Or TypeOf(KeyAndValue.Value) = Type("Structure") Then
					Continue;
				EndIf;
				
				String = StrTemplate(Template, KeyAndValue.Key, KeyAndValue.Value); 
				ArrayOfKeysAndValues.Add(String);
				
			EndDo;
			
		EndIf;
		
		Return StrConcat(ArrayOfKeysAndValues, ", ");
		
	Else
		
		Return String(Object);
		
	EndIf;

EndFunction

#EndRegion