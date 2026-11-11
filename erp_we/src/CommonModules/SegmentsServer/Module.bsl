
#Region Public

// Adds a partner to the partners segment.
//
// Parameters:
//  Segment  - CatalogRef.PartnersSegments - the segment that the partner is added to.
//  Partner  - CatalogRef.Partners - partner to add to the segment.
//
Procedure AddPartnerToSegment(Segment,Partner) Export
	
	Record = InformationRegisters.SegmentPartners.CreateRecordManager();
	Record.Segment = Segment;
	Record.Partner = Partner;
	Record.Write();
	
EndProcedure

// Adds the item\characteristic pair to the item segment.
//
// Parameters:
//  Segment        - CatalogRef.ProductSegments - the segment to which you are adding the item.
//  Products   - CatalogRef.Products - the item to add to the segment.
//  Characteristic - CatalogRef.ItemsCharacteristics - item characteristics to add to the segment.
//
Procedure AddProductsToSegment(Segment, Products, Characteristic = Undefined) Export

	Record = InformationRegisters.SegmentProducts.CreateRecordManager();
	Record.Segment = Segment;
	Record.Products = Products;
	If Characteristic = Undefined Then
		Record.Characteristic = Characteristic;
	EndIf;
	
	Record.Write();

EndProcedure 

// Removes a couple of item\with the characteristic of the segment of the item.
//
// Parameters:
//  Segment        - CatalogRef.ProductSegments - the segment from which items are deleted.
//  Products   - CatalogRef.Products - item to delete from the segment.
//  Characteristic - CatalogRef.ItemsCharacteristics - removed from the item segment.
//
Procedure RemoveProductsFromSegment(Segment, Products, Characteristic = Undefined) Export

	RecordSet = InformationRegisters.SegmentProducts.CreateRecordSet();
	RecordSet.Filter.Segment.Set(Segment);
	RecordSet.Filter.Products.Set(Products);
	If Characteristic <> Undefined Then
		RecordSet.Filter.Characteristic.Set(Characteristic);
	EndIf;
	RecordSet.Write();

EndProcedure

// Removes a partner from the partners segment.
//
// Parameters:
//  Segment  - CatalogRef.PartnersSegments - the segment that the partner is being removed from.
//  Partner  - CatalogRef.Partners - partner to delete from the segment.
//
Procedure RemovePartnerFromSegment(Segment, Partner) Export

	RecordSet = InformationRegisters.SegmentPartners.CreateRecordSet();
	RecordSet.Filter.Segment.Set(Segment);
	RecordSet.Filter.Partner.Set(Partner);
	RecordSet.Write();

EndProcedure

// Creates an entry in the log and messages to the user, 
//  Supports up to 4 parameters in comments using the function 
//    Strokemymouse.Substitute the parameter string
//  Supports transmitting error information, and a detailed representation 
//    of the error is added to the log entry comment.
// 
// Parameters:
//   LogParameters  - Structure - parameters for recording in the registration Log:
//    * Prefix    - String           - the prefix for the name of the event log.
//    * Metadata - MetadataObject - metadata for writing to the log.
//    * Data     - Arbitrary     - data to write to the log.
//   LogLevel - Number - Corresponds to the log levels.
//   EventName     - String - The suffix for the name of the event log.
//   CommentWithParameters -String - Comment, possibly with parameters %1 .. %4.
//   ErrorInfo - ErrorInfo, String - Information about the error that also needs
//                                                     to be documented in the log comments.
//
Procedure LogRecord(LogParameters, LogLevel , EventName, 
		Val CommentWithParameters , ErrorInfo = "") Export
	
	// Determining the log level based on the type of error message passed.
	If TypeOf(LogLevel) <> Type("EventLogLevel") Then
		If TypeOf(ErrorInfo) = Type("String") Then
			LogLevel = EventLogLevel.Warning;
		ElsIf TypeOf(ErrorInfo) = Type("ErrorInfo") Then
			LogLevel = EventLogLevel.Error;
		Else
			LogLevel = EventLogLevel.Information;
		EndIf;
	EndIf;
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		If CommentWithParameters = "" Then
			MessageToUserText = BriefErrorDescription(ErrorInfo);
			CommentWithParameters = DetailErrorDescription(ErrorInfo);
		Else
			MessageToUserText = CommentWithParameters + Chars.LF + BriefErrorDescription(ErrorInfo);
			CommentWithParameters = CommentWithParameters + Chars.LF + DetailErrorDescription(ErrorInfo);
		EndIf;
	Else
		If TypeOf(ErrorInfo) = Type("String") And ErrorInfo <> "" Then
			CommentWithParameters = CommentWithParameters + Chars.LF + ErrorInfo;
		EndIf;
		MessageToUserText = CommentWithParameters;
	EndIf;
	
	// Log 
	SetPrivilegedMode(True);
	EventGroup_ = LogParameters.EventGroup_ + ?(EventName = "", "", "."+ EventName);
	WriteLogEvent(
		EventGroup_, 
		LogLevel, 
		LogParameters.Metadata, 
		LogParameters.Data, 
		CommentWithParameters);
	SetPrivilegedMode(False);
	
	If LogLevel = EventLogLevel.Error Or LogLevel = EventLogLevel.Warning Then
		If LogLevel = EventLogLevel.Error Then
			LogParameters.Insert("HadErrors", True);
		Else
			LogParameters.Insert("HasWarnings", True);
		EndIf;
		Message = New UserMessage;
		Message.Text = TrimAll(MessageToUserText); //  + Symbols.PS + Symbols.PS + NStr ("ru = 'For details, see in the registration log.'")
		Message.SetData(LogParameters.Data);
		Message.Message();
	EndIf;
	
EndProcedure

// Clears the non-dynamic segments on the planned dates
//
Procedure PerformRoutineCleaning() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.SegmentClearance);
	
	SetPrivilegedMode(True);

	// select manually generated segments with a suitable cleaning date
	Query = New Query(
		"SELECT
		|	ProductSegments.Ref
		|FROM
		|	Catalog.ProductSegments AS ProductSegments
		|WHERE
		|	ProductSegments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateManually)
		|	AND ProductSegments.ClearDate <> DATETIME(1, 1, 1)
		|	AND ProductSegments.ClearDate <= &ClearDate
		|
		|UNION ALL
		|
		|SELECT
		|	PartnersSegments.Ref
		|FROM
		|	Catalog.PartnersSegments AS PartnersSegments
		|WHERE
		|	PartnersSegments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateManually)
		|	AND PartnersSegments.ClearDate <> DATETIME(1, 1, 1)
		|	AND PartnersSegments.ClearDate <= &ClearDate");
	
	Query.SetParameter("ClearDate",CurrentSessionDate());
	Selection = Query.Execute().Select();

	// clear selected segments
	While Selection.Next() Do
		SegmentsOfCallServer.Clear(Selection.Ref);
	EndDo;

	SetPrivilegedMode(False);

EndProcedure

// Starts segment generation and controls the result
// 
// Parameters:
//   Segment - CatalogRef.PartnersSegments, CatalogRef.ProductSegments - the segment to be formed.
//
Procedure PerformPeriodicFormation(Segment) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.SegmentGeneration);
	
	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	If Not ValueIsFilled(Segment) Then
		Return;
	EndIf;
	
	LogParameters = New Structure("EventGroup_, Metadata, Data");
	LogParameters.EventGroup_ = NStr("vi = 'Tạo phân khúc. Khởi động theo lịch biểu';
									|ru = 'Формирование сегмента. Запуск по расписанию';
									|en = 'Segment generation. Run on schedule'; fa = 'Segment generation. Run on schedule';
									|it = 'Generazione del segmento. Avvio secondo la pianificazione';
									|pl = 'Tworzenie segmentu. Zaplanowane uruchomienie';
									|tr = 'Segment oluşumu. Programa göre başlatma'", CommonClientServer.DefaultLanguageCode());
	LogParameters.Metadata    = Segment.Metadata();
	LogParameters.Data        = Segment;
	
	LogRecord(LogParameters, EventLogLevel.Note, "", NStr("vi = 'Khởi động';
															|ru = 'Запуск';
															|en = 'Start'; fa = 'شروع';
															|it = 'Avvio';
															|pl = 'Start';
															|tr = 'Başlangıc'", CommonClientServer.DefaultLanguageCode()));
	
	SegmentDetails = Common.ObjectAttributesValues(
		Segment,
		"DeletionMark, GenerationMethod, Description ");
	
	// Checks
	If SegmentDetails.DeletionMark Then
		LogRecord(LogParameters, EventLogLevel.Error, "",
			NStr("vi = 'Kết thúc';
				|ru = 'Завершение';
				|en = 'End'; fa = 'پایان';
				|it = 'Completamento';
				|pl = 'End';
				|tr = 'Tamamlama'", CommonClientServer.DefaultLanguageCode()),
			NStr("vi = 'Phân khúc đã đặt dấu xóa';
				|ru = 'Сегмент помечен на удаление';
				|en = 'The segment is marked for deletion'; fa = 'The segment is marked for deletion';
				|it = 'Il segmento è stato contrassegnato per l''eliminazione';
				|pl = 'Segment oznaczony do usunięcia';
				|tr = 'Silinmek üzere işaretlenmiş segment'", CommonClientServer.DefaultLanguageCode()));
		Return;
	ElsIf SegmentDetails.GenerationMethod <> Enums.SegmentGenerationMethods.UpdateRegularly Then
		LogRecord(LogParameters, EventLogLevel.Error, "",
			NStr("vi = 'Kết thúc';
				|ru = 'Завершение';
				|en = 'End'; fa = 'پایان';
				|it = 'Completamento';
				|pl = 'End';
				|tr = 'Tamamlama'", CommonClientServer.DefaultLanguageCode()), 
			NStr("vi = 'Phân khúc không cập nhật định kỳ';
				|ru = 'Сегмент не периодически обновляемый';
				|en = 'The segment is not occasionally updated'; fa = 'The segment is not occasionally updated';
				|it = 'Il segmento non viene aggiornato periodicamente';
				|pl = 'Segment nie jest okresowo aktualizowany.';
				|tr = 'Segment dönemsel olarak güncellenmiyor'", CommonClientServer.DefaultLanguageCode()));
		Return;
	EndIf;
	
	Try
		SegmentsOfCallServer.Generate(Segment);
	Except
		
		LogRecord(LogParameters, 
		              EventLogLevel.Error,
		              "",
		              NStr("vi = 'Lỗi lập phân khúc';
							|ru = 'Ошибка формирования сегмента';
							|en = 'Segment generation error'; fa = 'Segment generation error';
							|it = 'Errore durante la generazione del segmento';
							|pl = 'Błąd formowania segmentu';
							|tr = 'Segment oluşturma hatası'", CommonClientServer.DefaultLanguageCode()) + " '"+ SegmentDetails.Description +"'",
		              ErrorInfo());
		
	EndTry;
	
	LogRecord(LogParameters, EventLogLevel.Note, "",NStr("vi = 'Kết thúc';
														|ru = 'Завершение';
														|en = 'End'; fa = 'پایان';
														|it = 'Completamento';
														|pl = 'End';
														|tr = 'Tamamlama'", CommonClientServer.DefaultLanguageCode()));
	
EndProcedure

// Serializes an object in XML
//
// Parameters:
//  Value  - Arbitrary - the object you want to serialize into XML.
//
// Returns:
//   String   - an object serialized in XML.
//
Function GetXML(Value) Export
	
	Record = New XMLWriter();
	Record.SetString();
	XDTOSerializer.WriteXML(Record, Value);
	Return Record.Close();
	
EndFunction

// Gets the description, SKD, and settings for the segment
//
// Parameters:
//  Ref     - CatalogRef.ProductSegments, CatalogRef.PartnersSegments - the segment whose SKD and
//                                                                                           settings are obtained.
//  TemplateName - String - name of the segment template.
//
// Returns:
//   Structure - consists of the following fields:
//      * LongDesc                  - String - segment description
//      * DataCompositionSchema     - DataCompositionSchema, Undefined - SKD of the template.
//      * DataCompositionSettings - DataCompositionSettings, Undefined -SKD template settings.
//
Function GetDescriptionAndLayoutDiagramOfDataByTemplateName(Ref, TemplateName) Export

	ReturnValue = New Structure;
	ReturnValue.Insert("LongDesc",                  "");
	ReturnValue.Insert("DataCompositionSchema",     Undefined);
	ReturnValue.Insert("DataCompositionSettings", Undefined);
	
	If TypeOf(Ref) = Type("CatalogRef.ProductSegments") Then
		
		CatalogName = "ProductSegments";
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.PartnersSegments") Then
		
		CatalogName = "PartnersSegments";
		
	Else
		
		Return ReturnValue;
	
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Segments.DataCompositionSchema AS StorageOfDataCompositionSchema,
	|	Segments.StorageOfDataCompositionSettings
	|FROM
	|	&CatalogName AS Segments
	|WHERE
	|	Segments.Ref = &Ref";
	
	Query.Text = StrReplace(Query.Text, "&CatalogName","Catalog." + CatalogName);
	Query.SetParameter("Ref",Ref);
	
	Selection = Query.Execute().Select();
	
	If Not ValueIsFilled(TemplateName) Then
		
		ReturnValue.LongDesc = TemplateName;
		If Selection.Next() Then
			
			StorageOfDataCompositionSchema =  Selection.StorageOfDataCompositionSchema; // ValueStorage 
			DataCompositionSchema = StorageOfDataCompositionSchema.Get();
			If DataCompositionSchema = Undefined Then
				ReturnValue.DataCompositionSchema = Catalogs[CatalogName].GetTemplate("MainSchema");
				ReturnValue.DataCompositionSettings = ReturnValue.DataCompositionSchema.DefaultSettings;
			Else
				ReturnValue.DataCompositionSchema = DataCompositionSchema;
				StorageOfDataCompositionSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage 
				ReturnValue.DataCompositionSettings = StorageOfDataCompositionSettings.Get();
			EndIf;
			
		EndIf;
		
	Else
		
		ReturnValue.LongDesc = Metadata.FindByType(TypeOf(Ref)).Templates.Find(TemplateName).Synonym;
		ReturnValue.DataCompositionSchema = Catalogs[CatalogName].GetTemplate(TemplateName);
		If Selection.Next() Then
			StorageOfDataCompositionSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage 
			ReturnValue.DataCompositionSettings = StorageOfDataCompositionSettings.Get();
		EndIf;
		
	EndIf;
	
	Return ReturnValue;

EndFunction

// Returns a table of values that contains references to the elements
// included in the segment, according to the SKD settings.
//
// Parameters:
//   LinkSegment - CatalogRef.PartnersSegments, CatalogRef.ProductSegments - the segment
//       that contains the elements that are received.
//
// Returns:
//   ValueList - the list of elements included in the segment.
//
Function ListOfDCSElements(LinkSegment) Export

	Settings = GetListSettings(LinkSegment);
	Return DCSTable(Settings.DCS, Settings.Settings);

EndFunction

#Region ProceduresEventHandlersForFormsAndModulesForSegmentCatalogObjects

// Called from the event handlers "when created on the server" for the partner and item segment element forms.
//
// Parameters:
//  Form   - ClientApplicationForm - The Form of the partner segment element or item that is being created contains:
//    * Object - CatalogObject.ProductSegments - segment for 
//  Failure-Boolean-indicates that the segment was not recorded.
//
Procedure OnCreateAtServer(Form) Export
	
	Object = Form.Object; 
	ObjectRef = Object.Ref;
	
	If TypeOf(ObjectRef) = Type("CatalogRef.PartnersSegments") Then
		
		ByPartners = True;
		
	ElsIf TypeOf(ObjectRef) = Type("CatalogRef.ProductSegments") Then
		
		ByPartners = False;
		
	Else
		
		Return;
		
	EndIf;
	
	If ByPartners Then
		Form.HasUpdateRight = AccessRight("Update",Metadata.Catalogs.PartnersSegments);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Generate", "Visible",
		                                                               AccessRight("Update", Metadata.InformationRegisters.SegmentPartners));
	Else
		Form.HasUpdateRight = AccessRight("Update",Metadata.Catalogs.ProductSegments);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Generate", "Visible",
		                                                               AccessRight("Update", Metadata.InformationRegisters.SegmentProducts));
	EndIf;
	
	Form.Items.ClearDate.ReadOnly =
		Object.GenerationMethod <> Enums.SegmentGenerationMethods.GenerateManually;
		
	If ValueIsFilled(ObjectRef) Then
		
		SegmentDetails = Common.ObjectAttributesValues(ObjectRef, "DataCompositionSchema, StorageOfDataCompositionSettings");
		
		DCS = SegmentDetails.DataCompositionSchema.Get();
		Settings = SegmentDetails.StorageOfDataCompositionSettings.Get();
		
		If DCS <> Undefined Then
			Form.DCSAddress = PutToTempStorage(DCS, New UUID);
		EndIf;
		If Settings <> Undefined Then
			Form.DCSSettingsAddress = PutToTempStorage(Settings, New UUID);
		EndIf;
		
	Else
		
		Object.DCSTemplateName = "MainSchema";
		
	EndIf;
	
	GetScheduleForRoutineTask(Form);
	
	If Not IsBlankString(Object.DCSTemplateName) Then
		
		TemplateMetadata_ = Metadata.FindByType(TypeOf(ObjectRef)).Templates.Find(Object.DCSTemplateName);
		If TemplateMetadata_ = Undefined Then
			
			Form.PresentationOfTheSKDTemplate = NStr("vi = 'Tùy chọn';
													|ru = 'Произвольная';
													|en = 'Arbitrary'; fa = 'دلخواه';
													|it = 'Casuale';
													|pl = 'Arbitrary';
													|tr = 'İsteğe bağlı'");
			
		Else
			
			Form.PresentationOfTheSKDTemplate = TemplateMetadata_.Synonym;
			
		EndIf;
		
	Else
		
		Form.PresentationOfTheSKDTemplate = NStr("vi = 'Tùy chọn';
												|ru = 'Произвольная';
												|en = 'Arbitrary'; fa = 'دلخواه';
												|it = 'Casuale';
												|pl = 'Arbitrary';
												|tr = 'İsteğe bağlı'");
		
	EndIf;
	
EndProcedure

Procedure BeforeWriteAtServer(Form,CurrentObject) Export
	
	If Not IsBlankString(Form.DCSAddress) Then 
		CurrentObject.DataCompositionSchema =
			New ValueStorage(GetFromTempStorage(Form.DCSAddress));
	Else
		
	CurrentObject.DataCompositionSchema = New ValueStorage(Undefined);

	EndIf;
		
	If Not IsBlankString(Form.DCSSettingsAddress) Then 
		
		CurrentObject.StorageOfDataCompositionSettings =
			New ValueStorage(GetFromTempStorage(Form.DCSSettingsAddress));
			
	Else
			
		CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(Undefined);
			
	EndIf;
	
	If Form.Object.GenerationMethod = Enums.SegmentGenerationMethods.UpdateRegularly Then
		CurrentObject.AdditionalProperties.Insert("Schedule", Form.Schedule);
		CurrentObject.AdditionalProperties.Insert("Use", Form.ScheduledJobUsed);
	EndIf;

EndProcedure

// Called from the "Before recording" event handlers for the partner and item segments.
//
// Parameters:
//  Object  - CatalogObject.PartnersSegments, CatalogObject.ProductSegments - the object being recorded.
//  Cancel   - Boolean - indicates that the segment was not recorded.
//
Procedure SegmentObjectBeforeRecording(Object, Cancel) Export
	
	If Cancel Or Object.DataExchange.Load Or Object.IsFolder Then
		Return;
	EndIf;
	
	// Creating a routine task (obtaining a unique identifier)
	SetPrivilegedMode(True);
	
	Job = ScheduledJobsServer.Job(Object.ScheduledJob);
	If Job = Undefined And Object.GenerationMethod = Enums.SegmentGenerationMethods.UpdateRegularly Then
		
		JobParameters = New Structure;
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.SegmentGeneration);
		JobParameters.Insert("Use", False);
		JobParameters.Insert("Description", NStr("vi = 'Tạo phân khúc bạn hàng';
												|ru = 'Формирование сегмента партнеров';
												|en = 'Partner segment generation'; fa = 'Partner segment generation';
												|it = 'Formazione del segmento dei partner';
												|pl = 'Tworzenie segmentu partnerów';
												|tr = 'İş ortağı segmentinin oluşturulması'") + ": " + TrimAll(Object.Description));
		Job = ScheduledJobsServer.AddJob(JobParameters);
		
		Object.ScheduledJob = ScheduledJobsServer.UUID(Job);
		
	EndIf;
	
	Object.AdditionalProperties.Insert("Job",Job);
	SetPrivilegedMode(False);
	
EndProcedure

// Called from the event handlers "Before deleting" the partner segments and the item.
//
// Parameters:
//  Object  - CatalogObject.PartnersSegments, CatalogObject.ProductSegments - object to be marked for deletion.
//  Cancel   - Boolean - indicates whether the segment is not marked for deletion.
//
Procedure SegmentBeforeDeletion(Object, Cancel) Export

	If Cancel Or Object.IsFolder Then
		Return;
	EndIf;
	
	If Object.GenerationMethod <>
		Enums.SegmentGenerationMethods.GenerateDynamically Then
		SegmentsOfCallServer.Clear(Object.Ref);
	EndIf;
	
	ScheduledJobsServer.DeleteJob(Object.ScheduledJob);

EndProcedure

// Called from event handlers for the "fill Processing" event for partner and item segments.
//
// Parameters:
//  Object           - CatalogObject.PartnersSegments, CatalogObject.ProductSegments - the object to copy.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//
Procedure SegmentFillProcessing(Object, FillingData = Undefined) Export
	
	If Not Object.IsFolder Then
		
		If ValueIsFilled(FillingData) Then
			FillPropertyValues(Object, FillingData);
		EndIf; 
		
		// set the default responsible
		If Not ValueIsFilled(Object.EmployeeResponsible) Then
			Object.EmployeeResponsible = Users.CurrentUser();
		EndIf;
		
		// set the creation date
		If Not ValueIsFilled(Object.CreationDate) Then
			Object.CreationDate = CurrentSessionDate();
		EndIf;
		
	EndIf;
	
EndProcedure 

// Called from event handlers for the" when copying " event for partner segments and items.
//
// Parameters:
//  Object  - CatalogObject.PartnersSegments, CatalogObject.ProductSegments - the object to copy.
//
Procedure SegmentWhenCopying(Object) Export
	
	If Object.IsFolder Then
		Return;
	EndIf;
	
	Object.CreationDate = CurrentSessionDate();
	Object.ScheduledJob = Undefined;
	
EndProcedure

// Called from the event handlers "on write" of the partner and item segments.
//
// Parameters:
//  Object  - CatalogObject.PartnersSegments, CatalogObject.ProductSegments - the object being recorded.
//  Cancel   - Boolean - indicates that the segment was not recorded.
//
Procedure SegmentWhenRecording(Object, Cancel) Export
	
	If Cancel Or Object.DataExchange.Load Or Object.IsFolder Then
		Return;
	EndIf;
	
	If Object.GenerationMethod =
		Enums.SegmentGenerationMethods.GenerateDynamically Then
		SegmentsOfCallServer.Clear(Object.Ref);
	EndIf;
	
	If Object.AdditionalProperties.Property("Job") Then
		Job = Object.AdditionalProperties.Job;
		If Job = Undefined Then
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	
	JobParameters = New Structure;
	
	If Object.GenerationMethod <> Enums.SegmentGenerationMethods.UpdateRegularly Then
		
		JobParameters.Insert("Use", False);
		
	EndIf;
	
	// The schedule is set in the form of an element
	If Object.AdditionalProperties.Property("Schedule") 
			And TypeOf(Object.AdditionalProperties.Schedule) = Type("JobSchedule")
			And String(Object.AdditionalProperties.Schedule) <> String(Job.Schedule)
		Then
		JobParameters.Insert("Schedule", Object.AdditionalProperties.Schedule);
	EndIf;
	
	// Usage is set in the form of an element
	If Object.DeletionMark And Job.Use Then
		
		JobParameters.Insert("Use", False);
		
	ElsIf Object.AdditionalProperties.Property("Use") 
			And Object.AdditionalProperties.Use <> Job.Use Then
		
		JobParameters.Insert("Use", Object.AdditionalProperties.Use);
		
	EndIf;

	If TypeOf(Object.Ref) = Type("CatalogRef.PartnersSegments") Then
		
		JobDescription = NStr("vi = 'Tạo phân khúc khách hàng';
								|ru = 'Формирование сегмента клиентов';
								|en = 'Customer segment generation'; fa = 'Customer segment generation';
								|it = 'Generazione del segmento dei clienti';
								|pl = 'Formowanie segmentu klientów';
								|tr = 'Müşteri segmentinin oluşturulması'") + ": ";
		
	ElsIf TypeOf(Object.Ref) = Type("CatalogRef.ProductSegments") Then
		
		JobDescription = NStr("vi = 'Tạo phân khúc mặt hàng';
								|ru = 'Формирование сегмента номенклатуры';
								|en = 'Generation of inventory segment'; fa = 'Generation of inventory segment';
								|it = 'Formazione del segmento dell''articolo';
								|pl = 'Tworzenie segmentu towaru';
								|tr = 'Stok segmentinin oluşturulması'") + ": ";
		
	EndIf;
	
	JobDescription = JobDescription + TrimAll(Object.Description);
	JobParameters.Insert("Description", JobDescription);
	
	If Job.Parameters.Count() <> 1 Or Job.Parameters[0] <> Object.Ref Then
		Parameters = New Array;
		Parameters.Add(Object.Ref);
		JobParameters.Insert("Parameters", Parameters);
	EndIf;
	
	SetPrivilegedMode(True);
	ScheduledJobsServer.ChangeJob(Object.ScheduledJob, JobParameters);
	
EndProcedure

#EndRegion

#Region ElementSetProcessingFunctions

// Returns a table of values containing the elements included in the segment,
// taking into account the way the segment is formed.
//
// Parameters:
//   LinkSegment - CatalogRef.PartnersSegments, CatalogRef.ProductSegments - the segment
//       that contains the elements that are received.
//
// Returns:
//   ValueTable - a table of values containing the elements included in the segment.
//
Function ValueTable(LinkSegment) Export
	
	GenerationMethod = Common.ObjectAttributeValue(LinkSegment, "GenerationMethod");

	If GenerationMethod =
		Enums.SegmentGenerationMethods.GenerateDynamically Then
		Return ListOfDCSElements(LinkSegment);
	Else
		Return SelectingFromRegister(LinkSegment).Unload();
	EndIf;

EndFunction

// Returns an array of elements that are part of the segment,
// taking into account the method of forming the segment.
//
// Parameters:
//   LinkSegment - CatalogRef.PartnersSegments, CatalogRef.ProductSegments - the segment
//       that contains the elements that are received.
//
// Returns:
//   Array - array of elements included in the segment.
//
Function ItemArray(LinkSegment) Export

	Return ValueTable(LinkSegment).UnloadColumn(0);

EndFunction

#EndRegion

#Region AccessRights

// Checks the right to change segments, depending on the segment type. 
//
// Parameters:
//  SegmentType  - String - indicates the type of segment.
//
// Returns:
//   Boolean   - True if there is a right to change.
//
Function YouHaveRightToChangeCompositionOfSegments(SegmentType) Export
	
	If SegmentType = "Products" Then
		VerifiableMetadata = Metadata.InformationRegisters.SegmentProducts;
	ElsIf SegmentType = "Partners" Then
		VerifiableMetadata = Metadata.InformationRegisters.SegmentPartners;
	Else
		Return False;
	EndIf;
	
	Return AccessRight("Update",VerifiableMetadata);
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions_

// Determines which characteristics of the item are included in the segment.
//
// Parameters:
//  Products  - CatalogRef.Products - the item whose characteristics are obtained.
//  Segment       - CatalogRef.ProductSegments - the segment that contains the item's characteristics.
//
// Returns:
//   ValueTable   - a table containing the Nomenclature and Characteristic columns.
//
Function GetProductSegmentCharacteristics(Products, Segment) Export
	
	If Not PrivilegedMode() Then
		SetPrivilegedMode(True);
	EndIf;
	
	Settings = GetListSettings(Segment);
	
	If Settings.DCS.DataSets.Find("SegmentGeneration") = Undefined Then
		
		DataCompositionClientServer.AddFilter(
			Settings.Settings, 
			New DataCompositionField("ListItem"),
			Products);
		
	Else
		
		DataCompositionClientServer.AddFilter(
			Settings.Settings, 
			New DataCompositionField("Products"),
			Products);
		
	EndIf;
	
	Return DCSTable(Settings.DCS, Settings.Settings);
	
EndFunction

// Returns the flag for whether the object is included in the segment
//
// Parameters:
//  ObjectRef   - Arbitrary - link to the partner object or item being analyzed,
//  LinkSegment  - CatalogRef.ProductSegments, CatalogRef.PartnersSegments - link to
//      a partner segment or item.,
//  Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//  Dynamic   - Boolean - True if the method of forming the segment is to form dynamically.
//
// Returns:
//   Boolean - the truth, if included.
//
Function BelongsToSegment(ObjectRef, LinkSegment, Characteristic = Undefined, Dynamic = True) Export
	
	If Dynamic Then
		
		If Not PrivilegedMode() Then
			SetPrivilegedMode(True);
		EndIf;
		
		Settings = GetListSettings(LinkSegment);
		
		If Settings.DCS.DataSets.Find("SegmentGeneration") = Undefined Then
			
			Filter          = Settings.Settings.Filter; // DataCompositionFilter 
			FilterItems1 = Filter.Items; // DataCompositionFilterItemCollection
			
			// set list selection
			FilterElement = FilterItems1.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue  = New DataCompositionField("ListItem");
			FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
			FilterElement.RightValue = ObjectRef;
			FilterElement.Use  = True;
			
			If Characteristic <> Undefined Then
				FilterElement = FilterItems1.Add(Type("DataCompositionFilterItem"));
				FilterElement.LeftValue  = New DataCompositionField("ElementCharacteristics");
				FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
				FilterElement.RightValue = Characteristic;
				FilterElement.Use  = True;
			EndIf;
			
		Else
			
			ByPartner = TypeOf(ObjectRef) = Type("CatalogRef.Partners");
			
			DataCompositionClientServer.AddFilter(
					Settings.Settings, 
					New DataCompositionField(?(ByPartner,"Partner","Products")),
					ObjectRef,,,
					New Structure("ReplaceCurrent", False));
			
			If Not ByPartner And Characteristic <> Undefined Then
				DataCompositionClientServer.AddFilter(
					Settings.Settings, 
					New DataCompositionField("Characteristic"),
					Characteristic);
			EndIf;
			
		EndIf;
		
		Return DCSTable(Settings.DCS, Settings.Settings).Count() > 0;
		
	Else
		
		Query = New Query;
		
		If TypeOf(ObjectRef) = Type("CatalogRef.Products") Then
			
			Query.Text = "SELECT ALLOWED TOP 1
			               |	SegmentProducts.Products
			               |FROM
			               |	InformationRegister.SegmentProducts AS SegmentProducts
			               |WHERE
			               |	SegmentProducts.Segment = &LinkSegment
			               |	AND SegmentProducts.Products = &ObjectRef
			               |	AND SegmentProducts.Characteristic = &Characteristic";
			
		ElsIf	TypeOf(ObjectRef) = Type("CatalogRef.Partners") Then
			
			Query.Text = "SELECT ALLOWED TOP 1
			               |	SegmentPartners.Partner
			               |FROM
			               |	InformationRegister.SegmentPartners AS SegmentPartners
			               |WHERE
			               |	SegmentPartners.Segment = &LinkSegment
			               |	AND SegmentPartners.Partner = &ObjectRef"; 
			
		Else
			
			Return Undefined;
			
		EndIf;
		
		Query.SetParameter("ObjectRef",ObjectRef);
		Query.SetParameter("LinkSegment",LinkSegment);
		Query.SetParameter("Characteristic",Characteristic);
		
		Return Not Query.Execute().IsEmpty();
		
	EndIf;
	
EndFunction

// Checks whether the partner is included in segments with the "periodically update" type after creating a new partner.
//
// Parameters:
//  Partner  - CatalogRef.Partners - Verified partner.
//
Procedure CheckWhetherPartnerIsIncludedInSegmentsWhenCreating(Partner) Export

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	PartnersSegments.Ref AS Segment
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments
	|WHERE
	|	(NOT PartnersSegments.IsFolder)
	|	AND (NOT PartnersSegments.DeletionMark)
	|	AND PartnersSegments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.UpdateRegularly)
	|	AND PartnersSegments.CheckForInclusionWhileCreatingNew";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		If BelongsToSegment(Partner, Selection.Segment, , True) Then
			AddPartnerToSegment(Selection.Segment, Partner);
		EndIf;
	
	EndDo;

EndProcedure

// Sets the value and use of the parameter that determines the selection by partner
// based on the value and use of the segment parameter.
//
// Parameters:
//  SegmentParameter   - DataCompositionSchemaParameter  - parameter containing selection by segment.
//  PartnersParameter  - DataCompositionSchemaParameter  - the parameter containing the selection of the partner.
//
Procedure SetSegmentSelection(SegmentParameter, PartnersParameter) Export

	PartnersParameter.Use = False;

	If SegmentParameter.Use Then
		PartnerList = SegmentsOfCallServer.ValueList(SegmentParameter.Value);
		If PartnerList.Count() > 0 Then
			PartnersParameter.Value = PartnerList;
			PartnersParameter.Use = True;
		EndIf;
	EndIf;

EndProcedure

// If the use of selection for a non-item segment is enabled in the SKD settings,
// the procedure sets the service parameter for using selection for a non-item segment.
//
// Parameters:
//  SettingObject1 - DataCompositionSettingsComposer, DataCompositionNestedObjectSettings - where to get the settings.
//  UseSettingsOnly - Boolean - indicates that the default settings will be used.
//
// Returns:
//   Boolean - a sign of using segment selection.
//
Function EnableSelectionByNonSegmentOfVSPDProductItem(SettingObject1, UseSettingsOnly = False) Export
	
	ThisParameterIsUsedOnlyForNonSegments  = DataCompositionClientServer.GetParameter(
		SettingObject1.Settings, 
		"SelectionBasedOnNonProductSegmentIsUsed");
	
	If ThisParameterIsUsedOnlyForNonSegments = Undefined Then
		Return False;
	EndIf;
	
	ThisParameterIsUsedOnlyForNonSegments.Value      = False;
	ThisParameterIsUsedOnlyForNonSegments.Use = False;
	
	If TypeOf(SettingObject1) = Type("DataCompositionSettingsComposer") And Not UseSettingsOnly Then
		MainCircuitSettings = SettingObject1.GetSettings();
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionNestedObjectSettings") Or UseSettingsOnly Then
		MainCircuitSettings = SettingObject1.Settings;
	EndIf;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(MainCircuitSettings.Filter, "NotProductSegment");
	NonSegmentSelectionIsUsed = False;
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then  
			NonSegmentSelectionIsUsed = True;
			Break;
		EndIf;
	EndDo;
	
	DataCompositionClientServer.SetParameter(SettingObject1, "SelectionBasedOnNonProductSegmentIsUsed", True, NonSegmentSelectionIsUsed);
	
	Return NonSegmentSelectionIsUsed;
	
EndFunction

// If the use of selection by item segment is enabled in the SCD settings,
// the procedure sets the service parameter for using selection by item segment.
//
// Parameters:
//  SettingObject1 - DataCompositionSettingsComposer, DataCompositionNestedObjectSettings - where to get the settings.
//  UseSettingsOnly - Boolean - indicates that the default settings will be used.
//
// Returns:
//   Boolean - a sign of using segment selection.
//
Function EnableSelectionBySegmentOfVSPDProductRange(SettingObject1, UseSettingsOnly = False) Export
	
	ThisParameterIsUsedForSegmentSelection  = DataCompositionClientServer.GetParameter(
		SettingObject1.Settings, 
		"FilterByProductSegmentIsUsed");

	If ThisParameterIsUsedForSegmentSelection = Undefined Then
		Return False;
	EndIf;
	
	ThisParameterIsUsedOnlyForNonSegments  = DataCompositionClientServer.GetParameter(
		SettingObject1.Settings, 
		"SelectionBasedOnNonProductSegmentIsUsed");
	
	ThisParameterIsUsedForSegmentSelection.Value      = False;
	ThisParameterIsUsedForSegmentSelection.Use = False;
	
	If TypeOf(SettingObject1) = Type("DataCompositionSettingsComposer") And Not UseSettingsOnly Then
		MainCircuitSettings = SettingObject1.GetSettings();
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionNestedObjectSettings") Or UseSettingsOnly Then
		MainCircuitSettings = SettingObject1.Settings;
	EndIf;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(MainCircuitSettings.Filter, "ProductSegment");
	SegmentSelectionIsUsed = False;
	SegmentSelectionIsNotUsed = False;
	SettingsUpdateRequired = False;
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then 
			If Not ThisParameterIsUsedOnlyForNonSegments = Undefined Then
				If KindOfComparisonIsNot(FilterElement.ComparisonType) Then
					SegmentSelectionIsNotUsed = True;
				Else
					SegmentSelectionIsUsed = True;
					SegmentSelectionIsNotUsed = SegmentSelectionIsNotUsed Or False;
				EndIf;
				ThisParameterIsUsedOnlyForNonSegments.Value      = SegmentSelectionIsNotUsed;
				ThisParameterIsUsedOnlyForNonSegments.Use = SegmentSelectionIsNotUsed;
				
				If ThisParameterIsUsedOnlyForNonSegments.Value Then
					FilterElement.ComparisonType = TypeOfComparisonToInvert(FilterElement.ComparisonType);
					SettingsUpdateRequired = True;
				EndIf;
			Else
				SegmentSelectionIsUsed = True;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If TypeOf(SettingObject1) = Type("DataCompositionSettingsComposer") 
		And Not UseSettingsOnly 
		And SettingsUpdateRequired Then
		
		SettingObject1.LoadSettings(MainCircuitSettings);
		SettingObject1.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
	EndIf;
	
	If SegmentSelectionIsUsed = True And SegmentSelectionIsNotUsed = True Then
		MessageToUserText = NStr("vi = 'Không hỗ trợ lọc đồng thời bao gồm và loại trừ theo phân khúc mặt hàng (""Không bằng"", ""Không trong danh sách""...). Cần chọn bao gồm hoặc loại trừ';
								|ru = 'Не поддерживается одновременный отбор по сегментам номенклатуры на вхождение и исключение (""Не равно"", ""Не в списке"" и прочее). Необходимо выбрать или вхождение или исключение';
								|en = 'Cannot filter items by inventory segments to include and exclude an item at the same time (""Not equal to"", ""Not in list"", and other). Select one option only'; fa = 'Cannot filter items by inventory segments to include and exclude an item at the same time (""Not equal to"", ""Not in list"", and other). Select one option only';
								|it = 'Не поддерживается одновременный отбор по сегментам номенклатуры на вхождение и исключение (""Не равно"", ""Не в списке"" и прочее). Необходимо выбрать или вхождение или исключение';
								|pl = 'Cannot filter items by inventory segments to include and exclude an item at the same time (""Not equal to"", ""Not in list"", and other). Select one option only';
								|tr = 'Oluşum ve hariç tutma (""Eşit değil"", ""Listede yok"", vb.) için stok segmentleri tarafından eşzamanlı seçim desteklenmemektedir. Dahil etme veya hariç tutma seçeneklerinden birini seçmek gerekir'");
		Common.MessageToUser(MessageToUserText);
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingObject1, "FilterByProductSegmentIsUsed", True, SegmentSelectionIsUsed);
	If Not ThisParameterIsUsedOnlyForNonSegments = Undefined Then
		DataCompositionClientServer.SetParameter(SettingObject1, "SelectionBasedOnNonProductSegmentIsUsed", True, SegmentSelectionIsNotUsed);
	EndIf;
	
	If SegmentSelectionIsUsed Then
		
		Field = New DataCompositionField("FilterBySegmentInternal");
		If SettingObject1.Settings.Filter.FilterAvailableFields.Items.Find(Field) <> Undefined Then
			
			If Not DataCompositionClientServer.SelectionIsUsed_(SettingObject1.Settings.Filter.Items, Field) Then
				FilterElement = DataCompositionClientServer.AddFilter(
					SettingObject1.Settings.Filter,
					Field,
					True,
					DataCompositionComparisonType.Equal,
					True);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return SegmentSelectionIsUsed Or SegmentSelectionIsNotUsed;
	
EndFunction

// If the use of partner segment selection is enabled in the SCD settings,
// the procedure sets the service parameter for using partner segment selection.
//
// Parameters:
// SettingObject1 - DataCompositionSettingsComposer, DataCompositionNestedObjectSettings - where to get the settings.
//
// Returns:
//   Boolean - a sign of using segment selection.
//
Function EnableSelectionByVSKDPartnerSegment(SettingObject1) Export
	
	ThisParameterIsUsedForSegmentSelection = DataCompositionClientServer.GetParameter(
		SettingObject1.Settings,
		"FilterByPartnerSegmentIsUsed");
	If ThisParameterIsUsedForSegmentSelection = Undefined Then
		Return False;
	EndIf;
	
	ThisParameterIsUsedForSegmentSelection.Value = False;
	ThisParameterIsUsedForSegmentSelection.Use = False;
	
	If TypeOf(SettingObject1) = Type("DataCompositionSettingsComposer") Then
		MainCircuitSettings = SettingObject1.GetSettings();
	ElsIf TypeOf(SettingObject1) = Type("DataCompositionNestedObjectSettings") Then
		MainCircuitSettings = SettingObject1.Settings;
	EndIf;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(MainCircuitSettings.Filter, "PartnersSegment");
	SegmentSelectionIsUsed = False;
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then  
			SegmentSelectionIsUsed = True;
			Break;
		EndIf;
	EndDo;
	
	DataCompositionClientServer.SetParameter(SettingObject1, "FilterByPartnerSegmentIsUsed", True, SegmentSelectionIsUsed);
	
	Return SegmentSelectionIsUsed;
	
EndFunction

// Verifies that the partner is included in the shipment ban segments
//
// Parameters:
//  Partner	 - CatalogRef.Partners - Verified partner.
// 
// Returns:
//  Boolean - a sign of the partner's entry.
//
Function PartnerIsIncludedInShipmentBanSegments(Partner) Export
	
	If Not GetFunctionalOption("UseShipmentProhibition") Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SegmentPartners.Segment
	|FROM
	|	InformationRegister.SegmentPartners AS SegmentPartners
	|WHERE
	|	SegmentPartners.Segment.SegmentIsUsedToProhibitShipment
	|	AND NOT SegmentPartners.Segment.IsFolder
	|	AND NOT SegmentPartners.Segment.DeletionMark
	|	AND SegmentPartners.Partner = &Partner";
	
	Query.SetParameter("Partner", Partner);
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty()
	
EndFunction

// Sets visibility of the shipment ban to the partner on the form
//
// Parameters:
//  Partner	 - CatalogRef.Partners - Check the partner
//  FormItems	 - FormItems - elements of a changeable form.
//
Procedure SetVisibilityOfShipmentBanToPartner(Partner, FormItems) Export
	
	If ValueIsFilled(Partner) Then
		ShipmentIsProhibited = SegmentsServer.PartnerIsIncludedInShipmentBanSegments(Partner);
	Else
		ShipmentIsProhibited = False;
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("PictureShipmentToThePartnerIsProhibited");
	ItemArray.Add("TextShippingToAPartnerIsProhibited");
	TMCommonUseClientServer.SetPropertyOfFormElements(FormItems, ItemArray, "Visible", ShipmentIsProhibited);
	
EndProcedure

// Returns the number of segments of the prohibition of shipment
// 
// Returns:
//  Number - the number of segments.
//
Function NumberOfShipmentBanSegments() Export
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 2
	|	PartnersSegments.Ref AS Segment
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments
	|WHERE
	|	PartnersSegments.SegmentIsUsedToProhibitShipment
	|	AND NOT PartnersSegments.DeletionMark";
		
	Result = Query.Execute().Unload();
	
	Return Result.Count()
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns the result of a query that defines a set of segment elements
// from the information registers (used for non-dynamic segments).
//
Function SelectingFromRegister(LinkSegment)

	If TypeOf(LinkSegment) = Type("CatalogRef.ProductSegments") Then
		Query = New Query(
			"SELECT ALLOWED
			|	SegmentProducts.Products,
			|	SegmentProducts.Characteristic
			|FROM
			|	InformationRegister.SegmentProducts AS SegmentProducts
			|WHERE
			|	SegmentProducts.Segment = &Segment");
		Query.SetParameter("Segment", LinkSegment);
	Else
		Query = New Query(
			"SELECT ALLOWED
			|	SegmentPartners.Partner
			|FROM
			|	InformationRegister.SegmentPartners AS SegmentPartners
			|WHERE
			|	SegmentPartners.Segment = &Segment");
		Query.SetParameter("Segment", LinkSegment);
	EndIf;

	Return Query.Execute();

EndFunction

// Returns a structure containing the SKD of a segment and the settings of a variant
// containing a list of elements. In this case, the list request fields are enabled.
//
Function GetListSettings(LinkSegment)
	
	SegmentDCSDetails = Common.ObjectAttributesValues(
		LinkSegment,
		"DataCompositionSchema,StorageOfDataCompositionSettings,DCSTemplateName");
		
	SegmentSettings = SegmentDCSDetails.StorageOfDataCompositionSettings.Get();
		
	If IsBlankString(SegmentDCSDetails.DCSTemplateName) Then
		
		DCS = SegmentDCSDetails.DataCompositionSchema.Get();
		
	Else
		
		SKD_OfTemplate = GetDescriptionAndLayoutDiagramOfDataByTemplateName(LinkSegment, SegmentDCSDetails.DCSTemplateName);
		DCS = SKD_OfTemplate.DataCompositionSchema;
		
	EndIf;
	
	// connect list request fields
	
	If DCS.DataSets.Find("SegmentList") <> Undefined Then
		
		Fields = DCS.DataSets.SegmentList.Fields;
		For Each Field In Fields Do
			Field.UseRestriction.Field = False;
		EndDo;//connect list request fields
		
		ListSettings = DCS.SettingVariants.List.Settings;
		Settings = DCS.DefaultSettings;
		DataCompositionClientServer.CopyElements(ListSettings.DataParameters, Settings.DataParameters);
		DataCompositionClientServer.CopyElements(ListSettings.Filter, Settings.Filter);
		
	ElsIf  DCS.DataSets.Find("SegmentGeneration") <> Undefined Then
		
		If SegmentSettings <> Undefined Then
			
			ListSettings = SegmentSettings;
			
		Else
			
			ListSettings = DCS.SettingVariants.SegmentGeneration.Settings;
			
		EndIf;
		
		SegmentOutputSet = DCS.DataSets.Find("DisplaySegment");
		If SegmentOutputSet <> Undefined Then
			DCS.DataSets.Delete(SegmentOutputSet);
		EndIf;
		
		SettingsComposerIntermediate = New DataCompositionSettingsComposer;
		SettingsComposerIntermediate.Initialize(New DataCompositionAvailableSettingsSource(DCS));
		SettingsComposerIntermediate.LoadSettings(ListSettings);
		SettingsComposerIntermediate.Refresh();
		
		ListSettings = SettingsComposerIntermediate.Settings;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	Return New Structure("DCS, Settings", DCS, ListSettings);
	
EndFunction

// Generates and returns a table of values for SKD and settings
// Parameters:
// DCS       - DataCompositionSchema - 
// Settings - DataCompositionSettings - a variant of the schema settings, according to which you need to create a table.
//
// Returns:
//   ValueTable
//
Function DCSTable(DCS, Settings)

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DCS,Settings,,,
		Type("DataCompositionValueCollectionTemplateGenerator"));
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,,,True);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	ValueTable = New ValueTable;
	OutputProcessor.SetObject(ValueTable);
	OutputProcessor.Output(DataCompositionProcessor);

	Column = ValueTable.Columns.Find("Partner");
	If Column <> Undefined Then
		Column.Name = "ListItem";
	EndIf;
	Column = ValueTable.Columns.Find("Products");
	If Column <> Undefined Then
		Column.Name = "ListItem";
	EndIf;
	Column = ValueTable.Columns.Find("Characteristic");
	If Column <> Undefined Then
		Column.Name = "ElementCharacteristics";
	EndIf;
	
	If ValueTable.Columns.Count() = 1 Then
		ValueTable.GroupBy("ListItem");
	Else
		ValueTable.GroupBy("ListItem,ElementCharacteristics");
	EndIf;

	Return ValueTable;

EndFunction

Procedure GetScheduleForRoutineTask(Form) Export
	
	Form.Schedule = New JobSchedule;
	
	If Form.Object.Ref.IsEmpty() Then
		
		Form.Schedule.BeginTime = '00010101220000'; // at 10:00 pm
		Form.Schedule.DaysRepeatPeriod = 1; //every day
		
	Else
		
		SetPrivilegedMode(True);
		JobID = Form.Object.ScheduledJob;
		If TypeOf(JobID) = Type("UUID") Then
			Job = ScheduledJobsServer.Job(JobID);
			If Job <> Undefined Then
				Form.Schedule = Job.Schedule;
				Form.ScheduledJobUsed = Job.Use;
				Form.ScheduleAsString = String(Form.Schedule);
			EndIf;
		EndIf; 
		
	EndIf;
	
EndProcedure

Function KindOfComparisonIsNot(Var_ComparisonType)
	
	TypesOfComparisonAreNot = New Array();
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotInHierarchy);
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotInList);
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotInListByHierarchy);
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotFilled);
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotBeginsWith);
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotLike);
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotEqual);
	TypesOfComparisonAreNot.Add(DataCompositionComparisonType.NotContains);
	
	Return Not (TypesOfComparisonAreNot.Find(Var_ComparisonType) = Undefined);
	
EndFunction

Function TypeOfComparisonToInvert(Var_ComparisonType)

	ComparisonKinds = New Map();
	ComparisonKinds.Insert(DataCompositionComparisonType.InHierarchy, DataCompositionComparisonType.NotInHierarchy);
	ComparisonKinds.Insert(DataCompositionComparisonType.InList,DataCompositionComparisonType.NotInList);
	ComparisonKinds.Insert(DataCompositionComparisonType.InListByHierarchy,DataCompositionComparisonType.NotInListByHierarchy);
	ComparisonKinds.Insert(DataCompositionComparisonType.Filled,DataCompositionComparisonType.NotFilled);
	ComparisonKinds.Insert(DataCompositionComparisonType.BeginsWith,DataCompositionComparisonType.NotBeginsWith);
	ComparisonKinds.Insert(DataCompositionComparisonType.Like,DataCompositionComparisonType.NotLike);
	ComparisonKinds.Insert(DataCompositionComparisonType.Equal,DataCompositionComparisonType.NotEqual);
	ComparisonKinds.Insert(DataCompositionComparisonType.Contains,DataCompositionComparisonType.NotContains);

	ComparisonKinds.Insert(DataCompositionComparisonType.NotInHierarchy, DataCompositionComparisonType.InHierarchy);
	ComparisonKinds.Insert(DataCompositionComparisonType.NotInList,DataCompositionComparisonType.InList);
	ComparisonKinds.Insert(DataCompositionComparisonType.NotInListByHierarchy,DataCompositionComparisonType.InListByHierarchy);
	ComparisonKinds.Insert(DataCompositionComparisonType.NotFilled,DataCompositionComparisonType.Filled);
	ComparisonKinds.Insert(DataCompositionComparisonType.NotBeginsWith,DataCompositionComparisonType.BeginsWith);
	ComparisonKinds.Insert(DataCompositionComparisonType.NotLike,DataCompositionComparisonType.Like);
	ComparisonKinds.Insert(DataCompositionComparisonType.NotEqual,DataCompositionComparisonType.Equal);
	ComparisonKinds.Insert(DataCompositionComparisonType.NotContains,DataCompositionComparisonType.Contains);
	
	TypeOfComparisonFound = ComparisonKinds.Get(Var_ComparisonType);

	If TypeOfComparisonFound = Undefined Then
		TypeOfComparisonFound = DataCompositionComparisonType.Equal;
	EndIf;
	
	Return TypeOfComparisonFound;
	
EndFunction

#EndRegion
