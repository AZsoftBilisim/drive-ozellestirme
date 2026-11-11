#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.GroupSendToTechnicalSupport.Visible = CommonCEL.UsedMessagesToTechnicalSupportService()
		And CommonCELInternalServerCall.AuthenticationDataOfOnlineSupportUserFilled();
			
	Items.UploadToFileGroup.Visible = Not CommonCEL.ThisIsMobilePlatform();
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	For Each String In Rows Do
		Data = String.Value.Data;
		If Data.Property("IncomingParameters") And Data.Property("IncomingParameters") Then
			Data.IncomingParameters = LoggingOfCELOperations.FormatOfLoggingParameter(Data.IncomingParameters);
			Data.OutgoingParameters = LoggingOfCELOperations.FormatOfLoggingParameter(Data.OutgoingParameters);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	Keys = New Array;
	For Each RecordKey In Items.List.SelectedRows Do
		Keys.Add(RecordKey);
	EndDo;
	
	If Keys.Count() = 1 Then
		If TypeOf(Keys[0]) = Type("DynamicListGroupRow") Then
			RunTime = 0;
		Else
			RunTime = Item.CurrentData.RunTime;
		EndIf;
	ElsIf Keys.Count() > 1 Then
		RunTime = TimeOfOperation(Keys);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SendDedicatedMessagesToTechnicalSupport(Command)
	// Insert the contents of the handler.
	MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
	MessageParameters = MessageModuleToBPOTechnicalSupportServiceClient.ParametersForSendingErrorMessage();
	
	InformationRecords = DedicatedTechnicalSupportInformation();
	If InformationRecords.Count()>0 Then
	
		AttachmentParameters = New Structure;
		AttachmentParameters.Insert("Presentation", NStr("vi = 'Giao dịch với thiết bị.txt';
														|ru = 'Операции с оборудованием.txt';
														|en = 'Peripheral operations.txt'; fa = 'Peripheral operations.txt';
														|it = 'Операции с оборудованием.txt';
														|pl = 'Peripheral operations.txt';
														|tr = 'Ekipman işlemleri.txt'"));
		AttachmentParameters.Insert("Data",        StrConcat(InformationRecords, Chars.LF));
		AttachmentParameters.Insert("DataKind",     "Text");
		MessageParameters.AttachmentsData.Add(AttachmentParameters);
		
	EndIf;
	
	MessageParameters.ErrorText = NStr("vi = 'Thông tin về các giao dịch với thiết bị được kết nối';
										|ru = 'Информация о операциях с подключаемым оборудованием';
										|en = 'Peripheral operation information'; fa = 'Peripheral operation information';
										|it = 'Информация о операциях с подключаемым оборудованием';
										|pl = 'Peripheral operation information';
										|tr = 'Bağlı ekipmanlar ile gerçekleştirilen işlemlere dair bilgiler'");
	CallbackDescription = New CallbackDescription("MessageToTechnicalSupportCompletion", ThisObject);
	MessageModuleToBPOTechnicalSupportServiceClient.StartSendingErrorMessage(CallbackDescription, MessageParameters);
	
EndProcedure

&AtClient
Procedure SendToTechnicalSupport(Command)
	// Insert the contents of the handler.
	MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
	MessageParameters = MessageModuleToBPOTechnicalSupportServiceClient.ParametersForSendingErrorMessage();
	
	InformationRecords = InfoForTechSupport();
	For Each Information In InformationRecords Do
	
		AttachmentParameters = New Structure;
		AttachmentParameters.Insert("Presentation", Information.FileName);
		AttachmentParameters.Insert("Data",        Information.Data);
		AttachmentParameters.Insert("DataKind",     "Address");
		MessageParameters.AttachmentsData.Add(AttachmentParameters);
		
	EndDo;
	
	MessageParameters.ErrorText = NStr("vi = 'Thông tin về các giao dịch với thiết bị được kết nối';
										|ru = 'Информация о операциях с подключаемым оборудованием';
										|en = 'Peripheral operation information'; fa = 'Peripheral operation information';
										|it = 'Информация о операциях с подключаемым оборудованием';
										|pl = 'Peripheral operation information';
										|tr = 'Bağlı ekipmanlar ile gerçekleştirilen işlemlere dair bilgiler'");
	CallbackDescription = New CallbackDescription("MessageToTechnicalSupportCompletion", ThisObject);
	MessageModuleToBPOTechnicalSupportServiceClient.StartSendingErrorMessage(CallbackDescription, MessageParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function InfoForTechSupport()
	
	TempFileName = GetTempFileName(".txt");
	InformationRecords = New Array();
	Try
		Records = EntriesOnList();
		WritingDownText = New TextWriter(TempFileName);
		For Each Record In Records Do
			WritingDownText.WriteLine(RecordRow(Record));
		EndDo;
		WritingDownText.Close();
		MessageModuleToBPOTechnicalSupportService = 
			CommonCEL.CommonModule("MessagesToTechnicalSupportCEL");
		InformationRecords = MessageModuleToBPOTechnicalSupportService.FileInArchiveIsBrokenDown(TempFileName);
	Except
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Thư viện thiết bị được kết nối.Lỗi gửi thông báo đến bộ phận hỗ trợ kỹ thuật';
				|ru = 'БПО. Ошибка отправки сообщения в техподдержку';
				|en = 'PEL. An error occurred when sending the message to the technical support'; fa = 'PEL. An error occurred when sending the message to the technical support';
				|it = 'БПО. Ошибка отправки сообщения в техподдержку';
				|pl = 'PEL. An error occurred when sending the message to the technical support';
				|tr = 'БПО. Ошибка отправки сообщения в техподдержку'"), 
			StrTemplate(NStr("vi = 'Không thể tạo tệp với các giao dịch: %1';
							|ru = 'Не удается сформировать файл с операциями: %1';
							|en = 'Cannot generate the file with operations: %1'; fa = 'Cannot generate the file with operations: %1';
							|it = 'Не удается сформировать файл с операциями: %1';
							|pl = 'Cannot generate the file with operations: %1';
							|tr = 'İşlemler içeren bir dosya oluşturulamadı: %1'"), ErrorDescription),
			"Error");
	EndTry;
	DeleteFiles(TempFileName);
	
	Return InformationRecords;
	
EndFunction

&AtServer
Function DedicatedTechnicalSupportInformation()
	
	Selection = SelectedEntries();
	InformationRecords = New Array();
	While Selection.Next() Do
		InformationRecords.Add(RecordRow(Selection));
	EndDo;
	Return InformationRecords;
	
EndFunction

&AtClient
Procedure MessageToTechnicalSupportCompletion(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorCode) Then
		CommonCELClient.MessageToUser(Result.ErrorMessage);
	EndIf;
	
EndProcedure 

&AtServer
Function SelectedEntries()
	
	KeyTable_ = New ValueTable();
	KeyTable_.Columns.Add("Date", New TypeDescription("Date"));
	KeyTable_.Columns.Add("OperationNumber", New TypeDescription("Number"));
	For Each RecordKey In Items.List.SelectedRows Do
		TableRow = KeyTable_.Add();
		FillPropertyValues(TableRow, RecordKey);
	EndDo;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OperationsWithPeripherals.Equipment AS Equipment,
		|	OperationsWithPeripherals.Date AS Date,
		|	OperationsWithPeripherals.OperationNumber AS OperationNumber,
		|	OperationsWithPeripherals.YearMonth AS YearMonth,
		|	OperationsWithPeripherals.IncomingParameters AS IncomingParameters,
		|	OperationsWithPeripherals.OutgoingParameters AS OutgoingParameters,
		|	OperationsWithPeripherals.Result AS Result,
		|	OperationsWithPeripherals.Timecode AS Timecode,
		|	OperationsWithPeripherals.EntryType AS EntryType,
		|	OperationsWithPeripherals.VersionAddIn AS VersionAddIn,
		|	OperationsWithPeripherals.DriverVersion AS DriverVersion,
		|	OperationsWithPeripherals.Operation AS Operation,
		|	OperationsWithPeripherals.DeviceID_ AS DeviceID_,
		|	OperationsWithPeripherals.RunTime AS RunTime,
		|	OperationsWithPeripherals.InterfaceRevision AS InterfaceRevision,
		|	OperationsWithPeripherals.Millisecond AS Millisecond,
		|	OperationsWithPeripherals.ErrorCode AS ErrorCode,
		|	OperationsWithPeripherals.ErrorText AS ErrorText,
		|	OperationsWithPeripherals.IncomingParametersString AS IncomingParametersString,
		|	OperationsWithPeripherals.OutgoingParametersString AS OutgoingParametersString,
		|	OperationsWithPeripherals.ErrorTextString AS ErrorTextString
		|FROM
		|	InformationRegister.OperationsWithPeripherals AS OperationsWithPeripherals
		|WHERE
		|	(OperationsWithPeripherals.Date, OperationsWithPeripherals.OperationNumber) IN (&KeyTable_)
		|
		|ORDER BY
		|	Date,
		|	OperationNumber";
	
	Query.SetParameter("KeyTable_", KeyTable_);
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	Return Selection;
	
EndFunction

&AtServerNoContext
Function TimeOfOperation(Keys)
	
	KeyTable_ = New ValueTable();
	KeyTable_.Columns.Add("Equipment", New TypeDescription("CatalogRef.Peripherals"));
	KeyTable_.Columns.Add("Date", New TypeDescription("Date"));
	KeyTable_.Columns.Add("OperationNumber", New TypeDescription("Number"));
	For Each RecordKey In Keys Do
		If TypeOf(RecordKey) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		TableRow = KeyTable_.Add();
		FillPropertyValues(TableRow, RecordKey);
	EndDo;
	
	If KeyTable_.Count()=0 Then
		Return 0;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OperationsWithPeripherals.RunTime AS RunTime
		|FROM
		|	InformationRegister.OperationsWithPeripherals AS OperationsWithPeripherals
		|WHERE
		|	(OperationsWithPeripherals.Equipment, OperationsWithPeripherals.Date, OperationsWithPeripherals.OperationNumber) IN (&KeyTable_)
		|TOTALS
		|	SUM(RunTime)
		|BY
		|	OVERALL";
	
	Query.SetParameter("KeyTable_", KeyTable_);
	Selection = Query.Execute().Select();
	Selection.Next();
	RunTime = Selection.RunTime / 1000;
	Return RunTime;
	
EndFunction

&AtServer
Function RecordRow(Record)
	
	Return InformationRegisters.OperationsWithPeripherals.LogEntryLine(Record);
	
EndFunction

&AtClient
Procedure ExportToFile(Command)
	TextDocumet = UploadAllLinesAtServerToFile();
	TextDocumet.Show();
EndProcedure

&AtServer
Function EntriesOnList()
	
	Schema = Items.List.GetPerformingDataCompositionScheme();
	Settings = Items.List.GetPerformingDataCompositionSettings();
	
	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "IncomingParameters";
	Field.Field = New DataCompositionField("IncomingParameters");
	
	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "OutgoingParameters";
	Field.Field = New DataCompositionField("OutgoingParameters");
	
	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "Millisecond";
	Field.Field = New DataCompositionField("Millisecond");
	
	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "Date";
	Field.Field = New DataCompositionField("Date");
	
	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "IncomingParametersString";
	Field.Field = New DataCompositionField("IncomingParametersString");
	
	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "OutgoingParametersString";
	Field.Field = New DataCompositionField("OutgoingParametersString");

	
	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "ErrorText";
	Field.Field = New DataCompositionField("ErrorText");

	Field = Settings.Structure[0].Selection.Items.Add(Type("DataCompositionSelectedField"));
	Field.Use = True;
	Field.Title = "ErrorTextString";
	Field.Field = New DataCompositionField("ErrorTextString");
	
	Settings.Structure[0].Order.Items.Clear();
	
	Field = Settings.Structure[0].Order.Items.Add(Type("DataCompositionOrderItem"));
	Field.Use = True;
	Field.Field = New DataCompositionField("Date");
	Field.OrderType = DataCompositionSortDirection.Asc;
	
	Field = Settings.Structure[0].Order.Items.Add(Type("DataCompositionOrderItem"));
	Field.Use = True;
	Field.Field = New DataCompositionField("OperationNumber");
	Field.OrderType = DataCompositionSortDirection.Asc;
	
	TemplateComposer = New DataCompositionTemplateComposer();
	CompositionTemplate = TemplateComposer.Execute(Schema, Settings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	
	Return OutputProcessor.Output(CompositionProcessor);
	
EndFunction

&AtServer
Function UploadAllLinesAtServerToFile()

	#If Not MobileAppServer Then
	Records = EntriesOnList();
	TextDocument = New TextDocument();
	For Each Record In Records Do
		TextDocument.AddLine(RecordRow(Record));
	EndDo;
	
	Return TextDocument;
	#EndIf
	
EndFunction

&AtServer
Function UploadSelectedLinesToFileAtServer()

	#If Not MobileAppServer Then
	Selection = SelectedEntries();
	TextDocument = New TextDocument();
	While Selection.Next() Do
		TextDocument.AddLine(RecordRow(Selection));
	EndDo;
	
	Return TextDocument;
	#EndIf
	
EndFunction

&AtClient
Procedure UploadSelectedImagesToFile(Command)
	TextDocumet = UploadSelectedLinesToFileAtServer();
	TextDocumet.Show();
EndProcedure

#EndRegion
